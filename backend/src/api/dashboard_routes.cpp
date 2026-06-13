#include "api/dashboard_routes.h"

#include "db/postgres.h"
#include "support/api_helpers.h"

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_sql;
using tourism::support::json_error;
using tourism::support::ok;
using tourism::support::string_list;

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
                    (SELECT COUNT(*) FROM travel_diaries WHERE status <> 2)::text AS diary_count
            )SQL");

            crow::json::wvalue::list stats;
            stats.push_back(crow::json::wvalue{{"label", "景点数据"}, {"value", rows.value(0, "scenic_count")}, {"detail", "来自 scenic_spots 表"}});
            stats.push_back(crow::json::wvalue{{"label", "路线边数"}, {"value", rows.value(0, "edge_count")}, {"detail", "来自 graph_edges 表"}});
            stats.push_back(crow::json::wvalue{{"label", "旅行日记"}, {"value", rows.value(0, "diary_count")}, {"detail", "支持数据库持久化"}});

            crow::json::wvalue data;
            data["stats"] = std::move(stats);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
