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
};

TravelChatResponse chat_with_travel_agent(const TravelChatRequest& request);

// Generate a concise summary (≤80 chars) from diary content
std::string summarize_diary_text(const std::string& title, const std::string& content);

// Polish/improve travel diary content
std::string polish_diary_text(const std::string& content);

// Generate stable-diffusion-compatible image prompt from diary title + content
ImagePromptResponse generate_image_prompt(const std::string& title, const std::string& content);

} // namespace tourism::services
