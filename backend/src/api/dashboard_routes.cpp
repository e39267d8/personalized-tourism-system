#include "api/dashboard_routes.h"

#include "db/postgres.h"
#include "services/achievement_service.h"
#include "services/auth_service.h"
#include "support/api_helpers.h"

#include <optional>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_sql;
using tourism::services::BadgeRedemptionInput;
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
using tourism::services::review_submissions;
using tourism::services::user_badge_redemptions;
using tourism::services::user_collectibles;
using tourism::support::json_error;
using tourism::support::json_string;
using tourism::support::ok;
using tourism::support::string_list;
using tourism::support::to_double;
using tourism::support::to_int;

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

void register_dashboard_routes(TourismApp& app) {
    CROW_ROUTE(app, "/health")([] {
        crow::json::wvalue data;
        data["status"] = "ok";
        data["message"] = "Personalized Tourism System API is running";
        data["version"] = "1.2.0";
        try {
            PgConnection db;
            exec_sql(db, "SELECT 1");
            data["database"] = "connected";
        } catch (const std::exception& error) {
            data["database"] = "error";
            data["databaseError"] = error.what();
        }
        return data;
    });

    CROW_ROUTE(app, "/")([] {
        crow::json::wvalue data;
        data["name"] = "Personalized Tourism System API";
        data["version"] = "1.2.0";
        data["database"] = "PostgreSQL/PostGIS";
        data["endpoints"] = string_list({
            "/api/v1/dashboard",
            "/api/v1/scenic-spots",
            "/api/v1/scenic-categories",
            "/api/v1/recommendations/personalized",
            "/api/v1/profile/preferences",
            "/api/v1/budget-plans",
            "/api/v1/routes",
            "/api/v1/diaries",
            "/api/v1/achievements",
            "/api/v1/collectibles",
            "/api/v1/badge-redemptions",
            "/api/v1/achievement-review-submissions",
            "/api/v1/profile"
        });
        return data;
    });

    CROW_ROUTE(app, "/api/v1/dashboard")([]() -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_sql(db, R"SQL(
                SELECT
                    (SELECT COUNT(*) FROM scenic_spots WHERE status = 1)::text AS scenic_count,
                    (SELECT COUNT(*) FROM graph_edges)::text AS edge_count,
                    (SELECT COUNT(*) FROM travel_diaries WHERE status <> 2)::text AS diary_count,
                    (SELECT COUNT(*) FROM achievements)::text AS achievement_count
            )SQL");

            crow::json::wvalue::list stats;
            stats.push_back(crow::json::wvalue{{"label", "景点数据"}, {"value", rows.value(0, "scenic_count")}, {"detail", "来自 scenic_spots 表"}});
            stats.push_back(crow::json::wvalue{{"label", "路线边数"}, {"value", rows.value(0, "edge_count")}, {"detail", "来自 graph_edges 表"}});
            stats.push_back(crow::json::wvalue{{"label", "旅行日记"}, {"value", rows.value(0, "diary_count")}, {"detail", "支持数据库持久化"}});
            stats.push_back(crow::json::wvalue{{"label", "成就徽章"}, {"value", rows.value(0, "achievement_count")}, {"detail", "旅行护照与数字纪念凭证"}});

            crow::json::wvalue data;
            data["stats"] = std::move(stats);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

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
