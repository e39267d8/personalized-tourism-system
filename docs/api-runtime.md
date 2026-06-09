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

## 景点

### `GET /api/v1/scenic-spots`

景点列表和搜索结果。

常见查询参数：

- `q`: 关键词。
- `category` 或 `category_id`: 分类。
- `limit`: 返回数量。
- `offset`: 分页偏移。
- `max_ticket` 或 `maxTicket`: 最高票价。
- `sort`: 排序方式。

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

### 室内导航

| 方法 | 路径 | 用途 |
| --- | --- | --- |
| `GET` | `/api/v1/scenic-spots/<id>/indoor-buildings` | 查询景点已接入的室内导航建筑 |
| `GET` | `/api/v1/indoor-buildings/<id>/features` | 查询室内楼层、节点、类型和拓扑边 |
| `POST` | `/api/v1/indoor-buildings/<id>/routes/plan` | 基于室内图规划路线 |

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

- 偏好分类。
- 预算。
- 出行方式。
- 人群或标签。

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

### `GET /api/v1/diaries/search`

游记搜索。

### `GET /api/v1/diaries/<id>`

游记详情。

### `POST /api/v1/diaries`

创建游记。

### `PUT /api/v1/diaries/<id>`

更新游记。

### `DELETE /api/v1/diaries/<id>`

删除游记。

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
  messages: [
    { role: 'user', content: '帮我规划北京一日游' }
  ]
})
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
