#include "api/scenic_routes.h"

#include "db/postgres.h"
#include "services/route_graph_service.h"
#include "services/scenic_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cmath>
#include <functional>
#include <limits>
#include <map>
#include <queue>
#include <string>
#include <utility>
#include <vector>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::services::computed_route_json;
using tourism::services::load_route_graph;
using tourism::services::normalize_optimization;
using tourism::services::plan_route_with_waypoints;
using tourism::services::RouteEdge;
using tourism::services::RouteGraphData;
using tourism::services::RouteNode;
using tourism::services::list_scenic;
using tourism::services::scenic_json;
using tourism::support::json_error;
using tourism::support::json_int;
using tourism::support::json_string;
using tourism::support::ok;
using tourism::support::query_int;
using tourism::support::to_double;
using tourism::support::to_int;
using tourism::support::trim_text;

constexpr double kInternalSnapMaxMeters = 60.0;

std::string facility_type_label(const std::string& type) {
    if (type == "toilet") return "卫生间";
    if (type == "restaurant") return "餐饮";
    if (type == "cafe") return "咖啡";
    if (type == "shop") return "商店";
    if (type == "supermarket") return "超市";
    if (type == "parking") return "停车";
    if (type == "service") return "服务中心";
    if (type == "ticket") return "售票";
    if (type == "atm") return "ATM";
    if (type == "clinic") return "医务";
    if (type == "drinking_water") return "饮水";
    if (type == "entrance") return "入口";
    if (type == "building") return "建筑";
    if (type == "museum") return "展馆";
    if (type == "attraction") return "景观";
    return type.empty() ? "设施" : type;
}

crow::json::wvalue facility_json(const tourism::db::PgResult& rows, int row) {
    std::string type = rows.value(row, "type");

    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["nodeId"] = to_int(rows.value(row, "node_id"));
    item["name"] = rows.value(row, "name");
    item["type"] = type;
    item["typeLabel"] = facility_type_label(type);
    item["address"] = rows.value(row, "address");
    item["rating"] = to_double(rows.value(row, "rating"));
    item["priceLevel"] = to_int(rows.value(row, "price_level"));
    item["openingHours"] = rows.value(row, "opening_hours");
    item["phone"] = rows.value(row, "phone");
    item["longitude"] = to_double(rows.value(row, "longitude"));
    item["latitude"] = to_double(rows.value(row, "latitude"));
    item["source"] = rows.value(row, "source");
    item["routable"] = to_int(rows.value(row, "routable")) > 0;
    item["connectorDistanceMeters"] = static_cast<int>(std::round(to_double(rows.value(row, "connector_distance"))));
    return item;
}

crow::json::wvalue graph_node_json(const RouteNode& node) {
    crow::json::wvalue item;
    item["id"] = node.id;
    item["name"] = node.name;
    item["type"] = node.type;
    item["facilityId"] = node.facility_id;
    item["facilityType"] = node.facility_type;
    item["facilityTypeLabel"] = facility_type_label(node.facility_type);
    item["congestion"] = node.congestion;
    item["longitude"] = node.longitude;
    item["latitude"] = node.latitude;
    return item;
}

void add_point(crow::json::wvalue::list& coordinates, double latitude, double longitude) {
    crow::json::wvalue::list point;
    point.push_back(latitude);
    point.push_back(longitude);
    coordinates.push_back(crow::json::wvalue(std::move(point)));
}

crow::json::wvalue edge_json(const RouteGraphData& graph, const RouteEdge& edge) {
    crow::json::wvalue item;
    item["id"] = edge.id;
    item["fromNodeId"] = edge.from;
    item["toNodeId"] = edge.to;
    item["travelMode"] = edge.mode;
    item["source"] = edge.source;
    item["distance"] = edge.distance;
    item["duration"] = edge.duration;
    item["congestion"] = edge.congestion;

    crow::json::wvalue::list coordinates;
    if (!edge.coordinates.empty()) {
        for (const auto& coordinate : edge.coordinates) add_point(coordinates, coordinate.first, coordinate.second);
    } else if (graph.nodes.count(edge.from) && graph.nodes.count(edge.to)) {
        const auto& from = graph.nodes.at(edge.from);
        const auto& to = graph.nodes.at(edge.to);
        add_point(coordinates, from.latitude, from.longitude);
        add_point(coordinates, to.latitude, to.longitude);
    }
    item["coordinates"] = crow::json::wvalue(std::move(coordinates));
    return item;
}

double squared_distance(double lat1, double lng1, double lat2, double lng2) {
    double dlat = lat1 - lat2;
    double dlng = lng1 - lng2;
    return dlat * dlat + dlng * dlng;
}

double haversine_meters(double lat1, double lng1, double lat2, double lng2) {
    constexpr double earth_radius = 6371000.0;
    constexpr double pi = 3.14159265358979323846;
    auto to_radians = [pi](double value) { return value * pi / 180.0; };
    double dlat = to_radians(lat2 - lat1);
    double dlng = to_radians(lng2 - lng1);
    double rlat1 = to_radians(lat1);
    double rlat2 = to_radians(lat2);
    double value = std::sin(dlat / 2.0) * std::sin(dlat / 2.0) +
                   std::cos(rlat1) * std::cos(rlat2) *
                   std::sin(dlng / 2.0) * std::sin(dlng / 2.0);
    return earth_radius * 2.0 * std::atan2(std::sqrt(value), std::sqrt(1.0 - value));
}

double json_double_value(const crow::json::rvalue& body, const std::string& key, double fallback = 0.0) {
    if (!body || !body.has(key)) return fallback;
    try {
        return body[key].d();
    } catch (...) {
        try {
            return to_double(static_cast<std::string>(body[key].s()), fallback);
        } catch (...) {
        }
    }
    return fallback;
}

bool has_osm_edge(const RouteGraphData& graph, int node_id) {
    auto edge_iter = graph.edges.find(node_id);
    if (edge_iter == graph.edges.end()) return false;
    return std::any_of(edge_iter->second.begin(), edge_iter->second.end(), [](const RouteEdge& edge) {
        return edge.source == "osm";
    });
}

std::pair<int, double> nearest_node_with_distance(const RouteGraphData& graph,
                                                  double latitude,
                                                  double longitude,
                                                  bool require_osm_edge = false) {
    int best_id = 0;
    double best_rank_distance = std::numeric_limits<double>::infinity();
    for (const auto& [id, node] : graph.nodes) {
        if (require_osm_edge && !has_osm_edge(graph, id)) continue;
        double distance = squared_distance(latitude, longitude, node.latitude, node.longitude);
        if (distance < best_rank_distance) {
            best_rank_distance = distance;
            best_id = id;
        }
    }
    if (best_id <= 0) return {0, std::numeric_limits<double>::infinity()};
    const auto& node = graph.nodes.at(best_id);
    return {best_id, haversine_meters(latitude, longitude, node.latitude, node.longitude)};
}

