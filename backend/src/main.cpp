#include "crow.h"

#include <libpq-fe.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <iostream>
#include <limits>
#include <queue>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#include <wininet.h>
#endif

namespace {

struct BudgetPlan {
    std::string id;
    std::string label;
    int budget;
    std::string title;
    std::string route;
    std::vector<std::string> includes;
    std::string tradeoff;
};

struct JsonHeaders {
    struct context {};

    void before_handle(crow::request&, crow::response&, context&) {}

    void after_handle(crow::request&, crow::response& res, context&) {
        auto content_type = res.get_header_value("Content-Type");
        if (content_type.empty() || content_type.find("application/json") != std::string::npos) {
            res.set_header("Content-Type", "application/json; charset=utf-8");
        }
    }
};

const std::vector<BudgetPlan> budget_plans = {
    {"lite", "轻预算", 80, "免费展览 + 城市漫步", "国家博物馆 -> 天安门广场 -> 前门大街",
     {"门票 0 元", "餐饮约 45 元", "交通约 12 元"}, "优先选择免费景点和步行路线，适合小型演示。"},
    {"balanced", "均衡型", 180, "中轴线完整体验", "前门 -> 天安门 -> 故宫 -> 景山",
     {"核心门票约 62 元", "餐饮约 80 元", "交通约 20 元"}, "体验完整，适合课程答辩和首次来北京用户。"},
    {"comfort", "舒适型", 360, "少排队 + 好餐厅 + 轻交通", "故宫 -> 景山 -> 王府井餐饮",
     {"预约优先", "餐饮约 180 元", "打车/骑行约 80 元"}, "成本更高，但减少转场压力。"}
};

std::string db_conninfo() {
    if (const char* env = std::getenv("TOURISM_DB_CONN")) {
        if (*env) return env;
    }
    return "host=127.0.0.1 port=5432 dbname=tourism_system user=postgres";
}

class PgConnection {
public:
    PgConnection() : conn_(PQconnectdb(db_conninfo().c_str())) {
        if (!conn_ || PQstatus(conn_) != CONNECTION_OK) {
            std::string message = conn_ ? PQerrorMessage(conn_) : "cannot allocate PostgreSQL connection";
            if (conn_) PQfinish(conn_);
            throw std::runtime_error(message);
        }
        PQsetClientEncoding(conn_, "UTF8");
    }

    ~PgConnection() {
        if (conn_) PQfinish(conn_);
    }

    PGconn* get() { return conn_; }

private:
    PGconn* conn_;
};

class PgResult {
public:
    explicit PgResult(PGresult* result) : result_(result) {}
    ~PgResult() {
        if (result_) PQclear(result_);
    }

    PgResult(const PgResult&) = delete;
    PgResult& operator=(const PgResult&) = delete;
    PgResult(PgResult&& other) noexcept : result_(other.result_) {
        other.result_ = nullptr;
    }
    PgResult& operator=(PgResult&& other) noexcept {
        if (this != &other) {
            if (result_) PQclear(result_);
            result_ = other.result_;
            other.result_ = nullptr;
        }
        return *this;
    }

    PGresult* get() { return result_; }
    int rows() const { return PQntuples(result_); }

