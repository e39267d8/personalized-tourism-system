#include "api/scenic_routes.h"

#include "db/postgres.h"
#include "services/route_graph_service.h"
#include "services/scenic_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
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
                WHERE $1 = '' OR lower(keyword) LIKE '%' || lower($1) || '%'
                GROUP BY keyword
                ORDER BY MIN(rank), keyword
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
                       s.category_id,
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

            std::map<std::string, int> type_counts;
            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) {
                type_counts[rows.value(row, "type")] += 1;
                items.push_back(facility_json(rows, row));
            }

            crow::json::wvalue::list types;
            for (const auto& [type_key, count] : type_counts) {
                crow::json::wvalue item;
                item["type"] = type_key;
                item["label"] = facility_type_label(type_key);
                item["count"] = count;
                types.push_back(std::move(item));
            }

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            data["types"] = std::move(types);
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
