# TourPilot 个性化旅游系统

TourPilot 是一个旅游规划全栈项目。前端使用 Vue 3 + Vite + Tailwind CSS，后端使用 C++ Crow，数据库使用 PostgreSQL/PostGIS。项目支持景点搜索、个性化推荐、预算方案、路线规划、景区内部导航、美食推荐、游记、旅行护照成就、数字纪念凭证和 AI 旅行助手。

## 核心功能

- 首页推荐、搜索景点、景点详情。
- 预算推荐、个性化推荐。
- 路线规划和 Leaflet 地图展示，景区内部导航使用高德 JS API 展示。
- 游记广场、游记编辑、游记详情、点赞收藏评分评论。
- 个人偏好读取与保存。
- 登录、注册、退出、保持登录状态、登录后修改密码。
- AI 旅行助手 `/agent`，通过后端调用真实大模型 API。

## 技术栈

前端：

- Vue 3
- Vue Router
- Vite
- Tailwind CSS
- Axios
- Leaflet

后端：

- C++17
- Crow
- libpq/PostgreSQL
- PostgreSQL + PostGIS
- CMake

外部服务：

- DeepSeek 或兼容 Chat Completions 的大模型接口。
- 高德 Web Service 路线接口。
- OpenStreetMap/Overpass 内部路网数据，高德 JS API 前端地图。

## 项目结构

```text
personalized-tourism-system/
├─ frontend/
│  ├─ src/
│  │  ├─ main.js
│  │  ├─ App.vue
│  │  ├─ router/
│  │  ├─ views/
│  │  ├─ components/
│  │  ├─ services/tourismApi.js
│  │  ├─ data/
│  │  ├─ stores/
│  │  └─ utils/
│  ├─ public/images/diary/
│  ├─ scripts/
│  └─ package.json
├─ backend/
│  ├─ include/
│  │  ├─ api/
│  │  ├─ db/
│  │  ├─ services/
│  │  └─ support/
│  ├─ src/
│  │  ├─ main.cpp
│  │  ├─ api/
│  │  ├─ db/
│  │  ├─ services/
│  │  ├─ support/
│  │  └─ graph/
│  └─ CMakeLists.txt
├─ database/
├─ docs/
├─ QUICKSTART.md
└─ AGENTS.md
```

## 前端运行链路

`frontend/src/main.js` 是前端入口：

1. 导入 `App.vue`。
2. 注册 `router/index.js`。
3. 导入 `index.css`，让 Tailwind 生效。
4. 导入 `leaflet/dist/leaflet.css`，让地图控件和 marker 样式正常显示。
5. `createApp(App).use(router).mount('#app')` 挂载应用。

`App.vue` 负责顶部导航、全局搜索和 `<router-view />`。首页、搜索页、详情页、路线页和 AI 助手都在同一个 Vue 单页应用里，通过 Vue Router 切换。

## 后端结构

后端已经拆成模块化结构。`backend/src/main.cpp` 只负责解析启动参数、创建 Crow app、注册路由模块并启动服务。

主要模块：

```text
backend/src/api/
├─ auth_routes.cpp            # 登录、注册、退出、当前用户、修改密码
├─ dashboard_routes.cpp       # /health、dashboard、achievements、checkins、collectibles、badge redemptions、review decisions
├─ profile_routes.cpp         # profile、preferences
├─ scenic_routes.cpp          # 景点列表、搜索、详情、建议词、评价
├─ recommendation_routes.cpp  # 预算方案、个性化推荐
├─ route_routes.cpp           # 路线节点、路线列表、路线规划
├─ diary_routes.cpp           # 游记、点赞、收藏、评分、评论、成就评审提交
├─ aigc_routes.cpp            # AIGC 摘要、润色、旅游助手
└─ food_routes.cpp            # 美食推荐、菜系筛选、Top-K 排序

backend/src/services/
├─ auth_service.cpp           # PBKDF2 密码哈希、Bearer token 校验
├─ achievement_service.cpp    # 旅行护照成就、打卡、数字纪念凭证、实体徽章兑换、游记评审决策
├─ scenic_service.cpp         # 景点查询和景点 JSON
├─ budget_service.cpp         # 预算方案
├─ recommendation_service.cpp # 推荐计算
├─ route_graph_service.cpp    # 本地路线图规划
├─ amap_route_service.cpp     # 高德路线服务
└─ llm_service.cpp            # 大模型 HTTP 调用
```

## 环境变量

