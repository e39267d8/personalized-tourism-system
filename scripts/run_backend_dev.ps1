$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

$env:PATH = 'C:\Program Files\PostgreSQL\16\bin;' + $env:PATH

$candidates = @(
    (Join-Path $repoRoot 'backend\build\bin\Release\tourism_server.exe'),
    (Join-Path $repoRoot 'backend\build-mingw\bin\tourism_server.exe'),
    (Join-Path $repoRoot 'backend\build-codex-verify-mingw\bin\Debug\tourism_server.exe'),
    (Join-Path $repoRoot 'backend\build\bin\Debug\tourism_server.exe')
)
$serverExe = $candidates |
    Where-Object { Test-Path $_ } |
    Sort-Object { (Get-Item $_).LastWriteTimeUtc } -Descending |
    Select-Object -First 1
if (-not $serverExe) {
    throw 'tourism_server.exe not found in backend build outputs.'
}

& $serverExe --host 127.0.0.1 --port 8080 *> (Join-Path $repoRoot 'backend_runtime.log')
