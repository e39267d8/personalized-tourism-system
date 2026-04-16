# 数据库 Schema 一致性检查报告

**检查日期**: 2026-04-16  
**检查范围**: `schema.sql` vs `functions.sql`

---

## ❌ 发现的问题

### 1. **字段不匹配问题**

#### 问题 1.1: `scenic_spots` 表缺少字段

**functions.sql 中引用的字段**:
- `scenic_spots.category_id` (第 44 行)
- `scenic_spots.crowd_level` (第 36 行，206 行，309 行)
- `scenic_spots.city` (第 395 行)
- `scenic_spots.visit_count` (第 240 行，472 行)
- `scenic_spots.status` (第 45 行，72 行，294 行，308 行，323 行，402 行)

**schema.sql 中实际定义的字段**:
- `category` VARCHAR(50) ❌ 应该是 `category_id BIGINT`
- **缺少** `crowd_level` SMALLINT
- **缺少** `city` VARCHAR
- **缺少** `visit_count` INTEGER
- **缺少** `status` SMALLINT

**影响**: functions.sql 中的存储过程将无法执行，因为引用了不存在的字段。

---

#### 问题 1.2: `graph_nodes` 表缺少字段

**functions.sql 中引用的字段**:
- `graph_nodes.facility_id` (第 205 行，210 行 - 通过 JOIN 间接引用)

**schema.sql 中实际定义的字段**:
- **缺少** `facility_id INTEGER`

**影响**: 无法正确关联设施节点。

---

#### 问题 1.3: `graph_edges` 表字段不匹配

**functions.sql 中引用的字段**:
- `graph_edges.from_node_id` (第 188 行)
- `graph_edges.to_node_id` (第 182 行)
- `graph_edges.base_weight` (第 185 行，201 行)
- `graph_edges.dynamic_weight` (第 185 行，201 行)
- `graph_edges.weight_updated_at` (第 217 行)

**schema.sql 中实际定义的字段**:
- `from_node` INTEGER ❌ 应该是 `from_node_id`
- `to_node` INTEGER ❌ 应该是 `to_node_id`
- **缺少** `base_weight` DECIMAL
- **缺少** `dynamic_weight` DECIMAL
- **缺少** `weight_updated_at` TIMESTAMP

**影响**: 路径规划相关函数无法执行。

---

#### 问题 1.4: `facilities` 表缺少字段

**functions.sql 中引用的字段**:
- `facilities.facility_type_id` (第 98 行，110 行)
- `facilities.status` (第 111 行)

**schema.sql 中实际定义的字段**:
- `type` VARCHAR(50) ❌ 应该是 `facility_type_id BIGINT`
- **缺少** `status` SMALLINT

**影响**: 设施查询函数无法正确执行。

---

#### 问题 1.5: `travel_diaries` 表缺少字段

**functions.sql 中引用的字段**:
- `travel_diaries.visibility` (第 368 行)
- `travel_diaries.view_count` (第 359 行，487 行)
- `travel_diaries.like_count` (第 360 行，503 行)
- `travel_diaries.start_date` (第 462 行)
- `travel_diaries.end_date` (第 462 行)
- `travel_diaries.route_data` (第 462 行)
- `travel_diaries.visited_spots` (第 462 行)
- `travel_diaries.published_at` (第 464 行)

**schema.sql 中实际定义的字段**:
- **缺少** `visibility` SMALLINT
- **缺少** `view_count` INTEGER
- **缺少** `like_count` INTEGER
- **缺少** `start_date` DATE
- **缺少** `end_date` DATE
- **缺少** `route_data` JSONB
- **缺少** `visited_spots` JSONB
- **缺少** `published_at` TIMESTAMP

**影响**: 游记管理函数无法执行。

---

#### 问题 1.6: `reviews` 表缺少字段

**functions.sql 中引用的字段**:
- `reviews.target_type` (第 532 行，546 行，551 行，558 行，568 行，575 行)
- `reviews.target_id` (第 532 行，546 行，552 行，559 行，569 行，576 行)
- `reviews.is_verified` (第 533 行)
- `reviews.status` (第 534 行，553 行，560 行，570 行，577 行)
- `reviews.title` (第 519 行)

**schema.sql 中实际定义的字段**:
- **缺少** `target_type` VARCHAR
- **缺少** `target_id` BIGINT
- **缺少** `is_verified` BOOLEAN
- **缺少** `status` SMALLINT
- **缺少** `title` VARCHAR

**影响**: 评论管理函数无法执行。

---

#### 问题 1.7: 缺少关联表

**functions.sql 中引用的表**:
- `user_preferences` (第 247-251 行)
- `review_tag_mapping` (第 541 行)
- `mv_hot_scenic_spots` 物化视图 (第 419 行)