| 变量 | 用途 | 默认行为 |
| --- | --- | --- |
| `TOURISM_DB_CONN` | PostgreSQL 连接串 | 默认 `host=127.0.0.1 port=5432 dbname=tourism_system user=postgres` |
| `TOURISM_LLM_API_KEY` | 大模型 API Key | 未配置时 AI 助手返回配置错误 |
| `TOURISM_LLM_BASE_URL` | 大模型接口地址 | 默认 `https://api.deepseek.com` |
| `TOURISM_LLM_MODEL` | 大模型名称 | 建议显式设置为平台支持的模型 |
| `AMAP_WEB_SERVICE_KEY` / `AMAP_KEY` | 覆盖高德 Web Service Key | 未配置时使用后端内置免费高德 key |
| `VITE_AMAP_JS_KEY` | 覆盖前端高德 JS API Key | 未配置时使用项目内置免费 JS API key |
| `VITE_AMAP_SECURITY_JS_CODE` | 前端高德 JS API 安全密钥 | 可选；仅在高德控制台安全配置要求时设置 |
| `TOURISM_REVIEWER_USERNAMES` | 大师级游记评审用户名白名单 | 逗号分隔；`demo_user` 默认具备评审权限 |

DeepSeek key 不允许写入仓库，只能放本地环境变量：

```powershell
$env:TOURISM_LLM_API_KEY="你的 DeepSeek API Key"
$env:TOURISM_LLM_BASE_URL="https://api.deepseek.com"
$env:TOURISM_LLM_MODEL="deepseek-chat"
```

高德 key 已经有内置默认值。如需临时覆盖：

```powershell
$env:AMAP_WEB_SERVICE_KEY="你的高德 Web Service Key"
```

前端景区内部地图使用高德 JS API，默认使用项目内置免费 JS API key；如需临时覆盖，或高德控制台要求安全密钥，可在启动前端的窗口设置：

```powershell
$env:VITE_AMAP_JS_KEY="你的高德 JS API Key"
$env:VITE_AMAP_SECURITY_JS_CODE="你的高德 JS API 安全密钥，可选"
```

PowerShell 的 `$env:...` 只对当前窗口和它启动的子进程生效。需要在启动后端的同一个窗口里设置环境变量。

## 图片来源规则

景点图片只使用三层来源：

1. 后端接口返回的数据库图片，通常来自高德导入或人工维护。
2. 前端本地拼音图片，目录为 `frontend/public/images/diary/`，映射在 `frontend/src/data/imageCatalog.js`。
3. 前端 SVG 占位图，由 `frontend/src/utils/images.js` 生成。

本地拼音图片目前是人工整理的北京景点图库，只能作为北京景点的兜底图。前端会优先读取后端返回的 `city`、`province`、`district` 等结构化区域字段判断是否属于北京；如果明确是南京、银川等外地城市，即使地址里包含“北京西路”“北京路”等道路名，也不会使用北京本地图库，而是继续使用数据库图片或 SVG 占位图。

后端不再用外部随机图片做景点 fallback。

## 登录与演示账号

当前账号系统支持用户名或邮箱登录。前端会把后端返回的 token 保存到 `localStorage.token`，并在请求时通过 `Authorization: Bearer <token>` 发送给后端。

演示账号：

```text
用户名：demo_user
邮箱：demo@example.com
密码：demo123456
```

需要登录的页面和操作：`/profile`、`/collectibles/:id`、`/diary/new`、`/diary/edit/:id`，以及游记点赞、收藏、评分、评论、创建、编辑、删除，景点打卡、成就奖励领取、数字纪念凭证详情、实体徽章兑换和大师级游记评审提交。大师评审决策只允许 `demo_user` 或 `TOURISM_REVIEWER_USERNAMES` 中配置的用户操作。首页、搜索、景点详情、路线规划、AI 助手、游记详情、`/food` 和 `/achievements` 仍可匿名浏览。

## 快速启动

先初始化或补齐数据库。`git pull` 只会更新代码和 SQL 文件，不会自动修改本机 PostgreSQL；室内导航依赖新增的 `indoor_*` 表和北大红楼首批室内图数据，所以团队成员拉取分支后必须同步执行对应 SQL 迁移和 seed。

全新数据库完整初始化：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

已有数据库只补室内导航时：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

补完后可以用下面的查询确认北大红楼室内导航已经在同一个 `tourism_system` 数据库里：

```powershell
psql -U postgres -d tourism_system -c "SELECT b.scenic_spot_id, s.name, b.name, b.provider, (SELECT COUNT(*) FROM indoor_features f WHERE f.building_id = b.id) AS features FROM indoor_buildings b JOIN scenic_spots s ON s.id = b.scenic_spot_id;"
```

数据库完成后再启动服务：

