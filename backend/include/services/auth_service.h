#pragma once

#include "crow.h"
#include "db/postgres.h"

#include <optional>
#include <string>

namespace tourism::services {

struct AuthUser {
    int id = 0;
    std::string username;
    std::string email;
    std::string nickname;
    std::string avatar_url;
};

std::string hash_password(const std::string& password);
bool verify_password(const std::string& password, const std::string& stored_hash);
std::string generate_token();
std::string bearer_token(const crow::request& req);

std::optional<AuthUser> current_user(tourism::db::PgConnection& db, const crow::request& req);
crow::json::wvalue auth_user_json(const AuthUser& user);

} // namespace tourism::services
