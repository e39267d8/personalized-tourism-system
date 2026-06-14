#include "api/aigc_routes.h"

#include "db/postgres.h"
#include "services/llm_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <sstream>
#include <vector>

namespace tourism::api {
namespace {

using tourism::support::json_error;
using tourism::support::json_int;
using tourism::support::json_string;
using tourism::support::json_value_string;
using tourism::support::ok;
using tourism::support::trim_text;
using tourism::db::PgConnection;

std::string build_travel_agent_context(tourism::db::PgConnection& db, const std::string& destination) {
    std::string query = trim_text(destination);
    std::ostringstream context;

    auto spots = tourism::db::exec_params(db, R"SQL(
        SELECT s.name,
               COALESCE(c.name, '') AS category_name,
               COALESCE(s.city, '') AS city,
               COALESCE(s.rating, 0)::text AS rating,
               COALESCE(s.ticket_price, 0)::text AS ticket_price,
               COALESCE(s.duration_minutes, 0)::text AS duration_minutes,
               COALESCE(array_to_string(s.tags, '、'), '') AS tags
        FROM scenic_spots s
        LEFT JOIN categories c ON c.id = s.category_id
        WHERE s.status = 1
          AND (
              $1 = ''
              OR s.name ILIKE '%' || $1 || '%'
              OR COALESCE(s.city, '') ILIKE '%' || $1 || '%'
              OR COALESCE(s.address, '') ILIKE '%' || $1 || '%'
              OR COALESCE(array_to_string(s.tags, ' '), '') ILIKE '%' || $1 || '%'
          )
        ORDER BY COALESCE(s.rating, 0) DESC, COALESCE(s.view_count, 0) DESC, s.id
        LIMIT 8
    )SQL", {query});

    if (spots.rows() > 0) {
        context << "Candidate attractions/schools: ";
        for (int row = 0; row < spots.rows(); ++row) {
            if (row > 0) context << " | ";
            context << spots.value(row, "name");
            std::string category = spots.value(row, "category_name");
            std::string city = spots.value(row, "city");
            std::string rating = spots.value(row, "rating");
            std::string ticket = spots.value(row, "ticket_price");
            std::string duration = spots.value(row, "duration_minutes");
            std::string tags = spots.value(row, "tags");
            context << "(";
            bool added = false;
            auto add_part = [&](const std::string& part) {
                if (part.empty() || part == "0" || part == "0.00") return;
                if (added) context << ", ";
                context << part;
                added = true;
            };
            add_part(category);
            add_part(city);
            add_part("rating " + rating);
            add_part("ticket " + ticket + " CNY");
            add_part("suggested stay " + duration + " min");
            add_part(tags);
            context << ")";
        }
    }

    auto foods = tourism::db::exec_params(db, R"SQL(
        SELECT DISTINCT ON (f.id)
               f.name,
               f.type,
               COALESCE(f.rating, 0)::text AS rating,
               COALESCE(f.price_level, 0)::text AS price_level,
               COALESCE(f.source_tags->>'cuisine', '') AS cuisine,
               COALESCE(s.name, '') AS scenic_name,
               COALESCE(s.city, '') AS city
        FROM facilities f
        LEFT JOIN graph_nodes gn ON gn.facility_id = f.id
        LEFT JOIN scenic_spots s ON s.id = COALESCE(f.scenic_spot_id, gn.scenic_spot_id)
        WHERE f.location IS NOT NULL
          AND (f.type = 'restaurant' OR f.type = 'cafe' OR f.type = 'fast_food')
          AND (
              $1 = ''
              OR f.name ILIKE '%' || $1 || '%'
              OR COALESCE(f.address, '') ILIKE '%' || $1 || '%'
              OR COALESCE(f.source_tags->>'cuisine', '') ILIKE '%' || $1 || '%'
              OR COALESCE(s.name, '') ILIKE '%' || $1 || '%'
              OR COALESCE(s.city, '') ILIKE '%' || $1 || '%'
          )
        ORDER BY f.id, COALESCE(f.rating, 0) DESC, f.name
        LIMIT 6
    )SQL", {query});

    if (foods.rows() > 0) {
        if (!context.str().empty()) context << " ";
        context << "Food options: ";
        for (int row = 0; row < foods.rows(); ++row) {
            if (row > 0) context << " | ";
            context << foods.value(row, "name") << "(";
            bool added = false;
            auto add_part = [&](const std::string& part) {
                if (part.empty() || part == "0" || part == "0.00") return;
                if (added) context << ", ";
                context << part;
                added = true;
            };
            add_part(foods.value(row, "cuisine"));
            add_part(foods.value(row, "type"));
            add_part("rating " + foods.value(row, "rating"));
            add_part("price level " + foods.value(row, "price_level"));
            add_part("near " + foods.value(row, "scenic_name"));
            context << ")";
        }
    }

    std::string result = context.str();
    if (result.size() > 2400) result = result.substr(0, 2400);
    return result;
}

crow::json::wvalue::list travel_suggestions_json(const std::string& destination, const std::string& style) {
    std::string city = trim_text(destination);
    if (city.empty()) city = "目的地";

    std::vector<std::string> suggestions;
    if (style == "food") {
        suggestions = {
            "按餐饮和步行距离重新排一天路线",
            "帮我筛选适合晚餐的地点",
            "把预算控制在 800 元以内"
        };
    } else if (style == "photo") {
        suggestions = {
            "按日落和拍照点重新安排行程",
            "推荐少走回头路的拍照路线",
            "帮我避开人最多的时段"
        };
    } else if (style == "culture") {
        suggestions = {
            "帮我按博物馆和历史景点排顺序",
            "把每一站的看点讲得更具体",
            "推荐雨天也能执行的备选方案"
        };
    } else {
        suggestions = {
            "把这份计划改得更轻松",
            "按低预算重新安排",
            "推荐" + city + "适合雨天的备选方案"
        };
    }

    crow::json::wvalue::list items;
    for (const auto& suggestion : suggestions) items.push_back(suggestion);
    return items;
}

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
            try {
                PgConnection db;
                chat_request.local_context = build_travel_agent_context(db, destination);
            } catch (...) {
                chat_request.local_context.clear();
            }

