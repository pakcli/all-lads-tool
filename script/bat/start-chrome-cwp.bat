@echo off
echo Starting Chrome with Remote Debugging on port 9222...
set "CHROME_BIN=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME_BIN%" set "CHROME_BIN=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
start "" "%CHROME_BIN%" --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --profile-directory="Default" "https://pinwheel.indowebsite.net:2083/"
echo Chrome launched! Keep this Chrome open and run ps_sync-cwp.ps1 anytime to sync.
