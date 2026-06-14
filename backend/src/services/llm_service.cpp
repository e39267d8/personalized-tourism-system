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
    return env_value("TOURISM_LLM_MODEL", "DEEPSEEK_MODEL", "deepseek-chat");
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

std::string normalize_visual_style(std::string value) {
    value = trim_text(value);
    if (value == "watercolor" || value == "flat" || value == "ink" || value == "pixel") return value;
    return "anime";
}

std::string visual_style_label(const std::string& value) {
    if (value == "watercolor") return "水彩手绘";
    if (value == "flat") return "扁平插画";
    if (value == "ink") return "国风线稿";
    if (value == "pixel") return "像素风";
    return "日系动画";
}

std::string visual_style_prompt(const std::string& value) {
    if (value == "watercolor") return "soft watercolor 2D illustration, paper texture, gentle brush strokes";
    if (value == "flat") return "clean flat 2D vector illustration, simple shapes, crisp color blocks";
    if (value == "ink") return "Chinese ink line art, elegant 2D illustration, restrained colors";
    if (value == "pixel") return "pixel art travel comic, 2D sprite-like scene, limited color palette";
    return "anime-style 2D travel illustration, clean line art, cinematic lighting";
}

std::string normalize_panel_layout(std::string value) {
    value = trim_text(value);
    if (value == "single" || value == "two-panel" || value == "six-panel" || value == "vertical-comic") return value;
    return "four-panel";
}

int panel_count_for_layout(const std::string& value) {
    if (value == "single") return 1;
    if (value == "two-panel") return 2;
    if (value == "six-panel") return 6;
    if (value == "vertical-comic") return 5;
    return 4;
}

std::string panel_layout_label(const std::string& value) {
    if (value == "single") return "单幅主视觉";
    if (value == "two-panel") return "上下两格";
    if (value == "six-panel") return "六格漫画";
    if (value == "vertical-comic") return "竖版长图";
    return "四格漫画";
}

