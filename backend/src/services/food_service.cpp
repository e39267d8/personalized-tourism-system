#include "services/food_service.h"

#include "services/topk_selector.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <unordered_map>

namespace tourism::services {
namespace {

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

std::string lowercase_ascii(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return value;
}

bool contains_text(const std::string& text, const std::string& query) {
    if (query.empty()) return true;
    if (text.find(query) != std::string::npos) return true;
    return lowercase_ascii(text).find(lowercase_ascii(query)) != std::string::npos;
}

double price_score(int price_level) {
    if (price_level == 2) return 15.0;
    if (price_level == 3) return 12.0;
    if (price_level == 1) return 10.0;
    if (price_level == 4) return 7.0;
    return 8.0;
}

double completeness_score(const FoodItem& item) {
    double present = 0.0;
    if (!item.address.empty()) present += 1.0;
    if (!item.opening_hours.empty()) present += 1.0;
    if (!item.phone.empty()) present += 1.0;
    if (item.scenic_spot_id > 0 || !item.scenic_name.empty()) present += 1.0;
    return present / 4.0 * 20.0;
}

double trust_score(const FoodItem& item) {
    double score = 0.0;
    if (item.type == "restaurant" || item.type == "cafe" || item.type == "fast_food") score += 8.0;
    if (!item.cuisine.empty() && item.cuisine != "chinese") score += 7.0;
    else if (!item.cuisine.empty()) score += 5.0;
    return std::min(score, 15.0);
}

double derived_hot_score(const FoodItem& item) {
    double rating = std::max(0.0, std::min(item.rating, 5.0));
    return rating / 5.0 * 50.0 +
           completeness_score(item) +
           price_score(item.price_level) +
           trust_score(item);
}

bool matches_query(const FoodItem& item, const std::string& query) {
    if (query.empty()) return true;
    return contains_text(item.name, query) ||
           contains_text(item.cuisine, query) ||
           contains_text(item.cuisine_label, query) ||
           contains_text(item.address, query) ||
           contains_text(item.scenic_name, query);
}

std::string match_reason(const FoodItem& item, const FoodQuery& query) {
    if (query.search.empty()) return "";
    if (contains_text(item.name, query.search)) return "名称匹配 \"" + query.search + "\"";
    if (contains_text(item.cuisine_label, query.search) || contains_text(item.cuisine, query.search)) {
        return "菜系匹配 \"" + query.search + "\"";
    }
    if (contains_text(item.address, query.search)) return "地址匹配 \"" + query.search + "\"";
    if (contains_text(item.scenic_name, query.search)) return "景区匹配 \"" + query.search + "\"";
    return "";
}

bool cuisine_matches(const FoodItem& item, const std::string& cuisine) {
    if (cuisine.empty()) return true;
    return item.cuisine == cuisine ||
           item.cuisine_label == cuisine ||
           contains_text(item.cuisine_label, cuisine);
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

std::string cuisine_label(const std::string& cuisine_key) {
    return cuisine_label_map(cuisine_key);
}

std::vector<FoodItem> query_food_items(tourism::db::PgConnection& db, const FoodQuery& query) {
    // Join facilities with graph_nodes to support both curated food seed data and imported POI data.
    std::string scenic_filter;
    if (query.scenic_spot_id > 0) {
        scenic_filter = " AND COALESCE(f.scenic_spot_id, gn.scenic_spot_id, 0) = " + std::to_string(query.scenic_spot_id);
    }

    std::string sql = R"SQL(
        SELECT DISTINCT ON (f.id)
               f.id::text, f.name, f.type,
               COALESCE(f.rating, 0)::text AS rating,
               COALESCE(f.price_level, 0)::text AS price_level,
               ST_X(f.location::geometry)::text AS longitude,
               ST_Y(f.location::geometry)::text AS latitude,
               COALESCE(f.address, '') AS address,
               COALESCE(f.opening_hours, '') AS opening_hours,
               COALESCE(f.phone, '') AS phone,
               COALESCE(f.scenic_spot_id, gn.scenic_spot_id, 0)::text AS scenic_spot_id,
               COALESCE(s.name, '') AS scenic_name
        FROM facilities f
        LEFT JOIN graph_nodes gn ON gn.facility_id = f.id
        LEFT JOIN scenic_spots s ON s.id = COALESCE(f.scenic_spot_id, gn.scenic_spot_id)
        WHERE f.location IS NOT NULL
          AND (f.type = 'restaurant' OR f.type = 'cafe' OR f.type = 'fast_food')
    )SQL" + scenic_filter + R"SQL(
        ORDER BY f.id, COALESCE(f.rating, 0) DESC, f.name
        LIMIT 1000
    )SQL";

    auto rows = exec_sql(db, sql);

    std::vector<FoodItem> items;
    for (int row = 0; row < rows.rows(); ++row) {
        FoodItem item;
        item.id = to_int(rows.value(row, "id"));
        item.name = rows.value(row, "name");
        item.type = rows.value(row, "type");
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
        item.hot_score = derived_hot_score(item);
        item.popularity = static_cast<int>(std::round(item.hot_score));

        if (!cuisine_matches(item, query.cuisine)) continue;
        if (!matches_query(item, query.search)) continue;
        items.push_back(std::move(item));
    }

    return items;
}

std::vector<FoodScore> rank_foods(const std::vector<FoodItem>& items,
                                  const FoodQuery& query,
                                  bool use_topk) {
    if (items.empty()) return {};

    auto score_item = [&](const FoodItem& item) -> FoodScore {
        FoodScore result{item, 0.0, ""};
        result.food.hot_score = derived_hot_score(item);
        result.food.popularity = static_cast<int>(std::round(result.food.hot_score));

        if (query.has_user_location) {
            double dist = haversine_meters(query.user_lat, query.user_lng,
                                          item.latitude, item.longitude);
            result.food.distance_meters = dist;
        } else {
            result.food.distance_meters = 0.0;
        }

        if (query.sort == "rating") result.score = result.food.rating;
        else if (query.sort == "distance" && query.has_user_location) result.score = -result.food.distance_meters;
        else result.score = result.food.hot_score;

        result.match_reason = match_reason(result.food, query);

        return result;
    };

    std::vector<FoodScore> scored;
    scored.reserve(items.size());
    for (const auto& item : items) scored.push_back(score_item(item));

    if (use_topk && query.limit > 0 && static_cast<int>(scored.size()) > query.limit) {
        auto comp = [&query](const FoodScore& a, const FoodScore& b) {
            if (a.score != b.score) return a.score > b.score;
            if (query.sort == "rating" && a.food.hot_score != b.food.hot_score) return a.food.hot_score > b.food.hot_score;
            if (query.sort == "distance" && a.food.rating != b.food.rating) return a.food.rating > b.food.rating;
            return a.food.id < b.food.id;
        };
        TopKSelector<FoodScore> selector(query.limit, comp);
        for (auto& s : scored) selector.insert(std::move(s));
        return selector.finalize();
    }

    std::sort(scored.begin(), scored.end(),
              [&query](const FoodScore& a, const FoodScore& b) {
                  if (a.score != b.score) return a.score > b.score;
                  if (query.sort == "rating" && a.food.hot_score != b.food.hot_score) return a.food.hot_score > b.food.hot_score;
                  if (query.sort == "distance" && a.food.rating != b.food.rating) return a.food.rating > b.food.rating;
                  return a.food.id < b.food.id;
              });

    if (query.limit > 0 && static_cast<int>(scored.size()) > query.limit) {
        scored.resize(query.limit);
    }

    return scored;
}

crow::json::wvalue food_json(const FoodItem& food) {
    crow::json::wvalue item;
    item["id"] = food.id;
    item["name"] = food.name;
    item["type"] = food.type;
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
    item["hotScore"] = food.hot_score;
    return item;
}

} // namespace tourism::services
