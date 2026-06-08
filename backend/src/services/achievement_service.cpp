#include "services/achievement_service.h"

#include "support/api_helpers.h"

#include <algorithm>
#include <cstdlib>
#include <cmath>
#include <sstream>
#include <stdexcept>
#include <unordered_set>
#include <vector>

namespace tourism::services {
namespace {

using tourism::db::PgConnection;
using tourism::db::PgResult;
using tourism::db::exec_params;
using tourism::db::exec_sql;
using tourism::support::json_escape;
using tourism::support::string_list;
using tourism::support::to_double;
using tourism::support::to_int;
using tourism::support::trim_text;

struct AchievementRule {
    std::string code;
    int target = 1;
    std::vector<std::string> spots;
};

std::vector<AchievementRule> rules() {
    return {
        {"passport-first-stamp", 1, {}},
        {"stamp-gugong", 1, {"故宫"}},
        {"theme-axis", 4, {"前门", "天安门", "故宫", "景山"}},
        {"theme-museum", 2, {"国家博物馆", "故宫"}},
        {"theme-old-citywalk", 4, {"鼓楼", "什刹海", "北海", "景山"}},
        {"theme-royal-gardens", 3, {"颐和园", "圆明园", "北海"}},
        {"theme-night-food", 2, {"王府井", "三里屯"}},
        {"theme-family-nature", 2, {"奥林匹克森林公园", "北海"}},
        {"diary-memory-maker", 1, {}},
        {"master-travel-writer", 1, {}}
    };
}

AchievementRule rule_for(const std::string& code) {
    for (const auto& rule : rules()) {
        if (rule.code == code) return rule;
    }
    return {code, 1, {}};
}

std::string sql_quote(const std::string& value) {
    std::string out = "'";
    for (char ch : value) {
        if (ch == '\'') out += "''";
        else out += ch;
    }
    out += "'";
    return out;
}

std::string status_label(const std::string& status) {
    if (status == "unlocked") return "已解锁";
    if (status == "in_progress") return "进行中";
    return "未解锁";
}

std::string tier_label(int tier) {
    if (tier == 1) return "基础打卡";
    if (tier == 2) return "主题集章";
    if (tier == 3) return "旅行日记";
    return "大师评审";
}

std::string redemption_status_label(const std::string& status) {
    if (status == "approved") return "已确认";
    if (status == "rejected") return "未通过";
    if (status == "shipped") return "已寄出";
    return "待处理";
}

std::string review_status_label(const std::string& status) {
    if (status == "approved") return "已通过";
    if (status == "rejected") return "未通过";
    return "待评审";
}

double haversine_meters(double lat1, double lng1, double lat2, double lng2) {
    constexpr double earth_radius = 6371000.0;
    constexpr double pi = 3.14159265358979323846;
    auto rad = [pi](double value) { return value * pi / 180.0; };
    double dlat = rad(lat2 - lat1);
    double dlng = rad(lng2 - lng1);
    double a = std::sin(dlat / 2.0) * std::sin(dlat / 2.0) +
               std::cos(rad(lat1)) * std::cos(rad(lat2)) *
               std::sin(dlng / 2.0) * std::sin(dlng / 2.0);
    return earth_radius * 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));
}

std::string progress_json(int current, int target, int percent, const std::string& label) {
    std::ostringstream out;
    out << "{\"current\":" << current
        << ",\"target\":" << std::max(target, 1)
        << ",\"percent\":" << std::max(0, std::min(percent, 100))
        << ",\"label\":\"" << json_escape(label) << "\"}";
    return out.str();
}

crow::json::wvalue progress_value(const PgResult& rows, int row) {
    crow::json::wvalue value;
    value["current"] = to_int(rows.value(row, "progress_current"));
    value["target"] = to_int(rows.value(row, "progress_target"), 1);
    value["percent"] = to_int(rows.value(row, "progress_percent"));
    value["label"] = rows.value(row, "progress_label");
    return value;
}

int checked_spot_count(PgConnection& db, int user_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT COUNT(DISTINCT scenic_spot_id)::text AS count
        FROM user_scenic_checkins
        WHERE user_id = $1
    )SQL", {std::to_string(user_id)});
    return rows.rows() ? to_int(rows.value(0, "count")) : 0;
}

std::string checked_spot_name(PgConnection& db, int user_id, const std::string& name_fragment) {
    auto rows = exec_params(db, R"SQL(
        SELECT s.name
        FROM user_scenic_checkins c
        JOIN scenic_spots s ON s.id = c.scenic_spot_id
        WHERE c.user_id = $1 AND s.name ILIKE '%' || $2 || '%'
        ORDER BY c.created_at DESC
        LIMIT 1
    )SQL", {std::to_string(user_id), name_fragment});
    return rows.rows() ? rows.value(0, "name") : "";
}

bool has_checked_spot(PgConnection& db, int user_id, const std::string& name_fragment) {
    return !checked_spot_name(db, user_id, name_fragment).empty();
}

std::vector<std::string> checked_theme_spots(PgConnection& db, int user_id, const std::vector<std::string>& spots) {
    std::vector<std::string> checked;
    for (const auto& spot : spots) {
        if (has_checked_spot(db, user_id, spot)) checked.push_back(spot);
    }
    return checked;
}

std::vector<std::string> missing_theme_spots(const std::vector<std::string>& required, const std::vector<std::string>& checked) {
    std::vector<std::string> missing;
    for (const auto& spot : required) {
        if (std::find(checked.begin(), checked.end(), spot) == checked.end()) missing.push_back(spot);
    }
    return missing;
}

