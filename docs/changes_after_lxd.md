# 拉取 lxd 分支后的阶段改动记录

本文记录以 `lxd` 分支为继续开发基础后完成的一组阶段性改动。它是历史交接文档，不要以后每次拉分支都复制一份新文档；后续普通变更请追加到 `docs/engineering_log.md`。

## 基线理解

拉取 `lxd` 后，项目已经具备：

- Vue 3 前端，包含景点详情、景点搜索、路线规划、美食推荐、成就、游记、AI 助手等页面。
- C++ Crow 后端，并已按 route module 拆分。
- 唯一 PostgreSQL/PostGIS 数据库：`tourism_system`。
- 高德 POI 离线导入文件：`database/imports/amap_pois.sql`。
- 景区内部导航能力：基于 `facilities`、`graph_nodes`、`graph_edges`、OSM/Overpass 导入、高德 JS 地图展示和后端路线规划。

重要数据结论：

- 3476 条景点记录来自高德官方 API，一次性生成 SQL 后导入本地库。
- 系统运行时的景点页面主要读取本地 PostgreSQL，不是每次都实时请求高德 POI 搜索。
- 当前没有在高德导入外再维护第二套人工景点表。

## 为什么做这些改动

课设需要室内导航，但完整大规模室内地图建设成本太高。因此采用以下方向：

- 室内导航按正式工程能力建设。
- 首期只控制覆盖体量，不降低工程标准。
- 不做孤立假 Demo。
- 保持数据、provider、API、算法和审计边界清晰。
- 所有数据继续放在 `tourism_system`。

## 架构决策

室内导航采用 provider 模型：

- `amap_indoor`：预留给高德官方室内图能力，例如 `cpid`、楼层数据和后续浏览器侧室内路线接入。
- `local_indoor_graph`：当前实现的本地正式 provider，基于室内图表和后端 Dijkstra，是课设验收与答辩的稳定兜底。

首期实现北大红楼一个真实建筑的本地室内图，后续可继续扩展更多建筑。

## 数据库改动

新增室内导航领域表：

- `indoor_buildings`
- `indoor_floors`
- `indoor_features`
- `indoor_edges`
- `indoor_route_audit`

新增增量迁移：

- `database/indoor_navigation_schema.sql`

新增室内数据 seed：

- `database/seed_indoor_navigation.sql`

当前 seed 覆盖：

- 真实景点绑定：北大红楼。
- 室内建筑：北大红楼主楼。
- 楼层：F1、F2。
- 室内节点：10 个。
- 有向边：18 条。
- Provider：`local_indoor_graph`。
- 数据来源：`manual-curated`。

所有室内数据行都带有：

- `provider`
- `source`
- `source_ref`
- `created_at`
- `updated_at`

seed 通过名称和小范围坐标兜底绑定到已有高德 POI。如果找不到目标 POI，会抛出明确 SQL 错误，避免静默绑定到错误景点。

## 后端改动

主要文件：

- `backend/src/api/scenic_routes.cpp`

新增室内导航 API：

```text
GET  /api/v1/scenic-spots/:id/indoor-buildings
GET  /api/v1/indoor-buildings/:id/features
POST /api/v1/indoor-buildings/:id/routes/plan
```

路线规划行为：

- 读取 `indoor_features` 和 `indoor_edges`。
- 校验起点和终点属于同一室内建筑。
- 在后端运行 Dijkstra。
- `strategy=time` 使用 `travel_time` 作为权重。
- `strategy=distance` 使用 `distance` 作为权重。
- 返回 provider、configured provider、algorithm、distance、duration、path、steps 和 fallback 状态。
- 将路线请求写入 `indoor_route_audit`。

当前实现：

```text
algorithm = indoor-dijkstra
provider = local_indoor_graph
```

## 前端改动

主要文件：

- `frontend/src/services/tourismApi.js`
- `frontend/src/views/ScenicDetail.vue`
- `frontend/src/components/IndoorNavigationPanel.vue`

景点详情页新增室内导航区域。

第一版能力：

- 无室内数据时显示空状态。
- 查询室内建筑、楼层、节点和类型。
- 选择起点、终点和时间/距离策略。
- 展示路线距离、耗时、算法、provider、兜底状态和步骤。

