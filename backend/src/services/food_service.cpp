#include "services/food_service.h"

#include "services/topk_selector.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <cmath>
#include <sstream>
#include <unordered_set>

namespace tourism::services {
namespace {

using tourism::db::exec_params;
using tourism::db::exec_sql;
using tourism::support::to_double;
using tourism::support::to_int;

double haversine_meters(double lat1, double lng1, double lat2, double lng2) {
    constexpr double earth_radius = 6371000.0;
    constexpr double pi = 3.14159265358979323846;
    auto to_radians = [pi](double value) { return value * pi / 180.0; };
    double dlat = to_radians(lat2 - lat1);
    double dlng = to_radians(lng2 - lng1);
    double rlat1 = to_radians(lat1);
    double rlat2 = to_radians(lat2);
    double value = std::sin(dlat / 2.0) * std::sin(dlat / 2.0) +
                   std::cos(rlat1) * std::cos(rlat2) *
                   std::sin(dlng / 2.0) * std::sin(dlng / 2.0);
    return earth_radius * 2.0 * std::atan2(std::sqrt(value), std::sqrt(1.0 - value));
}

// Map of cuisine key -> Chinese label
std::string cuisine_label_map(const std::string& key) {
    static const std::unordered_map<std::string, std::string> map = {
        {"chinese", "中餐"}, {"western", "西餐"}, {"japanese", "日料"},
        {"korean", "韩餐"}, {"french", "法餐"}, {"italian", "意大利菜"},
        {"chicken", "炸鸡"}, {"burger", "汉堡"},
        {"noodle", "面食"}, {"dumplings", "饺子"}, {"hot_pot", "火锅"},
        {"seafood", "海鲜"}, {"bbq", "烧烤"}, {"coffee_shop", "咖啡"},
        {"tea", "茶饮"}, {"dessert", "甜品"}, {"snack", "小吃"},
        {"street_food", "街头小吃"}, {"fast_food", "快餐"},
        {"xinjiang", "新疆菜"}, {"dongbei", "东北菜"}, {"sichuan", "川菜"},
        {"cantonese", "粤菜"}, {"hunan", "湘菜"}, {"roast_duck", "烤鸭"},
    };
    auto it = map.find(key);
    return it != map.end() ? it->second : key;
}

} // namespace

// Infer cuisine from facility name using keyword matching
std::string infer_cuisine(const std::string& name) {
    struct CuisinePattern { std::string keyword; std::string key; };
    static const std::vector<CuisinePattern> patterns = {
        {"火锅", "hot_pot"}, {"涮肉", "hot_pot"}, {"烤鸭", "roast_duck"},
        {"烧烤", "bbq"}, {"烤肉", "bbq"}, {"串串", "bbq"},
        {"川菜", "sichuan"}, {"湘菜", "hunan"}, {"粤菜", "cantonese"},
        {"东北菜", "dongbei"}, {"新疆", "xinjiang"},
        {"面", "noodle"}, {"粉", "noodle"}, {"米线", "noodle"},
        {"饺子", "dumplings"}, {"馄饨", "dumplings"}, {"包子", "dumplings"},
        {"海鲜", "seafood"}, {"鱼", "seafood"}, {"虾", "seafood"},
        {"咖啡", "coffee_shop"}, {"茶", "tea"}, {"奶茶", "tea"},
        {"甜品", "dessert"}, {"蛋糕", "dessert"}, {"冰淇淋", "dessert"},
        {"小吃", "snack"}, {"夜市", "street_food"}, {"街", "street_food"},
        {"汉堡", "burger"}, {"披萨", "italian"}, {"意面", "italian"},
        {"牛排", "western"}, {"西餐", "western"}, {"日料", "japanese"},
        {"韩餐", "korean"}, {"炸鸡", "chicken"}, {"快餐", "fast_food"},
        {"卤煮", "snack"}, {"豆汁", "snack"}, {"爆肚", "snack"},
        {"炒肝", "snack"}, {"炸酱面", "noodle"}, {"拉面", "noodle"},
    };
    for (const auto& p : patterns) {
        if (name.find(p.keyword) != std::string::npos) return p.key;
    }
    return "chinese";
}

std::string extract_cuisine(const std::string& source_tags) {
    // source_tags may contain cuisine hints; if empty, return empty
    if (source_tags.empty()) return "";
    auto pos = source_tags.find("\"cuisine\"");
    if (pos == std::string::npos) {
        pos = source_tags.find("'cuisine'");
    }
    if (pos == std::string::npos) return "";

    auto colon = source_tags.find(':', pos);
    if (colon == std::string::npos) return "";

    auto start = source_tags.find('"', colon);
    auto end = source_tags.find('"', start + 1);
    if (start == std::string::npos || end == std::string::npos) {
        start = source_tags.find('\'', colon);
        end = source_tags.find('\'', start + 1);
    }
    if (start == std::string::npos || end == std::string::npos) return "";
    return source_tags.substr(start + 1, end - start - 1);
}

std::string cuisine_label(const std::string& cuisine_key) {
    return cuisine_label_map(cuisine_key);
}

std::vector<FoodItem> query_food_items(tourism::db::PgConnection& db, const FoodQuery& query) {
    // Join facilities with graph_nodes to get scenic_spot_id
    std::string scenic_filter;
    if (query.scenic_spot_id > 0) {
        scenic_filter = " AND gn.scenic_spot_id = " + std::to_string(query.scenic_spot_id);
    }

    std::string sql = R"SQL(
        SELECT f.id::text, f.name, f.type,
               COALESCE(f.rating, 0)::text AS rating,
               COALESCE(f.price_level, 0)::text AS price_level,
               ST_X(f.location::geometry)::text AS longitude,
               ST_Y(f.location::geometry)::text AS latitude,
               COALESCE(f.address, '') AS address,
               COALESCE(f.opening_hours, '') AS opening_hours,
               COALESCE(f.phone, '') AS phone,
               COALESCE(gn.scenic_spot_id, 0)::text AS scenic_spot_id,
               (SELECT s.name FROM scenic_spots s WHERE s.id = gn.scenic_spot_id) AS scenic_name
        FROM facilities f
        LEFT JOIN graph_nodes gn ON gn.facility_id = f.id
        WHERE f.location IS NOT NULL
          AND (f.type = 'restaurant' OR f.type = 'cafe' OR f.type = 'fast_food')
    )SQL" + scenic_filter + R"SQL(
          AND ($1 = '' OR lower(f.name) LIKE '%' || lower($1) || '%')
        ORDER BY COALESCE(f.rating, 0) DESC, f.name
        LIMIT 200
    )SQL";

