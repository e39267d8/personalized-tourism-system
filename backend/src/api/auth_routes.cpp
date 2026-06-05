#include "api/auth_routes.h"

#include "db/postgres.h"
#include "services/auth_service.h"
#include "support/api_helpers.h"

#include <algorithm>
#include <cctype>
#include <chrono>
#include <mutex>
#include <unordered_map>

namespace tourism::api {
namespace {

using tourism::db::PgConnection;
using tourism::db::exec_params;
using tourism::services::auth_user_json;
using tourism::services::bearer_token;
using tourism::services::current_user;
using tourism::services::generate_token;
using tourism::services::hash_password;
using tourism::services::verify_password;
using tourism::support::json_error;
using tourism::support::json_string;
using tourism::support::ok;
using tourism::support::to_int;
using tourism::support::trim_text;

constexpr int kMaxLoginFailures = 5;
constexpr auto kLoginFailureWindow = std::chrono::minutes(10);
constexpr auto kLoginBlockedDuration = std::chrono::minutes(1);

struct LoginAttempt {
    int failures = 0;
    std::chrono::steady_clock::time_point window_start = std::chrono::steady_clock::now();
    std::chrono::steady_clock::time_point blocked_until = {};
};

std::mutex login_attempt_mutex;
std::unordered_map<std::string, LoginAttempt> login_attempts;

bool valid_email(const std::string& email) {
    if (email.empty() || email.size() > 100 || email.find(' ') != std::string::npos) return false;
    auto at = email.find('@');
    auto dot = email.find('.', at == std::string::npos ? 0 : at);
    return at != std::string::npos && dot != std::string::npos && at > 0 && dot > at + 1;
}

bool valid_username(const std::string& username) {
    if (username.size() < 3 || username.size() > 50) return false;
    return std::all_of(username.begin(), username.end(), [](unsigned char ch) {
        return std::isalnum(ch) || ch == '_' || ch == '-';
    });
}

bool valid_password(const std::string& password) {
    return password.size() >= 8 && password.size() <= 128;
}

size_t utf8_length(const std::string& text) {
    size_t length = 0;
    for (unsigned char ch : text) {
        if ((ch & 0xc0) != 0x80) ++length;
    }
    return length;
}

std::string login_attempt_key(std::string identifier) {
    std::transform(identifier.begin(), identifier.end(), identifier.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return identifier;
}

bool login_is_blocked(const std::string& key) {
    std::lock_guard<std::mutex> lock(login_attempt_mutex);
    auto found = login_attempts.find(key);
    if (found == login_attempts.end()) return false;
    return std::chrono::steady_clock::now() < found->second.blocked_until;
}

void record_failed_login(const std::string& key) {
    std::lock_guard<std::mutex> lock(login_attempt_mutex);
    auto now = std::chrono::steady_clock::now();
    auto& attempt = login_attempts[key];
    if (now - attempt.window_start > kLoginFailureWindow) {
        attempt.failures = 0;
        attempt.window_start = now;
    }
    ++attempt.failures;
    if (attempt.failures >= kMaxLoginFailures) {
        attempt.blocked_until = now + kLoginBlockedDuration;
    }
}

void clear_login_attempts(const std::string& key) {
    std::lock_guard<std::mutex> lock(login_attempt_mutex);
    login_attempts.erase(key);
}

crow::json::wvalue auth_payload(int user_id, const std::string& token, crow::json::wvalue user) {
    crow::json::wvalue data;
    data["token"] = token;
    data["tokenType"] = "Bearer";
    data["expiresIn"] = 7 * 24 * 60 * 60;
    data["user"] = std::move(user);
    data["userId"] = user_id;
    return data;
}

std::string create_session(PgConnection& db, int user_id) {
    exec_params(db, R"SQL(
        DELETE FROM refresh_tokens
        WHERE user_id = $1::bigint
          AND (revoked = TRUE OR expires_at <= CURRENT_TIMESTAMP)
    )SQL", {std::to_string(user_id)}, PGRES_COMMAND_OK);

    std::string token = generate_token();
    exec_params(db, R"SQL(
        INSERT INTO refresh_tokens (user_id, token, expires_at, revoked)
        VALUES ($1::bigint, $2, CURRENT_TIMESTAMP + INTERVAL '7 days', FALSE)
    )SQL", {std::to_string(user_id), token}, PGRES_COMMAND_OK);
    return token;
}

} // namespace

void register_auth_routes(TourismApp& app) {
    CROW_ROUTE(app, "/api/v1/auth/register").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string username = trim_text(json_string(body, "username"));
            std::string email = trim_text(json_string(body, "email"));
            std::string password = json_string(body, "password");
            std::string nickname = trim_text(json_string(body, "nickname"));
            if (nickname.empty()) nickname = username;

            if (!valid_username(username)) return json_error(400, "用户名只能包含 3 到 50 位字母、数字、下划线或短横线");
            if (!valid_email(email)) return json_error(400, "请输入有效邮箱");
            if (!valid_password(password)) return json_error(400, "密码长度需要在 8 到 128 个字符之间");
            if (utf8_length(nickname) > 50) return json_error(400, "昵称最多 50 个字符");

            PgConnection db;
            auto existing = exec_params(db, R"SQL(
                SELECT id::text FROM users
                WHERE lower(username) = lower($1) OR lower(email) = lower($2)
                LIMIT 1
            )SQL", {username, email});
            if (existing.rows() > 0) return json_error(409, "用户名或邮箱已存在");

            auto rows = exec_params(db, R"SQL(
                INSERT INTO users (username, password_hash, email, nickname, status)
                VALUES ($1, $2, $3, $4, 1)
                RETURNING id::text, username, email, COALESCE(nickname, username) AS nickname,
                          COALESCE(avatar_url, '') AS avatar_url
            )SQL", {username, hash_password(password), email, nickname});

            int user_id = to_int(rows.value(0, "id"));
            std::string token = create_session(db, user_id);
            tourism::services::AuthUser user{user_id, rows.value(0, "username"), rows.value(0, "email"),
                                             rows.value(0, "nickname"), rows.value(0, "avatar_url")};
            return crow::response(201, ok(auth_payload(user_id, token, auth_user_json(user))));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/auth/login").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string identifier = trim_text(json_string(body, "identifier"));
            if (identifier.empty()) identifier = trim_text(json_string(body, "account"));
            if (identifier.empty()) identifier = trim_text(json_string(body, "username"));
            std::string password = json_string(body, "password");
            if (identifier.empty() || password.empty()) return json_error(400, "请输入账号和密码");
            if (identifier.size() > 100 || password.size() > 128) return json_error(401, "账号或密码错误");
            std::string attempt_key = login_attempt_key(identifier);
            if (login_is_blocked(attempt_key)) return json_error(429, "登录尝试过于频繁，请稍后再试");

            PgConnection db;
            auto rows = exec_params(db, R"SQL(
                SELECT id::text, username, password_hash, email,
                       COALESCE(nickname, username) AS nickname,
                       COALESCE(avatar_url, '') AS avatar_url,
                       status::text
                FROM users
                WHERE lower(username) = lower($1) OR lower(email) = lower($1)
                LIMIT 1
            )SQL", {identifier});

            bool legacy_demo_password = rows.rows() > 0 &&
                rows.value(0, "password_hash") == "demo_hash_not_for_production" &&
                password == "demo123456";
            bool password_ok = rows.rows() > 0 &&
                (verify_password(password, rows.value(0, "password_hash")) || legacy_demo_password);
            if (rows.rows() == 0 || rows.value(0, "status") != "1" || !password_ok) {
                record_failed_login(attempt_key);
                return json_error(401, "账号或密码错误");
            }

            int user_id = to_int(rows.value(0, "id"));
            clear_login_attempts(attempt_key);
            if (legacy_demo_password) {
                exec_params(db, "UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2",
                            {hash_password(password), std::to_string(user_id)}, PGRES_COMMAND_OK);
            }
            std::string token = create_session(db, user_id);
            exec_params(db, "UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1",
                        {std::to_string(user_id)}, PGRES_COMMAND_OK);
            tourism::services::AuthUser user{user_id, rows.value(0, "username"), rows.value(0, "email"),
                                             rows.value(0, "nickname"), rows.value(0, "avatar_url")};
            return crow::response(ok(auth_payload(user_id, token, auth_user_json(user))));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/auth/me")([](const crow::request& req) -> crow::response {
        try {
            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");
            crow::json::wvalue data;
            data["user"] = auth_user_json(*user);
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/auth/logout").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            std::string token = bearer_token(req);
            if (token.empty()) return json_error(401, "请先登录");
            PgConnection db;
            exec_params(db, "UPDATE refresh_tokens SET revoked = TRUE WHERE token = $1",
                        {token}, PGRES_COMMAND_OK);
            crow::json::wvalue data;
            data["loggedOut"] = true;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });

