# 室内导航与真实数据规则

## 数据基线

- 景点数据来自高德开放平台 POI 结果，并已生成到 `database/imports/amap_pois.sql`。
- 这些数据是“一次性获取后离线入库”的模式；系统运行时主要读取本地 PostgreSQL，而不是每次打开页面都实时请求高德 POI 搜索。
- 唯一运行数据库是 `tourism_system`。
- 高德导入文件当前约包含 3476 条 `scenic_spots` 插入记录。
- 当前没有再单独维护第二套人工景点表。以后如果补人工景点，也必须明确 `source` 和 `source_ref`。

这个流程和“爬取后入库”的工程性质很接近，但数据源是高德官方 API，字段更规整，也更容易在答辩时说明合规来源。

## 室内导航策略

室内导航是正式功能，首期只是控制覆盖体量，不做一次性假 Demo。

Provider 边界：

- `amap_indoor`：优先预留给高德官方室内图能力，包括 `indoor_map`、`cpid`、楼层数据和浏览器侧室内路线能力。
- `local_indoor_graph`：本地正式 provider，用于稳定演示、算法答辩，以及高德室内数据缺失或不可用时的兜底。

首期策略：

- 选择一个真实景点建筑，建立小规模但正式的本地室内图。
- 保留正式 schema、API、provider 字段、审计字段和算法路径，后续新增建筑不需要重构。
- 在 `indoor_buildings` 中保留高德室内能力相关字段，后续接入官方 provider 时不用重新设计表结构。

## 数据库规则

硬规则：只使用 `tourism_system`。

室内导航表属于同一个数据库内的领域表：

- `indoor_buildings`
- `indoor_floors`
- `indoor_features`
- `indoor_edges`
- `indoor_route_audit`

每条新增室内数据必须包含：

- `source`
- `source_ref`
- `provider`
- `created_at`
- `updated_at`

禁止新增：

- 第二个数据库。
- 第二套景点表。
- 第二套用户表。
- 与现有职责重复的路线表或路线算法入口。

## API 契约

前端所有调用统一走 `frontend/src/services/tourismApi.js`。

### 查询室内建筑

`GET /api/v1/scenic-spots/:id/indoor-buildings`

返回该景点下的室内导航建筑，核心字段包括：

- `provider`
- `hasIndoorMap`
- `amapCpid`
- `floorCount`
- `featureCount`

### 查询室内节点

`GET /api/v1/indoor-buildings/:id/features?floor=F1&type=toilet`

返回设施、房间、展厅、楼梯、电梯、入口等可导航节点。`floor` 和 `type` 是可选筛选条件，不是规划路线的前置条件。

响应包含：

- `items`：节点，来自 `indoor_features`。
- `floors`：楼层，来自 `indoor_floors`。
- `types`：节点类型统计。
- `edges`：拓扑边，来自 `indoor_edges`。

### 规划室内路线

`POST /api/v1/indoor-buildings/:id/routes/plan`

请求体：

```json
{
  "startFeatureId": 101,
  "endFeatureId": 208,
  "strategy": "time"
}
```

响应体：

```json
{
  "provider": "local_indoor_graph",
  "configuredProvider": "local_indoor_graph",
  "algorithm": "indoor-dijkstra",
  "distanceMeters": 180,
  "durationSeconds": 240,
  "steps": [],
  "path": [],
  "fallbackUsed": false
}
```

## 算法规则

- 核心室内路线规划放在后端。
- 前端可以选择建筑、楼层、起点、终点和策略，但不能实现核心路线算法。
- `local_indoor_graph` 在 `indoor_edges` 上运行 Dijkstra。
- `strategy=time` 使用 `travel_time` 作为边权重。
- `strategy=distance` 使用 `distance` 作为边权重。
- 跨楼层通过 `elevator` 或 `stairs` 类型边表达，并为跨层边设置合理时间成本。

## 数据核查口径

不使用独立核查脚本作为正式流程。核查以 SQL 文件、数据库导入顺序和 PostgreSQL 查询结果为准。

常用检查：

```powershell
psql -U postgres -d tourism_system -c "SELECT COUNT(*) AS scenic_spot_count FROM scenic_spots;"
psql -U postgres -d tourism_system -c "SELECT b.id, s.name AS scenic_spot, b.name AS indoor_building, b.provider, (SELECT COUNT(*) FROM indoor_features f WHERE f.building_id = b.id) AS feature_count FROM indoor_buildings b JOIN scenic_spots s ON s.id = b.scenic_spot_id;"
psql -U postgres -d tourism_system -c "SELECT building_id, COUNT(*) AS edge_count FROM indoor_edges GROUP BY building_id ORDER BY building_id;"
```

答辩口径：

- 3476 条景点来自高德 API 的一次性离线入库。
- 运行时景点页面主要读取本地库，不依赖每次实时调用高德 POI 搜索。
- 室内导航采用正式 provider fallback 结构。
- 本地图 provider 使用 Dijkstra，可展示节点、边、跨楼层路径和权重策略。
- 首期室内覆盖体量小，但工程接口可扩展。

## 开发顺序

1. 改数据前先确认现有 schema、导入 SQL 和目标数据库。
2. 只在现有数据库中新增或更新表结构。
3. seed/import SQL 必须使用稳定 `source_ref` 做 upsert。
4. 后端 API 放入匹配的 route module。
5. 前端调用统一通过 `tourismApi.js`。
6. UI 必须同时处理“有数据”和“无数据”状态。
7. provider 行为或 schema 改变时更新本文和 `docs/engineering_log.md`。

## 验收清单

- 景点 POI 数量大于 200。
- 所有项目数据都在 `tourism_system`。
- 至少一个真实景点存在室内建筑记录。
- 有室内数据的建筑能返回节点和边。
- 有室内边的建筑能规划路线。
- 无室内数据的景点返回空状态或明确错误，不崩溃。
- 路线响应包含 provider、configured provider、algorithm、distance、duration、steps、path 和 fallback 状态。