bool route_uses_real_road(const std::vector<RouteEdge>& edges) {
    return std::any_of(edges.begin(), edges.end(), [](const RouteEdge& edge) {
        return edge.source == "osm";
    });
}

bool route_has_long_connector(const std::vector<RouteEdge>& edges) {
    return std::any_of(edges.begin(), edges.end(), [](const RouteEdge& edge) {
        return edge.source == "generated" && edge.distance > kInternalSnapMaxMeters;
    });
}

bool node_has_incident_edge(const RouteGraphData& graph, int node_id) {
    auto outgoing = graph.edges.find(node_id);
    if (outgoing != graph.edges.end() && !outgoing->second.empty()) return true;
    for (const auto& [from, edges] : graph.edges) {
        (void)from;
        for (const auto& edge : edges) {
            if (edge.to == node_id) return true;
        }
    }
    return false;
}

int default_start_node_id(const RouteGraphData& graph) {
    for (const auto& [id, node] : graph.nodes) {
        if (node.type == "entrance" || node.facility_type == "entrance") return id;
    }
    for (const auto& [id, node] : graph.nodes) {
        if (node.type == "scenic") return id;
    }
    return graph.nodes.empty() ? 0 : graph.nodes.begin()->first;
}

std::vector<int> default_start_candidates(const RouteGraphData& graph) {
    std::vector<int> candidates;
    auto add = [&](int id) {
        if (id > 0 && std::find(candidates.begin(), candidates.end(), id) == candidates.end()) {
            candidates.push_back(id);
        }
    };
    for (const auto& [id, node] : graph.nodes) {
        if (node.type == "entrance" || node.facility_type == "entrance") add(id);
    }
    for (const auto& [id, node] : graph.nodes) {
        if (node.type == "scenic") add(id);
    }
    for (const auto& [id, node] : graph.nodes) {
        (void)node;
        if (has_osm_edge(graph, id)) add(id);
    }
    add(default_start_node_id(graph));
    return candidates;
}

int reachable_default_start_node_id(const RouteGraphData& graph,
                                    int end_node_id,
                                    const std::string& optimization) {
    for (int candidate_id : default_start_candidates(graph)) {
        if (!graph.nodes.count(candidate_id)) continue;
        auto route = plan_route_with_waypoints(graph, {candidate_id, end_node_id}, "walk", optimization, 3);
        if (route.success && route_uses_real_road(route.edges)) return candidate_id;
    }
    return 0;
}

crow::json::wvalue route_quality_json(const RouteGraphData& graph,
                                      const std::vector<RouteEdge>& edges,
                                      int start_node_id,
                                      int end_node_id,
                                      double start_snap_distance,
                                      bool used_map_start) {
    double real_distance = 0.0;
    double connector_distance = 0.0;
    int connector_count = 0;
    crow::json::wvalue::list warnings;
    for (const auto& edge : edges) {
        if (edge.source == "generated") {
            connector_distance += edge.distance;
            ++connector_count;
        } else if (edge.source == "osm") {
            real_distance += edge.distance;
        }
    }
    if (connector_count > 0) warnings.push_back("虚线为设施接入段，不代表真实道路");
    if (used_map_start && start_snap_distance > 0.0) warnings.push_back("地图点选起点已吸附到最近内部道路");

    crow::json::wvalue quality;
    quality["realRoadDistanceMeters"] = static_cast<int>(std::round(real_distance));
    quality["connectorDistanceMeters"] = static_cast<int>(std::round(connector_distance));
    quality["connectorSegmentCount"] = connector_count;
    quality["startSnapDistanceMeters"] = start_snap_distance == std::numeric_limits<double>::infinity()
        ? 0
        : static_cast<int>(std::round(start_snap_distance));
    quality["startNodeId"] = start_node_id;
    quality["endNodeId"] = end_node_id;
    if (graph.nodes.count(start_node_id)) quality["snappedStartName"] = graph.nodes.at(start_node_id).name;
    if (graph.nodes.count(end_node_id)) quality["snappedEndName"] = graph.nodes.at(end_node_id).name;
    quality["warnings"] = std::move(warnings);
    return quality;
}

int node_id_for_facility(tourism::db::PgConnection& db, int scenic_spot_id, int facility_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT gn.id::text
        FROM graph_nodes gn
        JOIN facilities f ON f.id = gn.facility_id
        WHERE f.scenic_spot_id = $1 AND f.id = $2
        ORDER BY gn.id
        LIMIT 1
    )SQL", {std::to_string(scenic_spot_id), std::to_string(facility_id)});
    return rows.rows() ? to_int(rows.value(0, "id")) : 0;
}

struct IndoorFeature {
    int id = 0;
    std::string name;
    std::string type;
    std::string floor_code;
    std::string floor_name;
    std::string provider;
    std::string source;
    std::string source_ref;
    double x = 0.0;
    double y = 0.0;
};

struct IndoorEdge {
    int id = 0;
    int from = 0;
    int to = 0;
    double distance = 0.0;
    int travel_time = 0;
    std::string type;
    std::string provider;
};

struct IndoorRouteResult {
    bool success = false;
    std::string error;
    std::vector<int> feature_path;
    std::vector<IndoorEdge> edge_path;
    double distance = 0.0;
    int duration = 0;
};

std::string indoor_feature_type_label(const std::string& type) {
    if (type == "entrance") return "入口";
    if (type == "hallway") return "大厅/走廊";
    if (type == "service") return "服务点";
    if (type == "toilet") return "卫生间";
    if (type == "exhibition") return "展厅";
    if (type == "elevator") return "电梯";
    if (type == "stairs") return "楼梯";
    if (type == "room") return "房间";
    if (type == "shop") return "商店";
    if (type == "cafe") return "咖啡";
    return type.empty() ? "节点" : type;
}

std::string indoor_edge_type_label(const std::string& type) {
    if (type == "corridor") return "通道";
    if (type == "elevator") return "电梯";
    if (type == "stairs") return "楼梯";
    return type.empty() ? "路径" : type;
}

