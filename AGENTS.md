# AGENTS.md

本文件给 AI agent 和协作开发者快速理解仓库使用。保持简洁、最新、可执行。

## 语言规范

- 新增或修改的项目文档默认使用中文。
- 用户可见页面文案默认使用中文。
- API 路径、JSON 字段、表名、provider 名、算法标识、环境变量等技术契约可以保留英文。
- 不要恢复旧的乱码文本；如果必须触碰乱码字符串，直接替换为干净的 UTF-8 中文。

## 项目快照

TourPilot 是个性化旅游规划系统。

- 前端：Vue 3、Vite、Vue Router、Tailwind CSS、Axios、Leaflet，高德 JS API 用于景区内部导航展示。
- 后端：C++17、Crow、PostgreSQL/libpq、CMake。
- 数据库：PostgreSQL + PostGIS。
- 外部服务：DeepSeek 兼容聊天 API、高德 Web Service、高德 JS API、OpenStreetMap/Overpass。

DeepSeek key 必须放在环境变量中。后端内置一个免费的高德 Web Service 默认 key，可用 `AMAP_WEB_SERVICE_KEY` 或 `AMAP_KEY` 覆盖。前端高德 JS API loader 也有内置免费 key，可用 `VITE_AMAP_JS_KEY` 和可选的 `VITE_AMAP_SECURITY_JS_CODE` 覆盖。

## 主要入口

前端：

- `frontend/src/main.js`：创建 Vue app，安装 router，导入 Tailwind 和 Leaflet CSS。
- `frontend/src/App.vue`：根布局、顶部导航、全局搜索和 `<router-view />`。
- `frontend/src/router/index.js`：SPA 路由表。
- `frontend/src/services/tourismApi.js`：唯一主力前端 API 客户端。
- `frontend/src/stores/auth.js`：登录状态、token 持久化、当前用户。
- `frontend/src/views/TravelAgent.vue`：真实 API 支撑的 AI 旅行助手。
- `frontend/src/views/RoutePlan.vue`：Leaflet 地图和路线规划页。
- `frontend/src/views/FoodRecommend.vue`：美食推荐页。
- `frontend/src/views/Achievements.vue`：旅行护照/成就总览页。
- `frontend/src/views/CollectibleDetail.vue`：数字纪念凭证页。
- `frontend/src/components/IndoorNavigationPanel.vue`：室内拓扑图、起终点选择和路线结果。
- `frontend/src/services/amapLoader.js`：高德 JS API loader。
- `frontend/src/utils/coordinates.js`：WGS84/GCJ-02 坐标转换。
- `frontend/src/utils/images.js`：图片选择和占位图。
- `frontend/src/data/imageCatalog.js`：本地拼音图片目录。

后端：

- `backend/src/main.cpp`：只负责启动和注册 route module。
- `backend/include/api/app.h`：共享 Crow app 类型。
- `backend/src/api/*_routes.cpp`：接口路由模块。
- `backend/src/services/*_service.cpp`：业务逻辑和外部服务。
- `backend/src/services/auth_service.cpp`：密码哈希和 Bearer token 查找。
- `backend/src/services/achievement_service.cpp`：旅行护照成就、打卡、纪念凭证、徽章兑换和轻量审核。
- `backend/src/db/postgres.cpp`：PostgreSQL 连接和查询辅助。
- `backend/src/support/api_helpers.cpp`：响应、参数和 header 辅助。

数据库：

- `database/schema.sql`
- `database/imports/amap_pois.sql`
- `database/internal_navigation_schema.sql`
- `database/imports/internal_navigation.sql`
- `database/seeds/seed_campus_spots.sql`
- `database/imports/internal_navigation_pku.sql`
- `database/indoor_navigation_schema.sql`
- `database/migrations/beijing_ticket_price_correction.sql`
- `database/migrations/diary_compression_schema.sql`
- `database/migrations/diary_compression_legacy_cleanup.sql`
- `database/migrations/diary_location_cover_schema.sql`
- `database/migrations/diary_animation_schema.sql`
- `database/migrations/cross_layer_navigation_schema.sql`
- `database/migrations/route_tiantan_global_node.sql`
- `database/migrations/route_global_osm_stitch_schema.sql`
- `database/seeds/seed_demo.sql`
- `database/seeds/seed_indoor_navigation.sql`
- `database/seeds/seed_facilities.sql`
- `database/seeds/seed_foods.sql`
- `database/verify_demo.sql`
- `scripts/import_internal_map_data.py`：从 OSM/Overpass 和高德附近设施生成景区内部导航 SQL。数据库中几何统一存 WGS84；高德 POI 查询先用 GCJ-02，请求结果再转回 WGS84 入库。

文档：

- `README.md`：项目总览和文档入口。
- `QUICKSTART.md`：最小本地启动和数据库初始化步骤。
- `docs/api-runtime.md`：当前真实运行 API 文档。
- `docs/engineering_log.md`：按时间记录重要工程变化，普通协作变更追加这里。
- `docs/adr/`：架构决策记录，用于解释重大设计取舍。

