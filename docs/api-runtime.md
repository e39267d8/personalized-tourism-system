# 运行中的 API 文档

本文记录当前前端实际调用、后端实际注册的 API。旧文档中出现过早期草稿接口，当前以本文为准。

默认后端地址：

```text
http://127.0.0.1:8080
```

前端开发环境请求：

```text
/api/v1/...
```

Vite 会把 `/api` 代理到后端。

## 通用响应

接口通常返回 JSON。前端 `frontend/src/services/tourismApi.js` 会解包：

```js
const unwrap = (response) => response.data?.data ?? response.data
```

错误响应尽量使用：

```json
{
  "code": "error_code",
  "message": "可读错误信息"
}
```

## 健康检查与概览

### `GET /health`

检查后端是否启动。

### `GET /`

返回后端 API 简要信息。

### `GET /api/v1/dashboard`

首页统计和概览数据。

### `GET /api/v1/achievements`

成就页数据。

成就系统当前公开接口：

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/api/v1/achievements` | 成就总览、护照层级、解锁状态、下一步建议 |
| `POST` | `/api/v1/scenic-spots/<id>/checkins` | 景点打卡，返回新解锁成就 |
| `POST` | `/api/v1/achievements/<id>/claim` | 领取数字纪念凭证 |
| `GET` | `/api/v1/collectibles` | 我的数字纪念凭证列表 |
| `GET` | `/api/v1/collectibles/<id>` | 单张数字纪念凭证详情 |
| `POST` | `/api/v1/badge-redemptions` | 提交实体徽章申请 |
| `GET` | `/api/v1/badge-redemptions` | 查询我的实体徽章申请 |
| `GET` | `/api/v1/achievement-review-submissions` | 评审队列，仅评审账号可用 |
| `POST` | `/api/v1/achievement-review-submissions/<id>/decision` | 评审通过或驳回，仅评审账号可用 |

数据库同步口径：

- 结构迁移：`database/migrations/achievement_module_schema.sql`
- 演示数据：`database/seeds/seed_achievements.sql`

运行时 `achievement_service.cpp` 仍保留兼容性兜底，但正式协作流程以 SQL 迁移和 seed 为准。

## 景点

### `GET /api/v1/scenic-spots`

景点列表和搜索结果。

常见查询参数：

- `q`: 关键词。
- `category` 或 `category_id`: 分类。
- `limit`: 返回数量。
- `offset`: 分页偏移。
- `max_ticket` 或 `maxTicket`: 最高票价。
- `sort`: 排序方式，支持 `relevance`、`rating`、`hot`、`price`。

查询能力：

- 名称：精确、前缀、包含匹配。
- 中文简称：按字顺序连字匹配，例如“国博”命中“中国国家博物馆”。
- 类别：按 `categories.name` 匹配，例如“博物馆”“公园”“校园”。
- 关键字：匹配景点标签和描述，描述匹配作为兜底，避免过宽召回。

查询性能：

- `database/migrations/scenic_search_indexes.sql` 启用 `pg_trgm`，为名称、描述、分类名补充模糊检索索引。
- 同一迁移补充 `status + rating/view_count/favorite_count` 组合排序索引，支撑评分优先和热度优先。

前端调用：

```js
tourismApi.scenicSpots(params)
```

### `GET /api/v1/scenic-spots/search`

兼容保留的景点搜索接口，能力接近列表搜索。

### `GET /api/v1/scenic-categories`

获取景点分类。

### `GET /api/v1/search/suggestions`

获取搜索建议词。

常见查询参数：

- `q`: 当前输入关键词。

### `GET /api/v1/scenic-spots/<id>`

景点详情。

### `GET /api/v1/scenic-spots/<id>/reviews`

景点详情页的评价列表。

### `GET /api/v1/scenic-spots/<id>/popular-times`

景点 24 小时人气画像（热门时段）。数据来自系统自有用户行为：
打卡（权重 3）、路线规划（权重 2）、游记（权重 1）按小时聚合。

- 行为样本 ≥5：与典型游客曲线按 60/40 混合，`source: "behavior+model"`。
- 样本不足：回退纯模型曲线，`source: "model"`，保证图表始终可渲染。

响应核心字段：`hours[]`（`{hour, level}`，level 0-100）、`peakHours[]`（level ≥80 的小时）、
`samples`（`total` / `checkins` / `diaries`）。

同一套行为画像也用于 `POST /api/v1/routes/plan/congestion`：规划前按所选时段
（±1 小时窗口）计算各景点活跃度因子，活跃度高的景点内部边拥挤度上调
（≥0.66 加 2 级、≥0.33 加 1 级，上限 4），使 Dijkstra 倾向绕开热门区域。
该接口响应附 `congestionSource`（`behavior+time` / `time-model`）与
`behaviorBoostedEdges`（被修正的边数）。

### 室内导航

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/api/v1/scenic-spots/<id>/indoor-buildings` | 查询景点已接入的室内导航建筑 |
| `GET` | `/api/v1/indoor-buildings/<id>/features` | 查询室内楼层、节点、类型和拓扑边 |
| `POST` | `/api/v1/indoor-buildings/<id>/routes/plan` | 基于室内图规划路线 |
| `POST` | `/api/v1/indoor-buildings/<id>/routes/plan-cross` | 跨层规划：景区路网起点 → 建筑入口 → 室内终点 |

