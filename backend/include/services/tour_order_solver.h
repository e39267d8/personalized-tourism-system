#pragma once

#include <string>
#include <vector>

namespace tourism::services {

struct TspDistanceMatrix {
    std::vector<std::vector<double>> distance;
    std::vector<std::vector<int>> duration;
    std::vector<std::vector<double>> weight;
    int size = 0;
};

struct TspResult {
    bool success = false;
    std::string error;
    std::vector<int> best_order;
    double total_distance = 0.0;
    int total_duration = 0;
    double total_weight = 0.0;
    std::string algorithm_used;
};

struct TourOrderConstraint {
    int point_index = 0; // index in TspDistanceMatrix, 0 is the fixed start
    int order = 0;       // 1-based target visit order, excluding start and return leg
};

TspResult solve_ordered_tsp(const TspDistanceMatrix& matrix,
                            const std::vector<TourOrderConstraint>& constraints);

} // namespace tourism::services
