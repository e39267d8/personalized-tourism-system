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

TravelChatResponse chat_with_travel_agent(const TravelChatRequest& request);

} // namespace tourism::services