**schema.sql 中实际定义的表**:
- **缺少** `user_preferences` 表
- **缺少** `review_tag_mapping` 表
- **缺少** `mv_hot_scenic_spots` 物化视图

**影响**: 用户偏好查询和评论标签关联功能无法使用。

---

### 2. **数据类型不一致**

#### 问题 2.1: ID 类型不统一

**schema.sql**:
- 使用 `SERIAL` (INTEGER) 作为主键类型

**functions.sql**:
- 使用 `BIGINT` 作为参数和返回值类型

**影响**: 可能导致类型转换错误或性能问题。

---

### 3. **索引缺失**

**functions.sql 中查询需要的索引**:
- `scenic_spots.status` - 缺少索引
- `scenic_spots.city` - 缺少索引
- `scenic_spots.crowd_level` - 缺少索引
- `scenic_spots.visit_count` - 缺少索引
- `travel_diaries.visibility` - 缺少索引
- `travel_diaries.view_count` - 缺少索引
- `travel_diaries.like_count` - 缺少索引
- `reviews.status` - 缺少索引
- `reviews.target_type` - 缺少索引
- `reviews.target_id` - 缺少索引

---

## 🔧 修复建议

### 方案 A: 修改 schema.sql（推荐）

更新 `schema.sql` 以匹配 `functions.sql` 中的字段定义：

```sql
-- 修改 scenic_spots 表
ALTER TABLE scenic_spots 
  ADD COLUMN category_id BIGINT,
  ADD COLUMN crowd_level SMALLINT,
  ADD COLUMN city VARCHAR(50),
  ADD COLUMN visit_count INTEGER DEFAULT 0,
  ADD COLUMN status SMALLINT DEFAULT 1;

-- 修改 graph_nodes 表
ALTER TABLE graph_nodes
  ADD COLUMN facility_id INTEGER;

-- 修改 graph_edges 表
ALTER TABLE graph_edges
  RENAME COLUMN from_node TO from_node_id,
  RENAME COLUMN to_node TO to_node_id,
  ADD COLUMN base_weight DECIMAL(10,2),
  ADD COLUMN dynamic_weight DECIMAL(10,2),
  ADD COLUMN weight_updated_at TIMESTAMP;

-- 修改 facilities 表
ALTER TABLE facilities
  ADD COLUMN facility_type_id BIGINT,
  ADD COLUMN status SMALLINT DEFAULT 1;

-- 修改 travel_diaries 表
ALTER TABLE travel_diaries
  ADD COLUMN visibility SMALLINT DEFAULT 1,
  ADD COLUMN view_count INTEGER DEFAULT 0,
  ADD COLUMN like_count INTEGER DEFAULT 0,
  ADD COLUMN start_date DATE,
  ADD COLUMN end_date DATE,
  ADD COLUMN route_data JSONB,
  ADD COLUMN visited_spots JSONB,
  ADD COLUMN published_at TIMESTAMP;

-- 修改 reviews 表
ALTER TABLE reviews
  ADD COLUMN target_type VARCHAR(20),
  ADD COLUMN target_id BIGINT,
  ADD COLUMN is_verified BOOLEAN DEFAULT FALSE,
  ADD COLUMN status SMALLINT DEFAULT 1,
  ADD COLUMN title VARCHAR(200);

-- 创建缺失的表
CREATE TABLE user_preferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    preference_type VARCHAR(50),
    preference_value JSONB,
    weight DECIMAL(3,2) DEFAULT 1.0
);

CREATE TABLE review_tag_mapping (
    review_id INTEGER REFERENCES reviews(id),
    tag_id INTEGER,
    PRIMARY KEY (review_id, tag_id)
);

-- 创建物化视图
CREATE MATERIALIZED VIEW mv_hot_scenic_spots AS
SELECT id, name, rating, visit_count
FROM scenic_spots
WHERE status = 1
ORDER BY rating DESC, visit_count DESC;
```

### 方案 B: 修改 functions.sql

修改 `functions.sql` 中的 SQL 语句，使其匹配 `schema.sql` 中的字段定义。

**优点**: 不需要修改 schema
**缺点**: 需要大量修改存储过程，可能影响功能完整性

---

## ✅ 推荐方案

**采用方案 A**，理由：
1. `functions.sql` 中的功能更完整
2. 包含更多业务逻辑（用户偏好、评论标签等）
3. 支持更复杂的查询场景
4. 符合实际业务需求

---

## 📋 待办事项

1. [ ] 更新 `schema.sql` 添加缺失字段
2. [ ] 创建缺失的关联表
3. [ ] 创建缺失的物化视图
4. [ ] 添加必要的索引
5. [ ] 更新 ER 图文档
6. [ ] 测试所有存储过程

---

**检查者**: AI Assistant  
**状态**: 待修复
