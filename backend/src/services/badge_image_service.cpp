#include "services/badge_image_service.h"

#include "crow.h"
#include "services/llm_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <chrono>
#include <cctype>
#include <cstdlib>
#include <ctime>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#include <bcrypt.h>
#include <wininet.h>
#endif

namespace tourism::services {
namespace {

using tourism::support::json_escape;
using tourism::support::json_value_string;
using tourism::support::trim_text;

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

std::string strip_trailing_slashes(std::string value) {
    while (!value.empty() && value.back() == '/') value.pop_back();
    return value;
}

std::string kling_access_key() {
    return env_value("KLING_ACCESS_KEY", "KLING_AK");
}

std::string kling_secret_key() {
    return env_value("KLING_SECRET_KEY", "KLING_SK");
}

std::string kling_generate_url() {
    return strip_trailing_slashes(env_value("KLING_IMAGE_GENERATE_URL", nullptr, "https://api-beijing.klingai.com/v1/images/generations"));
}

std::string kling_model() {
    return env_value("KLING_IMAGE_MODEL", nullptr, "kling-v1");
}

std::string base64_encode(const unsigned char* bytes, size_t length) {
    static constexpr char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string out;
    out.reserve(((length + 2) / 3) * 4);
    for (size_t i = 0; i < length; i += 3) {
        unsigned int value = bytes[i] << 16;
        if (i + 1 < length) value |= bytes[i + 1] << 8;
        if (i + 2 < length) value |= bytes[i + 2];
        out.push_back(table[(value >> 18) & 0x3f]);
        out.push_back(table[(value >> 12) & 0x3f]);
        out.push_back(i + 1 < length ? table[(value >> 6) & 0x3f] : '=');
        out.push_back(i + 2 < length ? table[value & 0x3f] : '=');
    }
    return out;
}

std::string base64url_encode(const std::string& text) {
    std::string out = base64_encode(reinterpret_cast<const unsigned char*>(text.data()), text.size());
    for (char& ch : out) {
        if (ch == '+') ch = '-';
        else if (ch == '/') ch = '_';
    }
    while (!out.empty() && out.back() == '=') out.pop_back();
    return out;
}

std::string base64url_encode(const std::vector<unsigned char>& bytes) {
    std::string out = base64_encode(bytes.data(), bytes.size());
    for (char& ch : out) {
        if (ch == '+') ch = '-';
        else if (ch == '/') ch = '_';
    }
    while (!out.empty() && out.back() == '=') out.pop_back();
    return out;
}

std::vector<unsigned char> hmac_sha256(const std::string& key, const std::string& data) {
#ifdef _WIN32
    BCRYPT_ALG_HANDLE algorithm = nullptr;
    BCRYPT_HASH_HANDLE hash = nullptr;
    DWORD object_length = 0;
    DWORD hash_length = 0;
    DWORD bytes_written = 0;

    auto cleanup = [&]() {
        if (hash) BCryptDestroyHash(hash);
        if (algorithm) BCryptCloseAlgorithmProvider(algorithm, 0);
    };

    if (BCryptOpenAlgorithmProvider(&algorithm, BCRYPT_SHA256_ALGORITHM, nullptr, BCRYPT_ALG_HANDLE_HMAC_FLAG) < 0) {
        throw std::runtime_error("Cannot open HMAC SHA256 provider");
    }
    if (BCryptGetProperty(algorithm, BCRYPT_OBJECT_LENGTH, reinterpret_cast<PUCHAR>(&object_length), sizeof(object_length), &bytes_written, 0) < 0 ||
        BCryptGetProperty(algorithm, BCRYPT_HASH_LENGTH, reinterpret_cast<PUCHAR>(&hash_length), sizeof(hash_length), &bytes_written, 0) < 0) {
        cleanup();
        throw std::runtime_error("Cannot read HMAC SHA256 properties");
    }

    std::vector<unsigned char> object(object_length);
    std::vector<unsigned char> digest(hash_length);
    if (BCryptCreateHash(algorithm, &hash, object.data(), object_length,
                         reinterpret_cast<PUCHAR>(const_cast<char*>(key.data())),
                         static_cast<ULONG>(key.size()), 0) < 0 ||
        BCryptHashData(hash, reinterpret_cast<PUCHAR>(const_cast<char*>(data.data())), static_cast<ULONG>(data.size()), 0) < 0 ||
        BCryptFinishHash(hash, digest.data(), static_cast<ULONG>(digest.size()), 0) < 0) {
        cleanup();
        throw std::runtime_error("Cannot sign Kling JWT");
    }
    cleanup();
    return digest;
#else
    (void)key;
    (void)data;
    throw std::runtime_error("Kling JWT signing is only implemented for Windows");
#endif
}

std::string kling_jwt(const std::string& access_key, const std::string& secret_key) {
    const long long now = static_cast<long long>(std::time(nullptr));
    const std::string header = R"({"alg":"HS256","typ":"JWT"})";
    std::ostringstream payload;
    payload << "{\"iss\":\"" << json_escape(access_key) << "\",\"exp\":" << (now + 1800) << ",\"nbf\":" << (now - 5) << "}";
    const std::string unsigned_token = base64url_encode(header) + "." + base64url_encode(payload.str());
    return unsigned_token + "." + base64url_encode(hmac_sha256(secret_key, unsigned_token));
}

std::string http_request_text(const std::string& method,
                              const std::string& url,
                              const std::string& body,
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
        throw std::runtime_error("Invalid Kling API URL");
    }

