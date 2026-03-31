/**
 * @file dijkstra.h
 * @brief Dijkstra 最短路径算法实现
 * @author yhm, zby, lxd
 * @version 1.0
 * @date 2026-03-31
 * 
 * 数据结构课程设计 - 个性化旅游系统
 * 
 * 算法特性：
 * 1. 使用自定义最小堆（优先队列）
 * 2. 时间复杂度：O((V+E)logV)
 * 3. 支持动态权重更新（拥挤度）
 * 4. 支持多交通方式约束
 * 
 * 数据结构要求：
 * - 优先队列：最小堆（禁止使用 O(n) 遍历）
 * - 距离映射：哈希表 O(1) 查找
 * - 前驱映射：哈希表 O(1) 查找
 */

#ifndef DIJKSTRA_H
#define DIJKSTRA_H

#include "graph.h"
#include <queue>
#include <vector>
#include <limits>
#include <unordered_map>
#include <cstdint>

namespace tourism {
namespace graph {

/**
 * @brief 路径规划结果
 */
struct PathResult {
    std::vector<int64_t> path;      // 路径节点序列
    std::vector<std::string> transport_modes;  // 每段的交通方式
    double total_distance;           // 总距离（米）
    int total_duration;              // 总耗时（秒）
    double total_weight;             // 总权重
    bool success;                    // 是否成功找到路径
    std::string error_message;       // 错误信息（如果有）
    
    PathResult() 
        : total_distance(0.0), total_duration(0), 
          total_weight(0.0), success(false) {}
};

/**
 * @brief 优先队列元素（距离，节点 ID）
 */
using DistanceNodePair = std::pair<double, int64_t>;

/**
 * @brief Dijkstra 最短路径算法
 * 
 * @param graph 图
 * @param start 起始节点 ID
 * @param end 目标节点 ID
 * @param transport_filter 交通方式过滤（可选，空字符串表示不限）
 * @return 路径结果
 * 
 * 时间复杂度：O((V+E)logV)
 * 空间复杂度：O(V+E)
 */
PathResult dijkstra(const Graph& graph, int64_t start, int64_t end,
                    const std::string& transport_filter = "");

/**
 * @brief Dijkstra 算法（多约束版本）
 * 
 * 支持：
 * 1. 多种交通方式选择
 * 2. 避开特定路段
 * 3. 时间预算约束
 * 
 * @param graph 图
 * @param start 起始节点 ID
 * @param end 目标节点 ID
 * @param allowed_transports 允许的交通方式列表（空表示全部允许）
 * @param avoid_segments 需要避开的路段 ID 列表
 * @param time_budget_seconds 时间预算（秒，0 表示无限制）
 * @return 路径结果
 */
PathResult dijkstra_with_constraints(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::vector<std::string>& allowed_transports = {},
    const std::vector<int64_t>& avoid_segments = {},
    int time_budget_seconds = 0
);

/**
 * @brief 多源 Dijkstra（从起点到多个目标的最短路径）
 * 
 * @param graph 图
 * @param start 起始节点 ID
 * @param ends 多个目标节点 ID 列表
 * @param transport_filter 交通方式过滤
 * @return 起点到每个目标的路径结果映射
 */
std::unordered_map<int64_t, PathResult> dijkstra_multi_target(
    const Graph& graph,
    int64_t start,
    const std::vector<int64_t>& ends,
    const std::string& transport_filter = ""
);

/**
 * @brief 双向 Dijkstra 算法（优化版）
 * 
 * 从起点和终点同时开始搜索，在中间相遇
 * 适用于单点对单点的快速查询
 * 
 * @param graph 图
 * @param start 起始节点 ID
 * @param end 目标节点 ID
 * @param transport_filter 交通方式过滤
 * @return 路径结果
 */
PathResult bidirectional_dijkstra(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::string& transport_filter = ""
);

/**
 * @brief 动态权重更新后的增量 Dijkstra
 * 
 * 当部分边的权重发生变化时，避免全量重计算
 * 仅重新计算受影响的路径
 * 
 * @param graph 图
 * @param start 起始节点 ID
 * @param end 目标节点 ID
 * @param changed_edges 权重发生变化的边列表
 * @param previous_result 之前的路径结果
 * @return 更新后的路径结果
 */
PathResult incremental_dijkstra(
    const Graph& graph,
    int64_t start,
    int64_t end,
    const std::vector<std::tuple<int64_t, int64_t, std::string>>& changed_edges,
    const PathResult& previous_result
);

} // namespace graph
} // namespace tourism

#endif // DIJKSTRA_H
