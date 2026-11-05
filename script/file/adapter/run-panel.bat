@echo off
title PolyClip 4-Mode Panel Launcher
if exist "%~dp0..\detector-clipboard-4-mode.ps1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\detector-clipboard-4-mode.ps1" -Panel
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0detector-clipboard-4-mode.ps1" -Panel
)
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR OCCURRED] Window exited with code %ERRORLEVEL%
    pause
)
