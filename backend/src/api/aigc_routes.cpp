#include "api/aigc_routes.h"

#include "services/llm_service.h"
#include "support/api_helpers.h"

#include <algorithm>

namespace tourism::api {
namespace {

using tourism::support::json_error;
using tourism::support::json_int;
using tourism::support::json_string;
using tourism::support::json_value_string;
using tourism::support::ok;
using tourism::support::trim_text;

std::vector<tourism::services::TravelChatMessage> travel_chat_messages_from_json(const crow::json::rvalue& body) {
    std::vector<tourism::services::TravelChatMessage> messages;
    if (!body || !body.has("messages")) return messages;

    try {
        for (const auto& item : body["messages"]) {
            if (messages.size() >= 10) break;
            std::string role = item.has("role") ? json_value_string(item["role"]) : "";
            std::string content = item.has("content") ? trim_text(json_value_string(item["content"])) : "";
            if (content.empty()) continue;
            if (role != "user" && role != "assistant") role = "user";
            messages.push_back({role, content});
        }
    } catch (...) {
    }
    return messages;
}

} // namespace

void register_aigc_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/aigc/diary-summary").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string title = json_string(body, "title", "");
        std::string content = json_string(body, "content", "");
        std::string summary = tourism::services::summarize_diary_text(title, content);
        crow::json::wvalue data;
        data["summary"] = summary;
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/aigc/travel-chat").methods("POST"_method)([](const crow::request& req) -> crow::response {
        auto body = crow::json::load(req.body);
        if (!body) return json_error(400, "Invalid JSON");

        std::string message = trim_text(json_string(body, "message", ""));
        if (message.empty()) return json_error(400, "message is required");

        std::string destination = trim_text(json_string(body, "destination", ""));
        std::string style = json_string(body, "style", "balanced");
        int days = std::max(1, std::min(14, json_int(body, "days", 3)));
        int budget = std::max(0, json_int(body, "budget", 1000));

        try {
            tourism::services::TravelChatRequest chat_request;
            chat_request.message = message;
            chat_request.destination = destination;
            chat_request.style = style;
            chat_request.days = days;
            chat_request.budget = budget;
            chat_request.messages = travel_chat_messages_from_json(body);

            auto result = tourism::services::chat_with_travel_agent(chat_request);

            crow::json::wvalue data;
            data["reply"] = result.reply;
            data["provider"] = result.provider;
            data["model"] = result.model;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            std::string message_text = error.what();
            int status = message_text.find("TOURISM_LLM_API_KEY") == std::string::npos ? 502 : 500;
            return json_error(status, message_text);
        }
    });

    CROW_ROUTE(app, "/api/v1/aigc/polish").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string content = json_string(body, "content", "");
        std::string polished = tourism::services::polish_diary_text(content);
        crow::json::wvalue data;
        data["polished"] = polished;
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/aigc/image-prompt").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string title = json_string(body, "title", "");
        std::string content = json_string(body, "content", "");

        auto result = tourism::services::generate_image_prompt(title, content);

        crow::json::wvalue data;
        data["promptEn"] = result.prompt_en;
        data["promptCn"] = result.prompt_cn;
        data["style"] = result.style;
        data["colorPalette"] = result.color_palette;
        return ok(std::move(data));
    });
}

} // namespace tourism::api
