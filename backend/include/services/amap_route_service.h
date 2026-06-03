#pragma once

#include "crow.h"

#include <string>
#include <vector>

namespace tourism::services {

std::string amap_key();

crow::json::wvalue plan_amap_route_json(const std::string& key,
                                        const std::string& city,
                                        const std::string& travel_mode,
                                        const std::vector<std::string>& place_texts);

} // namespace tourism::services
