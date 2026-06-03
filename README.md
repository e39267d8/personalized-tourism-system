# TourPilot 个性化旅游系统

TourPilot 是一个旅游规划全栈项目。前端使用 Vue 3 + Vite + Tailwind CSS，后端使用 C++ Crow，数据库使用 PostgreSQL/PostGIS。项目支持景点搜索、个性化推荐、预算方案、路线规划、游记、成就和 AI 旅行助手。

## 核心功能

- 首页推荐、搜索景点、景点详情。
- 预算推荐、个性化推荐。
- 路线规划和 Leaflet 地图展示。
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
- OpenStreetMap 地图瓦片。

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
├─ dashboard_routes.cpp       # /health、dashboard、achievements
├─ profile_routes.cpp         # profile、preferences
├─ scenic_routes.cpp          # 景点列表、搜索、详情、建议词、评价
├─ recommendation_routes.cpp  # 预算方案、个性化推荐
├─ route_routes.cpp           # 路线节点、路线列表、路线规划
├─ diary_routes.cpp           # 游记、点赞、收藏、评分、评论
└─ aigc_routes.cpp            # AIGC 摘要、润色、旅游助手

backend/src/services/
├─ auth_service.cpp           # PBKDF2 密码哈希、Bearer token 校验
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

PowerShell 的 `$env:...` 只对当前窗口和它启动的子进程生效。需要在启动后端的同一个窗口里设置环境变量。

## 图片来源规则

景点图片只使用三层来源：

1. 后端接口返回的数据库图片，通常来自高德导入或人工维护。
2. 前端本地拼音图片，目录为 `frontend/public/images/diary/`，映射在 `frontend/src/data/imageCatalog.js`。
3. 前端 SVG 占位图，由 `frontend/src/utils/images.js` 生成。

后端不再用外部随机图片做景点 fallback。

## 登录与演示账号

当前账号系统支持用户名或邮箱登录。前端会把后端返回的 token 保存到 `localStorage.token`，并在请求时通过 `Authorization: Bearer <token>` 发送给后端。

演示账号：

```text
用户名：demo_user
邮箱：demo@example.com
密码：demo123456
```

需要登录的页面和操作：`/profile`、`/achievements`、`/diary/new`、`/diary/edit/:id`，以及游记点赞、收藏、评分、评论、创建、编辑、删除。首页、搜索、景点详情、路线规划、AI 助手和游记详情仍可匿名浏览。

## 快速启动

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql

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

## 验证命令

```powershell
cmake --build backend\build-codex-verify-mingw

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

## 更多文档

- [快速运行手册](QUICKSTART.md)
- [AI/Agent 接手说明](AGENTS.md)
- [系统架构](docs/architecture.md)
- [后端拆分记录](docs/backend-refactor.md)
- [前端学习说明](docs/frontend-guide.md)
- [运行中 API 文档](docs/api-runtime.md)