int qualified_diary_count(PgConnection& db, int user_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT COUNT(*)::text AS count
        FROM travel_diaries
        WHERE user_id = $1
          AND status = 1
          AND char_length(COALESCE(content, '')) >= 120
          AND COALESCE(cardinality(images), 0) >= 1
          AND COALESCE(cardinality(scenic_spot_ids), 0) >= 1
    )SQL", {std::to_string(user_id)});
    return rows.rows() ? to_int(rows.value(0, "count")) : 0;
}

int approved_review_count(PgConnection& db, int user_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT COUNT(*)::text AS count
        FROM achievement_review_submissions
        WHERE user_id = $1 AND status = 'approved'
    )SQL", {std::to_string(user_id)});
    return rows.rows() ? to_int(rows.value(0, "count")) : 0;
}

std::string progress_label_for(const std::string& code, int current, int target) {
    if (code == "passport-first-stamp") return "已打卡 " + std::to_string(current) + " 个景点";
    if (code == "stamp-gugong") return current > 0 ? "故宫印章已收集" : "前往故宫完成打卡";
    if (code == "diary-memory-maker") return "合格旅行日记 " + std::to_string(current) + " 篇";
    if (code == "master-travel-writer") return "大师评审通过 " + std::to_string(current) + " 篇";
    return "已收集 " + std::to_string(current) + "/" + std::to_string(target) + " 枚主题印章";
}

std::string next_action_for(const std::string& code,
                            const std::string& status,
                            const std::vector<std::string>& missing_spots) {
    if (status == "unlocked") return "已完成，可以领取数字纪念凭证";
    if (!missing_spots.empty()) return "下一枚建议去：" + missing_spots.front();
    if (code == "passport-first-stamp") return "去任意景点详情页收集第一枚旅行印章";
    if (code == "stamp-gugong") return "去故宫详情页完成一次打卡";
    if (code == "diary-memory-maker") return "发布一篇含景点、图片且超过 120 字的旅行日记";
    if (code == "master-travel-writer") return "将优质公开游记提交人工评审";
    return "继续探索并收集主题印章";
}

std::string seed_sql() {
    return R"SQL(
        INSERT INTO achievements (code, name, description, icon_url, level, type, tier, display_order, requirement, reward, is_active)
        VALUES
        ('passport-first-stamp', '北京旅行第一章', '完成任意一个景点打卡，开启你的 TourPilot 旅行护照。', '', 1, 'exploration', 1, 10,
         '{"kind":"checkin_count","target":1}', '{"points":30,"digitalCollectible":true}', TRUE),
        ('stamp-gugong', '故宫印章', '到访故宫并完成打卡，收集一枚经典地标印章。', '', 1, 'exploration', 1, 20,
         '{"kind":"spot","spot":"故宫"}', '{"points":40,"digitalCollectible":true}', TRUE),
        ('theme-axis', '中轴线集章者', '集齐前门、天安门、故宫、景山，完成北京中轴线主题探索。', '', 2, 'theme', 2, 30,
         '{"kind":"theme","spots":["前门","天安门","故宫","景山"]}', '{"points":120,"digitalCollectible":true,"physicalBadge":true}', TRUE),
        ('theme-museum', '博物馆漫游家', '完成国家博物馆与故宫相关打卡，解锁文化探索主题章。', '', 2, 'theme', 2, 40,
         '{"kind":"theme","spots":["国家博物馆","故宫"]}', '{"points":100,"digitalCollectible":true,"physicalBadge":true}', TRUE),
        ('theme-old-citywalk', '老城漫步达人', '集齐鼓楼、什刹海、北海、景山，完成老城 citywalk 主题。', '', 2, 'theme', 2, 50,
         '{"kind":"theme","spots":["鼓楼","什刹海","北海","景山"]}', '{"points":140,"digitalCollectible":true,"physicalBadge":true}', TRUE),
        ('theme-royal-gardens', '皇家园林收藏家', '打卡颐和园、圆明园、北海，收集皇家园林主题印章。', '', 2, 'theme', 2, 60,
         '{"kind":"theme","spots":["颐和园","圆明园","北海"]}', '{"points":140,"digitalCollectible":true,"physicalBadge":true}', TRUE),
        ('theme-night-food', '夜游美食探索者', '打卡王府井与三里屯，记录城市夜色和美食记忆。', '', 2, 'theme', 2, 70,
         '{"kind":"theme","spots":["王府井","三里屯"]}', '{"points":100,"digitalCollectible":true,"physicalBadge":true}', TRUE),
        ('theme-family-nature', '亲子自然观察员', '打卡奥林匹克森林公园与北海，完成轻松自然主题。', '', 2, 'theme', 2, 80,
         '{"kind":"theme","spots":["奥林匹克森林公园","北海"]}', '{"points":100,"digitalCollectible":true,"physicalBadge":true}', TRUE),
        ('diary-memory-maker', '旅行记忆创作者', '发布包含景点、图片和完整体验记录的旅行日记。', '', 3, 'diary', 3, 90,
         '{"kind":"diary","min_words":120,"min_images":1,"min_spots":1}', '{"points":180,"digitalCollectible":true,"creatorBadge":true}', TRUE),
        ('master-travel-writer', '大师级旅行记录者', '优质旅行日记通过人工评审，获得最高级纪念奖励。', '', 4, 'diary_review', 4, 100,
         '{"kind":"master_review","status":"approved"}', '{"points":300,"digitalCollectible":true,"physicalBadge":true,"premium":true}', TRUE)
        ON CONFLICT (code) DO UPDATE SET
            name = EXCLUDED.name,
            description = EXCLUDED.description,
            icon_url = EXCLUDED.icon_url,
            level = EXCLUDED.level,
            type = EXCLUDED.type,
            tier = EXCLUDED.tier,
            display_order = EXCLUDED.display_order,
            requirement = EXCLUDED.requirement,
            reward = EXCLUDED.reward,
            is_active = EXCLUDED.is_active
    )SQL";
}

