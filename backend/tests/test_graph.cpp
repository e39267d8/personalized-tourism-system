/**
 * @file test_graph.cpp
 * @brief 图数据结构单元测试
 */

#include <gtest/gtest.h>
#include "graph.h"

using namespace tourism::graph;

// 测试节点添加
TEST(GraphTest, AddNode) {
    Graph g;
    
    // 添加节点
    EXPECT_TRUE(g.add_node(1, "Node1", 116.397, 39.916, "scenic"));
    EXPECT_TRUE(g.add_node(2, "Node2", 116.400, 39.920, "junction"));
    
    // 重复添加应失败
    EXPECT_FALSE(g.add_node(1, "Node1_Duplicate", 116.397, 39.916));
    
    // 验证节点数量
    EXPECT_EQ(g.node_count(), 2);
}

// 测试节点移除
TEST(GraphTest, RemoveNode) {
    Graph g;
    g.add_node(1, "Node1", 116.397, 39.916);
    g.add_node(2, "Node2", 116.400, 39.920);
    g.add_edge(1, 2, 1.0, "walk", 100, 60);
    
    // 移除节点
    EXPECT_TRUE(g.remove_node(1));
    
    // 验证节点已移除
    EXPECT_FALSE(g.has_node(1));
    EXPECT_EQ(g.node_count(), 1);
    
    // 验证相关边也被移除
    EXPECT_FALSE(g.has_edge(1, 2));
}

// 测试边添加
TEST(GraphTest, AddEdge) {
    Graph g;
    g.add_node(1, "Node1", 116.397, 39.916);
    g.add_node(2, "Node2", 116.400, 39.920);
    
    // 添加边
    EXPECT_TRUE(g.add_edge(1, 2, 1.0, "walk", 100, 60));
    
    // 验证边存在
    EXPECT_TRUE(g.has_edge(1, 2, "walk"));
    EXPECT_EQ(g.edge_count(), 1);
    
    // 重复添加应失败
    EXPECT_FALSE(g.add_edge(1, 2, 1.5, "walk", 100, 60));
    
    // 添加不同交通方式的边（多重边）
    EXPECT_TRUE(g.add_edge(1, 2, 0.5, "bike", 100, 30));
    EXPECT_EQ(g.edge_count(), 2);
}

// 测试获取邻居
TEST(GraphTest, GetNeighbors) {
    Graph g;
    g.add_node(1, "Node1", 116.397, 39.916);
    g.add_node(2, "Node2", 116.400, 39.920);
    g.add_node(3, "Node3", 116.410, 39.930);
    
    g.add_edge(1, 2, 1.0, "walk", 100, 60);
    g.add_edge(1, 3, 2.0, "bike", 200, 90);
    
    // 获取所有邻居
    auto neighbors = g.get_neighbors(1);
    EXPECT_EQ(neighbors.size(), 2);
    
    // 按交通方式过滤
    auto walk_neighbors = g.get_neighbors(1, "walk");
    EXPECT_EQ(walk_neighbors.size(), 1);
    EXPECT_EQ(walk_neighbors[0].to, 2);
}

// 测试图清空
TEST(GraphTest, Clear) {
    Graph g;
    g.add_node(1, "Node1", 116.397, 39.916);
    g.add_node(2, "Node2", 116.400, 39.920);
    g.add_edge(1, 2, 1.0, "walk", 100, 60);
    
    // 清空图
    g.clear();
    
    EXPECT_EQ(g.node_count(), 0);
    EXPECT_EQ(g.edge_count(), 0);
}

// 测试节点存在性检查
TEST(GraphTest, HasNode) {
    Graph g;
    EXPECT_FALSE(g.has_node(1));  // 不存在的节点
    
    g.add_node(1, "Node1", 116.397, 39.916);
    EXPECT_TRUE(g.has_node(1));
    EXPECT_FALSE(g.has_node(2));
}

// 测试边存在性检查
TEST(GraphTest, HasEdge) {
    Graph g;
    g.add_node(1, "Node1", 116.397, 39.916);
    g.add_node(2, "Node2", 116.400, 39.920);
    
    EXPECT_FALSE(g.has_edge(1, 2));  // 不存在的边
    
    g.add_edge(1, 2, 1.0, "walk", 100, 60);
    EXPECT_TRUE(g.has_edge(1, 2, "walk"));
    EXPECT_FALSE(g.has_edge(1, 2, "bike"));
}

// 测试边权重更新
TEST(GraphTest, UpdateEdgeWeight) {
    Graph g;
    g.add_node(1, "Node1", 116.397, 39.916);
    g.add_node(2, "Node2", 116.400, 39.920);
    g.add_edge(1, 2, 1.0, "walk", 100, 60);
    
    // 更新权重
    EXPECT_TRUE(g.update_edge_weight(1, 2, "walk", 2.0));
    
    auto neighbors = g.get_neighbors(1, "walk");
    EXPECT_EQ(neighbors[0].weight, 2.0);
}

// 测试获取所有节点
TEST(GraphTest, GetAllNodes) {
    Graph g;
    g.add_node(1, "Node1", 116.397, 39.916, "scenic");
    g.add_node(2, "Node2", 116.400, 39.920, "junction");
    
    auto nodes = g.get_all_nodes();
    EXPECT_EQ(nodes.size(), 2);
    
    // 验证节点属性
    bool found_node1 = false;
    for (const auto& node : nodes) {
        if (node.id == 1) {
            found_node1 = true;
            EXPECT_EQ(node.type, "scenic");
            EXPECT_EQ(node.longitude, 116.397);
        }
    }
    EXPECT_TRUE(found_node1);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