`features` 响应包含 `items`、`floors`、`types` 和 `edges`。其中
`items` 来自 `indoor_features`，`edges` 来自 `indoor_edges`，前端用它们绘制
SVG 室内拓扑图。

路线规划 payload：

```json
{
  "startFeatureId": 1,
  "endFeatureId": 8,
  "strategy": "time"
}
```

路线响应包含 `distanceMeters`、`durationSeconds`、`algorithm`、`path` 和
`steps`。`path` 用于拓扑图节点高亮，`steps` 用于展示楼层内和跨楼层路径步骤。

跨层规划 `plan-cross` payload：

```json
{
  "startNodeId": 123,
  "endFeatureId": 8,
  "strategy": "time"
}
```

`startNodeId` 是景区路网 `graph_nodes` 节点。后端先在室外图上跑 Dijkstra
到建筑的室外锚点（`indoor_buildings.outdoor_node_id`，由
`database/migrations/cross_layer_navigation_schema.sql` 按名称自动绑定），再从室内
`entrance` feature 跑室内 Dijkstra 到终点。响应字段：

- `outdoor`：室外段，结构与路线规划接口一致（含地图坐标）。
- `indoor`：室内段，结构与室内规划接口一致（含 `steps` / `path`）。
- `handoff`：交接信息（`outdoorNodeId` / `outdoorNodeName` / `entranceFeatureId` / `entranceName`）。
- `totalDistanceMeters` / `totalDurationSeconds`：两段合计。
- `algorithm`: `cross-layer-dijkstra`。

建筑未绑定室外锚点且名称匹配失败时返回 422 与明确错误信息，纯室内导航不受影响。

## 推荐与预算

### `GET /api/v1/budget-plans`

根据预算返回路线或行程预算方案。

常见查询参数：

- `budget`: 预算金额。
- `days`: 天数。

### `GET /api/v1/recommendations/scenic-spots`

获取推荐景点列表。

常见查询参数：

- `limit`
- `category`
- `budget`

### `POST /api/v1/recommendations/personalized`

根据用户偏好生成个性化推荐。

payload 常见字段：

- `preferredCategories`: 偏好分类。
- `preferredTags`: 偏好标签。
- `budgetLevel`: 预算偏好。
- `crowdPreference`: 人流偏好。
- `intensity`: 游玩强度。
- `sortBy`: 推荐排序，支持 `interest`、`rating`、`hot`，省略时默认 `interest`。

响应补充字段：