    std::string host_name(parts.lpszHostName, parts.dwHostNameLength);
    std::string target(parts.lpszUrlPath, parts.dwUrlPathLength);
    target += std::string(parts.lpszExtraInfo, parts.dwExtraInfoLength);
    if (target.empty()) target = "/";

    HINTERNET internet = InternetOpenA("TourPilot/1.0", INTERNET_OPEN_TYPE_PRECONFIG, nullptr, nullptr, 0);
    if (!internet) throw std::runtime_error("Cannot initialize Kling HTTP client");

    HINTERNET connection = InternetConnectA(internet, host_name.c_str(), parts.nPort, nullptr, nullptr,
                                            INTERNET_SERVICE_HTTP, 0, 0);
    if (!connection) {
        InternetCloseHandle(internet);
        throw std::runtime_error("Cannot connect to Kling API host");
    }

    DWORD flags = INTERNET_FLAG_RELOAD | INTERNET_FLAG_NO_CACHE_WRITE;
    if (parts.nScheme == INTERNET_SCHEME_HTTPS) flags |= INTERNET_FLAG_SECURE;

    HINTERNET request_handle = HttpOpenRequestA(connection, method.c_str(), target.c_str(), nullptr, nullptr, nullptr, flags, 0);
    if (!request_handle) {
        InternetCloseHandle(connection);
        InternetCloseHandle(internet);
        throw std::runtime_error("Cannot create Kling API request");
    }

    std::string header_text;
    for (const auto& header : headers) header_text += header.first + ": " + header.second + "\r\n";

    BOOL sent = HttpSendRequestA(request_handle, header_text.c_str(), static_cast<DWORD>(header_text.size()),
                                 body.empty() ? nullptr : const_cast<char*>(body.data()),
                                 static_cast<DWORD>(body.size()));
    if (!sent) {
        InternetCloseHandle(request_handle);
        InternetCloseHandle(connection);
        InternetCloseHandle(internet);
        throw std::runtime_error("Kling API request failed");
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
        throw std::runtime_error("Kling API returned HTTP " + std::to_string(status) + ": " + response_body.substr(0, 512));
    }
    return response_body;
#else
    (void)method;
    (void)url;
    (void)body;
    (void)headers;
    throw std::runtime_error("Kling HTTP client is only implemented for Windows");
#endif
}

std::string json_field(const crow::json::rvalue& value, const std::string& key) {
    try {
        if (value && value.has(key.c_str())) return json_value_string(value[key.c_str()]);
    } catch (...) {
    }
    return "";
}

std::string find_image_url(const crow::json::rvalue& value) {
    if (!value) return "";
    for (const auto& key : {"image_url", "imageUrl", "url", "result_url", "resultUrl"}) {
        std::string text = json_field(value, key);
        if (!text.empty()) return text;
    }
    try {
        if (value.has("images")) {
            for (const auto& image : value["images"]) {
                std::string found = find_image_url(image);
                if (!found.empty()) return found;
            }
        }
        if (value.has("task_result")) {
            std::string found = find_image_url(value["task_result"]);
            if (!found.empty()) return found;
        }
        if (value.has("result")) {
            std::string found = find_image_url(value["result"]);
            if (!found.empty()) return found;
        }
        if (value.has("data")) {
            std::string found = find_image_url(value["data"]);
            if (!found.empty()) return found;
        }
    } catch (...) {
    }
    return "";
}

std::string find_task_id(const crow::json::rvalue& value) {
    if (!value) return "";
    for (const auto& key : {"task_id", "taskId", "id"}) {
        std::string text = json_field(value, key);
        if (!text.empty()) return text;
    }
    try {
        if (value.has("data")) return find_task_id(value["data"]);
    } catch (...) {
    }
    return "";
}

std::string find_status(const crow::json::rvalue& value) {
    if (!value) return "";
    for (const auto& key : {"task_status", "taskStatus", "status"}) {
        std::string text = json_field(value, key);
        if (!text.empty()) return text;
    }
    try {
        if (value.has("data")) return find_status(value["data"]);
    } catch (...) {
    }
    return "";
}

std::string clean_prompt(std::string prompt) {
    prompt = trim_text(prompt);
    const std::vector<std::string> prefixes = {"English prompt:", "Prompt:", "prompt:", "英文prompt:", "英文 prompt:"};
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto& prefix : prefixes) {
            if (prompt.rfind(prefix, 0) == 0) {
                prompt = trim_text(prompt.substr(prefix.size()));
                changed = true;
            }
        }
    }
    while (!prompt.empty() && (prompt.front() == '"' || prompt.front() == '\'' || prompt.front() == '`')) prompt.erase(prompt.begin());
    while (!prompt.empty() && (prompt.back() == '"' || prompt.back() == '\'' || prompt.back() == '`')) prompt.pop_back();
    return trim_text(prompt);
}

