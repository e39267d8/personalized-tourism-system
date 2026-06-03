#pragma once

#include "crow.h"
#include "db/postgres.h"

#include <string>
#include <unordered_map>
#include <vector>

namespace tourism::services {

struct RouteNode {
    int id = 0;
    std::string name;
    std::string type;
    std::string scenic_name;
    double longitude = 0.0;
    double latitude = 0.0;
    int congestion = 2;
};

struct RouteEdge {
    int id = 0;
    int from = 0;
    int to = 0;
    std::string mode;
    double distance = 0.0;
    int duration = 0;
    double base_weight = 1.0;
    int congestion = 2;
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
    double total_weight = 0.0;
};

std::string normalize_transport(const std::string& value);
std::string normalize_optimization(const std::string& value);

RouteGraphData load_route_graph(tourism::db::PgConnection& db);
RouteSearchResult plan_route_with_waypoints(const RouteGraphData& graph,
                                            const std::vector<int>& points,
                                            const std::string& transport,
                                            const std::string& optimization,
                                            int crowd_tolerance);

crow::json::wvalue route_node_json(const RouteNode& node);
crow::json::wvalue computed_route_json(const RouteGraphData& graph,
                                       const RouteSearchResult& route,
                                       const std::string& optimization,
                                       const std::string& requested_transport);
crow::json::wvalue route_json(const tourism::db::PgResult& rows, int row);

} // namespace tourism::services
