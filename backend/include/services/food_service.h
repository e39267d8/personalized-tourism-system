#pragma once

#include "crow.h"
#include "db/postgres.h"

#include <string>
#include <vector>

namespace tourism::services {

struct FoodItem {
    int id = 0;
    std::string name;
    std::string cuisine;
    std::string cuisine_label;
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
    int scenic_spot_id = 0;
    std::string scenic_name;
};

struct FoodQuery {
    int scenic_spot_id = 0;
    std::string cuisine;
    std::string search;
    std::string sort = "hot";
    double user_lat = 0.0;
    double user_lng = 0.0;
    int limit = 10;
};

// Parse cuisine from source_tags JSON
std::string extract_cuisine(const std::string& source_tags);
std::string cuisine_label(const std::string& cuisine_key);

// Infer cuisine type from facility name (keyword matching)
std::string infer_cuisine(const std::string& name);

// Query food items from database
std::vector<FoodItem> query_food_items(tourism::db::PgConnection& db, const FoodQuery& query);

// Score and rank food items (supports partial sorting)
struct FoodScore {
    FoodItem food;
    double score = 0.0;
    std::string match_reason;
};

std::vector<FoodScore> rank_foods(const std::vector<FoodItem>& items,
                                  const FoodQuery& query,
                                  bool use_topk = true);

// Format as JSON
crow::json::wvalue food_json(const FoodItem& food);

} // namespace tourism::services
