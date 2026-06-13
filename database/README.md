# 数据库目录说明

这个目录只保留项目运行和数据维护需要的少量入口文件。

## 正式初始化文件

- `schema.sql`：完整建表脚本，包含景点、路线、游记、评论、收藏、评分、成就等结构。
- `imports/amap_pois.sql`：唯一正式景点来源，负责导入高德 POI 景点数据和可用图片。
- `imports/amap_pois_supplement.sql`：高德 POI 补充导入，补主导入缺失的北京核心地标（中国国家博物馆、军事博物馆、颐和园），幂等可重复执行。
- `internal_navigation_schema.sql`：景区内部设施、道路和路网表结构。
- `imports/internal_navigation.sql`：故宫、北海、奥林匹克森林公园等景区内部导航数据。
- `seeds/seed_campus_spots.sql`：北京大学校园主对象 seed，用于把校园作为 `scenic_spots` 中的正式对象接入系统。
- `imports/internal_navigation_pku.sql`：北京大学校园内部道路图，使用现有 `graph_nodes`、`graph_edges`、`facilities`，不新建第二套校园图表。
- `seeds/seed_pku_curated_map.sql`：北京大学校园人工校核连通主路网 seed，补足 OSM 内部路网碎片化导致的设施不可达问题；主路网来源标记为 `campus_curated`，设施接入短边标记为 `generated`。
- `indoor_navigation_schema.sql`：室内导航领域表结构，包含 `indoor_buildings`、`indoor_floors`、`indoor_features`、`indoor_edges` 和 `indoor_route_audit`。
- `seeds/seed_indoor_navigation.sql`：北大红楼首批正式室内图数据，使用 `local_indoor_graph` provider，不是独立数据库，也不是前端假 Demo。
- `migrations/achievement_module_schema.sql`：成就系统正式结构迁移，补齐成就编码、景点打卡、游记评审、实体徽章申请与数字纪念凭证相关表和索引。
- `migrations/diary_compression_schema.sql`：旅行日记 Huffman 压缩存储迁移，`travel_diaries` 增加 `content_compressed` 和 `content_original_bytes` 列。
- `migrations/cross_layer_navigation_schema.sql`：室内外跨层导航迁移，`indoor_buildings` 增加 `outdoor_node_id` 室外路网锚点并按名称自动绑定。
- `migrations/diary_location_cover_schema.sql`：日记地点与封面迁移，`travel_diaries` 增加 `cover_image`、`location_name`、`location_address`、`location_latitude`、`location_longitude`、`location_poi_id` 六列；存量日记封面自动用 `images[1]` 填充。
- `migrations/diary_animation_schema.sql`：日记动画预览迁移，`travel_diaries` 增加 `videos` 和 `animation_storyboard` 列。
- `migrations/scenic_search_indexes.sql`：景点/学校查询与排序索引迁移，启用 `pg_trgm` 并补充名称、描述、标签、类型和热度/评分排序索引。
- `seeds/seed_extra_users.sql`：补充演示用户，供多人互动和审核演示使用。
- `seeds/seed_facilities.sql`：补充景区设施数据。
- `seeds/seed_foods.sql`：补齐美食推荐依赖的餐饮设施数据。
- `seeds/seed_demo.sql`：基础演示关系数据，不再插入景点；它会按名称从 `scenic_spots` 动态查找景点 id，再插入路线、游记、评论、收藏和推荐标签数据。
- `seeds/seed_achievements.sql`：成就系统演示 seed，负责旅行护照、用户成就进度和数字纪念凭证示例数据。
- `verify_demo.sql`：初始化后检查核心表数据量。
- `migration.sql`：旧数据库升级参考；全新建库通常不需要执行。

`git pull` 不会自动更新本机 PostgreSQL；如果只拉代码但不执行对应 SQL 迁移和 seed，室内导航会显示“未接入”，路线规划也可能继续显示旧的演示直线。所有数据仍然进入唯一数据库 `tourism_system`。

全新数据库完整初始化顺序：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -f database\imports\amap_pois.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\amap_pois_supplement.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_campus_spots.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation_pku.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_pku_curated_map.sql
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

已有 lxd/yhm 数据库只补北京大学校园内部道路图：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\internal_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_campus_spots.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\internal_navigation_pku.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_pku_curated_map.sql
```

已有 lxd/yhm 数据库只补北大红楼室内导航：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\indoor_navigation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_indoor_navigation.sql
```

