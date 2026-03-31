# 个性化旅游系统 - API 接口文档

**版本**: v1.0  
**更新日期**: 2026-03-31  
**基础路径**: `/api/v1`

---

## 目录

1. [认证模块](#认证模块)
2. [用户模块](#用户模块)
3. [景点模块](#景点模块)
4. [推荐模块](#推荐模块)
5. [路径规划模块](#路径规划模块)
6. [周边查询模块](#周边查询模块)
7. [游记模块](#游记模块)
8. [AIGC 模块](#aigc 模块)
9. [评论模块](#评论模块)

---

## 通用说明

### 响应格式

所有 API 响应遵循统一格式：

```json
{
  "code": 200,
  "message": "success",
  "data": { },
  "timestamp": 1234567890,
  "trace_id": "uuid-string"
}
```

### 错误码

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（需要登录） |
| 403 | 禁止访问 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

### 认证方式

需要认证的接口需在 Header 中携带 JWT Token：

```
Authorization: Bearer {token}
```

---

## 认证模块

### 1.1 用户注册

**POST** `/auth/register`

**请求参数**:
```json
{
  "username": "string (4-50 字符)",
  "email": "string (邮箱格式)",
  "password": "string (8-50 字符)",
  "phone": "string (可选)",
  "nickname": "string (可选)"
}
```

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "user_id": 12345,
    "token": "jwt-token-string",
    "expires_in": 86400
  }
}
```

---

### 1.2 用户登录

**POST** `/auth/login`

**请求参数**:
```json
{
  "account": "string (用户名/邮箱/手机号)",
  "password": "string",
  "captcha": "string (可选)"
}
```

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "user_id": 12345,
    "token": "jwt-token-string",
    "refresh_token": "refresh-token-string",
    "expires_in": 86400,
    "user_info": {
      "username": "xxx",
      "nickname": "xxx",
      "avatar_url": "xxx"
    }
  }
}
```

---

### 1.3 刷新令牌

**POST** `/auth/refresh`

**请求参数**:
```json
{
  "refresh_token": "string"
}
```

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "token": "new-jwt-token",
    "expires_in": 86400
  }
}
```

---

## 用户模块

### 2.1 获取用户信息

**GET** `/users/me`

**认证**: 需要

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "id": 12345,
    "username": "xxx",
    "email": "xxx",
    "phone": "xxx",
    "nickname": "xxx",
    "avatar_url": "xxx",
    "gender": 1,
    "birth_date": "1990-01-01",
    "created_at": "2024-01-01T00:00:00Z"
  }
}
```

---

### 2.2 更新用户偏好

**PUT** `/users/me/preferences`

**认证**: 需要

**请求参数**:
```json
{
  "preferences": [
    {
      "preference_type": "scenic_type",
      "preference_value": {"categories": [1, 2, 3]},
      "weight": 1.0
    },
    {
      "preference_type": "budget",
      "preference_value": {"min": 100, "max": 500},
      "weight": 0.8
    }
  ]
}
```

---

## 景点模块

### 3.1 景点列表

**GET** `/scenic-spots`

**查询参数**:
- `page` (integer, 默认 1): 页码
- `page_size` (integer, 默认 20, 最大 100): 每页数量
- `category_id` (integer, 可选): 分类 ID
- `city` (string, 可选): 城市
- `min_rating` (decimal, 可选): 最低评分
- `crowd_level` (integer, 可选): 拥挤度 (1-4)
- `sort` (string, 默认 "rating"): 排序方式 (rating, distance, popularity)
- `longitude` (decimal, 可选): 经度（用于距离排序）
- `latitude` (decimal, 可选): 纬度

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "total": 1000,
    "page": 1,
    "page_size": 20,
    "items": [
      {
        "id": 12345,
        "name": "故宫博物院",
        "description": "xxx",
        "category": {"id": 1, "name": "历史文化"},
        "location": {"longitude": 116.397, "latitude": 39.916},
        "address": "北京市东城区景山前街 4 号",
        "ticket_price": 60.00,
        "duration_hours": 180,
        "crowd_level": 3,
        "rating": 4.8,
        "review_count": 15000,
        "images": ["url1", "url2"],
        "tags": ["历史", "文化", "建筑"],
        "distance": 1200.5
      }
    ]
  }
}
```

---

### 3.2 景点详情

**GET** `/scenic-spots/{id}`

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "id": 12345,
    "name": "故宫博物院",
    "description": "详细介绍...",
    "category": {"id": 1, "name": "历史文化"},
    "location": {"longitude": 116.397, "latitude": 39.916},
    "opening_hours": {
      "monday": "08:30-17:00",
      "tuesday": "08:30-17:00"
    },
    "ticket_price": 60.00,
    "rating": 4.8,
    "review_count": 15000,
    "images": ["url1", "url2"],
    "tags": ["历史", "文化"],
    "attributes": [
      {"name": "有无障碍设施", "value": true}
    ]
  }
}
```

---

### 3.3 搜索景点

**GET** `/scenic-spots/search`

**查询参数**:
- `q` (string, 必需): 搜索关键词
- `page` (integer): 页码
- `page_size` (integer): 每页数量
- `filters` (json, 可选): 高级筛选条件

---

## 推荐模块

### 4.1 个性化推荐

**GET** `/recommendations/scenic-spots`

**查询参数**:
- `longitude` (decimal, 可选): 当前位置经度
- `latitude` (decimal, 可选): 当前位置纬度
- `limit` (integer, 默认 10): 推荐数量
- `scenario` (string, 可选): 场景 (nearby, travel_plan, explore)

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "recommendations": [
      {
        "scenic_spot": {...},
        "reason": "基于您的偏好推荐",
        "score": 0.95,
        "distance": 1200.5
      }
    ],
    "algorithm_version": "v2.1"
  }
}
```

---

### 4.2 热门景点

**GET** `/recommendations/hot-spots`

**查询参数**:
- `city` (string, 可选): 城市
- `time_range` (string, 默认 "week"): 时间范围 (today, week, month)
- `limit` (integer, 默认 10): 数量

---

## 路径规划模块

### 5.1 单一路径规划

**POST** `/routes/plan`

**请求参数**:
```json
{
  "waypoints": [
    {"longitude": 116.397, "latitude": 39.916, "name": "起点"},
    {"longitude": 116.400, "latitude": 39.920, "name": "终点"}
  ],
  "transport_mode": "walk",
  "optimization": "time",
  "avoid": ["toll", "highway"],
  "departure_time": "2024-01-01T09:00:00Z"
}
```

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "route_id": "route-uuid",
    "total_distance_meters": 5000,
    "total_duration_seconds": 3600,
    "total_cost": 0.0,
    "path": [
      {
        "longitude": 116.397,
        "latitude": 39.916,
        "instruction": "从起点出发",
        "distance_to_next": 500,
        "duration_to_next": 300
      }
    ],
    "geometry": "encoded_polyline_string",
    "transport_mode": "walk"
  }
}
```

---

### 5.2 多景点游览路径

**POST** `/routes/multi-spot`

**请求参数**:
```json
{
  "start_point": {"longitude": 116.397, "latitude": 39.916},
  "end_point": {"longitude": 116.420, "latitude": 39.940},
  "scenic_spot_ids": [1, 2, 3, 4, 5],
  "transport_mode": "walk",
  "time_budget_minutes": 480,
  "visit_durations": {
    "1": 120,
    "2": 90
  }
}
```

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "route_id": "multi-route-uuid",
    "optimized_order": [1, 3, 2, 5, 4],
    "total_distance_meters": 8000,
    "total_travel_time_seconds": 5400,
    "total_visit_time_seconds": 21600,
    "route_details": [
      {
        "scenic_spot_id": 1,
        "arrival_time": "09:00",
        "departure_time": "11:00"
      }
    ],
    "geometry": "encoded_polyline_string"
  }
}
```

---

## 周边查询模块

### 6.1 查找周边景点

**GET** `/nearby/scenic-spots`

**查询参数**:
- `longitude` (decimal, 必需): 经度
- `latitude` (decimal, 必需): 纬度
- `radius` (integer, 默认 5000): 半径（米）
- `category_id` (integer, 可选): 分类 ID
- `limit` (integer, 默认 20): 数量

---

### 6.2 查找周边设施

**GET** `/nearby/facilities`

**查询参数**:
- `longitude` (decimal, 必需)
- `latitude` (decimal, 必需)
- `radius` (integer, 默认 1000): 半径（米）
- `facility_type_id` (integer, 可选): 设施类型 ID
- `limit` (integer, 默认 20): 数量

---

### 6.3 查找最近设施

**GET** `/nearby/nearest/{facility_type}`

**路径参数**:
- `facility_type`: 设施类型 (restroom, parking, restaurant, hospital, police)

**查询参数**:
- `longitude` (decimal, 必需)
- `latitude` (decimal, 必需)

---

## 游记模块

### 7.1 创建游记

**POST** `/diaries`

**认证**: 需要

**请求参数**:
```json
{
  "title": "北京三日游",
  "content": "富文本内容...",
  "cover_image_url": "https://...",
  "start_date": "2024-01-01",
  "end_date": "2024-01-03",
  "route_data": {
    "type": "LineString",
    "coordinates": [[116.397, 39.916], ...]
  },
  "visited_spots": [
    {"scenic_spot_id": 1, "visit_order": 1, "duration_minutes": 120}
  ],
  "visibility": 1
}
```

---

### 7.2 游记列表

**GET** `/diaries`

**查询参数**:
- `user_id` (integer, 可选): 用户 ID
- `page` (integer): 页码
- `page_size` (integer): 每页数量
- `sort` (string, 默认 "published_at"): 排序
- `city` (string, 可选): 城市

---

### 7.3 游记详情

**GET** `/diaries/{id}`

**响应示例**:
```json
{
  "code": 200,
  "data": {
    "id": 12345,
    "title": "北京三日游",
    "content": "xxx",
    "author": {...},
    "start_date": "2024-01-01",
    "end_date": "2024-01-03",
    "visited_spots": [...],
    "images": [...],
    "like_count": 100,
    "view_count": 5000,
    "is_liked": false,
    "created_at": "2024-01-01T12:00:00Z"
  }
}
```

---

### 7.4 游记搜索

**GET** `/diaries/search`

**查询参数**:
- `q` (string, 必需): 搜索关键词
- `page` (integer): 页码
- `page_size` (integer): 每页数量
- `city` (string, 可选): 城市
- `date_from` (date, 可选): 开始日期
- `date_to` (date, 可选): 结束日期

---

## AIGC 模块

### 8.1 生成游记摘要

**POST** `/aigc/diary-summary`

**认证**: 需要

**请求参数**:
```json
{
  "diary_id": 12345,
  "style": "concise",
  "max_length": 200
}
```

---

### 8.2 生成游记标题

**POST** `/aigc/diary-titles`

**认证**: 需要

**请求参数**:
```json
{
  "diary_id": 12345,
  "count": 5
}
```

---

### 8.3 游记润色

**POST** `/aigc/polish`

**认证**: 需要

**请求参数**:
```json
{
  "content": "用户原始内容...",
  "style": "literary",
  "preserve_facts": true
}
```

---

## 评论模块

### 9.1 发表评论

**POST** `/reviews`

**认证**: 需要

**请求参数**:
```json
{
  "target_type": "scenic",
  "target_id": 12345,
  "rating": 5,
  "title": "非常棒的体验",
  "content": "详细的评价内容...",
  "images": ["url1", "url2"],
  "visit_date": "2024-01-01",
  "tags": [1, 2, 3]
}
```

---

### 9.2 评论列表

**GET** `/reviews`

**查询参数**:
- `target_type` (string, 必需): 目标类型 (scenic, facility, diary)
- `target_id` (integer, 必需): 目标 ID
- `page` (integer): 页码
- `page_size` (integer): 每页数量
- `sort` (string, 默认 "created_at"): 排序
- `rating` (integer, 可选): 评分筛选

---

### 9.3 评论点赞

**POST** `/reviews/{id}/helpful`

**认证**: 需要

**请求参数**:
```json
{
  "action": "add"
}
```

---

## 性能要求

所有核心接口的响应时间要求：

| 接口类型 | 目标响应时间 | 最大响应时间 |
|---------|-------------|-------------|
| 景点列表/详情 | < 100ms | < 500ms |
| 路径规划 | < 200ms | < 1000ms |
| 推荐接口 | < 150ms | < 800ms |
| 全文检索 | < 100ms | < 500ms |
| 周边查询 | < 80ms | < 300ms |

---

## 版本历史

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| v1.0 | 2026-03-31 | 初始版本，包含所有核心接口 |

---

**文档维护者**: yhm, zby, lxd  
**联系方式**: [课程项目 GitHub](https://github.com/your-repo)
