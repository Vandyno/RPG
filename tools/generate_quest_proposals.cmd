@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_quest_proposals.ps1" %*
exit /b %ERRORLEVEL%
