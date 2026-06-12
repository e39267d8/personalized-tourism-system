@echo off
setlocal
set "PATH=C:\Program Files\PostgreSQL\16\bin;%PATH%"
cd /d "%~dp0\.."
set "SERVER_EXE="
if exist "backend\build-mingw\bin\tourism_server.exe" set "SERVER_EXE=backend\build-mingw\bin\tourism_server.exe"
if not defined SERVER_EXE if exist "backend\build-codex-verify-mingw\bin\Debug\tourism_server.exe" set "SERVER_EXE=backend\build-codex-verify-mingw\bin\Debug\tourism_server.exe"
if not defined SERVER_EXE if exist "backend\build\bin\Debug\tourism_server.exe" set "SERVER_EXE=backend\build\bin\Debug\tourism_server.exe"
if not defined SERVER_EXE (
  echo [run_backend_dev] tourism_server.exe not found in build-mingw / build-codex-verify-mingw / build.
  exit /b 1
)
"%SERVER_EXE%" --host 127.0.0.1 --port 8080 > backend_runtime.out 2> backend_runtime.err
