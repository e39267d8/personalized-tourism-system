#include "services/budget_service.h"

#include <string>
#include <vector>

namespace tourism::services {
namespace {

struct BudgetPlan {
    std::string id;
    std::string label;
    int budget;
    std::string title;
    std::string route;
    std::vector<std::string> includes;
    std::string tradeoff;
};

const std::vector<BudgetPlan> kBudgetPlans = {
    {
        "lite",
        "轻预算",
        80,
        "免费展馆 + 城市漫步",
        "国家博物馆 -> 天安门广场 -> 前门大街",
        {"门票 0 元", "餐饮约 45 元", "交通约 12 元"},
        "优先选择免费景点和步行路线，适合低成本体验。"
    },
    {
        "balanced",
        "均衡型",
        180,
        "中轴线完整体验",
        "前门 -> 天安门 -> 故宫 -> 景山",
        {"核心门票约 62 元", "餐饮约 80 元", "交通约 20 元"},
        "体验更完整，适合首次来北京的用户。"
    },
    {
        "comfort",
        "舒适型",
        360,
        "少排队 + 好餐厅 + 轻交通",
        "故宫 -> 景山 -> 王府井餐饮",
        {"预约优先", "餐饮约 180 元", "打车/骑行约 80 元"},
        "成本更高，但能减少转场和排队压力。"
    }
};

crow::json::wvalue string_list(const std::vector<std::string>& values) {
    crow::json::wvalue::list list;
    for (const auto& value : values) list.push_back(value);
    return crow::json::wvalue(std::move(list));
}

crow::json::wvalue budget_plan_json(const BudgetPlan& plan) {
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

} // namespace

crow::json::wvalue budget_plans_json(int budget) {
    crow::json::wvalue::list items;
    for (const auto& plan : kBudgetPlans) {
        if (plan.budget <= budget) items.push_back(budget_plan_json(plan));
    }

    crow::json::wvalue data;
    data["total"] = static_cast<int>(items.size());
    data["items"] = std::move(items);
    return data;
}

} // namespace tourism::services
