@echo off
rem =========================================================================
rem Canvas Grade Monitor Launcher Batch Script
rem Version: 3.0
rem Starts the local proxy server if needed and launches the dashboard in browser
rem =========================================================================

set VERSION=3.0
set SCRIPT_DIR=%~dp0

rem Launch Grade Monitor silently using PowerShell launcher
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_DIR%launch.ps1"
