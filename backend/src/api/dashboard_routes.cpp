#include "api/dashboard_routes.h"

#include "db/postgres.h"
#include "services/auth_service.h"
#include "support/api_helpers.h"

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::PgResult;
using tourism::db::exec_params;
using tourism::db::exec_sql;
using tourism::services::current_user;
using tourism::support::first_nonempty;
using tourism::support::json_error;
using tourism::support::ok;
using tourism::support::string_list;
using tourism::support::to_int;

crow::json::wvalue achievement_json(const PgResult& rows, int row) {
    std::string status = rows.value(row, "status");
    int progress = status == "unlocked" ? 100 : status == "in_progress" ? 60 : 20;

    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["name"] = rows.value(row, "name");
    item["level"] = "Lv." + first_nonempty({rows.value(row, "level")}, "1");
    item["progress"] = progress;
    item["status"] = status == "unlocked" ? "已解锁" : status == "in_progress" ? "进行中" : "未解锁";
    item["description"] = rows.value(row, "description");
    return item;
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
            stats.push_back(crow::json::wvalue{{"label", "数据库景点"}, {"value", rows.value(0, "scenic_count")}, {"detail", "来自 scenic_spots 表"}});
            stats.push_back(crow::json::wvalue{{"label", "路线边数"}, {"value", rows.value(0, "edge_count")}, {"detail", "来自 graph_edges 表"}});
            stats.push_back(crow::json::wvalue{{"label", "旅行日记"}, {"value", rows.value(0, "diary_count")}, {"detail", "支持数据库保存"}});
            stats.push_back(crow::json::wvalue{{"label", "成就徽章"}, {"value", rows.value(0, "achievement_count")}, {"detail", "来自 achievements 表"}});

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
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, R"SQL(
                SELECT a.id::text, a.name, a.description, a.level::text,
                       COALESCE(ua.status, 'locked') AS status
                FROM achievements a
                LEFT JOIN user_achievements ua ON ua.achievement_id = a.id AND ua.user_id = $1
                ORDER BY a.id
            )SQL", {std::to_string(user->id)});
            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(achievement_json(rows, row));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
