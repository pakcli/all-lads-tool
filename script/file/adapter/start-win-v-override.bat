@echo off
title PolyClip Win+V Daemon
echo Starting PolyClip Win+V Override and History Daemon...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0daemon-override-win-v.ps1"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Daemon stopped with code %ERRORLEVEL%
    pause
)
