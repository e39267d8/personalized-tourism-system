#include "services/route_graph_service.h"

#include "support/api_helpers.h"

#include <algorithm>
#include <iomanip>
#include <limits>
#include <queue>
#include <sstream>

namespace tourism::services {
namespace {

using tourism::db::exec_sql;
using tourism::support::duration_label;
using tourism::support::first_nonempty;
using tourism::support::split_pipe;
using tourism::support::string_list;
using tourism::support::to_double;
using tourism::support::to_int;
using tourism::support::transport_label;

double route_edge_weight(const RouteEdge& edge, const std::string& optimization, int crowd_tolerance) {
    double crowd_penalty = std::max(0, edge.congestion - crowd_tolerance);
    if (optimization == "distance") return edge.distance + crowd_penalty * 300.0;
    if (optimization == "time") return edge.duration + crowd_penalty * 180.0;
    if (optimization == "budget") {
        double mode_cost = edge.mode == "walk" ? 0.0 : edge.mode == "bike" ? 3.0 : edge.mode == "subway" ? 5.0 : 15.0;
        return edge.distance / 120.0 + edge.duration / 60.0 + mode_cost * 20.0 + crowd_penalty * 10.0;
    }
    return edge.distance / 90.0 + edge.duration / 45.0 + edge.base_weight + crowd_penalty * 12.0;
}

RouteSearchResult dijkstra_route(const RouteGraphData& graph,
                                 int start,
                                 int end,
                                 const std::string& transport,
                                 const std::string& optimization,
                                 int crowd_tolerance) {
    RouteSearchResult result;
    if (!graph.nodes.count(start) || !graph.nodes.count(end)) {
        result.error = "路线节点不存在";
        return result;
    }
    if (start == end) {
        result.success = true;
        result.nodes = {start};
        return result;
    }

    const double inf = std::numeric_limits<double>::infinity();
    std::unordered_map<int, double> dist;
    std::unordered_map<int, RouteEdge> prev;
    for (const auto& [id, node] : graph.nodes) {
        (void)node;
        dist[id] = inf;
    }

    using QueueItem = std::pair<double, int>;
    std::priority_queue<QueueItem, std::vector<QueueItem>, std::greater<QueueItem>> queue;
    dist[start] = 0.0;
    queue.push({0.0, start});

    while (!queue.empty()) {
        auto [current_weight, current] = queue.top();
        queue.pop();
        if (current_weight > dist[current]) continue;
        if (current == end) break;

        auto edge_iter = graph.edges.find(current);
        if (edge_iter == graph.edges.end()) continue;
        for (const auto& edge : edge_iter->second) {
            if (!transport.empty() && edge.mode != transport) continue;
            double next_weight = current_weight + route_edge_weight(edge, optimization, crowd_tolerance);
            if (next_weight < dist[edge.to]) {
                dist[edge.to] = next_weight;
                prev[edge.to] = edge;
                queue.push({next_weight, edge.to});
            }
        }
    }

    if (!prev.count(end)) {
        result.error = "当前交通方式下找不到可达路线";
        return result;
    }

    std::vector<RouteEdge> reversed_edges;
    int current = end;
    while (current != start) {
        RouteEdge edge = prev[current];
        reversed_edges.push_back(edge);
        current = edge.from;
    }
    std::reverse(reversed_edges.begin(), reversed_edges.end());

    result.nodes.push_back(start);
    for (const auto& edge : reversed_edges) {
        result.edges.push_back(edge);
        result.nodes.push_back(edge.to);
        result.total_distance += edge.distance;
        result.total_duration += edge.duration;
        result.total_weight += route_edge_weight(edge, optimization, crowd_tolerance);
    }
    result.success = true;
    return result;
}

crow::json::wvalue route_coordinates_json(const std::string& packed_coordinates) {
    crow::json::wvalue::list coordinates;
    for (const auto& point : split_pipe(packed_coordinates)) {
        auto comma = point.find(',');
        if (comma == std::string::npos) continue;

        double longitude = to_double(point.substr(0, comma));
        double latitude = to_double(point.substr(comma + 1));

        crow::json::wvalue::list leaflet_point;
        leaflet_point.push_back(latitude);
        leaflet_point.push_back(longitude);
        coordinates.push_back(crow::json::wvalue(std::move(leaflet_point)));
    }
    return crow::json::wvalue(std::move(coordinates));
}

} // namespace

std::string normalize_transport(const std::string& value) {
    if (value == "walk" || value == "步行") return "walk";
    if (value == "bike" || value == "骑行") return "bike";
    if (value == "subway" || value == "地铁") return "subway";
    if (value == "bus" || value == "公交") return "bus";
    if (value == "car" || value == "driving" || value == "驾车") return "car";
    return "";
}

std::string normalize_optimization(const std::string& value) {
    if (value == "distance" || value == "距离优先") return "distance";
    if (value == "time" || value == "时间优先") return "time";
    if (value == "budget" || value == "预算优先") return "budget";
    return "balanced";
}

RouteGraphData load_route_graph(tourism::db::PgConnection& db) {
    RouteGraphData graph;

    auto nodes = exec_sql(db, R"SQL(
        SELECT gn.id::text, gn.name, gn.node_type,
               COALESCE(ss.name, '') AS scenic_name,
               gn.congestion_level::text,
               ST_X(gn.location::geometry)::text AS longitude,
               ST_Y(gn.location::geometry)::text AS latitude
        FROM graph_nodes gn
        LEFT JOIN scenic_spots ss ON ss.id = gn.scenic_spot_id
        WHERE gn.location IS NOT NULL
        ORDER BY gn.node_type, gn.id
    )SQL");

    for (int row = 0; row < nodes.rows(); ++row) {
        RouteNode node;
        node.id = to_int(nodes.value(row, "id"));
        node.name = nodes.value(row, "name");
        node.type = nodes.value(row, "node_type");
        node.scenic_name = nodes.value(row, "scenic_name");
        node.congestion = to_int(nodes.value(row, "congestion_level"), 2);
        node.longitude = to_double(nodes.value(row, "longitude"));
        node.latitude = to_double(nodes.value(row, "latitude"));
        graph.nodes[node.id] = node;
    }

    auto edges = exec_sql(db, R"SQL(
        SELECT id::text, from_node::text, to_node::text, travel_mode,
               distance::text, COALESCE(travel_time, CEIL(distance / 1.2))::text AS travel_time,
               base_weight::text, congestion_level::text
        FROM graph_edges
        ORDER BY id
    )SQL");

    for (int row = 0; row < edges.rows(); ++row) {
        RouteEdge edge;
        edge.id = to_int(edges.value(row, "id"));
        edge.from = to_int(edges.value(row, "from_node"));
        edge.to = to_int(edges.value(row, "to_node"));
        edge.mode = edges.value(row, "travel_mode");
        edge.distance = to_double(edges.value(row, "distance"));
        edge.duration = to_int(edges.value(row, "travel_time"));
        edge.base_weight = to_double(edges.value(row, "base_weight"), 1.0);
        edge.congestion = to_int(edges.value(row, "congestion_level"), 2);
        if (graph.nodes.count(edge.from) && graph.nodes.count(edge.to)) {
            graph.edges[edge.from].push_back(edge);
        }
    }

    return graph;
}

RouteSearchResult plan_route_with_waypoints(const RouteGraphData& graph,
                                            const std::vector<int>& points,
                                            const std::string& transport,
                                            const std::string& optimization,
                                            int crowd_tolerance) {
    RouteSearchResult combined;
    if (points.size() < 2) {
        combined.error = "请选择起点和终点";
        return combined;
    }

    for (size_t i = 0; i + 1 < points.size(); ++i) {
        RouteSearchResult segment = dijkstra_route(graph, points[i], points[i + 1], transport, optimization, crowd_tolerance);
        if (!segment.success && !transport.empty()) {
            segment = dijkstra_route(graph, points[i], points[i + 1], "", optimization, crowd_tolerance);
            segment.used_transport_fallback = segment.success;
        }
        if (!segment.success) {
            combined.error = segment.error;
            return combined;
        }

        if (combined.nodes.empty()) combined.nodes.push_back(segment.nodes.front());
        for (size_t node_index = 1; node_index < segment.nodes.size(); ++node_index) {
            combined.nodes.push_back(segment.nodes[node_index]);
        }
        combined.edges.insert(combined.edges.end(), segment.edges.begin(), segment.edges.end());
        combined.total_distance += segment.total_distance;
        combined.total_duration += segment.total_duration;
        combined.total_weight += segment.total_weight;
        combined.used_transport_fallback = combined.used_transport_fallback || segment.used_transport_fallback;
    }

    combined.success = true;
    return combined;
}

crow::json::wvalue route_node_json(const RouteNode& node) {
    crow::json::wvalue item;
    item["id"] = node.id;
    item["name"] = first_nonempty({node.scenic_name, node.name});
    item["nodeName"] = node.name;
    item["type"] = node.type;
    item["congestion"] = node.congestion;
    item["longitude"] = node.longitude;
    item["latitude"] = node.latitude;
    return item;
}

crow::json::wvalue computed_route_json(const RouteGraphData& graph,
                                       const RouteSearchResult& route,
                                       const std::string& optimization,
                                       const std::string& requested_transport) {
    crow::json::wvalue::list stops;
    crow::json::wvalue::list coordinates;
    std::string first_stop;
    std::string last_stop;
    for (int node_id : route.nodes) {
        const auto& node = graph.nodes.at(node_id);
        std::string stop_name = first_nonempty({node.scenic_name, node.name});
        if (first_stop.empty()) first_stop = stop_name;
        last_stop = stop_name;
        stops.push_back(stop_name);
        crow::json::wvalue::list point;
        point.push_back(node.latitude);
        point.push_back(node.longitude);
        coordinates.push_back(crow::json::wvalue(std::move(point)));
    }

    crow::json::wvalue::list segments;
    for (const auto& edge : route.edges) {
        const auto& from = graph.nodes.at(edge.from);
        const auto& to = graph.nodes.at(edge.to);
        crow::json::wvalue segment;
        segment["from"] = first_nonempty({from.scenic_name, from.name});
        segment["to"] = first_nonempty({to.scenic_name, to.name});
        segment["transport"] = transport_label(edge.mode);
        segment["transportMode"] = edge.mode;
        segment["distance"] = edge.distance;
        segment["duration"] = edge.duration;
        segment["congestion"] = edge.congestion;
        segments.push_back(std::move(segment));
    }

    std::ostringstream distance;
    distance << std::fixed << std::setprecision(1) << (route.total_distance / 1000.0) << " km";

    crow::json::wvalue item;
    item["id"] = 0;
    item["route_id"] = "live-route";
    item["title"] = !first_stop.empty() && !last_stop.empty() ? first_stop + " 到 " + last_stop : "实时规划路线";
    item["stops"] = std::move(stops);
    item["segments"] = std::move(segments);
    item["coordinates"] = std::move(coordinates);
    item["distance"] = distance.str();
    item["time"] = duration_label(std::to_string(route.total_duration / 60));
    item["cost"] = route.total_distance <= 0 ? 0 : std::max(0, static_cast<int>(route.total_distance / 1000.0 * 2));
    item["intensity"] = route.total_distance > 3500 ? "中等" : "轻松";
    item["transport"] = requested_transport.empty() ? "混合" : transport_label(requested_transport);
    item["bestFor"] = optimization + " 优先";
    item["total_distance_meters"] = static_cast<int>(route.total_distance);
    item["total_duration_seconds"] = route.total_duration;
    item["usedTransportFallback"] = route.used_transport_fallback;
    return item;
}

crow::json::wvalue route_json(const tourism::db::PgResult& rows, int row) {
    int meters = static_cast<int>(to_double(rows.value(row, "total_distance")));
    int seconds = to_int(rows.value(row, "total_duration"));
    int cost = std::max(20, meters / 100 + (rows.value(row, "travel_mode") == "bike" ? 12 : 0));

    std::ostringstream distance;
    distance << std::fixed << std::setprecision(1) << (meters / 1000.0) << " km";

    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["title"] = rows.value(row, "title");
    item["stops"] = string_list(split_pipe(rows.value(row, "stops")));
    item["distance"] = distance.str();
    item["time"] = duration_label(std::to_string(seconds / 60));
    item["cost"] = cost;
    item["intensity"] = meters > 3500 ? "中等" : "轻松";
    item["transport"] = transport_label(rows.value(row, "travel_mode"));
    item["bestFor"] = rows.value(row, "optimization_type") + " 优先";
    item["coordinates"] = route_coordinates_json(rows.value(row, "coordinates"));
    return item;
}

} // namespace tourism::services
