#pragma once

#include "crow.h"
#include "support/api_helpers.h"

namespace tourism::api {

using TourismApp = crow::App<tourism::support::JsonHeaders>;

} // namespace tourism::api
