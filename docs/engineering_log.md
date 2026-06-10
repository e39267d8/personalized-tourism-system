# 工程记录

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

## 2026-06-10 / feature-lxd-search / 文档职责收敛

类型：文档规范、协作规则、API 文档补全。

背景：此前 README、AGENTS、QUICKSTART 和分支交接文档之间存在职责重叠，容易在每次拉分支后继续复制 `changes_after_xxx.md`。本次按统一规则收敛：README 只放项目总览，QUICKSTART 只放运行和初始化步骤，AGENTS 只放工程规则，普通工程变更统一写入本文，重大技术决策写入 ADR。

变更：

- 将 `README.md` 收敛为项目总览和文档入口，移除运行命令、环境变量、专题实现细节和阶段流水。
- 在 `AGENTS.md` 明确文档职责、数据库变更正式口径，以及不再创建 `changes_after_xxx.md` 的协作规则。
- 删除历史分支交接文档 `docs/changes_after_lxd.md`，其有效内容已由 `docs/engineering_log.md`、`docs/adr/0001-indoor-navigation-provider.md`、`QUICKSTART.md` 和 `database/README.md` 承接。
- 补全 `docs/api-runtime.md` 中游记运行时 API：全文检索、按标题/景点检索、`GET /api/v1/diaries/<id>/replay-route`、压缩统计/迁移接口和 Huffman 工具接口。
- 明确 Huffman 工具接口不是日记压缩落库的权威路径；真实存储以日记创建/更新、压缩迁移接口和 `database/diary_compression_schema.sql` 为准。

验证口径：

- 文档检索中不再存在 `docs/changes_after_lxd.md`，`changes_after_xxx` 只保留在 AGENTS 的禁止规则里。
- `docs/adr/0001-indoor-navigation-provider.md` 已正式记录室内导航采用 `amap_indoor` + `local_indoor_graph` provider 模型的架构决策。
- `docs/engineering_log.md` 已包含“日记→路线一键复刻”和“日记 Huffman 压缩真实落库”两项工程记录，`docs/api-runtime.md` 已补齐对应 API 契约。

## 2026-06-10 / feature-lxd-search / 北京大学校园内部道路图

类型：校园内部导航、数据库导入、真实地图数据、文档。

背景：课程设计要求景区和校园都应有内部道路图。北大红楼室内导航只覆盖单体建筑室内拓扑，不能替代北京大学校园级道路图；校园内部图必须进入现有 `graph_nodes`、`graph_edges`、`facilities`，不新建第二套校园图表。

变更：

- 新增 `database/seed_campus_spots.sql`：把北京大学作为 `scenic_spots` 中的正式校园对象接入系统，分类为“高校校园”。
- 新增 `scripts/pku_campus_spots.json`：北京大学校园生成配置，包含燕园主校区边界和排除词，避免把清华或中关村周边 POI 算入北大校园。
- 新增 `database/imports/internal_navigation_pku.sql`：北京大学校园内部道路图导入 SQL，数据来自 OSM/Overpass；导入前会清理同一景点下旧的 `pku:%` 内部图数据，再写入当前校园范围，保持幂等。
- 扩展 `scripts/import_internal_map_data.py`：支持按 `bounds` 和 `exclude_terms` 过滤节点/边，并在生成 SQL 中加入旧内部图清理段，避免重复导入造成历史宽范围数据残留。
- 更新 README、QUICKSTART 和数据库说明，补充校园内部图导入顺序、只补校园图命令、验证 SQL，并明确“北京大学校园内部道路图”和“北大红楼室内导航”是两项不同能力。

验证口径：

- 已在本地 `tourism_system` 执行：
  - `database/internal_navigation_schema.sql`
  - `database/seed_campus_spots.sql`
  - `database/imports/internal_navigation_pku.sql`
- 导入日志显示旧宽范围 `pku:%` 数据被清理后重新写入：794 个 PKU 图节点、402 条 OSM 道路边、567 条设施表记录、358 条设施接入边。
- 正式表统计结果：北京大学校园范围内 794 个图节点、760 条内部图边，其中 OSM 真实道路边 402 条、设施接入边 358 条；建筑节点 449 个，非建筑服务设施 118 个、10 类。
- `facilities` 表总计 567 条是因为建筑节点也会以 `building` 类型同步到设施表；课程设计口径下，“其它服务设施”按 `type <> 'building'` 统计。
- 课程设计口径下，校园内部道路图满足边数不少于 200、建筑不少于 20、其它服务设施不少于 50 且服务设施类型不少于 10 的要求。

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

- 新增迁移 `database/diary_compression_schema.sql`：`travel_diaries` 增加 `content_compressed BYTEA`（压缩字节流，NULL=明文存储）与 `content_original_bytes INTEGER`（原文字节数）两列，幂等可重复执行。
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

## 2026-06-09 / feature-yhm-graph / 室内导航中文化

类型：室内导航、数据 seed、后端响应、前端文案、文档规范。

变更：

- 将 `database/seed_indoor_navigation.sql` 中北大红楼室内建筑、楼层、节点名称改为中文。
- 将后端室内节点类型、边类型、路线步骤说明改为中文。
- 将室内导航面板中的 provider、算法、策略、耗时、路线步骤说明改为中文展示。
- 删除不正式的数据核查脚本，后续以 SQL 文件、导入顺序和数据库查询结果作为核查口径。
- 将室内导航相关协作文档和 ADR 改为中文，并补充“以后中文优先”的规则。

验证口径：

- 重新执行 `database/seed_indoor_navigation.sql` 后，北大红楼室内节点应显示为“主入口、一层大厅、票务服务台、基本陈列展厅”等中文名称。
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

- 增加正式室内导航表和 seed 文件：`database/indoor_navigation_schema.sql`、`database/seed_indoor_navigation.sql`。
- 使用 `local_indoor_graph` 为北大红楼建立首批本地室内图数据。
- 更新快速启动和数据库说明，明确 `git pull` 只更新代码和 SQL 文件，不会自动改变队友本地 PostgreSQL 数据。
- 明确已有数据库必须在同一个 `tourism_system` 中执行室内导航迁移和 seed。

验证口径：

- `database/indoor_navigation_schema.sql` 通过 `CREATE TABLE IF NOT EXISTS` 保持幂等。
- `database/seed_indoor_navigation.sql` 使用稳定 `source_ref` 做 upsert。
- 预期 seed 结果：1 栋北大红楼室内建筑、2 个楼层、10 个节点、18 条有向边。

注意：

- 不为室内导航创建第二个数据库。
- 不为普通分支协作重复创建新的交接文档。
- 数据核查优先使用 SQL 查询和数据库导入记录，不再以独立脚本作为正式流程。
