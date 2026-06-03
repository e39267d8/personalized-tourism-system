#pragma once

#include "crow.h"
#include "db/postgres.h"
#include "services/recommendation_service.h"

#include <string>

namespace tourism::services {

const std::string& scenic_select_sql();

crow::json::wvalue scenic_json(const tourism::db::PgResult& rows, int row);
crow::response list_scenic(const crow::request& req);
ScenicCandidate scenic_candidate_from_row(const tourism::db::PgResult& rows, int row);

} // namespace tourism::services