bool has_default_achievements(PgConnection& db) {
    std::string codes;
    for (const auto& rule : rules()) {
        if (!codes.empty()) codes += ",";
        codes += sql_quote(rule.code);
    }
    auto rows = exec_sql(db, "SELECT COUNT(*)::text AS count FROM achievements WHERE code IN (" + codes + ")");
    return rows.rows() && to_int(rows.value(0, "count")) >= static_cast<int>(rules().size());
}

void seed_default_achievements_if_missing(PgConnection& db) {
    ensure_achievement_schema(db);
    if (!has_default_achievements(db)) exec_sql(db, seed_sql(), PGRES_COMMAND_OK);
}

std::unordered_set<std::string> unlocked_codes(PgConnection& db, int user_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT a.code
        FROM user_achievements ua
        JOIN achievements a ON a.id = ua.achievement_id
        WHERE ua.user_id = $1 AND ua.status = 'unlocked'
    )SQL", {std::to_string(user_id)});
    std::unordered_set<std::string> codes;
    for (int row = 0; row < rows.rows(); ++row) codes.insert(rows.value(row, "code"));
    return codes;
}

crow::json::wvalue collectible_json(const PgResult& rows, int row) {
    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["achievementId"] = to_int(rows.value(row, "achievement_id"));
    item["diaryId"] = to_int(rows.value(row, "diary_id"));
    item["tokenId"] = rows.value(row, "token_id");
    item["name"] = rows.value(row, "name");
    item["description"] = rows.value(row, "description");
    item["imageUrl"] = rows.value(row, "image_url");
    item["blockchainHash"] = rows.value(row, "blockchain_hash");
    item["mintedAt"] = rows.value(row, "minted_at");
    item["createdAt"] = rows.value(row, "created_at");
    item["achievementName"] = rows.value(row, "achievement_name");
    item["achievementCode"] = rows.value(row, "achievement_code");
    item["tier"] = to_int(rows.value(row, "tier"), 1);
    item["tierLabel"] = tier_label(to_int(rows.value(row, "tier"), 1));
    item["chainMode"] = "模拟链上凭证";
    item["shareTitle"] = "我在 TourPilot 解锁了「" + rows.value(row, "name") + "」";
    return item;
}

crow::json::wvalue redemption_json(const PgResult& rows, int row) {
    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["achievementId"] = to_int(rows.value(row, "achievement_id"));
    item["achievementName"] = rows.value(row, "achievement_name");
    item["status"] = rows.value(row, "status");
    item["statusLabel"] = redemption_status_label(rows.value(row, "status"));
    item["recipientName"] = rows.value(row, "recipient_name");
    item["phone"] = rows.value(row, "phone");
    item["address"] = rows.value(row, "address");
    item["note"] = rows.value(row, "note");
    item["createdAt"] = rows.value(row, "created_at");
    item["updatedAt"] = rows.value(row, "updated_at");
    return item;
}

crow::json::wvalue review_submission_json(const PgResult& rows, int row) {
    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["userId"] = to_int(rows.value(row, "user_id"));
    item["username"] = rows.value(row, "username");
    item["nickname"] = rows.value(row, "nickname");
    item["diaryId"] = to_int(rows.value(row, "diary_id"));
    item["diaryTitle"] = rows.value(row, "diary_title");
    item["contentLength"] = to_int(rows.value(row, "content_length"));
    item["imageCount"] = to_int(rows.value(row, "image_count"));
    item["spotCount"] = to_int(rows.value(row, "spot_count"));
    item["status"] = rows.value(row, "status");
    item["statusLabel"] = review_status_label(rows.value(row, "status"));
    item["reviewNote"] = rows.value(row, "reviewer_note");
    item["submittedAt"] = rows.value(row, "submitted_at");
    item["reviewedAt"] = rows.value(row, "reviewed_at");
    return item;
}

} // namespace

bool can_review_achievements(const AuthUser& user) {
    if (user.username == "demo_user") return true;
    const char* configured = std::getenv("TOURISM_REVIEWER_USERNAMES");
    if (!configured) return false;

    std::stringstream stream(configured);
    std::string item;
    while (std::getline(stream, item, ',')) {
        if (trim_text(item) == user.username) return true;
    }
    return false;
}

