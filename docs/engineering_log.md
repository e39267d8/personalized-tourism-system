# 工程记录

## 2026-06-14 / beijing-ticket-price-correction / 北京核心景点门票校正

类型：数据库迁移、景点数据质量、前端展示口径。

背景：高德 POI 主导入中的北京核心景点 `ticket_price` 多数为 `0`，导致搜索、推荐、景点卡片和预算相关展示把故宫、天坛、北海、景山等收费景点误显示为免费。

变更：
- 新增 `database/migrations/beijing_ticket_price_correction.sql`，在导入高德 POI 和补充 POI 后统一校正北京核心景点成人基础门票。
- 修正范围覆盖故宫、颐和园、天坛、北海、景山、中山、圆明园、八达岭、恭王府、雍和宫、鼓楼/钟楼、北京动物园、国家植物园、香山、陶然亭、玉渊潭、地坛，以及天安门广场、国博、军博、前门、王府井、南锣鼓巷、什刹海、奥林匹克公园、北京大学等免费预约或开放式地点。
- `ticket_price` 只存成人常规/旺季基础门票；淡季票、联票、半价票、特展、场馆内二次消费和预约规则写入迁移注释，不放入单值字段。
- 更新 `QUICKSTART.md`、`database/README.md` 和 `AGENTS.md`，把票价校正迁移纳入正式初始化流程。

验证口径：
- 新库初始化时必须在 `imports/amap_pois_supplement.sql` 后执行 `migrations/beijing_ticket_price_correction.sql`。
- 已有库可单独执行该迁移修正票价；迁移幂等，可重复执行。
- 前端展示应看到故宫 60、颐和园 30、天坛 15、北海 10、景山 2、国博 0、天安门广场 0。

## 2026-06-14 / aigc-local-context / 旅行助手接入本地数据上下文

类型：AIGC、后端提示词、前端助手体验、API 契约。

背景：`/agent` 已能调用真实大模型，但提示词只包含用户输入的目的地、天数、预算和风格，没有利用 TourPilot 本地景点/学校/餐饮数据；前端已经支持展示 `suggestions`，后端却没有返回该字段；代码默认模型也与 QUICKSTART 中的 `deepseek-chat` 不一致。

变更：
- `llm_service` 默认模型改为 `deepseek-chat`，与 QUICKSTART 对齐；仍可通过 `TOURISM_LLM_MODEL` 覆盖。
- `/api/v1/aigc/travel-chat` 调用大模型前，会按 `destination` 查询本地 `scenic_spots` 与餐饮 `facilities`，把候选景点、学校、美食、评分、票价、建议游览时长等摘要注入 system prompt。
- `/api/v1/aigc/travel-chat` 响应新增 `suggestions`，按旅行风格返回 3 条可继续追问的问题，供 `TravelAgent.vue` 直接渲染。
- 更新 `docs/api-runtime.md` 和前端 API 测试，明确请求 payload、响应字段和本地数据上下文边界。

验证口径：
- 未配置 DeepSeek key 时，旅行助手仍不生成假回复；配置 key 后回复应优先参考本地候选景点/餐饮，但不能声称实时预约、票务或营业状态。
- `tourismApi.travelAgentChat()` 应解包 `suggestions`，前端快捷追问继续可点击填入输入框。

## 2026-06-14 / route-global-osm-stitch / 路线规划接入更准确 OSM 路网

类型：路线规划、数据库迁移、地图几何质量。

背景：全局路线规划节点 1-9 已能完成多目标环游，但它们主要依赖早期演示边；同时，导入的 OSM 路网存在同坐标/近坐标重复路口，导致真实道路图被切成很多小块。用户在地图上看到路线“绕”或出现非输入地点时，也与前端把后端中间路口名称再次交给文本路线服务有关。

变更：
- 新增 `database/migrations/route_global_osm_stitch_schema.sql`：对 2 米内的重复 OSM 路口写入双向 `osm_stitch` 边，并把全局景点节点接入 600 米内最近的 OSM 路口；不删除旧演示边，旧图仍可兜底。
- 后端路线权重轻微倾向 `osm` / `osm_stitch` 真实道路，旧空 source 演示边保留但不再天然优先；质量统计将 `osm_stitch` 计入真实道路边。
- 前端环游模式优先使用后端已通过质量检查且包含真实道路边的本地几何；调用外部路线服务时只传用户停靠点序列，不再传后端中间路口。
- 修复 `route_tiantan_global_node.sql` 中的乱码中文，保持迁移可读、可重复执行。

验证口径：
- 已有库按顺序执行 `route_tiantan_global_node.sql` 和 `route_global_osm_stitch_schema.sql`。
- 典型环游输入“前门大街 / 故宫博物院 / 国家博物馆 / 天坛公园”应保持可生成；若本地 OSM 路径可达，返回 `routeQuality.realRoadEdges > 0` 并优先绘制本地道路几何。
- 圆明园等不在当前全局路网的点仍会走明确的路线服务兜底，不伪造本地假路线。

本文记录分支交接后的重要工程变更。以后不要每拉一次分支就新建一份“某分支之后改动”文档；普通协作变更统一追加到这里，重大架构取舍再写入 `docs/adr/`。

记录范围：

- 有意义的功能变化。
- 数据库结构、导入文件、seed 数据变化。
- 会影响队友运行、验证、答辩的协作规则。
- 有用户可见影响的重要修复。

语言规则：

- 新增或修改的项目文档默认使用中文。
- 用户可见页面文案默认使用中文。
- API 路径、JSON 字段、表名、provider 名、算法标识等技术契约可以保留英文。

## 2026-06-13 / feature-lxd-search / 颐和园内部道路图达标（≥200边+建筑）+ 加自行车 + 边几何

类型：景区内部道路图、真实地图爬取、4c 交通工具、道路几何渲染、文档。

背景：验收要求单个景区内部道路图边数 ≥200 条、含建筑/服务设施、尽量接近真实（建议
爬取真实地图）。颐和园此前只有人工骨架 ~38 条边，远不达标；且演示边为节点间直线段，
不如友队沿真实道路弯曲。

变更：

- 用既有 `scripts/import_internal_map_data.py` 爬取颐和园真实 OSM 内部数据，生成
  `database/imports/internal_navigation_yiheyuan.sql`：2000 条真实道路边 + 1249 栋建筑。
  导入末尾删除 OSM 抓取的服务设施（`DELETE ... source='osm' AND source_ref LIKE 'yiheyuan:%'`），
  避免设施查询被大量不可达 OSM 设施淹没——设施/路由演示仍用 curated 连通骨架。
  现颐和园内部边 2776 条、建筑 1249 栋、设施 16 个（干净）、交通模式 3 种。
- curated 生成器加自行车道（与步行同几何，速度 4 vs 1.2 m/s）；颐和园现具备
  步行/自行车/电瓶车三工具，可演示 4c 混合最短时间。
- curated 边几何取自地图服务步行折线，路线沿真实道路弯曲；并加绕路过滤：折线
  长度 > 直线 2.5 倍（或 +80m）判定为地图服务绕远（如不知十七孔桥而绕整个湖），
  回退两点直线，避免距离/时间虚高（修复前东宫门→北宫门步行虚高到 5.7km/1.3h，
  修复后 968m/13 分钟）。

验证口径：

- 颐和园内部图接口返回 ~2675 节点 / 2776 边（≥200 达标），约 0.8s。
- 设施查询默认仍只显示 16 个连通 curated 设施，不被 OSM 设施淹没。
- 4c 三工具（spot 3489 东宫门→北宫门）：步行 13 分钟 / 自行车 3 分钟 / 电瓶车 3 分钟。
- 队友需执行：`imports/internal_navigation_yiheyuan.sql` 与 `seeds/seed_yiheyuan_demo_map.sql`。
- 诚实口径：道路图与建筑为 OSM 真实爬取；用于路由/设施演示的连通骨架与三类交通
  专用道为人工校核，几何借地图服务渲染。

## 2026-06-13 / feature-lxd-search / 内部导航交通工具最短时间策略（验收 4c）

类型：内部路线规划、多交通工具、拥挤度时间模型、Dijkstra、数据库 seed。

背景：验收 4c 要求内部导航支持交通工具最短时间——校区步行/自行车（仅走自行车道）、
景区步行/电瓶车（仅走电瓶车线），按各工具速度与道路拥挤度计算时间，且时间最短的
线路可多工具混合。此前内部规划端点写死 `walk`，演示图也只有步行边，4c 基本未实现。

变更（后端）：

- `route_graph_service.cpp` 新增 `mode_ideal_speed`（步行 1.2 / 自行车 4 / 电瓶车 5 m/s）
  与 `congestion_speed_factor`（拥挤等级 1..4 → 系数 1.0/0.8/0.6/0.4，即"真实速度=拥挤度×理想速度"，验收 4b）。
- `route_edge_weight` 的时间策略改为 `时间 = 距离 / (理想速度 × 拥挤度系数)`，按边的
  `travel_mode` 区分速度；混合模式下不同 mode 的边各自计时，Dijkstra 自然选出多工具混合的最短时间路径。
