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

TspDistanceMatrix build_tsp_matrix(const RouteGraphData& graph,
                                   const std::vector<int>& points,
                                   const std::string& transport,
                                   const std::string& optimization,
                                   int crowd_tolerance) {
    TspDistanceMatrix matrix;
    matrix.size = static_cast<int>(points.size());
    if (matrix.size == 0) return matrix;

    matrix.distance.assign(matrix.size, std::vector<double>(matrix.size, std::numeric_limits<double>::infinity()));
    matrix.duration.assign(matrix.size, std::vector<int>(matrix.size, std::numeric_limits<int>::max()));
    matrix.weight.assign(matrix.size, std::vector<double>(matrix.size, std::numeric_limits<double>::infinity()));

    for (int i = 0; i < matrix.size; ++i) {
        matrix.distance[i][i] = 0.0;
        matrix.duration[i][i] = 0;
        matrix.weight[i][i] = 0.0;
    }

    for (int i = 0; i < matrix.size; ++i) {
        for (int j = 0; j < matrix.size; ++j) {
            if (i == j) continue;
            auto result = dijkstra_route(graph, points[i], points[j], transport, optimization, crowd_tolerance);
            if (!result.success) {
                // Try without transport restriction
                result = dijkstra_route(graph, points[i], points[j], "", optimization, crowd_tolerance);
            }
            if (result.success) {
                matrix.distance[i][j] = result.total_distance;
                matrix.duration[i][j] = result.total_duration;
                matrix.weight[i][j] = result.total_weight > 0 ? result.total_weight : result.total_distance / 90.0 + result.total_duration / 45.0;
            }
        }
    }
    return matrix;
}

namespace {

constexpr double kInf = std::numeric_limits<double>::infinity();
constexpr int kMaxEnumeration = 8;
constexpr int kMaxBacktracking = 12;
constexpr int kMaxBranchAndBound = 20;

double tsp_evaluate(const TspDistanceMatrix& matrix, const std::vector<int>& order) {
    double total = 0.0;
    for (size_t i = 0; i + 1 < order.size(); ++i) {
        double w = matrix.weight[order[i]][order[i + 1]];
        if (w >= kInf) return kInf;
        total += w;
    }
    return total;
}

void tsp_stats(const TspDistanceMatrix& matrix, const std::vector<int>& order,
               TspResult& result) {
    result.total_distance = 0.0;
    result.total_duration = 0;
    result.total_weight = 0.0;
    for (size_t i = 0; i + 1 < order.size(); ++i) {
        result.total_distance += matrix.distance[order[i]][order[i + 1]];
        result.total_duration += matrix.duration[order[i]][order[i + 1]];
        result.total_weight += matrix.weight[order[i]][order[i + 1]];
    }
}

bool tsp_matrix_reachable(const TspDistanceMatrix& matrix) {
    for (int i = 0; i < matrix.size; ++i) {
        for (int j = 0; j < matrix.size; ++j) {
            if (i != j && matrix.weight[i][j] >= kInf) return false;
        }
    }
    return true;
}

} // namespace

TspResult tsp_enumeration(const TspDistanceMatrix& matrix) {
    TspResult result;
    result.algorithm_used = "枚举";
    if (matrix.size < 2) {
        result.error = "至少需要2个点";
        return result;
    }
    if (!tsp_matrix_reachable(matrix)) {
        result.error = "部分点之间不可达";
        return result;
    }

    std::vector<int> perm(matrix.size);
    for (int i = 0; i < matrix.size; ++i) perm[i] = i;
    // Fix start at 0, only permute indices 1..n-1
    std::vector<int> best_order = perm;
    double best_weight = kInf;

    std::vector<int> tail(matrix.size - 1);
    for (int i = 1; i < matrix.size; ++i) tail[i - 1] = i;

    do {
        std::vector<int> order(matrix.size);
        order[0] = 0;
        for (int i = 0; i < matrix.size - 1; ++i) order[i + 1] = tail[i];
        // Close the loop: add return to start
        double weight = tsp_evaluate(matrix, order);
        if (matrix.weight[order.back()][order[0]] < kInf) {
            weight += matrix.weight[order.back()][order[0]];
        }
        if (weight < best_weight) {
            best_weight = weight;
            best_order = std::move(order);
        }
    } while (std::next_permutation(tail.begin(), tail.end()));

    result.success = true;
    result.best_order = std::move(best_order);
    tsp_stats(matrix, result.best_order, result);
    // Add return leg
    result.total_distance += matrix.distance[result.best_order.back()][result.best_order[0]];
    result.total_duration += matrix.duration[result.best_order.back()][result.best_order[0]];
    result.total_weight += matrix.weight[result.best_order.back()][result.best_order[0]];
    return result;
}

