#include "api/route_routes.h"

#include "db/postgres.h"
#include "graph/congestion.h"
#include "services/amap_route_service.h"
#include "services/route_graph_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <unordered_map>
#include <utility>
#include <vector>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_sql;
using tourism::services::RouteNode;
using tourism::services::assess_route_quality;
using tourism::services::apply_congestion_travel_time;
using tourism::services::build_tsp_matrix;
using tourism::services::compose_tsp_route;
using tourism::services::computed_route_json;
using tourism::services::load_route_graph;
using tourism::services::normalize_optimization;
using tourism::services::normalize_transport;
using tourism::services::plan_route_with_waypoints;
using tourism::services::route_json;
using tourism::services::route_node_json;
using tourism::services::solve_tsp;
using tourism::services::tour_route_json;
using tourism::support::json_error;
using tourism::support::json_int;
using tourism::support::json_int_array;
using tourism::support::json_string;
using tourism::support::json_string_array;
using tourism::support::ok;
using tourism::support::trim_text;
using tourism::support::query_int;
using tourism::support::to_double;
using tourism::support::to_int;

// 拥挤度数据闭环：从系统自有行为数据（打卡/路线规划/游记）聚合
// 指定小时（±1h 窗口）各景点的活跃度因子（0..1，按最大值归一化）。
// 数据飞轮：用户用得越多，拥挤度画像越贴近真实。
std::unordered_map<int, double> load_spot_activity(PgConnection& db, int hour) {
    std::unordered_map<int, double> factors;
    const int prev = (hour + 23) % 24;
    const int next = (hour + 1) % 24;
    auto rows = tourism::db::exec_params(db, R"SQL(
        WITH signals AS (
            SELECT c.scenic_spot_id AS spot_id, 3.0 AS weight
            FROM user_scenic_checkins c
            WHERE EXTRACT(HOUR FROM c.created_at)::int IN ($1::int, $2::int, $3::int)
            UNION ALL
            SELECT gn.scenic_spot_id, 2.0
            FROM route_plans rp
            JOIN graph_nodes gn ON gn.id = ANY(array_cat(ARRAY[rp.start_node_id, rp.end_node_id],
                                                         COALESCE(rp.waypoint_node_ids, ARRAY[]::integer[])))
            WHERE gn.scenic_spot_id IS NOT NULL
              AND EXTRACT(HOUR FROM rp.created_at)::int IN ($1::int, $2::int, $3::int)
            UNION ALL
            SELECT unnest(d.scenic_spot_ids), 1.0
            FROM travel_diaries d
            WHERE d.status = 1
              AND EXTRACT(HOUR FROM d.created_at)::int IN ($1::int, $2::int, $3::int)
        )
        SELECT spot_id::text, SUM(weight)::text AS score
        FROM signals
        WHERE spot_id IS NOT NULL
        GROUP BY spot_id
    )SQL", {std::to_string(hour), std::to_string(prev), std::to_string(next)});

    double max_score = 0;
    std::vector<std::pair<int, double>> scores;
    for (int row = 0; row < rows.rows(); ++row) {
        int spot_id = to_int(rows.value(row, "spot_id"));
        double score = to_double(rows.value(row, "score"));
        if (spot_id > 0 && score > 0) {
            scores.push_back({spot_id, score});
            max_score = std::max(max_score, score);
        }
    }
    if (max_score <= 0) return factors;
    for (const auto& [spot_id, score] : scores) factors[spot_id] = score / max_score;
    return factors;
}

