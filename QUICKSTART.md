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

`git pull` 只会更新代码和 SQL 文件，不会自动更新本机 PostgreSQL。景区/校园内部道路图、室内导航、路线规划演示路网、美食推荐和日记扩展字段都需要同步执行对应 SQL 迁移和 seed；如果没有执行对应 SQL，页面会显示“未接入”、查不到新增数据，或继续画旧的演示直线。

全新数据库初始化顺序：

```powershell
createdb -U postgres tourism_system
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\amap_pois_supplement.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_campus_spots.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation_pku.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_pku_curated_map.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_pku_bike_lanes.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation_yiheyuan.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_yiheyuan_demo_map.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\achievement_module_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_compression_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\cross_layer_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_location_cover_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_animation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\scenic_search_indexes.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_extra_users.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_facilities.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_foods.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_achievements.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_indoor_navigation.sql
psql -U postgres -d tourism_system -f database\maintenance\repair_data_quality.sql
psql -U postgres -d tourism_system -f database\verify_demo.sql
```

已有数据库只补北京大学校园内部道路图：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_campus_spots.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation_pku.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_pku_curated_map.sql
```

已有数据库只补北大红楼室内导航：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_indoor_navigation.sql
```

已有数据库只补成就系统结构与演示数据：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\achievement_module_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_achievements.sql
```

已有数据库只补日记压缩存储（新增 `content_compressed` / `content_original_bytes` 列）：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_compression_schema.sql
```

已有数据库只补日记地点与封面（新增 `cover_image`、`location_*` 六列，存量日记封面自动回填）：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_location_cover_schema.sql
```

已有数据库只补日记动画预览（新增 `videos` 和 `animation_storyboard` 列）：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_animation_schema.sql
```

已有数据库只补美食推荐演示数据：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_facilities.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_foods.sql
```

已有数据库只补路线规划演示路网和成就演示数据（推荐在拉到路线规划或成就相关修复后重跑一次）：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_achievements.sql
```

说明：

- `seed_demo.sql` 现在支持幂等重跑，但只负责基础演示关系数据。
- `seed_achievements.sql` 单独负责成就系统演示数据，更适合创新功能分支独立维护。
- 如果路线规划页在“拥挤度感知”模式下仍然只画节点直线，先重跑这条 SQL，再刷新页面验证。

已有数据库只补室内外跨层导航（`indoor_buildings` 新增 `outdoor_node_id` 室外锚点绑定，需先导入内部路网和室内导航数据）：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\cross_layer_navigation_schema.sql
```

迁移会按名称自动绑定建筑与室外路网节点（如"北大红楼"↔"北京大学红楼"）。验证绑定结果：

```powershell
psql -U postgres -d tourism_system -c "SELECT b.id, b.name, b.outdoor_node_id, gn.name AS outdoor_node FROM indoor_buildings b LEFT JOIN graph_nodes gn ON gn.id = b.outdoor_node_id;"
```

迁移后，新建/更新的日记自动压缩存储；存量明文日记可登录后调用一次 `POST /api/v1/diaries/compression/migrate` 批量压缩，并用 `GET /api/v1/diaries/compression/stats` 验证压缩统计。

补完后验证北京大学校园内部道路图：

```powershell
psql -U postgres -d tourism_system -c "WITH target AS (SELECT scenic_spot_id AS id FROM graph_nodes WHERE source_ref LIKE 'pku:%' OR source_ref LIKE 'pku-curated:%' GROUP BY scenic_spot_id ORDER BY COUNT(*) DESC LIMIT 1) SELECT (SELECT COUNT(*) FROM graph_nodes n WHERE n.scenic_spot_id=t.id AND (n.source_ref LIKE 'pku:%' OR n.source_ref LIKE 'pku-curated:%')) AS pku_graph_nodes, (SELECT COUNT(*) FROM graph_nodes n WHERE n.scenic_spot_id=t.id AND (n.source_ref LIKE 'pku:%' OR n.source_ref LIKE 'pku-curated:%') AND n.node_type='building') AS building_nodes, (SELECT COUNT(*) FROM facilities f WHERE f.scenic_spot_id=t.id AND (f.source_ref LIKE 'pku:%' OR f.source_ref LIKE 'pku-curated:%') AND f.type <> 'building') AS service_facilities, (SELECT COUNT(DISTINCT f.type) FROM facilities f WHERE f.scenic_spot_id=t.id AND (f.source_ref LIKE 'pku:%' OR f.source_ref LIKE 'pku-curated:%') AND f.type <> 'building') AS service_facility_types, (SELECT COUNT(*) FROM graph_edges e JOIN graph_nodes a ON a.id=e.from_node JOIN graph_nodes b ON b.id=e.to_node WHERE a.scenic_spot_id=t.id AND b.scenic_spot_id=t.id AND (a.source_ref LIKE 'pku:%' OR a.source_ref LIKE 'pku-curated:%') AND (b.source_ref LIKE 'pku:%' OR b.source_ref LIKE 'pku-curated:%')) AS graph_edges FROM target t;"
```

补完后验证北大红楼室内导航数据：

```powershell
psql -U postgres -d tourism_system -c "SELECT b.scenic_spot_id, s.name, b.name, b.provider, (SELECT COUNT(*) FROM indoor_features f WHERE f.building_id = b.id) AS features FROM indoor_buildings b JOIN scenic_spots s ON s.id = b.scenic_spot_id;"
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
backend\build-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
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
backend\build-mingw\bin\tourism_server.exe --help
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
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_demo.sql
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
