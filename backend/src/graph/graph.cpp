/**
 * @file graph.cpp
 * @brief 图数据结构实现
 */

#include "graph.h"
#include <algorithm>
#include <stdexcept>

// 如果需要 JSON 序列化，包含 nlohmann/json
// #include <nlohmann/json.hpp>

namespace tourism {
namespace graph {

bool Graph::add_node(int64_t id, const std::string& name,
                     double lon, double lat, const std::string& type) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 检查节点是否已存在
    if (nodes_.count(id) > 0) {
        return false;  // 节点已存在
    }
    
    // 创建节点
    Node node(id, name, lon, lat, type);
    nodes_[id] = node;
    
    // 初始化邻接表条目
    if (adj_list_.count(id) == 0) {
        adj_list_[id] = std::vector<Edge>();
    }
    
    return true;
}

bool Graph::remove_node(int64_t id) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 检查节点是否存在
    if (nodes_.count(id) == 0) {
        return false;  // 节点不存在
    }
    
    // 移除该节点的所有出边
    adj_list_.erase(id);
    
    // 移除所有指向该节点的入边
    for (auto& [from_id, edges] : adj_list_) {
        edges.erase(
            std::remove_if(edges.begin(), edges.end(),
                [id](const Edge& e) { return e.to == id; }),
            edges.end()
        );
    }
    
    // 移除节点本身
    nodes_.erase(id);
    
    return true;
}

bool Graph::add_edge(int64_t from, int64_t to, double weight,
                     const std::string& transport, int distance, int duration,
                     double base_weight, double dynamic_weight) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    // 检查节点是否存在
    if (nodes_.count(from) == 0 || nodes_.count(to) == 0) {
        return false;  // 节点不存在
    }
    
    // 检查是否已存在相同交通方式的边
    auto& edges = adj_list_[from];
    for (const auto& edge : edges) {
        if (edge.to == to && edge.transport_type == transport) {
            // 已存在，可以选择更新或返回错误
            return false;
        }
    }
    
    // 创建边
    Edge edge(0, to, weight, transport, distance, duration, 
              base_weight, dynamic_weight);
    edges.push_back(edge);
    
    return true;
}

int Graph::remove_edge(int64_t from, int64_t to, const std::string& transport) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (adj_list_.count(from) == 0) {
        return 0;  // 没有出边
    }
    
    auto& edges = adj_list_[from];
    int removed_count = 0;
    
    if (transport.empty()) {
        // 移除所有到目标节点的边
        auto it = std::remove_if(edges.begin(), edges.end(),
            [to](const Edge& e) { return e.to == to; });
        removed_count = static_cast<int>(std::distance(it, edges.end()));
        edges.erase(it, edges.end());
    } else {
        // 移除特定交通方式的边
        auto it = std::remove_if(edges.begin(), edges.end(),
            [to, &transport](const Edge& e) {
                return e.to == to && e.transport_type == transport;
            });
        removed_count = static_cast<int>(std::distance(it, edges.end()));
        edges.erase(it, edges.end());
    }
    
    return removed_count;
}

const Node* Graph::get_node(int64_t id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = nodes_.find(id);
    if (it != nodes_.end()) {
        return &(it->second);
    }
    return nullptr;
}

std::vector<Edge> Graph::get_neighbors(int64_t node_id, 
                                        const std::string& transport_filter) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = adj_list_.find(node_id);
    if (it == adj_list_.end()) {
        return std::vector<Edge>();  // 没有邻居
    }
    
    if (transport_filter.empty()) {
        return it->second;  // 返回所有邻居
    }
    
    // 过滤特定交通方式
    std::vector<Edge> filtered;
    for (const auto& edge : it->second) {
        if (edge.transport_type == transport_filter) {
            filtered.push_back(edge);
        }
    }
    return filtered;
}

std::vector<Node> Graph::get_all_nodes() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<Node> result;
    result.reserve(nodes_.size());
    
    for (const auto& [id, node] : nodes_) {
        result.push_back(node);
    }
    
    return result;
}

std::vector<Edge> Graph::get_all_edges() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<Edge> result;
    
    for (const auto& [from_id, edges] : adj_list_) {
        for (const auto& edge : edges) {
            result.push_back(edge);
        }
    }
    
    return result;
}

size_t Graph::node_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return nodes_.size();
}

size_t Graph::edge_count() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    size_t count = 0;
    for (const auto& [from_id, edges] : adj_list_) {
        count += edges.size();
    }
    return count;
}

bool Graph::has_node(int64_t id) const {
    std::lock_guard<std::mutex> lock(mutex_);
    return nodes_.count(id) > 0;
}

bool Graph::has_edge(int64_t from, int64_t to, 
                     const std::string& transport) const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = adj_list_.find(from);
    if (it == adj_list_.end()) {
        return false;
    }
    
    for (const auto& edge : it->second) {
        if (edge.to == to) {
            if (transport.empty() || edge.transport_type == transport) {
                return true;
            }
        }
    }
    
    return false;
}

bool Graph::update_edge_weight(int64_t from, int64_t to,
                               const std::string& transport, double new_weight) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = adj_list_.find(from);
    if (it == adj_list_.end()) {
        return false;
    }
    
    for (auto& edge : it->second) {
        if (edge.to == to && edge.transport_type == transport) {
            edge.weight = new_weight;
            return true;
        }
    }
    
    return false;
}

void Graph::clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    nodes_.clear();
    adj_list_.clear();
}

// JSON 序列化（需要 nlohmann/json）
/*
std::string Graph::to_json() const {
    std::lock_guard<std::mutex> lock(mutex_);
    
    nlohmann::json j;
    j["nodes"] = nlohmann::json::array();
    j["edges"] = nlohmann::json::array();
    
    for (const auto& [id, node] : nodes_) {
        j["nodes"].push_back({
            {"id", node.id},
            {"name", node.name},
            {"lon", node.longitude},
            {"lat", node.latitude},
            {"type", node.type}
        });
    }
    
    for (const auto& [from_id, edges] : adj_list_) {
        for (const auto& edge : edges) {
            j["edges"].push_back({
                {"from", from_id},
                {"to", edge.to},
                {"weight", edge.weight},
                {"transport", edge.transport_type},
                {"distance", edge.distance_meters},
                {"duration", edge.duration_seconds}
            });
        }
    }
    
    return j.dump();
}

bool Graph::from_json(const std::string& json_str) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto j = nlohmann::json::parse(json_str);
    
    // 清空现有数据
    nodes_.clear();
    adj_list_.clear();
    
    // 解析节点
    for (const auto& node_json : j["nodes"]) {
        Node node;
        node.id = node_json["id"];
        node.name = node_json["name"];
        node.longitude = node_json["lon"];
        node.latitude = node_json["lat"];
        node.type = node_json["type"];
        nodes_[node.id] = node;
    }
    
    // 解析边
    for (const auto& edge_json : j["edges"]) {
        int64_t from = edge_json["from"];
        Edge edge;
        edge.to = edge_json["to"];
        edge.weight = edge_json["weight"];
        edge.transport_type = edge_json["transport"];
        edge.distance_meters = edge_json["distance"];
        edge.duration_seconds = edge_json["duration"];
        
        if (adj_list_.count(from) == 0) {
            adj_list_[from] = std::vector<Edge>();
        }
        adj_list_[from].push_back(edge);
    }
    
    return true;
}
*/

} // namespace graph
} // namespace tourism