void ensure_achievement_schema(PgConnection& db) {
    exec_sql(db, "ALTER TABLE achievements ADD COLUMN IF NOT EXISTS code VARCHAR(80)", PGRES_COMMAND_OK);
    exec_sql(db, "ALTER TABLE achievements ADD COLUMN IF NOT EXISTS tier INTEGER DEFAULT 1", PGRES_COMMAND_OK);
    exec_sql(db, "ALTER TABLE achievements ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0", PGRES_COMMAND_OK);
    exec_sql(db, "ALTER TABLE achievements ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE", PGRES_COMMAND_OK);
    exec_sql(db, "UPDATE achievements SET code = 'legacy-' || id::text WHERE code IS NULL OR code = ''", PGRES_COMMAND_OK);
    exec_sql(db, "CREATE UNIQUE INDEX IF NOT EXISTS idx_achievements_code ON achievements(code)", PGRES_COMMAND_OK);

    exec_sql(db, R"SQL(
        CREATE TABLE IF NOT EXISTS user_scenic_checkins (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            scenic_spot_id INTEGER NOT NULL REFERENCES scenic_spots(id) ON DELETE CASCADE,
            latitude DECIMAL(10, 7),
            longitude DECIMAL(10, 7),
            verification VARCHAR(20) DEFAULT 'self' CHECK (verification IN ('gps', 'self')),
            distance_meters DECIMAL(10, 2),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, scenic_spot_id)
        )
    )SQL", PGRES_COMMAND_OK);

    exec_sql(db, R"SQL(
        CREATE TABLE IF NOT EXISTS achievement_review_submissions (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            diary_id INTEGER NOT NULL REFERENCES travel_diaries(id) ON DELETE CASCADE,
            status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
            reviewer_note TEXT,
            submitted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            reviewed_at TIMESTAMP WITH TIME ZONE,
            UNIQUE(user_id, diary_id)
        )
    )SQL", PGRES_COMMAND_OK);

    exec_sql(db, R"SQL(
        CREATE TABLE IF NOT EXISTS physical_badge_redemptions (
            id BIGSERIAL PRIMARY KEY,
            user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            achievement_id INTEGER NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
            recipient_name VARCHAR(80) NOT NULL,
            phone VARCHAR(40) NOT NULL,
            address TEXT NOT NULL,
            note TEXT,
            status VARCHAR(20) DEFAULT 'pending',
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(user_id, achievement_id)
        )
    )SQL", PGRES_COMMAND_OK);

    exec_sql(db, R"SQL(
        UPDATE physical_badge_redemptions
        SET status = CASE
            WHEN status IN ('processing', 'completed') THEN 'approved'
            WHEN status = 'cancelled' THEN 'rejected'
            WHEN status IS NULL OR status = '' THEN 'pending'
            ELSE status
        END
    )SQL", PGRES_COMMAND_OK);
    exec_sql(db, "ALTER TABLE physical_badge_redemptions DROP CONSTRAINT IF EXISTS physical_badge_redemptions_status_check", PGRES_COMMAND_OK);
    exec_sql(db, "ALTER TABLE physical_badge_redemptions ADD CONSTRAINT physical_badge_redemptions_status_check CHECK (status IN ('pending', 'approved', 'rejected', 'shipped'))", PGRES_COMMAND_OK);

    exec_sql(db, "CREATE INDEX IF NOT EXISTS idx_checkins_user ON user_scenic_checkins(user_id)", PGRES_COMMAND_OK);
    exec_sql(db, "CREATE INDEX IF NOT EXISTS idx_checkins_spot ON user_scenic_checkins(scenic_spot_id)", PGRES_COMMAND_OK);
    exec_sql(db, "CREATE INDEX IF NOT EXISTS idx_review_submissions_user ON achievement_review_submissions(user_id)", PGRES_COMMAND_OK);
    exec_sql(db, "CREATE INDEX IF NOT EXISTS idx_review_submissions_status ON achievement_review_submissions(status)", PGRES_COMMAND_OK);
    exec_sql(db, "CREATE INDEX IF NOT EXISTS idx_badge_redemptions_user ON physical_badge_redemptions(user_id)", PGRES_COMMAND_OK);
    exec_sql(db, "CREATE INDEX IF NOT EXISTS idx_badge_redemptions_status ON physical_badge_redemptions(status)", PGRES_COMMAND_OK);
}

void seed_default_achievements(PgConnection& db) {
    ensure_achievement_schema(db);
    exec_sql(db, seed_sql(), PGRES_COMMAND_OK);
}

void evaluate_user_achievements(PgConnection& db, int user_id) {
    if (user_id <= 0) return;
    seed_default_achievements(db);

    auto rows = exec_sql(db, R"SQL(
        SELECT id::text, code
        FROM achievements
        WHERE is_active = TRUE
        ORDER BY display_order, id
    )SQL");

    for (int row = 0; row < rows.rows(); ++row) {
        int id = to_int(rows.value(row, "id"));
        std::string code = rows.value(row, "code");
        auto rule = rule_for(code);

        int current = 0;
        int target = std::max(rule.target, 1);
        if (code == "passport-first-stamp") {
            current = std::min(checked_spot_count(db, user_id), target);
        } else if (code == "stamp-gugong") {
            current = has_checked_spot(db, user_id, "故宫") ? 1 : 0;
        } else if (code == "diary-memory-maker") {
            current = std::min(qualified_diary_count(db, user_id), target);
        } else if (code == "master-travel-writer") {
            current = std::min(approved_review_count(db, user_id), target);
        } else {
            current = static_cast<int>(checked_theme_spots(db, user_id, rule.spots).size());
        }

        int percent = std::max(0, std::min(100, static_cast<int>(std::round(current * 100.0 / target))));
        std::string status = percent >= 100 ? "unlocked" : percent > 0 ? "in_progress" : "locked";
        std::string progress = progress_json(current, target, percent, progress_label_for(code, current, target));

        exec_params(db, R"SQL(
            INSERT INTO user_achievements (user_id, achievement_id, progress, status, unlocked_at)
            VALUES ($1::bigint, $2::int, $3::jsonb, $4::varchar(20),
                    CASE WHEN $4::varchar(20) = 'unlocked' THEN CURRENT_TIMESTAMP ELSE NULL END)
            ON CONFLICT (user_id, achievement_id) DO UPDATE SET
                progress = EXCLUDED.progress,
                status = CASE
                    WHEN user_achievements.status = 'unlocked' THEN 'unlocked'
                    ELSE EXCLUDED.status
                END,
                unlocked_at = CASE
                    WHEN user_achievements.unlocked_at IS NOT NULL THEN user_achievements.unlocked_at
                    WHEN EXCLUDED.status = 'unlocked' THEN CURRENT_TIMESTAMP
                    ELSE NULL
                END
        )SQL", {std::to_string(user_id), std::to_string(id), progress, status}, PGRES_COMMAND_OK);
    }
}

