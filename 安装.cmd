@echo off
setlocal
if not exist "%~dp0CodexStartupAnimationSetup.exe" (
  echo Cannot find CodexStartupAnimationSetup.exe. Please download and extract the complete project ZIP.
  pause
  exit /b 1
)
start "Codex Startup Animation Setup" "%~dp0CodexStartupAnimationSetup.exe"