    std::string value(int row, const char* column) const {
        int index = PQfnumber(result_, column);
        if (index < 0 || PQgetisnull(result_, row, index)) return "";
        return PQgetvalue(result_, row, index);
    }

private:
    PGresult* result_;
};

PgResult exec_params(PgConnection& db, const std::string& sql, const std::vector<std::string>& params,
                     ExecStatusType expected = PGRES_TUPLES_OK) {
    std::vector<const char*> values;
    values.reserve(params.size());
    for (const auto& param : params) values.push_back(param.c_str());

    PGresult* raw = PQexecParams(db.get(), sql.c_str(), static_cast<int>(values.size()), nullptr,
                                 values.data(), nullptr, nullptr, 0);
    PgResult result(raw);
    if (PQresultStatus(result.get()) != expected) {
        throw std::runtime_error(PQerrorMessage(db.get()));
    }
    return result;
}

PgResult exec_sql(PgConnection& db, const std::string& sql, ExecStatusType expected = PGRES_TUPLES_OK) {
    PGresult* raw = PQexec(db.get(), sql.c_str());
    PgResult result(raw);
    if (PQresultStatus(result.get()) != expected) {
        throw std::runtime_error(PQerrorMessage(db.get()));
    }
    return result;
}

crow::json::wvalue ok(crow::json::wvalue data) {
    crow::json::wvalue response;
    response["code"] = 200;
    response["message"] = "success";
    response["data"] = std::move(data);
    return response;
}

crow::response json_error(int status, const std::string& message) {
    crow::json::wvalue body;
    body["code"] = status;
    body["message"] = message;
    crow::response res(status, body);
    res.set_header("Content-Type", "application/json; charset=utf-8");
    return res;
}

std::vector<std::string> split_pipe(const std::string& value) {
    std::vector<std::string> parts;
    std::stringstream stream(value);
    std::string item;
    while (std::getline(stream, item, '|')) {
        if (!item.empty()) parts.push_back(item);
    }
    return parts;
}

std::string trim_text(const std::string& value) {
    auto begin = std::find_if_not(value.begin(), value.end(), [](unsigned char ch) { return std::isspace(ch); });
    auto end = std::find_if_not(value.rbegin(), value.rend(), [](unsigned char ch) { return std::isspace(ch); }).base();
    if (begin >= end) return "";
    return std::string(begin, end);
}

crow::json::wvalue string_list(const std::vector<std::string>& values) {
    crow::json::wvalue::list list;
    for (const auto& value : values) list.push_back(value);
    return crow::json::wvalue(std::move(list));
}

std::string first_nonempty(std::initializer_list<std::string> values, const std::string& fallback = "") {
    for (const auto& value : values) {
        if (!value.empty()) return value;
    }
    return fallback;
}

int to_int(const std::string& value, int fallback = 0) {
    try {
        if (!value.empty()) return std::stoi(value);
    } catch (...) {
    }
    return fallback;
}

double to_double(const std::string& value, double fallback = 0.0) {
    try {
        if (!value.empty()) return std::stod(value);
    } catch (...) {
    }
    return fallback;
}

std::string duration_label(const std::string& minutes_text) {
    int minutes = to_int(minutes_text);
    if (minutes <= 0) return "约 1 小时";
    if (minutes < 60) return std::to_string(minutes) + " 分钟";
    if (minutes % 60 == 0) return std::to_string(minutes / 60) + " 小时";
    std::ostringstream out;
    out << std::fixed << std::setprecision(1) << (minutes / 60.0) << " 小时";
    return out.str();
}

std::string crowd_label(int level) {
    if (level <= 1) return "低";
    if (level == 2) return "适中";
    if (level == 3) return "较高";
    return "拥挤";
}

std::string transport_label(const std::string& mode) {
    if (mode == "walk") return "步行";
    if (mode == "bike") return "骑行";
    if (mode == "subway") return "地铁";
    if (mode == "bus") return "公交";
    if (mode == "car") return "驾车";
    return "混合";
}

std::string today() {
    std::time_t now = std::time(nullptr);
    std::tm local{};
#ifdef _WIN32
    localtime_s(&local, &now);
#else
    localtime_r(&now, &local);
#endif
    std::ostringstream out;
    out << std::put_time(&local, "%Y-%m-%d");
    return out.str();
}

std::string json_string(const crow::json::rvalue& body, const std::string& key, const std::string& fallback = "") {
    if (!body || !body.has(key)) return fallback;
    try {
        return static_cast<std::string>(body[key].s());
    } catch (...) {
        return fallback;
    }
}

std::vector<std::string> json_tags(const crow::json::rvalue& body) {
    std::vector<std::string> tags;
    if (!body || !body.has("tags")) return tags;
    try {
        for (const auto& tag : body["tags"]) tags.push_back(static_cast<std::string>(tag.s()));
    } catch (...) {
    }
    return tags;
}

std::string pg_text_array(const std::vector<std::string>& values) {
    std::string result = "{";
    for (size_t i = 0; i < values.size(); ++i) {
        if (i) result += ",";
        result += "\"";
        for (char ch : values[i]) {
            if (ch == '"' || ch == '\\') result += '\\';
            result += ch;
        }
        result += "\"";
    }
    result += "}";
    return result;
}

std::string summary_from(const std::string& content) {
    if (content.size() <= 120) return content;
    return content.substr(0, 120);
}

double distance_number(const std::string& distance) {
    std::string numeric;
    for (char ch : distance) {
        if ((ch >= '0' && ch <= '9') || ch == '.') numeric += ch;
        else if (!numeric.empty()) break;
    }
    return to_double(numeric);
}

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

int json_int(const crow::json::rvalue& body, const std::string& key, int fallback = 0) {
    if (!body || !body.has(key)) return fallback;
    try {
        return static_cast<int>(body[key].i());
    } catch (...) {
        return fallback;
    }
}

std::vector<int> json_int_array(const crow::json::rvalue& body, const std::string& key) {
    std::vector<int> values;
    if (!body || !body.has(key)) return values;
    try {
        for (const auto& item : body[key]) {
            int value = static_cast<int>(item.i());
            if (value > 0) values.push_back(value);
        }
    } catch (...) {
    }
    return values;
}

std::string normalize_transport(const std::string& value) {
    if (value == "walk" || value == "步行") return "walk";
    if (value == "bike" || value == "骑行") return "bike";
    if (value == "subway" || value == "地铁") return "subway";
    if (value == "bus" || value == "公交") return "bus";
    if (value == "car" || value == "驾车") return "car";
    return "";
}

std::string normalize_optimization(const std::string& value) {
    if (value == "distance" || value == "距离优先") return "distance";
    if (value == "time" || value == "时间优先") return "time";
    if (value == "budget" || value == "预算优先") return "budget";
    return "balanced";
}

struct AmapPlace {
    std::string name;
    std::string address;
    std::string city;
    std::string location;
    double longitude = 0.0;
    double latitude = 0.0;
};

std::string amap_key() {
    if (const char* value = std::getenv("AMAP_WEB_SERVICE_KEY")) {
        if (*value) return value;
    }
    if (const char* value = std::getenv("AMAP_KEY")) {
        if (*value) return value;
    }
    return "";
}

std::string url_encode(const std::string& value) {
    static const char* hex = "0123456789ABCDEF";
    std::string output;
    for (unsigned char ch : value) {
        if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') ||
            (ch >= '0' && ch <= '9') || ch == '-' || ch == '_' || ch == '.' || ch == '~') {
            output.push_back(static_cast<char>(ch));
        } else {
            output.push_back('%');
            output.push_back(hex[ch >> 4]);
            output.push_back(hex[ch & 15]);
        }
    }
    return output;
}

std::string amap_url(const std::string& path, const std::vector<std::pair<std::string, std::string>>& params) {
    std::string url = "https://restapi.amap.com" + path + "?";
    for (size_t i = 0; i < params.size(); ++i) {
        if (i) url += "&";
        url += params[i].first + "=" + url_encode(params[i].second);
    }
    return url;
}

std::string http_get_text(const std::string& url) {
#ifdef _WIN32
    HINTERNET internet = InternetOpenA("TourPilot/1.0", INTERNET_OPEN_TYPE_PRECONFIG, nullptr, nullptr, 0);
    if (!internet) throw std::runtime_error("无法初始化 HTTP 客户端");

    HINTERNET request = InternetOpenUrlA(internet, url.c_str(), nullptr, 0,
                                        INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE | INTERNET_FLAG_SECURE,
                                        0);
    if (!request) {
        InternetCloseHandle(internet);
        throw std::runtime_error("无法请求高德 Web 服务");
    }

    std::string body;
    char buffer[4096];
    DWORD bytes_read = 0;
    while (InternetReadFile(request, buffer, sizeof(buffer), &bytes_read) && bytes_read > 0) {
        body.append(buffer, bytes_read);
    }

    InternetCloseHandle(request);
    InternetCloseHandle(internet);
    return body;
#else
    (void)url;
    throw std::runtime_error("当前后端未实现非 Windows HTTP 客户端");
#endif
}

std::string json_value_string(const crow::json::rvalue& value, const std::string& fallback = "") {
    try {
        if (!value) return fallback;
        return static_cast<std::string>(value.s());
    } catch (...) {
        return fallback;
    }
}

bool retryable_amap_error(const std::string& info) {
    return info.find("QPS") != std::string::npos ||
           info.find("RATE") != std::string::npos ||
           info.find("OVER") != std::string::npos ||
           info.find("LIMIT") != std::string::npos ||
           info.find("CUQPS") != std::string::npos;
}