- Dijkstra 交通方式过滤由"单一精确匹配"改为 `mode_allowed`，支持 `walk+bike`、`walk+shuttle`
  这类 '+' 组合允许集（空=不限）。
- `scenic_routes.cpp` 内部规划端点接收 `transport`（walk / bike→walk+bike / shuttle→walk+shuttle / mixed），
  响应新增 `transport` 与 `transportBreakdown`（各工具用量米数）。

变更（数据）：

- 颐和园演示图（`seed_yiheyuan_demo_map.sql`，生成器加 `SHUTTLE_EDGES`）补一条电瓶车固定线（`travel_mode='shuttle'`）。
- 新增 `seeds/seed_pku_bike_lanes.sql`：北大主干道自行车道（`travel_mode='bike'`），依赖 curated 主路网，幂等。

变更（前端）：

- `ScenicDetail.vue` 内部导航增加"交通工具（时间最短策略）"下拉（步行 / 自行车+步行 / 电瓶车+步行），
  选工具时用 `optimization='time'`，并展示交通工具用量明细徽章。

验证口径：

- 颐和园 东宫门→北宫门：纯步行 18 分钟；步行+电瓶车 5 分钟。东宫门→苏州街：步行+电瓶车 = 电瓶车 1238m + 步行 140m（真实混合）。
- 北大 西门→邱德拔体育馆：纯步行 17 分钟；步行+自行车 6 分钟。
- 回归：拥挤度绕行仍正常（早高峰 time 优先绕行 3.5km，distance 直达 2.3km）。
- 队友需执行：`seed_pku_bike_lanes.sql` 与 `seed_yiheyuan_demo_map.sql`。

## 2026-06-13 / feature-lxd-search / 北京大学校园内部连通图校核

类型：校园内部道路图、设施查询、Dijkstra、数据库 seed、路线质量判断。

背景：北京大学已有 `database/imports/internal_navigation_pku.sql` 的 OSM 内部节点、建筑、设施和道路边，但开放地图校园路网存在大量断裂连通片区。设施查询虽然使用 Dijkstra，但起点和设施落在不同碎片时只能不可达，验收时很难稳定展示“选中场所后按实际步行距离查附近设施”。

变更：

- 新增 `scripts/gen_pku_curated_map.py` 和生成结果 `database/seeds/seed_pku_curated_map.sql`，参考颐和园内部图做法，为北京大学补充一张人工校核的连通校园主路网。
- 新 seed 继续使用正式 `facilities`、`graph_nodes`、`graph_edges`，不新增第二套校园图表；包含 29 个主路网节点、72 条双向主路网边、27 个分类设施和 54 条设施接入短边。
- 主路网边来源标记为 `campus_curated`，设施接入短边来源标记为 `generated`，不把人工校核边伪装成 OSM。
- 后端路线质量判断从“只认 `osm` 边”为真实道路，调整为“所有非 `generated` 边均为正式道路”；前端内部图默认起点和起点下拉优先选择 `campus_curated` / `demo` 来源节点，避免补图后仍默认落到旧碎片入口。
- 新增 ADR：`docs/adr/0003-campus-curated-internal-graph.md`，说明原始地图导入与人工校核连通层的边界。
- 更新 `QUICKSTART.md` 和 `database/README.md`，把 `seed_pku_curated_map.sql` 加入初始化与补跑流程。

验证口径：

- 执行 `database\seeds\seed_pku_curated_map.sql` 后，北京大学内部图应新增 `campus_curated` 主路网和可达分类设施。
- 刷新北京大学详情页，设施查询默认应从校核连通图入口出发，附近设施按 `walkDistance` 升序展示。
- 选择西门、图书馆、百周年纪念讲堂、农园餐厅、博雅塔等校内场所作为查询位置时，附近设施距离和排序应随起点变化。

## 2026-06-13 / feature-lxd-search / 场所附近设施实际步行距离排序

类型：场所查询、附近设施、内部路网 Dijkstra、前端验收流程。

背景：评分标准要求在景区或学校内部选中某个景点/场所后，查找一定范围内的超市、卫生间等设施，并按距离排序，且不能使用直线距离。此前后端已经支持 `from_node_id` 下的 Dijkstra 步行距离排序，但前端固定按入口排序，缺少“当前选中场所”和范围/关键词查询入口。

变更：

- 景点详情页“设施查询”把原“起点”升级为“查询位置 / 路线起点”，支持自动入口、下拉选择和地图点选三种来源。
- 设施列表继续复用 `/api/v1/scenic-spots/:id/facilities?from_node_id=...`，由后端按内部路网 Dijkstra 计算 `walkDistance` 并升序排序；前端不使用经纬度直线距离给设施排序。
- 当用户选择建筑、入口等未直接连通的设施节点时，前端会吸附到附近最近的连通路网节点作为 Dijkstra 起点，避免出现“只有自己可达”的假排序。
- 新增设施关键词查询和步行范围过滤：关键词可匹配设施名称、类别中文名和类别代码；范围过滤按 `walkDistance` 过滤 `300m / 500m / 1000m / 1500m` 内可达设施。
- 新增“附近设施”列表，与目的设施下拉共用同一批结果；点击附近设施可同步选为目的设施，再使用现有内部路线规划。

验证口径：

- 前端生产构建通过：`npm.cmd run build`。
- 打开景点详情页，默认按入口附近的实际步行距离显示设施；切换“下拉选择”到另一个场所后，设施距离和排序应重新计算。
- 输入“厕所、商店、餐饮”等关键词，或选择步行范围，结果应继续保持实际步行距离升序。
- 当前内部路网存在离散连通片区时，不可达设施不会用直线距离兜底；在“全部可达范围”中可达设施排前，不可达设施排后，选择具体范围时不可达设施会被过滤掉。

## 2026-06-13 / feature-lxd-search / 内部路网图视觉降噪

类型：景区/校园内部路网、前端展示优化、验收体验。

背景：内部路网默认视图已经改为数据库 SVG 渲染，但北京大学等校园内部道路在一屏内显示时仍偏像调试图：道路片段分散、网格过重、设施点颜色过硬，验收时不利于快速看出“这是内部道路图”。

变更：

- 默认“聚焦路网”按真实道路的连通片区优先展示一批主路网，减少互不相连的小片段把画布摊散；“全量数据”仍可查看全部数据库道路。
- SVG 道路增加白色底衬和较细的主线，规划路线也增加底衬，视觉上更接近可读地图线而不是裸折线。
- 设施点数量和样式降噪：默认显示数量从 80 下调到 56，建筑点更轻，入口和选中设施更突出，选中标签改为白底标签。
- 背景网格改为更浅的辅助网格，只作为方向参照，不抢道路层级。

验证口径：

- 前端生产构建通过：`npm.cmd run build`。
- 刷新 `http://127.0.0.1:3000/spots/3486` 后，默认内部路网应比之前更聚焦、更少黑点噪音；如果需要看完整数据库边，切换“全量数据”。
- 本次没有改动内部路网接口、数据库数据和寻路算法，只优化验收可视化。

## 2026-06-13 / feature-lxd-search / 内部道路图验收展示改造

类型：景区/校园内部路网、前端验收展示、地图服务边界。

背景：景点详情页原先直接使用外部地图底图展示内部道路叠加层，页面左下角会出现地图服务供应商署名，容易让验收时误解“内部道路图是外部底图自带的”。同时只展示节点/道路数量不足以证明我们确实在使用数据库路网。

变更：

- 景点详情页“景区设施导航”增加视图切换：默认进入“内部路网”，不加载外部地图底图；“地图服务”作为辅助查看方式，需要用户主动切换才加载。
- 默认“内部路网”用 SVG 直接渲染后端 `/api/v1/scenic-spots/:id/internal-map` 返回的 `graph_edges` 和 `facilities`：真实道路用实线，设施接入边用虚线，规划路线用高亮线。
- 保留内部节点、内部道路、服务设施、可导航设施数量作为辅助证据，但主要验收证据改为“数据库路网可视化本身”。
- 用户可见文案继续避免出现具体地图供应商品牌，统一使用“地图服务”；内部真实路网仍来自正式数据库 `graph_nodes`、`graph_edges`、`facilities`。

验证口径：

- 前端生产构建通过：`npm.cmd run build`。
- 进入 `http://127.0.0.1:3000/spots/12` 或 `http://127.0.0.1:3000/spots/3486`，默认看到的是数据库内部路网 SVG，不应出现外部地图底图署名。
- 故宫内部图接口应返回 6618 个节点、6928 条边；北京大学内部图接口应返回 794 个节点、760 条边。

补充优化：

- 默认“内部路网”改为“聚焦路网”视图：按真实道路边的空间分布做分位裁剪，避免远处离散设施和接入边把画布拉得过大。
- 增加“全量数据”切换，用于验收时证明所有数据库边和设施仍可查看；设施接入边默认隐藏，可通过“显示设施接入边”打开。
- 默认仅展示核心设施点，并清理 `OSM 服务设施 + 编号` 这类原始名称标签，只在选中设施时显示可读名称，降低画面噪音。

