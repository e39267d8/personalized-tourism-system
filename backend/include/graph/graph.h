/**
 * @file graph.h
 * @brief 图数据结构定义（邻接表实现）
 * @author yhm, zby, lxd
 * @version 1.0
 * @date 2026-03-31
 * 
 * 数据结构课程设计 - 个性化旅游系统
 * 核心图数据结构：支持多重边（不同交通方式）
 */

#ifndef GRAPH_H
#define GRAPH_H

#include <vector>
#include <unordered_map>
#include <string>
#include <memory>
#include <optional>
#include <mutex>

namespace tourism {
namespace graph {

/**
 * @brief 边（Edge）结构
 * 支持多重边：同一对节点间可以有多种交通方式的边
 */
struct Edge {
    int64_t id;              // 边 ID（对应数据库 graph_edges.id）
    int64_t to;              // 目标节点 ID
    double weight;           // 权重（用于路径规划）
    std::string transport_type;  // 交通方式：'walk', 'bike', 'car', 'bus', 'subway'
    int distance_meters;     // 实际距离（米）
    int duration_seconds;    // 预计耗时（秒）
    double base_weight;      // 基础权重
    double dynamic_weight;   // 动态权重（考虑拥挤度等）
    
    Edge() : id(0), to(0), weight(0.0), distance_meters(0), 
             duration_seconds(0), base_weight(0.0), dynamic_weight(0.0) {}
    
    Edge(int64_t id, int64_t to, double weight, const std::string& transport,
         int distance, int duration, double base_w = 0.0, double dynamic_w = 0.0)
        : id(id), to(to), weight(weight), transport_type(transport),
          distance_meters(distance), duration_seconds(duration),
          base_weight(base_w), dynamic_weight(dynamic_w) {}
};

/**
 * @brief 节点（Node）结构
 * 可以是景点、路口、交通枢纽等
 */
struct Node {
    int64_t id;              // 节点 ID（对应数据库 graph_nodes.id）
    std::string name;        // 节点名称
    double longitude;        // 经度（WGS84）
    double latitude;         // 纬度（WGS84）
    std::string type;        // 节点类型：'scenic', 'junction', 'transport', 'facility'
    int64_t scenic_spot_id;  // 关联的景点 ID（如果有）
    int64_t facility_id;     // 关联的设施 ID（如果有）
    
    Node() : id(0), longitude(0.0), latitude(0.0), 
             scenic_spot_id(0), facility_id(0) {}
    
    Node(int64_t id, const std::string& name, double lon, double lat, 
         const std::string& type = "junction")
        : id(id), name(name), longitude(lon), latitude(lat), 
          type(type), scenic_spot_id(0), facility_id(0) {}
};

/**
 * @brief 图（Graph）类 - 邻接表实现
 * 
 * 特性：
 * 1. 支持有向图（道路通常是有向的）
 * 2. 支持多重边（同一对节点间多种交通方式）
 * 3. 线程安全（使用读写锁）
 * 4. 动态权重更新（支持拥挤度等实时因素）
 * 
 * 时间复杂度：
 * - add_node: O(1)
 * - add_edge: O(1)
 * - get_neighbors: O(1)
 * - get_node: O(1)
 */
class Graph {
public:
    /**
     * @brief 构造空图
     */
    Graph() = default;
    
    /**
     * @brief 析构函数
     */
    ~Graph() = default;
    
    // 禁止拷贝（使用移动语义）
    Graph(const Graph&) = delete;
    Graph& operator=(const Graph&) = delete;
    
    // 允许移动
    Graph(Graph&&) = default;
    Graph& operator=(Graph&&) = default;

    /**
     * @brief 添加节点
     * @param id 节点 ID
     * @param name 节点名称
     * @param lon 经度
     * @param lat 纬度
     * @param type 节点类型
     * @return 是否成功
     */
    bool add_node(int64_t id, const std::string& name, 
                  double lon, double lat, const std::string& type = "junction");
    
    /**
     * @brief 移除节点（同时移除相关边）
     * @param id 节点 ID
     * @return 是否成功
     */
    bool remove_node(int64_t id);
    
    /**
     * @brief 添加边
     * @param from 起始节点 ID
     * @param to 目标节点 ID
     * @param weight 权重
     * @param transport 交通方式
     * @param distance 距离（米）
     * @param duration 耗时（秒）
     * @param base_weight 基础权重
     * @param dynamic_weight 动态权重
     * @return 是否成功
     */
    bool add_edge(int64_t from, int64_t to, double weight,
                  const std::string& transport, int distance, int duration,
                  double base_weight = 0.0, double dynamic_weight = 0.0);
    
    /**
     * @brief 移除边
     * @param from 起始节点 ID
     * @param to 目标节点 ID
     * @param transport 交通方式（可选，不填则移除所有交通方式的边）
     * @return 移除的边数量
     */
    int remove_edge(int64_t from, int64_t to, 
                    const std::string& transport = "");
    
    /**
     * @brief 获取节点
     * @param id 节点 ID
     * @return 节点指针（如果不存在则返回 nullptr）
     */
    const Node* get_node(int64_t id) const;
    
    /**
     * @brief 获取节点的所有邻居边
     * @param node_id 节点 ID
     * @param transport_filter 交通方式过滤（可选）
     * @return 邻居边列表
     */
    std::vector<Edge> get_neighbors(int64_t node_id, 
                                    const std::string& transport_filter = "") const;
    
    /**
     * @brief 获取所有节点
     * @return 节点列表
     */
    std::vector<Node> get_all_nodes() const;
    
    /**
     * @brief 获取所有边
     * @return 边列表
     */
    std::vector<Edge> get_all_edges() const;
    
    /**
     * @brief 获取节点数量
     * @return 节点数
     */
    size_t node_count() const;
    
    /**
     * @brief 获取边数量
     * @return 边数
     */
    size_t edge_count() const;
    
    /**
     * @brief 检查节点是否存在
     * @param id 节点 ID
     * @return 是否存在
     */
    bool has_node(int64_t id) const;
    
    /**
     * @brief 检查边是否存在
     * @param from 起始节点 ID
     * @param to 目标节点 ID
     * @param transport 交通方式（可选）
     * @return 是否存在
     */
    bool has_edge(int64_t from, int64_t to, 
                  const std::string& transport = "") const;
    
    /**
     * @brief 更新边的动态权重（用于拥挤度等实时因素）
     * @param from 起始节点 ID
     * @param to 目标节点 ID
     * @param transport 交通方式
     * @param new_weight 新权重
     * @return 是否成功
     */
    bool update_edge_weight(int64_t from, int64_t to, 
                           const std::string& transport, double new_weight);
    
    /**
     * @brief 清空图
     */
    void clear();
    
    /**
     * @brief 导出为 JSON 字符串
     * @return JSON 字符串
     */
    std::string to_json() const;
    
    /**
     * @brief 从 JSON 字符串导入
     * @param json_str JSON 字符串
     * @return 是否成功
     */
    bool from_json(const std::string& json_str);

private:
    // 节点存储：ID -> Node
    std::unordered_map<int64_t, Node> nodes_;
    
    // 邻接表：节点 ID -> 边列表
    std::unordered_map<int64_t, std::vector<Edge>> adj_list_;
    
    // 线程锁
    mutable std::mutex mutex_;
};

} // namespace graph
} // namespace tourism

#endif // GRAPH_H
