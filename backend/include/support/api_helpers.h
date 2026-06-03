#pragma once

#include "crow.h"

#include <initializer_list>
#include <string>
#include <vector>

namespace tourism::support {

struct JsonHeaders {
    struct context {};

    void before_handle(crow::request&, crow::response&, context&);
    void after_handle(crow::request&, crow::response& res, context&);
};

crow::json::wvalue ok(crow::json::wvalue data);
crow::response json_error(int status, const std::string& message);

std::vector<std::string> split_pipe(const std::string& value);
std::string trim_text(const std::string& value);
crow::json::wvalue string_list(const std::vector<std::string>& values);
std::string first_nonempty(std::initializer_list<std::string> values, const std::string& fallback = "");

int to_int(const std::string& value, int fallback = 0);
int clamp_int(int value, int min_value, int max_value);
int query_int(const crow::request& req, const char* key, int fallback, int min_value, int max_value);
double to_double(const std::string& value, double fallback = 0.0);

std::string duration_label(const std::string& minutes_text);
std::string crowd_label(int level);
std::string transport_label(const std::string& mode);
std::string today();

std::string json_string(const crow::json::rvalue& body, const std::string& key, const std::string& fallback = "");
int json_int(const crow::json::rvalue& body, const std::string& key, int fallback = 0);
std::string json_value_string(const crow::json::rvalue& value, const std::string& fallback = "");
std::vector<int> json_int_array(const crow::json::rvalue& body, const std::string& key);
std::vector<std::string> json_string_array(const crow::json::rvalue& body, const std::string& key);
std::vector<std::string> json_tags(const crow::json::rvalue& body);

std::string json_escape(const std::string& value);
std::string json_array_text(const std::vector<std::string>& values);
std::string pg_text_array(const std::vector<std::string>& values);
std::string summary_from(const std::string& content);
double distance_number(const std::string& distance);

} // namespace tourism::support
