<#
.SYNOPSIS
  Production-grade CWP Sync with Pre-flight Dependency Checker,
  Interactive Login Verifier, GitIgnore Engine, and User Confirmation.

.DESCRIPTION
  1. Checks and installs required dependencies (Node.js, Playwright, Chrome).
  2. Respects .gitignore (via git ls-files or manual ignore parser).
  3. Inspects Chrome CDP port 9222 and verifies CWP login / File Manager state.
  4. If login page is detected, prompts user to log in and press Enter to retry.
  5. Displays pre-flight summary and asks for (y/n) confirmation before syncing.
  6. Supports -Watch mode for automated live updates.

.EXAMPLE
  .\ps_sync-cwp.ps1
  .\ps_sync-cwp.ps1 -Watch
  .\ps_sync-cwp.ps1 -LocalPath .\dist -MaxFileMB 50
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$LocalPath = (Get-Location).Path,

    [string]$CwpUrl = "",
    [string]$ChromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe",
    [string]$Profile = "",
    [string]$ProfileDir = "",
    [int]$Port = 9222,
    [string]$ZipName = "site.zip",
    [int]$MaxFileMB = 25,
    [switch]$AutoExtract = $true,
    [switch]$Watch
)

$ErrorActionPreference = "Stop"
$LocalPath = (Resolve-Path $LocalPath).Path
$ToolDir = Join-Path $env:LOCALAPPDATA "cwp-sync"
$ZipPath = Join-Path $env:TEMP $ZipName

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$configPath = Join-Path $scriptDir "ps_sync-cwp.json"

# Load persistent config from <ps1filename>.json
$scriptConfig = [ordered]@{}
if (Test-Path $configPath) {
    try {
        $loaded = Get-Content -Path $configPath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($loaded) {
            foreach ($prop in $loaded.PSObject.Properties) {
                $scriptConfig[$prop.Name] = $prop.Value
            }
        }
    } catch {}
}

# Resolve CWP URL (use saved default from json or detect dynamically from open tabs)
$defaultUrl = if ($scriptConfig.Contains("cwp_url") -and $scriptConfig["cwp_url"]) { 
    $scriptConfig["cwp_url"] 
} else { 
    "https://pinwheel.indowebsite.net:2083/" 
}

if (-not $CwpUrl) {
    $CwpUrl = $defaultUrl
}

Write-Host "  [Target CWP] $CwpUrl" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# ==============================================================================
# 1. DEPENDENCY CHECK & AUTO-INSTALL
# ==============================================================================
Write-Host "`n[1/4] Checking System Dependencies..." -ForegroundColor Yellow

# Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "[!] Node.js is NOT installed on this machine." -ForegroundColor Red
    $choice = Read-Host "Would you like to install Node.js via winget now? (y/n)"
    if ($choice -match "^[Yy]") {
        Write-Host "> Installing Node.js LTS via winget..." -ForegroundColor Cyan
        winget install OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
            throw "Node.js was installed. Please restart your terminal and re-run this script."
        }
    }
    else {
        throw "Node.js is required. Download it from https://nodejs.org and re-run."
    }
}
else {
    $nodeVer = (node --version).Trim()
    Write-Host "  [OK] Node.js detected: $nodeVer" -ForegroundColor Green
}