```powershell
$env:TOURISM_LLM_API_KEY="你的 DeepSeek API Key"
$env:TOURISM_LLM_BASE_URL="https://api.deepseek.com"
$env:TOURISM_LLM_MODEL="deepseek-chat"
$env:PATH="C:\Program Files\PostgreSQL\15\bin;$env:PATH"

cmake -S backend -B backend\build-codex-verify-mingw
cmake --build backend\build-codex-verify-mingw
backend\build-codex-verify-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
```

另开一个窗口启动前端：

```powershell
cd frontend
npm install
npm run dev
```

打开：

- 前端：http://127.0.0.1:3000
- 健康检查：http://127.0.0.1:8080/health
- AI 助手：http://127.0.0.1:3000/agent
- 美食推荐：http://127.0.0.1:3000/food
- 旅行护照：http://127.0.0.1:3000/achievements

## 验证命令

```powershell
cmake --build backend\build-codex-verify-mingw

python scripts\audit_project_data.py

cd frontend
npm.cmd run lint
npm.cmd run build
```

后端冒烟：

```powershell
Invoke-WebRequest http://127.0.0.1:8080/health
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/scenic-spots?limit=2"
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/search/suggestions?q=故宫"
Invoke-WebRequest http://127.0.0.1:8080/api/v1/routes
Invoke-WebRequest http://127.0.0.1:8080/api/v1/diaries
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/foods?scenic_spot_id=12&sort=hot&limit=10"
Invoke-WebRequest http://127.0.0.1:8080/api/v1/achievements
Invoke-WebRequest http://127.0.0.1:8080/api/v1/badge-redemptions -Headers @{Authorization="Bearer <token>"}
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/achievement-review-submissions?status=pending" -Headers @{Authorization="Bearer <reviewer-token>"}
```

登录冒烟：

```powershell
Invoke-WebRequest `
  -Method POST `
  -Uri http://127.0.0.1:8080/api/v1/auth/login `
  -ContentType "application/json" `
  -Body '{"identifier":"demo_user","password":"demo123456"}'
```

AI 助手冒烟：

```powershell
Invoke-WebRequest `
  -Method POST `
  -Uri http://127.0.0.1:8080/api/v1/aigc/travel-chat `
  -ContentType "application/json" `
  -Body '{"message":"帮我规划北京三日游","destination":"北京","days":3,"budget":1000,"style":"balanced"}'
```

路线文本规划冒烟：

```powershell
Invoke-WebRequest `
  -Method POST `
  -Uri http://127.0.0.1:8080/api/v1/routes/plan `
  -ContentType "application/json" `
  -Body '{"city":"北京","startText":"前门大街","endText":"故宫博物院","waypointTexts":["天安门广场"],"travelMode":"walk","optimization":"balanced"}'
```

## 常见问题

- 后端启动后立刻回到 PowerShell：通常是缺 DLL。先执行 `$env:PATH="C:\Program Files\PostgreSQL\15\bin;$env:PATH"` 再启动。
- 前端页面能打开但 API 失败：先访问 `/health`，确认后端正在 `127.0.0.1:8080` 运行。
- 登录失败：确认 `database\seed_demo.sql` 已执行；旧数据库也可用 `demo_user / demo123456` 首次登录并自动升级密码哈希。
- AI 助手失败：检查 `TOURISM_LLM_API_KEY` 是否在启动后端的同一个窗口设置。
- 路线规划失败：高德 key 已有内置默认值；若仍失败，检查网络是否能访问 `https://restapi.amap.com`。

## 美食推荐模块

`/food` 页面对应后端 `/api/v1/foods` 和 `/api/v1/foods/cuisines`。数据来源是 `facilities` 表中的 `restaurant`、`cafe`、`fast_food`，景区归属优先使用 `facilities.scenic_spot_id`，也兼容通过 `graph_nodes` 关联到景区的设施。

`GET /api/v1/foods` 支持：

- `scenic_spot_id`：按景区筛选周边餐饮。
- `q`：模糊查询名称、菜系、地址和景区名；窗口名称按名称处理。
- `cuisine`：按推断菜系过滤，例如咖啡、火锅、烤鸭、小吃等。
- `sort`：`hot`、`rating`、`distance`，默认 `hot`。
- `lat` / `lng`：距离展示或距离排序参考点；未传时使用所选景区坐标。
- `limit`：默认 10，上限 50。

热门推荐不新增数据库字段，使用派生 `hotScore`：评分 50%、信息完整度 20%、价格友好度 15%、类型/名称可信度 15%。排序统一通过 `TopKSelector` 做 Top-K 部分排序，响应会包含 `hotScore`、`matchReason`、`distanceMeters`、`sort` 和算法说明。

## 旅行护照、成就与数字纪念凭证

