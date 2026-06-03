#include "api/route_routes.h"

#include "db/postgres.h"
#include "services/amap_route_service.h"
#include "services/route_graph_service.h"
#include "support/api_helpers.h"

#include <algorithm>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_sql;
using tourism::services::RouteNode;
using tourism::services::computed_route_json;
using tourism::services::load_route_graph;
using tourism::services::normalize_optimization;
using tourism::services::normalize_transport;
using tourism::services::plan_route_with_waypoints;
using tourism::services::route_json;
using tourism::services::route_node_json;
using tourism::support::json_error;
using tourism::support::json_int;
using tourism::support::json_int_array;
using tourism::support::json_string;
using tourism::support::json_string_array;
using tourism::support::ok;
using tourism::support::trim_text;

} // namespace

void register_route_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/route-nodes")([]() -> crow::response {
        try {
            PgConnection db;
            auto graph = load_route_graph(db);

            std::vector<RouteNode> nodes;
            nodes.reserve(graph.nodes.size());
            for (const auto& [id, node] : graph.nodes) {
                (void)id;
                nodes.push_back(node);
            }
            std::sort(nodes.begin(), nodes.end(), [](const RouteNode& left, const RouteNode& right) {
                if (left.type != right.type) return left.type > right.type;
                return left.id < right.id;
            });

            crow::json::wvalue::list items;
            for (const auto& node : nodes) items.push_back(route_node_json(node));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/routes")([]() -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_sql(db, R"SQL(
                SELECT rp.id::text, rp.title, rp.travel_mode, rp.total_distance::text,
                       rp.total_duration::text, rp.optimization_type,
                       COALESCE((
                           SELECT string_agg((point.value->>0) || ',' || (point.value->>1), '|' ORDER BY point.ordinality)
                           FROM jsonb_array_elements(rp.route_geometry->'coordinates') WITH ORDINALITY AS point(value, ordinality)
                       ), '') AS coordinates,
                       COALESCE(array_to_string(ARRAY(
                           SELECT gn.name
                           FROM unnest(array_cat(ARRAY[rp.start_node_id],
                                array_cat(COALESCE(rp.waypoint_node_ids, ARRAY[]::integer[]), ARRAY[rp.end_node_id])))
                                WITH ORDINALITY AS ids(node_id, ord)
                           JOIN graph_nodes gn ON gn.id = ids.node_id
                           ORDER BY ids.ord
                       ), '|'), '') AS stops
                FROM route_plans rp
                ORDER BY rp.id
            )SQL");

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(route_json(rows, row));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/routes/plan").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            int start_node_id = json_int(body, "startNodeId");
            int end_node_id = json_int(body, "endNodeId");
            std::vector<int> waypoints = json_int_array(body, "waypointNodeIds");
            std::string start_text = trim_text(json_string(body, "startText"));
            std::string end_text = trim_text(json_string(body, "endText"));
            std::vector<std::string> waypoint_texts = json_string_array(body, "waypointTexts");
            std::string raw_transport = json_string(body, "travelMode", "mixed");
            std::string transport = normalize_transport(raw_transport);
            std::string optimization = normalize_optimization(json_string(body, "optimization", "balanced"));
            int crowd_tolerance = std::max(1, std::min(4, json_int(body, "crowdTolerance", 3)));
            std::string city = trim_text(json_string(body, "city", "北京"));

            if (!start_text.empty() || !end_text.empty()) {
                if (start_text.empty() || end_text.empty()) {
                    return json_error(400, "请输入出发点和目的地");
                }

                std::vector<std::string> place_texts;
                place_texts.push_back(start_text);
                for (const auto& waypoint : waypoint_texts) place_texts.push_back(waypoint);
                place_texts.push_back(end_text);

                std::string key = tourism::services::amap_key();
                if (key.empty()) {
                    return json_error(500, "未配置高德 Web Service Key，无法使用文本地点路线规划");
                }

                std::string amap_mode = raw_transport == "driving" || raw_transport == "car" ? "driving" :
                                        raw_transport == "bike" ? "bike" :
                                        raw_transport == "transit" || raw_transport == "bus" || raw_transport == "subway" ? raw_transport :
                                        "walk";
                return crow::response(ok(tourism::services::plan_amap_route_json(key, city, amap_mode, place_texts)));
            }

            if (start_node_id <= 0 || end_node_id <= 0) {
                return json_error(400, "请选择起点和终点");
            }

            PgConnection db;
            auto graph = load_route_graph(db);

            std::vector<int> points;
            points.push_back(start_node_id);
            for (int waypoint : waypoints) {
                if (waypoint != start_node_id && waypoint != end_node_id) points.push_back(waypoint);
            }
            points.push_back(end_node_id);

            auto route = plan_route_with_waypoints(graph, points, transport, optimization, crowd_tolerance);
            if (!route.success) return json_error(404, route.error.empty() ? "无法规划路线" : route.error);

            crow::json::wvalue data = computed_route_json(graph, route, optimization, transport);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
