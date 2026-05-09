#include "services/amap_route_service.h"

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cstdlib>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#include <wininet.h>
#endif

namespace tourism::services {
namespace {

struct AmapPlace {
    std::string name;
    std::string address;
    std::string city;
    std::string location;
    double longitude = 0.0;
    double latitude = 0.0;
};

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

std::string trim_text(const std::string& value) {
    auto begin = std::find_if_not(value.begin(), value.end(), [](unsigned char ch) { return std::isspace(ch); });
    auto end = std::find_if_not(value.rbegin(), value.rend(), [](unsigned char ch) { return std::isspace(ch); }).base();
    if (begin >= end) return "";
    return std::string(begin, end);
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

std::string first_nonempty(std::initializer_list<std::string> values, const std::string& fallback = "") {
    for (const auto& value : values) {
        if (!value.empty()) return value;
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

} // namespace

std::string amap_key() {
    if (const char* value = std::getenv("AMAP_WEB_SERVICE_KEY")) {
        if (*value) return value;
    }
    if (const char* value = std::getenv("AMAP_KEY")) {
        if (*value) return value;
    }
    return "";
}

crow::json::wvalue plan_amap_route_json(const std::string& key,
                                        const std::string& city,
                                        const std::string& travel_mode,
                                        const std::vector<std::string>& place_texts) {
    AmapRoutePlan route = plan_amap_route(key, city, travel_mode, place_texts);
    return amap_route_json(route, travel_mode);
}

} // namespace tourism::services
