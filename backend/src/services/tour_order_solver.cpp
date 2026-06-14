#include "services/tour_order_solver.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <numeric>
#include <unordered_set>

namespace tourism::services {
namespace {

constexpr double kInf = std::numeric_limits<double>::infinity();
constexpr int kMaxExactRemaining = 9;

double cycle_weight(const TspDistanceMatrix& matrix, const std::vector<int>& order) {
    if (order.size() != static_cast<size_t>(matrix.size) || order.empty() || order[0] != 0) return kInf;
    double total = 0.0;
    for (size_t i = 0; i + 1 < order.size(); ++i) {
        double edge = matrix.weight[order[i]][order[i + 1]];
        if (edge >= kInf) return kInf;
        total += edge;
    }
    double back = matrix.weight[order.back()][0];
    return back >= kInf ? kInf : total + back;
}

void fill_stats(const TspDistanceMatrix& matrix, const std::vector<int>& order, TspResult& result) {
    result.total_distance = 0.0;
    result.total_duration = 0;
    result.total_weight = 0.0;
    for (size_t i = 0; i + 1 < order.size(); ++i) {
        result.total_distance += matrix.distance[order[i]][order[i + 1]];
        result.total_duration += matrix.duration[order[i]][order[i + 1]];
        result.total_weight += matrix.weight[order[i]][order[i + 1]];
    }
    result.total_distance += matrix.distance[order.back()][0];
    result.total_duration += matrix.duration[order.back()][0];
    result.total_weight += matrix.weight[order.back()][0];
}

bool matrix_reachable(const TspDistanceMatrix& matrix) {
    for (int i = 0; i < matrix.size; ++i) {
        for (int j = 0; j < matrix.size; ++j) {
            if (i != j && matrix.weight[i][j] >= kInf) return false;
        }
    }
    return true;
}

} // namespace

TspResult solve_ordered_tsp(const TspDistanceMatrix& matrix,
                            const std::vector<TourOrderConstraint>& constraints) {
    TspResult result;
    result.algorithm_used = "约束多点最短回路";
    if (matrix.size < 3) {
        result.error = "环游至少需要1个出发点和2个目标地点";
        return result;
    }
    if (!matrix_reachable(matrix)) {
        result.error = "部分点之间不可达";
        return result;
    }

    const int target_count = matrix.size - 1;
    std::vector<int> fixed_at_order(target_count + 1, -1);
    std::unordered_set<int> fixed_points;
    for (const auto& constraint : constraints) {
        if (constraint.point_index <= 0 || constraint.point_index >= matrix.size) {
            result.error = "指定顺序包含无效目标";
            return result;
        }
        if (constraint.order <= 0 || constraint.order > target_count) {
            result.error = "指定到达序号超出目标数量范围";
            return result;
        }
        if (fixed_at_order[constraint.order] != -1) {
            result.error = "不能重复指定同一个到达序号";
            return result;
        }
        if (!fixed_points.insert(constraint.point_index).second) {
            result.error = "不能为同一个目标重复指定顺序";
            return result;
        }
        fixed_at_order[constraint.order] = constraint.point_index;
    }

    std::vector<int> remaining_points;
    std::vector<int> remaining_positions;
    for (int point = 1; point < matrix.size; ++point) {
        if (!fixed_points.count(point)) remaining_points.push_back(point);
    }
    for (int order = 1; order <= target_count; ++order) {
        if (fixed_at_order[order] == -1) remaining_positions.push_back(order);
    }

    std::vector<int> best_order(matrix.size, 0);
    double best_weight = kInf;

    auto materialize = [&](const std::vector<int>& points_for_positions) {
        std::vector<int> order(matrix.size, 0);
        size_t cursor = 0;
        for (int pos = 1; pos <= target_count; ++pos) {
            if (fixed_at_order[pos] > 0) order[pos] = fixed_at_order[pos];
            else order[pos] = points_for_positions[cursor++];
        }
        return order;
    };

    if (remaining_points.size() <= kMaxExactRemaining) {
        std::sort(remaining_points.begin(), remaining_points.end());
        do {
            std::vector<int> candidate = materialize(remaining_points);
            double weight = cycle_weight(matrix, candidate);
            if (weight < best_weight) {
                best_weight = weight;
                best_order = std::move(candidate);
            }
        } while (std::next_permutation(remaining_points.begin(), remaining_points.end()));
        result.algorithm_used = constraints.empty() ? "精确枚举" : "约束精确枚举";
    } else {
        std::vector<int> candidate(matrix.size, 0);
        std::unordered_set<int> unused(remaining_points.begin(), remaining_points.end());
        for (int pos = 1; pos <= target_count; ++pos) {
            if (fixed_at_order[pos] > 0) {
                candidate[pos] = fixed_at_order[pos];
                continue;
            }
            int prev = candidate[pos - 1];
            int next_fixed = -1;
            for (int next = pos + 1; next <= target_count; ++next) {
                if (fixed_at_order[next] > 0) {
                    next_fixed = fixed_at_order[next];
                    break;
                }
            }
            int best_point = -1;
            double best_score = kInf;
            for (int point : unused) {
                double score = matrix.weight[prev][point];
                if (next_fixed > 0) score += matrix.weight[point][next_fixed] * 0.25;
                if (score < best_score || (std::abs(score - best_score) < 1e-9 && point < best_point)) {
                    best_score = score;
                    best_point = point;
                }
            }
            if (best_point < 0) {
                result.error = "未找到可行环游路线";
                return result;
            }
            candidate[pos] = best_point;
            unused.erase(best_point);
        }

        bool improved = true;
        while (improved) {
            improved = false;
            for (int left = 1; left <= target_count; ++left) {
                if (fixed_at_order[left] > 0) continue;
                for (int right = left + 1; right <= target_count; ++right) {
                    if (fixed_at_order[right] > 0) continue;
                    double before = cycle_weight(matrix, candidate);
                    std::swap(candidate[left], candidate[right]);
                    double after = cycle_weight(matrix, candidate);
                    if (after < before) improved = true;
                    else std::swap(candidate[left], candidate[right]);
                }
            }
        }
        best_order = std::move(candidate);
        best_weight = cycle_weight(matrix, best_order);
        result.algorithm_used = constraints.empty() ? "近邻优化(2-opt)" : "约束近邻优化(2-opt)";
    }

    if (best_weight >= kInf) {
        result.error = "未找到可行环游路线";
        return result;
    }

    result.success = true;
    result.best_order = std::move(best_order);
    fill_stats(matrix, result.best_order, result);
    return result;
}

} // namespace tourism::services
