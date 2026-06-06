#pragma once

#include "dijkstra.h"
#include <functional>
#include <map>
#include <string>
#include <vector>

namespace tourism {
namespace graph {

/**
 * @brief Congestion-aware Dijkstra variant.
 * 
 * Computes edge weights as: base_weight + dynamic_weight * congestion_level
 * where congestion_level is looked up per edge.
 */
PathResult dijkstra_congestion_aware(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::string& transport_filter,
    const std::map<int64_t, double>& edge_congestion);

/**
 * @brief Simulate congestion levels by time of day and transport mode.
 * 
 * Returns a map from edge_id to congestion factor (0.0-5.0).
 * Higher = more congested.
 * 
 * Peak hours: 7-9, 17-19 -> high congestion for car/bus
 * Off-peak: 22-6 -> low congestion
 * Walk/bike: less affected by time
 */
std::map<int64_t, double> simulate_congestion_by_time(
    const Graph& graph,
    int hour,
    const std::string& transport_mode,
    double base_bias = 1.0);

/**
 * @brief Get a descriptive label for a congestion level.
 */
const char* congestion_label(double level);

/**
 * @brief Get color hex for a congestion level (for UI display).
 */
const char* congestion_color(double level);

} // namespace graph
} // namespace tourism