后续重构能力：

- 从“数据库查询表单”改为“SVG 室内拓扑图 + 路由控制台”。
- 用 `features.x/y/floorCode` 绘制节点。
- 用 `edges` 绘制拓扑边。
- 规划后高亮路径节点和路径边。
- 支持楼层切换、跨楼层提示和搜索式起终点选择。

核心路线规划不在前端实现。

## 中文化改动

为避免页面出现英文节点名，本阶段进一步完成：

- `database/seed_indoor_navigation.sql` 的建筑、楼层、节点名称改为中文。
- 后端室内节点类型、边类型、路线步骤说明改为中文。
- 前端 provider、算法、策略、耗时、步骤说明改为中文展示。
- 文档默认改为中文；技术契约字段保留英文。

说明：页面中曾出现的 `Main Entrance`、`Ticket And Service Desk` 等名称不是高德实时返回，而是我们最初写在本地室内图 seed 里的英文节点名。

## 数据库设置与导入顺序

`git pull` 只会更新代码和 SQL 文件，不会更新队友本机 PostgreSQL。若没有执行室内导航迁移和 seed，页面会正确显示“未接入”，这不是前端故障。

全新数据库导入顺序：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

已有 `lxd` 数据库只补室内导航：

```powershell
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

## 验证命令

确认室内 seed 位于同一个数据库：

```powershell
psql -U postgres -d tourism_system -c "SELECT b.id, b.scenic_spot_id, s.name AS scenic_spot, b.name AS indoor_building, b.provider, (SELECT COUNT(*) FROM indoor_features f WHERE f.building_id = b.id) AS features FROM indoor_buildings b JOIN scenic_spots s ON s.id = b.scenic_spot_id;"
```

预期能看到类似结果：

```text
北大红楼 / 北大红楼主楼 / local_indoor_graph / 10 features
```

后端启动后验证 API：

```powershell
Invoke-WebRequest http://127.0.0.1:8080/api/v1/scenic-spots/39/indoor-buildings
Invoke-WebRequest http://127.0.0.1:8080/api/v1/indoor-buildings/1/features
```

如果 SQL 查询得到的 `scenic_spot_id` 不是 39，就用实际 id 打开 `/spots/:id`。

构建与静态检查：

```powershell
cmake --build backend\build-codex-verify-mingw --target tourism_server --config Debug --parallel 2

cd frontend
npm.cmd run lint
npm.cmd run build
```

## 协作规则

硬规则：

- 只使用 `tourism_system`。
- 不新增第二套景点表。
- 不新增第二套用户表。
- 不重复开发路线规划职责。
- 前端不绕过 `tourismApi.js` 调后端。
- 不在 Vue 组件里实现核心 Dijkstra/路线算法。
- 每条导入或人工整理数据都要有清晰来源。
- 每个 provider 专属能力都要说明 provider 边界。
- 新增/修改文档默认使用中文。

推荐流程：

1. 改数据前先查 `database/schema.sql`、现有迁移文件和 seed 文件。
2. 新增表结构写增量迁移。
3. 新增 seed/import 文件使用稳定 `source_ref` upsert。
4. 重大设计写 ADR；普通工程变化追加到 `docs/engineering_log.md`。
5. PR 或提交说明里写清楚改动范围和验证结果。

## 剩余工作

- 根据真实可用 `cpid` 增加第二个室内建筑。
- 后续接入 `amap_indoor` 的高德室内图展示。
- 为后端 API 增加更稳定的自动化冒烟测试。
- 继续优化 SVG 拓扑图的节点布局和路线说明。

## 答辩表述

简短版本：

> 我们使用高德官方 POI 作为离线数据源，3476 条景点数据先生成 SQL 再导入 PostgreSQL，因此运行时主要读本地库。室内导航采用正式 provider 模型：`amap_indoor` 预留给高德官方室内图能力，`local_indoor_graph` 提供稳定的本地图 Dijkstra 实现。首期只覆盖北大红楼一个真实建筑，但数据库、API、provider 字段、审计记录和拓扑可视化都按可扩展功能建设。
