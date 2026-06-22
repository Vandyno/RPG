@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0test_gdunit.ps1" %*
exit /b %ERRORLEVEL%
