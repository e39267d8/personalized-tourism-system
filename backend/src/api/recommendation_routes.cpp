#include "api/recommendation_routes.h"

#include "db/postgres.h"
#include "services/budget_service.h"
#include "services/recommendation_service.h"
#include "services/scenic_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <cctype>
#include <unordered_map>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::services::RecommendationProfile;
using tourism::services::rank_personalized_recommendations;
using tourism::services::scenic_candidate_from_row;
using tourism::services::scenic_json;
using tourism::services::scenic_select_sql;
using tourism::support::json_error;
using tourism::support::json_int;
using tourism::support::json_string;
using tourism::support::json_string_array;
using tourism::support::ok;
using tourism::support::query_int;
using tourism::support::string_list;
using tourism::support::to_double;

RecommendationProfile recommendation_profile_from_json(const crow::json::rvalue& body) {
    RecommendationProfile profile;
    profile.preferred_tags = json_string_array(body, "preferredTags");
    profile.preferred_categories = json_string_array(body, "preferredCategories");
    profile.budget_level = json_string(body, "budgetLevel", "medium");
    profile.crowd_preference = json_string(body, "crowdPreference", "any");
    profile.intensity = json_string(body, "intensity", "medium");
    profile.sort_by = json_string(body, "sortBy", "interest");
    return profile;
}

std::string normalize_sort_by(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    if (value == "rating" || value == "hot" || value == "interest") return value;
    if (value == "personalized") return "interest";
    return "interest";
}

} // namespace

void register_recommendation_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/budget-plans")([](const crow::request& req) {
        int budget = query_int(req, "budget", 1000000, 0, 1000000);
        return ok(tourism::services::budget_plans_json(budget));
    });

    CROW_ROUTE(app, "/api/v1/recommendations/scenic-spots")([](const crow::request& req) -> crow::response {
        try {
            int limit = query_int(req, "limit", 10, 1, 30);
            PgConnection db;
            auto rows = exec_params(db, scenic_select_sql(), {"", "", "", "rating", std::to_string(limit), ""});
            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) {
                crow::json::wvalue rec;
                rec["scenic_spot"] = scenic_json(rows, row);
                rec["score"] = to_double(rows.value(row, "rating")) / 5.0;
                rec["reason"] = "数据库评分和标签匹配";
                items.push_back(std::move(rec));
            }
            crow::json::wvalue data;
            data["recommendations"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/recommendations/personalized").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            int limit = json_int(body, "limit", 6);
            if (limit <= 0) limit = 6;
            if (limit > 30) limit = 30;

            auto profile = recommendation_profile_from_json(body);
            profile.sort_by = normalize_sort_by(profile.sort_by);

            PgConnection db;
            auto rows = exec_params(db, scenic_select_sql(), {"", "", "", "relevance", "5000", ""});

            std::vector<tourism::services::ScenicCandidate> candidates;
            std::unordered_map<int, int> row_by_id;
            candidates.reserve(static_cast<size_t>(rows.rows()));
            for (int row = 0; row < rows.rows(); ++row) {
                auto candidate = scenic_candidate_from_row(rows, row);
                row_by_id[candidate.id] = row;
                candidates.push_back(std::move(candidate));
            }

            auto ranked = rank_personalized_recommendations(candidates, profile, limit);

            crow::json::wvalue::list items;
            for (const auto& result : ranked) {
                auto row_it = row_by_id.find(result.scenic_spot_id);
                if (row_it == row_by_id.end()) continue;

                crow::json::wvalue item;
                item["scenic_spot"] = scenic_json(rows, row_it->second);
                item["score"] = result.score;
                item["matchedTags"] = string_list(result.matched_tags);
                item["reason"] = result.reason;
                item["scoreBreakdown"]["tagScore"] = result.tag_score;
                item["scoreBreakdown"]["categoryScore"] = result.category_score;
                item["scoreBreakdown"]["ratingScore"] = result.rating_score;
                item["scoreBreakdown"]["budgetScore"] = result.budget_score;
                item["scoreBreakdown"]["crowdScore"] = result.crowd_score;
                item["scoreBreakdown"]["intensityScore"] = result.intensity_score;
                item["scoreBreakdown"]["hotScore"] = result.hot_score;
                item["scoreBreakdown"]["hotSignalScore"] = result.hot_signal_score;
                item["displayMetric"] = profile.sort_by == "rating"
                    ? "rating"
                    : (profile.sort_by == "hot" ? "hot" : "interest");
                item["displayValue"] = profile.sort_by == "rating"
                    ? to_double(rows.value(row_it->second, "rating"))
                    : (profile.sort_by == "hot"
                        ? (result.hot_signal_score > 0.0 ? result.hot_signal_score : result.hot_score)
                        : result.score);
                items.push_back(std::move(item));
            }

            crow::json::wvalue data;
            data["recommendations"] = std::move(items);
            data["sortBy"] = profile.sort_by;
            data["topKStrategy"] = "min-heap Top-K partial sorting, O(n log k), keeps only the requested leading candidates";
            data["algorithm"] = "interest score combines tags, category, rating, budget, crowd, visit duration and dynamic heat; rating mode ranks by rating; hot mode ranks by favorites, check-ins, diary mentions and route references";
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