## 2026-06-13 / route-tiantan-global-node / 天坛全局路线节点补齐
类型：路线规划、数据库迁移、演示路网修复。
背景：多目标环游输入“天坛”时，前端会在缺少全局天坛节点的情况下匹配到天坛内部设施/建筑节点；该内部图与故宫、前门的全局演示图不连通，导致 `/api/v1/routes/tour` 返回“部分点之间不可达”，并在外部地图服务不可用时显示环游失败。
变更：
- 新增 `database/migrations/route_tiantan_global_node.sql`，为已有库补齐 `天坛公园节点` 以及它与前门、国家博物馆、天安门的双向步行边。
- 同步更新 `database/seeds/seed_demo.sql`，新建库初始化时也包含天坛全局节点和演示边。
- `/route` 的本地节点解析继续排除 `junction`，避免把街道路口或景区内部节点混入全局景点/学校环游规划。
- 路线服务兜底失败时，前端错误提示会带上真实原因，便于区分后端未启动、外部地图服务不可用和本地图不可达。
验证口径：
- 已有库需执行 `database\migrations\route_tiantan_global_node.sql` 后再验证“前门大街 → 故宫博物院 → 天坛 → 返回前门大街”。
- 新库初始化应先执行 `seed_demo.sql`，再执行该迁移；`database/README.md` 已同步顺序。

## 2026-06-13 / multi-target-tour-route / 多目标智能环游路线

类型：路线规划、前后端契约、算法测试、答辩文档。

变更：

- `/route` 页面新增多目标智能环游交互：用户手动输入当前位置 / 出发点，再输入多个目标景点或学校；每个目标可选填“第几个到达”。
- 环游模式下，“第几个到达”只针对目标地点计数，不包含出发点和最后返回出发点；前端校验目标数量、序号范围和重复序号。
- `POST /api/v1/routes/tour` 新增 `startNodeId`、`targetNodeIds`、`fixedOrders` payload，同时保留旧 `nodeIds` 兼容逻辑。
- 后端新增纯算法模块处理带固定到达序号的多目标最短回路：指定序号作为硬约束，未指定目标自动排序；小规模精确枚举，大规模使用确定性近邻优化，不使用随机排列。
- `docs/api-runtime.md` 和 `docs/答辩文档.md` 已补充多目标环游路线的接口语义和答辩说明。

验证口径：

- 起点为空、目标少于 2 个、指定序号越界或重复时，前端应阻止提交并显示中文错误。
- 新 payload 与旧 `nodeIds` payload 都应能调用 `/api/v1/routes/tour`。
- 如果 9 个目标中某目标指定第 5 个到达，后端返回的目标顺序应保证该目标位于第 5 站。

## 2026-06-13 / food-recommendation-closure / 美食推荐需求闭环

类型：美食推荐、前后端契约、seed 数据、协作文档。

背景：评分要求中的美食模块需要在选中游览景点或学校后，按用户选择的热度、评价、距离排序，并支持按菜系过滤；同时支持输入美食名、菜系、饭店或窗口名称做模糊查询，多结果继续按热度、评分或距离排序。用户通常只看前 10 个结果，因此后端应避免全量排序。

变更：

- 前端 `/food` 的位置筛选统一为“景点 / 学校”，学校类对象单独分组展示；未选择具体位置时不允许选择“距离最近”，避免无位置上下文时误导用户。
- 后端 `/api/v1/foods` 在 SQL 层按景点/学校、关键词和菜系缩小候选集，排序继续使用 `TopKSelector` 保留前 K 个结果后返回。
- 模糊查询覆盖餐饮名称、地址、菜系元数据、景点/学校名称和分类；菜系推断优先读取 `facilities.source_tags.cuisine`，再回退到名称推断。
- API 响应补充 `matchedTotal`、`returned`、`sourceCuisine`、`scenicCategory`、`locationTypeLabel`，便于前端区分学校和景点来源，同时保留原有 `total` 兼容字段。
- `database/seeds/seed_foods.sql` 增加北京大学校园餐饮数据，并写入 `source/source_ref/source_tags`，用于菜系推断和幂等更新。
- `QUICKSTART.md`、`database/README.md`、`docs/api-runtime.md` 和 `AGENTS.md` 已同步美食模块的运行、API 和协作规则；已有库只补美食数据时需要先执行 `database\internal_navigation_schema.sql`。

验证口径：

- `/food` 选择北京大学后应能看到校园餐饮，并可按热门、评分、距离切换排序。
- 搜索“咖啡”“面馆”“食堂”等关键词时，应匹配餐饮名称、菜系或学校/景点相关结果。
- `GET /api/v1/foods?scenic_spot_id=...&sort=distance&limit=10` 返回前 10 条结果，并在响应中包含 `matchedTotal` 与实际 `sort`。

## 2026-06-13 / codex-db-sync / 队友更新后的数据库同步修复

类型：数据库迁移、seed 幂等性、本机数据同步。

变更：

- 新增 `database/migrations/diary_compression_legacy_cleanup.sql`，用于清理早期半成品压缩字段 `compressed_content`、`original_bytes`、`compressed_bytes`，继续统一使用正式字段 `content_compressed` 和 `content_original_bytes`。
- 修复 `database/seeds/seed_foods.sql` 中美食 `graph_nodes` 依赖硬编码 `scenic_spot_id` 的问题，改为从对应 `facilities.scenic_spot_id` 派生，避免不同本机数据库景点主键不一致时触发外键失败。
- 修复 `database/seeds/seed_demo.sql` 中基础设施节点未同步景点归属的问题，按 `facilities.scenic_spot_id` 回填 `graph_nodes.scenic_spot_id`。
- 更新 `QUICKSTART.md` 和 `database/README.md` 的初始化顺序，把压缩旧字段清理迁移纳入全量初始化和已有库日记迁移补跑路径。
- 本机 `tourism_system` 已重跑队友新增的成就、搜索索引、日记动画、跨层导航、美食、演示和室内导航相关 SQL，并删除旧压缩字段。

验证口径：

- `seed_foods.sql` 应能在景点主键不同的本机数据库上重复执行，不再因 `graph_nodes.scenic_spot_id` 外键失败中断。
- `travel_diaries` 应只保留 `content_compressed`、`content_original_bytes`、`videos`、`animation_storyboard` 等正式扩展字段，不再保留旧压缩列。

## 2026-06-13 / feature-lxd-search / 成就系统模块边界与并行协作准备

类型：模块拆分、数据库正式化、并行开发协作、文档规范。

背景：后续会并行推进两条主线。一条负责评分标准里的基础功能，另一条负责评分标准之外的创新点“成就系统”。仓库里成就功能已经具备后端服务、前端页面和演示数据，但此前成就接口混在 `dashboard_routes.cpp`，成就演示数据混在 `seed_demo.sql`，不利于多人并行，也不符合“数据库变更以 SQL 迁移和 seed 为准”的协作规范。

变更：

- 新增 `backend/src/api/achievement_routes.cpp` 和 `backend/include/api/achievement_routes.h`，把成就相关公开接口从 `dashboard_routes.cpp` 中拆出；首页概览接口继续保留在 dashboard 模块。
- 新增正式迁移 `database/migrations/achievement_module_schema.sql`，把成就编码、景点打卡、游记评审、实体徽章申请和数字纪念凭证相关结构固化到 SQL，减少“运行时自动补表”带来的状态不透明。
- 新增正式 seed `database/seeds/seed_achievements.sql`，把旅行护照、用户成就进度和数字纪念凭证示例数据从 `seed_demo.sql` 分离；`seed_demo.sql` 继续只承载基础演示路线、游记、评论、收藏和推荐标签。
- 新增 ADR `docs/adr/0002-achievement-module-boundary.md`，明确基础功能主线与成就创新主线的后端、前端、数据库和共享文件边界。
- 更新 `QUICKSTART.md`、`database/README.md` 和 `docs/api-runtime.md`，补充成就模块独立迁移和 seed 的执行顺序与接口口径。

验证口径：

- 新拉代码后，如果只需要同步成就模块数据库，应执行：
  - `database/migrations/achievement_module_schema.sql`
  - `database/seeds/seed_achievements.sql`
- 后端成就接口注册入口应位于 `achievement_routes.cpp`，`dashboard_routes.cpp` 不再承载成就业务接口。
- `seed_demo.sql` 与 `seed_achievements.sql` 可以分别幂等重跑，降低基础功能与创新功能分支同时修改同一 seed 文件的冲突概率。

## 2026-06-12 / feature-lxd-search / 路线规划质量闸门与演示路线清理

类型：路线规划、地图渲染、质量兜底、验收风险治理。

背景：路线规划核查发现，普通路线接口失败时前端会生成演示折线；TSP/拥挤度分层渲染在路线服务几何失败时也可能退回低可信本地图几何或把公交失败降级为步行几何。这会让用户误以为系统生成了真实可走路线，和“修复问题、不搞假的”的验收目标冲突。同时，不能把“拒绝假路线”做成“本地算法失败就直接空白”：如果真实地图路线服务仍可用，应当诚实兜底，但不能把兜底结果冒充 TSP 或拥挤度算法结果。

变更：

