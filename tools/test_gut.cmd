@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test_gut.ps1" %*
exit /b %ERRORLEVEL%
