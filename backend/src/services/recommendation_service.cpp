#include "services/recommendation_service.h"

#include <algorithm>
#include <cctype>
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

double normalized_rating(double rating) {
    if (rating <= 0.0) return 0.0;
    if (rating >= 5.0) return 1.0;
    return clamp01((rating - 3.5) / 1.5);
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

double intensity_score(int duration_minutes, const std::string& intensity) {
    if (duration_minutes <= 0) return 0.6;
    if (intensity == "light") {
        if (duration_minutes <= 90) return 1.0;
        if (duration_minutes <= 180) return 0.75;
        if (duration_minutes <= 300) return 0.45;
        return 0.2;
    }
    if (intensity == "high") {
        if (duration_minutes >= 240) return 1.0;
        if (duration_minutes >= 180) return 0.8;
        if (duration_minutes >= 120) return 0.6;
        return 0.3;
    }
    if (duration_minutes >= 90 && duration_minutes <= 210) return 1.0;
    if (duration_minutes >= 60 && duration_minutes <= 300) return 0.75;
    return 0.45;
}

std::string normalize_sort_by(std::string sort_by) {
    std::transform(sort_by.begin(), sort_by.end(), sort_by.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    if (sort_by == "rating" || sort_by == "hot" || sort_by == "interest") return sort_by;
    if (sort_by == "personalized") return "interest";
    return "interest";
}

double hot_score(int view_count, int favorite_count) {
    double views = std::log1p(static_cast<double>(std::max(view_count, 0))) * 8.0;
    double favorites = std::log1p(static_cast<double>(std::max(favorite_count, 0))) * 12.0;
    return std::round(std::min(100.0, views + favorites) * 100.0) / 100.0;
}

double behavior_hot_score(const ScenicCandidate& spot) {
    double views = std::log1p(static_cast<double>(std::max(spot.view_count, 0))) * 4.0;
    double favorites = std::log1p(static_cast<double>(std::max(spot.favorite_count, 0))) * 6.0;
    double behavior_favorites = std::log1p(static_cast<double>(std::max(spot.behavior_favorite_count, 0))) * 22.0;
    double checkins = std::log1p(static_cast<double>(std::max(spot.behavior_checkin_count, 0))) * 16.0;
    double diary_mentions = std::log1p(static_cast<double>(std::max(spot.diary_mention_count, 0))) * 13.0;
    double route_refs = std::log1p(static_cast<double>(std::max(spot.route_reference_count, 0))) * 11.0;
    double score = views + favorites + behavior_favorites + checkins + diary_mentions + route_refs;
    return std::round(std::min(100.0, score) * 100.0) / 100.0;
}

double behavior_signal_score(const ScenicCandidate& spot) {
    return static_cast<double>(std::max(spot.behavior_favorite_count, 0)) * 4.0 +
           static_cast<double>(std::max(spot.behavior_checkin_count, 0)) * 3.0 +
           static_cast<double>(std::max(spot.diary_mention_count, 0)) * 2.0 +
           static_cast<double>(std::max(spot.route_reference_count, 0)) +
           static_cast<double>(std::max(spot.favorite_count, 0)) / 10.0 +
           static_cast<double>(std::max(spot.view_count, 0)) / 100.0;
}

bool has_behavior_signal(const ScenicCandidate& spot) {
    return spot.behavior_favorite_count > 0 ||
           spot.behavior_checkin_count > 0 ||
           spot.diary_mention_count > 0 ||
           spot.route_reference_count > 0 ||
           spot.view_count > 0 ||
           spot.favorite_count > 0;
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

    result.rating_score = normalized_rating(spot.rating);
    result.budget_score = budget_score(spot.ticket_price, profile.budget_level);
    result.crowd_score = crowd_score(spot.crowd_level, profile.crowd_preference);
    result.intensity_score = intensity_score(spot.duration_minutes, profile.intensity);
    result.hot_score = behavior_hot_score(spot);
    result.hot_signal_score = behavior_signal_score(spot);

    double hot_component = has_behavior_signal(spot)
        ? clamp01(result.hot_score / 100.0)
        : result.rating_score;
    if (!has_preferences(profile)) {
        result.score = result.rating_score * 28.0 +
                       hot_component * 28.0 +
                       result.budget_score * 14.0 +
                       result.crowd_score * 12.0 +
                       result.intensity_score * 18.0;
    } else {
        result.score = result.tag_score * 34.0 +
                       result.category_score * 18.0 +
                       result.rating_score * 14.0 +
                       result.budget_score * 8.0 +
                       result.crowd_score * 6.0 +
                       result.intensity_score * 10.0 +
                       hot_component * 10.0;
    }
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
    // Heap top is the worst current item - the "cutoff" for the current top-k.
    struct HeapEntry {
        RecommendationScore value;
        double rank = 0.0;
        double tie_1 = 0.0;
        double tie_2 = 0.0;
        double tie_3 = 0.0;

        bool operator<(const HeapEntry& other) const {
            if (rank != other.rank) return rank > other.rank;
            if (tie_1 != other.tie_1) return tie_1 > other.tie_1;
            if (tie_2 != other.tie_2) return tie_2 > other.tie_2;
            if (tie_3 != other.tie_3) return tie_3 > other.tie_3;
            return value.scenic_spot_id < other.value.scenic_spot_id;
        }
    };
    std::priority_queue<HeapEntry> min_heap;

    RecommendationProfile normalized = profile;
    if (normalized.budget_level.empty()) normalized.budget_level = "medium";
    if (normalized.crowd_preference.empty()) normalized.crowd_preference = "any";
    if (normalized.intensity.empty()) normalized.intensity = "medium";
    normalized.sort_by = normalize_sort_by(normalized.sort_by);

    auto make_entry = [&](RecommendationScore scored) {
        HeapEntry entry;
        entry.value = std::move(scored);
        if (normalized.sort_by == "rating") {
            entry.rank = entry.value.rating_score;
            entry.tie_1 = entry.value.hot_score;
            entry.tie_2 = entry.value.hot_signal_score;
        } else if (normalized.sort_by == "hot") {
            entry.rank = entry.value.hot_score;
            entry.tie_1 = entry.value.hot_signal_score;
            entry.tie_2 = entry.value.rating_score;
        } else {
            entry.rank = entry.value.score;
            entry.tie_1 = entry.value.tag_score + entry.value.category_score + entry.value.intensity_score;
            entry.tie_2 = entry.value.hot_score + entry.value.rating_score;
        }
        entry.tie_3 = static_cast<double>(-entry.value.scenic_spot_id);
        return entry;
    };

    auto is_better = [](const HeapEntry& left, const HeapEntry& right) {
        if (left.rank != right.rank) return left.rank > right.rank;
        if (left.tie_1 != right.tie_1) return left.tie_1 > right.tie_1;
        if (left.tie_2 != right.tie_2) return left.tie_2 > right.tie_2;
        if (left.tie_3 != right.tie_3) return left.tie_3 > right.tie_3;
        return left.value.scenic_spot_id < right.value.scenic_spot_id;
    };

    for (const auto& candidate : candidates) {
        HeapEntry entry = make_entry(score_candidate(candidate, normalized));
        if (static_cast<int>(min_heap.size()) < limit) {
            min_heap.push(std::move(entry));
        } else if (!min_heap.empty()) {
            const auto& cutoff = min_heap.top();
            if (is_better(entry, cutoff)) {
                min_heap.pop();
                min_heap.push(std::move(entry));
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