crow::json::rvalue amap_request_json(const std::string& path, const std::vector<std::pair<std::string, std::string>>& params) {
    std::string last_error;
    for (int attempt = 0; attempt < 3; ++attempt) {
        if (attempt > 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(600 * attempt));
        } else {
            std::this_thread::sleep_for(std::chrono::milliseconds(180));
        }

        auto payload = crow::json::load(http_get_text(amap_url(path, params)));
        if (!payload) throw std::runtime_error("高德返回了无效 JSON");
        if (!payload.has("status") || json_value_string(payload["status"]) == "1") return payload;

        std::string info = payload.has("info") ? json_value_string(payload["info"], "高德请求失败") : "高德请求失败";
        std::string infocode = payload.has("infocode") ? json_value_string(payload["infocode"]) : "";
        last_error = infocode.empty() ? info : info + " (" + infocode + ")";
        if (!retryable_amap_error(info) && !retryable_amap_error(infocode)) break;
    }
    throw std::runtime_error(last_error.empty() ? "高德请求失败" : last_error);
}

bool parse_location(const std::string& location, double& longitude, double& latitude) {
    auto comma = location.find(',');
    if (comma == std::string::npos) return false;
    longitude = to_double(location.substr(0, comma));
    latitude = to_double(location.substr(comma + 1));
    return longitude != 0.0 && latitude != 0.0;
}

std::vector<std::string> json_string_array(const crow::json::rvalue& body, const std::string& key) {
    std::vector<std::string> values;
    if (!body || !body.has(key)) return values;
    try {
        for (const auto& item : body[key]) {
            std::string value = trim_text(static_cast<std::string>(item.s()));
            if (!value.empty()) values.push_back(value);
        }
    } catch (...) {
    }
    return values;
}

AmapPlace resolve_amap_place(const std::string& key, const std::string& text, const std::string& city) {
    std::string query = trim_text(text);
    if (query.empty()) throw std::runtime_error("地点不能为空");

    auto poi_payload = amap_request_json("/v3/place/text", {
        {"key", key},
        {"keywords", query},
        {"city", city},
        {"citylimit", city.empty() ? "false" : "true"},
        {"offset", "1"},
        {"page", "1"},
        {"extensions", "base"},
        {"output", "JSON"}
    });

    try {
        if (poi_payload.has("pois") && poi_payload["pois"].size() > 0) {
            const auto& poi = poi_payload["pois"][0];
            AmapPlace place;
            place.name = poi.has("name") ? json_value_string(poi["name"], query) : query;
            place.address = poi.has("address") ? json_value_string(poi["address"]) : "";
            place.city = poi.has("cityname") ? json_value_string(poi["cityname"], city) : city;
            place.location = poi.has("location") ? json_value_string(poi["location"]) : "";
            if (parse_location(place.location, place.longitude, place.latitude)) return place;
        }
    } catch (...) {
    }

    auto geocode_payload = amap_request_json("/v3/geocode/geo", {
        {"key", key},
        {"address", query},
        {"city", city},
        {"output", "JSON"}
    });

    if (!geocode_payload.has("geocodes") || geocode_payload["geocodes"].size() == 0) {
        throw std::runtime_error("无法识别地点：" + query);
    }
    const auto& geocode = geocode_payload["geocodes"][0];
    AmapPlace place;
    place.name = geocode.has("formatted_address") ? json_value_string(geocode["formatted_address"], query) : query;
    place.address = place.name;
    place.city = city;
    place.location = geocode.has("location") ? json_value_string(geocode["location"]) : "";
    if (!parse_location(place.location, place.longitude, place.latitude)) {
        throw std::runtime_error("地点没有可用坐标：" + query);
    }
    return place;
}

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

std::string transport_label(const std::string& mode);