- 路线规划页删除前端演示路线 fallback：普通 `POST /api/v1/routes/plan` 失败时显示明确错误，不再用硬编码坐标和插值折线伪造路线。
- TSP/拥挤度分层渲染关闭“公交失败后改用步行几何”的隐式降级。
- TSP/拥挤度本地算法失败、节点缺失或质量闸门拒绝时，前端会优先调用真实地图路线服务兜底；兜底成功后页面显示黄色说明，普通步行/骑行/驾车按当前输入顺序显示真实道路路线，地铁公交按起终点显示真实道路路线，并标记 `routeServiceFallback=true`，不冒充 TSP 或拥挤度算法结果。
- 后端新增 `RouteQualityReport` 与 `assess_route_quality()`，对本地 Dijkstra/TSP/拥挤度路线做展示前检查。
- 本地路线若存在缺失道路几何、超过 60 米的 `generated` 接入边，或完全由生成接入边拼成且没有真实 OSM 路段支撑，则返回 422，不生成路线。
- 通过质量闸门的本地路线响应新增 `routeQuality`，包含真实 OSM 路段数、生成接入边数、缺几何边数和最长生成接入边距离，便于验收解释。
- 真实地图路线服务若只返回文字步骤但没有道路折线，后端不再用起终点坐标连成直线，而是返回“未返回可展示的道路折线”，避免地图上出现误导性的直线。
- 前端用户可见文案统一使用“地图服务 / 路线服务 / 室内地图服务”，不显示供应商名称或内部配置变量名。

验证口径：

- 普通路线接口失败时，页面应显示“路线规划失败，未生成演示路线”，地图不画假线。
- `POST /api/v1/routes/plan`、`POST /api/v1/routes/tour`、`POST /api/v1/routes/plan/congestion` 对低质量本地路线应返回 422 和明确原因。
- 可展示的本地路线响应应包含 `routeQuality.displayable=true`。
- TSP/拥挤度模式如果本地算法不可展示，但真实地图路线服务成功，页面应显示可走的真实道路路线和黄色兜底说明；如果兜底也失败，则显示明确错误，地图不画线。
- 普通步行/公交路线仍按真实 polyline 渲染，不受本地质量闸门影响；路线服务未返回 polyline 时不画起终点直线。
- 前端源码扫描不应出现用户可见的供应商中文名称。

## 2026-06-12 / feature-lxd-search / 推荐 Top-K、查询索引与页面闪屏治理

类型：推荐算法、搜索查询、前端体验、数据库迁移、答辩文档。

背景：评分要求明确要求旅游景点和学校推荐支持热度、评价和个人兴趣排序，并且用户通常只看前 10 个结果，应避免全量排序后截断；搜索要求支持名称、类别、关键字查询，并在多结果时支持热度和评价排序。页面核查时还发现首页、搜索页、推荐页存在“先显示演示/fallback 数据再替换真实数据”的闪屏观感。

变更：

- `POST /api/v1/recommendations/personalized` 新增可选 `sortBy`，支持 `interest`、`rating`、`hot`，默认 `interest`。
- 后端推荐继续采用小顶堆 Top-K 部分排序，只维护前 `limit` 个候选，避免对全部景点/学校做完整排序后再截取。
- 推荐候选补充 `view_count` 和 `favorite_count`，热度模式按浏览量、收藏量的对数缩放计算 `hotScore`，评价模式按评分优先并用热度/综合分兜底。
- 前端推荐页新增“个人兴趣优先 / 评价优先 / 热度优先”排序切换，后端返回顺序不再被前端二次全量排序覆盖。
- 搜索页首次加载改为空数据 + 骨架屏；路由 query 作为搜索触发源，请求序号会丢弃过期响应，避免快速输入或切换排序时旧响应覆盖新结果。
- 首页不再先渲染 fallback 推荐/路线/预算方案，首次加载展示稳定骨架屏，接口失败时才启用本地 fallback。
- 新增正式迁移 `database/migrations/scenic_search_indexes.sql`，启用 `pg_trgm`，为景点/学校名称、描述、分类名和评分/热度排序补充索引。
- 新增长期维护文档 `docs/答辩文档.md`，开头收录评分加分项/减分项，并先写“（1）旅游推荐”章节，用答辩口径解释 Top-K、动态推荐和多维查询排序。

验证口径：

- 前端构建应通过，首页、发现景点、推荐页进入时不再先闪出演示数据后替换。
- 推荐页切换 `interest/rating/hot` 时，请求 payload 包含 `sortBy`，响应顺序由后端 Top-K 排序决定。
- 搜索页输入“国博”等中文简称仍可命中中国国家博物馆；切换 `rating` 和 `hot` 时结果按对应字段排序。
- 已有数据库需要补跑：

```bat
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\migrations\scenic_search_indexes.sql
```

## 2026-06-10 / feature-lxd-search / 文档职责收敛

类型：文档规范、协作规则、API 文档补全。

背景：此前 README、AGENTS、QUICKSTART 和分支交接文档之间存在职责重叠，容易在每次拉分支后继续复制 `changes_after_xxx.md`。本次按统一规则收敛：README 只放项目总览，QUICKSTART 只放运行和初始化步骤，AGENTS 只放工程规则，普通工程变更统一写入本文，重大技术决策写入 ADR。

变更：

- 将 `README.md` 收敛为项目总览和文档入口，移除运行命令、环境变量、专题实现细节和阶段流水。
- 在 `AGENTS.md` 明确文档职责、数据库变更正式口径，以及不再创建 `changes_after_xxx.md` 的协作规则。
- 删除历史分支交接文档 `docs/changes_after_lxd.md`，其有效内容已由 `docs/engineering_log.md`、`docs/adr/0001-indoor-navigation-provider.md`、`QUICKSTART.md` 和 `database/README.md` 承接。
- 补全 `docs/api-runtime.md` 中游记运行时 API：全文检索、按标题/景点检索、`GET /api/v1/diaries/<id>/replay-route`、压缩统计/迁移接口和 Huffman 工具接口。
- 明确 Huffman 工具接口不是日记压缩落库的权威路径；真实存储以日记创建/更新、压缩迁移接口和 `database/migrations/diary_compression_schema.sql` 为准。

验证口径：

- 文档检索中不再存在 `docs/changes_after_lxd.md`，`changes_after_xxx` 只保留在 AGENTS 的禁止规则里。
- `docs/adr/0001-indoor-navigation-provider.md` 已正式记录室内导航采用 `amap_indoor` + `local_indoor_graph` provider 模型的架构决策。
- `docs/engineering_log.md` 已包含“日记→路线一键复刻”和“日记 Huffman 压缩真实落库”两项工程记录，`docs/api-runtime.md` 已补齐对应 API 契约。

## 2026-06-10 / feature-lxd-search / 北京大学校园内部道路图

类型：校园内部导航、数据库导入、真实地图数据、文档。

背景：课程设计要求景区和校园都应有内部道路图。北大红楼室内导航只覆盖单体建筑室内拓扑，不能替代北京大学校园级道路图；校园内部图必须进入现有 `graph_nodes`、`graph_edges`、`facilities`，不新建第二套校园图表。

变更：

- 新增 `database/seeds/seed_campus_spots.sql`：把北京大学作为 `scenic_spots` 中的正式校园对象接入系统，分类为“高校校园”。
- 新增 `scripts/pku_campus_spots.json`：北京大学校园生成配置，包含燕园主校区边界和排除词，避免把清华或中关村周边 POI 算入北大校园。
- 新增 `database/imports/internal_navigation_pku.sql`：北京大学校园内部道路图导入 SQL，数据来自 OSM/Overpass；导入前会清理同一景点下旧的 `pku:%` 内部图数据，再写入当前校园范围，保持幂等。
- 扩展 `scripts/import_internal_map_data.py`：支持按 `bounds` 和 `exclude_terms` 过滤节点/边，并在生成 SQL 中加入旧内部图清理段，避免重复导入造成历史宽范围数据残留。
- 更新 README、QUICKSTART 和数据库说明，补充校园内部图导入顺序、只补校园图命令、验证 SQL，并明确“北京大学校园内部道路图”和“北大红楼室内导航”是两项不同能力。

验证口径：

- 已在本地 `tourism_system` 执行：
  - `database/internal_navigation_schema.sql`
  - `database/seeds/seed_campus_spots.sql`
  - `database/imports/internal_navigation_pku.sql`
- 导入日志显示旧宽范围 `pku:%` 数据被清理后重新写入：794 个 PKU 图节点、402 条 OSM 道路边、567 条设施表记录、358 条设施接入边。
- 正式表统计结果：北京大学校园范围内 794 个图节点、760 条内部图边，其中 OSM 真实道路边 402 条、设施接入边 358 条；建筑节点 449 个，非建筑服务设施 118 个、10 类。
- `facilities` 表总计 567 条是因为建筑节点也会以 `building` 类型同步到设施表；课程设计口径下，“其它服务设施”按 `type <> 'building'` 统计。
- 课程设计口径下，校园内部道路图满足边数不少于 200、建筑不少于 20、其它服务设施不少于 50 且服务设施类型不少于 10 的要求。

## 2026-06-12 / feature-yhm-graph / 三项缺陷修复：公交步行接驳缺失、简称搜索、核心地标缺数据

类型：重要缺陷修复（后端解析 / 搜索算法 / 数据补充）。

一、地铁公交规划丢失全部步行接驳段