文档职责：

- README 只放项目总览和文档导航，不放运行手册、阶段变更流水或专题实现细节。
- QUICKSTART 只放本地运行、数据库初始化和验证命令。
- AGENTS 只放给开发者/AI 的工程规则、数据边界和协作约束。
- 普通工程变更统一追加到 `docs/engineering_log.md`。
- 重大技术决策单独写到 `docs/adr/`，例如室内导航 provider 取舍。
- 数据库变更以 SQL 迁移、seed 和 import 文件为准，不把个人核查脚本作为正式流程。
- 不要每拉取一个分支就新建 `changes_after_xxx.md` 之类的阶段文档。

## 后端模块

- `dashboard_routes`：`/health`、`/`、`/api/v1/dashboard`、`/api/v1/achievements`，以及成就打卡、领取、纪念凭证、徽章兑换和审核接口。
- `auth_routes`：登录、注册、退出、当前用户、修改密码。
- `profile_routes`：`/api/v1/profile`、`/api/v1/profile/preferences`。
- `scenic_routes`：景点列表、搜索、详情、分类、建议词、评价、景区内部导航 API、室内导航 API。
- `recommendation_routes`：预算方案和个性化推荐。
- `route_routes`：路线节点、路线列表、路线规划。
- `diary_routes`：游记、点赞、收藏、评分、评论、存量压缩迁移、检索、成就审核提交。
- `diary_animation_routes`：日记动画分镜生成与保存。
- `diary_compression_routes`：日记压缩统计与单篇压缩详情。
- `huffman_routes`：Huffman 压缩/解压工具接口。
- `aigc_routes`：游记摘要、润色、旅行聊天。
- `food_routes`：`/api/v1/foods` 和 `/api/v1/foods/cuisines`。

新增 API 时放到匹配的 `backend/src/api/*_routes.cpp`，不要让 `main.cpp` 重新变大。

## 前端路由

- `/`：`Home.vue`
- `/login`：`Login.vue`
- `/register`：`Register.vue`
- `/search`：`Search.vue`
- `/spots/:id`：`ScenicDetail.vue`
- `/recommend`：`Recommendation.vue`
- `/route`：`RoutePlan.vue`
- `/agent`：`TravelAgent.vue`
- `/diary`：`Diary.vue`
- `/diary/new`：`DiaryEditor.vue`
- `/diary/edit/:id`：`DiaryEditor.vue`
- `/diary/:id`：`DiaryDetail.vue`
- `/achievements`：`Achievements.vue`
- `/collectibles/:id`：`CollectibleDetail.vue`
- `/food`：`FoodRecommend.vue`
- `/profile`：`Profile.vue`

## 室内导航规则

- 唯一运行数据库是 `tourism_system`，不要为室内导航创建第二个数据库。
- 高德景点 POI 从 `database/imports/amap_pois.sql` 离线导入本地 PostgreSQL；运行时景点页面应读本地表，不要每次页面加载都调用高德 POI 搜索。
- 室内导航领域表：`indoor_buildings`、`indoor_floors`、`indoor_features`、`indoor_edges`、`indoor_route_audit`。
- Provider 必须明确：`amap_indoor` 用于高德官方室内图能力，`local_indoor_graph` 用于本地图兜底和算法答辩。
- 所有室内数据行必须有 `source`、`source_ref` 和 `provider`；seed/import SQL 使用稳定 `source_ref` upsert。
- 前端调用必须走 `frontend/src/services/tourismApi.js`，不要在 Vue 组件里绕过后端。
- 核心室内路线规划不能放在前端。当前本地室内路线是后端在 `indoor_edges` 上跑 Dijkstra。
- 室内/内部导航 API 应收敛到对应 navigation route module；如果还在整理中，迁移时必须保持所有公开路径不变。
- 首期覆盖可以小，但必须正式。一个真实建筑可以接受，前提是 schema、API、provider fallback、审计记录和可视化路线完整。
- 数据核查以 SQL 导入文件和 PostgreSQL 查询为准，不再使用独立核查脚本作为正式流程。

## 景区内部导航规则

- 内部导航数据来自 OSM/Overpass 路网、建筑、入口，以及高德附近设施 POI。
- 数据库/API 几何统一存 WGS84；高德地图展示前由前端转 GCJ-02，地图点选起点再转回 WGS84 调后端。
- 内部路线必须包含真实 OSM 道路/路径边；生成的设施接入边只允许在配置阈值内使用。
- 无法接入路网的设施应返回明确错误，不要用直线假路线。
- 不要把 OSM 节点名、接入段等底层概念放大成主要用户文案。
- 校园内部道路图也使用 `graph_nodes`、`graph_edges`、`facilities`，不要新建第二套校园图表。
- `database/imports/internal_navigation_pku.sql` 是北京大学校园内部道路图；`database/seeds/seed_indoor_navigation.sql` 是北大红楼室内拓扑，两者不是同一项能力，不能相互替代。
- PKU 校园图按 `scripts/pku_campus_spots.json` 的燕园主校区边界过滤，避免把清华或中关村周边 POI 算入北京大学校园。

