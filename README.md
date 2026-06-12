# TourPilot 个性化旅游系统

TourPilot 是一个旅游规划全栈项目，面向景点搜索、个性化推荐、预算方案、路线规划、景区/校园内部导航、美食推荐、游记、旅行护照成就、数字纪念凭证和 AI 旅行助手等课设场景。

系统采用本地 PostgreSQL/PostGIS 作为唯一运行数据库。高德 POI、OSM/Overpass 内部路网、室内导航 seed、校园内部图和日记压缩迁移都通过 SQL 文件进入同一个 `tourism_system` 数据库。

## 核心功能

- 景点首页、分类、搜索、详情和评价。
- 个性化推荐、预算方案和路线规划。
- 景区/校园内部设施导航与北京大学校园内部道路图。
- 北大红楼室内拓扑导航，采用 `amap_indoor` + `local_indoor_graph` provider 模型。
- 游记广场、游记详情、互动、视频 URL、动画分镜预览、日记到路线的一键复刻。
- Huffman 日记正文压缩存储、透明解压读取和压缩统计。
- 美食推荐、旅行护照成就、数字纪念凭证和 AI 旅行助手。

## 技术栈

- 前端：Vue 3、Vue Router、Vite、Tailwind CSS、Axios、Leaflet、高德 JS API。
- 后端：C++17、Crow、libpq、CMake。
- 数据库：PostgreSQL + PostGIS。
- 外部数据/服务：高德 Web Service、OpenStreetMap/Overpass、DeepSeek 兼容聊天 API。

## 项目结构

```text
personalized-tourism-system/
├─ frontend/              # Vue 单页应用
├─ backend/               # C++ Crow 后端
├─ database/              # schema、imports、migrations、seeds、maintenance
│  ├─ imports/            # 外部数据导入 SQL
│  ├─ migrations/         # 增量结构迁移
│  ├─ seeds/              # 正式初始化和演示扩展 seed
│  └─ maintenance/        # 数据审计和修复脚本
├─ scripts/               # 数据生成和本地辅助脚本
├─ docs/                  # API、工程记录、架构说明和 ADR
├─ QUICKSTART.md          # 本地运行、初始化和验证步骤
└─ AGENTS.md              # 开发者/AI 协作工程规则
```

## 文档入口

- [QUICKSTART.md](QUICKSTART.md)：本地环境、数据库初始化、启动和冒烟验证。
- [database/README.md](database/README.md)：数据库入口文件、导入顺序和数据验证 SQL。
- [AGENTS.md](AGENTS.md)：开发者/AI 工程规则、文档职责、数据和架构约束。
- [docs/engineering_log.md](docs/engineering_log.md)：普通工程变更记录。
- [docs/adr/](docs/adr/)：重大技术决策记录。
- [docs/api-runtime.md](docs/api-runtime.md)：当前前端实际调用、后端实际注册的 API。
- [docs/architecture.md](docs/architecture.md)：系统架构说明。

文档职责保持固定：README 只放项目总览；QUICKSTART 只放运行和初始化步骤；AGENTS 只放工程规则；普通工程变更追加到 `docs/engineering_log.md`；重大技术决策写入 `docs/adr/`。