- 现象：选地铁公交后地图只画地铁线，"怎么走到地铁站"完全缺失。
- 根因（经最小复现程序定位）：高德 transit 响应中步行 step 的 `duration`、`road` 等"缺失"字段以**空数组 `[]`** 形式出现而非字符串；`amap_route_service.cpp` 对其做 `static_cast<std::string>` 触发 Crow 的 "json type container" 异常，被外层 `catch(...)` 静默吞掉，导致整段步行解析全军覆没。公交线字段恰好都是真字符串所以幸存——这就是"只剩地铁线"的原因。
- 修复：新增异常安全的 `json_number_string()`（容器/异常回退 "0"），替换全部裸 cast（步行/驾车 step、busline、transit/path 总计 10 处）。
- 实测：国博→颐和园地铁公交从 2 段变 23 段（出发步行 8 段 → 2 号线 → 换乘步行 → 4 号线 → 到达步行 7 段），坐标点 169→296，门到门完整。

二、中文简称搜索不命中（"搜不出国博"之算法层）

- 根因：搜索全部基于 LIKE 连续子串，"国博"在"中**国**家**博**物馆"中不连续，永远无法命中。
- 修复：景点搜索与搜索建议增加"简称连字匹配"档——`'%' || regexp_replace(lower(q), '(.)', '\1%', 'g')` 把查询拆成逐字按序模式（国博→%国%博%），字符按序出现即命中；要求查询 ≥2 字防止过宽，且仅在常规包含未命中时计 40 分（低于包含匹配 60 分），`match_reason` 标注"名称简称匹配"。建议接口排序补"包含优先、短名称优先"。
- 实测："恭博"→恭王府博物馆、"军博"→军事博物馆、"国博"→中国国家博物馆（排第一）。

三、北京核心地标缺数据（"搜不出国博"之数据层）

- 排查发现主 POI 导入未覆盖：**中国国家博物馆、中国人民革命军事博物馆、颐和园**（颐和园整库缺失）。算法修好后这些景点依然搜不到，因为数据不存在。
- 新增 `database/imports/amap_pois_supplement.sql`：从高德 place/text 拉取三个地标的真实 POI（坐标/地址/评分/开放时间/图片），与主导入同款幂等防重（名称+城市+100 米范围 NOT EXISTS）。已在本地执行（INSERT 3 行）。
- 注：搜索框前端链路（顶部导航/首页/搜索页）排查无问题，"搜索像占位"的观感即 0 结果回退展示精选景点所致，根因同上。

验证口径：

- 后端构建通过；`/routes/plan`（transit）含步行接驳段；"国博/军博/颐和园"搜索与建议均正常返回。
- 队友拉取后需执行：`psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\imports\amap_pois_supplement.sql`

## 2026-06-11 / feature-yhm-graph / 修复：环游模式与拥挤度感知只画直线

类型：重要缺陷修复（前端）。

背景：路线规划页勾选「环游模式 (TSP)」或「拥挤度感知」后，地图只画出一条直线，不勾选则正常。排查结论：后端 `/routes/tour` 与 `/routes/plan/congestion` 一直返回基于本地路网的真实多节点路径，问题全在前端——这两个分支是占位级实现：环游模式把数组下标 `[1,2,3...]` 当节点 ID 发给后端；拥挤度模式用一张写死的 8 地名→ID 映射表（且 ID 与 seed 实际节点错位），坐标靠前端硬编码表拼凑，拼不出来就回退两个固定点连直线。后端返回的真实 `coordinates`/`stops`/`segments` 全被丢弃。

修复：

- 前端新增本地路网节点解析：按需调用 `GET /api/v1/route-nodes` 并缓存，把用户输入的地点文本按名称匹配（精确 > 包含，scenic 类型优先）解析为真实节点 ID；匹配不到时给出明确错误并列出路网内可用景点示例，不再静默回退。
- 环游/拥挤度两个分支改为直接展开后端响应（`computed_route_json` 结构）：地图折线用真实图路径坐标，停靠点、导航步骤（segments）、距离/时长/费用、TSP 访问顺序（后端已返回名称）、拥挤度行为画像字段（`congestionSource`/`behaviorBoostedEdges`）全部来自后端，删除全部硬编码地名表与假坐标拼装。
- 顺带修复旧代码中 `(x || 0 / 1000)` 的运算符优先级错误（距离恒显示原始米数）。
- 交通方式映射集中为 `localGraphTravelMode()`（driving→car、transit→subway），环游与拥挤度共用。

验证口径：

- 前端生产构建通过；后端无改动。
- 实测 `POST /routes/plan/congestion`（前门大街→北海公园，hour=10）：返回 7 站真实路径（经天安门广场、故宫、景山），4.3 km；前端按该坐标序列画折线，不再是直线。
- 实测 `POST /routes/tour`（4 节点）：返回名称形式访问顺序与 14 点真实路径坐标，10.8 km，算法「枚举」。
- 输入路网外地点（如"颐和园"不在演示路网时）应显示明确错误提示与可用地点示例，而不是画一条假直线。

跟进（同日）：分层渲染，解决"驾车穿楼"。

- 上述修复后路线仍按图节点连线绘制——本地图的边只有节点对、没有道路几何，节点间直连会穿过街区；且演示图无驾车边，所选驾车被回退为步行混合。
- 改为分层渲染：算法层（TSP / 拥挤度 Dijkstra）只决定"经过哪些点、什么顺序"；渲染层把停靠点序列交给 `POST /routes/plan`（高德文本规划）按所选交通方式取真实道路折线。与"日记重走路线"同一套路。
  - 环游：高德按 TSP 访问顺序规划闭环（末尾补回起点）。
  - 拥挤度：图路径中的 scenic 中间节点作为高德途经点（上限 6 个），绕开热门区域的决策体现在真实道路上；`congestionSource`/`behaviorBoostedEdges` 等元数据仍来自拥挤度接口。
  - 高德不可用时回退图几何（保底可用），此时不再伪装交通方式（fallback 标志如实保留）。
- 实测：国博→天安门广场→故宫 驾车返回 62 点真实道路折线（2.9 km / 12 分钟），对比图几何 7 点直连。
- 排查插曲：用 PowerShell 5.1 直发中文 JSON 会因默认编码非 UTF-8 导致高德报 30001（地点识别失败），浏览器请求不受影响；后续命令行测试需显式 UTF-8 字节。

## 2026-06-11 / feature-zby-recommend / 日记位置与封面、AI 标题生成、日记广场强化

类型：数据库迁移、后端 CRUD 扩展、前端编辑器重构、AI 新接口。

变更：

- 新增数据库迁移 `database/migrations/diary_location_cover_schema.sql`：`travel_diaries` 增加 `cover_image`（显式封面图）、`location_name`/`location_address`/`location_latitude`/`location_longitude`/`location_poi_id` 五个地点字段；存量日记的 `cover_image` 由迁移自动用 `images[1]` 填充。
- 后端日记 CRUD（POST/PUT/GET）全面支持上述新字段，SELECT SQL 新增对应列，`diary_json()` 返回 `coverImage` 和 `locationDetail` 对象。`GET /api/v1/diaries/mine` 新增 `status` 查询参数（`all`/`published`/`draft`），支持按草稿/发布状态过滤。
- 新增 `POST /api/v1/aigc/diary-title`：根据正文内容生成标题文案（调用 `generate_diary_title_text()`）。
- 前端 DiaryEditor.vue：图片区改为胶卷带（filmstrip）横向排列，支持长按拖拽排序；图片可独立设置封面（原为"第一张自动为封面"）；AI 摘要按钮改为"AI 标题文案"（调用新接口）；景点 ID 输入移至图片区；格式工具栏激活状态增加指示点。
- 前端 Diary.vue：视图模式和草稿状态与 URL 参数双向同步（`/diary?view=mine&status=draft`）；日记列表去重（防本地与服务端重复）；删除前加确认对话框；未登录访问我的日记自动跳转登录；`diaryStore.justPublished` 合并逻辑修正（优先使用服务端字段）。
- 前端 Profile.vue：细节完善（未展开审核）。

验证口径：

- 前后端构建均通过（2026-06-11 合并 origin/feature/zby-recommend 后）。
- 执行迁移后 `\d travel_diaries` 应含 `cover_image`、`location_name` 等新列，存量日记的 `cover_image` 不为 NULL。
- 新建日记时上传多张图片，可点"设为封面"切换，保存后 API 返回 `coverImage` 为指定图片。
- `/diaries/mine?status=draft` 只返回草稿；`/diaries/mine?status=published` 只返回已发布。
- 点击"AI 标题文案"按钮，后端 `POST /aigc/diary-title` 正常返回标题建议。

注：本次变更未同步更新 `docs/engineering_log.md`、`QUICKSTART.md`、`database/README.md`，由本轮补录，后续 zby 应遵循文档规范在每次提交后自行更新。

## 2026-06-11 / feature-lxd-search / 室内外跨层导航

类型：跨层路径规划、数据库迁移、后端新接口、前端交互。

