# 后端拆分记录

本文记录后端从大型 `main.cpp` 拆分后的当前结构，方便后续维护。

## 拆分目标

原来的 `main.cpp` 同时包含启动逻辑、路由注册、SQL、推荐、路线、AIGC、图片 fallback 等内容，文件过大且容易损坏。当前目标是让 `main.cpp` 只保留服务启动职责：

- 解析命令行参数。
- 创建 Crow app。
- 注册各业务模块。
- 启动 HTTP 服务。

## 当前 main.cpp 职责

路径：`backend/src/main.cpp`

当前只应包含：

```text
include route headers
parse --host and --port
create tourism::api::TourismApp
register_*_routes(app)
print startup info
app.port(...).bindaddr(...).multithreaded().run()
```

后续不要再把具体接口实现塞回 `main.cpp`。

## 路由模块

路径：`backend/src/api/`

| 文件 | 职责 |
| --- | --- |
| `dashboard_routes.cpp` | `/health`、根路径 `/`、dashboard、achievements |
| `profile_routes.cpp` | 用户资料和偏好 |
| `scenic_routes.cpp` | 景点列表、搜索、分类、建议词、详情、景点评价 |
| `recommendation_routes.cpp` | 预算方案、景点推荐、个性化推荐 |
| `route_routes.cpp` | 路线节点、路线列表、路线规划 |
| `diary_routes.cpp` | 游记列表、搜索、详情、创建、更新、删除、点赞、收藏、评分、评论 |
| `aigc_routes.cpp` | 游记摘要、文本润色、旅游助手 |

每个模块在 `backend/include/api/` 下有对应头文件，并暴露一个注册函数：

```cpp
void register_xxx_routes(TourismApp& app);
```

## 服务模块

路径：`backend/src/services/`

| 文件 | 职责 |
| --- | --- |
| `scenic_service.cpp` | 景点查询和景点 JSON 组装 |
| `budget_service.cpp` | 预算方案计算 |
| `recommendation_service.cpp` | 个性化推荐规则 |
| `route_graph_service.cpp` | 路线图数据、Dijkstra 和节点路线规划 |
| `amap_route_service.cpp` | 高德 Web Service 路线调用和解析 |
| `llm_service.cpp` | DeepSeek 或兼容 Chat Completions API 调用 |

原则：

- 路由模块负责 HTTP 层。
- 服务模块负责业务计算和外部服务。
- SQL 较复杂时可以放在服务模块中，但返回给前端的 HTTP 响应仍由路由模块组织。

## 图片策略

后端景点服务只返回数据库中已有的图片字段，不再使用外部随机图片 fallback。

景点图片的完整兜底顺序由前端负责：

1. 接口返回图片。
2. 本地拼音图片。
3. SVG 占位图。

## 高德路线策略

`backend/src/services/amap_route_service.cpp` 内置免费默认高德 Web Service key。环境变量优先级：

1. `AMAP_WEB_SERVICE_KEY`
2. `AMAP_KEY`
3. 内置免费默认 key

这样文本地点路线规划在未配置环境变量时也能调用高德。DeepSeek key 不同，必须只走环境变量。

## 数据库模块

路径：`backend/src/db/postgres.cpp`

职责：

- 读取 `TOURISM_DB_CONN`。
- 创建 PostgreSQL 连接。
- 设置 UTF-8 客户端编码。
- 封装 `PQexec` 和 `PQexecParams`。

默认连接串：

```text
host=127.0.0.1 port=5432 dbname=tourism_system user=postgres
```

如需改连接，使用环境变量，不要在代码里写死数据库密码。

## Support 模块

路径：`backend/src/support/api_helpers.cpp`

职责包括：

- 统一 JSON 响应。
- 统一错误响应。
- 查询参数安全解析。
- 数值范围限制。
- Crow response header 辅助。

新增接口时优先复用这里的解析和响应函数，避免 `std::stoi` 等异常直接变成不清晰的 500。

## CMake 结构

路径：`backend/CMakeLists.txt`

当前源码按分组维护：

```text
DB_SOURCES
SUPPORT_SOURCES
GRAPH_SOURCES
SERVICE_SOURCES
API_SOURCES
MAIN_SOURCES
ALL_SOURCES
```

新增 `.cpp` 文件后，要把它加入对应分组，否则后端不会编译进 `tourism_server`。

## 新增接口放哪里

判断方式：

- 景点、搜索、建议词、景点评价：`scenic_routes.cpp`
- 推荐、预算、个性化推荐：`recommendation_routes.cpp`
- 路线、节点、导航：`route_routes.cpp`
- 游记、评论、互动：`diary_routes.cpp`
- 用户资料、偏好：`profile_routes.cpp`
- 健康检查、首页统计、成就：`dashboard_routes.cpp`
- AI 相关：`aigc_routes.cpp`

如果接口需要复杂计算或外部服务：

1. 在 `services/` 中新增或复用服务函数。
2. 在 `api/` 路由中调用服务函数。
3. 在 `CMakeLists.txt` 加入新的 `.cpp`。
4. 保持前端已依赖的字段和路径稳定。

## 当前仍需注意

- 数据库 schema 中仍保留一些早期认证相关表，但前端当前没有正式登录流程。
- 继续改动中文字符串时，统一替换为干净 UTF-8 中文。
- GTest 暂时放一边，不作为当前运行和验收要求。
- AIGC 旅游助手必须走真实 API，未配置 DeepSeek key 时返回配置错误，不生成假回复。