- `sortBy`: 本次实际采用的排序模式。
- `topKStrategy`: Top-K 部分排序说明。
- `algorithm`: 推荐分和排序模式说明。
- `scoreBreakdown.hotScore`: 热度分，基于浏览量和收藏量的对数缩放。

后端推荐不会先全量排序再截取前 10，而是使用小顶堆维护 Top-K 候选池：
扫描候选景点/学校时只保留当前最好的 `limit` 个结果，复杂度约为 `O(n log k)`。

## 美食

### `GET /api/v1/foods`

按景点或学校推荐附近餐饮。前端 `/food` 使用同一接口同时服务景点和高校校园；学校在数据库中仍复用
`scenic_spots` 口径，例如“北京大学”属于“高校校园”分类。

常见查询参数：

- `scenic_spot_id`: 景点或学校 ID。传入后可按该位置中心点计算距离；省略时返回全局候选。
- `q`: 模糊查询关键词，匹配餐饮名称、地址、菜系、景点/学校名称和导入元数据中的英文/中文别名。
- `cuisine`: 菜系 key，例如 `coffee_shop`、`noodle`、`roast_duck`。
- `sort`: `hot`、`rating`、`distance`。`distance` 需要 `lat/lng` 或 `scenic_spot_id`，否则后端会降级为 `hot` 并在响应 `sort` 中返回实际排序。
- `lat` / `lng`: 用户当前位置，可用于距离排序。
- `limit`: 返回数量，默认 10，上限 50。前端默认只取前 10 家。

响应核心字段：

- `items`: 推荐餐饮列表。
- `matchedTotal`: Top-K 前的匹配候选数。
- `returned` / `total`: 实际返回数量。
- `sort`: 本次实际排序。
- `items[].hotScore`: 综合热度分，来自评分、信息完整度、价格友好度和类型可信度的派生分。
- `items[].distanceMeters`: 到用户位置或所选景点/学校中心点的直线距离。
- `items[].locationTypeLabel`: `景点` 或 `学校`。
- `items[].scenicSpotId` / `items[].scenicName`: 所属景点或学校。

后端排序不会先全量排序再截取前 10，而是由 `TopKSelector` 扫描候选并维护前 K 个结果。

### `GET /api/v1/foods/cuisines`

返回可用菜系列表。支持同样的 `scenic_spot_id` 参数，用于按景点或学校收窄菜系 chips。

## 路线

### `GET /api/v1/route-nodes`

获取路线图节点。

### `GET /api/v1/routes`

获取已有路线或演示路线列表。

### `POST /api/v1/routes/plan`

规划路线。

文本地点模式：

```js
tourismApi.planRoute({
  city: '北京',
  startText: '故宫',
  endText: '天坛',
  waypointTexts: ['北海公园'],
  travelMode: 'driving',
  optimization: 'balanced'
})
```

节点 ID 模式：

```js
tourismApi.planRoute({
  startNodeId: 1,
  endNodeId: 2,
  waypointNodeIds: []
})
```

文本地点模式会调用高德 Web Service。后端内置一个免费默认高德 key；如果设置了 `AMAP_WEB_SERVICE_KEY` 或 `AMAP_KEY`，环境变量会优先生效。

### `POST /api/v1/routes/tour`

多目标智能环游路线。第一个点是用户手动输入并解析出的当前位置 / 出发点；目标地点只在目标集合里编号，不包含出发点和最后返回出发点。

推荐 payload：

```js
tourismApi.tourRoute({
  startNodeId: 1,
  targetNodeIds: [2, 3, 4, 5],
  fixedOrders: [
    { nodeId: 4, order: 2 }
  ],
  travelMode: 'walk',
  optimization: 'balanced'
})
```

语义：

- `startNodeId`: 固定出发点，路线最后会返回这里。
- `targetNodeIds`: 需要参观的目标景点 / 学校节点，至少 2 个。
- `fixedOrders`: 可选。`order=2` 表示该目标是所有目标中的第 2 个到达，不把出发点算作第 1 站。
- 未指定顺序的目标由后端在剩余位置中自动求最短闭环，不使用随机排列。
- 旧 payload `{ nodeIds: [...] }` 仍兼容，解释为第一个节点是出发点，其余节点是目标。

