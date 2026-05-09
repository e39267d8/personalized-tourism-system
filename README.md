# 个性化旅游系统

这是一个课程设计级别的旅游网站项目，当前目标是提供一个可以基础演示的网站：前端负责页面与交互，C++ 后端提供 HTTP API，PostgreSQL/PostGIS 保存景点、路线、游记和成就数据。

## 当前真实状态

| 模块 | 状态 | 说明 |
|---|---|---|
| 前端页面 | 可用 | 包含首页、推荐与预算、路线规划、旅游日记、成就系统 |
| 后端 API | 可用 | 使用 Crow 提供 `/api/v1` 接口 |
| 数据库 | 可用 | 使用 PostgreSQL 15 + PostGIS，脚本在 `database/` |
| 景点数据 | 已接数据库 | `/api/v1/scenic-spots` 从 `scenic_spots` 读取 |
| 路线数据 | 已接数据库 | `/api/v1/routes` 从 `route_plans` 和 `graph_nodes` 读取 |
| 旅游日记 | 已接数据库 | 支持查询、新增、编辑、删除 |
| 成就系统 | 基础接数据库 | 从 `achievements` 和 `user_achievements` 读取 |
| 预算推荐 | 轻量演示 | 后端内置三档预算方案，便于展示创新功能 |
| AIGC | 占位演示 | 目前是模板摘要/润色，没有接真实大模型 |

## 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Vue 3, Vite, Vue Router, Tailwind CSS, Leaflet, Axios |
| 后端 | C++17, Crow, Standalone Asio, libpq |
| 数据库 | PostgreSQL 15, PostGIS |
| 构建 | CMake, MinGW Makefiles, npm |

## 项目结构

```text
personalized-tourism-system/
  backend/              C++ 后端服务
  database/             数据库建表、演示数据、验证脚本
  frontend/             Vue 前端
  docs/                 课程文档或补充说明
  QUICKSTART.md         Windows 本地运行指南
```

## 后端主要接口

| 接口 | 方法 | 功能 |
|---|---|---|
| `/health` | GET | 检查后端和数据库连接 |
| `/api/v1/dashboard` | GET | 首页统计 |
| `/api/v1/scenic-spots` | GET | 景点列表，来自数据库 |
| `/api/v1/scenic-spots/<id>` | GET | 景点详情 |
| `/api/v1/search/suggestions` | GET | 搜索建议词 |
| `/api/v1/budget-plans` | GET | 预算方案 |
| `/api/v1/routes` | GET | 路线列表，来自数据库 |
| `/api/v1/diaries` | GET/POST | 游记查询和新增 |
| `/api/v1/diaries/<id>` | GET/PUT/DELETE | 游记详情、编辑、删除 |
| `/api/v1/achievements` | GET | 成就列表 |
| `/api/v1/aigc/diary-summary` | POST | 演示版游记摘要 |

## 数据库连接

后端默认连接：

```text
host=127.0.0.1 port=5432 dbname=tourism_system user=postgres
```

如果你的 PostgreSQL 需要密码，可以在启动后端前设置环境变量：

```bat
set TOURISM_DB_CONN=host=127.0.0.1 port=5432 dbname=tourism_system user=postgres password=你的密码
```

## 搜索能力

站内搜索不是简单前端过滤，而是在后端按相关度排序。当前排序信号包括：

- 名称精确匹配
- 名称前缀匹配
- 名称包含关键词
- 标签匹配
- 类型匹配
- 描述匹配
- 评分、收藏数、浏览数热度加权

支持参数：

```text
GET /api/v1/scenic-spots?q=故宫&category=历史古迹&max_ticket=80&sort=relevance&limit=50
```

`sort` 可选：

| 值 | 含义 |
|---|---|
| `relevance` | 相关度优先 |
| `rating` | 评分优先 |
| `price` | 低价优先 |
| `hot` | 热度优先 |

## 高德 POI 数据扩充

如果需要大量景点数据，可以用高德开放平台 Web 服务接口拉取 POI，再导入本地 PostgreSQL。项目提供了脚本：

```bat
python scripts\import_amap_pois.py --key 你的高德Key --city 北京 --keywords 景点 --output database\amap_pois.sql
psql -U postgres -d tourism_system -f database\amap_pois.sql
```

推荐做法是“定期拉取 API 数据入库，再用本地数据库搜索”，不要每次用户搜索都实时请求第三方 API。这样速度更快，也不会因为第三方接口限流影响网站体验。

## 快速运行

详细步骤见 [QUICKSTART.md](QUICKSTART.md)。最短流程如下：

```bat
set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
set PGCLIENTENCODING=UTF8
chcp 65001

psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS tourism_system;"
psql -U postgres -d postgres -c "CREATE DATABASE tourism_system WITH ENCODING 'UTF8';"
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -f database\verify_demo.sql
```

编译并启动后端：

```bat
cd backend
cmake -S . -B build-codex-mingw -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug -DASIO_INCLUDE_DIR=C:\tmp\asio\include -DPostgreSQL_ROOT="C:\Program Files\PostgreSQL\15"
cmake --build build-codex-mingw
set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
build-codex-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
```

启动前端：

```bat
cd frontend
npm install
npm run dev
```

浏览器打开 Vite 输出的地址，通常是 `http://127.0.0.1:3000/`。前端会把 `/api` 请求代理到 `http://127.0.0.1:8080`。

## 适合答辩时说明的边界

| 功能 | 可以怎么说 |
|---|---|
| 数据库 | 已使用 PostgreSQL/PostGIS 保存核心演示数据 |
| 景点/路线/游记 | 已经通过后端 API 读取或写入数据库 |
| 推荐算法 | 当前是规则和预算分档演示，后续可替换为 Top-K 或偏好权重算法 |
| AIGC | 当前保留接口和页面入口，后续可接真实模型 API |
| 高德数据 | 当前没有实时接高德，演示数据是手工整理的小型数据集 |
