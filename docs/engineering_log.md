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