RouteGraphData load_route_graph(PgConnection& db) {
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

RouteSearchResult dijkstra_route(const RouteGraphData& graph,
                                 int start,
                                 int end,
                                 const std::string& transport,
                                 const std::string& optimization,
                                 int crowd_tolerance) {
    RouteSearchResult result;
    if (!graph.nodes.count(start) || !graph.nodes.count(end)) {
        result.error = "起点或终点不存在";
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
    for (const auto& [id, node] : graph.nodes) dist[id] = inf;

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

std::vector<std::string> split_by_char(const std::string& value, char separator) {
    std::vector<std::string> parts;
    std::stringstream stream(value);
    std::string item;
    while (std::getline(stream, item, separator)) {
        if (!item.empty()) parts.push_back(item);
    }
    return parts;
}

void append_polyline_coordinates(const std::string& polyline, crow::json::wvalue::list& coordinates) {
    for (const auto& point_text : split_by_char(polyline, ';')) {
        double longitude = 0.0;
        double latitude = 0.0;
        if (!parse_location(point_text, longitude, latitude)) continue;
        crow::json::wvalue::list point;
        point.push_back(latitude);
        point.push_back(longitude);
        coordinates.push_back(crow::json::wvalue(std::move(point)));
    }
}

struct AmapRouteSegment {
    std::string instruction;
    std::string road;
    std::string transport;
    double distance = 0.0;
    int duration = 0;
    std::string polyline;
};

struct AmapRoutePlan {
    std::vector<AmapPlace> places;
    std::vector<AmapRouteSegment> segments;
    double total_distance = 0.0;
    int total_duration = 0;
};

std::string amap_direction_path(const std::string& travel_mode) {
    if (travel_mode == "driving" || travel_mode == "car") return "/v3/direction/driving";
    if (travel_mode == "bike") return "/v4/direction/bicycling";
    if (travel_mode == "transit" || travel_mode == "bus" || travel_mode == "subway") return "/v3/direction/transit/integrated";
    return "/v3/direction/walking";
}

std::string amap_direction_transport(const std::string& travel_mode) {
    if (travel_mode == "driving" || travel_mode == "car") return "驾车";
    if (travel_mode == "bike") return "骑行";
    if (travel_mode == "transit" || travel_mode == "bus" || travel_mode == "subway") return "地铁公交";
    return "步行";
}

crow::json::rvalue first_path_from_amap_payload(const crow::json::rvalue& payload) {
    if (payload.has("route") && payload["route"].has("paths") && payload["route"]["paths"].size() > 0) {
        return payload["route"]["paths"][0];
    }
    if (payload.has("data") && payload["data"].has("paths") && payload["data"]["paths"].size() > 0) {
        return payload["data"]["paths"][0];
    }
    throw std::runtime_error("高德没有返回可用路线");
}

crow::json::rvalue first_transit_from_amap_payload(const crow::json::rvalue& payload) {
    if (payload.has("route") && payload["route"].has("transits") && payload["route"]["transits"].size() > 0) {
        return payload["route"]["transits"][0];
    }
    throw std::runtime_error("高德没有返回可用公交/地铁路线");
}

std::string amap_json_string_field(const crow::json::rvalue& value, const std::string& key) {
    try {
        if (value.has(key)) return static_cast<std::string>(value[key]);
    } catch (...) {
    }
    return "";
}

void append_amap_steps(const crow::json::rvalue& path,
                       const std::string& transport,
                       AmapRoutePlan& plan) {
    std::vector<std::string> step_keys = {"steps", "rides"};
    for (const auto& key : step_keys) {
        if (!path.has(key)) continue;
        for (const auto& step : path[key]) {
            AmapRouteSegment segment;
            segment.instruction = step.has("instruction") ? json_value_string(step["instruction"]) : "";
            segment.road = step.has("road") ? json_value_string(step["road"]) : "";
            segment.transport = transport;
            segment.distance = step.has("distance") ? to_double(static_cast<std::string>(step["distance"])) : 0.0;
            segment.duration = step.has("duration") ? to_int(static_cast<std::string>(step["duration"])) : 0;
            segment.polyline = step.has("polyline") ? json_value_string(step["polyline"]) : "";
            if (!segment.instruction.empty() || !segment.polyline.empty()) {
                plan.segments.push_back(segment);
            }
        }
        return;
    }
}

void append_transit_walk_steps(const crow::json::rvalue& walking, AmapRoutePlan& plan) {
    try {
        if (!walking.has("steps")) return;
        for (const auto& step : walking["steps"]) {
            AmapRouteSegment segment;
            segment.instruction = step.has("instruction") ? json_value_string(step["instruction"]) : "步行";
            segment.road = step.has("road") ? json_value_string(step["road"]) : "";
            segment.transport = "步行";
            segment.distance = step.has("distance") ? to_double(static_cast<std::string>(step["distance"])) : 0.0;
            segment.duration = step.has("duration") ? to_int(static_cast<std::string>(step["duration"])) : 0;
            segment.polyline = step.has("polyline") ? json_value_string(step["polyline"]) : "";
            if (!segment.instruction.empty() || !segment.polyline.empty()) plan.segments.push_back(segment);
        }
    } catch (...) {
    }
}

void append_transit_buslines(const crow::json::rvalue& bus, AmapRoutePlan& plan) {
    try {
        if (!bus.has("buslines")) return;
        for (const auto& line : bus["buslines"]) {
            std::string line_name = line.has("name") ? json_value_string(line["name"]) : "公交/地铁";
            std::string departure = line.has("departure_stop") ? amap_json_string_field(line["departure_stop"], "name") : "";
            std::string arrival = line.has("arrival_stop") ? amap_json_string_field(line["arrival_stop"], "name") : "";

            AmapRouteSegment segment;
            segment.instruction = departure.empty() || arrival.empty()
                ? line_name
                : "乘坐 " + line_name + "，从 " + departure + " 到 " + arrival;
            segment.road = line_name;
            segment.transport = "地铁公交";
            segment.distance = line.has("distance") ? to_double(static_cast<std::string>(line["distance"])) : 0.0;
            segment.duration = line.has("duration") ? to_int(static_cast<std::string>(line["duration"])) : 0;
            segment.polyline = line.has("polyline") ? json_value_string(line["polyline"]) : "";
            plan.segments.push_back(segment);
        }
    } catch (...) {
    }
}

void append_transit_segments(const crow::json::rvalue& transit, AmapRoutePlan& plan) {
    try {
        if (!transit.has("segments")) return;
        for (const auto& segment : transit["segments"]) {
            if (segment.has("walking")) append_transit_walk_steps(segment["walking"], plan);
            if (segment.has("bus")) append_transit_buslines(segment["bus"], plan);
        }
    } catch (...) {
    }
}

AmapRoutePlan plan_amap_route(const std::string& key,
                              const std::string& city,
                              const std::string& travel_mode,
                              const std::vector<std::string>& place_texts) {
    if (place_texts.size() < 2) throw std::runtime_error("请选择起点和终点");

    AmapRoutePlan plan;
    for (size_t index = 0; index < place_texts.size(); ++index) {
        try {
            plan.places.push_back(resolve_amap_place(key, place_texts[index], city));
        } catch (const std::exception& error) {
            throw std::runtime_error("第 " + std::to_string(index + 1) + " 个地点「" + place_texts[index] + "」识别失败：" + error.what());
        }
    }

    std::string path = amap_direction_path(travel_mode);
    std::string transport = amap_direction_transport(travel_mode);
    for (size_t i = 0; i + 1 < plan.places.size(); ++i) {
        std::vector<std::pair<std::string, std::string>> params = {
            {"key", key},
            {"origin", plan.places[i].location},
            {"destination", plan.places[i + 1].location},
            {"output", "JSON"}
        };
        if (travel_mode == "transit" || travel_mode == "bus" || travel_mode == "subway") {
            params.push_back({"city", first_nonempty({plan.places[i].city, city}, "北京")});
            params.push_back({"cityd", first_nonempty({plan.places[i + 1].city, city}, "北京")});
            params.push_back({"strategy", travel_mode == "subway" ? "5" : "0"});
            params.push_back({"nightflag", "0"});
        }

        try {
            auto payload = amap_request_json(path, params);

            if (travel_mode == "transit" || travel_mode == "bus" || travel_mode == "subway") {
                auto transit = first_transit_from_amap_payload(payload);
                double distance = transit.has("distance") ? to_double(static_cast<std::string>(transit["distance"])) : 0.0;
                int duration = transit.has("duration") ? to_int(static_cast<std::string>(transit["duration"])) : 0;
                plan.total_distance += distance;
                plan.total_duration += duration;
                append_transit_segments(transit, plan);
                continue;
            }

            auto route_path = first_path_from_amap_payload(payload);
            double distance = route_path.has("distance") ? to_double(static_cast<std::string>(route_path["distance"])) : 0.0;
            int duration = route_path.has("duration") ? to_int(static_cast<std::string>(route_path["duration"])) : 0;
            plan.total_distance += distance;
            plan.total_duration += duration;
            append_amap_steps(route_path, transport, plan);
        } catch (const std::exception& error) {
            throw std::runtime_error(
                "第 " + std::to_string(i + 1) + " 段「" +
                plan.places[i].name + " → " + plan.places[i + 1].name +
                "」规划失败：" + error.what()
            );
        }
    }
    return plan;
}

crow::json::wvalue amap_route_json(const AmapRoutePlan& plan, const std::string& travel_mode) {
    crow::json::wvalue::list stops;
    crow::json::wvalue::list requested_places;
    for (const auto& place : plan.places) {
        stops.push_back(place.name);
        crow::json::wvalue item;
        item["name"] = place.name;
        item["address"] = place.address;
        item["city"] = place.city;
        item["longitude"] = place.longitude;
        item["latitude"] = place.latitude;
        requested_places.push_back(std::move(item));
    }

    crow::json::wvalue::list segments;
    crow::json::wvalue::list coordinates;
    for (const auto& segment : plan.segments) {
        crow::json::wvalue item;
        item["from"] = segment.instruction.empty() ? "按路线前进" : segment.instruction;
        item["to"] = segment.road;
        item["transport"] = segment.transport;
        item["transportMode"] = travel_mode;
        item["distance"] = segment.distance;
        item["duration"] = segment.duration;
        item["congestion"] = 0;
        segments.push_back(std::move(item));
        append_polyline_coordinates(segment.polyline, coordinates);
    }

    if (coordinates.empty()) {
        for (const auto& place : plan.places) {
            crow::json::wvalue::list point;
            point.push_back(place.latitude);
            point.push_back(place.longitude);
            coordinates.push_back(crow::json::wvalue(std::move(point)));
        }
    }

    std::ostringstream distance;
    distance << std::fixed << std::setprecision(1) << (plan.total_distance / 1000.0) << " km";

    crow::json::wvalue data;
    data["id"] = 0;
    data["route_id"] = "amap-route";
    data["title"] = plan.places.front().name + " 到 " + plan.places.back().name;
    data["stops"] = std::move(stops);
    data["requestedPlaces"] = std::move(requested_places);
    data["segments"] = std::move(segments);
    data["coordinates"] = std::move(coordinates);
    data["distance"] = distance.str();
    data["time"] = duration_label(std::to_string(plan.total_duration / 60));
    data["cost"] = travel_mode == "walk" ? 0 : std::max(3, static_cast<int>(plan.total_distance / 1000.0 * 2));
    data["intensity"] = plan.total_distance > 3500 ? "中等" : "轻松";
    data["transport"] = amap_direction_transport(travel_mode);
    data["bestFor"] = "高德路径规划";
    data["total_distance_meters"] = static_cast<int>(plan.total_distance);
    data["total_duration_seconds"] = plan.total_duration;
    data["usedAmap"] = true;
    data["usedTransportFallback"] = false;
    return data;
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

bool contains_any(const std::string& text, const std::vector<std::string>& needles) {
    for (const auto& needle : needles) {
        if (!needle.empty() && text.find(needle) != std::string::npos) return true;
    }
    return false;
}

bool unusable_image_url(const std::string& url) {
    return url.empty() ||
           url.find("example.com") != std::string::npos ||
           url.find("upload.wikimedia.org") != std::string::npos ||
           url.find("placeholder") != std::string::npos ||
           url.find("undefined") != std::string::npos ||
           url.find("null") != std::string::npos;
}

std::string scenic_fallback_image(const std::string& name, const std::string& category, const std::string& tags) {
    std::string profile = name + " " + category + " " + tags;

    if (contains_any(profile, {"博物馆", "展览", "纪念馆", "Museum"})) {
        return "https://images.unsplash.com/photo-1566127992631-137a642a90f4?auto=format&fit=crop&w=1200&q=80";
    }
    if (contains_any(profile, {"公园", "园林", "植物园", "湿地", "湖", "山", "Park"})) {
        return "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80";
    }
    if (contains_any(profile, {"古迹", "遗址", "寺", "庙", "宫", "长城", "历史", "Historic"})) {
        return "https://images.unsplash.com/photo-1513415756790-2ac1db1297d0?auto=format&fit=crop&w=1200&q=80";
    }
    if (contains_any(profile, {"商业", "步行街", "购物", "美食", "街区", "夜市"})) {
        return "https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=1200&q=80";
    }
    if (contains_any(profile, {"海", "沙滩", "海滩", "岛", "湾"})) {
        return "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80";
    }
    return "https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=1200&q=80";
}

std::string public_image_url(const std::string& database_image,
                             const std::string& name,
                             const std::string& category,
                             const std::string& tags) {
    auto parts = split_pipe(database_image);
    std::string candidate = parts.empty() ? database_image : parts.front();
    if (unusable_image_url(candidate)) {
        return scenic_fallback_image(name, category, tags);
    }
    return candidate;
}

crow::json::wvalue scenic_json(const PgResult& rows, int row) {
    std::string image = first_nonempty({rows.value(row, "thumbnail_url"), rows.value(row, "images")});
    int id = to_int(rows.value(row, "id"));
    std::string category = first_nonempty({rows.value(row, "category")}, "景点");
    std::string tags = rows.value(row, "tags");

    crow::json::wvalue item;
    item["id"] = id;
    item["name"] = rows.value(row, "name");
    item["category"] = category;
    item["district"] = first_nonempty({rows.value(row, "city"), rows.value(row, "address")}, "北京");
    item["rating"] = to_double(rows.value(row, "rating"));
    item["duration"] = duration_label(rows.value(row, "duration_minutes"));
    item["ticket"] = static_cast<int>(to_double(rows.value(row, "ticket_price")));
    item["crowd"] = crowd_label(to_int(rows.value(row, "crowd_level"), 2));
    item["tags"] = string_list(split_pipe(tags));
    item["image"] = public_image_url(image, rows.value(row, "name"), category, tags);
    item["description"] = rows.value(row, "description");
    item["address"] = rows.value(row, "address");
    item["openingHours"] = rows.value(row, "opening_hours");
    if (!rows.value(row, "search_score").empty()) item["score"] = to_double(rows.value(row, "search_score"));
    if (!rows.value(row, "match_reason").empty()) item["matchReason"] = rows.value(row, "match_reason");
    return item;
}

crow::json::wvalue diary_json(const PgResult& rows, int row) {
    std::string cover = first_nonempty({rows.value(row, "images")},
                                       "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80");

    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["title"] = rows.value(row, "title");
    item["date"] = first_nonempty({rows.value(row, "start_date")}, today());
    item["distance"] = first_nonempty({rows.value(row, "total_distance_km")}, "0") + " km";
    item["mood"] = "已记录";
    item["cover"] = cover;
    item["tags"] = string_list(split_pipe(rows.value(row, "tags")));
    item["excerpt"] = first_nonempty({rows.value(row, "summary"), rows.value(row, "content")});
    item["content"] = rows.value(row, "content");
    item["stats"]["views"] = to_int(rows.value(row, "view_count"));
    item["stats"]["likes"] = to_int(rows.value(row, "like_count"));
    item["stats"]["comments"] = to_int(rows.value(row, "comment_count"));
    return item;
}

crow::json::wvalue route_json(const PgResult& rows, int row) {
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
    item["intensity"] = meters > 3500 ? "中" : "低";
    item["transport"] = transport_label(rows.value(row, "travel_mode"));
    item["bestFor"] = rows.value(row, "optimization_type") + " 优先";
    item["coordinates"] = route_coordinates_json(rows.value(row, "coordinates"));
    return item;
}

crow::json::wvalue achievement_json(const PgResult& rows, int row) {
    std::string status = rows.value(row, "status");
    int progress = status == "unlocked" ? 100 : status == "in_progress" ? 60 : 20;

    crow::json::wvalue item;
    item["id"] = to_int(rows.value(row, "id"));
    item["name"] = rows.value(row, "name");
    item["level"] = "Lv." + first_nonempty({rows.value(row, "level")}, "1");
    item["progress"] = progress;
    item["status"] = status == "unlocked" ? "已解锁" : status == "in_progress" ? "进行中" : "未解锁";
    item["description"] = rows.value(row, "description");
    return item;
}

const std::string scenic_select_sql = R"SQL(
    SELECT s.id, s.name, s.description, s.rating, s.address, s.city, s.opening_hours,
           s.ticket_price, s.duration_minutes, s.crowd_level, s.thumbnail_url,
           COALESCE(c.name, '景点') AS category,
           COALESCE(array_to_string(s.tags, '|'), '') AS tags,
           COALESCE(array_to_string(s.images, '|'), '') AS images,
           (
               CASE WHEN $2 = '' THEN 0 WHEN lower(s.name) = lower($2) THEN 120 ELSE 0 END +
               CASE WHEN $2 = '' THEN 0 WHEN lower(s.name) LIKE lower($2) || '%' THEN 80 ELSE 0 END +
               CASE WHEN $2 = '' THEN 0 WHEN lower(s.name) LIKE '%' || lower($2) || '%' THEN 60 ELSE 0 END +
               CASE WHEN $2 = '' THEN 0 WHEN lower(COALESCE(c.name, '')) LIKE '%' || lower($2) || '%' THEN 42 ELSE 0 END +
               CASE WHEN $2 = '' THEN 0 WHEN lower(COALESCE(array_to_string(s.tags, ' '), '')) LIKE '%' || lower($2) || '%' THEN 48 ELSE 0 END +
               CASE WHEN $2 = '' THEN 0 WHEN lower(COALESCE(s.description, '')) LIKE '%' || lower($2) || '%' THEN 18 ELSE 0 END +
               (s.rating * 8) +
               LEAST(s.favorite_count, 10000) / 500.0 +
               LEAST(s.view_count, 100000) / 5000.0
           )::numeric(10,2) AS search_score,
           CASE
               WHEN $2 = '' THEN '综合评分和热度排序'
               WHEN lower(s.name) = lower($2) THEN '名称精确匹配'
               WHEN lower(s.name) LIKE lower($2) || '%' THEN '名称前缀匹配'
               WHEN lower(s.name) LIKE '%' || lower($2) || '%' THEN '名称包含关键词'
               WHEN lower(COALESCE(array_to_string(s.tags, ' '), '')) LIKE '%' || lower($2) || '%' THEN '标签匹配'
               WHEN lower(COALESCE(c.name, '')) LIKE '%' || lower($2) || '%' THEN '类型匹配'
               ELSE '描述内容匹配'
           END AS match_reason
    FROM scenic_spots s
    LEFT JOIN categories c ON c.id = s.category_id
    WHERE s.status = 1
      AND ($1 = '' OR c.name = $1)
      AND ($3 = '' OR s.ticket_price <= $3::numeric)
      AND (
          $2 = ''
          OR lower(s.name) LIKE '%' || lower($2) || '%'
          OR lower(COALESCE(c.name, '')) LIKE '%' || lower($2) || '%'
          OR lower(COALESCE(array_to_string(s.tags, ' '), '')) LIKE '%' || lower($2) || '%'
          OR (
              NOT EXISTS (
                  SELECT 1
                  FROM scenic_spots candidate
                  LEFT JOIN categories candidate_category ON candidate_category.id = candidate.category_id
                  WHERE candidate.status = 1
                    AND (
                        lower(candidate.name) LIKE '%' || lower($2) || '%'
                        OR lower(COALESCE(candidate_category.name, '')) LIKE '%' || lower($2) || '%'
                        OR lower(COALESCE(array_to_string(candidate.tags, ' '), '')) LIKE '%' || lower($2) || '%'
                    )
              )
              AND lower(COALESCE(s.description, '')) LIKE '%' || lower($2) || '%'
          )
      )
    ORDER BY
      CASE WHEN $4 = 'rating' THEN s.rating END DESC,
      CASE WHEN $4 = 'price' THEN s.ticket_price END ASC,
      CASE WHEN $4 = 'hot' THEN s.view_count END DESC,
      search_score DESC,
      s.rating DESC,
      s.view_count DESC,
      s.id
    LIMIT $5::int
)SQL";

const std::string diary_select_sql = R"SQL(
    SELECT id, title, summary, content, start_date::text, total_distance_km::text,
           COALESCE(array_to_string(images, '|'), '') AS images,
           COALESCE(array_to_string(tags, '|'), '') AS tags,
           view_count::text, like_count::text, comment_count::text
    FROM travel_diaries
    WHERE status <> 2
)SQL";

crow::response list_scenic(const crow::request& req) {
    try {
        std::string category = req.url_params.get("category") ? req.url_params.get("category") : "";
        std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
        std::string max_ticket = req.url_params.get("max_ticket") ? req.url_params.get("max_ticket") : "";
        std::string sort = req.url_params.get("sort") ? req.url_params.get("sort") : "relevance";
        std::string limit = req.url_params.get("limit") ? req.url_params.get("limit") : "50";
        PgConnection db;
        auto rows = exec_params(db, scenic_select_sql, {category, query, max_ticket, sort, limit});

        crow::json::wvalue::list items;
        for (int row = 0; row < rows.rows(); ++row) items.push_back(scenic_json(rows, row));

        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return crow::response(ok(std::move(data)));
    } catch (const std::exception& error) {
        return json_error(500, error.what());
    }
}

crow::json::wvalue budget_json(const BudgetPlan& plan) {
    crow::json::wvalue item;
    item["id"] = plan.id;
    item["label"] = plan.label;
    item["budget"] = plan.budget;
    item["title"] = plan.title;
    item["route"] = plan.route;
    item["includes"] = string_list(plan.includes);
    item["tradeoff"] = plan.tradeoff;
    return item;
}

} // namespace

int main(int argc, char** argv) {
    int port = 8080;
    std::string host = "0.0.0.0";

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--port" && i + 1 < argc) {
            port = std::stoi(argv[++i]);
        } else if (arg == "--host" && i + 1 < argc) {
            host = argv[++i];
        } else if (arg == "--help" || arg == "-h") {
            std::cout << "Usage: tourism_server [--host <host>] [--port <port>]\n";
            return 0;
        }
    }

    crow::App<JsonHeaders> app;

    CROW_ROUTE(app, "/health")([] {
        crow::json::wvalue data;
        data["status"] = "ok";
        data["message"] = "Personalized Tourism System API is running";
        data["version"] = "1.2.0";
        try {
            PgConnection db;
            exec_sql(db, "SELECT 1");
            data["database"] = "connected";
        } catch (const std::exception& error) {
            data["database"] = "error";
            data["databaseError"] = error.what();
        }
        return data;
    });

    CROW_ROUTE(app, "/")([] {
        crow::json::wvalue data;
        data["name"] = "Personalized Tourism System API";
        data["version"] = "1.2.0";
        data["database"] = "PostgreSQL/PostGIS";
        data["endpoints"] = string_list({
            "/api/v1/dashboard",
            "/api/v1/scenic-spots",
            "/api/v1/budget-plans",
            "/api/v1/routes",
            "/api/v1/diaries",
            "/api/v1/achievements",
            "/api/v1/profile"
        });
        return data;
    });

    CROW_ROUTE(app, "/api/v1/dashboard")([]() -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_sql(db, R"SQL(
                SELECT
                    (SELECT COUNT(*) FROM scenic_spots WHERE status = 1)::text AS scenic_count,
                    (SELECT COUNT(*) FROM graph_edges)::text AS edge_count,
                    (SELECT COUNT(*) FROM travel_diaries WHERE status <> 2)::text AS diary_count,
                    (SELECT COUNT(*) FROM achievements)::text AS achievement_count
            )SQL");

            crow::json::wvalue::list stats;
            stats.push_back(crow::json::wvalue{{"label", "数据库景点"}, {"value", rows.value(0, "scenic_count")}, {"detail", "来自 scenic_spots 表"}});
            stats.push_back(crow::json::wvalue{{"label", "路线边数"}, {"value", rows.value(0, "edge_count")}, {"detail", "来自 graph_edges 表"}});
            stats.push_back(crow::json::wvalue{{"label", "旅游日记"}, {"value", rows.value(0, "diary_count")}, {"detail", "支持数据库保存"}});
            stats.push_back(crow::json::wvalue{{"label", "成就徽章"}, {"value", rows.value(0, "achievement_count")}, {"detail", "来自 achievements 表"}});

            crow::json::wvalue data;
            data["stats"] = std::move(stats);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/profile")([]() -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_sql(db, R"SQL(
                SELECT u.id::text, u.username, COALESCE(u.nickname, u.username) AS nickname,
                       u.email, COALESCE(u.avatar_url, '') AS avatar_url,
                       (SELECT COUNT(*) FROM travel_diaries td WHERE td.user_id = u.id AND td.status <> 2)::text AS diary_count,
                       (SELECT COUNT(*) FROM user_achievements ua WHERE ua.user_id = u.id AND ua.status = 'unlocked')::text AS unlocked_count,
                       (SELECT COUNT(*) FROM user_favorites uf WHERE uf.user_id = u.id)::text AS favorite_count
                FROM users u
                WHERE u.id = 1
                LIMIT 1
            )SQL");

            if (rows.rows() == 0) return json_error(404, "Profile not found");

            crow::json::wvalue data;
            data["id"] = to_int(rows.value(0, "id"));
            data["username"] = rows.value(0, "username");
            data["nickname"] = rows.value(0, "nickname");
            data["email"] = rows.value(0, "email");
            data["avatarUrl"] = rows.value(0, "avatar_url");
            data["stats"]["diaries"] = to_int(rows.value(0, "diary_count"));
            data["stats"]["achievements"] = to_int(rows.value(0, "unlocked_count"));
            data["stats"]["favorites"] = to_int(rows.value(0, "favorite_count"));
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots")([](const crow::request& req) {
        return list_scenic(req);
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/search")([](const crow::request& req) {
        return list_scenic(req);
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

    CROW_ROUTE(app, "/api/v1/budget-plans")([](const crow::request& req) {
        int budget = 1000000;
        if (auto budget_param = req.url_params.get("budget")) budget = std::stoi(budget_param);

        crow::json::wvalue::list items;
        for (const auto& plan : budget_plans) {
            if (plan.budget <= budget) items.push_back(budget_json(plan));
        }
        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/recommendations/scenic-spots")([](const crow::request& req) -> crow::response {
        try {
            int limit = 10;
            if (auto limit_param = req.url_params.get("limit")) limit = std::stoi(limit_param);
            PgConnection db;
            auto rows = exec_params(db, scenic_select_sql, {"", "", "", "rating", std::to_string(limit)});
            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) {
                crow::json::wvalue rec;
                rec["scenic_spot"] = scenic_json(rows, row);
                rec["score"] = to_double(rows.value(row, "rating")) / 5.0;
                rec["reason"] = "数据库评分和标签匹配";
                items.push_back(std::move(rec));
            }
            crow::json::wvalue data;
            data["recommendations"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/route-nodes")([]() -> crow::response {
        try {
            PgConnection db;
            RouteGraphData graph = load_route_graph(db);

            std::vector<RouteNode> nodes;
            nodes.reserve(graph.nodes.size());
            for (const auto& [id, node] : graph.nodes) nodes.push_back(node);
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
                std::string key = amap_key();
                if (key.empty()) {
                    return json_error(500, "后端未设置 AMAP_WEB_SERVICE_KEY，无法使用高德路径规划");
                }

                std::vector<std::string> place_texts;
                place_texts.push_back(start_text);
                for (const auto& waypoint : waypoint_texts) place_texts.push_back(waypoint);
                place_texts.push_back(end_text);

                std::string amap_mode = raw_transport == "driving" || raw_transport == "car" ? "driving" :
                                        raw_transport == "bike" ? "bike" :
                                        raw_transport == "transit" || raw_transport == "bus" || raw_transport == "subway" ? raw_transport :
                                        "walk";
                AmapRoutePlan route = plan_amap_route(key, city, amap_mode, place_texts);
                return crow::response(ok(amap_route_json(route, amap_mode)));
            }

            if (start_node_id <= 0 || end_node_id <= 0) {
                return json_error(400, "请选择起点和终点");
            }

            PgConnection db;
            RouteGraphData graph = load_route_graph(db);

            std::vector<int> points;
            points.push_back(start_node_id);
            for (int waypoint : waypoints) {
                if (waypoint != start_node_id && waypoint != end_node_id) points.push_back(waypoint);
            }
            points.push_back(end_node_id);

            RouteSearchResult route = plan_route_with_waypoints(graph, points, transport, optimization, crowd_tolerance);
            if (!route.success) return json_error(404, route.error.empty() ? "无法规划路线" : route.error);

            crow::json::wvalue data = computed_route_json(graph, route, optimization, transport);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries")([](const crow::request& req) -> crow::response {
        try {
            std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
            PgConnection db;
            auto rows = exec_params(db, diary_select_sql + R"SQL(
                AND ($1 = '' OR lower(title || ' ' || COALESCE(summary, '') || ' ' || content) LIKE '%' || lower($1) || '%')
                ORDER BY created_at DESC, id DESC
            )SQL", {query});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(diary_json(rows, row));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/search")([](const crow::request& req) -> crow::response {
        try {
            std::string query = req.url_params.get("q") ? req.url_params.get("q") : "";
            PgConnection db;
            auto rows = exec_params(db, diary_select_sql + R"SQL(
                AND ($1 = '' OR lower(title || ' ' || COALESCE(summary, '') || ' ' || content) LIKE '%' || lower($1) || '%')
                ORDER BY created_at DESC, id DESC
            )SQL", {query});

            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(diary_json(rows, row));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>")([](int id) -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, diary_select_sql + " AND id = $1", {std::to_string(id)});
            if (rows.rows() == 0) return json_error(404, "Diary not found");
            return crow::response(ok(diary_json(rows, 0)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string title = first_nonempty({json_string(body, "title")}, "未命名日记");
            std::string content = first_nonempty({json_string(body, "excerpt"), json_string(body, "content")}, "");
            std::string date = first_nonempty({json_string(body, "date"), json_string(body, "start_date")}, today());
            std::string cover = first_nonempty({json_string(body, "cover")},
                                               "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80");
            std::string tags = pg_text_array(json_tags(body));
            std::string distance = std::to_string(distance_number(json_string(body, "distance", "0")));

            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                INSERT INTO travel_diaries
                    (user_id, title, summary, content, status, start_date, end_date, total_distance_km,
                     images, tags, view_count, like_count, comment_count)
                VALUES
                    (1, $1, $2, $3, 1, $4::date, $4::date, $5::numeric, ARRAY[$6]::text[], $7::text[], 0, 0, 0)
                RETURNING id, title, summary, content, start_date::text, total_distance_km::text,
                          COALESCE(array_to_string(images, '|'), '') AS images,
                          COALESCE(array_to_string(tags, '|'), '') AS tags,
                          view_count::text, like_count::text, comment_count::text
            )SQL", {title, summary_from(content), content, date, distance, cover, tags});

            return crow::response(201, ok(diary_json(rows, 0)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>").methods("PUT"_method)([](const crow::request& req, int id) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string title = first_nonempty({json_string(body, "title")}, "未命名日记");
            std::string content = first_nonempty({json_string(body, "excerpt"), json_string(body, "content")}, "");
            std::string date = first_nonempty({json_string(body, "date"), json_string(body, "start_date")}, today());
            std::string cover = first_nonempty({json_string(body, "cover")},
                                               "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80");
            std::string tags = pg_text_array(json_tags(body));
            std::string distance = std::to_string(distance_number(json_string(body, "distance", "0")));

            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                UPDATE travel_diaries
                SET title = $1, summary = $2, content = $3, start_date = $4::date, end_date = $4::date,
                    total_distance_km = $5::numeric, images = ARRAY[$6]::text[], tags = $7::text[],
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = $8 AND status <> 2
                RETURNING id, title, summary, content, start_date::text, total_distance_km::text,
                          COALESCE(array_to_string(images, '|'), '') AS images,
                          COALESCE(array_to_string(tags, '|'), '') AS tags,
                          view_count::text, like_count::text, comment_count::text
            )SQL", {title, summary_from(content), content, date, distance, cover, tags, std::to_string(id)});

            if (rows.rows() == 0) return json_error(404, "Diary not found");
            return crow::response(ok(diary_json(rows, 0)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>").methods("DELETE"_method)([](int id) -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_params(db, "DELETE FROM travel_diaries WHERE id = $1 RETURNING id", {std::to_string(id)});
            if (rows.rows() == 0) return json_error(404, "Diary not found");
            crow::json::wvalue data;
            data["deleted"] = true;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/achievements")([]() -> crow::response {
        try {
            PgConnection db;
            auto rows = exec_sql(db, R"SQL(
                SELECT a.id::text, a.name, a.description, a.level::text,
                       COALESCE(ua.status, 'locked') AS status
                FROM achievements a
                LEFT JOIN user_achievements ua ON ua.achievement_id = a.id AND ua.user_id = 1
                ORDER BY a.id
            )SQL");
            crow::json::wvalue::list items;
            for (int row = 0; row < rows.rows(); ++row) items.push_back(achievement_json(rows, row));

            crow::json::wvalue data;
            data["total"] = static_cast<int>(items.size());
            data["items"] = std::move(items);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/aigc/diary-summary").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string content = json_string(body, "content", "");
        crow::json::wvalue data;
        data["summary"] = content.empty() ? "这是一篇待完善的旅行记录。" : "自动摘要：" + content.substr(0, std::min<size_t>(content.size(), 90));
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/aigc/polish").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string content = json_string(body, "content", "");
        crow::json::wvalue data;
        data["polished"] = content + "\n\n系统建议：补充路线顺序、预算感受和最推荐的停留点，会让游记更适合分享。";
        return ok(std::move(data));
    });

    std::cout << "============================================\n";
    std::cout << "Personalized Tourism System API\n";
    std::cout << "Host: " << host << "\n";
    std::cout << "Port: " << port << "\n";
    std::cout << "Version: 1.2.0\n";
    std::cout << "Database: " << db_conninfo() << "\n";
    std::cout << "============================================\n";

    app.port(port).bindaddr(host).multithreaded().run();
    return 0;
}