背景：室外景区路网（graph_nodes/graph_edges）和室内图（indoor_features/indoor_edges）此前是两套孤立的图，导航在建筑门口"断链"。本次在建筑入口处缝合两层，一次请求完成"景区路网步行 → 建筑入口交接 → 室内逐层导航"的完整路径（如：从故宫南门步行到北大红楼，再走到二层展厅）。

变更：

- 新增迁移 `database/migrations/cross_layer_navigation_schema.sql`：`indoor_buildings` 增加 `outdoor_node_id`（室外路网锚点节点），并按名称规则自动绑定（精确匹配 + "北大/北京大学"前缀归一化，处理室内 seed"北大红楼"与 OSM 室外节点"北京大学红楼"的命名差异）；幂等可重复执行。
- 新增 `POST /api/v1/indoor-buildings/<id>/routes/plan-cross`：
  - 室外段：景区路网 Dijkstra（步行，时间/距离策略跟随请求）。
  - 交接点：建筑室外锚点 ↔ 室内楼层最低的 `entrance` feature。
  - 室内段：复用既有 indoor-dijkstra（楼层步骤、楼梯/电梯指令）。
  - 锚点未持久化时按迁移同款名称规则实时匹配；匹配失败返回明确错误，不影响纯室内导航。
  - 响应含 `outdoor`（含地图坐标，结构同路线规划接口）、`indoor`（结构同室内规划接口）、`handoff`（交接点信息）与总距离/总耗时；审计记录算法为 `cross-layer-dijkstra`。
- 前端室内导航面板起点新增「室内 / 景区路网」模式切换：选景区路网起点（入口/景点/设施节点下拉）后一键规划跨层路线；结果显示"跨层路线总览"（室外段 → 入口交接 → 室内段 + 总计），室内段步骤与 SVG 高亮完全复用现有渲染。

验证口径：

- 后端 `tourism_server` 与前端生产构建均通过。
- 执行迁移后 `SELECT name, outdoor_node_id FROM indoor_buildings` 中北大红楼应已绑定到室外"北京大学红楼"节点。
- `POST /api/v1/indoor-buildings/<id>/routes/plan-cross`（startNodeId=景区入口节点，endFeatureId=二层展厅）应返回室外段坐标、交接信息、室内跨楼层步骤与总计；`indoor_route_audit` 留下 `cross-layer-dijkstra` 记录。
- 前端景点详情页室内导航面板切到「景区路网」起点，规划后出现"跨层路线总览"卡片，室内 SVG 正常高亮路径。
- 纯室内导航回归不受影响（起点保持「室内」模式时行为与之前一致）。

## 2026-06-11 / feature-lxd-search / 拥挤度数据闭环（行为画像 + 热门时段）

类型：拥挤度算法、行为数据聚合、后端新接口、前端可视化。

背景：此前拥挤度完全来自时段模拟函数（早晚高峰写死），与系统真实使用情况无关。本次把系统自有的三类用户行为数据接入拥挤度体系，形成"用户用得越多、画像越准"的数据闭环（类似 Google Maps 热门时段机制）。

行为信号与权重：

- 打卡（`user_scenic_checkins`，权重 3）：用户实际到场，最强信号。
- 路线规划（`route_plans` 中起点/途经/终点节点所属景点，权重 2）：出行意图。
- 游记（`travel_diaries.scenic_spot_ids`，权重 1）：回顾性信号。

变更：

- 新增 `GET /api/v1/scenic-spots/<id>/popular-times`：单景点 24 小时人气画像。行为样本 ≥5 时按 60/40 与典型游客曲线混合（`source: "behavior+model"`），样本不足时回退纯模型曲线（`source: "model"`），保证图表始终可渲染；响应含各小时 level（0-100）、peakHours 与样本计数。
- `POST /api/v1/routes/plan/congestion` 接入行为画像：规划前按所选时段（±1 小时窗口）聚合各景点活跃度因子（按最大值归一化），活跃度 ≥0.66 的景点内部边拥挤度 +2、≥0.33 的 +1（上限 4），Dijkstra 自然倾向绕开热门区域；响应新增 `congestionSource`（`behavior+time` / `time-model`）与 `behaviorBoostedEdges`（被修正的边数）。
- 前端景点详情页新增「热门时段」卡片：6:00-22:00 柱状图，当前小时高亮，标注数据来源（用户行为数据 / 典型模型）与样本数。
- 前端路线规划页拥挤度模式下，若本次规划被行为画像修正，显示"已结合用户行为画像，共修正 N 条路段"提示。

验证口径：

- 后端 `tourism_server` 与前端生产构建均通过。
- `GET /api/v1/scenic-spots/<id>/popular-times` 对无行为数据的景点返回 `source: "model"` 的典型曲线；对有打卡/游记关联的景点（如 seed 演示景点）返回 `behavior+model` 并附样本计数。
- 拥挤度规划：在有打卡记录的时段调用 `/routes/plan/congestion`，响应 `behaviorBoostedEdges > 0` 且 `congestionSource: "behavior+time"`；删除行为数据后退化为 `time-model`，规划仍正常。
- 行为聚合 SQL 失败或无数据时，拥挤度规划完整回退原时段模拟逻辑，不影响可用性。

## 2026-06-11 / feature-lxd-search / 三项算法与体验优化（时间衰减热度、增量倒排索引、入口等时圈）

类型：排序算法、索引维护策略、前端可视化。

变更：

一、日记热度排序加时间衰减（重力公式）

- 原 `sort=popular` 为静态加权 `likes*2 + comments*3 + views*0.1`，老内容凭存量浏览永久霸榜。
- 改为 Hacker News 风格重力公式：`(likes*2 + comments*3 + views*0.1 + rating*rating_count) / (age_days + 2)^1.5`，互动得分随发布时间按 1.5 次幂衰减。
- `/diaries`、`/diaries/mine`、`/diaries/search/spot` 三处 popular 排序统一使用同一公式；响应新增 `sortAlgorithm` 字段，前端日记广场直接展示算法标签。

二、倒排索引增量更新（修复检索时效性问题）

- 原先日记创建/更新/删除后索引不更新，新发布日记在全文检索中不可见，需等待手动重建或重启。
- `IndexManager` 新增 `sync_document(db, doc_id)`（从 DB 重读单行、兼容压缩存储解压、先删后加，仅已发布日记入索引）与 `remove_document(doc_id)`；单行索引构建逻辑与全量重建共用同一函数。
- 日记 POST/PUT/DELETE 路径接入增量同步：发布即可检索、转草稿即移出索引、删除即时生效。复杂度从 O(全库重建) 降为 O(单篇)。
- 索引未构建时增量为空操作（首次检索的全量构建自然包含全部日记），增量失败不影响业务。

三、设施入口等时圈可视化

- 景点详情页设施查询在"步行距离排序"模式下，按入口实际步行时间分档着色（步速 1.2m/s）：≤5 分钟绿、≤10 分钟黄、≤15 分钟橙、>15 分钟红。
- 地图设施标记按等时圈分档着色（选中态与不可导航态保持原样式），面板新增图例。
- 目的设施下拉在距离（米）之外追加"步行约 X 分钟"。
- 复用既有 `walkDistance`（Dijkstra 实际路径距离），无后端改动、无新增请求。

验证口径：

- 后端 `tourism_server` 与前端生产构建均通过。
- `GET /api/v1/diaries?sort=popular` 响应带 `sortAlgorithm`，且同等互动量下新日记排序高于旧日记。
- 索引已构建状态下：新建并发布一篇日记后，立即用 `/diaries/search/fulltext?q=<正文词>` 应能检索到；删除后立即检索不到；无需调用 `/diaries/index/rebuild`。
- 打开有内部路网的景点详情页，设施面板出现"入口步行等时圈"图例，地图标记颜色与图例分档一致。

## 2026-06-10 / feature-lxd-search / 日记→路线一键复刻「重走这条路线」

类型：后端新接口、前端交互、UGC 与路线规划闭环。

背景：现实中用户的旅行决策路径是"看别人游记 → 手动到地图逐个搜地点"，游记内容与路线规划之间存在断层。本系统日记广场（UGC）与路线规划在同一系统内，本次将两者打通：任意一篇日记可以一键转化为可导航的路线。

变更：

- 后端新增 `GET /api/v1/diaries/<id>/replay-route`：提取日记关联/提及的景点序列。
  - 优先使用 `travel_diaries.scenic_spot_ids` 显式关联（保持数组顺序）。
  - 关联为空时回退"叙述顺序提取"：按景点名在标题+正文+标签中**首次出现的位置**排序匹配 `scenic_spots`（`STRPOS`），即复刻路线顺序等于游记的叙事顺序；同位置子串名去重（"故宫"是"故宫博物院"子串时跳过），上限 8 个站点。
  - 兼容压缩存储：正文为压缩行时先解压再做名称匹配。
  - 城市取站点中出现最多的非空 `city`，默认北京。
- 前端日记详情页新增「重走这条路线」按钮：调用上述接口后携带站点序列跳转 `/route`；识别景点不足 2 个时给出提示。
- 前端路线规划页支持复刻模式：读取 query 参数自动预填城市/出发点/途经点/目的地并自动规划，顶部显示"正在重走日记路线《标题》"横幅，用户可调整途经点后重新生成。

验证口径：