std::string fallback_prompt(const BadgeImageRequest& request) {
    std::ostringstream prompt;
    prompt << "minimal premium collectible badge icon, simple line art, clean vector-like illustration, ";
    prompt << "round medal composition, inspired by " << request.achievement_name << " and " << request.collectible_name << ", ";
    prompt << "subtle scenic landmark features, elegant negative space, no text, no letters, no watermark, ";
    prompt << "Morandi palette with warm stone #c7b8a1, muted sage green, ivory background, high-end cultural travel souvenir design, 1:1";
    return prompt.str();
}

std::string llm_badge_prompt(const BadgeImageRequest& request) {
    try {
        TravelChatRequest chat;
        chat.style = "photo";
        chat.message =
            "请为可灵文生图生成一段中文 prompt，用来生成旅游平台的数字纪念徽章图。"
            "只输出中文 prompt，不要解释，不要标题。要求：线条简单、风格简约高级、有设计感、符合景点和成就特征，最重要的是景点特色鲜明，能看出是哪个景点；"
            "画面是 1:1 徽章/纪念章图标，可用于网页凭证墙；不要任何文字、字母、水印。"
            "色彩使用莫兰迪色系，主色参考 #c7b8a1，搭配低饱和色彩"
            "成就名称：" + request.achievement_name +
            "\n凭证名称：" + request.collectible_name +
            "\n成就描述：" + request.description +
            "\n成就层级：L" + std::to_string(request.tier);
        auto response = chat_with_travel_agent(chat);
        std::string prompt = clean_prompt(response.reply);
        if (!prompt.empty()) return prompt;
    } catch (...) {
    }
    return fallback_prompt(request);
}

std::string url_encode(const std::string& value) {
    std::ostringstream escaped;
    escaped << std::hex << std::uppercase;
    for (unsigned char ch : value) {
        if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') ||
            ch == '-' || ch == '_' || ch == '.' || ch == '~') {
            escaped << ch;
        } else {
            escaped << '%' << std::setw(2) << std::setfill('0') << static_cast<int>(ch);
        }
    }
    return escaped.str();
}

