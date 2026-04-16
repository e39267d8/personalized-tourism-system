# 个性化旅游推荐系统 - 实现计划

## 开发路线 (API-First)

按照 **数据库 → API → UI → 业务逻辑与算法实现** 的顺序推进：

### ✅ 第一阶段：数据库设计 (已完成 100%)

**完成内容：**
- 数据库 Schema 设计 (`database/schema.sql`)
- 10 张核心表设计：
  - `users` - 用户表
  - `scenic_spots` - 景点表 (含 PostGIS 空间数据支持)
  - `graph_nodes` - 图节点表
  - `graph_edges` - 图边表
  - `facilities` - 设施表
  - `travel_diaries` - 游记表
  - `reviews` - 评论表
  - `achievements` - 成就表
  - `user_achievements` - 用户成就表
  - `digital_collectibles` - 数字藏品表
- 空间索引 (GIST) 和全文索引 (GIN)
- 存储过程：`find_nearest_spots`, `find_facilities_in_range`

**技术栈：**
- PostgreSQL 15 + PostGIS 3.x
- 空间查询优化 (KNN 最近邻查询)
- 范围查询优化

---

### 🔄 第二阶段：API 接口定义 (已完成 100%)

**完成内容：**
- API 接口规范定义 (`api/api-definition.yaml`)
- OpenAPI 3.0 标准格式
- 6 大模块，20+ 接口：

#### 1. 景点管理 API
- `GET /api/v1/scenic-spots` - 获取景点列表 (分页、排序、过滤、空间查询)

#### 2. 路线规划 API
- `POST /api/v1/routes/plan` - 规划旅游路线 (Dijkstra 算法)

#### 3. 智能推荐 API
- `GET /api/v1/recommendations/scenic-spots` - 推荐景点 (KNN + 协同过滤)

#### 4. 用户管理 API
- `POST /api/v1/users` - 创建用户
- `PUT /api/v1/users/{user_id}/preferences` - 更新用户偏好

#### 5. 成就系统 API
- `GET /api/v1/achievements` - 获取成就列表
- `GET /api/v1/users/{user_id}/achievements` - 获取用户成就

#### 6. 数字藏品 API
- `GET /api/v1/digital-collectibles` - 获取数字藏品列表

**关键设计：**
- RESTful 风格
- JSON 响应格式统一
- 支持空间查询参数 (lat, lng)
- 支持分页、排序、过滤

---

### ⏳ 第三阶段：测试数据生成 (下一步)

**目标：**
生成真实的测试数据填充数据库，支持算法开发和前端展示

**需要生成：**
1. **200+ 景点数据**
   - 真实地理坐标 (经纬度)
   - 名称、描述、类别、评分
   - 开放时间、门票价格、标签

2. **200+ 图节点**
   - 景点节点 (关联 scenic_spots)
   - 交通节点 (公交站、地铁站、停车场)
   - 设施节点 (餐厅、酒店、洗手间)
   - 自定义节点

3. **500+ 图边**
   - 节点间的连接关系
   - 距离、交通方式、预计时间
   - 权重 (用于 Dijkstra)

**实现方式：**
- Python 脚本生成模拟数据
- 使用真实地图数据 (可选：OpenStreetMap)
- 确保图的连通性

---

### ⏳ 第四阶段：后端实现 (待开始)

**技术栈：**
- C++17 + Crow HTTP 框架
- PostgreSQL 客户端 (libpqxx)
- JSON 库 (nlohmann/json)

**实现内容：**
1. **HTTP 服务器搭建**
   - Crow 路由配置
   - 中间件 (CORS、日志、错误处理)

2. **数据库连接层**
   - 连接池管理
   - ORM 封装
   - 空间查询封装

3. **API 接口实现**
   - 按照 `api/api-definition.yaml` 实现所有接口
   - 请求参数验证
   - 响应格式统一

4. **Dijkstra 算法实现**
   - 优先队列优化版本
   - 支持多种权重 (距离/时间/体验)
   - 路径重建

---

### ⏳ 第五阶段：前端实现 (待开始)

**技术栈：**
- Vue 3 + Vite + Pinia
- Tailwind CSS
- Leaflet (地图)

**实现内容：**
1. **项目初始化**
2. **地图集成**
   - Leaflet 地图显示
   - 景点标记
   - 路线绘制
3. **UI 组件**
   - 景点列表
   - 路线规划界面
   - 用户个人中心
4. **API 调用**
   - Axios 封装
   - 状态管理 (Pinia)

---

### ⏳ 第六阶段：业务逻辑与算法深化 (待开始)

**实现内容：**
1. **个性化推荐算法**
   - 基于用户偏好
   - 基于历史行为
   - 协同过滤
2. **成就系统逻辑**
   - 4 层成就解锁规则
   - 成就进度追踪
3. **数字藏品铸造**
   - NFT 相关逻辑 (如需要)

---

## 下一步行动

### 立即执行：生成测试数据

**文件位置：** `database/seed_data.sql` 或 `scripts/generate_seed_data.py`

**优先级：** 高

**原因：**
- 有了测试数据才能验证数据库设计
- 才能开发和测试 Dijkstra 算法
- 才能进行后端 API 联调

---

## 项目结构

```
personalized-tourism-system/
├── database/
│   ├── schema.sql              # ✅ 数据库表结构
│   └── seed_data.sql           # ⏳ 测试数据 (下一步)
├── api/
│   └── api-definition.yaml     # ✅ API 接口定义
├── backend/                    # ⏳ 待创建
│   ├── src/
│   ├── CMakeLists.txt
│   └── ...
├── frontend/                   # ⏳ 待创建
│   ├── src/
│   ├── package.json
│   └── ...
├── scripts/                    # ⏳ 待创建
│   └── generate_seed_data.py   # 数据生成脚本
└── docs/
    ├── week-report-1.md
    ├── week-report-2.md
    └── ...
```

---

## 关键技术决策

### 为什么选择 API-First？

1. **明确接口边界** - 前后端并行开发
2. **避免返工** - 先定义好接口，实现时不会偏离需求
3. **便于测试** - 有了 API 定义可以先用 Postman 等工具测试
4. **文档驱动** - OpenAPI 文档即接口文档

### 数据库设计要点

1. **PostGIS 空间数据** - 支持高效的地理空间查询
2. **图结构存储** - nodes + edges 表存储图数据
3. **索引优化** - GIST 空间索引 + GIN 全文索引

### 算法实现要点

1. **Dijkstra 优先队列优化** - O((V+E)logV) 复杂度
2. **多权重支持** - 距离/时间/体验可切换
3. **路径重建** - 记录前驱节点还原完整路径

---

## 进度追踪

| 阶段 | 内容 | 状态 | 完成度 |
|------|------|------|--------|
| 1 | 数据库设计 | ✅ 完成 | 100% |
| 2 | API 定义 | ✅ 完成 | 100% |
| 3 | 测试数据生成 | 🔄 进行中 | 0% |
| 4 | 后端实现 | ⏳ 待开始 | 0% |
| 5 | 前端实现 | ⏳ 待开始 | 0% |
| 6 | 业务逻辑与算法 | ⏳ 待开始 | 0% |

**总体进度：20%**

---

## 下一步

**立即开始：生成测试数据**

需要确认：
1. 是否需要真实地图数据？还是模拟数据即可？
2. 测试数据覆盖范围 (北京？上海？全国？)
3. 数据生成方式 (Python 脚本？手动 SQL？)

请指示下一步方向！
