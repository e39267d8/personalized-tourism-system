# Windows 快速运行指南

这份指南按你当前的 Windows + PostgreSQL 15 + PostGIS 环境编写。

## 1. 打开命令行

建议使用 `cmd` 或 PowerShell 都可以。下面命令以 `cmd` 为例。

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system
set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
set PGCLIENTENCODING=UTF8
chcp 65001
```

检查 PostGIS 是否可用：

```bat
psql -U postgres -d postgres -c "SELECT version();"
```

## 2. 初始化数据库

如果你要重建演示数据库，执行：

```bat
psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS tourism_system;"
psql -U postgres -d postgres -c "CREATE DATABASE tourism_system WITH ENCODING 'UTF8';"
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -f database\verify_demo.sql
```

成功时你应该看到类似数量：

| 表 | 行数 |
|---|---:|
| `scenic_spots` | 8 |
| `graph_nodes` | 15 |
| `graph_edges` | 32 |
| `travel_diaries` | 3 |
| `route_plans` | 3 |
| `achievements` | 3 |

## 3. 编译后端

如果你使用当前项目里的构建方式：

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system\backend
cmake -S . -B build-codex-mingw -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug -DASIO_INCLUDE_DIR=C:\tmp\asio\include -DPostgreSQL_ROOT="C:\Program Files\PostgreSQL\15"
cmake --build build-codex-mingw
```

如果提示找不到 `asio.hpp`，需要先准备 Standalone Asio，并把 `-DASIO_INCLUDE_DIR=` 改成你本机 `asio.hpp` 所在目录。

## 4. 启动后端

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system\backend
set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
build-codex-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
```

如果你的数据库需要密码，先设置连接字符串：

```bat
set TOURISM_DB_CONN=host=127.0.0.1 port=5432 dbname=tourism_system user=postgres password=你的密码
```

后端启动后，新开一个终端测试：

```bat
powershell -Command "Invoke-RestMethod http://127.0.0.1:8080/health"
powershell -Command "Invoke-RestMethod http://127.0.0.1:8080/api/v1/scenic-spots"
```

`/health` 里应看到：

```json
{
  "status": "ok",
  "database": "connected"
}
```

## 5. 启动前端

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system\frontend
npm install
npm run dev
```

浏览器打开 Vite 输出的地址，通常是：

```text
http://127.0.0.1:3000/
```

前端会把 `/api` 自动代理到后端 `http://127.0.0.1:8080`。

## 6. 常见问题

| 问题 | 解决 |
|---|---|
| `psql` 不是内部或外部命令 | 执行 `set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%` |
| `postgis.control` 不存在 | PostGIS 没装完整，需要安装 PostgreSQL 15 对应的 PostGIS |
| `postgis-3.dll` 找不到 | 把 PostGIS 的 `bin/lib/share` 文件复制或安装到 PostgreSQL 15 目录，重启终端 |
| 中文乱码 | 执行 `chcp 65001` 和 `set PGCLIENTENCODING=UTF8` |
| 后端启动后数据库连接失败 | 检查 `TOURISM_DB_CONN`、用户名、密码、数据库名 |
| 前端页面没数据 | 先确认 `http://127.0.0.1:8080/health` 是否 database connected |
| 端口 8080 被占用 | 后端改用 `--port 8081`，同时修改 `frontend/vite.config.js` 代理地址 |

## 7. 当前演示范围

已经是真实数据库功能：

- 景点列表读取数据库
- 路线列表读取数据库
- 成就列表读取数据库
- 旅游日记查询、新增、编辑、删除写入数据库

仍然是演示功能：

- 预算推荐是后端内置规则
- AIGC 摘要/润色是占位逻辑
- 路线规划接口还没有真正调用 Dijkstra 动态计算
- 当前没有接入高德实时数据

## 8. 可选：导入高德 POI 数据

如果你有高德开放平台 Web 服务 Key，可以先生成 SQL，再导入数据库：

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system
python scripts\import_amap_pois.py --key 你的高德Key --city 北京 --keywords 景点 --output database\amap_pois.sql
psql -U postgres -d tourism_system -f database\amap_pois.sql
```

导入后重新打开搜索页，站内搜索会自动检索新增景点。
