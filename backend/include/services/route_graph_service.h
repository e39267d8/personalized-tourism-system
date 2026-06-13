#pragma once

#include "crow.h"
#include "db/postgres.h"

#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

namespace tourism::services {

struct RouteNode {
    int id = 0;
    std::string name;
    std::string type;
    std::string scenic_name;
    int scenic_spot_id = 0;
    int facility_id = 0;
    std::string facility_type;
    double longitude = 0.0;
    double latitude = 0.0;
    int congestion = 2;
};

struct RouteEdge {
    int id = 0;
    int from = 0;
    int to = 0;
    std::string mode;
    std::string source;
    double distance = 0.0;
    int duration = 0;
    int effective_duration = 0;
    double base_weight = 1.0;
    int congestion = 2;
    std::vector<std::pair<double, double>> coordinates;
};

struct RouteGraphData {
    std::unordered_map<int, RouteNode> nodes;
    std::unordered_map<int, std::vector<RouteEdge>> edges;
};

struct RouteSearchResult {
    bool success = false;
    bool used_transport_fallback = false;
    std::string error;
    std::vector<int> nodes;
    std::vector<RouteEdge> edges;
    double total_distance = 0.0;
    int total_duration = 0;
    int display_duration = 0;
    double total_weight = 0.0;
};

struct RouteQualityReport {
    bool displayable = true;
    std::string error;
    int real_road_edges = 0;
    int generated_connector_edges = 0;
    int missing_geometry_edges = 0;
    double max_generated_connector_meters = 0.0;
};

std::string normalize_transport(const std::string& value);
std::string normalize_optimization(const std::string& value);

RouteGraphData load_route_graph(tourism::db::PgConnection& db, int scenic_spot_id = 0);
RouteSearchResult plan_route_with_waypoints(const RouteGraphData& graph,
                                            const std::vector<int>& points,
                                            const std::string& transport,
                                            const std::string& optimization,
                                            int crowd_tolerance);
void apply_congestion_travel_time(RouteSearchResult& route, int crowd_tolerance);
RouteQualityReport assess_route_quality(const RouteSearchResult& route);

crow::json::wvalue route_node_json(const RouteNode& node);
crow::json::wvalue computed_route_json(const RouteGraphData& graph,
                                       const RouteSearchResult& route,
                                       const std::string& optimization,
                                       const std::string& requested_transport);
crow::json::wvalue route_json(const tourism::db::PgResult& rows, int row);

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

// Compute all-pairs shortest paths among a set of nodes
TspDistanceMatrix build_tsp_matrix(const RouteGraphData& graph,
                                   const std::vector<int>& points,
                                   const std::string& transport,
                                   const std::string& optimization,
                                   int crowd_tolerance);

// TSP algorithms
TspResult tsp_enumeration(const TspDistanceMatrix& matrix);
TspResult tsp_backtracking(const TspDistanceMatrix& matrix);
TspResult tsp_branch_and_bound(const TspDistanceMatrix& matrix);
TspResult tsp_nearest_neighbor(const TspDistanceMatrix& matrix);

// Auto-select best algorithm and solve
TspResult solve_tsp(const TspDistanceMatrix& matrix);

// Build a full route from a TSP result + graph
RouteSearchResult compose_tsp_route(const RouteGraphData& graph,
                                    const TspResult& tsp_result,
                                    const std::vector<int>& original_points,
                                    const std::string& transport,
                                    const std::string& optimization,
                                    int crowd_tolerance);

crow::json::wvalue tour_route_json(const RouteGraphData& graph,
                                   const RouteSearchResult& route,
                                   const std::vector<int>& visit_order,
                                   const std::string& optimization,
                                   const std::string& requested_transport,
                                   const std::string& algorithm_used);

} // namespace tourism::services
