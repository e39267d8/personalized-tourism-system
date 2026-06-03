#pragma once

#include <string>
#include <vector>

namespace tourism::services {

struct RecommendationProfile {
    std::vector<std::string> preferred_tags;
    std::vector<std::string> preferred_categories;
    std::string budget_level = "medium";
    std::string crowd_preference = "any";
    std::string intensity = "medium";
};

struct ScenicCandidate {
    int id = 0;
    std::string name;
    std::string category;
    std::vector<std::string> tags;
    double rating = 0.0;
    double ticket_price = 0.0;
    int crowd_level = 2;
    int duration_minutes = 0;
};

struct RecommendationScore {
    int scenic_spot_id = 0;
    double score = 0.0;
    double tag_score = 0.0;
    double category_score = 0.0;
    double rating_score = 0.0;
    double budget_score = 0.0;
    double crowd_score = 0.0;
    std::vector<std::string> matched_tags;
    std::string reason;
};

std::vector<RecommendationScore> rank_personalized_recommendations(
    const std::vector<ScenicCandidate>& candidates,
    const RecommendationProfile& profile,
    int limit);

} // namespace tourism::services
