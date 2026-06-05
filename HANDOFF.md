# HANDOFF

## 1. 当前目标

实现景区内部设施导航：在景点详情页展示内部道路、设施点、可导航设施，并支持从入口、下拉起点、地图点选起点规划到设施的步行路线。

当前用户最新反馈是：现有 OSM/内部示意底图太难看懂，路线面板暴露了太多技术概念，例如 OSM 节点名、虚线、接入段。下一步目标应转向“用户能看懂的地图和路线”：

- 使用高德实际地图作为前端底图展示。
- 后端仍保持 WGS84 + OSM 路网做严格导航。
- 前端负责 WGS84/GCJ-02 坐标转换，以保证标点和路线贴合高德底图。
- 隐藏或弱化“接入段/虚线/OSM 节点”等技术细节。
- 默认只展示可导航设施，让用户明确知道哪些能规划路线。

## 2. 已经修改了哪些文件

### 已修改 tracked 文件

- `AGENTS.md`
- `README.md`
- `backend/include/services/route_graph_service.h`
- `backend/src/api/auth_routes.cpp`
- `backend/src/api/scenic_routes.cpp`
- `backend/src/services/route_graph_service.cpp`
- `frontend/package.json`
- `frontend/src/router/index.js`
- `frontend/src/services/tourismApi.js`
- `frontend/src/stores/auth.js`
- `frontend/src/views/Login.vue`
- `frontend/src/views/Register.vue`
- `frontend/src/views/ScenicDetail.vue`

### 新增 untracked 文件

- `database/internal_navigation_schema.sql`
- `database/imports/internal_navigation.sql`
- `scripts/import_internal_map_data.py`
- `scripts/smoke_auth.ps1`
- `frontend/scripts/run-auth-tests.mjs`
- `frontend/src/utils/auth.js`
- `HANDOFF.md`

## 3. 每个文件改了什么

### `AGENTS.md`

- 增加 OSM/Overpass 内部地图导入说明。
- 增加内部导航数据库文件说明。
- 增加内部导航导入命令。
- 说明当前内部导航数据统一存 WGS84。
- 说明当前前端仍使用 OSM/WGS84 瓦片，并在瓦片失败时降级为内部示意图。

### `README.md`

- 增加 `internal_navigation_schema.sql` 和 `internal_navigation.sql` 的导入步骤。
- 增加“景区内部设施导航数据”说明。
- 记录导入脚本命令：
  `py scripts\import_internal_map_data.py --amap-pages 1 --max-edges-per-spot 2000 --connector-max-distance 60 --output database\imports\internal_navigation.sql`
- 说明 OSM/Overpass、AMap POI、WGS84/GCJ-02 转换、60m 接入阈值。
- 当前 README 仍描述“前端使用 OSM/WGS84 坐标”，这和用户最新希望“高德实际地图”不一致，下一步需要更新。

### `database/internal_navigation_schema.sql`

- 为 `facilities` 增加：
  - `scenic_spot_id`
  - `source`
  - `source_ref`
  - `source_tags`
- 为 `graph_nodes` 增加：
  - `source`
  - `source_ref`
  - `source_tags`
- 为 `graph_edges` 增加：
  - `geometry`
  - `source`
  - `source_ref`
  - `source_tags`
- 增加相关索引和唯一索引。

### `database/imports/internal_navigation.sql`

- 生成好的内部导航 SQL，约 8MB。
- 包含景区内部设施、OSM 路网节点/边、生成的设施到道路 connector。
- 当前文件内容经 Python UTF-8 读取确认中文是正常的；PowerShell `Get-Content` 可能显示乱码，但不是文件本身一定损坏。

### `scripts/import_internal_map_data.py`

- 新增内部地图数据生成脚本。
- 从 Overpass 拉取 OSM 内部道路、建筑、入口等。
- 从 AMap Web Service 拉取周边设施 POI。
- 高德查询时将 WGS84 中心点转 GCJ-02，请求结果再从 GCJ-02 转回 WGS84 入库。
- `source_tags` 记录原始高德坐标和转换后坐标。
- OSM 道路节点按坐标精度去重。
- 默认 connector 最大距离为 60m，超过阈值不接入。
- 生成 SQL 到 `database/imports/internal_navigation.sql`。