- 后端 `tourism_server` 与前端生产构建均通过。
- 对 seed 中带 `scenic_spot_ids` 的演示日记调用 `/replay-route`，应返回 `source: "spot-ids"` 与有序站点。
- 对正文提及多个景点但无显式关联的日记，应返回 `source: "narrative-extraction"`，站点顺序与正文叙述顺序一致。
- 日记详情页点击按钮后跳转路线规划页，表单已预填并自动出路线；横幅显示日记标题。

## 2026-06-10 / feature-lxd-search / 日记 Huffman 压缩真实落库

类型：数据库结构、后端存储路径、倒排索引、前端展示。

背景：此前 Huffman 压缩只是独立演示 API，`travel_diaries.content` 实际存明文，不满足"日记压缩存储"的字面要求。本次把压缩做进真实写入/读取路径。

变更：

- 新增迁移 `database/migrations/diary_compression_schema.sql`：`travel_diaries` 增加 `content_compressed BYTEA`（压缩字节流，NULL=明文存储）与 `content_original_bytes INTEGER`（原文字节数）两列，幂等可重复执行。
- 后端创建/更新日记时自动 Huffman 压缩：仅当压缩结果小于原文时存压缩列并将 `content` 置空（短于 64 字节或压缩无收益的文本保持明文，避免频率表头开销反向膨胀）。
- 所有日记读取路径（列表、详情、mine、检索）透明解压，前端无感知；响应新增 `compressedStorage` 与 `spaceSavedPercent` 字段。
- 倒排索引构建（`index_manager.cpp`）读取压缩列并解压后建索引，全文检索不受压缩影响。
- 新增 `GET /api/v1/diaries/compression/stats`：全站压缩存储统计（总数、已压缩数、原始/压缩字节、节省比例）。
- 新增 `POST /api/v1/diaries/compression/migrate`（需登录）：存量明文日记一键批量压缩。
- 前端：日记详情页显示"已压缩存储 · 省 X%"徽标；`/tools/huffman` 页定位改为"日记存储引擎"说明页，顶部新增系统实时存储统计卡片。

已知取舍：

- 压缩行的 `content` 为空，因此基础 LIKE 检索（`/diaries?q=`）只覆盖标题+摘要；全文内容检索由倒排索引端点（`/diaries/search/fulltext`）承担，这与真实系统"存储压缩、检索走索引"的架构一致。

验证口径：

- 后端 `tourism_server` 与前端生产构建均通过。
- 执行迁移 SQL 后：新建一篇长日记，`SELECT content = '', OCTET_LENGTH(content_compressed), content_original_bytes FROM travel_diaries WHERE id = <新id>` 应显示明文为空、压缩字节小于原文字节。
- 日记详情接口返回的 `content` 应与提交原文一致（解压还原），并带 `compressedStorage: true`。
- `GET /api/v1/diaries/compression/stats` 的 `savedPercent` 应大于 0。
- 全文检索 `/diaries/search/fulltext?q=<正文词>` 仍能命中压缩存储的日记。

补记：

- 新增 `GET /api/v1/diaries/<id>/compression`，补齐日记详情页单篇压缩信息卡片所需接口，避免前端请求 404 后只能回退为 `0 bytes / 等待校验` 的占位展示。
- 同步修正 `frontend/src/tests/tourismApi.test.js` 的 Huffman 测试契约：请求字段改为 `content` / `compressed`，响应字段改为 `originalBytes`、`compressedBytes`、`compressionRatio`、`content`。

## 2026-06-12 / feature-lxd-search / 路线规划剩余问题收尾

类型：路线规划、前后端联动、数据库 seed、开发脚本。

背景：此前路线页还残留 3 类问题。第一，拥挤度模式里早高峰/深夜、时间优先/距离优先看起来完全一样；第二，拥挤度模式在 7:00 一类高峰时段会画成节点直连折线；第三，队友拉到修复代码后如果本地数据库没同步 `seed_demo.sql`，页面仍可能继续显示旧的直线演示图。另有一个工程层面的隐患：开发启动脚本固定指向旧构建目录，容易出现“代码已改但实际跑的是旧后端”。

变更：

- 前端 `RoutePlan.vue` 的拥挤度模式不再把本地 Dijkstra 结果交给高德二次重算，而是直接使用后端返回的 `coordinates / pathEdges / requestedPlaces`。
  - 这样入口、换乘点等非 scenic 中间节点不会再被高德重投影吞掉。
  - 结果是“时间优先高峰绕行 / 距离优先直走 / 深夜恢复直走”的差异终于能在地图上真实显示出来。
- 后端 `computed_route_json()` 追加 `requestedPlaces`，把本地路网每个停靠点的真实坐标一并返回，前端画点不再退回到折线首尾猜测。
- `database/seeds/seed_demo.sql` 为演示 `graph_edges` 补齐正式 `geometry`，包括：
  - `天安门广场 -> 故宫博物院` 主通道；
  - `天安门广场 -> 故宫北门换乘点 -> 故宫博物院` 绕行通道；
  - 其余北海/鼓楼/国博/前门/王府井等演示边。
  这样拥挤度模式即使完全不调用高德，也会画出道路形态，而不是只剩节点直连线。
- 标准文本地点路线规划把 `optimization` 继续下传到高德服务层：
  - 驾车/公交会带上策略参数；
  - 同时不再盲取第一个候选，而是按 `duration` 或 `distance` 从高德返回候选里选最优方案；
  - 响应新增 `optimization`，`bestFor` 改为中文“时间优先 / 距离优先 / 均衡 · 高德路线规划”。
- `seed_demo.sql` 的成就、用户成就、数字藏品 seed 改成按 `code` 关联与 upsert，重跑不再因为 `achievements.code` 唯一键冲突而整段回滚。
- `scripts/run_backend_dev.cmd` / `scripts/run_backend_dev.ps1` 改为优先启动 `backend/build-mingw/bin/tourism_server.exe`，找不到时再回退旧目录，避免开发环境继续误跑过期后端。

验证口径：

- 重新执行 `database/seeds/seed_demo.sql` 后，以下 2 条边应有真实 `LINESTRING`：
  - `graph_edges(2 -> 1, walk)`；
  - `graph_edges(2 -> 104, walk)`。
- 拥挤度接口：
  - `POST /api/v1/routes/plan/congestion`，`start_id=2,end_id=1,travel_mode=walk,optimization=distance,hour=7` 应返回直达 `天安门广场 -> 故宫博物院`。
  - 同一请求改为 `optimization=time,hour=7` 应返回 `天安门广场 -> 故宫北门换乘点 -> 故宫博物院`。
  - 同一请求改为 `optimization=time,hour=23` 应恢复直达。
- 实测本地结果：
  - 高峰 `distance@7`：1.1 km / 15 分钟，主通道直达；
  - 高峰 `time@7`：2.2 km / 25 分钟，经“故宫北门换乘点”绕行；
  - 深夜 `time@23`：回到 1.1 km / 15 分钟直达。
- 普通文本地点路线规划：
  - 优化目标现在已经真实传给高德，部分点对可出现差异，例如本地实测 `中国国家博物馆 -> 圆明园` 驾车 `time=21.4 km / 37 分钟`，`distance=20.8 km / 36 分钟`；
  - 但对少数点对，高德本身仍可能返回同一路径，这是上游提供者的候选结果限制，不再是我们前后端把优化目标静默丢失。

补记：

- 如果队友 `git pull` 后路线页仍显示旧的直线演示图，优先检查是否已重跑 `database/seeds/seed_demo.sql`；这次路线修复有一部分落在正式 seed 数据里，不只是前后端代码。

## 2026-06-13 / feature-lxd-search / 推荐排序恢复真实差异、定位路线可感知、开发启动链纠偏

类型：推荐算法、路线规划交互、开发脚本、验收稳定性。

背景：验收复测时发现三个表面上像“功能做了但没起作用”的问题。第一，推荐页切换“个人兴趣 / 评价 / 热度”后结果几乎不变；第二，路线规划页点击“定位路线”缺少明显反馈，用户主观感受接近“没反应”；第三，拥挤度感知和“时间优先 / 距离优先”虽然代码里已有差异化逻辑，但实际复测经常看起来还是一样。继续排查后确认，问题不只在算法本身，也在开发环境长期误跑旧的 `build-mingw` 后端可执行文件，导致“代码已经改了，页面却还像旧版本”。

变更：

- 修正 `scripts/run_backend_dev.ps1`，与 `run_backend_dev.cmd` 保持一致：
  - 候选可执行文件加入 `backend/build/bin/Release/tourism_server.exe`
  - 改为按最后修改时间选择最新构建产物
  - 避免 PowerShell 脚本继续固定优先启动旧 `build-mingw` 版本
- 调整推荐算法权重与可解释指标：
  - `RecommendationScore` 新增 `intensity_score`、`hot_signal_score`
  - 个人兴趣排序不再只被“评分 4.2 大面积并列”拖平，而是额外考虑游玩时长与动态热度信号
  - 评价排序继续以评分为主，但用热度信号和综合分兜底，减少大面积并列时的“排序切了像没切”
  - 热度排序直接按真实行为信号排名：收藏、打卡、游记提及、路线引用，加上历史收藏/浏览兜底
