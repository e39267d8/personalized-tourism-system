#include "support/api_helpers.h"

#include <algorithm>
#include <cctype>
#include <ctime>
#include <iomanip>
#include <sstream>

namespace tourism::support {

void JsonHeaders::before_handle(crow::request&, crow::response&, context&) {}

void JsonHeaders::after_handle(crow::request&, crow::response& res, context&) {
    auto content_type = res.get_header_value("Content-Type");
    if (content_type.empty() || content_type.find("application/json") != std::string::npos) {
        res.set_header("Content-Type", "application/json; charset=utf-8");
    }
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

std::string first_nonempty(std::initializer_list<std::string> values, const std::string& fallback) {
    for (const auto& value : values) {
        if (!value.empty()) return value;
    }
    return fallback;
}

int to_int(const std::string& value, int fallback) {
    try {
        if (!value.empty()) return std::stoi(value);
    } catch (...) {
    }
    return fallback;
}

int clamp_int(int value, int min_value, int max_value) {
    return std::max(min_value, std::min(max_value, value));
}

int query_int(const crow::request& req, const char* key, int fallback, int min_value, int max_value) {
    if (auto raw = req.url_params.get(key)) {
        return clamp_int(to_int(raw, fallback), min_value, max_value);
    }
    return fallback;
}

double to_double(const std::string& value, double fallback) {
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
    if (level <= 1) return "较低";
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
    localtime_r(&local, &now);
#endif
    std::ostringstream out;
    out << std::put_time(&local, "%Y-%m-%d");
    return out.str();
}

std::string json_string(const crow::json::rvalue& body, const std::string& key, const std::string& fallback) {
    if (!body || !body.has(key)) return fallback;
    try {
        return static_cast<std::string>(body[key].s());
    } catch (...) {
        return fallback;
    }
}

int json_int(const crow::json::rvalue& body, const std::string& key, int fallback) {
    if (!body || !body.has(key)) return fallback;
    try {
        return static_cast<int>(body[key].i());
    } catch (...) {
        return fallback;
    }
}

std::string json_value_string(const crow::json::rvalue& value, const std::string& fallback) {
    try {
        if (!value) return fallback;
        return static_cast<std::string>(value.s());
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

std::vector<std::string> json_tags(const crow::json::rvalue& body) {
    return json_string_array(body, "tags");
}

std::string json_escape(const std::string& value) {
    std::string escaped;
    escaped.reserve(value.size() + 8);
    for (char ch : value) {
        switch (ch) {
            case '"': escaped += "\\\""; break;
            case '\\': escaped += "\\\\"; break;
            case '\b': escaped += "\\b"; break;
            case '\f': escaped += "\\f"; break;
            case '\n': escaped += "\\n"; break;
            case '\r': escaped += "\\r"; break;
            case '\t': escaped += "\\t"; break;
            default: escaped += ch; break;
        }
    }
    return escaped;
}

std::string json_array_text(const std::vector<std::string>& values) {
    std::string result = "[";
    for (size_t i = 0; i < values.size(); ++i) {
        if (i) result += ",";
        result += "\"" + json_escape(values[i]) + "\"";
    }
    result += "]";
    return result;
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

} // namespace tourism::support