## 美食推荐规则

- `/api/v1/foods` 支持 `scenic_spot_id`、`q`、`cuisine`、`sort=hot|rating|distance`、`lat/lng` 和 `limit`。
- 景点和学校共用 `scenic_spots` 口径；高校校园（如北京大学）通过分类/标签识别，前端统一显示为“景点 / 学校”位置筛选。
- 美食候选来自 `facilities` 中 `restaurant`、`cafe`、`fast_food` 类型。
- 菜系由 C++ 优先读取导入元数据 `source_tags.cuisine`，再从设施名称推断。模糊搜索匹配名称、菜系 key/label、地址和景点/学校名称。
- `sort=hot` 使用派生分数，不是数据库字段：评分 50%、信息完整度 20%、价格友好 15%、类型/名称可信度 15%。
- `sort=distance` 需要 `lat/lng` 或 `scenic_spot_id` 提供参考点；没有参考点时后端降级为 `hot`，前端应避免误导用户。
- 排名使用 `TopKSelector` 先保留前 K 个结果，再做最终有序返回。

## 成就与纪念凭证规则

- V1 成就体验是公开旅行护照 `/achievements`；未登录用户看示例，登录用户看保存进度。
- 受保护动作包括景点打卡、成就领取、纪念凭证、徽章兑换、游记成就审核提交。
- 轻量审核接口需要 `demo_user` 或 `TOURISM_REVIEWER_USERNAMES` 中的用户。
- 成就评估集中在 `backend/src/services/achievement_service.cpp`，不要在 route handler 复制规则。
- V1 有四层：基础景点打卡、主题印章集合、合格游记、大师游记审核。
- 数字纪念凭证是模拟链上凭证，不要新增真实区块链/网络调用，除非用户明确要求。
- 实体徽章只是兑换请求，没有库存、物流或完整后台履约流程。

## 图片规则

景点图片只按三层来源处理：

1. 后端返回的数据库图片，可能来自高德导入或人工整理。
2. `frontend/public/images/diary/` 中的本地拼音图片，通过 `frontend/src/data/imageCatalog.js` 解析。
3. `frontend/src/utils/images.js` 生成的前端 SVG 占位图。

本地拼音图片目录目前是北京景点照片，只能在确认北京上下文时使用。北京上下文优先看结构化 `city` / `province`，再看 `district`，最后才严格检查地址。不要把非北京城市的“北京路”等路名当成北京景点。

不要新增远程随机图片兜底。

## 认证规则

- 登录标识是用户名或邮箱。
- 演示账号：`demo_user / demo123456`。
- token 是存储在 `refresh_tokens` 中的 32 字节随机值，不是 JWT。
- 前端把 token 存在 `localStorage.token`，请求时发送 `Authorization: Bearer <token>`。
- 受保护前端路由：`/profile`、`/collectibles/:id`、`/diary/new`、`/diary/edit/:id`。
- 用户写操作需要登录：偏好、游记、点赞、收藏、评分、评论、打卡、成就领取、纪念凭证、徽章兑换、审核提交。
- 首页、搜索、景点详情、路线规划、AI 助手、游记列表/详情、`/food`、`/achievements` 保持匿名可浏览。

## 运行与验证规则

- 具体运行、初始化和冒烟命令只维护在 `QUICKSTART.md`，不要在 README 或 AGENTS 里重复维护第二份命令清单。
- 数据库入口、导入顺序和验证 SQL 维护在 `database/README.md`。
- 拉取分支后如果页面功能缺数据，先看 `QUICKSTART.md` 和 `database/README.md`，确认本机 `tourism_system` 是否执行了对应 SQL 迁移、seed 或 import。
- 环境变量名称和安全规则可以在这里说明，但具体设置命令放在 `QUICKSTART.md`。
- DeepSeek key、数据库密码和 token 不允许写入仓库、截图、日志或文档示例中的真实值。

## 当前测试策略

GTest 暂不属于当前清理范围。除非用户明确要求专门做测试任务，不要安装 GTest 或修改 CMake 测试策略。

## 约束

- 不要改公开 API 路径，除非同一提交同步更新前端。
- 不要把 DeepSeek key 写入文件、提交、截图或日志。
- 不要把 opaque token 认证流程改成 JWT，除非用户明确要求。
- 不要恢复 `frontend/src/api/index.js`；当前主 API 客户端是 `frontend/src/services/tourismApi.js`。
- 不要让 `main.cpp` 重新变大；接口实现放到模块里。
- 不要把 `frontend/dist` 当成源码逻辑。
- 不要删除 fallback demo 数据，除非用户明确要求只保留后端真实数据。
