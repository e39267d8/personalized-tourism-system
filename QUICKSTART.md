# 快速启动指南 ⚡

> 5 分钟快速启动个性化旅游系统开发环境

---

## 🎯 前置条件检查

### 必需软件

```bash
# 检查 C++ 编译器
g++ --version
# 需要：g++ 9+

# 检查 CMake
cmake --version
# 需要：CMake 3.15+

# 检查 Node.js
node --version
# 需要：Node.js 18+

# 检查 PostgreSQL
psql --version
# 需要：PostgreSQL 15+

# 检查 Git
git --version
```

### 可选但推荐

- Docker（用于 PostgreSQL + PostGIS 容器化）
- VS Code + C/C++ 插件
- VS Code + Volar (Vue 3 插件)

---

## 🚀 快速启动（使用 Docker）

### Step 1: 启动数据库（Docker 方式）

```bash
# 启动 PostgreSQL + PostGIS 容器
docker run -d \
  --name tourism-db \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -v tourism-data:/var/lib/postgresql/data \
  postgis/postgis:15-3.3

echo "✅ 数据库已启动"
```

### Step 2: 初始化数据库

```bash
# 等待容器启动
sleep 5

# 创建数据库
docker exec -it tourism-db createdb -U postgres tourism_system

# 执行建表脚本
docker exec -i tourism-db psql -U postgres -d tourism_system < database/schema.sql

# 执行函数脚本
docker exec -i tourism-db psql -U postgres -d tourism_system < database/functions.sql

# 生成测试数据
docker exec -i tourism-db psql -U postgres -d tourism_system < scripts/seed_data.sql

echo "✅ 数据库初始化完成"
```

### Step 3: 编译后端

```bash
cd backend

# 创建构建目录
mkdir build && cd build

# 配置（Debug 模式）
cmake .. -DCMAKE_BUILD_TYPE=Debug

# 编译
make -j$(nproc)
# Windows: make -j4

# 运行测试
ctest

echo "✅ 后端编译完成"
```

### Step 4: 启动后端服务器

```bash
# 在 backend/build 目录
./tourism_server

# 输出应显示：
# ============================================
# Personalized Tourism System Server
# ============================================
# Host: 0.0.0.0
# Port: 8080
# ...
```

打开新终端测试：

```bash
curl http://localhost:8080/health
# 应返回：{"status":"ok","message":"..."}
```

### Step 5: 启动前端

```bash
# 在新终端，进入 frontend 目录
cd frontend

# 安装依赖（首次运行）
npm install

# 启动开发服务器
npm run dev

# 输出应显示：
# ➜  Local:   http://localhost:3000/
```

打开浏览器访问：**http://localhost:3000**

---

## 🐳 完整 Docker Compose 方案（推荐）

创建 `docker-compose.yml`:

```yaml
version: '3.8'

services:
  db:
    image: postgis/postgis:15-3.3
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: tourism_system
    ports:
      - "5432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data
      - ./database:/docker-entrypoint-initdb.d

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    depends_on:
      - db
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/tourism_system

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    depends_on:
      - backend

volumes:
  postgres-data:
```

一键启动：

```bash
docker-compose up -d
```

---

## 🔧 手动配置（无 Docker）

### Step 1: 安装 PostgreSQL + PostGIS

**Ubuntu/Debian**:

```bash
sudo apt-get update
sudo apt-get install postgresql-15 postgresql-15-postgis-3
```

**Windows**:

1. 下载：https://www.postgresql.org/download/windows/
2. 安装时选择 PostGIS 组件
3. 或使用 Stack Builder

**macOS**:

```bash
brew install postgresql@15
brew install postgis
```

### Step 2: 创建数据库

```bash
# 创建数据库
createdb tourism_system

# 启用 PostGIS
psql -d tourism_system -c "CREATE EXTENSION postgis;"

# 执行脚本
psql -d tourism_system -f database/schema.sql
psql -d tourism_system -f database/functions.sql
```

### Step 3: 生成测试数据

```bash
cd scripts
python3 generate_test_data.py --output seed_data.sql

# 导入数据
psql -d tourism_system -f seed_data.sql
```