crow::json::wvalue achievements_overview(PgConnection& db, std::optional<int> user_id) {
    seed_default_achievements_if_missing(db);
    if (user_id) evaluate_user_achievements(db, *user_id);

    std::string user_id_text = user_id ? std::to_string(*user_id) : "0";
    auto rows = exec_params(db, R"SQL(
        SELECT a.id::text, a.code, a.name, a.description, COALESCE(a.icon_url, '') AS icon_url,
               a.level::text, a.type, a.tier::text, a.display_order::text,
               COALESCE(a.reward::text, '{}') AS reward,
               COALESCE(ua.status, 'locked') AS status,
               COALESCE(ua.unlocked_at::text, '') AS unlocked_at,
               COALESCE(ua.progress->>'current', '0') AS progress_current,
               COALESCE(ua.progress->>'target', '1') AS progress_target,
               COALESCE(ua.progress->>'percent', '0') AS progress_percent,
               COALESCE(ua.progress->>'label', '登录后开始收集旅行印章') AS progress_label,
               COALESCE(dc.id::text, '') AS collectible_id,
               COALESCE(dc.token_id, '') AS token_id,
               COALESCE(pbr.status, '') AS redemption_status
        FROM achievements a
        LEFT JOIN user_achievements ua ON ua.achievement_id = a.id AND ua.user_id = $1::bigint
        LEFT JOIN digital_collectibles dc ON dc.achievement_id = a.id AND dc.user_id = $1::bigint
        LEFT JOIN physical_badge_redemptions pbr ON pbr.achievement_id = a.id AND pbr.user_id = $1::bigint
        WHERE a.is_active = TRUE
        ORDER BY a.display_order, a.id
    )SQL", {user_id_text});

    crow::json::wvalue::list items;
    int unlocked_count = 0;
    int collectible_count = 0;
    for (int row = 0; row < rows.rows(); ++row) {
        std::string status = rows.value(row, "status");
        if (status == "unlocked") ++unlocked_count;
        if (!rows.value(row, "collectible_id").empty()) ++collectible_count;

        std::string code = rows.value(row, "code");
        int tier = to_int(rows.value(row, "tier"), 1);
        auto rule = rule_for(code);
        auto checked = user_id ? checked_theme_spots(db, *user_id, rule.spots) : std::vector<std::string>{};
        auto missing = missing_theme_spots(rule.spots, checked);

        crow::json::wvalue item;
        item["id"] = to_int(rows.value(row, "id"));
        item["code"] = code;
        item["name"] = rows.value(row, "name");
        item["description"] = rows.value(row, "description");
        item["iconUrl"] = rows.value(row, "icon_url");
        item["level"] = "Lv." + rows.value(row, "level");
        item["type"] = rows.value(row, "type");
        item["tier"] = tier;
        item["tierLabel"] = tier_label(tier);
        item["progress"] = progress_value(rows, row);
        item["progressPercent"] = to_int(rows.value(row, "progress_percent"));
        item["status"] = status;
        item["statusLabel"] = status_label(status);
        item["unlockedAt"] = rows.value(row, "unlocked_at");
        item["rewardText"] = tier >= 2 ? "数字纪念凭证 + 实体徽章资格" : "数字纪念凭证";
        item["hasPhysicalBadge"] = tier >= 2;
        item["collectibleId"] = rows.value(row, "collectible_id").empty() ? 0 : to_int(rows.value(row, "collectible_id"));
        item["tokenId"] = rows.value(row, "token_id");
        item["redemptionStatus"] = rows.value(row, "redemption_status");
        item["redemptionStatusLabel"] = redemption_status_label(rows.value(row, "redemption_status"));
        item["requiredSpots"] = string_list(rule.spots);
        item["checkedSpots"] = string_list(checked);
        item["missingSpots"] = string_list(missing);
        item["nextAction"] = next_action_for(code, status, missing);
        items.push_back(std::move(item));
    }

    auto collectibles = user_id ? user_collectibles(db, *user_id) : crow::json::wvalue{};
    auto redemptions = user_id ? user_badge_redemptions(db, *user_id) : crow::json::wvalue{};

    crow::json::wvalue data;
    data["authenticated"] = user_id.has_value();
    data["total"] = rows.rows();
    data["unlocked"] = unlocked_count;
    data["collectibleCount"] = collectible_count;
    data["items"] = std::move(items);
    data["collectibles"] = user_id ? std::move(collectibles["items"]) : crow::json::wvalue::list{};
    data["redemptionHistory"] = user_id ? std::move(redemptions["items"]) : crow::json::wvalue::list{};
    data["passport"]["title"] = "TourPilot 旅行护照";
    data["passport"]["summary"] = "打卡景点、完成主题、写下旅行日记，收集数字纪念凭证与实体徽章资格。";
    data["algorithm"] = "rule-based passport achievements";
    return data;
}