响应会包含 `returnToStart: true`、`startNodeId`、`targetNodeIds`、`fixedOrders`、`visitOrder`、`stops`、`distance`、`time` 和 `routeQuality`。`stops` 包含最后返回出发点，`visitOrder` 用于展示访问顺序。

返回用途：

- 前端路线结果卡片。
- Leaflet 折线和 marker。
- 导航步骤列表。

## 游记

### `GET /api/v1/diaries`

游记广场列表。

常见查询参数：

- `q`
- `limit`
- `offset`
- `sort`

`sort=popular` 使用时间衰减热度排序（Hacker News 风格重力公式）：
`(likes*2 + comments*3 + views*0.1 + rating*rating_count) / (age_days + 2)^1.5`，
互动得分随发布时间衰减，新优质内容可以浮上来。此时响应附带 `sortAlgorithm` 字段，
前端直接展示。`GET /api/v1/diaries/mine` 与 `GET /api/v1/diaries/search/spot`
的 `sort=popular` 使用同一公式。

### `GET /api/v1/diaries/search`

游记搜索。

### `GET /api/v1/diaries/search/fulltext`

倒排索引全文检索，用于游记广场的增强搜索。

常见查询参数：

- `q`: 必填，检索关键词。
- `mode`: 检索模式，默认 `any`。
- `limit`: 返回数量，默认 30，上限 100。

响应包含 `total`、`items`、`algorithm`、`indexSize`。当前算法标识为
`inverted-index-bm25`。后端读取游记正文时会透明处理 `content_compressed`，
因此 Huffman 压缩存储后的游记仍可被检索。

### `GET /api/v1/diaries/search/title`

按标题精准索引检索。查询参数 `title` 必填，响应包含 `items` 和
`algorithm: "hash-title-index"`。

### `GET /api/v1/diaries/search/spot`

按景点检索游记。常见查询参数：

- `scenic_spot_id`: 必填，景点 ID。
- `sort`: `latest`、`rating` 或 `popular`。
- `limit`: 返回数量，默认 30，上限 100。

### `GET /api/v1/diaries/<id>`

游记详情。后端会把压缩列中的正文透明解压后返回；前端不需要知道正文实际存放在
`content` 还是 `content_compressed`。

### `GET /api/v1/diaries/<id>/compression`

查询单篇日记的压缩存储详情，对应日记详情页中的“Huffman 无损压缩存储”信息卡片。

响应核心字段：

```json
{
  "diaryId": 1,
  "algorithm": "huffman",
  "originalBytes": 100,
  "compressedBytes": 65,
  "compressionRatio": 65,
  "spaceSavedPercent": 35,
  "compressedStorage": true,
  "verified": true
}
```

其中 `compressionRatio` 表示压缩后字节占原始字节的百分比，`spaceSavedPercent`
表示节省空间百分比。明文存储的短日记会返回 `compressedStorage: false`。

### `POST /api/v1/diaries`

创建游记。需要登录。后端会在写入时自动尝试 Huffman 压缩正文：
压缩结果确实小于原文时，正文写入 `travel_diaries.content_compressed`，
`content` 置空；短文本或压缩无收益时保留明文，避免频率表头开销导致反向膨胀。
请求可携带 `videos: string[]`，后端会写入 `travel_diaries.videos` 并在游记详情中原样返回。

### `PUT /api/v1/diaries/<id>`

更新游记。需要登录。正文压缩策略与创建游记一致。`videos` 字段采用整组覆盖语义。

### `POST /api/v1/diaries/<id>/animation`

生成日记动画预览。需要登录，只能操作自己的未删除日记。后端会读取标题、正文、图片和视频 URL，生成并覆盖
`travel_diaries.animation_storyboard`。响应结构供 `TravelAnimationPreview.vue` 直接渲染：

