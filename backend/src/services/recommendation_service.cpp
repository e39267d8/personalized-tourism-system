#include "services/recommendation_service.h"

#include <algorithm>
#include <cmath>
#include <queue>
#include <set>
#include <sstream>

namespace tourism::services {
namespace {

std::string trim(const std::string& value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string::npos) return "";
    const auto last = value.find_last_not_of(" \t\r\n");
    return value.substr(first, last - first + 1);
}

bool contains_text(const std::string& text, const std::string& needle) {
    if (needle.empty()) return false;
    return text.find(needle) != std::string::npos;
}

bool category_matches(const ScenicCandidate& spot, const std::string& preferred) {
    std::string value = trim(preferred);
    if (value.empty()) return false;
    if (spot.category == value || contains_text(spot.category, value) || contains_text(value, spot.category)) {
        return true;
    }
    return std::any_of(spot.tags.begin(), spot.tags.end(), [&](const std::string& tag) {
        return tag == value || contains_text(tag, value) || contains_text(value, tag);
    });
}

double clamp01(double value) {
    return std::max(0.0, std::min(1.0, value));
}

double budget_score(double ticket_price, const std::string& budget_level) {
    if (budget_level == "low") {
        if (ticket_price <= 0) return 1.0;
        if (ticket_price <= 30) return 0.85;
        if (ticket_price <= 80) return 0.45;
        return 0.15;
    }
    if (budget_level == "high") {
        if (ticket_price >= 80) return 1.0;
        if (ticket_price >= 30) return 0.75;
        return 0.6;
    }
    if (ticket_price <= 80) return 1.0;
    if (ticket_price <= 180) return 0.65;
    return 0.35;
}

double crowd_score(int crowd_level, const std::string& crowd_preference) {
    if (crowd_preference == "avoid_crowded") {
        if (crowd_level <= 1) return 1.0;
        if (crowd_level == 2) return 0.75;
        if (crowd_level == 3) return 0.35;
        return 0.1;
    }
    if (crowd_preference == "popular") {
        if (crowd_level >= 3) return 1.0;
        if (crowd_level == 2) return 0.65;
        return 0.45;
    }
    return 0.75;
}

bool has_preferences(const RecommendationProfile& profile) {
    return !profile.preferred_tags.empty() ||
           !profile.preferred_categories.empty() ||
           profile.budget_level != "medium" ||
           profile.crowd_preference != "any" ||
           profile.intensity != "medium";
}

std::string join_tags(const std::vector<std::string>& values, size_t max_count = 3) {
    std::ostringstream out;
    size_t count = std::min(values.size(), max_count);
    for (size_t i = 0; i < count; ++i) {
        if (i) out << "、";
        out << values[i];
    }
    return out.str();
}

std::string reason_for(const ScenicCandidate& spot,
                       const RecommendationProfile& profile,
                       const RecommendationScore& score,
                       bool profile_empty) {
    if (profile_empty) {
        return "基于综合评分推荐：评分较高，门票和人流压力相对均衡，适合作为默认目的地。";
    }

    std::vector<std::string> parts;
    if (!score.matched_tags.empty()) {
        parts.push_back("匹配你的" + join_tags(score.matched_tags) + "偏好");
    }
    if (score.category_score > 0.0) {
        parts.push_back("景点类型符合你的选择");
    }
    if (profile.budget_level == "low" && spot.ticket_price <= 30) {
        parts.push_back("门票较低，适合低预算游玩");
    } else if (profile.budget_level == "high" && spot.ticket_price >= 80) {
        parts.push_back("适合更完整的深度体验");
    }
    if (profile.crowd_preference == "avoid_crowded" && spot.crowd_level <= 2) {
        parts.push_back("人流压力相对较小");
    } else if (profile.crowd_preference == "popular" && spot.crowd_level >= 3) {
        parts.push_back("属于热门目的地");
    }

    if (parts.empty()) {
        return "综合评分、预算和人流条件与你的偏好较接近。";
    }

    std::ostringstream out;
    for (size_t i = 0; i < parts.size(); ++i) {
        if (i) out << "，";
        out << parts[i];
    }
    out << "。";
    return out.str();
}

RecommendationScore score_candidate(const ScenicCandidate& spot, const RecommendationProfile& profile) {
    RecommendationScore result;
    result.scenic_spot_id = spot.id;

    std::set<std::string> matched;
    for (const auto& preferred : profile.preferred_tags) {
        std::string value = trim(preferred);
        if (value.empty()) continue;
        for (const auto& tag : spot.tags) {
            if (tag == value || contains_text(tag, value) || contains_text(value, tag)) {
                matched.insert(value);
                break;
            }
        }
    }
    result.matched_tags.assign(matched.begin(), matched.end());

    result.tag_score = profile.preferred_tags.empty()
        ? 0.0
        : clamp01(static_cast<double>(result.matched_tags.size()) / static_cast<double>(profile.preferred_tags.size()));

    result.category_score = 0.0;
    for (const auto& category : profile.preferred_categories) {
        if (category_matches(spot, category)) {
            result.category_score = 1.0;
            break;
        }
    }

    result.rating_score = clamp01(spot.rating / 5.0);
    result.budget_score = budget_score(spot.ticket_price, profile.budget_level);
    result.crowd_score = crowd_score(spot.crowd_level, profile.crowd_preference);
    result.score = result.tag_score * 50.0 +
                   result.category_score * 20.0 +
                   result.rating_score * 15.0 +
                   result.budget_score * 10.0 +
                   result.crowd_score * 5.0;
    result.score = std::round(result.score * 100.0) / 100.0;
    result.reason = reason_for(spot, profile, result, !has_preferences(profile));
    return result;
}

} // namespace

std::vector<RecommendationScore> rank_personalized_recommendations(
    const std::vector<ScenicCandidate>& candidates,
    const RecommendationProfile& profile,
    int limit) {
    if (limit <= 0) limit = 6;

    // Use min-heap for partial sorting (O(n log k) instead of O(n log n))
    // Heap top is the smallest score - the "cutoff" for the current top-k
    struct HeapEntry {
        RecommendationScore value;
        bool operator<(const HeapEntry& other) const {
            if (value.score != other.value.score) return value.score > other.value.score;
            return value.scenic_spot_id < other.value.scenic_spot_id;
        }
    };
    std::priority_queue<HeapEntry> min_heap;

    RecommendationProfile normalized = profile;
    if (normalized.budget_level.empty()) normalized.budget_level = "medium";
    if (normalized.crowd_preference.empty()) normalized.crowd_preference = "any";
    if (normalized.intensity.empty()) normalized.intensity = "medium";

    for (const auto& candidate : candidates) {
        RecommendationScore scored = score_candidate(candidate, normalized);
        if (static_cast<int>(min_heap.size()) < limit) {
            min_heap.push({std::move(scored)});
        } else if (!min_heap.empty()) {
            const auto& cutoff = min_heap.top();
            if (scored.score > cutoff.value.score ||
                (scored.score == cutoff.value.score && scored.scenic_spot_id < cutoff.value.scenic_spot_id)) {
                min_heap.pop();
                min_heap.push({std::move(scored)});
            }
        }
    }

    std::vector<RecommendationScore> results;
    results.reserve(min_heap.size());
    while (!min_heap.empty()) {
        results.push_back(std::move(min_heap.top().value));
        min_heap.pop();
    }
    std::reverse(results.begin(), results.end());
    return results;
}

} // namespace tourism::services
