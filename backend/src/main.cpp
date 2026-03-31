/**
 * @file main.cpp
 * @brief 个性化旅游系统后端主程序
 * @author yhm, zby, lxd
 * @version 1.0
 * @date 2026-03-31
 */

#include "crow.h"
#include <iostream>
#include <string>

// 包含控制器（待实现）
// #include "controllers/scenic_controller.h"
// #include "controllers/route_controller.h"
// #include "controllers/diary_controller.h"

/**
 * @brief 主函数
 * 
 * 启动 HTTP 服务器，注册路由，处理请求
 */
int main(int argc, char** argv) {
    // 配置
    int port = 8080;
    std::string host = "0.0.0.0";
    
    // 解析命令行参数
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--port" && i + 1 < argc) {
            port = std::stoi(argv[++i]);
        } else if (arg == "--host" && i + 1 < argc) {
            host = argv[++i];
        } else if (arg == "--help" || arg == "-h") {
            std::cout << "Usage: tourism_server [options]\n";
            std::cout << "Options:\n";
            std::cout << "  --port <port>    HTTP server port (default: 8080)\n";
            std::cout << "  --host <host>    HTTP server host (default: 0.0.0.0)\n";
            std::cout << "  --help, -h       Show this help message\n";
            return 0;
        }
    }
    
    // 创建 Crow 应用
    crow::SimpleApp app;
    
    // ============================================
    // 注册路由
    // ============================================
    
    // 健康检查
    CROW_ROUTE(app, "/health")
    ([]() {
        crow::json::wvalue response;
        response["status"] = "ok";
        response["message"] = "Personalized Tourism System is running";
        response["version"] = "1.0.0";
        return response;
    });
    
    // 首页
    CROW_ROUTE(app, "/")
    ([]() {
        crow::json::wvalue response;
        response["message"] = "Welcome to Personalized Tourism System API";
        response["version"] = "v1.0.0";
        response["endpoints"] = crow::json::wvalue::list({
            "/health",
            "/api/v1/scenic-spots",
            "/api/v1/recommendations",
            "/api/v1/routes",
            "/api/v1/diaries",
            "/api/v1/reviews"
        });
        return response;
    });
    
    // ============================================
    // API v1 路由（示例，实际实现需要连接数据库和算法）
    // ============================================
    
    // 景点列表
    CROW_ROUTE(app, "/api/v1/scenic-spots")
    ([](const crow::request& req) {
        auto params = crow::cpp::query_string(req.url_params);
        
        // 获取查询参数
        int page = params.get<int>("page", 1);
        int page_size = params.get<int>("page_size", 20);
        std::string sort = params.get<std::string>("sort", "rating");
        
        // TODO: 实际应从数据库查询
        crow::json::wvalue::list items;
        for (int i = 0; i < page_size; ++i) {
            crow::json::wvalue item;
            item["id"] = i + 1;
            item["name"] = "景点_" + std::to_string(i + 1);
            item["rating"] = 4.5 + (i % 5) * 0.1;
            items.push_back(std::move(item));
        }
        
        crow::json::wvalue response;
        response["code"] = 200;
        response["message"] = "success";
        response["data"]["total"] = 1000;
        response["data"]["page"] = page;
        response["data"]["page_size"] = page_size;
        response["data"]["items"] = std::move(items);
        
        return response;
    });
    
    // 路径规划
    CROW_ROUTE(app, "/api/v1/routes/plan")
    .methods("POST"_method)
    ([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        if (!body) {
            crow::json::wvalue error;
            error["code"] = 400;
            error["message"] = "Invalid JSON";
            return error;
        }
        
        // TODO: 实际应调用 Dijkstra 算法
        crow::json::wvalue response;
        response["code"] = 200;
        response["message"] = "success";
        response["data"]["route_id"] = "demo-route-uuid";
        response["data"]["total_distance_meters"] = 5000;
        response["data"]["total_duration_seconds"] = 3600;
        response["data"]["path"] = crow::json::wvalue::list({
            crow::json::wvalue{{"longitude", 116.397}, {"latitude", 39.916}},
            crow::json::wvalue{{"longitude", 116.400}, {"latitude", 39.920}}
        });
        
        return response;
    });
    
    // 推荐接口
    CROW_ROUTE(app, "/api/v1/recommendations/scenic-spots")
    ([](const crow::request& req) {
        auto params = crow::cpp::query_string(req.url_params);
        int limit = params.get<int>("limit", 10);
        
        // TODO: 实际应调用 Top-K 推荐算法
        crow::json::wvalue::list recommendations;
        for (int i = 0; i < limit; ++i) {
            crow::json::wvalue rec;
            rec["scenic_spot"]["id"] = i + 1;
            rec["scenic_spot"]["name"] = "推荐景点_" + std::to_string(i + 1);
            rec["score"] = 0.95 - i * 0.05;
            rec["reason"] = "基于您的偏好推荐";
            recommendations.push_back(std::move(rec));
        }
        
        crow::json::wvalue response;
        response["code"] = 200;
        response["data"]["recommendations"] = std::move(recommendations);
        
        return response;
    });
    
    // ============================================
    // 启动服务器
    // ============================================
    
    std::cout << "============================================\n";
    std::cout << "Personalized Tourism System Server\n";
    std::cout << "============================================\n";
    std::cout << "Host: " << host << "\n";
    std::cout << "Port: " << port << "\n";
    std::cout << "Version: 1.0.0\n";
    std::cout << "============================================\n";
    std::cout << "Starting server...\n";
    
    // 绑定并运行
    app.port(port).bindaddr(host).multithreaded().run();
    
    return 0;
}
