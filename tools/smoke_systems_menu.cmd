@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0smoke_systems_menu.ps1" %*
exit /b %ERRORLEVEL%