已有数据库只补成就系统结构与演示数据：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\achievement_module_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_achievements.sql
```

已有数据库只补日记相关迁移和室内外跨层导航（迁移都幂等，可放心重复执行）：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_compression_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_location_cover_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\diary_animation_schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\cross_layer_navigation_schema.sql
```

已有数据库只补景点/学校查询和排序索引（迁移幂等，可放心重复执行）：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\scenic_search_indexes.sql
```

已有数据库只补美食推荐演示数据：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_facilities.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_foods.sql
```

已有数据库只补路线规划演示路网和成就演示数据：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_demo.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seeds\seed_achievements.sql
```

说明：

- `seed_demo.sql` 现在只负责基础演示路线、游记、评论、收藏和推荐标签。
- `seed_achievements.sql` 单独负责旅行护照、数字纪念凭证和成就进度演示数据，更适合与创新功能分支并行维护。
- 如果只拉取了成就系统分支，至少要同步 `achievement_module_schema.sql` 和 `seed_achievements.sql`，否则 `/api/v1/achievements` 页面可能只显示示例护照或接口报表结构缺失。
- 如果路线页“拥挤度感知”模式仍画旧的节点直线，先重跑这条 SQL，再刷新页面验证。

补完后验证室内导航数据：

```bat
psql -U postgres -d tourism_system -c "SELECT b.scenic_spot_id, s.name, b.name, b.provider, (SELECT COUNT(*) FROM indoor_features f WHERE f.building_id = b.id) AS features FROM indoor_buildings b JOIN scenic_spots s ON s.id = b.scenic_spot_id;"
```

补完后验证北京大学校园内部道路图：

```bat
psql -U postgres -d tourism_system -c "WITH target AS (SELECT scenic_spot_id AS id FROM graph_nodes WHERE source_ref LIKE 'pku:%' OR source_ref LIKE 'pku-curated:%' GROUP BY scenic_spot_id ORDER BY COUNT(*) DESC LIMIT 1) SELECT (SELECT COUNT(*) FROM graph_nodes n WHERE n.scenic_spot_id=t.id AND (n.source_ref LIKE 'pku:%' OR n.source_ref LIKE 'pku-curated:%')) AS pku_graph_nodes, (SELECT COUNT(*) FROM graph_nodes n WHERE n.scenic_spot_id=t.id AND (n.source_ref LIKE 'pku:%' OR n.source_ref LIKE 'pku-curated:%') AND n.node_type='building') AS building_nodes, (SELECT COUNT(*) FROM facilities f WHERE f.scenic_spot_id=t.id AND (f.source_ref LIKE 'pku:%' OR f.source_ref LIKE 'pku-curated:%') AND f.type <> 'building') AS service_facilities, (SELECT COUNT(DISTINCT f.type) FROM facilities f WHERE f.scenic_spot_id=t.id AND (f.source_ref LIKE 'pku:%' OR f.source_ref LIKE 'pku-curated:%') AND f.type <> 'building') AS service_facility_types, (SELECT COUNT(*) FROM graph_edges e JOIN graph_nodes a ON a.id=e.from_node JOIN graph_nodes b ON b.id=e.to_node WHERE a.scenic_spot_id=t.id AND b.scenic_spot_id=t.id AND (a.source_ref LIKE 'pku:%' OR a.source_ref LIKE 'pku-curated:%') AND (b.source_ref LIKE 'pku:%' OR b.source_ref LIKE 'pku-curated:%')) AS graph_edges FROM target t;"
```

说明：北京大学校园内部道路图和北大红楼室内导航是两项不同能力。前者进入 `graph_nodes`、`graph_edges`、`facilities`，用于校园级道路图；后者进入 `indoor_*` 表，用于单体建筑室内拓扑。

## 数据维护文件

- `maintenance/audit_data_quality.sql`：只查询，不修改数据。用于检查字段、重复景点和缺图情况。
- `maintenance/repair_data_quality.sql`：会修改数据。用于清理安全重复项、合并子 POI、同步图片字段并使用本地 public 图片补图。

建议先运行审计脚本，确认结果后再运行修复脚本：

```bat
psql -U postgres -d tourism_system -f database\maintenance\audit_data_quality.sql
psql -U postgres -d tourism_system -f database\maintenance\repair_data_quality.sql
```

历史草稿、一次性报告和测试导入文件不再保留在仓库中；需要时可从 Git 历史找回。
