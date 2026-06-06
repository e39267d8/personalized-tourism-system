#include "graph/congestion.h"

#include "graph/graph.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <unordered_map>

namespace tourism {
namespace graph {

PathResult dijkstra_congestion_aware(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::string& transport_filter,
    const std::map<int64_t, double>& edge_congestion) {

    PathResult result;

    if (!graph.has_node(start) || !graph.has_node(end)) {
        result.error_message = "Start or end node does not exist";
        return result;
    }

    if (start == end) {
        result.path = {start};
        result.success = true;
        return result;
    }

    const double INF = std::numeric_limits<double>::max();

    std::unordered_map<int64_t, double> dist;
    std::unordered_map<int64_t, std::pair<int64_t, Edge>> prev;

    auto all_nodes = graph.get_all_nodes();
    for (const auto& node : all_nodes) {
        dist[node.id] = INF;
    }

    dist[start] = 0.0;
    using PDI = std::pair<double, int64_t>;
    std::priority_queue<PDI, std::vector<PDI>, std::greater<PDI>> pq;
    pq.push({0.0, start});

    while (!pq.empty()) {
        auto [d, u] = pq.top();
        pq.pop();

        if (d > dist[u]) continue;
        if (u == end) break;

        auto neighbors = graph.get_neighbors(u, transport_filter);
        for (const auto& edge : neighbors) {
            // Compute congestion-adjusted weight
            double weight = edge.base_weight;
            auto cong_it = edge_congestion.find(edge.id);
            if (cong_it != edge_congestion.end()) {
                weight += edge.dynamic_weight * cong_it->second;
            } else {
                weight += edge.dynamic_weight; // default congestion = 1.0
            }
            if (weight <= 0.0) weight = edge.weight; // fallback

            double alt = dist[u] + weight;
            if (alt < dist[edge.to]) {
                dist[edge.to] = alt;
                prev[edge.to] = {u, edge};
                pq.push({alt, edge.to});
            }
        }
    }

    if (dist.find(end) == dist.end() || dist[end] >= INF - 1.0) {
        result.error_message = "No path found with congestion awareness";
        return result;
    }

    // Reconstruct path
    std::vector<int64_t> path;
    std::vector<std::string> transports;
    double total_dist = 0.0;
    int total_dur = 0;
    for (int64_t at = end; at != start;) {
        auto it = prev.find(at);
        if (it == prev.end()) break;
        path.push_back(at);
        const auto& [prev_node, edge] = it->second;
        transports.push_back(edge.transport_type);
        total_dist += edge.distance_meters;
        total_dur += edge.duration_seconds;
        at = prev_node;
    }
    path.push_back(start);
    std::reverse(path.begin(), path.end());
    std::reverse(transports.begin(), transports.end());

    result.path = path;
    result.transport_modes = transports;
    result.total_distance = total_dist;
    result.total_duration = total_dur;
    result.total_weight = dist[end];
    result.success = true;
    return result;
}

std::map<int64_t, double> simulate_congestion_by_time(
    const Graph& graph,
    int hour,
    const std::string& transport_mode,
    double base_bias) {

    std::map<int64_t, double> result;

    auto time_factor = [](int h) -> double {
        if (h >= 7 && h <= 9) return 3.5;
        if (h >= 17 && h <= 19) return 4.0;
        if (h >= 9 && h <= 11) return 2.0;
        if (h >= 14 && h <= 17) return 2.2;
        if (h >= 19 && h <= 21) return 1.8;
        if (h >= 11 && h <= 14) return 1.3;
        if (h >= 5 && h <= 7) return 1.2;
        if (h >= 21 && h <= 23) return 0.8;
        return 0.5;
    };

    auto mode_mult = [](const std::string& mode) -> double {
        if (mode == "car" || mode == "bus") return 2.5;
        if (mode == "subway") return 1.8;
        if (mode == "bike") return 1.1;
        return 1.0;
    };

    double base_factor = time_factor(hour) * mode_mult(transport_mode) * base_bias;

    auto all_edges = graph.get_all_edges();
    for (const auto& e : all_edges) {
        if (!transport_mode.empty() && e.transport_type != transport_mode) continue;
        double variation = 1.0 + (static_cast<double>(e.id % 17) - 8.0) / 10.0;
        variation = std::max(0.3, std::min(2.0, variation));
        result[e.id] = std::max(0.3, std::min(5.0, base_factor * variation));
    }

    return result;
}

const char* congestion_label(double level) {
    if (level <= 0.8) return "\u7545\u901a";      // 畅通
    if (level <= 1.5) return "\u8f7b\u5fae\u62e5\u5835"; // 轻微拥堵
    if (level <= 2.5) return "\u4e2d\u5ea6\u62e5\u5835"; // 中度拥堵
    if (level <= 3.5) return "\u4e25\u91cd\u62e5\u5835"; // 严重拥堵
    return "\u6781\u5ea6\u62e5\u5835";             // 极度拥堵
}

const char* congestion_color(double level) {
    if (level <= 0.8) return "#22c55e";
    if (level <= 1.5) return "#84cc16";
    if (level <= 2.5) return "#eab308";
    if (level <= 3.5) return "#f97316";
    return "#ef4444";
}

} // namespace graph
} // namespace tourism
