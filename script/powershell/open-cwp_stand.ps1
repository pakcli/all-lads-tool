# ps_open-cwp.ps1
# Automates the 3-step login navigation via Chrome CDP:
# 1. Finds 'platform.indowebsite.co.id/services/hosting'
# 2. Clicks button: "Login Control Panel"
# 3. Waits for CWP dashboard tab to open, then finds & clicks: <a href="fileManager2.php">File Manager</a>
# 4. Updates ps_sync-cwp.json with the fresh File Manager URL!

[CmdletBinding()]
param(
    [int]$Port = 9222
)

$ErrorActionPreference = "Stop"

# Helper for masked output
function Write-Info($msg) { Write-Host "[CWP-NAV] $msg" -ForegroundColor Cyan }
function Write-Success($msg) { Write-Host "[CWP-NAV] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[CWP-NAV] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[CWP-NAV] $msg" -ForegroundColor Red }

# 1. Verify Chrome CDP port
try {
    $version = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/version" -TimeoutSec 3 -ErrorAction Stop
    Write-Success "Connected to Chrome DevTools (Port $Port)"
} catch {
    Write-Err "Chrome tidak terdeteksi di port $Port."
    Write-Warn "Jalankan .\start-chrome-cwp.bat terlebih dahulu untuk membuka Chrome dengan port debugging."
    exit 1
}

# 2. Find Node.js or run inline node script
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
$nodePath = if ($nodeCmd) { $nodeCmd.Source } else { $null }
if (-not $nodePath) {
    Write-Err "Node.js tidak ditemukan di PATH. Node.js diperlukan untuk Chrome DevTools Protocol."
    exit 1
}

$tempNavJs = [System.IO.Path]::Combine($PSScriptRoot, ".cwp_nav_temp.js")

$navJsContent = @'
const http = require('http');
const WebSocket = (function() {
    try {
        const puppeteerPath = require.resolve('puppeteer-core');
        const wsPath = require.resolve('ws', { paths: [puppeteerPath, process.cwd()] });
        return require(wsPath);
    } catch {
        return null;
    }
})();

const PORT = 9222;

function httpGet(url) {
    return new Promise((resolve, reject) => {
        http.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(data)); } catch (e) { resolve(data); }
            });
        }).on('error', reject);
    });
}

function sendWs(ws, method, params = {}) {
    return new Promise((resolve, reject) => {
        const id = Math.floor(Math.random() * 100000);
        const timer = setTimeout(() => reject(new Error(`Timeout waiting for ${method}`)), 15000);
        function onMessage(data) {
            try {
                const msg = JSON.parse(data.toString());
                if (msg.id === id) {
                    clearTimeout(timer);
                    ws.off('message', onMessage);
                    if (msg.error) reject(new Error(msg.error.message));
                    else resolve(msg.result);
                }
            } catch (e) {}
        }
        ws.on('message', onMessage);
        ws.send(JSON.stringify({ id, method, params }));
    });
}

async function evalInTab(tabWsUrl, expression) {
    if (!WebSocket) throw new Error('WebSocket module not found');
    const ws = new WebSocket(tabWsUrl);
    await new Promise((res, rej) => {
        ws.once('open', res);
        ws.once('error', rej);
    });
    try {
        const result = await sendWs(ws, 'Runtime.evaluate', {
            expression,
            returnByValue: true,
            awaitPromise: true
        });
        return result.result ? result.result.value : null;
    } finally {
        ws.close();
    }
}

