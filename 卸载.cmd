@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LOCALAPPDATA%\CodexStartupAnimation\Uninstall.ps1"
echo.
pause
