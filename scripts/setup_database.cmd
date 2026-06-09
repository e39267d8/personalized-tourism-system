@echo off
setlocal

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup_database.ps1" %*
exit /b %ERRORLEVEL%