crow::json::wvalue create_scenic_checkin(PgConnection& db, int user_id, int scenic_spot_id, const CheckinInput& input) {
    seed_default_achievements(db);
    evaluate_user_achievements(db, user_id);
    auto before = unlocked_codes(db, user_id);

    auto spot_rows = exec_params(db, R"SQL(
        SELECT id::text, name,
               ST_Y(location::geometry)::text AS latitude,
               ST_X(location::geometry)::text AS longitude
        FROM scenic_spots
        WHERE id = $1 AND status = 1
        LIMIT 1
    )SQL", {std::to_string(scenic_spot_id)});
    if (!spot_rows.rows()) throw std::runtime_error("景点不存在或不可打卡");

    double spot_lat = to_double(spot_rows.value(0, "latitude"));
    double spot_lng = to_double(spot_rows.value(0, "longitude"));
    double distance = 0.0;
    std::string verification = "self";
    if (input.has_location) {
        distance = haversine_meters(input.latitude, input.longitude, spot_lat, spot_lng);
        if (distance <= 1500.0) verification = "gps";
    }

    auto rows = exec_params(db, R"SQL(
        INSERT INTO user_scenic_checkins (user_id, scenic_spot_id, latitude, longitude, verification, distance_meters)
        VALUES ($1::bigint, $2::int, NULLIF($3, '')::numeric, NULLIF($4, '')::numeric, $5::varchar(20), NULLIF($6, '')::numeric)
        ON CONFLICT (user_id, scenic_spot_id) DO UPDATE SET
            latitude = COALESCE(EXCLUDED.latitude, user_scenic_checkins.latitude),
            longitude = COALESCE(EXCLUDED.longitude, user_scenic_checkins.longitude),
            verification = CASE
                WHEN user_scenic_checkins.verification = 'gps' THEN 'gps'
                ELSE EXCLUDED.verification
            END,
            distance_meters = COALESCE(EXCLUDED.distance_meters, user_scenic_checkins.distance_meters)
        RETURNING id::text, verification, COALESCE(distance_meters, 0)::text, created_at::text
    )SQL", {
        std::to_string(user_id),
        std::to_string(scenic_spot_id),
        input.has_location ? std::to_string(input.latitude) : "",
        input.has_location ? std::to_string(input.longitude) : "",
        verification,
        input.has_location ? std::to_string(distance) : ""
    });

    evaluate_user_achievements(db, user_id);

    auto after_rows = exec_params(db, R"SQL(
        SELECT a.code, a.name
        FROM user_achievements ua
        JOIN achievements a ON a.id = ua.achievement_id
        WHERE ua.user_id = $1 AND ua.status = 'unlocked'
        ORDER BY a.display_order, a.id
    )SQL", {std::to_string(user_id)});

    crow::json::wvalue::list unlocked;
    for (int row = 0; row < after_rows.rows(); ++row) {
        if (before.find(after_rows.value(row, "code")) != before.end()) continue;
        crow::json::wvalue item;
        item["code"] = after_rows.value(row, "code");
        item["name"] = after_rows.value(row, "name");
        unlocked.push_back(std::move(item));
    }

    crow::json::wvalue data;
    data["id"] = to_int(rows.value(0, "id"));
    data["scenicSpotId"] = scenic_spot_id;
    data["scenicName"] = spot_rows.value(0, "name");
    data["verification"] = rows.value(0, "verification");
    data["verificationLabel"] = rows.value(0, "verification") == "gps" ? "GPS 定位验证" : "演示打卡";
    data["distanceMeters"] = to_double(rows.value(0, "distance_meters"));
    data["createdAt"] = rows.value(0, "created_at");
    data["unlockedAchievements"] = std::move(unlocked);
    data["message"] = rows.value(0, "verification") == "gps" ? "定位校验通过，旅行印章已收集" : "已用演示打卡收集旅行印章";
    return data;
}

crow::json::wvalue claim_achievement_reward(PgConnection& db, int user_id, int achievement_id) {
    seed_default_achievements(db);
    evaluate_user_achievements(db, user_id);

    auto achievement = exec_params(db, R"SQL(
        SELECT a.id::text, a.code, a.name, a.description, a.tier::text,
               COALESCE(ua.status, 'locked') AS status
        FROM achievements a
        LEFT JOIN user_achievements ua ON ua.achievement_id = a.id AND ua.user_id = $1
        WHERE a.id = $2 AND a.is_active = TRUE
        LIMIT 1
    )SQL", {std::to_string(user_id), std::to_string(achievement_id)});
    if (!achievement.rows()) throw std::runtime_error("成就不存在");
    if (achievement.value(0, "status") != "unlocked") throw std::runtime_error("成就尚未解锁，不能领取奖励");

    auto existing = exec_params(db, R"SQL(
        SELECT dc.id::text, dc.achievement_id::text, COALESCE(dc.diary_id, 0)::text AS diary_id,
               dc.token_id, dc.name, dc.description, COALESCE(dc.image_url, '') AS image_url,
               COALESCE(dc.blockchain_hash, '') AS blockchain_hash,
               COALESCE(dc.minted_at::text, '') AS minted_at, dc.created_at::text,
               a.name AS achievement_name, a.code AS achievement_code, a.tier::text
        FROM digital_collectibles dc
        LEFT JOIN achievements a ON a.id = dc.achievement_id
        WHERE dc.user_id = $1 AND dc.achievement_id = $2
        LIMIT 1
    )SQL", {std::to_string(user_id), std::to_string(achievement_id)});
    if (existing.rows()) return collectible_json(existing, 0);

    std::string token = "TP-" + achievement.value(0, "code") + "-" + std::to_string(user_id) + "-" + generate_token().substr(0, 8);
    std::string hash = "sim-" + generate_token();
    std::string metadata = "{\"demo\":true,\"chainMode\":\"simulated\",\"achievementCode\":\"" +
                           json_escape(achievement.value(0, "code")) + "\",\"tier\":" + achievement.value(0, "tier") + "}";

    auto rows = exec_params(db, R"SQL(
        INSERT INTO digital_collectibles
            (user_id, achievement_id, token_id, name, description, image_url, metadata, blockchain_hash, minted_at)
        VALUES
            ($1::bigint, $2::int, $3::varchar(100), $4::varchar(200), $5::text, '', $6::jsonb, $7::varchar(200), CURRENT_TIMESTAMP)
        RETURNING id::text, achievement_id::text, COALESCE(diary_id, 0)::text AS diary_id,
                  token_id, name, description, COALESCE(image_url, '') AS image_url,
                  blockchain_hash, minted_at::text, created_at::text,
                  name AS achievement_name, $8::text AS achievement_code, $9::text AS tier
    )SQL", {
        std::to_string(user_id),
        std::to_string(achievement_id),
        token,
        achievement.value(0, "name") + "数字纪念凭证",
        achievement.value(0, "description"),
        metadata,
        hash,
        achievement.value(0, "code"),
        achievement.value(0, "tier")
    });
    return collectible_json(rows, 0);
}