- 推荐接口 `POST /api/v1/recommendations/personalized` 的展示字段同步增强：
  - `displayValue` 在热度模式下优先返回真实热度信号值，而不是仅返回归一化热度分
  - `scoreBreakdown` 增加 `intensityScore` 与 `hotSignalScore`
  - `algorithm` 描述更新为“兴趣 + 评分 + 动态热度 + 时长”的实际逻辑
- 路线规划页“定位路线”按钮补足可感知交互：
  - `fitRoute()` 改为 `flyToBounds()` + `maxZoom`
  - 定位时对路线折线做短暂高亮，对起终点 tooltip 做短暂提示
  - 解决“地图明明重新 fit 了，但用户肉眼几乎感觉不到变化”的体验问题

验收口径：

- 推荐排序接口实测：
  - `sortBy=interest` 前列结果为 `颐和园 -> 中国国家博物馆 -> 故宫博物院`
  - `sortBy=rating` 前列结果为 `中国国家博物馆 -> 故宫博物院 -> 颐和园`
  - `sortBy=hot` 前列结果为 `中国国家博物馆 -> 故宫博物院 -> 正阳门箭楼 -> 鼓楼`
  - 三种排序结果已不再“看起来完全一样”
- 当前库中 `scenic_spots.view_count` / `favorite_count` 仍几乎全为 0，因此热度排序的主要有效信号来自：
  - `user_favorites`
  - `user_scenic_checkins`
  - `travel_diaries.scenic_spot_ids`
  - `route_plans` 引用到的 `graph_nodes.scenic_spot_id`
- 拥挤度接口实测（`start_id=6,end_id=1,travel_mode=walk`）：
  - `distance @ 07:00`：`6 -> 102 -> 2 -> 1`，`2.3 km / 58 分钟`
  - `time @ 07:00`：`6 -> 102 -> 2 -> 104 -> 1`，`3.5 km / 53 分钟`
  - `time @ 23:00`：回到 `6 -> 102 -> 2 -> 1`，`2.3 km / 32 分钟`
  - 说明“时间优先”和“距离优先”在高峰时段已经能真实走出不同路径，而非前端演示差异

补记：

- 这次问题里最隐蔽的不是算法，而是“误跑旧后端”造成的假回归。后续如果再出现“代码改了但页面完全没变化”，优先先确认实际监听 8080 的可执行文件路径。

## 2026-06-07 / local-save-tourism / 课设算法与演示数据补齐归档

类型：历史变更归档、算法能力、演示数据、工程清理。

背景：根目录历史文档 `CHANGES.md` 记录了早期课设算法补齐过程，但与当前文档职责冲突。有效内容归档到本文后，根目录不再保留阶段流水文档。

归档内容：

- 路线算法：新增多点环游 TSP 能力，按点数选择枚举、回溯、分支限界或近邻 + 2-opt；新增拥挤度感知 Dijkstra。
- 排序算法：推荐和美食模块使用 `TopKSelector` 做 Top-K 部分排序。
- 游记算法：新增 Huffman 压缩工具、倒排索引/BM25、标题 Hash 检索和景点倒排检索。
- 美食模块：新增 `/api/v1/foods`、`/api/v1/foods/cuisines`，菜系由设施名称推断，排序支持热门、评分和距离。
- 数据补齐：补演示用户、设施和美食 seed；后续正式初始化命令以 `database/README.md` 为准。
- 工程修复：新增数据库连接池、自包含 `test_algorithms` 目标、前端 API 测试草稿和压力测试脚本。

后续口径：

- 运行命令只维护在 `QUICKSTART.md`。
- 数据库导入顺序只维护在 `database/README.md`。
- API 契约只维护在 `docs/api-runtime.md`。
- 普通工程变更继续追加本文，不再新增根目录交接/阶段文档。

## 2026-06-12 / codex-structure-cleanup / 日记动画闭环与工程结构整理

类型：日记动画、数据库目录、文档收敛、测试契约、工程清理。

变更：

- 新增正式迁移 `database/migrations/diary_animation_schema.sql`，只为 `travel_diaries` 增加 `videos TEXT[]` 与 `animation_storyboard JSONB`，继续沿用既有 `content_compressed` / `content_original_bytes` 压缩字段。
- 后端日记创建、更新和读取补齐 `videos` 字段；新增 `POST /api/v1/diaries/<id>/animation`，基于标题、正文、图片和视频 URL 生成本地确定性动画分镜并覆盖保存。
- 数据库目录收敛：增量结构迁移进入 `database/migrations/`，正式 seed 进入 `database/seeds/`，保留 `imports/` 与 `maintenance/`。
- 清理根目录历史/临时入口：`CHANGES.md` 有效信息补录本文后删除；删除 `HANDOFF.md`、`tmp_pku_spots.csv`、过期 `api/api-definition.yaml`、旧 `docs/api.md`；启动脚本移动为 `scripts/start_all.cmd`。
- 前端默认测试改为顺序执行 auth/坐标测试、API 客户端测试和轻量 API 契约脚本；契约脚本会比对 `tourismApi.js` 路径与后端 `CROW_ROUTE`。
- 更新 `README.md`、`QUICKSTART.md`、`database/README.md`、`docs/api-runtime.md` 和 `AGENTS.md` 的权威入口、初始化顺序和日记动画说明。
- 继续拆分后端日记相关 route：`huffman_routes` 独立承接 `/api/v1/huffman/compress` 与 `/api/v1/huffman/decompress`；`diary_compression_routes` 独立承接压缩统计与单篇压缩详情，公开路径保持不变。

验证口径：

- 前端 API 单测应通过 24 条用例，覆盖 `generateDiaryAnimation`、压缩统计/迁移、跨层路线、景点设施和拥挤度路线。
- `npm.cmd run test:contract` 应显示 `API contract check passed`，避免再次出现前端调用有路由、后端无路由的半成品状态。
- 后端增量构建应通过；如果 `tourism_server.exe` 正在运行，需要先停止占用进程再链接。

## 2026-06-09 / feature-yhm-graph / 室内导航中文化

类型：室内导航、数据 seed、后端响应、前端文案、文档规范。

变更：

- 将 `database/seeds/seed_indoor_navigation.sql` 中北大红楼室内建筑、楼层、节点名称改为中文。
- 将后端室内节点类型、边类型、路线步骤说明改为中文。
- 将室内导航面板中的 provider、算法、策略、耗时、路线步骤说明改为中文展示。
- 删除不正式的数据核查脚本，后续以 SQL 文件、导入顺序和数据库查询结果作为核查口径。
- 将室内导航相关协作文档和 ADR 改为中文，并补充“以后中文优先”的规则。

验证口径：

- 重新执行 `database/seeds/seed_indoor_navigation.sql` 后，北大红楼室内节点应显示为“主入口、一层大厅、票务服务台、基本陈列展厅”等中文名称。
- `GET /api/v1/indoor-buildings/<id>/features` 应返回中文 `typeLabel` 和中文 `edgeTypeLabel`。
- `POST /api/v1/indoor-buildings/<id>/routes/plan` 的 `steps[].instruction` 应为中文。

## 2026-06-09 / feature-yhm-graph / 室内拓扑导航界面

类型：室内导航、前端交互、API 响应。

变更：

- 扩展 `GET /api/v1/indoor-buildings/:id/features`，在原有 `items/floors/types` 基础上新增 `edges` 数组，数据来自 `indoor_edges`。
- 将室内导航面板从表单式选择器改为“SVG 拓扑图 + 路由控制台”。
- 增加楼层切换、节点/边绘制、路线高亮、跨楼层提示、搜索式起终点选择和策略切换。

验证：

- 前端 lint 和生产构建通过。
- 后端 `tourism_server` 构建通过。
- 建筑 1 的 API 返回 10 个室内节点、2 个楼层、18 条有向边。
- 从节点 1 到节点 8 的路线返回 `indoor-dijkstra`，路径包含 5 个节点、4 个步骤，并包含 F1 到 F2 的楼梯跨层段。

## 2026-06-09 / feature-yhm-graph / 室内导航工程流程

类型：室内导航、数据库流程、文档。

变更：

- 增加正式室内导航表和 seed 文件：`database/indoor_navigation_schema.sql`、`database/seeds/seed_indoor_navigation.sql`。
- 使用 `local_indoor_graph` 为北大红楼建立首批本地室内图数据。
- 更新快速启动和数据库说明，明确 `git pull` 只更新代码和 SQL 文件，不会自动改变队友本地 PostgreSQL 数据。
- 明确已有数据库必须在同一个 `tourism_system` 中执行室内导航迁移和 seed。

验证口径：

- `database/indoor_navigation_schema.sql` 通过 `CREATE TABLE IF NOT EXISTS` 保持幂等。
- `database/seeds/seed_indoor_navigation.sql` 使用稳定 `source_ref` 做 upsert。
- 预期 seed 结果：1 栋北大红楼室内建筑、2 个楼层、10 个节点、18 条有向边。

注意：

- 不为室内导航创建第二个数据库。
- 不为普通分支协作重复创建新的交接文档。
- 数据核查优先使用 SQL 查询和数据库导入记录，不再以独立脚本作为正式流程。