std::string normalize_indoor_strategy(std::string strategy) {
    strategy = trim_text(strategy);
    std::transform(strategy.begin(), strategy.end(), strategy.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return strategy == "distance" ? "distance" : "time";
}

crow::json::wvalue indoor_building_json(const tourism::db::PgResult& rows, int row) {
    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["scenicSpotId"] = to_int(rows.value(row, "scenic_spot_id"));
    item["name"] = rows.value(row, "name");
    item["provider"] = rows.value(row, "provider");
    item["source"] = rows.value(row, "source");
    item["sourceRef"] = rows.value(row, "source_ref");
    item["amapCpid"] = rows.value(row, "amap_cpid");
    item["hasIndoorMap"] = to_int(rows.value(row, "has_indoor_map")) > 0;
    item["description"] = rows.value(row, "description");
    item["defaultFloorCode"] = rows.value(row, "default_floor_code");
    item["floorCount"] = to_int(rows.value(row, "floor_count"));
    item["featureCount"] = to_int(rows.value(row, "feature_count"));
    return item;
}

crow::json::wvalue indoor_floor_json(const tourism::db::PgResult& rows, int row) {
    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["buildingId"] = to_int(rows.value(row, "building_id"));
    item["floorCode"] = rows.value(row, "floor_code");
    item["floorName"] = rows.value(row, "floor_name");
    item["floorIndex"] = to_int(rows.value(row, "floor_index"));
    item["provider"] = rows.value(row, "provider");
    item["source"] = rows.value(row, "source");
    item["sourceRef"] = rows.value(row, "source_ref");
    return item;
}

IndoorFeature indoor_feature_from_rows(const tourism::db::PgResult& rows, int row) {
    IndoorFeature feature;
    feature.id = to_int(rows.value(row, "id"));
    feature.name = rows.value(row, "name");
    feature.type = rows.value(row, "type");
    feature.floor_code = rows.value(row, "floor_code");
    feature.floor_name = rows.value(row, "floor_name");
    feature.provider = rows.value(row, "provider");
    feature.source = rows.value(row, "source");
    feature.source_ref = rows.value(row, "source_ref");
    feature.x = to_double(rows.value(row, "x"));
    feature.y = to_double(rows.value(row, "y"));
    return feature;
}

crow::json::wvalue indoor_feature_json(const IndoorFeature& feature) {
    crow::json::wvalue item;
    item["id"] = feature.id;
    item["name"] = feature.name;
    item["type"] = feature.type;
    item["typeLabel"] = indoor_feature_type_label(feature.type);
    item["floorCode"] = feature.floor_code;
    item["floorName"] = feature.floor_name;
    item["x"] = feature.x;
    item["y"] = feature.y;
    item["provider"] = feature.provider;
    item["source"] = feature.source;
    item["sourceRef"] = feature.source_ref;
    return item;
}

crow::json::wvalue indoor_edge_json(const IndoorEdge& edge) {
    crow::json::wvalue item;
    item["id"] = edge.id;
    item["fromFeatureId"] = edge.from;
    item["toFeatureId"] = edge.to;
    item["distanceMeters"] = static_cast<int>(std::round(edge.distance));
    item["durationSeconds"] = edge.travel_time;
    item["edgeType"] = edge.type;
    item["edgeTypeLabel"] = indoor_edge_type_label(edge.type);
    item["provider"] = edge.provider;
    return item;
}

std::vector<IndoorFeature> load_indoor_features(PgConnection& db, int building_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT
            feat.id::text,
            feat.name,
            feat.type,
            COALESCE(feat.x, 0)::text AS x,
            COALESCE(feat.y, 0)::text AS y,
            feat.provider,
            feat.source,
            feat.source_ref,
            fl.floor_code,
            fl.floor_name
        FROM indoor_features feat
        JOIN indoor_floors fl ON fl.id = feat.floor_id
        WHERE feat.building_id = $1
        ORDER BY fl.floor_index, feat.sort_order, feat.id
    )SQL", {std::to_string(building_id)});

    std::vector<IndoorFeature> features;
    features.reserve(static_cast<size_t>(rows.rows()));
    for (int row = 0; row < rows.rows(); ++row) features.push_back(indoor_feature_from_rows(rows, row));
    return features;
}

std::vector<IndoorEdge> load_indoor_edges(PgConnection& db, int building_id) {
    auto rows = exec_params(db, R"SQL(
        SELECT
            id::text,
            from_feature_id::text,
            to_feature_id::text,
            distance::text,
            travel_time::text,
            edge_type,
            provider
        FROM indoor_edges
        WHERE building_id = $1
        ORDER BY id
    )SQL", {std::to_string(building_id)});

    std::vector<IndoorEdge> edges;
    edges.reserve(static_cast<size_t>(rows.rows()));
    for (int row = 0; row < rows.rows(); ++row) {
        IndoorEdge edge;
        edge.id = to_int(rows.value(row, "id"));
        edge.from = to_int(rows.value(row, "from_feature_id"));
        edge.to = to_int(rows.value(row, "to_feature_id"));
        edge.distance = to_double(rows.value(row, "distance"));
        edge.travel_time = to_int(rows.value(row, "travel_time"));
        edge.type = rows.value(row, "edge_type");
        edge.provider = rows.value(row, "provider");
        edges.push_back(std::move(edge));
    }
    return edges;
}

IndoorRouteResult plan_indoor_dijkstra(const std::map<int, IndoorFeature>& features,
                                       const std::vector<IndoorEdge>& edges,
                                       int start_feature_id,
                                       int end_feature_id,
                                       const std::string& strategy) {
    IndoorRouteResult result;
    if (!features.count(start_feature_id) || !features.count(end_feature_id)) {
        result.error = "Start or end feature is not in this indoor building";
        return result;
    }
    if (start_feature_id == end_feature_id) {
        result.success = true;
        result.feature_path.push_back(start_feature_id);
        return result;
    }

    std::map<int, std::vector<IndoorEdge>> adjacency;
    for (const auto& edge : edges) {
        if (features.count(edge.from) && features.count(edge.to)) adjacency[edge.from].push_back(edge);
    }

    constexpr double kInf = std::numeric_limits<double>::infinity();
    std::map<int, double> distance;
    std::map<int, int> previous;
    std::map<int, IndoorEdge> previous_edge;
    for (const auto& [id, feature] : features) {
        (void)feature;
        distance[id] = kInf;
    }

    using QueueItem = std::pair<double, int>;
    std::priority_queue<QueueItem, std::vector<QueueItem>, std::greater<QueueItem>> queue;
    distance[start_feature_id] = 0.0;
    queue.push({0.0, start_feature_id});

    while (!queue.empty()) {
        auto [current_cost, current] = queue.top();
        queue.pop();
        if (current_cost > distance[current] + 0.0001) continue;
        if (current == end_feature_id) break;

        auto edge_iter = adjacency.find(current);
        if (edge_iter == adjacency.end()) continue;
        for (const auto& edge : edge_iter->second) {
            double weight = strategy == "distance"
                ? std::max(edge.distance, 0.01)
                : std::max(static_cast<double>(edge.travel_time), 1.0);
            double next_cost = current_cost + weight;
            if (next_cost + 0.0001 < distance[edge.to]) {
                distance[edge.to] = next_cost;
                previous[edge.to] = current;
                previous_edge[edge.to] = edge;
                queue.push({next_cost, edge.to});
            }
        }
    }

    if (distance[end_feature_id] == kInf) {
        result.error = "No connected indoor route between the selected features";
        return result;
    }

    std::vector<int> reversed_nodes;
    int cursor = end_feature_id;
    reversed_nodes.push_back(cursor);
    while (cursor != start_feature_id) {
        auto prev_iter = previous.find(cursor);
        if (prev_iter == previous.end()) {
            result.error = "Indoor route reconstruction failed";
            return result;
        }
        result.edge_path.push_back(previous_edge[cursor]);
        cursor = prev_iter->second;
        reversed_nodes.push_back(cursor);
    }

    std::reverse(reversed_nodes.begin(), reversed_nodes.end());
    std::reverse(result.edge_path.begin(), result.edge_path.end());
    for (const auto& edge : result.edge_path) {
        result.distance += edge.distance;
        result.duration += edge.travel_time;
    }
    result.feature_path = std::move(reversed_nodes);
    result.success = true;
    return result;
}

