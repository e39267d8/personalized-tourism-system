# 第 1 天学习笔记：把项目跑起来

今天目标不是看懂所有代码，而是做到三件事：

1. 知道这个项目由前端、后端、数据库三部分组成。
2. 能用正确命令启动数据库、后端、前端。
3. 遇到报错时知道先看哪个地方。

## 1. 项目结构

```text
personalized-tourism-system/
  frontend/    Vue3 前端页面，浏览器看到的界面基本都在这里
  backend/     C++ 后端服务，负责提供 HTTP API
  database/    PostgreSQL 建表、演示数据、检查脚本
  docs/        项目说明和学习笔记
```

重点文件：

```text
frontend/package.json          前端启动命令
frontend/vite.config.js        前端端口和 API 代理配置
frontend/src/main.js           前端入口
frontend/src/router/index.js   页面路由
frontend/src/views/            页面文件
frontend/src/services/         前端请求后端 API 的封装

backend/CMakeLists.txt         后端编译配置
backend/src/main.cpp           后端入口和 API 路由

database/schema.sql            建表脚本
database/seed_demo.sql         演示数据
database/verify_demo.sql       数据检查脚本
```

## 2. cmd 和 PowerShell 不要混用

你之前的报错来自这里：

```text
$env:PGCLIENTENCODING='UTF8'
```

这是 PowerShell 写法，如果你在 cmd 里运行，就会报错。

另一个报错：

```text
& 'C:\Program Files\PostgreSQL\15\bin\psql.exe' ...
```

这个也是 PowerShell 写法，cmd 不能这么写。

## 3. 推荐你今天使用 cmd

打开 cmd 后运行：

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system
set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
set PGCLIENTENCODING=UTF8
chcp 65001
```

检查 PostgreSQL：

```bat
psql -U postgres -d postgres -c "SELECT version();"
```

如果提示 `psql` 不是内部或外部命令，说明 PostgreSQL 的 `bin` 目录没有加入当前终端 PATH。你也可以直接使用完整路径：

```bat
"C:\Program Files\PostgreSQL\15\bin\psql.exe" -U postgres -d postgres -c "SELECT version();"
```

当前机器自检结果：

```text
Node.js: v24.14.1
npm: 11.11.0
CMake: 4.3.1
PostgreSQL psql: 15.17
```

## 4. 初始化数据库

如果数据库还没建，或者你想重建演示数据：

```bat
psql -U postgres -d postgres -c "DROP DATABASE IF EXISTS tourism_system;"
psql -U postgres -d postgres -c "CREATE DATABASE tourism_system WITH ENCODING 'UTF8';"
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\schema.sql
psql -U postgres -d tourism_system -v ON_ERROR_STOP=1 -f database\seed_demo.sql
psql -U postgres -d tourism_system -f database\diary_social.sql
psql -U postgres -d tourism_system -f database\verify_demo.sql
```

能跑通的话，说明数据库这一层先过关了。

## 5. 启动后端

后端是 C++ 项目，用 CMake 编译。

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system\backend
cmake -S . -B build-codex-mingw -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Debug -DASIO_INCLUDE_DIR=C:\tmp\asio\include -DPostgreSQL_ROOT="C:\Program Files\PostgreSQL\15"
cmake --build build-codex-mingw
set PATH=C:\Program Files\PostgreSQL\15\bin;%PATH%
build-codex-mingw\bin\tourism_server.exe --host 127.0.0.1 --port 8080
```

如果数据库需要密码，在启动后端前加：

```bat
set TOURISM_DB_CONN=host=127.0.0.1 port=5432 dbname=tourism_system user=postgres password=你的密码
```

后端默认地址：

```text
http://127.0.0.1:8080
```

测试后端是否正常：

```bat
powershell -Command "Invoke-RestMethod http://127.0.0.1:8080/health"
powershell -Command "Invoke-RestMethod http://127.0.0.1:8080/api/v1/scenic-spots"
```

## 6. 启动前端

新开一个 cmd：

```bat
cd C:\Users\seele\Desktop\code\personalized-tourism-system\frontend
npm.cmd install
npm.cmd run dev
```

前端默认地址：

```text
http://127.0.0.1:3000/
```

前端代理配置在：

```text
frontend/vite.config.js
```

当前配置是：

```text
前端端口：3000
后端接口：http://127.0.0.1:8080
```

## 7. 今天要完成的检查清单

- [ ] 我能进入项目根目录。
- [ ] 我知道 cmd 和 PowerShell 的环境变量写法不同。
- [ ] 我能运行 `psql -U postgres -d postgres -c "SELECT version();"`。
- [ ] 我能导入 `schema.sql` 和 `seed_demo.sql`。
- [ ] 我知道后端入口是 `backend/src/main.cpp`。
- [ ] 我知道前端入口是 `frontend/src/main.js`。
- [ ] 我知道页面文件主要在 `frontend/src/views/`。
- [ ] 我能启动后端并访问 `/health`。
- [ ] 我能启动前端并打开 `http://127.0.0.1:3000/`。
- [ ] 我能用一句话解释：前端通过 `/api` 请求后端，后端从 PostgreSQL 读写数据。

## 8. 今天要写下来的 5 个问题

把答案写在这里，哪怕写得很简单也可以。

1. 前端项目用的是什么框架？

答案：

2. 后端项目用的是什么语言？

答案：

3. 数据库叫什么名字？

答案：

4. 前端端口是多少？后端端口是多少？

答案：

5. 如果前端没数据，我第一步应该检查哪个地址？

答案：

## 9. 今天结束前的小练习

打开这些文件，只看 5 分钟，不要求完全看懂：

```text
frontend/src/router/index.js
frontend/src/views/Home.vue
frontend/src/services/tourismApi.js
backend/src/main.cpp
database/schema.sql
```

然后写一句话：

```text
我今天大概知道这个项目是这样工作的：

浏览器打开 Vue 前端，前端页面通过 tourismApi 调用 /api/v1/... 接口，
C++ 后端接收请求，再去 PostgreSQL 数据库查询或写入数据，最后返回 JSON 给前端展示。
```