crow::json::wvalue user_collectibles(PgConnection& db, int user_id) {
    ensure_achievement_schema(db);
    auto rows = exec_params(db, R"SQL(
        SELECT dc.id::text, COALESCE(dc.achievement_id, 0)::text AS achievement_id,
               COALESCE(dc.diary_id, 0)::text AS diary_id,
               dc.token_id, dc.name, COALESCE(dc.description, '') AS description,
               COALESCE(dc.image_url, '') AS image_url,
               COALESCE(dc.blockchain_hash, '') AS blockchain_hash,
               COALESCE(dc.minted_at::text, '') AS minted_at,
               dc.created_at::text,
               COALESCE(a.name, '') AS achievement_name,
               COALESCE(a.code, '') AS achievement_code,
               COALESCE(a.tier, 1)::text AS tier
        FROM digital_collectibles dc
        LEFT JOIN achievements a ON a.id = dc.achievement_id
        WHERE dc.user_id = $1
        ORDER BY dc.created_at DESC, dc.id DESC
    )SQL", {std::to_string(user_id)});

    crow::json::wvalue::list items;
    for (int row = 0; row < rows.rows(); ++row) items.push_back(collectible_json(rows, row));
    crow::json::wvalue data;
    data["total"] = static_cast<int>(items.size());
    data["items"] = std::move(items);
    return data;
}

crow::json::wvalue collectible_detail(PgConnection& db, int user_id, int collectible_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT dc.id::text, COALESCE(dc.achievement_id, 0)::text AS achievement_id,
               COALESCE(dc.diary_id, 0)::text AS diary_id,
               dc.token_id, dc.name, COALESCE(dc.description, '') AS description,
               COALESCE(dc.image_url, '') AS image_url,
               COALESCE(dc.blockchain_hash, '') AS blockchain_hash,
               COALESCE(dc.minted_at::text, '') AS minted_at,
               dc.created_at::text,
               COALESCE(a.name, '') AS achievement_name,
               COALESCE(a.code, '') AS achievement_code,
               COALESCE(a.tier, 1)::text AS tier
        FROM digital_collectibles dc
        LEFT JOIN achievements a ON a.id = dc.achievement_id
        WHERE dc.user_id = $1 AND dc.id = $2
        LIMIT 1
    )SQL", {std::to_string(user_id), std::to_string(collectible_id)});
    if (!rows.rows()) throw std::runtime_error("数字纪念凭证不存在");
    return collectible_json(rows, 0);
}

crow::json::wvalue create_badge_redemption(PgConnection& db, int user_id, const BadgeRedemptionInput& input) {
    if (input.achievement_id <= 0) throw std::runtime_error("achievementId required");
    if (trim_text(input.recipient_name).empty() || trim_text(input.phone).empty() || trim_text(input.address).empty()) {
        throw std::runtime_error("请填写收件人、电话和地址");
    }

    seed_default_achievements(db);
    evaluate_user_achievements(db, user_id);
    auto eligible = exec_params(db, R"SQL(
        SELECT a.id::text, a.name, COALESCE(ua.status, 'locked') AS status, a.tier::text
        FROM achievements a
        LEFT JOIN user_achievements ua ON ua.achievement_id = a.id AND ua.user_id = $1
        WHERE a.id = $2 AND a.tier >= 2
        LIMIT 1
    )SQL", {std::to_string(user_id), std::to_string(input.achievement_id)});
    if (!eligible.rows()) throw std::runtime_error("该成就没有实体徽章兑换资格");
    if (eligible.value(0, "status") != "unlocked") throw std::runtime_error("成就尚未解锁，不能申请实体徽章");

    auto rows = exec_params(db, R"SQL(
        INSERT INTO physical_badge_redemptions
            (user_id, achievement_id, recipient_name, phone, address, note)
        VALUES ($1::bigint, $2::int, $3::varchar(80), $4::varchar(40), $5::text, $6::text)
        ON CONFLICT (user_id, achievement_id) DO UPDATE SET
            recipient_name = EXCLUDED.recipient_name,
            phone = EXCLUDED.phone,
            address = EXCLUDED.address,
            note = EXCLUDED.note,
            updated_at = CURRENT_TIMESTAMP
        RETURNING id::text, achievement_id::text, status, recipient_name, phone, address,
                  COALESCE(note, '') AS note, created_at::text, updated_at::text,
                  $7 AS achievement_name
    )SQL", {
        std::to_string(user_id),
        std::to_string(input.achievement_id),
        trim_text(input.recipient_name),
        trim_text(input.phone),
        trim_text(input.address),
        trim_text(input.note),
        eligible.value(0, "name")
    });

    return redemption_json(rows, 0);
}

crow::json::wvalue user_badge_redemptions(PgConnection& db, int user_id) {
    ensure_achievement_schema(db);
    auto rows = exec_params(db, R"SQL(
        SELECT pbr.id::text, pbr.achievement_id::text, a.name AS achievement_name,
               pbr.status, pbr.recipient_name, pbr.phone, pbr.address,
               COALESCE(pbr.note, '') AS note,
               pbr.created_at::text, pbr.updated_at::text
        FROM physical_badge_redemptions pbr
        JOIN achievements a ON a.id = pbr.achievement_id
        WHERE pbr.user_id = $1
        ORDER BY pbr.updated_at DESC, pbr.id DESC
    )SQL", {std::to_string(user_id)});

    crow::json::wvalue::list items;
    for (int row = 0; row < rows.rows(); ++row) items.push_back(redemption_json(rows, row));
    crow::json::wvalue data;
    data["total"] = static_cast<int>(items.size());
    data["items"] = std::move(items);
    return data;
}