std::string fallback_svg_data_url(const BadgeImageRequest& request) {
    std::string label = request.achievement_code.empty() ? "TP" : request.achievement_code.substr(0, 2);
    std::transform(label.begin(), label.end(), label.begin(), [](unsigned char ch) { return static_cast<char>(std::toupper(ch)); });
    std::ostringstream svg;
    svg << "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 512 512'>"
        << "<rect width='512' height='512' rx='88' fill='#f6f1ea'/>"
        << "<circle cx='256' cy='256' r='178' fill='#c7b8a1' opacity='.36'/>"
        << "<circle cx='256' cy='256' r='132' fill='none' stroke='#657d72' stroke-width='14'/>"
        << "<path d='M162 292c42-68 84-102 126-102 36 0 64 24 88 72' fill='none' stroke='#657d72' stroke-width='16' stroke-linecap='round'/>"
        << "<path d='M185 315h142M210 342h92' fill='none' stroke='#9a7c66' stroke-width='12' stroke-linecap='round'/>"
        << "<circle cx='202' cy='196' r='12' fill='#9a7c66'/>"
        << "<text x='256' y='405' text-anchor='middle' font-family='Arial, sans-serif' font-size='34' font-weight='700' fill='#657d72'>"
        << label << "</text></svg>";
    return "data:image/svg+xml;charset=UTF-8," + url_encode(svg.str());
}

BadgeImageResult try_kling_image(const BadgeImageRequest& request, const std::string& prompt) {
    (void)request;
    BadgeImageResult result;
    result.prompt = prompt;
    result.provider = "kling";
    result.model = kling_model();

    const std::string access_key = kling_access_key();
    const std::string secret_key = kling_secret_key();
    if (access_key.empty() || secret_key.empty()) {
        throw std::runtime_error("KLING_ACCESS_KEY and KLING_SECRET_KEY are not configured");
    }

    const std::string token = kling_jwt(access_key, secret_key);
    const std::string body =
        "{\"model_name\":\"" + json_escape(result.model) + "\","
        "\"prompt\":\"" + json_escape(prompt) + "\","
        "\"negative_prompt\":\"text, letters, watermark, logo, noisy details, clutter, photorealistic portrait, low quality\","
        "\"aspect_ratio\":\"1:1\","
        "\"n\":1}";

    auto headers = std::vector<std::pair<std::string, std::string>>{
        {"Content-Type", "application/json"},
        {"Authorization", "Bearer " + token}
    };

    const std::string submit_body = http_request_text("POST", kling_generate_url(), body, headers);
    auto submit_json = crow::json::load(submit_body);
    if (!submit_json) throw std::runtime_error("Kling API returned invalid JSON");

    result.image_url = find_image_url(submit_json);
    result.task_id = find_task_id(submit_json);
    result.status = find_status(submit_json);
    if (!result.image_url.empty()) return result;
    if (result.task_id.empty()) throw std::runtime_error("Kling API returned no image URL or task id");

    const std::string poll_template = env_value("KLING_IMAGE_RESULT_URL");
    const int max_polls = std::max(1, std::min(12, std::atoi(env_value("KLING_IMAGE_POLL_COUNT", nullptr, "6").c_str())));
    const int delay_ms = std::max(500, std::min(5000, std::atoi(env_value("KLING_IMAGE_POLL_DELAY_MS", nullptr, "1800").c_str())));

    for (int i = 0; i < max_polls; ++i) {
        std::this_thread::sleep_for(std::chrono::milliseconds(delay_ms));
        std::string poll_url = poll_template.empty() ? (kling_generate_url() + "/" + result.task_id) : poll_template;
        const std::string placeholder = "{task_id}";
        auto pos = poll_url.find(placeholder);
        if (pos != std::string::npos) poll_url.replace(pos, placeholder.size(), result.task_id);

        const std::string poll_body = http_request_text("GET", poll_url, "", headers);
        auto poll_json = crow::json::load(poll_body);
        if (!poll_json) continue;
        result.status = find_status(poll_json);
        result.image_url = find_image_url(poll_json);
        if (!result.image_url.empty()) return result;
    }

    throw std::runtime_error("Kling image task is not ready yet");
}

} // namespace

BadgeImageResult generate_badge_image(const BadgeImageRequest& request) {
    const std::string prompt = llm_badge_prompt(request);
    try {
        auto result = try_kling_image(request, prompt);
        if (!result.image_url.empty()) return result;
    } catch (const std::exception& error) {
        BadgeImageResult fallback;
        fallback.image_url = fallback_svg_data_url(request);
        fallback.prompt = prompt;
        fallback.provider = "fallback-svg";
        fallback.model = "local-svg";
        fallback.status = "fallback";
        fallback.error = error.what();
        return fallback;
    }

    BadgeImageResult fallback;
    fallback.image_url = fallback_svg_data_url(request);
    fallback.prompt = prompt;
    fallback.provider = "fallback-svg";
    fallback.model = "local-svg";
    fallback.status = "fallback";
    return fallback;
}

} // namespace tourism::services