```json
{
  "title": "北海一日",
  "caption": "把这篇游记整理成 3 段旅行动画预览。",
  "voiceover": "北海一日。湖边散步...",
  "scenes": [
    {
      "caption": "北海一日",
      "voiceover": "湖边散步...",
      "image": "/images/diary/beihai.jpg",
      "video": "https://example.com/clip.mp4",
      "durationMs": 4500,
      "motion": "pan"
    }
  ]
}
```

该接口当前生成的是本地确定性分镜，不调用真实视频生成或区块链网络。

### `DELETE /api/v1/diaries/<id>`

删除游记。

### `GET /api/v1/diaries/<id>/replay-route`

日记到路线的一键复刻接口，对应日记详情页「重走这条路线」按钮。

后端优先读取 `travel_diaries.scenic_spot_ids` 中显式关联的景点，并保持数组原始顺序；
如果关联景点不足 2 个，则从标题、正文和标签中按景点名出现顺序提取站点。

响应核心字段：

```json
{
  "diaryId": 1,
  "title": "北京一日游",
  "city": "北京",
  "total": 3,
  "source": "spot-ids",
  "stops": [
    { "id": 1, "name": "故宫博物院", "longitude": 116.397, "latitude": 39.917 }
  ]
}
```

`source` 可能为 `spot-ids` 或 `narrative-extraction`。前端拿到 `stops` 后跳转到
`/route`，把站点喂给现有路线规划流程渲染。

### 日记压缩存储