### `backend/include/services/route_graph_service.h`

- `RouteNode` 增加 scenic/facility 相关字段。
- `RouteEdge` 增加 `source` 和 `coordinates`。
- `load_route_graph` 支持按 `scenic_spot_id` 加载。

### `backend/src/services/route_graph_service.cpp`

- 加载图数据时支持 scenic spot 过滤。
- 加载边 geometry 坐标。
- 路线 JSON 新增 `pathEdges`。
- `coordinates` 改为按边真实 geometry 拼接，而不是只用节点直线。
- route segment/path edge 增加 `source`，用于区分 OSM 真实道路和 generated connector。

### `backend/src/api/scenic_routes.cpp`

- 新增内部导航 API：
  - `GET /api/v1/scenic-spots/<id>/facilities`
  - `GET /api/v1/scenic-spots/<id>/internal-map`
  - `POST /api/v1/scenic-spots/<id>/internal-routes/plan`
- `/facilities` 返回设施类型、坐标、`routable`、`connectorDistanceMeters`。
- 可导航设施排序靠前。
- 地图点选起点只吸附到真实 OSM 道路节点，超过 60m 返回 422。
- 设施未接入真实路网返回 422。
- 不再生成虚假的直线兜底路线。
- 路线响应增加 `routeQuality`。

### `frontend/src/services/tourismApi.js`

- 新增内部导航 API client：
  - `scenicFacilities`
  - `scenicInternalMap`
  - `planScenicInternalRoute`
- 同时有 auth 拦截器相关改动：安全重定向、401 处理、防 SSR/localStorage 报错。

### `frontend/src/views/ScenicDetail.vue`

- 新增“景区设施导航”模块。
- 使用 Leaflet 渲染内部地图。
- 当前底图仍是 OSM：
  `https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png`
- 支持在线瓦片加载失败时显示浅灰网格内部示意底图。
- 绘制内部 OSM 路网、设施点、起点 marker、路线。
- 支持起点模式：
  - 自动入口
  - 下拉选择
  - 地图点选
- 默认优先选择可导航设施。
- 不可导航设施置灰，并在下拉中标注“未接入路网”。
- 当前仍显示“虚线为设施接入段”“接入段”等技术提示，这是用户最新不满意的重点。

### Auth 相关文件

这些可能是之前并行/遗留改动，和内部导航不是同一个目标：

- `backend/src/api/auth_routes.cpp`
  - 增加用户名/邮箱/密码校验。
  - 增加登录失败次数限制。
  - 清理过期/撤销 token。
- `frontend/src/utils/auth.js`
  - 新增 `safeRedirectPath`
  - 新增登录/注册表单校验
  - 新增 `isAuthApiPath`
- `frontend/src/router/index.js`
  - 登录/注册页重定向改用 `safeRedirectPath`。
- `frontend/src/stores/auth.js`
  - localStorage 读写封装。
- `frontend/src/views/Login.vue`
  - 增加 maxlength、表单校验、防重复提交、安全 redirect。
- `frontend/src/views/Register.vue`
  - 增加 maxlength、表单校验、防重复提交、安全 redirect。
- `frontend/package.json`
  - `npm test` 改为 `node scripts/run-auth-tests.mjs`。
- `frontend/scripts/run-auth-tests.mjs`
  - 新增 auth 工具/状态测试。
- `scripts/smoke_auth.ps1`
  - 新增后端 auth smoke test。

## 4. 当前还没完成什么

- 还没有把景区内部导航底图切到高德实际地图。
- 还没有在前端做 WGS84/GCJ-02 双向转换：
  - DB/API 仍返回 WGS84。
  - 如果换高德底图，前端展示前必须 WGS84 -> GCJ-02。
  - 地图点选起点时必须 GCJ-02 -> WGS84 再发给后端。
- 路线展示仍偏技术/debug：
  - 仍显示 OSM 节点名。
  - 仍显示“接入段”。
  - 仍解释虚线/实线。
