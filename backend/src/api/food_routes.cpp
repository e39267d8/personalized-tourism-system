#include "api/food_routes.h"

#include "db/postgres.h"
#include "services/food_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <set>
#include <unordered_set>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::services::FoodItem;
using tourism::services::FoodQuery;
using tourism::services::FoodScore;
using tourism::services::cuisine_label;
using tourism::services::food_json;
using tourism::services::query_food_items;
using tourism::services::rank_foods;
using tourism::support::json_error;
using tourism::support::json_string;
using tourism::support::ok;
using tourism::support::query_int;
using tourism::support::to_double;
using tourism::support::to_int;
using tourism::support::trim_text;

crow::json::wvalue ranked_food_json(const FoodScore& ranked) {
    crow::json::wvalue item = food_json(ranked.food);
    item["score"] = ranked.score;
    item["matchReason"] = ranked.match_reason;
    return item;
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
            query.sort = trim_text(req.url_params.get("sort") ? req.url_params.get("sort") : "hot");
            query.limit = query_int(req, "limit", 10, 1, 50);

            // Parse user location for distance calculation
            std::string lat_str = req.url_params.get("lat") ? req.url_params.get("lat") : "";
            std::string lng_str = req.url_params.get("lng") ? req.url_params.get("lng") : "";
            if (!lat_str.empty()) query.user_lat = to_double(lat_str);
            if (!lng_str.empty()) query.user_lng = to_double(lng_str);

            auto items = query_food_items(db, query);
            auto ranked = rank_foods(items, query);

            crow::json::wvalue::list food_list;
            for (const auto& result : ranked) {
                food_list.push_back(ranked_food_json(result));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(food_list.size());
            data["items"] = std::move(food_list);
            data["algorithm"] = "score = rating*30 + popularity*25 + reviews*15 + price*15 + distance*15";
            data["scenicSpotId"] = query.scenic_spot_id;
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
                scenic_filter = " AND gn.scenic_spot_id = " + std::to_string(scenic_spot_id);
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
