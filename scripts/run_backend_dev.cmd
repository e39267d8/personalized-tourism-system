@echo off
setlocal
set "PATH=C:\Program Files\PostgreSQL\16\bin;%PATH%"
cd /d "%~dp0\.."
set "SERVER_EXE="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$c=@('backend\\build\\bin\\Release\\tourism_server.exe','backend\\build-mingw\\bin\\tourism_server.exe','backend\\build-codex-verify-mingw\\bin\\Debug\\tourism_server.exe','backend\\build\\bin\\Debug\\tourism_server.exe'); $item=$c | Where-Object { Test-Path $_ } | Sort-Object { (Get-Item $_).LastWriteTimeUtc } -Descending | Select-Object -First 1; if($item){$item}"`) do set "SERVER_EXE=%%I"
if not defined SERVER_EXE (
  echo [run_backend_dev] tourism_server.exe not found in backend build outputs.
  exit /b 1
)
"%SERVER_EXE%" --host 127.0.0.1 --port 8080 > backend_runtime.out 2> backend_runtime.err
