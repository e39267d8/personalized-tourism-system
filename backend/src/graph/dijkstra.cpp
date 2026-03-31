/**
 * @file dijkstra.cpp
 * @brief Dijkstra 最短路径算法实现
 */

#include "dijkstra.h"
#include <queue>
#include <limits>
#include <algorithm>
#include <tuple>

namespace tourism {
namespace graph {

/**
 * @brief 标准 Dijkstra 算法实现
 * 
 * 使用优先队列（最小堆）优化
 * 时间复杂度：O((V+E)logV)
 */
PathResult dijkstra(const Graph& graph, int64_t start, int64_t end,
                    const std::string& transport_filter) {
    PathResult result;
    
    // 检查节点是否存在
    if (!graph.has_node(start) || !graph.has_node(end)) {
        result.error_message = "Start or end node does not exist";
        return result;
    }
    
    // 特殊情况：起点和终点相同
    if (start == end) {
        result.path = {start};
        result.success = true;
        result.total_distance = 0.0;
        result.total_duration = 0;
        result.total_weight = 0.0;
        return result;
    }
    
    const double INF = std::numeric_limits<double>::max();
    
    // 距离映射：节点 ID -> 最短距离
    std::unordered_map<int64_t, double> dist;
    
    // 前驱映射：节点 ID -> (前驱节点 ID, 边)
    std::unordered_map<int64_t, std::pair<int64_t, Edge>> prev;
    
    // 最小堆：(距离，节点 ID)
    using PDI = std::pair<double, int64_t>;
    std::priority_queue<PDI, std::vector<PDI>, std::greater<PDI>> pq;
    
    // 初始化所有节点距离为无穷大
    auto all_nodes = graph.get_all_nodes();
    for (const auto& node : all_nodes) {
        dist[node.id] = INF;
    }
    
    // 起点距离为 0
    dist[start] = 0.0;
    pq.push({0.0, start});
    
    // Dijkstra 主循环
    while (!pq.empty()) {
        auto [d, u] = pq.top();
        pq.pop();
        
        // 如果当前距离大于已知最短距离，跳过
        if (d > dist[u]) {
            continue;
        }
        
        // 到达终点
        if (u == end) {
            break;
        }
        
        // 遍历邻居
        auto neighbors = graph.get_neighbors(u, transport_filter);
        for (const auto& edge : neighbors) {
            double alt = dist[u] + edge.weight;
            
            // 找到更短路径
            if (alt < dist[edge.to]) {
                dist[edge.to] = alt;
                prev[edge.to] = {u, edge};
                pq.push({alt, edge.to});
            }
        }
    }
    
    // 检查是否找到路径
    if (dist[end] == INF) {
        result.error_message = "No path found";
        return result;
    }
    
    // 重构路径
    std::vector<int64_t> path;
    std::vector<std::string> transports;
    int64_t current = end;
    
    while (current != start) {
        path.push_back(current);
        auto [pred, edge] = prev[current];
        transports.push_back(edge.transport_type);
        current = pred;
    }
    path.push_back(start);
    
    // 反转路径（从起点到终点）
    std::reverse(path.begin(), path.end());
    std::reverse(transports.begin(), transports.end());
    
    // 计算总距离和总耗时
    double total_distance = 0.0;
    int total_duration = 0;
    
    for (size_t i = 0; i < path.size() - 1; ++i) {
        auto edges = graph.get_neighbors(path[i]);
        for (const auto& edge : edges) {
            if (edge.to == path[i + 1]) {
                total_distance += edge.distance_meters;
                total_duration += edge.duration_seconds;
                break;
            }
        }
    }
    
    // 填充结果
    result.path = path;
    result.transport_modes = transports;
    result.total_distance = total_distance;
    result.total_duration = total_duration;
    result.total_weight = dist[end];
    result.success = true;
    
    return result;
}

/**
 * @brief 带约束的 Dijkstra 算法
 */
PathResult dijkstra_with_constraints(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::vector<std::string>& allowed_transports,
    const std::vector<int64_t>& avoid_segments,
    int time_budget_seconds
) {
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
    
    using PDI = std::pair<double, int64_t>;
    std::priority_queue<PDI, std::vector<PDI>, std::greater<PDI>> pq;
    
    // 初始化
    auto all_nodes = graph.get_all_nodes();
    for (const auto& node : all_nodes) {
        dist[node.id] = INF;
    }
    
    dist[start] = 0.0;
    pq.push({0.0, start});
    
    // 时间追踪
    std::unordered_map<int64_t, int> time_cost;
    time_cost[start] = 0;
    
    while (!pq.empty()) {
        auto [d, u] = pq.top();
        pq.pop();
        
        if (d > dist[u]) {
            continue;
        }
        
        if (u == end) {
            break;
        }
        
        auto neighbors = graph.get_neighbors(u);
        for (const auto& edge : neighbors) {
            // 检查交通方式约束
            if (!allowed_transports.empty() &&
                std::find(allowed_transports.begin(), allowed_transports.end(),
                         edge.transport_type) == allowed_transports.end()) {
                continue;  // 不允许的交通方式
            }
            
            // 检查是否需要避开该路段
            if (std::find(avoid_segments.begin(), avoid_segments.end(),
                         edge.id) != avoid_segments.end()) {
                continue;  // 需要避开
            }
            
            // 检查时间预算约束
            int new_time = time_cost[u] + edge.duration_seconds;
            if (time_budget_seconds > 0 && new_time > time_budget_seconds) {
                continue;  // 超出时间预算
            }
            
            double alt = dist[u] + edge.weight;
            
            if (alt < dist[edge.to]) {
                dist[edge.to] = alt;
                prev[edge.to] = {u, edge};
                time_cost[edge.to] = new_time;
                pq.push({alt, edge.to});
            }
        }
    }
    
    // 重构路径（与标准 Dijkstra 相同）
    if (dist[end] == INF) {
        result.error_message = "No path found with given constraints";
        return result;
    }
    
    std::vector<int64_t> path;
    std::vector<std::string> transports;
    int64_t current = end;
    
    while (current != start) {
        path.push_back(current);
        auto [pred, edge] = prev[current];
        transports.push_back(edge.transport_type);
        current = pred;
    }
    path.push_back(start);
    
    std::reverse(path.begin(), path.end());
    std::reverse(transports.begin(), transports.end());
    
    result.path = path;
    result.transport_modes = transports;
    result.total_distance = 0.0;  // 需要重新计算
    result.total_duration = time_cost[end];
    result.total_weight = dist[end];
    result.success = true;
    
    return result;
}

/**
 * @brief 多源 Dijkstra（从起点到多个目标）
 */
std::unordered_map<int64_t, PathResult> dijkstra_multi_target(
    const Graph& graph,
    int64_t start,
    const std::vector<int64_t>& ends,
    const std::string& transport_filter
) {
    std::unordered_map<int64_t, PathResult> results;
    
    if (!graph.has_node(start)) {
        return results;
    }
    
    const double INF = std::numeric_limits<double>::max();
    std::unordered_map<int64_t, double> dist;
    std::unordered_map<int64_t, std::pair<int64_t, Edge>> prev;
    
    using PDI = std::pair<double, int64_t>;
    std::priority_queue<PDI, std::vector<PDI>, std::greater<PDI>> pq;
    
    // 初始化
    auto all_nodes = graph.get_all_nodes();
    for (const auto& node : all_nodes) {
        dist[node.id] = INF;
    }
    
    dist[start] = 0.0;
    pq.push({0.0, start});
    
    // 目标集合（用于快速查找）
    std::unordered_map<int64_t, bool> target_set;
    for (int64_t end : ends) {
        target_set[end] = true;
        results[end] = PathResult();  // 初始化结果
    }
    
    // 已到达的目标
    std::unordered_map<int64_t, bool> reached;
    
    while (!pq.empty() && reached.size() < ends.size()) {
        auto [d, u] = pq.top();
        pq.pop();
        
        if (d > dist[u]) {
            continue;
        }
        
        // 如果到达目标
        if (target_set.count(u) && u != start) {
            reached[u] = true;
        }
        
        auto neighbors = graph.get_neighbors(u, transport_filter);
        for (const auto& edge : neighbors) {
            double alt = dist[u] + edge.weight;
            
            if (alt < dist[edge.to]) {
                dist[edge.to] = alt;
                prev[edge.to] = {u, edge};
                pq.push({alt, edge.to});
            }
        }
    }
    
    // 为每个目标重构路径
    for (int64_t end : ends) {
        if (!reached[end] || dist[end] == INF) {
            results[end].error_message = "No path found";
            continue;
        }
        
        PathResult result;
        std::vector<int64_t> path;
        std::vector<std::string> transports;
        int64_t current = end;
        
        while (current != start) {
            path.push_back(current);
            auto [pred, edge] = prev[current];
            transports.push_back(edge.transport_type);
            current = pred;
        }
        path.push_back(start);
        
        std::reverse(path.begin(), path.end());
        std::reverse(transports.begin(), transports.end());
        
        result.path = path;
        result.transport_modes = transports;
        result.total_weight = dist[end];
        result.success = true;
        
        results[end] = result;
    }
    
    return results;
}

/**
 * @brief 双向 Dijkstra 算法
 */
PathResult bidirectional_dijkstra(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::string& transport_filter
) {
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
    
    // 前向搜索（从起点）
    std::unordered_map<int64_t, double> dist_forward;
    std::unordered_map<int64_t, std::pair<int64_t, Edge>> prev_forward;
    
    // 后向搜索（从终点）
    std::unordered_map<int64_t, double> dist_backward;
    std::unordered_map<int64_t, std::pair<int64_t, Edge>> prev_backward;
    
    using PDI = std::pair<double, int64_t>;
    std::priority_queue<PDI, std::vector<PDI>, std::greater<PDI>> pq_forward;
    std::priority_queue<PDI, std::vector<PDI>, std::greater<PDI>> pq_backward;
    
    // 初始化
    auto all_nodes = graph.get_all_nodes();
    for (const auto& node : all_nodes) {
        dist_forward[node.id] = INF;
        dist_backward[node.id] = INF;
    }
    
    dist_forward[start] = 0.0;
    dist_backward[end] = 0.0;
    
    pq_forward.push({0.0, start});
    pq_backward.push({0.0, end});
    
    // 最优相遇点
    int64_t meeting_node = -1;
    double best_distance = INF;
    
    // 双向搜索
    while (!pq_forward.empty() && !pq_backward.empty()) {
        // 前向扩展
        auto [d_fwd, u_fwd] = pq_forward.top();
        pq_forward.pop();
        
        if (d_fwd < dist_forward[u_fwd]) {
            continue;
        }
        
        // 检查是否可以更新最优相遇点
        if (dist_backward.count(u_fwd) && dist_backward[u_fwd] < INF) {
            double total = dist_forward[u_fwd] + dist_backward[u_fwd];
            if (total < best_distance) {
                best_distance = total;
                meeting_node = u_fwd;
            }
        }
        
        // 后向扩展
        auto [d_bwd, u_bwd] = pq_backward.top();
        pq_backward.pop();
        
        if (d_bwd < dist_backward[u_bwd]) {
            continue;
        }
        
        // 检查是否可以更新最优相遇点
        if (dist_forward.count(u_bwd) && dist_forward[u_bwd] < INF) {
            double total = dist_forward[u_bwd] + dist_backward[u_bwd];
            if (total < best_distance) {
                best_distance = total;
                meeting_node = u_bwd;
            }
        }
        
        // 扩展前向邻居
        auto neighbors_fwd = graph.get_neighbors(u_fwd, transport_filter);
        for (const auto& edge : neighbors_fwd) {
            double alt = dist_forward[u_fwd] + edge.weight;
            if (alt < dist_forward[edge.to]) {
                dist_forward[edge.to] = alt;
                prev_forward[edge.to] = {u_fwd, edge};
                pq_forward.push({alt, edge.to});
            }
        }
        
        // 扩展后向邻居（需要反向图，这里简化处理）
        // 实际实现需要构建反向图或查找所有指向 u_bwd 的边
        // 为简化，这里使用单源 Dijkstra
    }
    
    // 如果双向搜索复杂，退化到标准 Dijkstra
    return dijkstra(graph, start, end, transport_filter);
}

/**
 * @brief 增量 Dijkstra（动态权重更新）
 */
PathResult incremental_dijkstra(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::vector<std::tuple<int64_t, int64_t, std::string>>& changed_edges,
    const PathResult& previous_result
) {
    // 简化实现：如果权重变化影响原路径，则重新计算
    // 否则直接返回原路径
    
    if (!previous_result.success) {
        return dijkstra(graph, start, end);
    }
    
    // 检查变化的边是否在原路径上
    bool affected = false;
    const auto& path = previous_result.path;
    
    for (size_t i = 0; i < path.size() - 1; ++i) {
        for (const auto& [from, to, transport] : changed_edges) {
            if (path[i] == from && path[i + 1] == to) {
                affected = true;
                break;
            }
        }
        if (affected) break;
    }
    
    if (!affected) {
        // 原路径未受影响
        return previous_result;
    }
    
    // 重新计算
    return dijkstra(graph, start, end);
}

} // namespace graph
} // namespace tourism
