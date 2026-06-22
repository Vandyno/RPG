@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0import_project.ps1" %*
exit /b %ERRORLEVEL%
