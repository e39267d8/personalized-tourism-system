# 数据库目录说明

这个目录只保留项目运行和数据维护需要的少量入口文件。

## 正式初始化文件

- `schema.sql`：完整建表脚本，包含景点、路线、游记、评论、收藏、评分、成就等结构。
- `imports/amap_pois.sql`：唯一正式景点来源，负责导入高德 POI 景点数据和可用图片。
- `internal_navigation_schema.sql`：景区内部设施、道路和路网表结构。
- `imports/internal_navigation.sql`：故宫、北海、奥林匹克森林公园等景区内部导航数据。
- `indoor_navigation_schema.sql`：室内导航领域表结构，包含 `indoor_buildings`、`indoor_floors`、`indoor_features`、`indoor_edges` 和 `indoor_route_audit`。
- `seed_indoor_navigation.sql`：北大红楼首批正式室内图数据，使用 `local_indoor_graph` provider，不是独立数据库，也不是前端假 Demo。
- `seed_demo.sql`：基础演示关系数据，不再插入景点；它会按名称从 `scenic_spots` 动态查找景点 id，再插入路线、游记、评论、收藏和成就数据。
- `verify_demo.sql`：初始化后检查核心表数据量。
- `migration.sql`：旧数据库升级参考；全新建库通常不需要执行。

`git pull` 不会自动更新本机 PostgreSQL；如果只拉代码但不执行对应 SQL 迁移和 seed，室内导航会显示“未接入”。所有数据仍然进入唯一数据库 `tourism_system`。

全新数据库完整初始化顺序：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
psql -U postgres -d tourism_system -f database\maintenance\repair_data_quality.sql
psql -U postgres -d tourism_system -f database\verify_demo.sql
```

已有 lxd/yhm 数据库只补室内导航：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_indoor_navigation.sql
```

补完后验证室内导航数据：

```bat
psql -U postgres -d tourism_system -c "SELECT b.scenic_spot_id, s.name, b.name, b.provider, (SELECT COUNT(*) FROM indoor_features f WHERE f.building_id = b.id) AS features FROM indoor_buildings b JOIN scenic_spots s ON s.id = b.scenic_spot_id;"
```

## 数据维护文件

- `maintenance/audit_data_quality.sql`：只查询，不修改数据。用于检查字段、重复景点和缺图情况。
- `maintenance/repair_data_quality.sql`：会修改数据。用于清理安全重复项、合并子 POI、同步图片字段并使用本地 public 图片补图。

建议先运行审计脚本，确认结果后再运行修复脚本：

```bat
psql -U postgres -d tourism_system -f database\maintenance\audit_data_quality.sql
psql -U postgres -d tourism_system -f database\maintenance\repair_data_quality.sql
```

历史草稿、一次性报告和测试导入文件不再保留在仓库中；需要时可从 Git 历史找回。