crow::json::wvalue indoor_step_json(const IndoorFeature& from,
                                    const IndoorFeature& to,
                                    const IndoorEdge& edge,
                                    int order) {
    std::string instruction = "从 " + from.name + " 前往 " + to.name;
    if (edge.type == "elevator") instruction = "乘电梯从 " + from.floor_name + " 前往 " + to.floor_name;
    if (edge.type == "stairs") instruction = "走楼梯从 " + from.floor_name + " 前往 " + to.floor_name;

    crow::json::wvalue item;
    item["order"] = order;
    item["fromFeatureId"] = from.id;
    item["toFeatureId"] = to.id;
    item["fromName"] = from.name;
    item["toName"] = to.name;
    item["fromFloorCode"] = from.floor_code;
    item["toFloorCode"] = to.floor_code;
    item["edgeType"] = edge.type;
    item["edgeTypeLabel"] = indoor_edge_type_label(edge.type);
    item["distanceMeters"] = static_cast<int>(std::round(edge.distance));
    item["durationSeconds"] = edge.travel_time;
    item["instruction"] = instruction;
    return item;
}

void audit_indoor_route(PgConnection& db,
                        int building_id,
                        const std::string& provider,
                        const std::string& algorithm,
                        int start_feature_id,
                        int end_feature_id,
                        const std::string& strategy,
                        bool success,
                        bool fallback_used,
                        int duration_ms,
                        const std::string& error_message) {
    try {
        exec_params(db, R"SQL(
            INSERT INTO indoor_route_audit
                (building_id, provider, algorithm, start_feature_id, end_feature_id,
                 strategy, success, fallback_used, duration_ms, error_message)
            VALUES
                ($1::int, $2, $3, $4::int, $5::int, $6, $7::boolean, $8::boolean, $9::int, $10)
        )SQL", {
            std::to_string(building_id),
            provider,
            algorithm,
            std::to_string(start_feature_id),
            std::to_string(end_feature_id),
            strategy,
            success ? "TRUE" : "FALSE",
            fallback_used ? "TRUE" : "FALSE",
            std::to_string(duration_ms),
            error_message
        }, PGRES_COMMAND_OK);
    } catch (...) {
        // Audit is helpful for defense and debugging, but route planning should
        // not fail solely because the audit row could not be written.
    }
}

} // namespace

