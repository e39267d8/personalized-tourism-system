$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

$env:PATH = 'C:\Program Files\PostgreSQL\16\bin;' + $env:PATH

& (Join-Path $repoRoot 'backend\build-codex-verify-mingw\bin\Debug\tourism_server.exe') --host 127.0.0.1 --port 8080 *> (Join-Path $repoRoot 'backend_runtime.log')
