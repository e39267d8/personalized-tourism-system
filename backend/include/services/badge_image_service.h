#pragma once

#include <string>

namespace tourism::services {

struct BadgeImageRequest {
    std::string collectible_name;
    std::string description;
    std::string achievement_name;
    std::string achievement_code;
    int tier = 1;
};

struct BadgeImageResult {
    std::string image_url;
    std::string prompt;
    std::string provider;
    std::string model;
    std::string task_id;
    std::string status;
    std::string error;
};

BadgeImageResult generate_badge_image(const BadgeImageRequest& request);

} // namespace tourism::services