    CROW_ROUTE(app, "/api/v1/auth/change-password").methods("POST"_method)([](const crow::request& req) -> crow::response {
        try {
            auto body = crow::json::load(req.body);
            if (!body) return json_error(400, "Invalid JSON");

            std::string old_password = json_string(body, "oldPassword");
            std::string new_password = json_string(body, "newPassword");
            if (!valid_password(new_password)) return json_error(400, "新密码长度需要在 8 到 128 个字符之间");

            PgConnection db;
            auto user = current_user(db, req);
            if (!user) return json_error(401, "请先登录");

            auto rows = exec_params(db, "SELECT password_hash FROM users WHERE id = $1", {std::to_string(user->id)});
            if (rows.rows() == 0 || !verify_password(old_password, rows.value(0, "password_hash"))) {
                return json_error(401, "原密码错误");
            }

            exec_params(db, R"SQL(
                UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2
            )SQL", {hash_password(new_password), std::to_string(user->id)}, PGRES_COMMAND_OK);
            exec_params(db, R"SQL(
                UPDATE refresh_tokens SET revoked = TRUE WHERE user_id = $1 AND token <> $2
            )SQL", {std::to_string(user->id), bearer_token(req)}, PGRES_COMMAND_OK);

            crow::json::wvalue data;
            data["changed"] = true;
            return crow::response(ok(std::move(data)));
        } catch (const std::exception& error) {
            return json_error(500, error.what());
        }
    });
}

} // namespace tourism::api