- 地图视觉仍难懂：
  - 点太密。
  - 内部线条缺少真实底图上下文。
  - 用户不知道哪些点可以规划。
- 需要重新设计前端 UX：
  - 默认只看可导航设施。
  - 非可导航设施放到“显示全部设施”开关后面。
  - 路线面板只显示用户语言，例如“从入口步行约 X 米，预计 Y 分钟”。
  - 技术 pathEdges/routeQuality 可放到折叠的“调试信息”里，默认隐藏。
- README/AGENTS 还需要按最终方案更新为“高德底图展示 + 后端 WGS84 路由”。

## 5. 已知 bug / 报错

- 用户反馈当前地图“很难看懂”，这是当前最大 UX 问题。
- 用户反馈不能理解“虚线/接入段”，需要从默认 UI 中移除这类技术概念。
- 当前前端仍使用 OSM 底图，不符合用户希望“在高德实际地图基础上标点以及连线”的方向。
- 如果直接切高德底图但不做坐标转换，会出现标点/路线偏移。
- PowerShell `Get-Content` 在当前终端中可能把 UTF-8 中文显示成乱码；用 Python `Path.read_text(encoding='utf-8')` 检查，文件实际中文可正常读取。
- 当前工作区有大量未提交改动，且包含内部导航和 auth 两组不同主题，下一步提交前需要拆分或确认范围。

## 6. 下一步应该从哪里继续

建议从 `frontend/src/views/ScenicDetail.vue` 继续，先做用户可见体验：

1. 新增前端坐标转换工具，例如：
   - `wgs84ToGcj02`
   - `gcj02ToWgs84`

2. 将内部导航地图底图从 OSM 切到高德瓦片：
   - 展示时把设施、道路、路线坐标从 WGS84 转 GCJ-02。
   - 点选地图起点时把高德底图上的 GCJ-02 坐标转回 WGS84，再调用后端规划接口。

3. 简化路线 UI：
   - 默认不展示 OSM 节点名。
   - 默认不展示“接入段/虚线”。
   - 路线统一画成一条用户能理解的步行路线。
   - `pathEdges` 和 `routeQuality` 只作为内部数据或折叠调试信息。

4. 简化设施 UI：
   - 默认只显示可导航设施。
   - 下拉框只列可导航设施。
   - 增加“显示全部设施”开关。
   - 不可导航设施只作为灰色参考点，不参与路线规划。

5. 最后再更新 `README.md` 和 `AGENTS.md`：
   - 说明 DB/API 统一 WGS84。
   - 说明前端高德底图展示使用 GCJ-02。
   - 说明点选起点需要前端转回 WGS84。

## 7. 需要运行的测试命令

### Python 脚本语法

```powershell
py -m py_compile scripts\import_internal_map_data.py
```

### 前端

```powershell
cd frontend
npm.cmd run lint
npm.cmd run build
npm.cmd test
```

### 后端

```powershell
cmake -S backend -B backend\build-codex-verify-mingw
cmake --build backend\build-codex-verify-mingw
```

### 数据库导入

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
```

### 重新生成内部导航数据

```powershell
py scripts\import_internal_map_data.py --amap-pages 1 --max-edges-per-spot 2000 --connector-max-distance 60 --output database\imports\internal_navigation.sql
```

### 后端 smoke test

```powershell
backend\build-codex-verify-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
Invoke-WebRequest http://127.0.0.1:8080/health
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/scenic-spots/4/facilities?limit=5"
Invoke-WebRequest "http://127.0.0.1:8080/api/v1/scenic-spots/4/internal-map"
```

### Auth smoke test

```powershell
.\scripts\smoke_auth.ps1 -BaseUrl "http://127.0.0.1:8080"
```

### 前端手测重点

- 打开景点详情页。
- 确认高德底图、设施点、路线三者没有坐标偏移。
- 默认设施列表只显示可导航设施。
- 地图点选起点后 marker 清楚，地图不乱跳。
- 规划路线后不再出现用户难懂的“OSM 路口”“接入段”“虚线说明”。
- 不可达设施只提示不可导航，不生成假直线。
