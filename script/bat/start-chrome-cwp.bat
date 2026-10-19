@echo off
echo Starting Chrome with Profile 1 and Remote Debugging on port 9222...
start "" "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1 --profile-directory="Profile 1" "https://pinwheel.indowebsite.net:2083/cwp_b9afa6ccc2b46428/fadhlisl/fileManager2.php"
echo Chrome launched! Keep this Chrome open and run ps_sync-cwp.ps1 anytime to sync instantly.