crow::json::wvalue submit_achievement_review(PgConnection& db, int user_id, int diary_id) {
    seed_default_achievements(db);
    auto diary = exec_params(db, R"SQL(
        SELECT id::text, title, char_length(COALESCE(content, ''))::text AS content_length,
               COALESCE(cardinality(images), 0)::text AS image_count,
               COALESCE(cardinality(scenic_spot_ids), 0)::text AS spot_count
        FROM travel_diaries
        WHERE id = $1 AND user_id = $2 AND status = 1
        LIMIT 1
    )SQL", {std::to_string(diary_id), std::to_string(user_id)});
    if (!diary.rows()) throw std::runtime_error("只能提交自己的公开游记");
    if (to_int(diary.value(0, "content_length")) < 120 ||
        to_int(diary.value(0, "image_count")) < 1 ||
        to_int(diary.value(0, "spot_count")) < 1) {
        throw std::runtime_error("游记需要包含景点、图片和较完整的体验记录后才能提交评审");
    }

    auto rows = exec_params(db, R"SQL(
        INSERT INTO achievement_review_submissions (user_id, diary_id, status)
        VALUES ($1::bigint, $2::int, 'pending')
        ON CONFLICT (user_id, diary_id) DO UPDATE SET
            status = CASE
                WHEN achievement_review_submissions.status = 'approved' THEN 'approved'
                ELSE 'pending'
            END,
            reviewer_note = CASE
                WHEN achievement_review_submissions.status = 'approved' THEN achievement_review_submissions.reviewer_note
                ELSE NULL
            END,
            reviewed_at = CASE
                WHEN achievement_review_submissions.status = 'approved' THEN achievement_review_submissions.reviewed_at
                ELSE NULL
            END,
            submitted_at = CURRENT_TIMESTAMP
        RETURNING id::text, user_id::text, diary_id::text, status,
                  COALESCE(reviewer_note, '') AS reviewer_note,
                  submitted_at::text, COALESCE(reviewed_at::text, '') AS reviewed_at,
                  $3 AS username, $3 AS nickname, $4 AS diary_title,
                  $5 AS content_length, $6 AS image_count, $7 AS spot_count
    )SQL", {
        std::to_string(user_id),
        std::to_string(diary_id),
        "",
        diary.value(0, "title"),
        diary.value(0, "content_length"),
        diary.value(0, "image_count"),
        diary.value(0, "spot_count")
    });

    evaluate_user_achievements(db, user_id);
    return review_submission_json(rows, 0);
}

crow::json::wvalue review_submissions(PgConnection& db, const std::string& status) {
    ensure_achievement_schema(db);
    std::string normalized = status == "pending" || status == "approved" || status == "rejected" ? status : "";
    auto rows = exec_params(db, R"SQL(
        SELECT ars.id::text, ars.user_id::text, u.username, COALESCE(u.nickname, u.username) AS nickname,
               ars.diary_id::text, d.title AS diary_title,
               char_length(COALESCE(d.content, ''))::text AS content_length,
               COALESCE(cardinality(d.images), 0)::text AS image_count,
               COALESCE(cardinality(d.scenic_spot_ids), 0)::text AS spot_count,
               ars.status, COALESCE(ars.reviewer_note, '') AS reviewer_note,
               ars.submitted_at::text, COALESCE(ars.reviewed_at::text, '') AS reviewed_at
        FROM achievement_review_submissions ars
        JOIN users u ON u.id = ars.user_id
        JOIN travel_diaries d ON d.id = ars.diary_id
        WHERE ($1::varchar(20) = '' OR ars.status = $1::varchar(20))
        ORDER BY
            CASE ars.status WHEN 'pending' THEN 0 WHEN 'approved' THEN 1 ELSE 2 END,
            ars.submitted_at DESC,
            ars.id DESC
    )SQL", {normalized});

    crow::json::wvalue::list items;
    for (int row = 0; row < rows.rows(); ++row) items.push_back(review_submission_json(rows, row));
    crow::json::wvalue data;
    data["total"] = static_cast<int>(items.size());
    data["items"] = std::move(items);
    return data;
}

crow::json::wvalue decide_review_submission(PgConnection& db, int submission_id, const ReviewDecisionInput& input) {
    std::string status = trim_text(input.status);
    if (status != "approved" && status != "rejected") {
        throw std::runtime_error("status must be approved or rejected");
    }

    auto rows = exec_params(db, R"SQL(
        UPDATE achievement_review_submissions
        SET status = $2::varchar(20),
            reviewer_note = NULLIF($3, ''),
            reviewed_at = CURRENT_TIMESTAMP
        WHERE id = $1
        RETURNING id::text, user_id::text
    )SQL", {
        std::to_string(submission_id),
        status,
        trim_text(input.review_note)
    });
    if (!rows.rows()) throw std::runtime_error("评审记录不存在");

    int user_id = to_int(rows.value(0, "user_id"));
    evaluate_user_achievements(db, user_id);

    auto detail = exec_params(db, R"SQL(
        SELECT ars.id::text, ars.user_id::text, u.username, COALESCE(u.nickname, u.username) AS nickname,
               ars.diary_id::text, d.title AS diary_title,
               char_length(COALESCE(d.content, ''))::text AS content_length,
               COALESCE(cardinality(d.images), 0)::text AS image_count,
               COALESCE(cardinality(d.scenic_spot_ids), 0)::text AS spot_count,
               ars.status, COALESCE(ars.reviewer_note, '') AS reviewer_note,
               ars.submitted_at::text, COALESCE(ars.reviewed_at::text, '') AS reviewed_at
        FROM achievement_review_submissions ars
        JOIN users u ON u.id = ars.user_id
        JOIN travel_diaries d ON d.id = ars.diary_id
        WHERE ars.id = $1
        LIMIT 1
    )SQL", {std::to_string(submission_id)});
    return review_submission_json(detail, 0);
}

} // namespace tourism::services
