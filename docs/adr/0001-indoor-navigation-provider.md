# 0001 室内导航 Provider 模型

状态：已接受

日期：2026-06-09

## 背景

课设需要室内导航，但在当前规模下做完整的大型室内地图产品成本过高。与此同时，室内导航不能做成前端假 Demo，必须具备正式的数据模型、后端路线规划、provider 边界和可答辩的算法说明。

项目已有唯一运行数据库 `tourism_system`，景点主数据来自 `database/imports/amap_pois.sql` 中的高德 POI 离线导入。

## 决策

室内导航采用 provider 模型：

- `amap_indoor`：预留给高德官方室内图能力，例如 `cpid`、楼层数据和后续室内 `routePath` 接入。
- `local_indoor_graph`：当前已实现的本地 provider，使用室内图表和后端 Dijkstra 在 `indoor_edges` 上计算路线。

所有室内导航数据都保存在现有 `tourism_system` 数据库中。首期可以只覆盖少量真实建筑，但必须使用正式的表结构、API、数据来源字段、provider 字段和验证规则。

## 影响

- 高德室内数据是否可用不会阻塞课设验收。
- 答辩时可以同时讲清“官方 provider 接入边界”和“本地图算法兜底”。
- 后续增加建筑时，只需要继续插入室内建筑、楼层、节点和边，不需要重做 API。
- 队友拉取代码后，如果本地 PostgreSQL 没有更新，必须手动执行室内导航迁移和 seed SQL。