async function run() {
    console.log('[JS] Fetching Chrome tabs...');
    const tabs = await httpGet(`http://127.0.0.1:${PORT}/json`);
    const pageTabs = tabs.filter(t => t.type === 'page');

    // Step 1: Check if File Manager is ALREADY open
    const fmTab = pageTabs.find(t => t.url && t.url.includes('fileManager2.php'));
    if (fmTab) {
        console.log('[FOUND_FM] ' + fmTab.url);
        return;
    }

    // Step 2: Check if CWP Dashboard is open
    const cwpTab = pageTabs.find(t => t.url && (t.url.includes(':2083') || t.url.includes('cwp_')));
    if (cwpTab) {
        console.log('[STEP] Found CWP Dashboard tab: ' + cwpTab.url);
        console.log('[STEP] Searching for File Manager link...');
        const clickResult = await evalInTab(cwpTab.webSocketDebuggerUrl, `
            (function() {
                // Find <a href="fileManager2.php" target="_blank">File Manager</a>
                const fmLink = document.querySelector('a[href*="fileManager2.php"]') || 
                               Array.from(document.querySelectorAll('a')).find(a => a.textContent.toLowerCase().includes('file manager'));
                if (fmLink) {
                    fmLink.click();
                    return { clicked: true, href: fmLink.href };
                }
                return { clicked: false, error: 'Link fileManager2.php not found on CWP dashboard' };
            })()
        `);
        console.log('[RESULT_CWP] ' + JSON.stringify(clickResult));
        return;
    }

    // Step 3: Find Indowebsite Portal tab
    const portalTab = pageTabs.find(t => t.url && t.url.includes('indowebsite.co.id'));
    if (portalTab) {
        console.log('[STEP] Found Indowebsite Portal tab: ' + portalTab.url);
        console.log('[STEP] Searching & clicking "Login Control Panel" button...');
        const clickResult = await evalInTab(portalTab.webSocketDebuggerUrl, `
            (function() {
                const btns = Array.from(document.querySelectorAll('button, a'));
                const loginBtn = btns.find(b => b.textContent && b.textContent.includes('Login Control Panel'));
                if (loginBtn) {
                    loginBtn.click();
                    return { clicked: true, text: loginBtn.textContent.trim() };
                }
                return { clicked: false, error: 'Button "Login Control Panel" not found in portal page' };
            })()
        `);
        console.log('[RESULT_PORTAL] ' + JSON.stringify(clickResult));
        return;
    }

    console.log('[ERROR] No matching tab found. Buka tab platform.indowebsite.co.id/services/hosting di Chrome terlebih dahulu.');
}

run().catch(err => {
    console.error('[ERROR] ' + err.message);
    process.exit(1);
});
'@

try {
    Set-Content -Path $tempNavJs -Value $navJsContent -Encoding UTF8

    Write-Info "Scanning tab Chrome..."
    
    $maxTries = 10
    $foundFmUrl = $null

    for ($i = 1; $i -le $maxTries; $i++) {
        $output = & $nodePath $tempNavJs 2>&1
        $outStr = $output -join "`n"

        if ($outStr -match '\[FOUND_FM\]\s*(https?://[^\s]+)') {
            $foundFmUrl = $matches[1]
            Write-Success "File Manager Tab ditemukan!"
            Write-Host "URL: $foundFmUrl" -ForegroundColor Green
            break
        }

        if ($outStr -match '\[RESULT_CWP\]\s*(.+)') {
            $res = $matches[1]
            Write-Info "Klik File Manager di CWP Dashboard: $res"
            Write-Info "Menunggu tab File Manager terbuka (2 detik)..."
            Start-Sleep -Seconds 2
            continue
        }

        if ($outStr -match '\[RESULT_PORTAL\]\s*(.+)') {
            $res = $matches[1]
            Write-Info "Klik 'Login Control Panel' di Portal Indowebsite: $res"
            Write-Info "Menunggu CWP Dashboard SSO redirect (4 detik)..."
            Start-Sleep -Seconds 4
            continue
        }

        if ($outStr -match '\[ERROR\]\s*(.+)') {
            Write-Warn $matches[1]
        }

        Start-Sleep -Seconds 2
    }

    if ($foundFmUrl) {
        # Update config ps_sync-cwp.json
        $configPath = Join-Path $PSScriptRoot "ps_sync-cwp.json"
        $config = @{}
        if (Test-Path $configPath) {
            try { $config = Get-Content $configPath -Raw | ConvertFrom-Json } catch {}
        }
        $config | Add-Member -MemberType NoteProperty -Name "cwp_url" -Value $foundFmUrl -Force
        $config | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8
        Write-Success "URL File Manager berhasil disimpan ke ps_sync-cwp.json!"
        Write-Host ""
        Write-Host "Sekarang kamu bisa langsung jalankan .\ps_sync-cwp.ps1 untuk upload & sync website!" -ForegroundColor Cyan
    } else {
        Write-Warn "Belum sampai ke File Manager. Jika ada tab baru yang terbuka, jalankan lagi script ini untuk melanjutkan klik."
    }
} finally {
    if (Test-Path $tempNavJs) {
        Remove-Item $tempNavJs -Force -ErrorAction SilentlyContinue
    }
}
