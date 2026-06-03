# TourPilot 快速运行手册

这份文档只讲如何把项目跑起来。项目根目录假设为：

```text
C:\Users\seele\Desktop\code\personalized-tourism-system
```

## 1. 准备环境

需要：

- Node.js 18+
- npm 9+
- CMake 3.15+
- C++17 编译器
- PostgreSQL 15
- PostGIS
- libpq/PostgreSQL 开发库
- standalone Asio

## 2. 初始化数据库

如果数据库不存在，先创建：

```powershell
createdb -U postgres tourism_system
```

初始化：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -f database\maintenance\repair_data_quality.sql
psql -U postgres -d tourism_system -f database\verify_demo.sql
```

如需覆盖数据库连接：

```powershell
$env:TOURISM_DB_CONN="host=127.0.0.1 port=5432 dbname=tourism_system user=postgres password=你的密码"
```

## 3. 配置外部 API

DeepSeek 必须通过环境变量配置，不要写入仓库：

```powershell
$env:TOURISM_LLM_API_KEY="你的 DeepSeek API Key"
$env:TOURISM_LLM_BASE_URL="https://api.deepseek.com"
$env:TOURISM_LLM_MODEL="deepseek-chat"
```

高德路线服务已经在后端内置免费默认 key。通常不需要配置；如果要覆盖：

```powershell
$env:AMAP_WEB_SERVICE_KEY="你的高德 Web Service Key"
```

## 4. 构建后端

```powershell
cmake -S backend -B backend\build-codex-verify-mingw
cmake --build backend\build-codex-verify-mingw
```

如果后端启动后立刻退出，先把 PostgreSQL 的 DLL 目录加到当前窗口 PATH：

```powershell
$env:PATH="C:\Program Files\PostgreSQL\15\bin;$env:PATH"
```

## 5. 启动后端

```powershell
backend\build-codex-verify-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
```

正常情况下，这个窗口会一直被后端服务占用，不会立刻回到 PowerShell 提示符。

验证：

```powershell
Invoke-WebRequest http://127.0.0.1:8080/health
```

## 6. 启动前端

另开一个窗口：

```powershell
cd frontend
npm install
npm run dev
```

默认地址：

```text
http://127.0.0.1:3000
```

指定端口：

```powershell
npm run dev -- --host 127.0.0.1 --port 4187
```

当前 `npm run dev` 使用 `node scripts/vite-dev.mjs`，用于绕过 Windows 下 Vite 配置加载的路径访问问题。

## 7. 构建前端

```powershell
cd frontend
npm.cmd run lint
npm.cmd run build
```

## 8. 冒烟验证

后端：

```powershell
Invoke-WebRequest http://127.0.0.1:8080/health
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/scenic-spots?limit=2"
Invoke-WebRequest http://127.0.0.1:8080/api/v1/scenic-categories
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/search/suggestions?q=故宫"
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/budget-plans?budget=200"
Invoke-WebRequest http://127.0.0.1:8080/api/v1/routes
Invoke-WebRequest http://127.0.0.1:8080/api/v1/diaries
```

登录：

```powershell
$login = Invoke-RestMethod `
  -Method POST `
  -Uri http://127.0.0.1:8080/api/v1/auth/login `
  -ContentType "application/json" `
  -Body '{"identifier":"demo_user","password":"demo123456"}'

$token = $login.data.token
Invoke-RestMethod `
  -Uri http://127.0.0.1:8080/api/v1/auth/me `
  -Headers @{ Authorization = "Bearer $token" }
```

高德文本路线规划：

```powershell
Invoke-WebRequest `
  -Method POST `
  -Uri http://127.0.0.1:8080/api/v1/routes/plan `
  -ContentType "application/json" `
  -Body '{"city":"北京","startText":"前门大街","endText":"故宫博物院","waypointTexts":["天安门广场"],"travelMode":"walk","optimization":"balanced"}'
```

本地节点路线规划：

```powershell
Invoke-WebRequest `
  -Method POST `
  -Uri http://127.0.0.1:8080/api/v1/routes/plan `
  -ContentType "application/json" `
  -Body '{"startNodeId":1,"endNodeId":3,"waypointNodeIds":[2],"travelMode":"walk","optimization":"balanced","crowdTolerance":3}'
```

AI 助手：

```powershell
Invoke-WebRequest `
  -Method POST `
  -Uri http://127.0.0.1:8080/api/v1/aigc/travel-chat `
  -ContentType "application/json" `
  -Body '{"message":"帮我规划北京三日游","destination":"北京","days":3,"budget":1000,"style":"balanced"}'
```

前端页面：

- `http://127.0.0.1:3000/`
- `http://127.0.0.1:3000/login`
- `http://127.0.0.1:3000/register`
- `http://127.0.0.1:3000/search?q=故宫`
- `http://127.0.0.1:3000/spots/3`
- `http://127.0.0.1:3000/route`
- `http://127.0.0.1:3000/agent`

## 9. 图片来源

景点图片只走三层来源：

1. 后端返回的数据库图片，来自高德导入或人工维护。
2. 前端本地拼音图片，位于 `frontend/public/images/diary/`。
3. 前端 SVG 占位图。

## 10. 演示账号

```text
用户名：demo_user
邮箱：demo@example.com
密码：demo123456
```

需要登录后访问：`/profile`、`/achievements`、`/diary/new`、`/diary/edit/:id`。游记点赞、收藏、评分、评论也需要登录。

## 11. 常见问题

### 后端启动后立刻返回 PowerShell

检查退出码：

```powershell
backend\build-codex-verify-mingw\bin\tourism_server.exe --help
$LASTEXITCODE
```

如果是 `-1073741515`，通常是缺少运行时 DLL。执行：

```powershell
$env:PATH="C:\Program Files\PostgreSQL\15\bin;$env:PATH"
```

### 前端页面能打开，但接口报错

前端请求 `/api/v1/...`，由 Vite 代理到 `http://127.0.0.1:8080`。先确认：

```powershell
Invoke-WebRequest http://127.0.0.1:8080/health
```

### 登录失败

确认已经执行：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
```

演示账号是 `demo_user / demo123456`。如果数据库里仍是旧的 `demo_hash_not_for_production`，后端会在首次成功登录后自动升级为 PBKDF2 密码哈希。

### AI 助手没有回复

检查：

- `TOURISM_LLM_API_KEY` 是否在启动后端的同一个窗口设置。
- `TOURISM_LLM_BASE_URL` 是否能访问。
- `TOURISM_LLM_MODEL` 是否是平台支持的模型。
- 后端终端是否有外部 API 请求失败日志。

### 地图不显示

检查：

- `frontend/src/main.js` 是否导入 `leaflet/dist/leaflet.css`。
- 浏览器是否能访问 OpenStreetMap 瓦片。
- 路线页地图容器是否有高度。
