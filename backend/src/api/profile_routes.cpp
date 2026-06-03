#include "api/profile_routes.h"

#include "db/postgres.h"
#include "services/auth_service.h"
#include "support/api_helpers.h"

#include <sstream>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::db::exec_sql;
using tourism::services::current_user;
using tourism::support::json_array_text;
using tourism::support::json_error;
using tourism::support::json_escape;
using tourism::support::json_string;
using tourism::support::json_string_array;
using tourism::support::ok;
using tourism::support::string_list;
using tourism::support::to_int;

crow::json::wvalue preference_payload_json(const crow::json::rvalue& body) {
    crow::json::wvalue data;
    data["preferredTags"] = string_list(json_string_array(body, "preferredTags"));
    data["preferredCategories"] = string_list(json_string_array(body, "preferredCategories"));
    data["budgetLevel"] = json_string(body, "budgetLevel", "medium");
    data["crowdPreference"] = json_string(body, "crowdPreference", "any");
    data["intensity"] = json_string(body, "intensity", "medium");
    return data;
}

std::string preference_payload_text(const crow::json::rvalue& body) {
    std::ostringstream out;
    out << "{";
    out << "\"preferredTags\":" << json_array_text(json_string_array(body, "preferredTags")) << ",";
    out << "\"preferredCategories\":" << json_array_text(json_string_array(body, "preferredCategories")) << ",";
    out << "\"budgetLevel\":\"" << json_escape(json_string(body, "budgetLevel", "medium")) << "\",";
    out << "\"crowdPreference\":\"" << json_escape(json_string(body, "crowdPreference", "any")) << "\",";
    out << "\"intensity\":\"" << json_escape(json_string(body, "intensity", "medium")) << "\"";
    out << "}";
    return out.str();
}

} // namespace

void register_profile_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/profile")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, R"SQL(
                SELECT u.id::text, u.username, COALESCE(u.nickname, u.username) AS nickname,
                       u.email, COALESCE(u.avatar_url, '') AS avatar_url,
                       (SELECT COUNT(*) FROM travel_diaries td WHERE td.user_id = u.id AND td.status <> 2)::text AS diary_count,
                       (SELECT COUNT(*) FROM user_achievements ua WHERE ua.user_id = u.id AND ua.status = 'unlocked')::text AS unlocked_count,
                       (SELECT COUNT(*) FROM user_favorites uf WHERE uf.user_id = u.id)::text AS favorite_count
                FROM users u
                WHERE u.id = $1
                LIMIT 1
            )SQL", {std::to_string(user->id)});

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

    CROW_ROUTE(app, "/api/v1/profile/preferences")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, R"SQL(
                SELECT COALESCE(preference_value::text, '{}') AS preference_value
                FROM user_preferences
                WHERE user_id = $1 AND preference_type = 'travel_profile'
                LIMIT 1
            )SQL", {std::to_string(user->id)});

            crow::json::wvalue data;
            data["exists"] = rows.rows() > 0;
            if (rows.rows() > 0) {
                auto parsed = crow::json::load(rows.value(0, "preference_value"));
                if (parsed) data["profile"] = preference_payload_json(parsed);
                else data["profile"] = crow::json::wvalue();
            } else {
                data["profile"] = crow::json::wvalue();
            }
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/profile/preferences").methods("PUT"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string preference_text = preference_payload_text(body);
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, R"SQL(
                INSERT INTO user_preferences (user_id, preference_type, preference_value, weight)
                VALUES ($2::bigint, 'travel_profile', $1::jsonb, 1.00)
                ON CONFLICT (user_id, preference_type) DO UPDATE SET
                    preference_value = EXCLUDED.preference_value,
                    weight = EXCLUDED.weight,
                    updated_at = CURRENT_TIMESTAMP
                RETURNING preference_value::text
            )SQL", {preference_text, std::to_string(user->id)});

            crow::json::wvalue data;
            data["saved"] = true;
            auto parsed = rows.rows() > 0 ? crow::json::load(rows.value(0, "preference_value")) : body;
            data["profile"] = parsed ? preference_payload_json(parsed) : preference_payload_json(body);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/profile/preferences").methods("DELETE"_method)([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            exec_params(db, "DELETE FROM user_preferences WHERE user_id = $1 AND preference_type = 'travel_profile'",
                        {std::to_string(user->id)}, PGRES_COMMAND_OK);
            crow::json::wvalue data;
            data["deleted"] = true;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