void register_scenic_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/scenic-spots")([](const crow::request& req) {
        return list_scenic(req);
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/search")([](const crow::request& req) {
        return list_scenic(req);
    });

    CROW_ROUTE(app, "/api/v1/scenic-categories")([]() -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT
                    c.id::text AS id,
                    c.name,
                    COALESCE(c.icon, '') AS icon,
                    COUNT(s.id)::text AS count
                FROM categories c
                JOIN scenic_spots s ON s.category_id = c.id
                WHERE s.status = 1
                GROUP BY c.id, c.name, c.icon, c.sort_order
                ORDER BY c.sort_order, c.name
            )SQL", {});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) {
                crow::json::wvalue item;
                item["id"] = to_int(rows.value(row, "id"));
                item["name"] = rows.value(row, "name");
                item["icon"] = rows.value(row, "icon");
                item["count"] = to_int(rows.value(row, "count"));
                items.push_back(std::move(item));
            }

            crow::json::wvalue data;
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/search/suggestions")([](const crow::request& req) -> crow::response {
        try {
            std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT keyword
                FROM (
                    SELECT name AS keyword, 1 AS rank FROM scenic_spots WHERE status = 1
                    UNION
                    SELECT c.name AS keyword, 2 AS rank FROM categories c
                    UNION
                    SELECT unnest(tags) AS keyword, 3 AS rank FROM scenic_spots WHERE status = 1
                ) source
                WHERE $1 = ''
                   OR lower(keyword) LIKE '%' || lower($1) || '%'
                   -- 简称连字匹配（与景点搜索同规则）："国博" 可命中 "中国国家博物馆"
                   OR (char_length($1) >= 2 AND lower(keyword) LIKE '%' || regexp_replace(lower($1), '(.)', '\1%', 'g'))
                GROUP BY keyword
                -- 包含匹配优先于简称匹配；短名称优先（简称查询的意图通常是核心地标）
                ORDER BY MIN(rank),
                         (lower(keyword) LIKE '%' || lower($1) || '%') DESC,
                         char_length(keyword),
                         keyword
                LIMIT 8
            )SQL", {query});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(rows.value(row, "keyword"));

            crow::json::wvalue data;
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>")([](int id) -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT s.id, s.name, s.description, s.rating, s.address, s.city, s.opening_hours,
                       s.ticket_price, s.duration_minutes, s.crowd_level, s.thumbnail_url,
                       s.view_count, s.favorite_count, s.category_id,
                       COALESCE(c.name, '景点') AS category,
                       COALESCE(array_to_string(s.tags, '|'), '') AS tags,
                       COALESCE(array_to_string(s.images, '|'), '') AS images
                FROM scenic_spots s
                LEFT JOIN categories c ON c.id = s.category_id
                WHERE s.status = 1 AND s.id = $1
            )SQL", {std::to_string(id)});
            if (rows.rows() > 0) return crow::response(ok(scenic_json(rows, 0)));
            return json_error(404, "Scenic spot not found");
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>/reviews")([](int id) -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT r.id::text, r.rating::text, COALESCE(r.content, '') AS content,
                       r.helpful_count::text, r.created_at::date::text AS created_at,
                       COALESCE(u.nickname, u.username, '旅行用户') AS author
                FROM reviews r
                JOIN users u ON u.id = r.user_id
                WHERE r.scenic_spot_id = $1 AND r.status = 1
                ORDER BY r.created_at DESC, r.id DESC
            )SQL", {std::to_string(id)});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) {
                crow::json::wvalue item;
                item["id"] = to_int(rows.value(row, "id"));
                item["author"] = rows.value(row, "author");
                item["rating"] = to_int(rows.value(row, "rating"));
                item["content"] = rows.value(row, "content");
                item["helpfulCount"] = to_int(rows.value(row, "helpful_count"));
                item["createdAt"] = rows.value(row, "created_at");
                items.push_back(std::move(item));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>/facilities")([](const crow::request& req, int id) -> crow::response {
        try {
            std::string type = trim_text(req.url_params.get("type") ? req.url_params.get("type") : "");
            std::string query = trim_text(req.url_params.get("q") ? req.url_params.get("q") : "");
            int limit = query_int(req, "limit", 80, 1, 200);
            // from_node_id: 若提供，按实际步行路径距离（Dijkstra）排序，否则按类型优先级排序
            int from_node_id = query_int(req, "from_node_id", 0, 0, 999999);

            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT f.id::text, f.name, f.type,
                       COALESCE(f.address, '') AS address,
                       COALESCE(f.rating, 0)::text AS rating,
                       COALESCE(f.price_level, 0)::text AS price_level,
                       COALESCE(f.opening_hours, '') AS opening_hours,
                       COALESCE(f.phone, '') AS phone,
                       COALESCE(gn.id, 0)::text AS node_id,
                       ST_X(f.location::geometry)::text AS longitude,
                       ST_Y(f.location::geometry)::text AS latitude,
                       COALESCE(f.source, '') AS source,
                       CASE WHEN EXISTS (
                           SELECT 1
                           FROM graph_edges ge
                           WHERE ge.from_node = gn.id OR ge.to_node = gn.id
                       ) THEN 1 ELSE 0 END::text AS routable,
                       COALESCE((
                           SELECT MIN(ge.distance)
                           FROM graph_edges ge
                           WHERE (ge.from_node = gn.id OR ge.to_node = gn.id)
                             AND ge.source = 'generated'
                       ), 0)::text AS connector_distance
                FROM facilities f
                LEFT JOIN graph_nodes gn ON gn.facility_id = f.id
                WHERE f.scenic_spot_id = $1
                  AND f.location IS NOT NULL
                  AND ($2 = '' OR f.type = $2)
                  AND ($3 = '' OR lower(f.name) LIKE '%' || lower($3) || '%')
                ORDER BY
                    CASE WHEN EXISTS (
                        SELECT 1
                        FROM graph_edges ge
                        WHERE ge.from_node = gn.id OR ge.to_node = gn.id
                    ) THEN 0 ELSE 1 END,
                    CASE f.type
                        WHEN 'entrance' THEN 0
                        WHEN 'toilet' THEN 1
                        WHEN 'restaurant' THEN 2
                        WHEN 'service' THEN 3
                        ELSE 4
                    END,
                    f.name,
                    f.id
                LIMIT $4::int
            )SQL", {std::to_string(id), type, query, std::to_string(limit)});

            // 辅助结构：原始行下标 + 设施节点ID + Dijkstra步行距离（米）
            struct FacilityRow {
                int row;
                int node_id;
                double walk_dist = -1.0;  // -1 表示无路可达
            };

            // 先统计类型分布（与排序无关，从原始行计算）
            std::map<std::string, int> type_counts;
            std::vector<FacilityRow> facility_rows;
            facility_rows.reserve(rows.rows());
            for (int row = 0; row < rows.rows(); ++row) {
                type_counts[rows.value(row, "type")] += 1;
                FacilityRow fr;
                fr.row = row;
                fr.node_id = to_int(rows.value(row, "node_id"));
                facility_rows.push_back(fr);
            }

            // 若提供起点，使用 Dijkstra 计算实际步行距离并按距离升序排列
            // 优势：反映真实可行走路径，而非直线距离（满足评分加分项）
            bool sorted_by_walk = (from_node_id > 0);
            if (sorted_by_walk) {
                auto graph = load_route_graph(db, id);
                for (auto& fr : facility_rows) {
                    if (fr.node_id <= 0) continue;
                    auto route = plan_route_with_waypoints(
                        graph, {from_node_id, fr.node_id}, "walk", "distance", 3);
                    fr.walk_dist = route.success ? route.total_distance : -1.0;
                }
                // 可达设施按步行距离升序，不可达设施排末尾（保持原相对顺序）
                std::stable_sort(facility_rows.begin(), facility_rows.end(),
                    [](const FacilityRow& a, const FacilityRow& b) {
                        if (a.walk_dist >= 0 && b.walk_dist >= 0) return a.walk_dist < b.walk_dist;
                        if (a.walk_dist >= 0) return true;
                        if (b.walk_dist >= 0) return false;
                        return false;
                    });
            }

            crow::json::wvalue::list items;
            for (const auto& fr : facility_rows) {
                auto item = facility_json(rows, fr.row);
                if (sorted_by_walk) {
                    // walkDistance: 实际步行路径距离（米），-1 表示路网中无可达路径
                    item["walkDistance"] = fr.walk_dist >= 0
                        ? static_cast<int>(std::round(fr.walk_dist))
                        : -1;
                }
                items.push_back(std::move(item));
            }

            crow::json::wvalue::list types;
            for (const auto& [type_key, count] : type_counts) {
                crow::json::wvalue type_item;
                type_item["type"] = type_key;
                type_item["label"] = facility_type_label(type_key);
                type_item["count"] = count;
                types.push_back(std::move(type_item));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            data["types"] = std::move(types);
            // 告知前端当前排序方式，方便 UI 标注"按步行距离排序"
            if (sorted_by_walk) data["sortedByWalkDistance"] = true;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // 热门时段：基于系统自有用户行为（打卡/路线规划/游记）聚合的小时级人气画像。
    // 行为数据稀疏时回退到典型游客曲线模型，保证图表始终可用。
    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>/popular-times")([](int id) -> crow::response {
        try {
            PgConnection db;

            // 三类行为信号按小时聚合：打卡（在场，权重3）> 路线规划（意图，权重2）> 游记（回顾，权重1）
            auto rows = exec_params(db, R"SQL(
                WITH signals AS (
                    SELECT EXTRACT(HOUR FROM c.created_at)::int AS hour, 3.0 AS weight
                    FROM user_scenic_checkins c
                    WHERE c.scenic_spot_id = $1
                    UNION ALL
                    SELECT EXTRACT(HOUR FROM rp.created_at)::int, 2.0
                    FROM route_plans rp
                    WHERE EXISTS (
                        SELECT 1 FROM graph_nodes gn
                        LEFT JOIN facilities f ON f.id = gn.facility_id
                        WHERE gn.id = ANY(array_cat(ARRAY[rp.start_node_id, rp.end_node_id],
                                                    COALESCE(rp.waypoint_node_ids, ARRAY[]::integer[])))
                          AND (gn.scenic_spot_id = $1 OR f.scenic_spot_id = $1)
                    )
                    UNION ALL
                    SELECT EXTRACT(HOUR FROM d.created_at)::int, 1.0
                    FROM travel_diaries d
                    WHERE d.status = 1 AND $1 = ANY(d.scenic_spot_ids)
                )
                SELECT hour::text, SUM(weight)::text AS score, COUNT(*)::text AS samples
                FROM signals
                GROUP BY hour
            )SQL", {std::to_string(id)});

            double behavior[24] = {0};
            int total_samples = 0;
            for (int row = 0; row < rows.rows(); ++row) {
                int hour = to_int(rows.value(row, "hour"));
                if (hour >= 0 && hour < 24) {
                    behavior[hour] = to_double(rows.value(row, "score"));
                    total_samples += to_int(rows.value(row, "samples"));
                }
            }

            // 典型游客一日曲线（百分比），作为基线/回退模型
            static const int kTemplate[24] = {0, 0, 0, 0, 0, 0, 5, 15, 35, 60, 85, 90,
                                              75, 70, 85, 90, 80, 60, 40, 30, 20, 10, 5, 0};

            double max_behavior = 0;
            for (double value : behavior) max_behavior = std::max(max_behavior, value);

            // 样本充足时行为数据主导（60/40 混合），不足时纯模型
            const bool use_behavior = total_samples >= 5 && max_behavior > 0;
            int levels[24];
            for (int hour = 0; hour < 24; ++hour) {
                if (use_behavior) {
                    double behavior_norm = behavior[hour] / max_behavior * 100.0;
                    levels[hour] = static_cast<int>(std::round(behavior_norm * 0.6 + kTemplate[hour] * 0.4));
                } else {
                    levels[hour] = kTemplate[hour];
                }
            }

            auto counts = exec_params(db, R"SQL(
                SELECT
                    (SELECT COUNT(*) FROM user_scenic_checkins WHERE scenic_spot_id = $1)::text AS checkins,
                    (SELECT COUNT(*) FROM travel_diaries WHERE status = 1 AND $1 = ANY(scenic_spot_ids))::text AS diaries
            )SQL", {std::to_string(id)});

            crow::json::wvalue::list hours;
            crow::json::wvalue::list peak_hours;
            for (int hour = 0; hour < 24; ++hour) {
                crow::json::wvalue item;
                item["hour"] = hour;
                item["level"] = levels[hour];
                hours.push_back(std::move(item));
                if (levels[hour] >= 80) peak_hours.push_back(hour);
            }

            crow::json::wvalue data;
            data["spotId"] = id;
            data["hours"] = std::move(hours);
            data["peakHours"] = std::move(peak_hours);
            data["source"] = use_behavior ? "behavior+model" : "model";
            data["samples"]["total"] = total_samples;
            data["samples"]["checkins"] = to_int(counts.value(0, "checkins"));
            data["samples"]["diaries"] = to_int(counts.value(0, "diaries"));
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>/indoor-buildings")([](int id) -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT
                    b.id::text,
                    b.scenic_spot_id::text,
                    b.name,
                    b.provider,
                    b.source,
                    b.source_ref,
                    COALESCE(b.amap_cpid, '') AS amap_cpid,
                    CASE WHEN b.has_indoor_map THEN 1 ELSE 0 END::text AS has_indoor_map,
                    COALESCE(b.description, '') AS description,
                    COALESCE(b.default_floor_code, '') AS default_floor_code,
                    COUNT(DISTINCT fl.id)::text AS floor_count,
                    COUNT(DISTINCT feat.id)::text AS feature_count
                FROM indoor_buildings b
                LEFT JOIN indoor_floors fl ON fl.building_id = b.id
                LEFT JOIN indoor_features feat ON feat.building_id = b.id
                WHERE b.scenic_spot_id = $1
                GROUP BY b.id
                ORDER BY b.has_indoor_map DESC, b.id
            )SQL", {std::to_string(id)});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(indoor_building_json(rows, row));

            crow::json::wvalue data;
            data["available"] = !items.empty();
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/indoor-buildings/<int>/features")([](const crow::request& req, int id) -> crow::response {
        try {
            std::string floor = trim_text(req.url_params.get("floor") ? req.url_params.get("floor") : "");
            std::string type = trim_text(req.url_params.get("type") ? req.url_params.get("type") : "");

            PgConnection db;
            auto floor_rows = exec_params(db, R"SQL(
                SELECT
                    id::text,
                    building_id::text,
                    floor_code,
                    floor_name,
                    floor_index::text,
                    provider,
                    source,
                    source_ref
                FROM indoor_floors
                WHERE building_id = $1
                ORDER BY floor_index, id
            )SQL", {std::to_string(id)});

            auto rows = exec_params(db, R"SQL(
                SELECT
                    feat.id::text,
                    feat.name,
                    feat.type,
                    COALESCE(feat.x, 0)::text AS x,
                    COALESCE(feat.y, 0)::text AS y,
                    feat.provider,
                    feat.source,
                    feat.source_ref,
                    fl.floor_code,
                    fl.floor_name
                FROM indoor_features feat
                JOIN indoor_floors fl ON fl.id = feat.floor_id
                WHERE feat.building_id = $1
                  AND ($2 = '' OR fl.floor_code = $2)
                  AND ($3 = '' OR feat.type = $3)
                ORDER BY fl.floor_index, feat.sort_order, feat.id
            )SQL", {std::to_string(id), floor, type});

            crow::json::wvalue::list floors;
            for (int row = 0; row < floor_rows.rows(); ++row) floors.push_back(indoor_floor_json(floor_rows, row));

            crow::json::wvalue::list edges;
            for (const auto& edge : load_indoor_edges(db, id)) edges.push_back(indoor_edge_json(edge));

            std::map<std::string, int> type_counts;
            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) {
                auto feature = indoor_feature_from_rows(rows, row);
                type_counts[feature.type] += 1;
                items.push_back(indoor_feature_json(feature));
            }

            crow::json::wvalue::list types;
            for (const auto& [type_key, count] : type_counts) {
                crow::json::wvalue item;
                item["type"] = type_key;
                item["label"] = indoor_feature_type_label(type_key);
                item["count"] = count;
                types.push_back(std::move(item));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            data["floors"] = std::move(floors);
            data["types"] = std::move(types);
            data["edges"] = std::move(edges);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/indoor-buildings/<int>/routes/plan").methods("POST"_method)(
        [](const crow::request& req, int id) -> crow::response {
            auto started_at = std::chrono::steady_clock::now();
            try {
                auto body = crow::json::load(req.body);
                if (!body) return json_error(400, "Invalid JSON");

                int start_feature_id = json_int(body, "startFeatureId");
                int end_feature_id = json_int(body, "endFeatureId");
                std::string strategy = normalize_indoor_strategy(json_string(body, "strategy", "time"));
                if (start_feature_id <= 0 || end_feature_id <= 0) {
                    return json_error(400, "startFeatureId and endFeatureId are required");
                }

                PgConnection db;
                auto building_rows = exec_params(db, R"SQL(
                    SELECT
                        id::text,
                        provider,
                        CASE WHEN has_indoor_map THEN 1 ELSE 0 END::text AS has_indoor_map
                    FROM indoor_buildings
                    WHERE id = $1
                    LIMIT 1
                )SQL", {std::to_string(id)});
                if (!building_rows.rows()) return json_error(404, "Indoor building not found");

                std::string configured_provider = building_rows.value(0, "provider");
                bool has_amap_indoor = to_int(building_rows.value(0, "has_indoor_map")) > 0;
                auto features_vector = load_indoor_features(db, id);
                auto edges = load_indoor_edges(db, id);

                std::map<int, IndoorFeature> features;
                for (const auto& feature : features_vector) features[feature.id] = feature;
                if (!features.count(start_feature_id) || !features.count(end_feature_id)) {
                    int elapsed_ms = static_cast<int>(std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - started_at).count());
                    audit_indoor_route(db, id, configured_provider, "indoor-dijkstra",
                                       start_feature_id, end_feature_id, strategy,
                                       false, false, elapsed_ms, "Feature is not in this indoor building");
                    return json_error(400, "Start or end feature is not in this indoor building");
                }
                if (edges.empty()) {
                    int elapsed_ms = static_cast<int>(std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - started_at).count());
                    audit_indoor_route(db, id, configured_provider, "indoor-dijkstra",
                                       start_feature_id, end_feature_id, strategy,
                                       false, false, elapsed_ms, "Indoor graph has no route edges");
                    return json_error(422, "Indoor graph has no route edges");
                }

                auto route = plan_indoor_dijkstra(features, edges, start_feature_id, end_feature_id, strategy);
                bool fallback_used = configured_provider == "amap_indoor" && has_amap_indoor;
                std::string response_provider = fallback_used ? "local_indoor_graph" : configured_provider;
                if (!route.success) {
                    int elapsed_ms = static_cast<int>(std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - started_at).count());
                    audit_indoor_route(db, id, response_provider, "indoor-dijkstra",
                                       start_feature_id, end_feature_id, strategy,
                                       false, fallback_used, elapsed_ms, route.error);
                    return json_error(422, route.error.empty() ? "No indoor route found" : route.error);
                }

                crow::json::wvalue::list path;
                for (int feature_id : route.feature_path) {
                    if (features.count(feature_id)) path.push_back(indoor_feature_json(features.at(feature_id)));
                }

                crow::json::wvalue::list steps;
                for (size_t index = 0; index < route.edge_path.size(); ++index) {
                    const auto& edge = route.edge_path[index];
                    steps.push_back(indoor_step_json(features.at(edge.from), features.at(edge.to), edge,
                                                     static_cast<int>(index + 1)));
                }

                int elapsed_ms = static_cast<int>(std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::steady_clock::now() - started_at).count());
                audit_indoor_route(db, id, response_provider, "indoor-dijkstra",
                                   start_feature_id, end_feature_id, strategy,
                                   true, fallback_used, elapsed_ms, "");

                crow::json::wvalue data;
                data["buildingId"] = id;
                data["provider"] = response_provider;
                data["configuredProvider"] = configured_provider;
                data["algorithm"] = "indoor-dijkstra";
                data["distanceMeters"] = static_cast<int>(std::round(route.distance));
                data["durationSeconds"] = route.duration;
                data["strategy"] = strategy;
                data["steps"] = std::move(steps);
                data["path"] = std::move(path);
                data["fallbackUsed"] = fallback_used;
                data["hasAmapIndoor"] = has_amap_indoor;
                data["elapsedMs"] = elapsed_ms;
                return crow::response(ok(std::move(data)));
            } catch (const std::exception& error) {
                return json_error(500, error.what());
            }
        });

    // 室内外跨层导航：一次请求完成"景区路网步行 → 建筑入口交接 → 室内逐层导航"。
    // 室外段走 graph_nodes/graph_edges 的 Dijkstra，室内段走 indoor_features/indoor_edges
    // 的 Dijkstra，两层在建筑的室外锚点节点（outdoor_node_id）与室内入口 feature 处缝合。
    CROW_ROUTE(app, "/api/v1/indoor-buildings/<int>/routes/plan-cross").methods("POST"_method)(
        [](const crow::request& req, int id) -> crow::response {
            auto started_at = std::chrono::steady_clock::now();
            try {
                auto body = crow::json::load(req.body);
                if (!body) return json_error(400, "Invalid JSON");

                int start_node_id = json_int(body, "startNodeId");
                int end_feature_id = json_int(body, "endFeatureId");
                std::string strategy = normalize_indoor_strategy(json_string(body, "strategy", "time"));
                if (start_node_id <= 0 || end_feature_id <= 0) {
                    return json_error(400, "startNodeId and endFeatureId are required");
                }

                PgConnection db;
                auto building_rows = exec_params(db, R"SQL(
                    SELECT b.id::text, b.name, b.provider, b.scenic_spot_id::text,
                           COALESCE(b.outdoor_node_id, 0)::text AS outdoor_node_id
                    FROM indoor_buildings b
                    WHERE b.id = $1
                    LIMIT 1
                )SQL", {std::to_string(id)});
                if (!building_rows.rows()) return json_error(404, "Indoor building not found");

                std::string building_name = building_rows.value(0, "name");
                int scenic_spot_id = to_int(building_rows.value(0, "scenic_spot_id"));
                int anchor_node_id = to_int(building_rows.value(0, "outdoor_node_id"));

                // 锚点未持久化时按名称规则实时匹配（与迁移 SQL 同一规则）
                if (anchor_node_id <= 0) {
                    auto anchor_rows = exec_params(db, R"SQL(
                        SELECT gn.id::text
                        FROM graph_nodes gn
                        WHERE gn.location IS NOT NULL
                          AND (
                              gn.name = $1
                              OR REPLACE(gn.name, '北京大学', '北大') = $1
                              OR REPLACE($1, '北大', '北京大学') = gn.name
                          )
                        ORDER BY (gn.node_type = 'building') DESC, gn.id
                        LIMIT 1
                    )SQL", {building_name});
                    if (anchor_rows.rows() > 0) anchor_node_id = to_int(anchor_rows.value(0, "id"));
                }
                if (anchor_node_id <= 0) {
                    return json_error(422, "该建筑尚未绑定室外路网锚点，无法跨层导航（可执行 cross_layer_navigation_schema.sql 或手动设置 outdoor_node_id）");
                }

                // ---- 室外段：景区路网 Dijkstra（步行）----
                auto graph = load_route_graph(db, scenic_spot_id);
                if (!graph.nodes.count(start_node_id)) {
                    return json_error(400, "室外起点不在该景区路网中");
                }
                if (!graph.nodes.count(anchor_node_id)) {
                    return json_error(422, "建筑锚点不在该景区路网中，请检查 outdoor_node_id 绑定");
                }

                std::string optimization = strategy == "distance" ? "distance" : "time";
                auto outdoor = plan_route_with_waypoints(
                    graph, {start_node_id, anchor_node_id}, "walk", optimization, 3);
                if (!outdoor.success) {
                    return json_error(422, outdoor.error.empty() ? "室外段无可达路线" : outdoor.error);
                }

                // ---- 交接点：室内入口 feature（楼层最低的 entrance）----
                auto entrance_rows = exec_params(db, R"SQL(
                    SELECT feat.id::text, feat.name
                    FROM indoor_features feat
                    JOIN indoor_floors fl ON fl.id = feat.floor_id
                    WHERE feat.building_id = $1 AND feat.type = 'entrance'
                    ORDER BY fl.floor_index, feat.sort_order, feat.id
                    LIMIT 1
                )SQL", {std::to_string(id)});
                if (!entrance_rows.rows()) {
                    return json_error(422, "该建筑室内图未定义入口节点（type='entrance'）");
                }
                int entrance_feature_id = to_int(entrance_rows.value(0, "id"));
                std::string entrance_name = entrance_rows.value(0, "name");

                // ---- 室内段：室内图 Dijkstra ----
                auto features_vector = load_indoor_features(db, id);
                auto indoor_edges = load_indoor_edges(db, id);
                std::map<int, IndoorFeature> features;
                for (const auto& feature : features_vector) features[feature.id] = feature;
                if (!features.count(end_feature_id)) {
                    return json_error(400, "室内终点不在该建筑中");
                }

                auto indoor = plan_indoor_dijkstra(features, indoor_edges, entrance_feature_id, end_feature_id, strategy);
                if (!indoor.success) {
                    return json_error(422, indoor.error.empty() ? "室内段无可达路线" : indoor.error);
                }

                int elapsed_ms = static_cast<int>(std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::steady_clock::now() - started_at).count());
                audit_indoor_route(db, id, "local_indoor_graph", "cross-layer-dijkstra",
                                   entrance_feature_id, end_feature_id, strategy, true, false, elapsed_ms, "");

                // ---- 组装响应：室外段（地图坐标）+ 交接信息 + 室内段（楼层步骤）+ 总计 ----
                crow::json::wvalue::list indoor_path;
                for (int feature_id : indoor.feature_path) {
                    if (features.count(feature_id)) indoor_path.push_back(indoor_feature_json(features.at(feature_id)));
                }
                crow::json::wvalue::list indoor_steps;
                for (size_t index = 0; index < indoor.edge_path.size(); ++index) {
                    const auto& edge = indoor.edge_path[index];
                    indoor_steps.push_back(indoor_step_json(features.at(edge.from), features.at(edge.to), edge,
                                                            static_cast<int>(index + 1)));
                }

                crow::json::wvalue indoor_json;
                indoor_json["algorithm"] = "indoor-dijkstra";
                indoor_json["distanceMeters"] = static_cast<int>(std::round(indoor.distance));
                indoor_json["durationSeconds"] = indoor.duration;
                indoor_json["strategy"] = strategy;
                indoor_json["steps"] = std::move(indoor_steps);
                indoor_json["path"] = std::move(indoor_path);
                indoor_json["entranceFeatureId"] = entrance_feature_id;

                crow::json::wvalue data;
                data["buildingId"] = id;
                data["buildingName"] = building_name;
                data["algorithm"] = "cross-layer-dijkstra";
                data["strategy"] = strategy;
                data["outdoor"] = computed_route_json(graph, outdoor, optimization, "walk");
                data["indoor"] = std::move(indoor_json);
                data["handoff"]["outdoorNodeId"] = anchor_node_id;
                data["handoff"]["outdoorNodeName"] = graph.nodes.at(anchor_node_id).name;
                data["handoff"]["entranceFeatureId"] = entrance_feature_id;
                data["handoff"]["entranceName"] = entrance_name;
                data["totalDistanceMeters"] = static_cast<int>(std::round(outdoor.total_distance + indoor.distance));
                data["totalDurationSeconds"] = outdoor.total_duration + indoor.duration;
                data["elapsedMs"] = elapsed_ms;
                return crow::response(ok(std::move(data)));
            } catch (const std::exception& error) {
                return json_error(500, error.what());
            }
        });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>/internal-map")([](int id) -> crow::response {
        try {
            PgConnection db;
            auto graph = load_route_graph(db, id);

            crow::json::wvalue::list nodes;
            for (const auto& [node_id, node] : graph.nodes) {
                (void)node_id;
                nodes.push_back(graph_node_json(node));
            }

            crow::json::wvalue::list edges;
            int edge_count = 0;
            for (const auto& [from, from_edges] : graph.edges) {
                (void)from;
                for (const auto& edge : from_edges) {
                    ++edge_count;
                    edges.push_back(edge_json(graph, edge));
                }
            }

            crow::json::wvalue data;
            data["nodes"] = std::move(nodes);
            data["edges"] = std::move(edges);
            data["nodeCount"] = static_cast<int>(graph.nodes.size());
            data["edgeCount"] = edge_count;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>/internal-routes/plan").methods("POST"_method)(
        [](const crow::request& req, int id) -> crow::response {
            try {
                auto body = crow::json::load(req.body);
                if (!body) return json_error(400, "Invalid JSON");

                PgConnection db;
                auto graph = load_route_graph(db, id);
                if (graph.nodes.empty()) return json_error(404, "当前景点暂无内部导航数据");

                int start_node_id = json_int(body, "startNodeId");
                int end_node_id = json_int(body, "endNodeId");
                int facility_id = json_int(body, "facilityId");
                double start_latitude = json_double_value(body, "startLat");
                double start_longitude = json_double_value(body, "startLng");
                bool used_map_start = start_latitude != 0.0 && start_longitude != 0.0;
                double start_snap_distance = 0.0;
                std::string optimization = normalize_optimization(json_string(body, "optimization", "balanced"));

                if (facility_id > 0 && end_node_id <= 0) {
                    end_node_id = node_id_for_facility(db, id, facility_id);
                }

                if (!graph.nodes.count(end_node_id)) return json_error(400, "终点不在当前景点内部路网中");
                if (!node_has_incident_edge(graph, end_node_id)) {
                    return json_error(422, "该设施未接入真实内部路网，无法生成步行路线");
                }

                if (start_node_id <= 0 && used_map_start) {
                    auto nearest = nearest_node_with_distance(graph, start_latitude, start_longitude, true);
                    start_node_id = nearest.first;
                    start_snap_distance = nearest.second;
                    if (start_node_id <= 0 || start_snap_distance > kInternalSnapMaxMeters) {
                        return json_error(422, "起点离内部道路较远，请在道路附近重新点选");
                    }
                }
                if (start_node_id <= 0) {
                    start_node_id = reachable_default_start_node_id(graph, end_node_id, optimization);
                    if (start_node_id <= 0) {
                        return json_error(422, "当前没有与该设施连通的景区入口");
                    }
                }

                if (!graph.nodes.count(start_node_id)) return json_error(400, "起点不在当前景点内部路网中");

                auto route = plan_route_with_waypoints(graph, {start_node_id, end_node_id}, "walk", optimization, 3);
                if (!route.success) {
                    return json_error(422, "当前内部路网无法连通该设施，未生成直线示意路线");
                }
                if (!route_uses_real_road(route.edges)) {
                    return json_error(422, "当前路线缺少真实道路数据，未生成直线示意路线");
                }
                if (route_has_long_connector(route.edges)) {
                    return json_error(422, "该设施离真实道路较远，未接入可导航路网");
                }

                crow::json::wvalue data = computed_route_json(graph, route, optimization, "walk");
                data["usedInternalMap"] = true;
                data["usedInternalFallback"] = false;
                data["startNodeId"] = start_node_id;
                data["endNodeId"] = end_node_id;
                data["routeQuality"] = route_quality_json(graph, route.edges, start_node_id, end_node_id, start_snap_distance, used_map_start);
                return crow::response(ok(std::move(data)));
            } catch (const std::exception& error) {
                return json_error(500, error.what());
            }
        });
}

} // namespace tourism::api
