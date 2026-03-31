/**
 * @file test_dijkstra.cpp
 * @brief Dijkstra 算法单元测试
 */

#include <gtest/gtest.h>
#include "graph.h"
#include "dijkstra.h"

using namespace tourism::graph;

// 测试基本最短路径
TEST(DijkstraTest, BasicShortestPath) {
    Graph g;
    
    // 创建简单图：1 -> 2 -> 3
    g.add_node(1, "Node1", 116.0, 39.0);
    g.add_node(2, "Node2", 116.1, 39.1);
    g.add_node(3, "Node3", 116.2, 39.2);
    
    g.add_edge(1, 2, 5.0, "walk", 100, 60);
    g.add_edge(2, 3, 3.0, "walk", 80, 48);
    g.add_edge(1, 3, 10.0, "walk", 200, 120);  // 直接路径更长
    
    auto result = dijkstra(g, 1, 3);
    
    EXPECT_TRUE(result.success);
    EXPECT_EQ(result.path, std::vector<int64_t>({1, 2, 3}));
    EXPECT_DOUBLE_EQ(result.total_weight, 8.0);
}

// 测试起点等于终点
TEST(DijkstraTest, SameStartEnd) {
    Graph g;
    g.add_node(1, "Node1", 116.0, 39.0);
    
    auto result = dijkstra(g, 1, 1);
    
    EXPECT_TRUE(result.success);
    EXPECT_EQ(result.path, std::vector<int64_t>({1}));
    EXPECT_DOUBLE_EQ(result.total_weight, 0.0);
}

// 测试无路径情况
TEST(DijkstraTest, NoPath) {
    Graph g;
    g.add_node(1, "Node1", 116.0, 39.0);
    g.add_node(2, "Node2", 116.1, 39.1);
    // 没有边
    
    auto result = dijkstra(g, 1, 2);
    
    EXPECT_FALSE(result.success);
    EXPECT_EQ(result.path.size(), 0);
}

// 测试不存在的节点
TEST(DijkstraTest, NonExistentNode) {
    Graph g;
    g.add_node(1, "Node1", 116.0, 39.0);
    
    auto result = dijkstra(g, 1, 999);
    
    EXPECT_FALSE(result.success);
    EXPECT_FALSE(result.error_message.empty());
}

// 测试多交通方式
TEST(DijkstraTest, MultiTransport) {
    Graph g;
    g.add_node(1, "Node1", 116.0, 39.0);
    g.add_node(2, "Node2", 116.1, 39.1);
    
    g.add_edge(1, 2, 10.0, "walk", 100, 1200);   // 步行慢
    g.add_edge(1, 2, 3.0, "bike", 100, 300);     // 自行车快
    
    // 不限制交通方式，应该选择权重最小的
    auto result1 = dijkstra(g, 1, 2);
    EXPECT_TRUE(result1.success);
    EXPECT_DOUBLE_EQ(result1.total_weight, 3.0);  // 选择自行车
    
    // 限制只能步行
    auto result2 = dijkstra(g, 1, 2, "walk");
    EXPECT_TRUE(result2.success);
    EXPECT_DOUBLE_EQ(result2.total_weight, 10.0);  // 只能步行
}

// 测试复杂图
TEST(DijkstraTest, ComplexGraph) {
    Graph g;
    
    // 创建更复杂的图
    g.add_node(1, "A", 116.0, 39.0);
    g.add_node(2, "B", 116.1, 39.1);
    g.add_node(3, "C", 116.2, 39.2);
    g.add_node(4, "D", 116.3, 39.3);
    
    g.add_edge(1, 2, 1.0, "walk", 50, 30);
    g.add_edge(1, 3, 4.0, "walk", 100, 60);
    g.add_edge(2, 3, 2.0, "walk", 60, 36);
    g.add_edge(2, 4, 6.0, "walk", 150, 90);
    g.add_edge(3, 4, 3.0, "walk", 80, 48);
    
    auto result = dijkstra(g, 1, 4);
    
    EXPECT_TRUE(result.success);
    // 最短路径：1 -> 2 -> 3 -> 4 (权重 1+2+3=6)
    EXPECT_EQ(result.path, std::vector<int64_t>({1, 2, 3, 4}));
    EXPECT_DOUBLE_EQ(result.total_weight, 6.0);
}

// 测试多目标 Dijkstra
TEST(DijkstraTest, MultiTarget) {
    Graph g;
    g.add_node(1, "Start", 116.0, 39.0);
    g.add_node(2, "Target1", 116.1, 39.1);
    g.add_node(3, "Target2", 116.2, 39.2);
    
    g.add_edge(1, 2, 5.0, "walk", 100, 60);
    g.add_edge(1, 3, 10.0, "walk", 200, 120);
    
    auto results = dijkstra_multi_target(g, 1, {2, 3});
    
    EXPECT_EQ(results.size(), 2);
    EXPECT_TRUE(results[2].success);
    EXPECT_TRUE(results[3].success);
    EXPECT_LT(results[2].total_weight, results[3].total_weight);
}

// 测试带约束的 Dijkstra
TEST(DijkstraTest, DijkstraWithConstraints) {
    Graph g;
    g.add_node(1, "Node1", 116.0, 39.0);
    g.add_node(2, "Node2", 116.1, 39.1);
    g.add_node(3, "Node3", 116.2, 39.2);
    
    g.add_edge(1, 2, 1.0, "walk", 100, 60);
    g.add_edge(2, 3, 1.0, "walk", 100, 60);
    g.add_edge(1, 3, 5.0, "car", 200, 30);  // 开车快但权重高
    
    // 只允许步行
    std::vector<std::string> allowed = {"walk"};
    auto result = dijkstra_with_constraints(g, 1, 3, allowed);
    
    EXPECT_TRUE(result.success);
    // 应该选择步行路径：1 -> 2 -> 3
    EXPECT_EQ(result.path, std::vector<int64_t>({1, 2, 3}));
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
