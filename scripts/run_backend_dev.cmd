@echo off
setlocal
set "PATH=C:\Program Files\PostgreSQL\16\bin;%PATH%"
cd /d "%~dp0\.."
backend\build-codex-verify-mingw\bin\Debug\tourism_server.exe --host 127.0.0.1 --port 8080 > backend_runtime.out 2> backend_runtime.err
