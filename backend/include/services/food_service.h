#pragma once

#ifndef TOURISM_FOOD_SERVICE_NO_DB
#include "crow.h"
#include "db/postgres.h"
#endif

#include <string>
#include <vector>

namespace tourism::services {

struct FoodItem {
    int id = 0;
    std::string name;
    std::string type;
    std::string cuisine;
    std::string cuisine_label;
    std::string source_cuisine;
    double rating = 0.0;
    int price_level = 0;
    double longitude = 0.0;
    double latitude = 0.0;
    std::string address;
    std::string opening_hours;
    std::string phone;
    int popularity = 0;
    int reviews = 0;
    double distance_meters = 0.0;
    double hot_score = 0.0;
    int scenic_spot_id = 0;
    std::string scenic_name;
    std::string scenic_category;
    std::string location_type_label;
};

struct FoodQuery {
    int scenic_spot_id = 0;
    std::string cuisine;
    std::string search;
    std::string sort = "hot";
    double user_lat = 0.0;
    double user_lng = 0.0;
    bool has_user_location = false;
    int limit = 10;
};

std::string cuisine_label(const std::string& cuisine_key);

// Infer cuisine type from imported cuisine metadata first, then facility name.
std::string infer_cuisine(const std::string& name, const std::string& source_cuisine);

// Infer cuisine type from facility name (keyword matching)
std::string infer_cuisine(const std::string& name);

// Score and rank food items (supports partial sorting)
struct FoodScore {
    FoodItem food;
    double score = 0.0;
    std::string match_reason;
};

std::vector<FoodScore> rank_foods(const std::vector<FoodItem>& items,
                                  const FoodQuery& query,
                                  bool use_topk = true);

#ifndef TOURISM_FOOD_SERVICE_NO_DB
// Query food items from database
std::vector<FoodItem> query_food_items(tourism::db::PgConnection& db, const FoodQuery& query);

// Format as JSON
crow::json::wvalue food_json(const FoodItem& food);
#endif

} // namespace tourism::services