### Step 4: 编译后端

```bash
cd backend
mkdir build && cd build

# 配置
cmake .. -DCMAKE_BUILD_TYPE=Debug

# 编译
make -j4

# 测试
ctest
```

### Step 5: 启动服务

```bash
# 后端（终端 1）
cd backend/build
./tourism_server

# 前端（终端 2）
cd frontend
npm install
npm run dev
```

---

## ✅ 验证安装

### 1. 测试数据库连接

```bash
psql -d tourism_system -c "SELECT PostGIS_Version();"
```

### 2. 测试后端 API

```bash
# 健康检查
curl http://localhost:8080/health

# 获取景点列表
curl http://localhost:8080/api/v1/scenic-spots?page=1&page_size=5

# 测试路径规划
curl -X POST http://localhost:8080/api/v1/routes/plan \
  -H "Content-Type: application/json" \
  -d '{"waypoints":[{"longitude":116.397,"latitude":39.916},{"longitude":116.400,"latitude":39.920}],"transport_mode":"walk"}'
```

### 3. 测试前端

打开浏览器访问：**http://localhost:3000**

应该看到：
- ✅ 顶部导航栏
- ✅ 欢迎横幅
- ✅ 功能卡片（智能推荐、路径规划、游记管理）
- ✅ 地图展示（Leaflet）

---

## 🐛 常见问题排查

### 问题 1: CMake 找不到 PostgreSQL

**错误**: `Could NOT find PostgreSQL`

**解决**:

```bash
# Ubuntu/Debian
sudo apt-get install libpq-dev

# Windows (vcpkg)
vcpkg install pqxx

# macOS
brew install libpq
```

### 问题 2: npm install 失败

**错误**: `npm ERR! code ENOENT`

**解决**:

```bash
# 清理 npm 缓存
npm cache clean --force

# 删除 node_modules 和 package-lock.json
rm -rf node_modules package-lock.json

# 重新安装
npm install
```

### 问题 3: PostGIS 扩展创建失败

**错误**: `could not open extension control file`

**解决**:

```bash
# 检查 PostGIS 是否安装
psql -c "SELECT * FROM pg_available_extensions WHERE name = 'postgis';"

# 如果为空，安装 PostGIS
# Ubuntu/Debian: sudo apt-get install postgresql-15-postgis-3
# macOS: brew install postgis
```

### 问题 4: 端口被占用

**错误**: `Address already in use`

**解决**:

```bash
# 查找占用端口的进程
# Linux/macOS
lsof -i :8080
# Windows
netstat -ano | findstr :8080

# 杀死进程
kill -9 <PID>

# 或修改端口
./tourism_server --port 8081
```

### 问题 5: 前端无法连接后端 API

**错误**: `Network Error` 或 CORS 错误

**解决**:

检查 `frontend/vite.config.js`:

```javascript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:8080',  // 确保端口正确
      changeOrigin: true
    }
  }
}
```

---

## 📚 下一步学习资源

### PostgreSQL + PostGIS

- 官方文档：https://postgis.net/documentation/
- 中文教程：https://www.postgis.net.cn/

### C++ 图算法

- 《算法导论》第 22-25 章
- CP-Algorithms: https://cp-algorithms.com/graph/dijkstra.html

### Vue.js 3

- 官方文档：https://vuejs.org/
- Vue Router: https://router.vuejs.org/
- Pinia: https://pinia.vuejs.org/

### Crow HTTP 服务器

- GitHub: https://github.com/CrowCpp/Crow
- 文档：https://crowcpp.org/

---

## 🎉 成功启动！

如果所有步骤顺利完成，你现在拥有：

✅ **数据库**: PostgreSQL + PostGIS，包含完整的表结构和测试数据  
✅ **后端**: C++ HTTP 服务器运行在 http://localhost:8080  
✅ **前端**: Vue.js 开发服务器运行在 http://localhost:3000  
✅ **测试**: GoogleTest 单元测试通过  

**开始开发吧！** 🚀

---

**最后更新**: 2026-03-31  
**维护者**: yhm, zby, lxd
