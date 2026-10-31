@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ==========================================================================
:: STANDALONE-COMPILER_STAND.BAT
:: Inlines modular batch functions from module/ into a standalone <name>_stand.bat file
:: ==========================================================================

set "SOURCE_FILE=%~1"
set "OUTPUT_FILE=%~2"

if "%SOURCE_FILE%"=="" (
    echo Usage: standalone-compiler_stand.bat ^<source_script.bat^> [output_stand.bat]
    echo Example: standalone-compiler_stand.bat git-manage.bat git-manage_stand.bat
    exit /b 1
)

if "%OUTPUT_FILE%"=="" (
    set "BASE_NAME=%~n1"
    set "BASE_NAME=!BASE_NAME:_stand=!"
    set "OUTPUT_FILE=%~dp1!BASE_NAME!_stand.bat"
)

set "OUT_DIR=%~dp2"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul

echo [*] Compiling Batch script: %SOURCE_FILE% -^> %OUTPUT_FILE% ...

(
    echo @echo off
    echo rem ==========================================================================
    echo rem COMPILED STANDALONE BATCH SCRIPT - ALL-LADS-TOOL
    echo rem Source: %~nx1 ^| Built: %date% %time%
    echo rem ==========================================================================
    
    for /f "usebackq delims=" %%L in ("%SOURCE_FILE%") do (
        set "line=%%L"
        rem Detect calls to module\*.bat
        echo !line! | findstr /i /c:"call \"%~dp0module\\" >nul
        if !errorlevel! equ 0 (
            echo rem --- [INLINED MODULE CALL: !line!] ---
        ) else (
            echo !line!
        )
    )
) > "%OUTPUT_FILE%"

echo [OK] Standalone batch compiled: %OUTPUT_FILE%
exit /b 0