void attach_route_quality(crow::json::wvalue& data, const tourism::services::RouteQualityReport& quality) {
    crow::json::wvalue item;
    item["displayable"] = quality.displayable;
    item["realRoadEdges"] = quality.real_road_edges;
    item["generatedConnectorEdges"] = quality.generated_connector_edges;
    item["missingGeometryEdges"] = quality.missing_geometry_edges;
    item["maxGeneratedConnectorMeters"] = quality.max_generated_connector_meters;
    data["routeQuality"] = std::move(item);
}

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
                    return json_error(500, "未配置地图路线服务 Key，无法使用文本地点路线规划");
                }

                std::string amap_mode = raw_transport == "driving" || raw_transport == "car" ? "driving" :
                                        raw_transport == "bike" ? "bike" :
                                        raw_transport == "transit" || raw_transport == "bus" || raw_transport == "subway" ? raw_transport :
                                        "walk";
                return crow::response(ok(tourism::services::plan_amap_route_json(
                    key, city, amap_mode, optimization, place_texts
                )));
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
            auto quality = assess_route_quality(route);
            if (!quality.displayable) return json_error(422, quality.error);

            crow::json::wvalue data = computed_route_json(graph, route, optimization, transport);
            attach_route_quality(data, quality);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/routes/tour").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::vector<int> waypoints = json_int_array(body, "nodeIds");
            std::string raw_transport = json_string(body, "travelMode", "walk");
            std::string transport = normalize_transport(raw_transport);
            std::string optimization = normalize_optimization(json_string(body, "optimization", "balanced"));
            int crowd_tolerance = std::max(1, std::min(4, json_int(body, "crowdTolerance", 3)));

            if (waypoints.size() < 2) {
                return json_error(400, "环游至少需要2个点位");
            }
            if (waypoints.size() > 30) {
                return json_error(400, "环游最多支持30个点位");
            }

            PgConnection db;
            auto graph = load_route_graph(db);

            // Verify all points exist in graph
            for (int node_id : waypoints) {
                if (!graph.nodes.count(node_id)) {
                    return json_error(400, "点位 " + std::to_string(node_id) + " 不在路网中");
                }
            }

            // Build TSP distance matrix
            auto matrix = build_tsp_matrix(graph, waypoints, transport, optimization, crowd_tolerance);

            // Solve TSP
            auto tsp_result = solve_tsp(matrix);
            if (!tsp_result.success) {
                return json_error(422, tsp_result.error.empty() ? "无法找到环游路线" : tsp_result.error);
            }

            // Compose full route from TSP result
            auto route = compose_tsp_route(graph, tsp_result, waypoints, transport, optimization, crowd_tolerance);
            if (!route.success) {
                return json_error(422, route.error.empty() ? "无法规划路线" : route.error);
            }
            auto quality = assess_route_quality(route);
            if (!quality.displayable) return json_error(422, quality.error);

            std::vector<int> visit_order;
            for (int idx : tsp_result.best_order) visit_order.push_back(waypoints[idx]);

            crow::json::wvalue data = tour_route_json(graph, route, visit_order, optimization, transport, tsp_result.algorithm_used);
            attach_route_quality(data, quality);
            data["tspDistance"] = static_cast<int>(tsp_result.total_distance);
            data["tspDuration"] = tsp_result.total_duration;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // Congestion-aware route planning
    CROW_ROUTE(app, "/api/v1/routes/plan/congestion").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            int start_id = json_int(body, "start_id", -1);
            int end_id = json_int(body, "end_id", -1);
            std::string transport = trim_text(json_string(body, "travel_mode", "walk"));
            int hour = std::max(0, std::min(23, json_int(body, "hour", 12)));

            if (start_id < 0 || end_id < 0) return json_error(400, "start_id and end_id are required");

            PgConnection db;
            auto graph = load_route_graph(db, 0);

            // 行为画像修正：该时段活跃度高的景点，其内部边拥挤度上调，
            // Dijkstra 自然倾向绕开热门区域（数据来自系统自有打卡/规划/游记）
            auto spot_activity = load_spot_activity(db, hour);
            int boosted_edges = 0;
            if (!spot_activity.empty()) {
                for (auto& [from_id, edge_list] : graph.edges) {
                    (void)from_id;
                    for (auto& edge : edge_list) {
                        double factor = 0;
                        auto from_node = graph.nodes.find(edge.from);
                        auto to_node = graph.nodes.find(edge.to);
                        if (from_node != graph.nodes.end()) {
                            auto it = spot_activity.find(from_node->second.scenic_spot_id);
                            if (it != spot_activity.end()) factor = std::max(factor, it->second);
                        }
                        if (to_node != graph.nodes.end()) {
                            auto it = spot_activity.find(to_node->second.scenic_spot_id);
                            if (it != spot_activity.end()) factor = std::max(factor, it->second);
                        }
                        int bump = factor >= 0.66 ? 2 : factor >= 0.33 ? 1 : 0;
                        // 只抬升本就拥挤的主通道边（≥3）：热门时段人流挤在主通道，
                        // 僻静绕行路径依然僻静。若把景点周边所有边一起抬升，
                        // 会抹平主路与绕行路的相对差异，绕行决策反而失效。
                        if (bump > 0 && edge.congestion >= 3 && edge.congestion < 4) {
                            edge.congestion = std::min(4, edge.congestion + bump);
                            boosted_edges++;
                        }
                    }
                }
            }

            // Compute time-of-day crowd_tolerance: lower = more tolerance for crowds
            // During peak hours, tolerance is low (crowds matter more)
            int crowd_tolerance = 3;
            if (hour >= 7 && hour <= 9) crowd_tolerance = 1;   // morning peak: very sensitive
            else if (hour >= 17 && hour <= 19) crowd_tolerance = 0; // evening peak: most sensitive
            else if (hour >= 9 && hour <= 11) crowd_tolerance = 2;
            else if (hour >= 22 || hour <= 5) crowd_tolerance = 4; // off-peak: not sensitive

            // 优化目标跟随请求（时间/距离/均衡的拥挤敏感度不同），不再写死 balanced
            std::string optimization = normalize_optimization(json_string(body, "optimization", "balanced"));

            std::vector<int> points = {start_id, end_id};
            auto result = plan_route_with_waypoints(graph, points, transport, optimization, crowd_tolerance);

            if (!result.success) return json_error(422, result.error);
            apply_congestion_travel_time(result, crowd_tolerance);
            auto quality = assess_route_quality(result);
            if (!quality.displayable) return json_error(422, quality.error);

            crow::json::wvalue data = computed_route_json(graph, result, optimization, transport);
            attach_route_quality(data, quality);
            data["hour"] = hour;
            data["optimization"] = optimization;
            data["crowd_tolerance"] = crowd_tolerance;
            data["congestionSource"] = boosted_edges > 0 ? "behavior+time" : "time-model";
            data["behaviorBoostedEdges"] = boosted_edges;
            static const char* labels[] = {"极度敏感", "敏感", "中等", "宽松", "非常宽松"};
            data["crowd_label"] = labels[std::max(0, std::min(4, crowd_tolerance))];

            // Add per-segment congestion info
            crow::json::wvalue segments;
            int seg_idx = 0;
            for (const auto& edge : result.edges) {
                segments[seg_idx]["from"] = edge.from;
                segments[seg_idx]["to"] = edge.to;
                segments[seg_idx]["congestion"] = edge.congestion;
                segments[seg_idx]["congestion_label"] = tourism::graph::congestion_label(static_cast<double>(edge.congestion));
                segments[seg_idx]["congestion_color"] = tourism::graph::congestion_color(static_cast<double>(edge.congestion));
                seg_idx++;
            }
            data["congestion_segments"] = std::move(segments);

            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    // Get simulated congestion data for display
    CROW_ROUTE(app, "/api/v1/routes/congestion").methods("GET"_method)([](const crow::request& req) -> crow::response {
        try {
            int hour = query_int(req, "hour", 12, 0, 23);
            std::string transport = req.url_params.get("mode") ? std::string(req.url_params.get("mode")) : "walk";

            PgConnection db;
            auto graph = load_route_graph(db, 0);

            crow::json::wvalue data;
            crow::json::wvalue info;
            int idx = 0;

            for (const auto& [node_id, edges] : graph.edges) {
                for (const auto& e : edges) {
                    if (!transport.empty() && e.mode != transport) continue;
                    info[idx]["edge_id"] = e.id;
                    info[idx]["from"] = e.from;
                    info[idx]["to"] = e.to;
                    info[idx]["level"] = e.congestion;
                    info[idx]["label"] = tourism::graph::congestion_label(static_cast<double>(e.congestion));
                    info[idx]["color"] = tourism::graph::congestion_color(static_cast<double>(e.congestion));
                    idx++;
                    if (idx >= 100) break;
                }
                if (idx >= 100) break;
            }
            data["hour"] = hour;
            data["transport"] = transport;
            data["congestion"] = std::move(info);

            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