    auto rows = exec_params(db, sql, {query.search});

    std::vector<FoodItem> items;
    for (int row = 0; row < rows.rows(); ++row) {
        FoodItem item;
        item.id = to_int(rows.value(row, "id"));
        item.name = rows.value(row, "name");
        item.cuisine = infer_cuisine(item.name);
        item.cuisine_label = cuisine_label(item.cuisine);
        item.rating = to_double(rows.value(row, "rating"));
        item.price_level = to_int(rows.value(row, "price_level"));
        item.longitude = to_double(rows.value(row, "longitude"));
        item.latitude = to_double(rows.value(row, "latitude"));
        item.address = rows.value(row, "address");
        item.opening_hours = rows.value(row, "opening_hours");
        item.phone = rows.value(row, "phone");
        item.scenic_spot_id = to_int(rows.value(row, "scenic_spot_id"));
        item.scenic_name = rows.value(row, "scenic_name");
        item.reviews = 0; // reviews are per scenic spot, not per facility

        // Approximate popularity from rating
        item.popularity = static_cast<int>(item.rating * 20);

        items.push_back(item);
    }

    return items;
}

std::vector<FoodScore> rank_foods(const std::vector<FoodItem>& items,
                                  const FoodQuery& query,
                                  bool use_topk) {
    if (items.empty()) return {};

    auto score_item = [&](const FoodItem& item) -> FoodScore {
        FoodScore result{item, 0.0, ""};

        // Base score from rating (30%)
        result.score += item.rating * 3.0;

        // Popularity (25%)
        result.score += std::min(item.popularity / 10.0, 10.0) * 2.5;

        // Reviews (15%)
        result.score += std::min(item.reviews / 10.0, 10.0) * 1.5;

        // Price level (15%) - mid-range preferred
        result.score += (item.price_level == 2 ? 10.0 : item.price_level == 3 ? 8.0 : 5.0) * 1.5;

        // Distance (15%) - closer is better
        if (query.user_lat != 0.0 && query.user_lng != 0.0) {
            double dist = haversine_meters(query.user_lat, query.user_lng,
                                          item.latitude, item.longitude);
            result.food.distance_meters = dist;
            double dist_score = std::max(0.0, 10.0 - dist / 1000.0);
            result.score += dist_score * 1.5;
        } else {
            result.food.distance_meters = 0.0;
            result.score += 5.0 * 1.5; // neutral score when no location
        }

        // Name search boost
        if (!query.search.empty()) {
            std::string lower_name = item.name;
            std::string lower_search = query.search;
            std::transform(lower_name.begin(), lower_name.end(), lower_name.begin(), ::tolower);
            std::transform(lower_search.begin(), lower_search.end(), lower_search.begin(), ::tolower);
            if (lower_name.find(lower_search) != std::string::npos) {
                result.score += 10.0;
                result.match_reason = "名称匹配 \"" + query.search + "\"";
            }
        }

        return result;
    };

    std::vector<FoodScore> scored;
    scored.reserve(items.size());
    for (const auto& item : items) scored.push_back(score_item(item));

    if (use_topk && query.limit > 0 && static_cast<int>(scored.size()) > query.limit) {
        auto comp = [](const FoodScore& a, const FoodScore& b) {
            if (a.score != b.score) return a.score > b.score;
            return a.food.id < b.food.id;
        };
        TopKSelector<FoodScore> selector(query.limit, comp);
        for (auto& s : scored) selector.insert(std::move(s));
        return selector.finalize();
    }

    std::sort(scored.begin(), scored.end(),
              [](const FoodScore& a, const FoodScore& b) { return a.score > b.score; });

    if (query.limit > 0 && static_cast<int>(scored.size()) > query.limit) {
        scored.resize(query.limit);
    }

    return scored;
}

crow::json::wvalue food_json(const FoodItem& food) {
    crow::json::wvalue item;
    item["id"] = food.id;
    item["name"] = food.name;
    item["cuisine"] = food.cuisine;
    item["cuisineLabel"] = food.cuisine_label;
    item["rating"] = food.rating;
    item["priceLevel"] = food.price_level;
    item["longitude"] = food.longitude;
    item["latitude"] = food.latitude;
    item["address"] = food.address;
    item["openingHours"] = food.opening_hours;
    item["phone"] = food.phone;
    item["scenicSpotId"] = food.scenic_spot_id;
    item["scenicName"] = food.scenic_name;
    item["popularity"] = food.popularity;
    item["reviews"] = food.reviews;
    item["distanceMeters"] = food.distance_meters;
    return item;
}

} // namespace tourism::services
