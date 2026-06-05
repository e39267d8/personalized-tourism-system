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

std::string display_node_name(const RouteNode& node) {
    if (node.type == "scenic") return first_nonempty({node.scenic_name, node.name});
    return first_nonempty({node.name, node.scenic_name});
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

std::vector<std::pair<double, double>> parse_edge_coordinates(const std::string& packed_coordinates) {
    std::vector<std::pair<double, double>> coordinates;
    for (const auto& point : split_pipe(packed_coordinates)) {
        auto comma = point.find(',');
        if (comma == std::string::npos) continue;
        double longitude = to_double(point.substr(0, comma));
        double latitude = to_double(point.substr(comma + 1));
        if (longitude != 0.0 || latitude != 0.0) coordinates.push_back({latitude, longitude});
    }
    return coordinates;
}

void append_route_point(crow::json::wvalue::list& coordinates, double latitude, double longitude) {
    if (latitude == 0.0 && longitude == 0.0) return;
    crow::json::wvalue::list point;
    point.push_back(latitude);
    point.push_back(longitude);
    coordinates.push_back(crow::json::wvalue(std::move(point)));
}

void append_edge_shape(crow::json::wvalue::list& coordinates,
                       const RouteEdge& edge,
                       const RouteNode& from,
                       const RouteNode& to) {
    if (edge.coordinates.empty()) {
        if (coordinates.empty()) append_route_point(coordinates, from.latitude, from.longitude);
        append_route_point(coordinates, to.latitude, to.longitude);
        return;
    }

    size_t start = coordinates.empty() ? 0 : 1;
    for (size_t index = start; index < edge.coordinates.size(); ++index) {
        append_route_point(coordinates, edge.coordinates[index].first, edge.coordinates[index].second);
    }
}

crow::json::wvalue edge_coordinates_json(const RouteEdge& edge,
                                         const RouteNode& from,
                                         const RouteNode& to) {
    crow::json::wvalue::list coordinates;
    if (!edge.coordinates.empty()) {
        for (const auto& coordinate : edge.coordinates) {
            append_route_point(coordinates, coordinate.first, coordinate.second);
        }
    } else {
        append_route_point(coordinates, from.latitude, from.longitude);
        append_route_point(coordinates, to.latitude, to.longitude);
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

RouteGraphData load_route_graph(tourism::db::PgConnection& db, int scenic_spot_id) {
    RouteGraphData graph;

    auto nodes = tourism::db::exec_params(db, R"SQL(
        SELECT gn.id::text, gn.name, gn.node_type,
               COALESCE(ss.name, '') AS scenic_name,
               COALESCE(gn.scenic_spot_id, f.scenic_spot_id, 0)::text AS scenic_spot_id,
               COALESCE(gn.facility_id, 0)::text AS facility_id,
               COALESCE(f.type, '') AS facility_type,
               gn.congestion_level::text,
               ST_X(gn.location::geometry)::text AS longitude,
               ST_Y(gn.location::geometry)::text AS latitude
        FROM graph_nodes gn
        LEFT JOIN scenic_spots ss ON ss.id = gn.scenic_spot_id
        LEFT JOIN facilities f ON f.id = gn.facility_id
        WHERE gn.location IS NOT NULL
          AND (
              $1::int <= 0
              OR gn.scenic_spot_id = $1::int
              OR f.scenic_spot_id = $1::int
          )
        ORDER BY gn.node_type, gn.id
    )SQL", {std::to_string(scenic_spot_id)});

    for (int row = 0; row < nodes.rows(); ++row) {
        RouteNode node;
        node.id = to_int(nodes.value(row, "id"));
        node.name = nodes.value(row, "name");
        node.type = nodes.value(row, "node_type");
        node.scenic_name = nodes.value(row, "scenic_name");
        node.scenic_spot_id = to_int(nodes.value(row, "scenic_spot_id"));
        node.facility_id = to_int(nodes.value(row, "facility_id"));
        node.facility_type = nodes.value(row, "facility_type");
        node.congestion = to_int(nodes.value(row, "congestion_level"), 2);
        node.longitude = to_double(nodes.value(row, "longitude"));
        node.latitude = to_double(nodes.value(row, "latitude"));
        graph.nodes[node.id] = node;
    }

    auto edges = tourism::db::exec_params(db, R"SQL(
        SELECT ge.id::text, ge.from_node::text, ge.to_node::text, ge.travel_mode,
               COALESCE(ge.source, '') AS source,
               distance::text, COALESCE(travel_time, CEIL(distance / 1.2))::text AS travel_time,
               base_weight::text, ge.congestion_level::text,
               COALESCE((
                   SELECT string_agg(
                       ST_X(point.geom)::text || ',' || ST_Y(point.geom)::text,
                       '|' ORDER BY point.path
                   )
                   FROM ST_DumpPoints(ge.geometry::geometry) AS point
               ), '') AS coordinates
        FROM graph_edges ge
        JOIN graph_nodes from_node ON from_node.id = ge.from_node
        JOIN graph_nodes to_node ON to_node.id = ge.to_node
        LEFT JOIN facilities from_facility ON from_facility.id = from_node.facility_id
        LEFT JOIN facilities to_facility ON to_facility.id = to_node.facility_id
        WHERE (
              $1::int <= 0
              OR from_node.scenic_spot_id = $1::int
              OR to_node.scenic_spot_id = $1::int
              OR from_facility.scenic_spot_id = $1::int
              OR to_facility.scenic_spot_id = $1::int
          )
        ORDER BY ge.id
    )SQL", {std::to_string(scenic_spot_id)});

    for (int row = 0; row < edges.rows(); ++row) {
        RouteEdge edge;
        edge.id = to_int(edges.value(row, "id"));
        edge.from = to_int(edges.value(row, "from_node"));
        edge.to = to_int(edges.value(row, "to_node"));
        edge.mode = edges.value(row, "travel_mode");
        edge.source = edges.value(row, "source");
        edge.distance = to_double(edges.value(row, "distance"));
        edge.duration = to_int(edges.value(row, "travel_time"));
        edge.base_weight = to_double(edges.value(row, "base_weight"), 1.0);
        edge.congestion = to_int(edges.value(row, "congestion_level"), 2);
        edge.coordinates = parse_edge_coordinates(edges.value(row, "coordinates"));
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
    item["name"] = display_node_name(node);
    item["nodeName"] = node.name;
    item["type"] = node.type;
    item["scenicSpotId"] = node.scenic_spot_id;
    item["facilityId"] = node.facility_id;
    item["facilityType"] = node.facility_type;
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
    std::string first_stop;
    std::string last_stop;
    for (int node_id : route.nodes) {
        const auto& node = graph.nodes.at(node_id);
        std::string stop_name = display_node_name(node);
        if (first_stop.empty()) first_stop = stop_name;
        last_stop = stop_name;
        stops.push_back(stop_name);
    }

    crow::json::wvalue::list segments;
    crow::json::wvalue::list path_edges;
    crow::json::wvalue::list coordinates;
    for (const auto& edge : route.edges) {
        const auto& from = graph.nodes.at(edge.from);
        const auto& to = graph.nodes.at(edge.to);
        crow::json::wvalue segment;
        segment["from"] = display_node_name(from);
        segment["to"] = display_node_name(to);
        segment["transport"] = transport_label(edge.mode);
        segment["transportMode"] = edge.mode;
        segment["source"] = edge.source;
        segment["distance"] = edge.distance;
        segment["duration"] = edge.duration;
        segment["congestion"] = edge.congestion;
        segments.push_back(std::move(segment));

        crow::json::wvalue path_edge;
        path_edge["id"] = edge.id;
        path_edge["fromNodeId"] = edge.from;
        path_edge["toNodeId"] = edge.to;
        path_edge["from"] = display_node_name(from);
        path_edge["to"] = display_node_name(to);
        path_edge["travelMode"] = edge.mode;
        path_edge["source"] = edge.source;
        path_edge["distance"] = edge.distance;
        path_edge["duration"] = edge.duration;
        path_edge["congestion"] = edge.congestion;
        path_edge["coordinates"] = edge_coordinates_json(edge, from, to);
        path_edges.push_back(std::move(path_edge));

        append_edge_shape(coordinates, edge, from, to);
    }

    if (coordinates.empty()) {
        for (int node_id : route.nodes) {
            const auto& node = graph.nodes.at(node_id);
            append_route_point(coordinates, node.latitude, node.longitude);
        }
    }

    std::ostringstream distance;
    distance << std::fixed << std::setprecision(1) << (route.total_distance / 1000.0) << " km";

    crow::json::wvalue item;
    item["id"] = 0;
    item["route_id"] = "live-route";
    item["title"] = !first_stop.empty() && !last_stop.empty() ? first_stop + " 到 " + last_stop : "实时规划路线";
    item["stops"] = std::move(stops);
    item["segments"] = std::move(segments);
    item["pathEdges"] = std::move(path_edges);
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
