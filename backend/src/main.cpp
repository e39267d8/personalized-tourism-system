#include "crow.h"

#include <algorithm>
#include <cctype>
#include <iostream>
#include <mutex>
#include <string>
#include <vector>

namespace {

struct ScenicSpot {
    int id;
    std::string name;
    std::string category;
    std::string district;
    double rating;
    std::string duration;
    int ticket;
    std::string crowd;
    std::vector<std::string> tags;
    std::string image;
    std::string description;
};

struct BudgetPlan {
    std::string id;
    std::string label;
    int budget;
    std::string title;
    std::string route;
    std::vector<std::string> includes;
    std::string tradeoff;
};

struct RoutePlan {
    int id;
    std::string title;
    std::vector<std::string> stops;
    std::string distance;
    std::string time;
    int cost;
    std::string intensity;
    std::string transport;
    std::string best_for;
};

struct Diary {
    int id;
    std::string title;
    std::string date;
    std::string distance;
    std::string mood;
    std::string cover;
    std::vector<std::string> tags;
    std::string excerpt;
    int views;
    int likes;
    int comments;
};

struct Achievement {
    int id;
    std::string name;
    std::string level;
    int progress;
    std::string status;
    std::string description;
};

std::mutex diary_mutex;

std::vector<ScenicSpot> scenic_spots = {
    {1, "故宫博物院", "历史古迹", "东城", 4.8, "4 小时", 60, "高", {"世界遗产", "中轴线", "亲子"},
     "https://images.unsplash.com/photo-1624193367099-c65ec0976e7e?auto=format&fit=crop&w=1200&q=80",
     "明清皇家宫殿建筑群，适合做历史文化路线的核心节点。"},
    {2, "天安门广场", "城市地标", "东城", 4.6, "1 小时", 0, "中", {"地标", "步行", "摄影"},
     "https://images.unsplash.com/photo-1599571234909-29ed5d1321d6?auto=format&fit=crop&w=1200&q=80",
     "北京中轴线上的开放式城市广场，可与故宫、前门串联。"},
    {3, "景山公园", "观景摄影", "西城", 4.55, "1.5 小时", 2, "低", {"日落", "俯瞰故宫", "轻徒步"},
     "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80",
     "登上万春亭可以俯瞰故宫和北京中轴线。"},
    {4, "国家博物馆", "博物馆", "东城", 4.7, "3 小时", 0, "中", {"室内", "展览", "低预算"},
     "https://images.unsplash.com/photo-1566054757965-8c4085344c96?auto=format&fit=crop&w=1200&q=80",
     "大型综合博物馆，适合文化主题推荐和雨天室内路线。"},
    {5, "前门大街", "商业街区", "东城", 4.3, "2 小时", 0, "中", {"美食", "夜游", "购物"},
     "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=1200&q=80",
     "传统商业街区，可作为餐饮和夜游节点。"},
    {6, "鼓楼与什刹海", "城市漫步", "西城", 4.4, "2.5 小时", 20, "低", {"胡同", "citywalk", "摄影"},
     "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?auto=format&fit=crop&w=1200&q=80",
     "老城地标与水岸街区，适合慢行和摄影。"}
};

std::vector<BudgetPlan> budget_plans = {
    {"lite", "轻预算", 80, "免费展览 + 城市漫步", "国家博物馆 -> 天安门广场 -> 前门大街",
     {"门票 0 元", "餐饮约 45 元", "交通约 12 元"}, "景点密度适中，主要靠步行和公共交通。"},
    {"balanced", "平衡型", 180, "中轴线完整体验", "前门 -> 天安门 -> 故宫 -> 景山",
     {"核心门票约 62 元", "餐饮约 80 元", "交通约 20 元"}, "体验完整，适合课程答辩和首次旅游用户。"},
    {"comfort", "舒适型", 360, "少排队 + 好餐厅 + 轻交通", "故宫 -> 景山 -> 王府井餐饮",
     {"预约优先级", "餐饮约 180 元", "打车/骑行约 80 元"}, "成本更高，但减少转场压力。"}
};

std::vector<RoutePlan> route_plans = {
    {1, "中轴线经典一日", {"前门大街", "天安门广场", "故宫博物院", "景山公园"}, "5.2 km", "7 小时", 92, "中", "步行 + 地铁", "初次来北京、历史文化"},
    {2, "低预算室内文化线", {"国家博物馆", "天安门东", "王府井"}, "2.1 km", "4 小时", 48, "低", "步行", "学生、雨天、轻松游"},
    {3, "鼓楼北海摄影线", {"鼓楼", "什刹海", "北海公园", "景山公园"}, "3.8 km", "5 小时", 52, "中", "步行 + 骑行", "摄影、citywalk、日落"}
};

std::vector<Diary> diaries = {
    {1, "中轴线一日游：从前门到景山", "2026-04-12", "5.2 km", "充实", scenic_spots[0].image,
     {"历史", "一日游", "中轴线"}, "上午从前门出发，经过天安门广场进入故宫，下午登上景山看完整条中轴线。", 430, 38, 6},
    {2, "博物馆和王府井的轻松半日", "2026-04-18", "2.1 km", "放松", scenic_spots[3].image,
     {"博物馆", "低预算", "夜游"}, "白天看展，傍晚去王府井吃饭购物，适合预算有限但想把体验做完整的路线。", 360, 31, 4},
    {3, "鼓楼到北海的 citywalk", "2026-04-26", "3.8 km", "治愈", scenic_spots[5].image,
     {"摄影", "citywalk", "公园"}, "从鼓楼出发，经什刹海到北海公园，最后到景山看日落，节奏很舒服。", 290, 24, 3}
};

std::vector<Achievement> achievements = {
    {1, "中轴线探索者", "Lv.1", 100, "已解锁", "完成包含前门、天安门、故宫、景山的路线。"},
    {2, "博物馆爱好者", "Lv.1", 75, "进行中", "收藏或评价 3 个博物馆类景点。"},
    {3, "城市漫步达人", "Lv.2", 60, "进行中", "完成一条 3 公里以上 citywalk 路线并发布游记。"},
    {4, "预算规划师", "Lv.2", 35, "未解锁", "连续 3 次生成预算内路线，并完成实际支出记录。"}
};

std::string lower_copy(std::string value) {
    std::transform(value.begin(), value.end(), value.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return value;
}

crow::json::wvalue ok(crow::json::wvalue data) {
    crow::json::wvalue response;
    response["code"] = 200;
    response["message"] = "success";
    response["data"] = std::move(data);
    return response;
}

crow::response json_error(int status, const std::string& message) {
    crow::json::wvalue body;
    body["code"] = status;
    body["message"] = message;
    crow::response res(status, body);
    res.set_header("Content-Type", "application/json");
    return res;
}

crow::json::wvalue string_list(const std::vector<std::string>& values) {
    crow::json::wvalue::list list;
    for (const auto& value : values) {
        list.push_back(value);
    }
    return crow::json::wvalue(std::move(list));
}

crow::json::wvalue scenic_json(const ScenicSpot& spot) {
    crow::json::wvalue item;
    item["id"] = spot.id;
    item["name"] = spot.name;
    item["category"] = spot.category;
    item["district"] = spot.district;
    item["rating"] = spot.rating;
    item["duration"] = spot.duration;
    item["ticket"] = spot.ticket;
    item["crowd"] = spot.crowd;
    item["tags"] = string_list(spot.tags);
    item["image"] = spot.image;
    item["description"] = spot.description;
    return item;
}

crow::json::wvalue budget_json(const BudgetPlan& plan) {
    crow::json::wvalue item;
    item["id"] = plan.id;
    item["label"] = plan.label;
    item["budget"] = plan.budget;
    item["title"] = plan.title;
    item["route"] = plan.route;
    item["includes"] = string_list(plan.includes);
    item["tradeoff"] = plan.tradeoff;
    return item;
}

crow::json::wvalue route_json(const RoutePlan& plan) {
    crow::json::wvalue item;
    item["id"] = plan.id;
    item["title"] = plan.title;
    item["stops"] = string_list(plan.stops);
    item["distance"] = plan.distance;
    item["time"] = plan.time;
    item["cost"] = plan.cost;
    item["intensity"] = plan.intensity;
    item["transport"] = plan.transport;
    item["bestFor"] = plan.best_for;
    return item;
}

crow::json::wvalue diary_json(const Diary& diary) {
    crow::json::wvalue item;
    item["id"] = diary.id;
    item["title"] = diary.title;
    item["date"] = diary.date;
    item["distance"] = diary.distance;
    item["mood"] = diary.mood;
    item["cover"] = diary.cover;
    item["tags"] = string_list(diary.tags);
    item["excerpt"] = diary.excerpt;
    item["stats"]["views"] = diary.views;
    item["stats"]["likes"] = diary.likes;
    item["stats"]["comments"] = diary.comments;
    return item;
}

crow::json::wvalue achievement_json(const Achievement& achievement) {
    crow::json::wvalue item;
    item["id"] = achievement.id;
    item["name"] = achievement.name;
    item["level"] = achievement.level;
    item["progress"] = achievement.progress;
    item["status"] = achievement.status;
    item["description"] = achievement.description;
    return item;
}

std::string json_string(const crow::json::rvalue& body, const std::string& key, const std::string& fallback = "") {
    if (!body || !body.has(key)) return fallback;
    try {
        return static_cast<std::string>(body[key].s());
    } catch (...) {
        return fallback;
    }
}

std::vector<std::string> json_tags(const crow::json::rvalue& body) {
    std::vector<std::string> tags;
    if (!body || !body.has("tags")) return tags;
    try {
        for (const auto& tag : body["tags"]) {
            tags.push_back(static_cast<std::string>(tag.s()));
        }
    } catch (...) {
    }
    return tags;
}

crow::json::wvalue list_scenic(const crow::request& req) {
    const char* category_param = req.url_params.get("category");
    const char* q_param = req.url_params.get("q");
    std::string category = category_param ? category_param : "";
    std::string q = q_param ? lower_copy(q_param) : "";

    crow::json::wvalue::list items;
    for (const auto& spot : scenic_spots) {
        if (!category.empty() && spot.category != category) continue;
        if (!q.empty()) {
            auto haystack = lower_copy(spot.name + " " + spot.category + " " + spot.description);
            if (haystack.find(q) == std::string::npos) continue;
        }
        items.push_back(scenic_json(spot));
    }

    crow::json::wvalue data;
    data["total"] = static_cast<int>(items.size());
    data["items"] = std::move(items);
    return ok(std::move(data));
}

} // namespace

int main(int argc, char** argv) {
    int port = 8080;
    std::string host = "0.0.0.0";

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--port" && i + 1 < argc) {
            port = std::stoi(argv[++i]);
        } else if (arg == "--host" && i + 1 < argc) {
            host = argv[++i];
        } else if (arg == "--help" || arg == "-h") {
            std::cout << "Usage: tourism_server [--host <host>] [--port <port>]\n";
            return 0;
        }
    }

    crow::SimpleApp app;

    CROW_ROUTE(app, "/health")([] {
        crow::json::wvalue data;
        data["status"] = "ok";
        data["message"] = "Personalized Tourism System API is running";
        data["version"] = "1.1.0";
        return data;
    });

    CROW_ROUTE(app, "/")([] {
        crow::json::wvalue data;
        data["name"] = "Personalized Tourism System API";
        data["version"] = "1.1.0";
        data["endpoints"] = string_list({
            "/api/v1/dashboard",
            "/api/v1/scenic-spots",
            "/api/v1/budget-plans",
            "/api/v1/routes",
            "/api/v1/diaries",
            "/api/v1/achievements"
        });
        return data;
    });

    CROW_ROUTE(app, "/api/v1/dashboard")([] {
        crow::json::wvalue data;
        data["stats"] = crow::json::wvalue::list({
            crow::json::wvalue{{"label", "演示景点"}, {"value", "8"}, {"detail", "含地理坐标与标签"}},
            crow::json::wvalue{{"label", "路线边"}, {"value", "32"}, {"detail", "支持 Dijkstra 演示"}},
            crow::json::wvalue{{"label", "游记样例"}, {"value", std::to_string(diaries.size())}, {"detail", "可编辑可扩展"}},
            crow::json::wvalue{{"label", "成就徽章"}, {"value", "4"}, {"detail", "适合答辩展示"}}
        });
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots")([](const crow::request& req) {
        return list_scenic(req);
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/<int>")([](int id) -> crow::response {
        auto it = std::find_if(scenic_spots.begin(), scenic_spots.end(), [id](const ScenicSpot& spot) { return spot.id == id; });
        if (it == scenic_spots.end()) return json_error(404, "Scenic spot not found");
        return crow::response(ok(scenic_json(*it)));
    });

    CROW_ROUTE(app, "/api/v1/scenic-spots/search")([](const crow::request& req) {
        return list_scenic(req);
    });

    CROW_ROUTE(app, "/api/v1/budget-plans")([](const crow::request& req) {
        int budget = 1000000;
        if (auto budget_param = req.url_params.get("budget")) {
            budget = std::stoi(budget_param);
        }
        crow::json::wvalue::list items;
        for (const auto& plan : budget_plans) {
            if (plan.budget <= budget) items.push_back(budget_json(plan));
        }
        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/recommendations/scenic-spots")([](const crow::request& req) {
        int limit = 10;
        if (auto limit_param = req.url_params.get("limit")) limit = std::stoi(limit_param);
        crow::json::wvalue::list items;
        int count = 0;
        for (const auto& spot : scenic_spots) {
            if (count++ >= limit) break;
            crow::json::wvalue rec;
            rec["scenic_spot"] = scenic_json(spot);
            rec["score"] = spot.rating / 5.0;
            rec["reason"] = spot.tags.empty() ? "综合评分较高" : "匹配偏好：" + spot.tags.front();
            items.push_back(std::move(rec));
        }
        crow::json::wvalue data;
        data["recommendations"] = std::move(items);
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/routes")([] {
        crow::json::wvalue::list items;
        for (const auto& route : route_plans) items.push_back(route_json(route));
        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/routes/plan").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string optimization = json_string(body, "optimization", "balanced");
        const RoutePlan& route = optimization == "distance" ? route_plans[2] : optimization == "time" ? route_plans[1] : route_plans[0];
        crow::json::wvalue data = route_json(route);
        data["route_id"] = "demo-route-" + std::to_string(route.id);
        data["total_distance_meters"] = route.id == 1 ? 5200 : route.id == 2 ? 2100 : 3800;
        data["total_duration_seconds"] = route.id == 1 ? 25200 : route.id == 2 ? 14400 : 18000;
        data["path"] = crow::json::wvalue::list({
            crow::json::wvalue{{"longitude", 116.397957}, {"latitude", 39.899318}},
            crow::json::wvalue{{"longitude", 116.397477}, {"latitude", 39.908692}},
            crow::json::wvalue{{"longitude", 116.397026}, {"latitude", 39.918058}}
        });
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/diaries")([](const crow::request& req) {
        std::string q = req.url_params.get("q") ? lower_copy(req.url_params.get("q")) : "";
        std::lock_guard<std::mutex> lock(diary_mutex);
        crow::json::wvalue::list items;
        for (const auto& diary : diaries) {
            if (!q.empty()) {
                auto haystack = lower_copy(diary.title + " " + diary.excerpt + " " + diary.mood);
                if (haystack.find(q) == std::string::npos) continue;
            }
            items.push_back(diary_json(diary));
        }
        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/diaries/search")([](const crow::request& req) {
        std::string q = req.url_params.get("q") ? lower_copy(req.url_params.get("q")) : "";
        std::lock_guard<std::mutex> lock(diary_mutex);
        crow::json::wvalue::list items;
        for (const auto& diary : diaries) {
            auto haystack = lower_copy(diary.title + " " + diary.excerpt + " " + diary.mood);
            for (const auto& tag : diary.tags) haystack += " " + lower_copy(tag);
            if (q.empty() || haystack.find(q) != std::string::npos) items.push_back(diary_json(diary));
        }
        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>")([](int id) -> crow::response {
        std::lock_guard<std::mutex> lock(diary_mutex);
        auto it = std::find_if(diaries.begin(), diaries.end(), [id](const Diary& diary) { return diary.id == id; });
        if (it == diaries.end()) return json_error(404, "Diary not found");
        return crow::response(ok(diary_json(*it)));
    });

    CROW_ROUTE(app, "/api/v1/diaries").methods("POST"_method)([](const crow::request& req) -> crow::response {
        auto body = crow::json::load(req.body);
        if (!body) return json_error(400, "Invalid JSON");
        std::lock_guard<std::mutex> lock(diary_mutex);
        int next_id = diaries.empty() ? 1 : diaries.back().id + 1;
        Diary diary{
            next_id,
            json_string(body, "title", "未命名日记"),
            json_string(body, "date", json_string(body, "start_date", "2026-05-08")),
            json_string(body, "distance", "0 km"),
            json_string(body, "mood", "记录中"),
            json_string(body, "cover", scenic_spots[0].image),
            json_tags(body),
            json_string(body, "excerpt", json_string(body, "content", "")),
            0, 0, 0
        };
        diaries.push_back(diary);
        return crow::response(201, ok(diary_json(diary)));
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>").methods("PUT"_method)([](const crow::request& req, int id) -> crow::response {
        auto body = crow::json::load(req.body);
        if (!body) return json_error(400, "Invalid JSON");
        std::lock_guard<std::mutex> lock(diary_mutex);
        auto it = std::find_if(diaries.begin(), diaries.end(), [id](const Diary& diary) { return diary.id == id; });
        if (it == diaries.end()) return json_error(404, "Diary not found");
        it->title = json_string(body, "title", it->title);
        it->date = json_string(body, "date", it->date);
        it->distance = json_string(body, "distance", it->distance);
        it->mood = json_string(body, "mood", it->mood);
        it->cover = json_string(body, "cover", it->cover);
        it->excerpt = json_string(body, "excerpt", it->excerpt);
        auto tags = json_tags(body);
        if (!tags.empty()) it->tags = tags;
        return crow::response(ok(diary_json(*it)));
    });

    CROW_ROUTE(app, "/api/v1/diaries/<int>").methods("DELETE"_method)([](int id) -> crow::response {
        std::lock_guard<std::mutex> lock(diary_mutex);
        auto old_size = diaries.size();
        diaries.erase(std::remove_if(diaries.begin(), diaries.end(), [id](const Diary& diary) { return diary.id == id; }), diaries.end());
        if (diaries.size() == old_size) return json_error(404, "Diary not found");
        crow::json::wvalue data;
        data["deleted"] = true;
        return crow::response(ok(std::move(data)));
    });

    CROW_ROUTE(app, "/api/v1/achievements")([] {
        crow::json::wvalue::list items;
        for (const auto& achievement : achievements) items.push_back(achievement_json(achievement));
        crow::json::wvalue data;
        data["total"] = static_cast<int>(items.size());
        data["items"] = std::move(items);
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/aigc/diary-summary").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string content = json_string(body, "content", "");
        crow::json::wvalue data;
        data["summary"] = content.empty() ? "这是一篇待完善的旅行记录。" : "自动摘要：" + content.substr(0, std::min<size_t>(content.size(), 90));
        return ok(std::move(data));
    });

    CROW_ROUTE(app, "/api/v1/aigc/polish").methods("POST"_method)([](const crow::request& req) {
        auto body = crow::json::load(req.body);
        std::string content = json_string(body, "content", "");
        crow::json::wvalue data;
        data["polished"] = content + "\n\n系统建议：补充路线顺序、预算感受和最推荐的停留点，会让游记更适合分享。";
        return ok(std::move(data));
    });

    std::cout << "============================================\n";
    std::cout << "Personalized Tourism System API\n";
    std::cout << "Host: " << host << "\n";
    std::cout << "Port: " << port << "\n";
    std::cout << "Version: 1.1.0\n";
    std::cout << "============================================\n";

    app.port(port).bindaddr(host).multithreaded().run();
    return 0;
}