std::vector<std::pair<std::string, std::string>> fallback_panels(const std::string& title,
                                                                 const std::string& content,
                                                                 const std::string& layout) {
    std::string subject = trim_text(title);
    if (subject.empty()) subject = "这段旅行";
    std::string detail = trim_text(content);
    if (detail.size() > 80) detail = detail.substr(0, 80);
    if (detail.empty()) detail = "保留照片中的主要景点、人物和旅行氛围。";

    std::vector<std::pair<std::string, std::string>> seeds = {
        {"开场", "用远景交代目的地和天气，让画面像旅行故事的第一页。"},
        {"抵达", "突出人物或背影进入景点的瞬间，保留原图主体位置。"},
        {"高光", "放大最有记忆点的建筑、街景或自然景观，强化色彩和光影。"},
        {"细节", "加入票根、路牌、食物或随身物件等小元素，让日记更有生活感。"},
        {"转场", "用道路、门洞、楼梯或水面反射连接前后画面。"},
        {"收束", "用傍晚光线或回望视角结束，呈现完成旅行后的余韵。"}
    };

    int count = panel_count_for_layout(layout);
    std::vector<std::pair<std::string, std::string>> panels;
    panels.reserve(static_cast<size_t>(count));
    for (int index = 0; index < count; ++index) {
        auto item = seeds[static_cast<size_t>(index) % seeds.size()];
        item.second = subject + "：" + item.second + " 参考正文：" + detail;
        panels.push_back(std::move(item));
    }
    return panels;
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
    if (!request.local_context.empty()) {
        system << " TourPilot local database context follows. Prefer these spots, food options, ratings and prices when relevant, "
               << "but treat the list as incomplete and do not claim live availability: "
               << request.local_context;
    }

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

std::string summarize_diary_text(const std::string& title, const std::string& content) {
    try {
        TravelChatRequest req;
        req.style = "balanced";
        req.message = "请用一句话（不超过80字）概括以下旅游日记内容：\n标题：" + title + "\n内容：" + content.substr(0, std::min<size_t>(content.size(), 800));
        auto resp = chat_with_travel_agent(req);
        std::string summary = resp.reply;
        if (summary.size() > 100) summary = summary.substr(0, 100) + "...";
        return summary;
    } catch (const std::exception&) {
        // Fallback when LLM unavailable
        return content.empty() ? "这是一篇待完善的旅行记录。"
               : "摘要：" + content.substr(0, std::min<size_t>(content.size(), 90));
    }
}

std::string polish_diary_text(const std::string& content) {
    try {
        TravelChatRequest req;
        req.style = "balanced";
        req.message = "请把以下内容润色成可以直接发布的旅行日记成稿。保持第一人称和原意，语言自然、有画面感，控制在相似长度。只输出正式日记正文，不要出现提示词、解释、标题、摘要、系统建议或项目符号：\n" + content;
        auto resp = chat_with_travel_agent(req);
        return resp.reply.empty() ? content : resp.reply;
    } catch (const std::exception&) {
        return content;
    }
}

std::string generate_diary_title_text(const std::string& content) {
    std::string cleaned = trim_text(content);
    if (cleaned.empty()) return "";
    try {
        TravelChatRequest req;
        req.style = "balanced";
        req.message = "请根据下面的旅行日记正文生成一个适合直接发布的中文标题。要求：12到20个字，具体、有画面感，不要引号，不要解释，不要出现“标题：”。正文：\n" +
                      cleaned.substr(0, std::min<size_t>(cleaned.size(), 900));
        auto resp = chat_with_travel_agent(req);
        std::string title = trim_text(resp.reply);
        const std::vector<std::string> wrappers = {"标题：", "标题:", "《", "》", "“", "”", "\"", "'"};
        bool changed = true;
        while (changed && !title.empty()) {
            changed = false;
            for (const auto& token : wrappers) {
                if (title.rfind(token, 0) == 0) {
                    title = trim_text(title.substr(token.size()));
                    changed = true;
                }
                if (title.size() >= token.size() &&
                    title.compare(title.size() - token.size(), token.size(), token) == 0) {
                    title = trim_text(title.substr(0, title.size() - token.size()));
                    changed = true;
                }
            }
        }
        if (title.size() > 80) title = title.substr(0, 80);
        return title;
    } catch (const std::exception&) {
        std::string fallback = cleaned.substr(0, std::min<size_t>(cleaned.size(), 24));
        return fallback.empty() ? "" : fallback;
    }
}

ImagePromptResponse generate_image_prompt(const std::string& title, const std::string& content) {
    ImagePromptResponse result;
    try {
        TravelChatRequest req;
        req.style = "photo";
        req.message = "根据以下旅游日记为 Stable Diffusion 生成一个英文图片描述 prompt。"
                      "同时给出中文配图建议和适合的视觉风格、色调。"
                      "回复格式：\n英文prompt: ...\n中文建议: ...\n风格: ...\n色调: ...\n\n"
                      "日记标题：" + title + "\n日记内容：" + content.substr(0, std::min<size_t>(content.size(), 500));
        auto resp = chat_with_travel_agent(req);

        std::string reply = resp.reply;
        // Parse the structured response
        auto extract = [&](const std::string& key) -> std::string {
            size_t pos = reply.find(key);
            if (pos == std::string::npos) return "";
            pos += key.size();
            size_t end = reply.find('\n', pos);
            if (end == std::string::npos) end = reply.size();
            std::string val = reply.substr(pos, end - pos);
            // Trim
            size_t s = val.find_first_not_of(" \t\r\n");
            if (s == std::string::npos) return val;
            size_t e = val.find_last_not_of(" \t\r\n");
            return val.substr(s, e - s + 1);
        };

        result.prompt_en = extract("英文prompt:");
        if (result.prompt_en.empty()) result.prompt_en = extract("英文prompt：");
        result.prompt_cn = extract("中文建议:");
        if (result.prompt_cn.empty()) result.prompt_cn = extract("中文建议：");
        result.style = extract("风格:");
        if (result.style.empty()) result.style = extract("风格：");
        result.color_palette = extract("色调:");
        if (result.color_palette.empty()) result.color_palette = extract("色调：");

        // Fallback if parsing failed
        if (result.prompt_en.empty()) {
            result.prompt_en = "Beautiful travel scene, " + title + ", natural lighting, 4k, photorealistic";
            result.prompt_cn = "旅行风景图：" + title;
            result.style = "写实摄影";
            result.color_palette = "自然色调";
        }
    } catch (const std::exception&) {
        result.prompt_en = "Beautiful travel scene, " + title + ", natural lighting, 4k, photorealistic";
        result.prompt_cn = "旅行风景图：" + title;
        result.style = "写实摄影";
        result.color_palette = "自然色调";
    }
    return result;
}

ImagePromptResponse generate_image_prompt(const std::string& title, const std::string& content,
                                          const std::string& visual_style,
                                          const std::string& panel_layout,
                                          int image_count) {
    ImagePromptResponse result;
    result.mode = "3d_to_2d";
    result.visual_style = normalize_visual_style(visual_style);
    result.panel_layout = normalize_panel_layout(panel_layout);
    result.style = visual_style_label(result.visual_style);
    result.color_palette = "清爽旅行色调";
    result.panels = fallback_panels(title, content, result.panel_layout);
    result.negative_prompt =
        "photorealistic, 3D render, low quality, blurry, distorted landmarks, extra limbs, unreadable text, watermark, logo";

    const std::string style_prompt = visual_style_prompt(result.visual_style);
    const std::string layout_label = panel_layout_label(result.panel_layout);
    const int panel_count = panel_count_for_layout(result.panel_layout);
    std::string subject = trim_text(title);
    if (subject.empty()) subject = "travel diary";

    auto build_fallback_prompt = [&]() {
        std::ostringstream en;
        en << "Convert the uploaded 3D-rendered or photo-like travel images into a 2D "
           << layout_label << " storyboard, " << style_prompt
           << ", preserve the original landmarks, route mood, clothing silhouettes and composition, "
           << panel_count << " panels, diary title: " << subject
           << ", coherent visual narrative, clean details, no fake text";
        result.prompt_en = en.str();
        result.prompt_cn = "将已上传的旅行图片从 3D/写实观感转成" + result.style + "的" + layout_label +
                           "，保留真实景点、人物位置和日记氛围，按每格脚本组织画面。";
    };

    build_fallback_prompt();

    try {
        TravelChatRequest req;
        req.style = "photo";
        req.message =
            "你是旅行日记的视觉分镜助手。请把下面日记和已上传图片的语境，整理成“3D/写实图片转 2D 插画”的生成提示词。"
            "用户选择的二维风格是：" +
            result.style + "；分格布局是：" + layout_label + "，共 " + std::to_string(panel_count) +
            " 格。如果有上传图片，应强调保留原图里的景点、人物姿态、服装轮廓、构图和旅行氛围，只改变为 2D 插画/漫画表现。"
            "不要要求生成真实照片，不要改变景点身份。回复格式严格使用：\n"
            "英文prompt: ...\n中文建议: ...\n色调: ...\n"
            "分格1: 标题 - 画面说明\n分格2: 标题 - 画面说明\n反向提示词: ...\n\n"
            "日记标题：" +
            title + "\n图片数量：" + std::to_string(std::max(0, image_count)) +
            "\n日记内容：" + content.substr(0, std::min<size_t>(content.size(), 700));
        auto resp = chat_with_travel_agent(req);

        const std::string reply = resp.reply;
        auto extract = [&](const std::string& key) -> std::string {
            size_t pos = reply.find(key);
            if (pos == std::string::npos) return "";
            pos += key.size();
            size_t end = reply.find('\n', pos);
            if (end == std::string::npos) end = reply.size();
            return trim_text(reply.substr(pos, end - pos));
        };

        std::string prompt_en = extract("英文prompt:");
        if (!prompt_en.empty()) result.prompt_en = prompt_en;

        std::string prompt_cn = extract("中文建议:");
        if (!prompt_cn.empty()) result.prompt_cn = prompt_cn;

        std::string color_palette = extract("色调:");
        if (!color_palette.empty()) result.color_palette = color_palette;

        std::string negative_prompt = extract("反向提示词:");
        if (!negative_prompt.empty()) result.negative_prompt = negative_prompt;

        std::vector<std::pair<std::string, std::string>> parsed_panels;
        parsed_panels.reserve(static_cast<size_t>(panel_count));
        for (int index = 1; index <= panel_count; ++index) {
            std::string line = extract("分格" + std::to_string(index) + ":");
            if (line.empty()) line = extract("分格" + std::to_string(index) + "：");
            if (line.empty()) continue;
            std::string panel_title = "分格" + std::to_string(index);
            std::string panel_description = line;
            size_t split = line.find(" - ");
            size_t split_size = 3;
            if (split == std::string::npos) {
                split = line.find("：");
                split_size = 3;
            }
            if (split == std::string::npos) {
                split = line.find(":");
                split_size = 1;
            }
            if (split != std::string::npos) {
                panel_title = trim_text(line.substr(0, split));
                panel_description = trim_text(line.substr(split + split_size));
            }
            if (panel_title.empty()) panel_title = "分格" + std::to_string(index);
            if (panel_description.empty()) panel_description = line;
            parsed_panels.push_back({panel_title, panel_description});
        }
        if (static_cast<int>(parsed_panels.size()) == panel_count) {
            result.panels = std::move(parsed_panels);
        }
    } catch (const std::exception&) {
        build_fallback_prompt();
    }

    return result;
}

} // namespace tourism::services
