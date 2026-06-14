#pragma once

#include <string>
#include <vector>

namespace tourism::services {

struct TravelChatMessage {
    std::string role;
    std::string content;
};

struct TravelChatRequest {
    std::string message;
    std::string destination;
    std::string style = "balanced";
    std::string local_context;
    int days = 3;
    int budget = 1000;
    std::vector<TravelChatMessage> messages;
};

struct TravelChatResponse {
    std::string reply;
    std::string provider;
    std::string model;
};

struct ImagePromptResponse {
    std::string prompt_en;
    std::string prompt_cn;
    std::string style;
    std::string color_palette;
    std::string mode;
    std::string visual_style;
    std::string panel_layout;
    std::string negative_prompt;
    std::vector<std::pair<std::string, std::string>> panels;
};

TravelChatResponse chat_with_travel_agent(const TravelChatRequest& request);

// Generate a concise summary (≤80 chars) from diary content
std::string summarize_diary_text(const std::string& title, const std::string& content);

// Polish/improve travel diary content
std::string polish_diary_text(const std::string& content);

// Generate a publish-ready diary title from content
std::string generate_diary_title_text(const std::string& content);

// Generate a 3D/photo-to-2D prompt plan from diary title + content.
ImagePromptResponse generate_image_prompt(const std::string& title, const std::string& content,
                                          const std::string& visual_style = "anime",
                                          const std::string& panel_layout = "four-panel",
                                          int image_count = 0);

} // namespace tourism::services