namespace {

void tsp_backtrack_dfs(const TspDistanceMatrix& matrix, std::vector<int>& current,
                       std::vector<bool>& visited, double current_weight,
                       int depth, double& best_weight, std::vector<int>& best_order,
                       const std::vector<double>& min_out_edge) {
    if (depth == matrix.size) {
        double total = current_weight + matrix.weight[current.back()][current[0]];
        if (total < best_weight) {
            best_weight = total;
            best_order = current;
        }
        return;
    }
    for (int i = 1; i < matrix.size; ++i) {
        if (visited[i]) continue;
        double edge_w = matrix.weight[current.back()][i];
        if (edge_w >= kInf) continue;
        double new_weight = current_weight + edge_w;
        // Lower bound: min out edges for remaining unvisited + back to start
        double bound = new_weight;
        for (int j = 1; j < matrix.size; ++j) {
            if (j != i && !visited[j]) bound += min_out_edge[j];
        }
        bound += min_out_edge[0];
        if (bound >= best_weight) continue;

        visited[i] = true;
        current.push_back(i);
        tsp_backtrack_dfs(matrix, current, visited, new_weight, depth + 1, best_weight, best_order, min_out_edge);
        current.pop_back();
        visited[i] = false;
    }
}

} // namespace

TspResult tsp_backtracking(const TspDistanceMatrix& matrix) {
    TspResult result;
    result.algorithm_used = "回溯";
    if (matrix.size < 2) {
        result.error = "至少需要2个点";
        return result;
    }
    if (!tsp_matrix_reachable(matrix)) {
        result.error = "部分点之间不可达";
        return result;
    }

    // Compute min out edge for each node as lower bound
    std::vector<double> min_out_edge(matrix.size, kInf);
    for (int i = 0; i < matrix.size; ++i) {
        for (int j = 0; j < matrix.size; ++j) {
            if (i != j && matrix.weight[i][j] < min_out_edge[i]) {
                min_out_edge[i] = matrix.weight[i][j];
            }
        }
    }

    std::vector<int> current = {0};
    std::vector<bool> visited(matrix.size, false);
    visited[0] = true;
    double best_weight = kInf;
    std::vector<int> best_order;

    tsp_backtrack_dfs(matrix, current, visited, 0.0, 1, best_weight, best_order, min_out_edge);

    if (best_order.empty()) {
        result.error = "未找到可行环游路线";
        return result;
    }

    result.success = true;
    result.best_order = std::move(best_order);
    tsp_stats(matrix, result.best_order, result);
    result.total_distance += matrix.distance[result.best_order.back()][result.best_order[0]];
    result.total_duration += matrix.duration[result.best_order.back()][result.best_order[0]];
    result.total_weight += matrix.weight[result.best_order.back()][result.best_order[0]];
    return result;
}