`/achievements` 是公开的旅行护照页面，未登录用户可以看示例玩法；登录后展示个人打卡、主题集章、游记创作和大师评审四层成就进度。页面会展示主题所需景点、已收集印章、缺失印章和下一步建议；数字藏品在 V1 中实现为“模拟链上数字纪念凭证”，不会调用真实区块链；实体徽章只做兑换申请和状态记录，不包含库存、物流或后台发货流程。

主要接口：

- `GET /api/v1/achievements`：旅行护照总览、四层成就、进度、奖励状态、数字凭证摘要、缺失印章、下一步建议和兑换记录。
- `POST /api/v1/scenic-spots/:id/checkins`：景点打卡；有浏览器定位时校验距离，定位失败或缺失时使用 `verification="self"` 演示打卡。
- `POST /api/v1/achievements/:id/claim`：领取已解锁成就奖励，生成模拟 `token_id` 和 `blockchain_hash`。
- `GET /api/v1/collectibles`、`GET /api/v1/collectibles/:id`：个人数字纪念凭证墙和证书详情页 `/collectibles/:id`，证书页支持本地生成分享卡图片。
- `GET /api/v1/badge-redemptions`、`POST /api/v1/badge-redemptions`：实体徽章兑换记录与兑换申请。
- `POST /api/v1/diaries/:id/achievement-review`：大师级旅行日记评审提交。
- `GET /api/v1/achievement-review-submissions`、`POST /api/v1/achievement-review-submissions/:id/decision`：轻量评审队列和通过/驳回决策；仅评审用户可访问。

相关数据表：

- `achievements`：成就定义，包含稳定 `code`、`tier`、`display_order`、`requirement` 和 `reward`。
- `user_achievements`：用户成就进度和解锁状态。
- `user_scenic_checkins`：景点打卡记录。
- `digital_collectibles`：数字纪念凭证。
- `achievement_review_submissions`：大师级游记评审队列。
- `physical_badge_redemptions`：实体徽章兑换申请。

成就规则集中在 `backend/src/services/achievement_service.cpp`，路由层只负责鉴权、参数解析和调用服务。新增成就规则时优先修改服务层和 seed 数据，不要把判定逻辑散落到多个 route 文件。

## 景区内部设施导航数据

景点详情页的“景区设施导航”依赖三类数据：

- `database\internal_navigation_schema.sql`：为 `facilities`、`graph_nodes`、`graph_edges` 补充内部导航字段和索引。
- `database\imports\internal_navigation.sql`：已经生成好的内部导航演示数据。
- `scripts\import_internal_map_data.py`：联网抓取真实地图数据并重新生成 `internal_navigation.sql`。

当前生成结果来自 OpenStreetMap/Overpass 的内部道路、建筑、入口等要素，以及高德 Web Service 的周边设施 POI。数据库统一存储 WGS84 / `SRID=4326`：OSM 数据原生使用 WGS84，高德 POI 会先用 GCJ-02 查询，再转换为 WGS84 入库，并在 `source_tags` 中保留原始高德坐标。导入脚本会把设施接入最近的真实 OSM 步行道路，但默认只允许 60m 内的短接入段；超过阈值的设施仍可查询，但内部路线会提示不可达，不会生成直线示意路线。当前 SQL 已成功生成故宫、北海、奥林匹克森林公园三处大景区数据。天坛和颐和园本次 Overpass 请求失败，脚本会跳过失败景区并保留已成功数据。

如果只需要导入已生成的数据：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
```

如果需要重新联网抓取并生成 SQL：

```powershell
py scripts\import_internal_map_data.py --amap-pages 1 --max-edges-per-spot 2000 --connector-max-distance 60 --output database\imports\internal_navigation.sql
```

高德 Web Service key 会按 `--amap-key`、`AMAP_WEB_SERVICE_KEY`、`AMAP_KEY`、脚本内置免费 key 的顺序选择。Overpass/高德请求需要网络可访问。前端景点详情页使用高德 JS API 展示内部导航地图：后端 API 和数据库仍统一返回 WGS84，前端展示前转换为 GCJ-02，地图点选起点时再转换回 WGS84 发给后端规划路线。前端默认使用项目内置免费 JS API key；如需覆盖可设置 `VITE_AMAP_JS_KEY`，如高德控制台启用了安全密钥校验再设置 `VITE_AMAP_SECURITY_JS_CODE`。

## 更多文档

- [快速运行手册](QUICKSTART.md)
- [AI/Agent 接手说明](AGENTS.md)
- [系统架构](docs/architecture.md)
- [后端拆分记录](docs/backend-refactor.md)
- [前端学习说明](docs/frontend-guide.md)
- [运行中 API 文档](docs/api-runtime.md)
