#include "crow.h"

#include <libpq-fe.h>

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

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

std::string scenic_fallback_image(int id) {
    static const std::vector<std::string> images = {
        "https://images.unsplash.com/photo-1624193367099-c65ec0976e7e?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1599571234909-29ed5d1321d6?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1566054757965-8c4085344c96?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1547981609-4b6bfe67ca0b?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1519608487953-e999c86e7455?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?auto=format&fit=crop&w=1200&q=80"
    };
    if (id >= 1 && id <= static_cast<int>(images.size())) return images[id - 1];
    return "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80";
}

std::string public_image_url(int id, const std::string& database_image) {
    if (database_image.empty() || database_image.find("example.com") != std::string::npos) {
        return scenic_fallback_image(id);
    }
    return split_pipe(database_image).empty() ? database_image : split_pipe(database_image).front();
}

crow::json::wvalue scenic_json(const PgResult& rows, int row) {
    std::string image = first_nonempty({rows.value(row, "thumbnail_url"), rows.value(row, "images")});
    int id = to_int(rows.value(row, "id"));

    crow::json::wvalue item;
    item["id"] = id;
    item["name"] = rows.value(row, "name");
    item["category"] = first_nonempty({rows.value(row, "category")}, "景点");
    item["district"] = first_nonempty({rows.value(row, "city"), rows.value(row, "address")}, "北京");
    item["rating"] = to_double(rows.value(row, "rating"));
    item["duration"] = duration_label(rows.value(row, "duration_minutes"));
    item["ticket"] = static_cast<int>(to_double(rows.value(row, "ticket_price")));
    item["crowd"] = crowd_label(to_int(rows.value(row, "crowd_level"), 2));
    item["tags"] = string_list(split_pipe(rows.value(row, "tags")));
    item["image"] = public_image_url(id, image);
    item["description"] = rows.value(row, "description");
    item["address"] = rows.value(row, "address");
    item["openingHours"] = rows.value(row, "opening_hours");
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
           COALESCE(array_to_string(s.images, '|'), '') AS images
    FROM scenic_spots s
    LEFT JOIN categories c ON c.id = s.category_id
    WHERE s.status = 1
      AND ($1 = '' OR c.name = $1)
      AND ($2 = '' OR lower(s.name || ' ' || COALESCE(s.description, '') || ' ' || COALESCE(c.name, '')) LIKE '%' || lower($2) || '%')
    ORDER BY s.rating DESC, s.view_count DESC, s.id
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
        PgConnection db;
        auto rows = exec_params(db, scenic_select_sql, {category, query});

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
            auto rows = exec_params(db, scenic_select_sql + " LIMIT " + std::to_string(limit), {"", ""});
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

    CROW_ROUTE(app, "/api/v1/routes/plan").methods("POST"_method)([](const crow::request&) -> crow::response {
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
                LIMIT 1
            )SQL");
            if (rows.rows() == 0) return json_error(404, "No route plan found");
            crow::json::wvalue data = route_json(rows, 0);
            data["route_id"] = "db-route-" + rows.value(0, "id");
            data["total_distance_meters"] = to_int(rows.value(0, "total_distance"));
            data["total_duration_seconds"] = to_int(rows.value(0, "total_duration"));
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