TspResult tsp_branch_and_bound(const TspDistanceMatrix& matrix) {
    TspResult result;
    result.algorithm_used = "分支限界";
    if (matrix.size < 2) {
        result.error = "至少需要2个点";
        return result;
    }
    if (!tsp_matrix_reachable(matrix)) {
        result.error = "部分点之间不可达";
        return result;
    }

    // Compute reduced cost matrix lower bound
    std::vector<std::vector<double>> reduced = matrix.weight;
    double initial_bound = 0.0;
    for (int i = 0; i < matrix.size; ++i) {
        double row_min = kInf;
        for (int j = 0; j < matrix.size; ++j) {
            if (i != j && reduced[i][j] < row_min) row_min = reduced[i][j];
        }
        if (row_min < kInf) {
            initial_bound += row_min;
            for (int j = 0; j < matrix.size; ++j) {
                if (i != j) reduced[i][j] -= row_min;
            }
        }
    }
    for (int j = 0; j < matrix.size; ++j) {
        double col_min = kInf;
        for (int i = 0; i < matrix.size; ++i) {
            if (i != j && reduced[i][j] < col_min) col_min = reduced[i][j];
        }
        if (col_min < kInf) {
            initial_bound += col_min;
            for (int i = 0; i < matrix.size; ++i) {
                if (i != j) reduced[i][j] -= col_min;
            }
        }
    }

    // Use priority queue for branch and bound
    struct BnbNode {
        std::vector<int> path;
        std::vector<bool> visited;
        double bound;
        int depth;
        bool operator<(const BnbNode& other) const {
            return bound > other.bound;
        }
    };

    std::priority_queue<BnbNode> pq;
    BnbNode root;
    root.path = {0};
    root.visited.assign(matrix.size, false);
    root.visited[0] = true;
    root.bound = initial_bound;
    root.depth = 1;
    pq.push(root);

    double best_weight = kInf;
    std::vector<int> best_order;

    std::vector<double> min_out_rest(matrix.size, 0.0);
    for (int i = 0; i < matrix.size; ++i) {
        min_out_rest[i] = kInf;
        for (int j = 0; j < matrix.size; ++j) {
            if (i != j && matrix.weight[i][j] < min_out_rest[i]) {
                min_out_rest[i] = matrix.weight[i][j];
            }
        }
    }

    while (!pq.empty()) {
        BnbNode node = pq.top();
        pq.pop();

        if (node.bound >= best_weight) continue;

        if (node.depth == matrix.size) {
            double total = tsp_evaluate(matrix, node.path);
            if (matrix.weight[node.path.back()][0] < kInf) {
                total += matrix.weight[node.path.back()][0];
            }
            if (total < best_weight) {
                best_weight = total;
                best_order = node.path;
            }
            continue;
        }

        for (int i = 1; i < matrix.size; ++i) {
            if (node.visited[i]) continue;
            double edge_w = matrix.weight[node.path.back()][i];
            if (edge_w >= kInf) continue;

            double current_w = tsp_evaluate(matrix, node.path) + edge_w;
            double rest_bound = 0.0;
            for (int j = 1; j < matrix.size; ++j) {
                if (j != i && !node.visited[j]) rest_bound += min_out_rest[j];
            }
            rest_bound += min_out_rest[0];
            double new_bound = current_w + rest_bound;
            if (new_bound >= best_weight) continue;

            BnbNode child;
            child.path = node.path;
            child.path.push_back(i);
            child.visited = node.visited;
            child.visited[i] = true;
            child.bound = new_bound;
            child.depth = node.depth + 1;
            pq.push(child);
        }
    }

    if (best_order.empty()) {
        result.error = "未找到可行环游路线";
        return result;
    }

    result.success = true;
    result.best_order = std::move(best_order);
    tsp_stats(matrix, result.best_order, result);
    result.total_distance += matrix.distance[result.best_order.back()][result.best_order[0]];
    result.total_duration += matrix.duration[result.best_order.back()][result.best_order[0]];
    result.total_weight += matrix.weight[result.best_order.back()][result.best_order[0]];
    return result;
}

