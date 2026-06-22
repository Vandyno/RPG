@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0smoke_render.ps1" %*
exit /b %ERRORLEVEL%
