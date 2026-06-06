@echo off
chcp 65001 >nul
title =====个性化旅游系统 一键启动=====

echo ========================================
echo    个性化旅游系统 - 开发环境启动
echo ========================================
echo.

REM ==========================================
REM 1. 检查 PostgreSQL 数据库
REM ==========================================
echo [1/4] 检查 PostgreSQL 服务...
sc query postgresql-x64-16 | find "RUNNING" >nul
if %errorlevel% neq 0 (
    echo   [提示] PostgreSQL 未运行，正在启动...
    net start postgresql-x64-16 >nul 2>&1
    if %errorlevel% neq 0 (
        echo   [错误] 无法启动 PostgreSQL，请手动启动后重试。
        pause
        exit /b 1
    )
    timeout /t 3 /nobreak >nul
)
echo   [√] PostgreSQL 服务运行中

REM ==========================================
REM 2. 验证数据库连接
REM ==========================================
echo [2/4] 验证数据库连接...
"C:\Program Files\PostgreSQL\16\bin\psql.exe" -h 127.0.0.1 -U postgres -d tourism_system -c "SELECT 1;" >nul 2>&1
if %errorlevel% neq 0 (
    echo   [错误] 数据库连接失败！请检查:
    echo     - PostgreSQL 是否运行在 127.0.0.1:5432
    echo     - tourism_system 数据库是否存在
    echo     - 如果首次使用，请先运行 database\schema.sql 和种子数据
    pause
    exit /b 1
)
echo   [√] 数据库连接正常

REM ==========================================
REM 3. 启动后端服务 (C++ / Crow)
REM ==========================================
echo [3/4] 启动后端服务 (端口 8080)...

REM 检查端口是否已被占用
netstat -ano | find ":8080" | find "LISTENING" >nul
if %errorlevel% equ 0 (
    echo   [警告] 端口 8080 已被占用，正在尝试释放...
    for /f "tokens=5" %%a in ('netstat -ano ^| find ":8080" ^| find "LISTENING"') do (
        taskkill /PID %%a /F >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

REM 设置环境变量
set "TOURISM_LLM_API_KEY=sk-placeholder"

REM 启动后端 (后台运行)
start "旅游系统后端" /MIN cmd /c "cd /d "%~dp0backend\build\bin\Debug" && tourism_server.exe"

REM 等待后端启动
echo   等待后端启动...
:wait_backend
timeout /t 1 /nobreak >nul
curl -s -o nul http://localhost:8080/health 2>nul
if %errorlevel% neq 0 (
    goto wait_backend
)
echo   [√] 后端服务已启动: http://localhost:8080

REM ==========================================
REM 4. 启动前端开发服务器 (Vue / Vite)
REM ==========================================
echo [4/4] 启动前端开发服务器 (端口 5173)...

REM 检查前端是否已安装依赖
if not exist "%~dp0frontend\node_modules\" (
    echo   [提示] 首次运行，正在安装前端依赖...
    cd /d "%~dp0frontend"
    call npm install
    cd /d "%~dp0"
)

REM 启动前端 (新窗口)
start "旅游系统前端" /MIN cmd /c "cd /d "%~dp0frontend" && npx vite --host 0.0.0.0 --port 5173"

echo.
echo ========================================
echo   全部服务启动完成！
echo ========================================
echo   后端 API:  http://localhost:8080
echo   前端页面:  http://localhost:5173
echo   健康检查:  http://localhost:8080/health
echo   仪表盘:    http://localhost:8080/api/v1/dashboard
echo ========================================
echo.
echo   测试账号: demo_user / demo123456
echo.
echo   [提示] 关闭本窗口不会停止服务
echo         需要停止时请关闭后端和前端窗口
echo ========================================
pause
