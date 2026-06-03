#pragma once

#include "crow.h"

namespace tourism::services {

crow::json::wvalue budget_plans_json(int budget);

} // namespace tourism::services
