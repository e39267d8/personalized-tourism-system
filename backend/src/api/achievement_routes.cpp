#include "api/achievement_routes.h"

#include "db/postgres.h"
#include "services/achievement_service.h"
#include "services/auth_service.h"
#include "services/badge_image_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <optional>
#include <string>
#include <utility>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::db::exec_sql;
using tourism::services::BadgeRedemptionInput;
using tourism::services::BadgeImageRequest;
using tourism::services::CheckinInput;
using tourism::services::ReviewDecisionInput;
using tourism::services::achievements_overview;
using tourism::services::can_review_achievements;
using tourism::services::claim_achievement_reward;
using tourism::services::collectible_detail;
using tourism::services::create_badge_redemption;
using tourism::services::create_scenic_checkin;
using tourism::services::current_user;
using tourism::services::decide_review_submission;
using tourism::services::generate_badge_image;
using tourism::services::review_submissions;
using tourism::services::submit_achievement_review;
using tourism::services::user_badge_redemptions;
using tourism::services::user_collectibles;
using tourism::support::json_error;
using tourism::support::json_string;
using tourism::support::ok;
using tourism::support::to_double;

std::string json_number_text(const crow::json::rvalue& body, const char* key) {
    if (!body || !body.has(key)) return "";
    try {
        return std::to_string(body[key].d());
    } catch (...) {
    }
    try {
        return std::to_string(body[key].i());
    } catch (...) {
    }
    try {
        return static_cast<std::string>(body[key].s());
    } catch (...) {
    }
    return "";
}

} // namespace

void register_achievement_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/achievements")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            std::optional<int> user_id;
            if (user) user_id = user->id;
            return crow::response(ok(achievements_overview(db, user_id)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>/checkins").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto body = crow::json::load(req.body);
            CheckinInput input;
            if (body) {
                std::string lat = json_number_text(body, "latitude");
                std::string lng = json_number_text(body, "longitude");
                if (lat.empty()) lat = json_number_text(body, "lat");
                if (lng.empty()) lng = json_number_text(body, "lng");
                if (!lat.empty() && !lng.empty()) {
                    input.has_location = true;
                    input.latitude = to_double(lat);
                    input.longitude = to_double(lng);
                }
            }

            return crow::response(201, ok(create_scenic_checkin(db, user->id, id, input)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/achievements/<int>/claim").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            return crow::response(ok(claim_achievement_reward(db, user->id, id)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/collectibles")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            return crow::response(ok(user_collectibles(db, user->id)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/collectibles/<int>/badge-image").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            exec_sql(db, "ALTER TABLE digital_collectibles ALTER COLUMN image_url TYPE TEXT", PGRES_COMMAND_OK);

            auto rows = exec_params(db, R"SQL(
                SELECT dc.id::text, dc.name, COALESCE(dc.description, '') AS description,
                       COALESCE(dc.image_url, '') AS image_url,
                       COALESCE(a.name, '') AS achievement_name,
                       COALESCE(a.code, '') AS achievement_code,
                       COALESCE(a.tier, 1)::text AS tier
                FROM digital_collectibles dc
                LEFT JOIN achievements a ON a.id = dc.achievement_id
                WHERE dc.user_id = $1 AND dc.id = $2
                LIMIT 1
            )SQL", {std::to_string(user->id), std::to_string(id)});
            if (!rows.rows()) return json_error(404, "数字纪念凭证不存在");

            std::string existing = rows.value(0, "image_url");
            if (!existing.empty()) {
                crow::json::wvalue data;
                data["id"] = id;
                data["imageUrl"] = existing;
                data["provider"] = "existing";
                return crow::response(ok(std::move(data)));
            }

            BadgeImageRequest input;
            input.collectible_name = rows.value(0, "name");
            input.description = rows.value(0, "description");
            input.achievement_name = rows.value(0, "achievement_name").empty() ? input.collectible_name : rows.value(0, "achievement_name");
            input.achievement_code = rows.value(0, "achievement_code");
            input.tier = std::max(1, std::stoi(rows.value(0, "tier")));

            auto generated = generate_badge_image(input);
            exec_params(db, R"SQL(
                UPDATE digital_collectibles
                SET image_url = $2,
                    metadata = COALESCE(metadata, '{}'::jsonb) || jsonb_build_object(
                        'badgePrompt', $3::text,
                        'badgeProvider', $4::text,
                        'badgeModel', $5::text,
                        'badgeTaskId', $6::text,
                        'badgeStatus', $7::text,
                        'badgeError', $8::text
                    )
                WHERE id = $1
            )SQL", {
                std::to_string(id),
                generated.image_url,
                generated.prompt,
                generated.provider,
                generated.model,
                generated.task_id,
                generated.status,
                generated.error
            }, PGRES_COMMAND_OK);

            crow::json::wvalue data;
            data["id"] = id;
            data["imageUrl"] = generated.image_url;
            data["prompt"] = generated.prompt;
            data["provider"] = generated.provider;
            data["model"] = generated.model;
            data["taskId"] = generated.task_id;
            data["status"] = generated.status;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/collectibles/<int>")([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            return crow::response(ok(collectible_detail(db, user->id, id)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/badge-redemptions").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            BadgeRedemptionInput input;
            input.achievement_id = body.has("achievementId") ? static_cast<int>(body["achievementId"].i()) : 0;
            input.recipient_name = json_string(body, "recipientName");
            input.phone = json_string(body, "phone");
            input.address = json_string(body, "address");
            input.note = json_string(body, "note");

            return crow::response(201, ok(create_badge_redemption(db, user->id, input)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/badge-redemptions")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            return crow::response(ok(user_badge_redemptions(db, user->id)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>/achievement-review").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            return crow::response(201, ok(submit_achievement_review(db, user->id, id)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/achievement-review-submissions")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            if (!can_review_achievements(*user)) return json_error(403, "没有成就评审权限");

            std::string status;
            if (auto raw = req.url_params.get("status")) status = raw;
            return crow::response(ok(review_submissions(db, status)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/achievement-review-submissions/<int>/decision").methods("POST"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            if (!can_review_achievements(*user)) return json_error(403, "没有成就评审权限");

            ReviewDecisionInput input;
            input.status = json_string(body, "status");
            input.review_note = json_string(body, "reviewNote");
            return crow::response(ok(decide_review_submission(db, id, input)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