            auto result = tourism::services::chat_with_travel_agent(chat_request);

            crow::json::wvalue data;
            data["reply"] = result.reply;
            data["provider"] = result.provider;
            data["model"] = result.model;
            data["suggestions"] = travel_suggestions_json(destination, style);
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

    CROW_ROUTE(app, "/api/v1/aigc/diary-title").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string content = json_string(body, "content", "");
        std::string title = tourism::services::generate_diary_title_text(content);
        crow::json::wvalue data;
        data["title"] = title;
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/aigc/image-prompt").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string title = json_string(body, "title", "");
        std::string content = json_string(body, "content", "");
        std::string visual_style = json_string(body, "visualStyle", "anime");
        std::string panel_layout = json_string(body, "panelLayout", "four-panel");
        int image_count = std::max(0, json_int(body, "imageCount", 0));

        auto result = tourism::services::generate_image_prompt(title, content, visual_style, panel_layout, image_count);

        crow::json::wvalue data;
        data["mode"] = result.mode;
        data["promptEn"] = result.prompt_en;
        data["promptCn"] = result.prompt_cn;
        data["style"] = result.style;
        data["visualStyle"] = result.visual_style;
        data["panelLayout"] = result.panel_layout;
        data["colorPalette"] = result.color_palette;
        data["negativePrompt"] = result.negative_prompt;

        crow::json::wvalue::list panels;
        for (const auto& panel : result.panels) {
            crow::json::wvalue item;
            item["title"] = panel.first;
            item["description"] = panel.second;
            panels.push_back(std::move(item));
        }
        data["panels"] = std::move(panels);
        return ok(std::move(data));
    });
}

} // namespace tourism::api