TspResult tsp_nearest_neighbor(const TspDistanceMatrix& matrix) {
    TspResult result;
    result.algorithm_used = "近邻优化(2-opt)";
    if (matrix.size < 2) {
        result.error = "至少需要2个点";
        return result;
    }
    if (!tsp_matrix_reachable(matrix)) {
        result.error = "部分点之间不可达";
        return result;
    }

    std::vector<int> order(matrix.size);
    std::vector<bool> visited(matrix.size, false);
    order[0] = 0;
    visited[0] = true;

    for (int k = 1; k < matrix.size; ++k) {
        int last = order[k - 1];
        int best_next = -1;
        double best_w = kInf;
        for (int j = 0; j < matrix.size; ++j) {
            if (!visited[j] && matrix.weight[last][j] < best_w) {
                best_w = matrix.weight[last][j];
                best_next = j;
            }
        }
        if (best_next < 0) break;
        order[k] = best_next;
        visited[best_next] = true;
    }

    // 2-opt local improvement
    bool improved = true;
    while (improved) {
        improved = false;
        for (int i = 1; i < matrix.size - 1; ++i) {
            for (int j = i + 1; j < matrix.size; ++j) {
                double old_w = matrix.weight[order[i - 1]][order[i]] + matrix.weight[order[j - 1]][order[j]];
                double new_w = matrix.weight[order[i - 1]][order[j - 1]] + matrix.weight[order[i]][order[j]];
                if (new_w < old_w) {
                    std::reverse(order.begin() + i, order.begin() + j);
                    improved = true;
                }
            }
        }
    }

    result.success = true;
    result.best_order = std::move(order);
    tsp_stats(matrix, result.best_order, result);
    result.total_distance += matrix.distance[result.best_order.back()][result.best_order[0]];
    result.total_duration += matrix.duration[result.best_order.back()][result.best_order[0]];
    result.total_weight += matrix.weight[result.best_order.back()][result.best_order[0]];
    return result;
}

TspResult solve_tsp(const TspDistanceMatrix& matrix) {
    if (matrix.size <= kMaxEnumeration) {
        return tsp_enumeration(matrix);
    } else if (matrix.size <= kMaxBacktracking) {
        return tsp_backtracking(matrix);
    } else if (matrix.size <= kMaxBranchAndBound) {
        return tsp_branch_and_bound(matrix);
    } else {
        return tsp_nearest_neighbor(matrix);
    }
}

RouteSearchResult compose_tsp_route(const RouteGraphData& graph,
                                    const TspResult& tsp_result,
                                    const std::vector<int>& original_points,
                                    const std::string& transport,
                                    const std::string& optimization,
                                    int crowd_tolerance) {
    RouteSearchResult combined;
    if (!tsp_result.success) {
        combined.error = tsp_result.error;
        return combined;
    }

    // Build ordered point list from tsp result, then add return to start
    std::vector<int> ordered;
    for (int idx : tsp_result.best_order) {
        ordered.push_back(original_points[idx]);
    }
    ordered.push_back(original_points[tsp_result.best_order[0]]); // return to start

    return plan_route_with_waypoints(graph, ordered, transport, optimization, crowd_tolerance);
}

crow::json::wvalue tour_route_json(const RouteGraphData& graph,
                                   const RouteSearchResult& route,
                                   const std::vector<int>& visit_order,
                                   const std::string& optimization,
                                   const std::string& requested_transport,
                                   const std::string& algorithm_used) {
    crow::json::wvalue base = computed_route_json(graph, route, optimization, requested_transport);

    crow::json::wvalue::list order_names;
    for (int idx : visit_order) {
        if (route.nodes.empty()) break;
        auto node_it = graph.nodes.find(idx);
        if (node_it != graph.nodes.end()) {
            order_names.push_back(display_node_name(node_it->second));
        }
    }

    base["tourType"] = "环游";
    base["algorithm"] = algorithm_used;
    base["visitOrder"] = std::move(order_names);
    base["pointCount"] = static_cast<int>(visit_order.size());
    return base;
}

} // namespace tourism::services