# Auto-detect Chrome or Edge
if (-not (Test-Path $ChromePath)) {
    $altPaths = @(
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
        "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
        "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
        "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    )
    foreach ($alt in $altPaths) {
        if (Test-Path $alt) { $ChromePath = $alt; break }
    }
}
if (-not (Test-Path $ChromePath)) {
    throw "Chrome or Edge executable not found. Please specify -ChromePath path\to\chrome.exe."
}
else {
    Write-Host "  [OK] Browser executable found: $ChromePath" -ForegroundColor Green
}

# Check Playwright-Core in ToolDir
New-Item -ItemType Directory -Force -Path $ToolDir | Out-Null
if (-not (Test-Path (Join-Path $ToolDir "node_modules\playwright-core"))) {
    Write-Host "  [!] playwright-core is missing in tool directory." -ForegroundColor Yellow
    $ans = Read-Host "Download and install playwright-core now? (y/n) [default: y]"
    if ($ans -and $ans -notmatch "^[Yy]") {
        throw "playwright-core is required for Chrome CDP automation."
    }
    Write-Host "> Installing playwright-core in $ToolDir..." -ForegroundColor Cyan
    Push-Location $ToolDir
    try {
        if (-not (Test-Path "package.json")) { npm init -y | Out-Null }
        npm i playwright-core --no-audit --no-fund | Out-Null
        Write-Host "  [OK] playwright-core installed successfully." -ForegroundColor Green
    }
    finally { 
        Pop-Location 
    }
}
else {
    Write-Host "  [OK] playwright-core installed and ready." -ForegroundColor Green
}

# Write Runner JS (Verbatim here-string to prevent quotation/escaping parse bugs)
$runnerJs = @'
const { chromium } = require('playwright-core');
const path = require('path');

const port = process.env.CDP_PORT;
const action = process.env.RUN_ACTION;
const zip = process.env.ZIP_PATH || '';
const autoExtract = process.env.AUTO_EXTRACT === 'true';
const cwpUrl = process.env.CWP_URL || '';

(async () => {
  let browser;
  try {
    browser = await chromium.connectOverCDP('http://127.0.0.1:' + port);
  } catch (err) {
    console.log(JSON.stringify({ status: 'CDP_UNREACHABLE', error: err.message }));
    process.exit(0);
  }

  const closeCdp = async () => {
    try {
      if (browser) {
        if (typeof browser.disconnect === 'function') {
          await browser.disconnect();
        } else {
          await browser.close();
        }
      }
    } catch (_) {}
  };

  const pages = browser.contexts().flatMap(c => c.pages());

  if (action === 'CHECK') {
    const checkTabs = async (list) => {
      // 1. CWP File Manager Tab
      const fm = list.find(p => p.url().toLowerCase().includes('filemanager') || p.title().toLowerCase().includes('file manager'));
      if (fm) return { status: 'READY', url: fm.url() };

      // 2. CWP Dashboard -> Click File Manager
      const cwp = list.find(p => p.url().includes(':2083') || p.url().includes(':2031') || p.url().includes('cwp_') || p.title().toLowerCase().includes('cwp') || p.title().toLowerCase().includes('control web panel'));
      if (cwp) {
        if (cwp.url().includes('login')) {
          return { status: 'LOGIN_REQUIRED', url: cwp.url() };
        }
        // Auto-click File Manager link on CWP Dashboard
        try {
          const fmLink = cwp.locator('a[href*="fileManager2.php"], a:has-text("File Manager")').first();
          if (await fmLink.count() > 0) {
            await fmLink.click();
            await new Promise(r => setTimeout(r, 2000));
            const refreshed = browser.contexts().flatMap(c => c.pages());
            const newFm = refreshed.find(p => p.url().toLowerCase().includes('filemanager') || p.title().toLowerCase().includes('file manager'));
            if (newFm) return { status: 'READY', url: newFm.url() };
            return { status: 'CLICKED_FM_LINK', url: cwp.url() };
          }
        } catch (e) {}
        return { status: 'CWP_DASHBOARD', url: cwp.url() };
      }

      // 3. Indowebsite Client Portal -> Click Login Control Panel
      const indo = list.find(p => p.url().includes('indowebsite.co.id') || p.title().toLowerCase().includes('indowebsite'));
      if (indo) {
        try {
          const loginBtn = indo.locator('button:has-text("Login Control Panel"), a:has-text("Login Control Panel")').first();
          if (await loginBtn.count() > 0) {
            await loginBtn.click();
            await new Promise(r => setTimeout(r, 3000));
            return { status: 'CLICKED_LOGIN_PORTAL', url: indo.url() };
          }
        } catch (e) {}
        return { status: 'INDOWEBSITE_PORTAL', url: indo.url() };
      }

      return null;
    };

    let result = await checkTabs(pages);
    if (!result) {
      await new Promise(r => setTimeout(r, 1000));
      const refreshed = browser.contexts().flatMap(c => c.pages());
      result = await checkTabs(refreshed);
    }

    if (result) {
      console.log(JSON.stringify(result));
      await closeCdp();
      return;
    }

    console.log(JSON.stringify({ status: 'NO_CWP_TAB', count: pages.length }));
    await closeCdp();
    return;
  }

  if (action === 'UPLOAD') {
    const page = pages.find(p => p.url().includes('fileManager') || p.title().toLowerCase().includes('file manager'));
    if (!page) {
      console.log(JSON.stringify({ status: 'NO_TAB' }));
      await closeCdp();
      process.exit(2);
    }

    await page.bringToFront();
    const zipName = path.basename(zip);

    const uploadBtn = page.locator('button:has-text("Upload"), a:has-text("Upload"), text="Upload"').first();
    await uploadBtn.click();
    await page.waitForSelector('input[type=file]', { timeout: 15000 });

    const fileInput = page.locator('input[type=file]').first();
    await fileInput.setInputFiles(zip);

    const overwriteBtn = page.locator('button:has-text("Overwrite"), button:has-text("Replace"), button:has-text("Yes")').first();
    try {
      await overwriteBtn.waitFor({ state: 'visible', timeout: 2500 });
      await overwriteBtn.click();
    } catch (_) {}

    try {
      await page.waitForSelector('text=' + zipName, { timeout: 120000 });
      await page.waitForSelector('.progress-bar:not([aria-valuenow="100"]), .upload-in-progress', { state: 'detached', timeout: 60000 }).catch(() => {});
    } catch (_) {}
    await page.waitForTimeout(2000);

    const closeBtn = page.locator('.modal .close, button.close, button:has-text("Close"), text="×"').first();
    if (await closeBtn.isVisible().catch(() => false)) {
      await closeBtn.click().catch(() => {});
    }
    await page.waitForTimeout(1000);

    if (autoExtract) {
      try {
        const refreshBtn = page.locator('button[title*="Refresh"], a[title*="Refresh"], button:has-text("Reload")').first();
        if (await refreshBtn.isVisible().catch(() => false)) {
          await refreshBtn.click();
        } else {
          await page.reload({ waitUntil: 'domcontentloaded' }).catch(() => {});
        }
        await page.waitForTimeout(2000);

        const zipItem = page.locator('text="' + zipName + '"').first();
        if (await zipItem.isVisible({ timeout: 8000 }).catch(() => false)) {
          await zipItem.click({ button: 'right' });
          await page.waitForTimeout(500);

          const extractMenu = page.locator('.context-menu-item:has-text("Extract"), a:has-text("Extract"), text="Extract"').first();
          if (await extractMenu.isVisible({ timeout: 4000 }).catch(() => false)) {
            await extractMenu.click();
            await page.waitForTimeout(1000);

            const confirmExtract = page.locator('.modal button:has-text("Extract"), button:has-text("Unpack"), button:has-text("Yes")').first();
            if (await confirmExtract.isVisible({ timeout: 4000 }).catch(() => false)) {
              await confirmExtract.click();
              await page.waitForTimeout(3000);
            }
          }
        }
      } catch (exErr) {
        console.warn('Extract warning: ' + exErr.message);
      }
    }

    console.log(JSON.stringify({ status: 'UPLOADED' }));
    await closeCdp();
  }
})().catch(err => {
  console.log(JSON.stringify({ status: 'ERROR', message: err.message }));
  process.exit(1);
});
'@

Set-Content -Path (Join-Path $ToolDir "cwp_runner.js") -Value $runnerJs -Encoding UTF8

# ==============================================================================
# 2. GITIGNORE & FILE PACKAGING ENGINE
# ==============================================================================
Write-Host "`n[2/4] Analyzing Source Directory & .gitignore Rules..." -ForegroundColor Yellow

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$script:hardExcludes = @(
    '\.git(/|\\|$)', 'node_modules(/|\\)', '__pycache__(/|\\)', '\.vscode(/|\\)', '\.idea(/|\\)',
    '\.env(\..+)?$', 'site\.zip$', 'sync-cwp\.ps1$', 'ps_sync-cwp\.ps1$', 'screenshot.*\.png$', 'raw-.*\.png$',
    '\.DS_Store$', 'Thumbs\.db$', '\.tmp$'
)

function Get-IncludedFiles {
    param([string]$Root)

    $isGit = (Get-Command git -ErrorAction SilentlyContinue) -and (
        & git -C $Root rev-parse --is-inside-work-tree 2>$null
    )

    $result = @()

    if ($isGit) {
        Write-Host "  [OK] Git detected. Querying native .gitignore (git ls-files)..." -ForegroundColor Green
        $relFiles = & git -C $Root ls-files --cached --others --exclude-standard
        foreach ($rel in $relFiles) {
            $norm = $rel.Replace('\', '/')
            $blocked = $false
            foreach ($h in $script:hardExcludes) {
                if ($norm -match $h) { $blocked = $true; break }
            }
            if (-not $blocked) {
                $full = Join-Path $Root $rel
                if (Test-Path $full -PathType Leaf) {
                    $result += [PSCustomObject]@{ FullName = $full; Rel = $norm }
                }
            }
        }
    }
    else {
        Write-Host "  [INFO] Git repository not detected. Parsing .gitignore / .cwpignore..." -ForegroundColor Gray
        $userIgnores = @()
        foreach ($file in @(".gitignore", ".cwpignore")) {
            $p = Join-Path $Root $file
            if (Test-Path $p) {
                $userIgnores += Get-Content $p | Where-Object { $_ -and -not $_.Trim().StartsWith('#') }
            }
        }

        $allFiles = Get-ChildItem -Path $Root -Recurse -File
        $rootPrefix = $Root.TrimEnd('\') + '\'
        foreach ($f in $allFiles) {
            $rel = $f.FullName.Substring($rootPrefix.Length).Replace('\', '/')
            $blocked = $false

            foreach ($h in $script:hardExcludes) {
                if ($rel -match $h) { $blocked = $true; break }
            }
            if (-not $blocked) {
                foreach ($rule in $userIgnores) {
                    $cleanRule = $rule.Trim().TrimStart('/')
                    if ($rel -like "$cleanRule*" -or $rel -like "*$cleanRule*") {
                        $blocked = $true
                        break
                    }
                }
            }
            if (-not $blocked) {
                $result += [PSCustomObject]@{ FullName = $f.FullName; Rel = $rel }
            }
        }
    }

    return $result
}

$filesToSync = Get-IncludedFiles -Root $LocalPath
$totalBytes = ($filesToSync | ForEach-Object { (Get-Item $_.FullName).Length } | Measure-Object -Sum).Sum
$totalMB = [math]::Round(($totalBytes / 1MB), 2)
Write-Host "  [OK] Found $($filesToSync.Count) files to package ($totalMB MB total)" -ForegroundColor Green

# ==============================================================================
# 3. CHROME CDP CONNECTION & CWP LOGIN STATE VERIFIER
# ==============================================================================
Write-Host "`n[3/4] Verifying Chrome Profile & CWP Session State..." -ForegroundColor Yellow

function Get-BrowserProfiles {
    param([string]$BrowserExe)

    $profiles = @()
    $userDataDir = ""

    if ($BrowserExe -match "chrome\.exe") {
        $userDataDir = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
    }
    elseif ($BrowserExe -match "msedge\.exe") {
        $userDataDir = Join-Path $env:LOCALAPPDATA "Microsoft\Edge\User Data"
    }
    else {
        $userDataDir = Join-Path $env:LOCALAPPDATA "Google\Chrome\User Data"
    }

    if (-not (Test-Path $userDataDir)) {
        return @{ UserDataDir = $userDataDir; Profiles = @() }
    }

    $localStatePath = Join-Path $userDataDir "Local State"
    if (Test-Path $localStatePath) {
        try {
            $localState = Get-Content -Path $localStatePath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
            if ($localState.profile -and $localState.profile.info_cache) {
                $cache = $localState.profile.info_cache
                foreach ($prop in $cache.PSObject.Properties) {
                    $folderName = $prop.Name
                    $info = $prop.Value
                    $displayName = if ($info.name) { $info.name } else { $folderName }
                    $email = if ($info.user_name) { $info.user_name } else { "" }
                    $profiles += [PSCustomObject]@{
                        FolderName  = $folderName
                        DisplayName = $displayName
                        Email       = $email
                    }
                }
            }
        }
        catch {}
    }

    if ($profiles.Count -eq 0) {
        $profileDirs = Get-ChildItem -Path $userDataDir -Directory -ErrorAction SilentlyContinue | Where-Object { 
            $_.Name -eq "Default" -or $_.Name -like "Profile *" 
        }
        foreach ($d in $profileDirs) {
            $name = $d.Name
            $prefPath = Join-Path $d.FullName "Preferences"
            if (Test-Path $prefPath) {
                try {
                    $pref = Get-Content $prefPath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
                    if ($pref.profile -and $pref.profile.name) { $name = $pref.profile.name }
                } catch {}
            }
            $profiles += [PSCustomObject]@{
                FolderName  = $d.Name
                DisplayName = $name
                Email       = ""
            }
        }
    }

    return @{
        UserDataDir = $userDataDir
        Profiles    = $profiles
    }
}

function Mask-Text {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    $t = $Text.Trim()
    if ($t.Length -le 2) { return $t }
    return $t.Substring(0, 2) + ('*' * ($t.Length - 2))
}

function Mask-Email {
    param([string]$Email)
    if ([string]::IsNullOrEmpty($Email)) { return "" }
    $t = $Email.Trim()
    if (-not $t.Contains('@')) { return (Mask-Text $t) }
    $parts = $t.Split('@', 2)
    $u = $parts[0]
    $d = $parts[1]
    return ((Mask-Text $u) + "@" + $d)
}

function Test-CdpPort {
    try { 
        Invoke-RestMethod "http://127.0.0.1:$Port/json/version" -TimeoutSec 1 | Out-Null
        $true 
    }
    catch { 
        $false 
    }
}

$targetUserDataDir = ""
$targetProfileFolder = ""
$selectedDisplayName = ""
$maskedDisplayName = ""

if ($ProfileDir) {
    $targetUserDataDir = $ProfileDir
    $selectedDisplayName = "Custom Directory ($ProfileDir)"
    $maskedDisplayName = $selectedDisplayName
}
else {
    $browserInfo = Get-BrowserProfiles -BrowserExe $ChromePath
    $userDataDir = $browserInfo.UserDataDir
    $availableProfiles = $browserInfo.Profiles
    $lastProfileFolder = ""
    if ($scriptConfig.Contains("profile_folder") -and $scriptConfig["profile_folder"]) {
        $lastProfileFolder = $scriptConfig["profile_folder"]
    }

    if ($Profile) {
        $match = $availableProfiles | Where-Object { 
            $_.FolderName -eq $Profile -or $_.DisplayName -eq $Profile 
        } | Select-Object -First 1

        if ($match) {
            $targetProfileFolder = $match.FolderName
            $selectedDisplayName = "$($match.DisplayName) [$($match.FolderName)]"
            $maskedDisplayName = "$(Mask-Text $match.DisplayName) [$($match.FolderName)]"
        }
        else {
            $targetProfileFolder = $Profile
            $selectedDisplayName = "Profile [$Profile]"
            $maskedDisplayName = "Profile [$Profile]"
        }
    }
    elseif ($availableProfiles.Count -eq 0) {
        $targetProfileFolder = "Default"
        $selectedDisplayName = "Default Profile"
        $maskedDisplayName = "Default Profile"
    }
    elseif ($availableProfiles.Count -eq 1) {
        $p = $availableProfiles[0]
        $targetProfileFolder = $p.FolderName
        $selectedDisplayName = "$($p.DisplayName) [$($p.FolderName)]"
        $maskedDisplayName = "$(Mask-Text $p.DisplayName) [$($p.FolderName)]"
        Write-Host "  [OK] Using detected Chrome profile: $maskedDisplayName" -ForegroundColor Green
    }
    else {
        Write-Host "`n  Available Chrome Profiles on your machine:" -ForegroundColor Cyan
        $defaultIdx = 1
        for ($i = 0; $i -lt $availableProfiles.Count; $i++) {
            $p = $availableProfiles[$i]
            $isLast = ($p.FolderName -eq $lastProfileFolder)
            if ($isLast) { $defaultIdx = $i + 1 }
            $maskedName = Mask-Text $p.DisplayName
            $emailStr = if ($p.Email) { " (" + (Mask-Email $p.Email) + ")" } else { "" }
            $lastTag = if ($isLast) { " [Last Selected]" } else { "" }
            Write-Host "    [$($i + 1)] $maskedName [$($p.FolderName)]$emailStr$lastTag"
        }
        $customOpt = $availableProfiles.Count + 1
        Write-Host "    [$customOpt] Specify custom profile folder path..."

        $userChoice = Read-Host "`n  Select profile [1-$customOpt] [default: $defaultIdx]"
        if (-not $userChoice) { $userChoice = "$defaultIdx" }

        $choiceNum = 0
        if ([int]::TryParse($userChoice, [ref]$choiceNum) -and $choiceNum -ge 1 -and $choiceNum -le $availableProfiles.Count) {
            $chosen = $availableProfiles[$choiceNum - 1]
            $targetProfileFolder = $chosen.FolderName
            $selectedDisplayName = "$($chosen.DisplayName) [$($chosen.FolderName)]"
            $maskedDisplayName = "$(Mask-Text $chosen.DisplayName) [$($chosen.FolderName)]"
        }
        elseif ($choiceNum -eq $customOpt) {
            $customPath = Read-Host "  Enter directory path for Chrome profile"
            if (-not (Test-Path $customPath)) {
                New-Item -ItemType Directory -Force -Path $customPath | Out-Null
            }
            $targetUserDataDir = $customPath
            $targetProfileFolder = ""
            $selectedDisplayName = "Custom Directory ($customPath)"
            $maskedDisplayName = $selectedDisplayName
        }
        else {
            $chosen = $availableProfiles[0]
            $targetProfileFolder = $chosen.FolderName
            $selectedDisplayName = "$($chosen.DisplayName) [$($chosen.FolderName)]"
            $maskedDisplayName = "$(Mask-Text $chosen.DisplayName) [$($chosen.FolderName)]"
        }
    }

    if (-not $targetUserDataDir) {
        $targetUserDataDir = $userDataDir
    }

    $scriptConfig["profile_folder"]       = $targetProfileFolder
    $scriptConfig["profile_display_name"] = $selectedDisplayName
    $scriptConfig["user_data_dir"]         = $targetUserDataDir
    try {
        $scriptConfig | ConvertTo-Json -Depth 4 | Set-Content -Path $configPath -Encoding UTF8
    } catch {}
}

# Ensure Chrome is running with remote debugging
if (-not (Test-CdpPort)) {
    $procName = [System.IO.Path]::GetFileNameWithoutExtension($ChromePath)
    $runningProcs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($runningProcs) {
        Write-Host "`n  ===========================================================" -ForegroundColor Yellow
        Write-Host "  [DISCLAIMER] CHROME PERLU DIRESTART SEKALI UNTUK FITUR INI" -ForegroundColor Yellow
        Write-Host "  ===========================================================" -ForegroundColor Yellow
        Write-Host "  Google Chrome melarang script eksternal menyentuh tab kecuali" -ForegroundColor Gray
        Write-Host "  Chrome dibuka dengan remote debugging port ($Port)." -ForegroundColor Gray
        Write-Host "  -> Semua tab kamu yang terbuka saat ini akan otomatis dipulihkan (Restore Session)." -ForegroundColor Cyan
        Write-Host "  -> Setelah Chrome terbuka dengan port ini, JANGAN TUTUP Chrome." -ForegroundColor Cyan
        Write-Host "     Untuk semua sync berikutnya, script langsung jalan TANPA restart lagi!" -ForegroundColor Green
        Write-Host "  ===========================================================" -ForegroundColor Yellow
        $restartAns = Read-Host "`n  Restart Chrome sekarang dengan profile '$maskedDisplayName'? (y/n) [default: y]"
        if (-not $restartAns -or $restartAns -match "^[Yy]") {
            Write-Host "  Menutup $procName dengan aman..." -ForegroundColor Cyan
            $runningProcs | Stop-Process -Force -ErrorAction SilentlyContinue
            $waitCount = 0
            while ((Get-Process -Name $procName -ErrorAction SilentlyContinue) -and ($waitCount++ -lt 20)) {
                Start-Sleep -Milliseconds 250
            }
            Start-Sleep -Seconds 1
        }
        else {
            throw "$procName harus dijalankan dengan remote debugging di port $Port."
        }
    }

    Write-Host "> Membuka $procName dengan profile '$maskedDisplayName' (CDP port $Port)..." -ForegroundColor Cyan
    $chromeArgs = @(
        "--remote-debugging-port=$Port",
        "--remote-debugging-address=127.0.0.1",
        "--user-data-dir=`"$targetUserDataDir`"",
        "--profile-directory=`"$targetProfileFolder`"",
        "--restore-last-session",
        $CwpUrl
    )

    Start-Process $ChromePath -ArgumentList $chromeArgs
    $tries = 0
    while (-not (Test-CdpPort)) {
        Start-Sleep -Seconds 1
        if (++$tries -gt 25) { throw "Timed out waiting for Chrome CDP on port $Port." }
    }
    Write-Host "  [OK] Chrome CDP is active and connected." -ForegroundColor Green
}
else {
    Write-Host "  [OK] Chrome CDP port $Port is already open. Using your already-opened Chrome profile and CWP tab!" -ForegroundColor Green
}

# Interactive CWP Login & File Manager Tab Loop
while ($true) {
    $env:CDP_PORT = $Port
    $env:RUN_ACTION = "CHECK"
    $env:CWP_URL = $CwpUrl
    Push-Location $ToolDir
    try {
        $checkRaw = node cwp_runner.js 2>&1 | Out-String
    }
    finally { 
        Pop-Location 
    }

    $jsonStr = ($checkRaw -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\{.*\}$' } | Select-Object -Last 1)
    $state = $null
    if ($jsonStr) {
        try { $state = $jsonStr | ConvertFrom-Json } catch {}
    }

    if ($state -and $state.status -eq 'READY') {
        Write-Host "  [OK] CWP File Manager Tab Terdeteksi: $($state.url)" -ForegroundColor Green
        # Save fresh URL to ps_sync-cwp.json
        $CwpUrl = $state.url
        try {
            $configPath = Join-Path $PSScriptRoot "ps_sync-cwp.json"
            $cfg = @{}
            if (Test-Path $configPath) { $cfg = Get-Content $configPath -Raw | ConvertFrom-Json }
            $cfg | Add-Member -MemberType NoteProperty -Name "cwp_url" -Value $CwpUrl -Force
            $cfg | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8
        } catch {}
        break
    }
    elseif ($state -and $state.status -eq 'CLICKED_LOGIN_PORTAL') {
        Write-Host "  [>>] Berhasil klik 'Login Control Panel' di Portal Indowebsite!" -ForegroundColor Cyan
        Write-Host "       Menunggu tab CWP Dashboard terbuka..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
    elseif ($state -and $state.status -eq 'CLICKED_FM_LINK') {
        Write-Host "  [>>] Berhasil klik link 'File Manager' di CWP Dashboard!" -ForegroundColor Cyan
        Write-Host "       Menunggu tab File Manager terbuka..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
    }
    elseif ($state -and $state.status -eq 'LOGIN_REQUIRED') {
        Write-Host "`n  [!] LOGIN REQUIRED: Anda di halaman login CWP ($($state.url))." -ForegroundColor Yellow
        Write-Host "  -> Silakan login manual di Chrome, lalu buka File Manager > public_html." -ForegroundColor Cyan
        $choice = Read-Host "  Tekan [Enter] untuk cek lagi, atau [q] untuk batal"
        if ($choice -match "^[Qq]") { exit }
    }
    elseif ($state -and $state.status -eq 'NO_CWP_TAB') {
        Write-Host "`n  [!] Tidak ada tab Portal/CWP/File Manager di Chrome." -ForegroundColor Yellow
        Write-Host "  -> Buka tab 'platform.indowebsite.co.id' atau 'CWP' di Chrome yang sedang berjalan." -ForegroundColor Cyan
        $choice = Read-Host "  Tekan [Enter] untuk cek lagi, atau [q] untuk batal"
        if ($choice -match "^[Qq]") { exit }
    }
    else {
        Write-Host "`n  [!] Menunggu CWP File Manager..." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
}

# ==============================================================================
# 4. PRE-FLIGHT SUMMARY & USER CONFIRMATION (Y/N)
# ==============================================================================
Write-Host "`n==========================================================" -ForegroundColor Green
Write-Host "  READY FOR SYNC - PRE-FLIGHT SUMMARY" -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Green
Write-Host "  Source Directory : $LocalPath"
Write-Host "  Files Included   : $($filesToSync.Count) files"
Write-Host "  Payload Size     : ~$totalMB MB"
Write-Host "  Chrome Profile   : $maskedDisplayName"
Write-Host "  Target CWP URL   : $CwpUrl"
Write-Host "  Target CWP Mode  : Upload and Auto-Extract into public_html"
Write-Host "  Watch Mode       : $(if ($Watch) { 'ENABLED (Auto-Sync on save)' } else { 'Single Run' })"
Write-Host "==========================================================" -ForegroundColor Green

$confirm = Read-Host "`nExecute sync to CWP now? (y/n) [default: y]"
if ($confirm -and $confirm -notmatch "^[Yy]") {
    Write-Host "Sync cancelled by user." -ForegroundColor Yellow
    exit 0
}

# ==============================================================================
# 5. ZIP GENERATION & EXECUTION ENGINE
# ==============================================================================
function Invoke-ZipAndUpload {
    Write-Host "`n[Packaging] Building Linux-compatible archive: $ZipPath..." -ForegroundColor Cyan
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    $zipArchive = [System.IO.Compression.ZipFile]::Open($ZipPath, 'Create')

    try {
        $skippedCount = 0
        $addedCount = 0

        foreach ($item in $filesToSync) {
            $fileInfo = Get-Item $item.FullName
            $sizeMB = $fileInfo.Length / 1MB

            if ($sizeMB -gt $MaxFileMB) {
                Write-Host "  [SKIP HUGE FILE] $($item.Rel) ($([math]::Round($sizeMB, 1)) MB > $MaxFileMB MB)" -ForegroundColor Yellow
                $skippedCount++
                continue
            }

            [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zipArchive, $item.FullName, $item.Rel, 'Optimal'
            )
            $addedCount++
        }
    }
    finally {
        $zipArchive.Dispose()
    }

    $finalMB = [math]::Round(((Get-Item $ZipPath).Length / 1MB), 2)
    Write-Host "  [OK] Archive created: $finalMB MB ($($addedCount) files)" -ForegroundColor Green

    Write-Host "[Uploading] Pushing to CWP File Manager over Chrome CDP..." -ForegroundColor Cyan
    $env:CDP_PORT = $Port
    $env:RUN_ACTION = "UPLOAD"
    $env:ZIP_PATH = $ZipPath
    $env:AUTO_EXTRACT = if ($AutoExtract) { "true" } else { "false" }

    Push-Location $ToolDir
    try {
        $out = node cwp_runner.js 2>&1 | Out-String
    }
    finally { 
        Pop-Location 
    }

    if ($out -match '"UPLOADED"') {
        if ($AutoExtract) {
            Write-Host "[$(Get-Date -f HH:mm:ss)] SUCCESS: Uploaded and Auto-Extracted $ZipName to CWP!" -ForegroundColor Green
        }
        else {
            Write-Host "[$(Get-Date -f HH:mm:ss)] SUCCESS: Uploaded $ZipName to CWP." -ForegroundColor Green
        }
    }
    else {
        Write-Host "[X] Upload encountered an issue: $out" -ForegroundColor Red
    }
}

# Run Initial Sync
Invoke-ZipAndUpload

# ==============================================================================
# 6. WATCH MODE (DEBOUNCED WITH SAFE DISPOSAL)
# ==============================================================================
if ($Watch) {
    Write-Host "`nWatching $LocalPath for changes... (Press Ctrl+C to stop)" -ForegroundColor Yellow
    $fsw = New-Object System.IO.FileSystemWatcher $LocalPath
    $fsw.IncludeSubdirectories = $true
    $fsw.EnableRaisingEvents = $true

    $subId = "CwpSync_Watcher_" + [Guid]::NewGuid().ToString("N")
    $script:dirty = $false
    $handler = { $script:dirty = $true }

    Register-ObjectEvent -InputObject $fsw -EventName Changed -SourceIdentifier "${subId}_Changed" -Action $handler | Out-Null
    Register-ObjectEvent -InputObject $fsw -EventName Created -SourceIdentifier "${subId}_Created" -Action $handler | Out-Null
    Register-ObjectEvent -InputObject $fsw -EventName Deleted -SourceIdentifier "${subId}_Deleted" -Action $handler | Out-Null
    Register-ObjectEvent -InputObject $fsw -EventName Renamed -SourceIdentifier "${subId}_Renamed" -Action $handler | Out-Null

    try {
        while ($true) {
            Start-Sleep -Milliseconds 800
            if ($script:dirty) {
                Start-Sleep -Milliseconds 1200  # Debounce delay
                $script:dirty = $false
                Write-Host "`nChange detected! Re-syncing..." -ForegroundColor Yellow
                $filesToSync = Get-IncludedFiles -Root $LocalPath
                Invoke-ZipAndUpload
            }
        }
    }
    finally {
        Write-Host "`nStopping Watcher and Cleaning event listeners..." -ForegroundColor Gray
        Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "${subId}*" } | Unregister-Event
        $fsw.Dispose()
        Write-Host "Watcher stopped safely." -ForegroundColor Green
    }
}