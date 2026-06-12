#include "api/aigc_routes.h"
#include "api/app.h"
#include "api/auth_routes.h"
#include "api/dashboard_routes.h"
#include "api/diary_animation_routes.h"
#include "api/diary_compression_routes.h"
#include "api/diary_routes.h"
#include "api/food_routes.h"
#include "api/huffman_routes.h"
#include "api/profile_routes.h"
#include "api/recommendation_routes.h"
#include "api/route_routes.h"
#include "api/scenic_routes.h"
#include "db/connection_pool.h"
#include "db/postgres.h"
#include "support/api_helpers.h"

#include <iostream>
#include <string>

int main(int argc, char** argv) {
    int port = 8080;
    std::string host = "0.0.0.0";

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--port" && i + 1 < argc) {
            port = tourism::support::clamp_int(tourism::support::to_int(argv[++i], port), 1, 65535);
        } else if (arg == "--host" && i + 1 < argc) {
            host = argv[++i];
        } else if (arg == "--help" || arg == "-h") {
            std::cout << "Usage: tourism_server [--host <host>] [--port <port>]\n";
            return 0;
        }
    }

    // 初始化连接池（池大小 = 20，匹配 Crow 线程数）
    try {
        tourism::db::ConnectionPool::instance().initialize(20);
    } catch (const std::exception& e) {
        std::cerr << "FATAL: Database connection pool init failed: " << e.what() << "\n";
        return 1;
    }

    tourism::api::TourismApp app;
    tourism::api::register_auth_routes(app);
    tourism::api::register_dashboard_routes(app);
    tourism::api::register_profile_routes(app);
    tourism::api::register_scenic_routes(app);
    tourism::api::register_recommendation_routes(app);
    tourism::api::register_route_routes(app);
    tourism::api::register_diary_routes(app);
    tourism::api::register_diary_animation_routes(app);
    tourism::api::register_diary_compression_routes(app);
    tourism::api::register_huffman_routes(app);
    tourism::api::register_aigc_routes(app);
    tourism::api::register_food_routes(app);

    std::cout << "============================================\n";
    std::cout << "Personalized Tourism System API\n";
    std::cout << "Host: " << host << "\n";
    std::cout << "Port: " << port << "\n";
    std::cout << "Version: 1.2.0\n";
    std::cout << "Pool: " << tourism::db::ConnectionPool::instance().available() << "/" << 20 << " connections\n";
    std::cout << "Database: " << tourism::db::db_conninfo() << "\n";
    std::cout << "============================================\n";

    app.port(port).bindaddr(host).multithreaded().run();
    return 0;
}
