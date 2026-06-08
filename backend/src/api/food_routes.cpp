#include "api/food_routes.h"

#include "db/postgres.h"
#include "services/food_service.h"
#include "support/api_helpers.h"

#include <set>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::db::exec_sql;
using tourism::services::FoodQuery;
using tourism::services::FoodScore;
using tourism::services::cuisine_label;
using tourism::services::food_json;
using tourism::services::query_food_items;
using tourism::services::rank_foods;
using tourism::support::json_error;
using tourism::support::ok;
using tourism::support::query_int;
using tourism::support::to_double;
using tourism::support::trim_text;

crow::json::wvalue ranked_food_json(const FoodScore& ranked) {
    crow::json::wvalue item = food_json(ranked.food);
    item["score"] = ranked.score;
    item["matchReason"] = ranked.match_reason;
    return item;
}

std::string normalize_food_sort(const std::string& value) {
    if (value == "rating" || value == "distance") return value;
    return "hot";
}

bool load_scenic_center(PgConnection& db, int scenic_spot_id, double& latitude, double& longitude) {
    if (scenic_spot_id <= 0) return false;
    auto rows = exec_params(db, R"SQL(
        SELECT ST_X(location::geometry)::text AS longitude,
               ST_Y(location::geometry)::text AS latitude
        FROM scenic_spots
        WHERE id = $1 AND location IS NOT NULL
        LIMIT 1
    )SQL", {std::to_string(scenic_spot_id)});
    if (!rows.rows()) return false;
    latitude = to_double(rows.value(0, "latitude"));
    longitude = to_double(rows.value(0, "longitude"));
    return latitude != 0.0 || longitude != 0.0;
}

} // namespace

void register_food_routes(TourismApp& app) {
    // GET /api/v1/foods?scenic_spot_id=X&cuisine=Y&q=Z&sort=hot|rating|distance&lat=X&lng=Y&limit=10
    CROW_ROUTE(app, "/api/v1/foods")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;

            FoodQuery query;
            query.scenic_spot_id = query_int(req, "scenic_spot_id", 0, 0, 100000);
            query.cuisine = trim_text(req.url_params.get("cuisine") ? req.url_params.get("cuisine") : "");
            query.search = trim_text(req.url_params.get("q") ? req.url_params.get("q") : "");
            query.sort = normalize_food_sort(trim_text(req.url_params.get("sort") ? req.url_params.get("sort") : "hot"));
            query.limit = query_int(req, "limit", 10, 1, 50);

            // Parse user location for distance calculation
            std::string lat_str = req.url_params.get("lat") ? req.url_params.get("lat") : "";
            std::string lng_str = req.url_params.get("lng") ? req.url_params.get("lng") : "";
            if (!lat_str.empty() && !lng_str.empty()) {
                query.user_lat = to_double(lat_str);
                query.user_lng = to_double(lng_str);
                query.has_user_location = query.user_lat != 0.0 || query.user_lng != 0.0;
            }
            if (!query.has_user_location) {
                query.has_user_location = load_scenic_center(db, query.scenic_spot_id, query.user_lat, query.user_lng);
            }
            if (query.sort == "distance" && !query.has_user_location) query.sort = "hot";

            auto items = query_food_items(db, query);
            auto ranked = rank_foods(items, query);

            crow::json::wvalue::list food_list;
            for (const auto& result : ranked) {
                food_list.push_back(ranked_food_json(result));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(food_list.size());
            data["items"] = std::move(food_list);
            data["algorithm"] = "TopK partial sort + derived hot score";
            data["scenicSpotId"] = query.scenic_spot_id;
            data["sort"] = query.sort;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // GET /api/v1/foods/cuisines?scenic_spot_id=X
    CROW_ROUTE(app, "/api/v1/foods/cuisines")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            int scenic_spot_id = query_int(req, "scenic_spot_id", 0, 0, 100000);

            // Collect distinct facility names from restaurant/cafe facilities
            std::string scenic_filter;
            if (scenic_spot_id > 0) {
                scenic_filter = " AND COALESCE(f.scenic_spot_id, gn.scenic_spot_id, 0) = " + std::to_string(scenic_spot_id);
            }

            std::string sql = R"SQL(
                SELECT DISTINCT f.name
                FROM facilities f
                LEFT JOIN graph_nodes gn ON gn.facility_id = f.id
                WHERE f.location IS NOT NULL
                  AND (f.type = 'restaurant' OR f.type = 'cafe' OR f.type = 'fast_food')
            )SQL" + scenic_filter;

            auto rows = exec_sql(db, sql);

            std::set<std::string> cuisine_set;
            for (int row = 0; row < rows.rows(); ++row) {
                std::string key = tourism::services::infer_cuisine(rows.value(row, "name"));
                if (!key.empty()) cuisine_set.insert(key);
            }

            crow::json::wvalue::list cuisines;
            for (const auto& key : cuisine_set) {
                crow::json::wvalue item;
                item["key"] = key;
                item["label"] = cuisine_label(key);
                cuisines.push_back(std::move(item));
            }

            crow::json::wvalue data;
            data["cuisines"] = std::move(cuisines);
            data["scenicSpotId"] = scenic_spot_id;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