日记压缩已经进入真实存储路径，不再只是演示页能力。

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/api/v1/diaries/<id>/compression` | 查询单篇日记的压缩详情 |
| `GET` | `/api/v1/diaries/compression/stats` | 查询全站日记压缩统计 |
| `POST` | `/api/v1/diaries/compression/migrate` | 将存量明文日记批量迁移为压缩存储，需登录 |
| `POST` | `/api/v1/diaries/<id>/animation` | 生成并保存日记动画分镜，需登录 |

`GET /api/v1/diaries/compression/stats` 响应核心字段：

```json
{
  "totalDiaries": 12,
  "compressedDiaries": 8,
  "originalBytes": 42000,
  "compressedBytes": 27000,
  "savedBytes": 15000,
  "savedPercent": 35.71,
  "algorithm": "huffman"
}
```

`POST /api/v1/diaries/compression/migrate` 会逐行压缩仍存放在 `content` 中的明文正文。
响应包含 `migrated`、`skipped` 和 `algorithm`。短文本或压缩后不节省空间的记录会计入
`skipped` 并继续保留明文。

### Huffman 工具接口

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `POST` | `/api/v1/huffman/compress` | 手动压缩一段正文，主要供工具页和算法说明使用 |
| `POST` | `/api/v1/huffman/decompress` | 手动解压工具接口返回的压缩内容 |

这些接口不是日记压缩落库的权威路径。真实日记存储以 `POST /api/v1/diaries`、
`PUT /api/v1/diaries/<id>`、`POST /api/v1/diaries/compression/migrate` 和
`database/migrations/diary_compression_schema.sql` 为准。

日记视频 URL 与动画分镜字段以 `database/migrations/diary_animation_schema.sql` 为准。

### 游记互动

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `POST` | `/api/v1/diaries/<id>/like` | 点赞 |
| `DELETE` | `/api/v1/diaries/<id>/like` | 取消点赞 |
| `POST` | `/api/v1/diaries/<id>/bookmark` | 收藏 |
| `DELETE` | `/api/v1/diaries/<id>/bookmark` | 取消收藏 |
| `POST` | `/api/v1/diaries/<id>/rating` | 评分 |
| `GET` | `/api/v1/diaries/<id>/comments` | 评论列表 |
| `POST` | `/api/v1/diaries/<id>/comments` | 创建评论 |
| `DELETE` | `/api/v1/comments/<id>` | 删除评论 |

当前游记互动仍偏演示系统，默认用户行为需要结合后端实现理解。

## 用户资料与偏好

### `GET /api/v1/profile`

个人中心基础信息。

### `GET /api/v1/profile/preferences`

读取用户偏好。

### `PUT /api/v1/profile/preferences`

保存用户偏好。

### `DELETE /api/v1/profile/preferences`

清空或重置用户偏好。

## AIGC

### `POST /api/v1/aigc/travel-chat`

AI 旅游助手，调用真实大模型 API。

前端调用：

```js
tourismApi.travelAgentChat({
  message: '帮我规划北京一日游',
  destination: '北京',
  days: 1,
  budget: 500,
  style: 'balanced',
  messages: [
    { role: 'user', content: '帮我规划北京一日游' }
  ]
})
```

后端会按 `destination` 从本地 `scenic_spots` 与餐饮 `facilities` 中取少量候选景点、学校和美食上下文，注入大模型提示词；该上下文只是 TourPilot 本地数据参考，不代表实时预约、营业或票务状态。

响应核心字段：

```json
{
  "reply": "建议第一天从前门出发...",
  "provider": "deepseek",
  "model": "deepseek-chat",
  "suggestions": ["把这份计划改得更轻松", "按低预算重新安排"]
}
```

依赖环境变量：

- `TOURISM_LLM_API_KEY`
- `TOURISM_LLM_BASE_URL`
- `TOURISM_LLM_MODEL`

没有 DeepSeek key 时返回配置错误，不生成假回复。

### `POST /api/v1/aigc/diary-summary`

生成游记摘要。

### `POST /api/v1/aigc/polish`

文本润色。当前主流程不一定使用，但后端保留接口。

### `POST /api/v1/aigc/image-prompt`

日记编辑页的 AIGC 视觉方案接口。当前能力是生成“3D/照片转 2D 插画”的提示词和分格脚本，不在后端直接生成图片。

请求示例：

```json
{
  "title": "故宫一日游",
  "content": "上午从午门进入，下午在角楼看日落。",
  "mode": "3d_to_2d",
  "visualStyle": "anime",
  "panelLayout": "four-panel",
  "imageCount": 3
}
```

字段说明：

- `visualStyle`：二维风格，可选 `anime`、`watercolor`、`flat`、`ink`、`pixel`。
- `panelLayout`：分格布局，可选 `single`、`two-panel`、`four-panel`、`six-panel`、`vertical-comic`。
- `imageCount`：前端已上传图片数量，用于提示词语境；图片二进制仍由日记保存流程处理。

响应示例：

```json
{
  "mode": "3d_to_2d",
  "promptEn": "Convert the uploaded travel images into a 2D four-panel storyboard...",
  "promptCn": "将已上传的旅行图片从 3D/写实观感转成日系动画的四格漫画...",
  "style": "日系动画",
  "visualStyle": "anime",
  "panelLayout": "four-panel",
  "colorPalette": "清爽旅行色调",
  "negativePrompt": "photorealistic, 3D render, low quality...",
  "panels": [
    { "title": "开场", "description": "用远景交代目的地和天气。" }
  ]
}
```

## 图片来源

景点图片只按三层来源处理：

1. 后端返回的数据库图片。数据库图片可能来自高德导入，也可能是人工录入。
2. 前端本地拼音图片，见 `frontend/src/data/imageCatalog.js`。
3. 前端 SVG 占位图，见 `frontend/src/utils/images.js`。

后端不再提供外部随机图片 fallback，前端也不要新增随机远程图片兜底。

## 不再作为当前主文档的接口

早期草稿中可能出现：

- `/auth/login`
- `/auth/register`
- `/nearby/...`
- 独立 reviews 模块
- 旧版 hot-spots 模块

这些不是当前前端主流程依赖的接口。后续如果要恢复，需要先明确后端实现、前端调用和数据库结构，再更新本文。
