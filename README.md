# 个性化旅游系统

> 数据结构课程设计项目 - 智能旅游全生命周期管理系统

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()
[![Version](https://img.shields.io/badge/version-1.0.0-orange)]()

## 📋 项目概述

本项目是一款以**智能体（Agent）**为核心驱动的个性化旅游系统，实现旅游全生命周期管理：

- **旅游前**：智能推荐服务（Top-K 排序、多维度匹配）
- **旅游中**：多约束路径规划、周边服务精准检索
- **旅游后**：游记管理、AI 辅助写作、多媒体内容生成

### 技术亮点

- ✅ **自定义数据结构**：图（邻接表）、优先队列、倒排索引、Trie 树、Huffman 编码
- ✅ **高效算法**：Dijkstra O((V+E)logV)、Top-K O(nlogK)、全文检索 O(1)
- ✅ **地理空间支持**：PostgreSQL + PostGIS，支持非直线距离查询
- ✅ **AI 集成**：AIGC 辅助写作、智能推荐、多媒体生成

---

## 👥 项目成员

| 姓名 | 角色 | 负责模块 |
|------|------|---------|
| **yhm** (组长) | 统筹与中枢 | 图数据结构、Dijkstra 算法、系统集成 |
| **zby** | 数据与契约 | 数据库设计、Top-K 推荐、周边查询 |
| **lxd** | 质量与表现 | 倒排索引、Huffman 压缩、AIGC 集成 |

---

## 🛠️ 技术栈

### 后端（C++）
- **语言**: C++17
- **HTTP 服务器**: Crow (轻量级)
- **数据库驱动**: libpqxx (PostgreSQL)
- **JSON 处理**: nlohmann/json
- **构建工具**: CMake
- **测试框架**: GoogleTest

### 前端（Vue.js）
- **框架**: Vue 3 + Vite
- **状态管理**: Pinia
- **路由**: Vue Router
- **UI 框架**: Tailwind CSS
- **地图**: Leaflet

### 数据库
- **主数据库**: PostgreSQL 15
- **空间扩展**: PostGIS 3.3
- **全文检索**: PostgreSQL GIN 索引

### AI 工具
- **代码生成**: Cursor + Qwen-Coder
- **架构设计**: Claude 3.5 Sonnet
- **多媒体生成**: AIGC API

---

## 📦 项目结构

```
personalized-tourism-system/
├── backend/                      # C++ 后端
│   ├── CMakeLists.txt
│   ├── include/
│   │   ├── graph/               # 图数据结构
│   │   │   ├── graph.h
│   │   │   ├── dijkstra.h
│   │   ├── recommendation/      # 推荐算法
│   │   ├── search/              # 检索与压缩
│   │   └── database/            # 数据库访问
│   ├── src/
│   └── tests/
├── frontend/                     # Vue.js 前端
│   ├── package.json
│   ├── src/
│   │   ├── views/
│   │   ├── components/
│   │   └── api/
│   └── public/
├── database/                     # 数据库脚本
│   ├── schema.sql               # 建表脚本
│   ├── functions.sql            # 存储过程
│   └── seed_data.sql            # 测试数据
├── docs/                         # 文档
│   ├── api.md                   # API 文档
│   └── algorithms.md            # 算法说明
├── scripts/                      # 辅助脚本
└── README.md
```

---

## 🚀 快速开始

### 环境要求

- **后端**: g++ 9+, CMake 3.15+, PostgreSQL 15+
- **前端**: Node.js 18+, npm 9+
- **数据库**: PostgreSQL 15 + PostGIS 3.3

### 1. 克隆项目

```bash
git clone https://github.com/your-repo/personalized-tourism-system.git
cd personalized-tourism-system
```

### 2. 数据库配置

```bash
# 创建数据库
createdb tourism_system

# 启用 PostGIS 扩展
psql -d tourism_system -c "CREATE EXTENSION postgis;"

# 执行建表脚本
psql -d tourism_system -f database/schema.sql
psql -d tourism_system -f database/functions.sql

# （可选）插入测试数据
psql -d tourism_system -f database/seed_data.sql
```

### 3. 编译后端

```bash
cd backend
mkdir build && cd build

# 配置
cmake .. -DCMAKE_BUILD_TYPE=Debug

# 编译
make -j$(nproc)

# 运行测试
ctest

# 启动服务器
./tourism_server
```

### 4. 启动前端

```bash
cd frontend

# 安装依赖
npm install

# 开发模式
npm run dev

# 生产构建
npm run build
```

### 5. 访问系统

打开浏览器访问：http://localhost:3000

---

## 📚 核心算法说明

### 1. 图数据结构与路径规划

**数据结构**: 邻接表（支持多重边）

```cpp
class Graph {
  std::unordered_map<int64_t, Node> nodes;
  std::unordered_map<int64_t, std::vector<Edge>> adj_list;
};
```

**Dijkstra 算法**: O((V+E)logV)

```cpp
PathResult dijkstra(const Graph& g, int64_t start, int64_t end) {
  // 最小堆优化
  std::priority_queue<PDI, std::vector<PDI>, std::greater<PDI>> pq;
  // ... 详见 src/graph/dijkstra.cpp
}
```

**特性**:
- ✅ 支持多交通方式（步行、自行车、汽车、公交）
- ✅ 动态权重更新（拥挤度）
- ✅ 双向搜索优化

### 2. Top-K 推荐排序

**算法**: 快速选择 (QuickSelect) - 平均 O(n)

```cpp
std::vector<Item> topK(std::vector<Item>& items, int k) {
  // 基于快速选择的 Top-K 选择
  // ... 详见 src/recommendation/topk.cpp
}
```

**多维匹配**: KD-Tree - O(logN)

### 3. 倒排索引与全文检索

**数据结构**: Trie 树 + 压缩倒排列表

```cpp
class InvertedIndex {
  Trie dictionary;
  std::unordered_map<std::string, PostingList> index;
};
```

**查询**: O(1) 关键词查找

### 4. Huffman 无损压缩

**算法**: 贪心构建 Huffman 树 - O(nlogn)

```cpp
HuffmanTree buildHuffman(const std::map<char, int>& freq) {
  // 构建 Huffman 树
  // ... 详见 src/search/huffman.cpp
}
```

---

## 🧪 测试

### 运行单元测试

```bash
cd backend/build

# 运行所有测试
ctest

# 运行特定测试
./test_graph
./test_dijkstra
./test_topk
./test_inverted_index
```

### 性能基准

```bash
# 性能测试脚本
python3 scripts/benchmark.py
```

**目标性能**:
- Dijkstra (200 节点): < 10ms
- Top-K (K=10, n=10000): < 50ms
- 倒排索引查询：< 5ms

---

## 📖 API 文档

完整 API 文档请参阅：[docs/api.md](docs/api.md)

### 核心接口示例

#### 1. 获取景点列表

```bash
curl http://localhost:8080/api/v1/scenic-spots \
  -G \
  -d "page=1" \
  -d "page_size=20" \
  -d "sort=rating"
```

#### 2. 路径规划

```bash
curl http://localhost:8080/api/v1/routes/plan \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "waypoints": [
      {"longitude": 116.397, "latitude": 39.916},
      {"longitude": 116.400, "latitude": 39.920}
    ],
    "transport_mode": "walk",
    "optimization": "time"
  }'
```

---

## 📅 开发里程碑

| 阶段 | 时间 | 目标 | 状态 |
|------|------|------|------|
| **M1** | W5 | 架构基线、数据字典 v1.0 | ✅ 完成 |
| **M2** | W8 | 可运行框架、数据库建表 | ✅ 完成 |
| **M3** | W9 | 期中验收、核心功能演示 | 🔄 进行中 |
| **M4** | W12 | 所有算法实现、性能压测 | ⏳ 待开始 |
| **M5** | W14 | 系统集成、测试覆盖率 85%+ | ⏳ 待开始 |
| **M6** | W16 | 最终验收、答辩 | ⏳ 待开始 |

---

## 🔧 开发指南

### 代码规范

**C++**:
- 遵循 Google C++ Style Guide
- 使用 clang-format 格式化代码
- 所有公共 API 必须有文档注释

**Vue.js**:
- 使用 ESLint + Prettier
- 组件采用 Composition API
- 所有 API 调用封装在 `src/api/` 目录

### Git 工作流

```bash
# 创建功能分支
git checkout -b feature/your-feature

# 提交代码
git add .
git commit -m "feat: add new feature"

# 推送并创建 PR
git push origin feature/your-feature
```

### 添加新算法

1. 在 `include/` 目录创建头文件
2. 在 `src/` 目录创建实现文件
3. 在 `tests/` 目录创建单元测试
4. 更新 `CMakeLists.txt`
5. 编写算法文档

---

## ⚠️ 注意事项

### 课程要求约束

1. **核心数据结构必须自定义实现**
   - ❌ 禁止使用 BGL、LEMON 等图算法库
   - ❌ 禁止使用现成推荐系统库
   - ✅ 必须手写 Graph、Dijkstra、Top-K、倒排索引

2. **时间复杂度要求**
   - 核心检索、排序类功能：禁止 O(n) 暴力遍历
   - 路径规划：O((V+E)logV)
   - Top-K: O(nlogK) 或 O(n)
   - 全文检索：O(1) 或 O(logN)

3. **数据规模**
   - 图节点 ≥ 200
   - 边 ≥ 200
   - 建筑物 ≥ 20
   - 服务设施 ≥ 50（10+ 类型）

---

## 📝 常见问题

### Q1: 如何生成测试数据？

```bash
python3 scripts/generate_test_data.py --nodes 200 --edges 500
```

### Q2: PostGIS 安装失败？

参考官方文档：https://postgis.net/install/

或使用 Docker:
```bash
docker run -d --name postgis \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  postgis/postgis:15-3.3
```

### Q3: CMake 找不到依赖？

确保已安装：
```bash
# Ubuntu/Debian
sudo apt-get install libpq-dev cmake g++

# Windows (使用 vcpkg)
vcpkg install pqxx crow nlohmann-json
```

---

## 📄 许可证

MIT License

---

## 🙏 致谢

- 课程指导教师
- 使用的所有开源库作者
- AI 辅助工具（Claude、Qwen-Coder、Cursor）

---

**最后更新**: 2026-03-31  
**维护者**: yhm, zby, lxd
