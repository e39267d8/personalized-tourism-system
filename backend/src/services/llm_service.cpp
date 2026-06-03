#include "services/llm_service.h"

#include "crow.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#include <wininet.h>
#endif

namespace tourism::services {
namespace {

std::string env_value(const char* primary, const char* secondary = nullptr, const std::string& fallback = "") {
    if (const char* value = std::getenv(primary)) {
        if (*value) return value;
    }
    if (secondary) {
        if (const char* value = std::getenv(secondary)) {
            if (*value) return value;
        }
    }
    return fallback;
}

std::string llm_api_key() {
    return env_value("TOURISM_LLM_API_KEY", "DEEPSEEK_API_KEY");
}

std::string llm_base_url() {
    std::string value = env_value("TOURISM_LLM_BASE_URL", nullptr, "https://api.deepseek.com");
    while (!value.empty() && value.back() == '/') value.pop_back();
    return value;
}

std::string llm_model() {
    return env_value("TOURISM_LLM_MODEL", "DEEPSEEK_MODEL", "deepseek-v4-pro");
}

std::string trim_text(const std::string& value) {
    auto begin = std::find_if_not(value.begin(), value.end(), [](unsigned char ch) { return std::isspace(ch); });
    auto end = std::find_if_not(value.rbegin(), value.rend(), [](unsigned char ch) { return std::isspace(ch); }).base();
    if (begin >= end) return "";
    return std::string(begin, end);
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

std::string json_value_string(const crow::json::rvalue& value, const std::string& fallback = "") {
    try {
        if (!value) return fallback;
        return static_cast<std::string>(value.s());
    } catch (...) {
        return fallback;
    }
}

std::string json_object_string_field(const crow::json::rvalue& value, const std::string& key) {
    try {
        if (value.has(key)) return json_value_string(value[key]);
    } catch (...) {
    }
    return "";
}

std::string travel_style_label(const std::string& style) {
    if (style == "culture") return "history and culture";
    if (style == "food") return "food-first";
    if (style == "photo") return "photo spots";
    if (style == "relaxed") return "relaxed slow travel";
    return "balanced";
}

std::string http_post_json_text(const std::string& url, const std::string& body,
                                const std::vector<std::pair<std::string, std::string>>& headers) {
#ifdef _WIN32
    URL_COMPONENTSA parts{};
    char scheme[16]{};
    char host[256]{};
    char path[2048]{};
    char extra[2048]{};

    parts.dwStructSize = sizeof(parts);
    parts.lpszScheme = scheme;
    parts.dwSchemeLength = sizeof(scheme);
    parts.lpszHostName = host;
    parts.dwHostNameLength = sizeof(host);
    parts.lpszUrlPath = path;
    parts.dwUrlPathLength = sizeof(path);
    parts.lpszExtraInfo = extra;
    parts.dwExtraInfoLength = sizeof(extra);

    if (!InternetCrackUrlA(url.c_str(), 0, 0, &parts)) {
        throw std::runtime_error("Invalid LLM API URL");
    }

    std::string host_name(parts.lpszHostName, parts.dwHostNameLength);
    std::string target(parts.lpszUrlPath, parts.dwUrlPathLength);
    target += std::string(parts.lpszExtraInfo, parts.dwExtraInfoLength);
    if (target.empty()) target = "/";

    HINTERNET internet = InternetOpenA("TourPilot/1.0", INTERNET_OPEN_TYPE_PRECONFIG, nullptr, nullptr, 0);
    if (!internet) throw std::runtime_error("Cannot initialize HTTP client");

    HINTERNET connection = InternetConnectA(internet, host_name.c_str(), parts.nPort, nullptr, nullptr,
                                            INTERNET_SERVICE_HTTP, 0, 0);
    if (!connection) {
        InternetCloseHandle(internet);
        throw std::runtime_error("Cannot connect to LLM API host");
    }

    DWORD flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE;
    if (parts.nScheme == INTERNET_SCHEME_HTTPS) flags |= INTERNET_FLAG_SECURE;

    HINTERNET request_handle = HttpOpenRequestA(connection, "POST", target.c_str(), nullptr, nullptr, nullptr, flags, 0);
    if (!request_handle) {
        InternetCloseHandle(connection);
        InternetCloseHandle(internet);
        throw std::runtime_error("Cannot create LLM API request");
    }

    std::string header_text;
    for (const auto& header : headers) {
        header_text += header.first + ": " + header.second + "\r\n";
    }

    BOOL sent = HttpSendRequestA(request_handle, header_text.c_str(), static_cast<DWORD>(header_text.size()),
                                 const_cast<char*>(body.data()), static_cast<DWORD>(body.size()));
    if (!sent) {
        InternetCloseHandle(request_handle);
        InternetCloseHandle(connection);
        InternetCloseHandle(internet);
        throw std::runtime_error("LLM API request failed");
    }

    DWORD status = 0;
    DWORD status_size = sizeof(status);
    HttpQueryInfoA(request_handle, HTTP_QUERY_STATUS_CODE | HTTP_QUERY_FLAG_NUMBER, &status, &status_size, nullptr);

    std::string response_body;
    char buffer[4096];
    DWORD bytes_read = 0;
    while (InternetReadFile(request_handle, buffer, sizeof(buffer), &bytes_read) && bytes_read > 0) {
        response_body.append(buffer, bytes_read);
    }

    InternetCloseHandle(request_handle);
    InternetCloseHandle(connection);
    InternetCloseHandle(internet);

    if (status >= 400) {
        throw std::runtime_error("LLM API returned HTTP " + std::to_string(status) + ": " + response_body.substr(0, 512));
    }
    return response_body;
#else
    (void)url;
    (void)body;
    (void)headers;
    throw std::runtime_error("LLM HTTP client is only implemented for Windows");
#endif
}

std::string messages_json(const TravelChatRequest& request) {
    std::ostringstream out;
    bool added = false;
    int count = 0;

    for (const auto& item : request.messages) {
        if (count >= 10) break;
        std::string role = item.role == "assistant" ? "assistant" : "user";
        std::string content = trim_text(item.content);
        if (content.empty()) continue;
        if (added) out << ",";
        out << "{\"role\":\"" << json_escape(role) << "\",\"content\":\"" << json_escape(content) << "\"}";
        added = true;
        ++count;
    }

    if (!added && !request.message.empty()) {
        out << "{\"role\":\"user\",\"content\":\"" << json_escape(request.message) << "\"}";
    }

    return out.str();
}

std::string build_payload(const TravelChatRequest& request) {
    std::ostringstream system;
    system << "You are TourPilot, a professional travel planning assistant for a Chinese tourism website. ";
    system << "Reply in Simplified Chinese. Give practical, executable travel advice. ";
    system << "Prefer clear day-by-day or morning/afternoon/evening structure when planning. ";
    system << "Do not invent booking availability or prices as facts; mark uncertain details as suggestions. ";
    system << "Current trip context: destination=" << request.destination
           << ", days=" << request.days
           << ", budget=" << request.budget << " CNY"
           << ", style=" << travel_style_label(request.style) << ".";

    std::ostringstream payload;
    payload << "{";
    payload << "\"model\":\"" << json_escape(llm_model()) << "\",";
    payload << "\"temperature\":0.7,";
    payload << "\"stream\":false,";
    payload << "\"messages\":[";
    payload << "{\"role\":\"system\",\"content\":\"" << json_escape(system.str()) << "\"}";

    std::string message_payload = messages_json(request);
    if (!message_payload.empty()) payload << "," << message_payload;

    payload << "]}";
    return payload.str();
}

std::string extract_reply(const std::string& response_body) {
    auto payload = crow::json::load(response_body);
    if (!payload) throw std::runtime_error("LLM API returned invalid JSON");

    try {
        if (payload.has("choices")) {
            for (const auto& choice : payload["choices"]) {
                if (!choice.has("message")) continue;
                std::string content = json_object_string_field(choice["message"], "content");
                if (!content.empty()) return content;
            }
        }
    } catch (...) {
    }

    std::string message = payload.has("message") ? json_value_string(payload["message"]) : "";
    throw std::runtime_error(message.empty() ? "LLM API returned no reply" : message);
}

} // namespace

TravelChatResponse chat_with_travel_agent(const TravelChatRequest& request) {
    std::string api_key = llm_api_key();
    if (api_key.empty()) {
        throw std::runtime_error("TOURISM_LLM_API_KEY is not configured");
    }

    std::string model = llm_model();
    std::string payload = build_payload(request);
    std::string response_body = http_post_json_text(
        llm_base_url() + "/chat/completions",
        payload,
        {
            {"Content-Type", "application/json"},
            {"Authorization", "Bearer " + api_key}
        }
    );

    return {extract_reply(response_body), "deepseek", model};
}

} // namespace tourism::services
