<#
.SYNOPSIS
    All Lads Tool - Master Dispatcher & Main Menu
.DESCRIPTION
    Zero-hardcoded central launcher for all toolchain scripts in all-lads-tool.
    Organized strictly A-Z by runtime script folder (bash, bat, javascript, powershell, python).
    Features Red-first RGB color progression, zero-action quick rerun (0),
    negative history stack indexing (-1, -2, -3), and deep history viewer (h).
.PARAMETER TargetDir
    Target project directory (default: parent workspace).
.PARAMETER ResetVersion
    Directly resets all-lads-tool to a specific version (e.g. 01-01, 01-00) or commit.
.PARAMETER CheckUpstream
    Checks if there are upstream updates on origin/main without pulling.
#>
[CmdletBinding()]
param(
    [string]$TargetDir = "",
    [string]$ResetVersion = "",
    [string]$LaunchedBy = "",
    [string]$RunJsonPath = "",
    [switch]$CheckUpstream
)

$scriptDir = $PSScriptRoot
$parentDir = (Resolve-Path (Join-Path $scriptDir "..")).Path

# 1. Identity & Origin: Siapa yang me-launch _mainmenu
$launcherInfo = if ($LaunchedBy) {
    $LaunchedBy
} elseif ($env:ALL_LADS_LAUNCHER) {
    $env:ALL_LADS_LAUNCHER
} else {
    "Direct Execution (No Launcher)"
}

# 2. Perantara _run.json: Cari file konfigurasi perantara
$resolvedRunJson = if ($RunJsonPath -and (Test-Path -LiteralPath $RunJsonPath)) {
    $RunJsonPath
} elseif (Test-Path (Join-Path $scriptDir "_run.json")) {
    Join-Path $scriptDir "_run.json"
} elseif (Test-Path (Join-Path $parentDir "_run.json")) {
    Join-Path $parentDir "_run.json"
} else {
    ""
}

# 3. Load State & Watch _run.json
$appState = @{
    lastTarget     = $parentDir
    activeSlug     = "default"
    history        = @()
    allowedDomains = @()
}

if ($resolvedRunJson) {
    try {
        $raw = [System.IO.File]::ReadAllText($resolvedRunJson, [System.Text.Encoding]::UTF8)
        if ($raw) {
            $parsed = $raw | ConvertFrom-Json
            if ($parsed.activeSlug)     { $appState.activeSlug = $parsed.activeSlug }
            if ($parsed.allowedDomains) { $appState.allowedDomains = @($parsed.allowedDomains) }
            if ($parsed.history)        { $appState.history = [System.Collections.ArrayList]@($parsed.history) }
        }
    } catch { }
}
if (-not ($appState.history -is [System.Collections.ArrayList])) {
    $appState.history = [System.Collections.ArrayList]@($appState.history)
}

$currentTarget = if ($TargetDir -and (Test-Path $TargetDir)) {
    (Resolve-Path $TargetDir).Path
} elseif ($appState.lastTarget -and (Test-Path $appState.lastTarget)) {
    $appState.lastTarget
} else {
    $parentDir
}

function Update-MainMenuHtml {
    <#
    .SYNOPSIS
        Auto-generates _mainmenu.html based on live scan of script/ folder.
        Conforms strictly to Rule #007 (Zero-Localhost, Cross-OS File URL).
    #>
    param()

    $htmlPath = Join-Path $scriptDir "_mainmenu.html"
    $scriptRoot = Join-Path $scriptDir "script"

    $scannedTools = @()
    if (Test-Path $scriptRoot) {
        $files = Get-ChildItem -Path $scriptRoot -Recurse -File | 
            Where-Object { 
                $_.Name -like "*_stand.*" -or 
                ($_.Extension -in ".ps1", ".js", ".py", ".sh", ".bat" -and $_.Directory.Name -ne "module" -and $_.Directory.Name -ne "modules")
            }

        foreach ($f in $files) {
            $context = $f.Directory.Name.ToUpper()
            $ext = $f.Extension.TrimStart('.').ToLower()
            $cleanName = $f.BaseName -replace '_stand$', ''
            $scannedTools += [PSCustomObject]@{
                Name     = $cleanName
                FileName = $f.Name
                Context  = $context
                Ext      = $ext
                RelPath  = ($f.FullName.Substring($scriptDir.Length).TrimStart('\', '/')).Replace('\', '/')
            }
        }
    }

    $cardsHtml = ""
    foreach ($tool in $scannedTools) {
        $tagClass = switch ($tool.Context) {
            "FILE"       { "tag-file" }
            "REPO"       { "tag-repo" }
            "POWERSHELL" { "tag-repo" }
            "WEBSITE"    { "tag-web" }
            "JAVASCRIPT" { "tag-web" }
            "BLENDER"    { "tag-3d" }
            "UNITY"      { "tag-3d" }
            "PYTHON"     { "tag-3d" }
            default      { "tag-file" }
        }

        $cardsHtml += @"
    <div class="card" data-ext="$($tool.Ext)" data-file="$($tool.FileName)">
      <div class="card-header">
        <span class="card-title">$($tool.Name)</span>
        <span class="tag $tagClass">$($tool.Context)</span>
      </div>
      <p class="card-desc">Target: $($tool.RelPath)</p>
      <button class="btn" onclick="executeTool('$($tool.FileName)')">Select Tool</button>
    </div>
"@
    }

    $generatedTimestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $totalCount = $scannedTools.Count

    $fullHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>All Lads Tool - Universal Drag & Drop Cockpit</title>
  <style>
    :root {
      --bg: #0d1117;
      --card-bg: #161b22;
      --border: #30363d;
      --text: #c9d1d9;
      --accent: #58a6ff;
      --accent-hover: #1f6feb;
      --success: #238636;
      --warning: #d29922;
      --danger: #da3633;
      --drop-active: rgba(88, 166, 255, 0.15);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    body { background-color: var(--bg); color: var(--text); padding: 24px; min-height: 100vh; display: flex; flex-direction: column; gap: 20px; }
    header { display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid var(--border); padding-bottom: 16px; }
    h1 { font-size: 1.5rem; color: #fff; display: flex; align-items: center; gap: 10px; }
    .badge { font-size: 0.75rem; background: var(--border); padding: 4px 8px; border-radius: 12px; color: var(--accent); }
    .drop-hero { border: 2px dashed var(--border); border-radius: 12px; padding: 36px 20px; text-align: center; background: var(--card-bg); cursor: pointer; transition: all 0.2s ease; position: relative; }
    .drop-hero.drag-over { border-color: var(--accent); background: var(--drop-active); transform: scale(1.01); }
    .drop-hero h2 { font-size: 1.2rem; color: #fff; margin-bottom: 8px; }
    .drop-hero p { font-size: 0.9rem; color: #8b949e; }
    .drop-hero input[type="file"] { position: absolute; top: 0; left: 0; width: 100%; height: 100%; opacity: 0; cursor: pointer; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 16px; }
    .card { background: var(--card-bg); border: 1px solid var(--border); border-radius: 8px; padding: 16px; display: flex; flex-direction: column; gap: 10px; transition: border-color 0.2s ease; }
    .card-header { display: flex; justify-content: space-between; align-items: center; }
    .card-title { font-weight: 600; color: #fff; font-size: 0.95rem; }
    .card-desc { font-size: 0.8rem; color: #8b949e; font-family: monospace; word-break: break-all; }
    .tag { font-size: 0.7rem; padding: 2px 6px; border-radius: 4px; font-weight: 500; }
    .tag-file { background: #23863633; color: #3fb950; border: 1px solid #238636; }
    .tag-repo { background: #1f6feb33; color: #58a6ff; border: 1px solid #1f6feb; }
    .tag-web { background: #a371f733; color: #bc8cff; border: 1px solid #a371f7; }
    .tag-3d { background: #d2992233; color: #e3b341; border: 1px solid #d29922; }
    .tray { background: var(--card-bg); border: 1px solid var(--border); border-radius: 8px; padding: 14px; display: none; }
    .tray.active { display: block; }
    .tray-header { display: flex; justify-content: space-between; align-items: center; }
    .file-details { font-family: monospace; font-size: 0.85rem; color: var(--accent); }
    .btn { background: var(--accent); color: #fff; border: none; border-radius: 6px; padding: 7px 12px; font-size: 0.85rem; font-weight: 500; cursor: pointer; }
    .btn:hover { background: var(--accent-hover); }
    .btn-secondary { background: #21262d; border: 1px solid var(--border); color: #c9d1d9; }
    .console-box { background: #000; border: 1px solid var(--border); border-radius: 8px; padding: 12px; font-family: monospace; font-size: 0.85rem; color: #3fb950; min-height: 100px; max-height: 200px; overflow-y: auto; white-space: pre-wrap; }
  </style>
</head>
<body>
  <header>
    <h1>🛠️ All Lads Tool <span class="badge">$totalCount Tools Auto-Synced</span></h1>
    <div style="font-size: 0.8rem; color: #8b949e;">Generated: $generatedTimestamp (Zero-Localhost)</div>
  </header>

  <div class="drop-hero" id="heroDrop">
    <input type="file" id="fileInput" multiple>
    <h2>📥 Drag & Drop Any File / Folder Here</h2>
    <p>Drop a file to auto-highlight matching tools and generate dispatch commands.</p>
  </div>

  <div class="tray" id="fileTray">
    <div class="tray-header">
      <div><strong>🎯 Staged Target:</strong> <span class="file-details" id="stagedFileName">None</span> <span id="stagedFileType" style="margin-left: 8px; font-size: 0.8rem; color: #8b949e;"></span></div>
      <button class="btn btn-secondary" onclick="clearStagedFile()">Clear</button>
    </div>
    <div style="font-size: 0.85rem; color: #8b949e; margin-top: 6px;" id="stagedRecommendation">Drop any file to see matching tools highlighted.</div>
  </div>

  <div class="grid" id="toolsGrid">
$cardsHtml
  </div>

  <div>
    <h3 style="font-size: 0.85rem; margin-bottom: 6px; color: #8b949e;">💻 CLI Dispatcher Command</h3>
    <div class="console-box" id="consoleOutput">> Ready. HTML generated from live script directory.</div>
  </div>

  <script>
    let activeFile = null;
    const heroDrop = document.getElementById('heroDrop');
    const fileInput = document.getElementById('fileInput');
    const fileTray = document.getElementById('fileTray');
    const stagedFileName = document.getElementById('stagedFileName');
    const stagedFileType = document.getElementById('stagedFileType');
    const stagedRecommendation = document.getElementById('stagedRecommendation');
    const consoleOutput = document.getElementById('consoleOutput');

    ['dragenter', 'dragover'].forEach(name => {
      heroDrop.addEventListener(name, (e) => { e.preventDefault(); heroDrop.classList.add('drag-over'); }, false);
    });
    ['dragleave', 'drop'].forEach(name => {
      heroDrop.addEventListener(name, (e) => { e.preventDefault(); heroDrop.classList.remove('drag-over'); }, false);
    });

    heroDrop.addEventListener('drop', (e) => {
      const files = e.dataTransfer.files;
      if (files.length > 0) handleFiles(files);
    });

    fileInput.addEventListener('change', (e) => {
      if (e.target.files.length > 0) handleFiles(e.target.files);
    });

    function handleFiles(files) {
      activeFile = files[0];
      fileTray.classList.add('active');
      stagedFileName.textContent = activeFile.name;
      stagedFileType.textContent = '(' + (activeFile.size / 1024).toFixed(1) + ' KB)';
      logConsole('[DROP DETECTED] ' + activeFile.name);

      document.querySelectorAll('.card').forEach(c => c.style.borderColor = 'var(--border)');
      const ext = activeFile.name.split('.').pop().toLowerCase();
      let matches = 0;

      document.querySelectorAll('.card').forEach(card => {
        const cardExt = card.getAttribute('data-ext');
        const cardFile = (card.getAttribute('data-file') || '').toLowerCase();
        if ((ext === 'csv' && cardFile.includes('csv')) ||
            (ext === 'ps1' && cardFile.includes('dry-run')) ||
            (ext === 'scss' && cardFile.includes('scss')) ||
            (ext === 'js' && cardExt === 'js') ||
            (ext === 'py' && cardExt === 'py')) {
          card.style.borderColor = 'var(--accent)';
          matches++;
        }
      });
      stagedRecommendation.innerHTML = '<span style="color: var(--accent);">⚡ ' + matches + ' matching tool(s) highlighted.</span>';
    }

    function clearStagedFile() {
      activeFile = null;
      fileTray.classList.remove('active');
      document.querySelectorAll('.card').forEach(c => c.style.borderColor = 'var(--border)');
      logConsole('[RESET] Staged file cleared.');
    }

    function logConsole(msg) {
      consoleOutput.textContent += '\n' + msg;
      consoleOutput.scrollTop = consoleOutput.scrollHeight;
    }

    function executeTool(fileName) {
      const targetParam = activeFile ? ' -Target \"' + activeFile.name + '\"' : '';
      const cmd = '.\\_run.ps1 -Tool \"' + fileName + '\"' + targetParam;
      logConsole('[CLI READY]: ' + cmd);
    }
  </script>
</body>
</html>
"@

    [System.IO.File]::WriteAllText($htmlPath, $fullHtml, [System.Text.Encoding]::UTF8)
}

function Save-AppState {
    if (-not $resolvedRunJson) { return }
    try {
        $data = [PSCustomObject]@{
            mainMenuPath   = $MyInvocation.MyCommand.Path
            activeSlug     = $appState.activeSlug
            allowedDomains = $appState.allowedDomains
            history        = $appState.history | Select-Object -First 30
        }
        $json = $data | ConvertTo-Json -Depth 5
        [System.IO.File]::WriteAllText($resolvedRunJson, $json, [System.Text.Encoding]::UTF8)
    } catch { }
}

function Add-ActionHistory ([string]$key, [string]$name) {
    $entry = [PSCustomObject]@{
        key       = $key
        name      = $name
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    }
    $appState.history.Insert(0, $entry)
    Save-AppState
}

function Invoke-VersionReset ([string]$query) {
    if ([string]::IsNullOrWhiteSpace($query)) {
        Write-Host "`nAvailable Milestones in Commit History:" -ForegroundColor Green
        git -C $scriptDir log --oneline -n 10
        $query = Read-Host "`nEnter version (e.g. 01-01, 01-00) or commit hash/message"
    }

    if ([string]::IsNullOrWhiteSpace($query)) { return }

    $cleanQuery = $query.Trim()
    $hash = git -C $scriptDir log --grep="$cleanQuery" -n 1 --format="%H" 2>$null
    if (-not $hash) {
        $hash = git -C $scriptDir rev-parse --verify "$cleanQuery^{commit}" 2>$null
    }

    if ($hash) {
        $subject = git -C $scriptDir log -n 1 --format="%s (%h)" $hash
        Write-Host "[*] Found: $subject" -ForegroundColor Cyan
        Write-Host "Resetting / checking out all-lads-tool to commit $hash..." -ForegroundColor Yellow
        git -C $scriptDir checkout $hash
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Successfully switched all-lads-tool to version $cleanQuery!" -ForegroundColor Green
        }
    } else {
        Write-Host "[ERROR] Version or commit matching '$cleanQuery' not found." -ForegroundColor Red
    }
}

function Invoke-UpstreamCheck {
    Write-Host "`n[*] Fetching remote references from origin/main..." -ForegroundColor Cyan
    git -C $scriptDir fetch origin main 2>$null
    $pendingCommits = git -C $scriptDir log HEAD..origin/main --oneline 2>$null

    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   UPSTREAM UPDATE STATUS  ::  all-lads-tool                           " -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan

    if ([string]::IsNullOrWhiteSpace($pendingCommits)) {
        Write-Host " Status: UP TO DATE (Tidak ada update baru di remote origin/main)." -ForegroundColor Green
    } else {
        Write-Host " Status: UPDATE TERSEDIA! Commit baru di upstream:" -ForegroundColor Yellow
        foreach ($line in ($pendingCommits -split "`r?`n")) {
            Write-Host "  -> $line" -ForegroundColor Cyan
        }
        Write-Host "`nUntuk mengambil update ini ke project aktif, jalankan:" -ForegroundColor DarkGray
        Write-Host "  git submodule update --remote --merge all-lads-tool" -ForegroundColor White
    }
    Write-Host "========================================================================`n" -ForegroundColor Cyan
}

function Execute-ActionByKey ([string]$actionKey) {
    switch ($actionKey) {
        # 1. BASH
        "1" {
            Add-ActionHistory "1" "Battery Telemetry (bash)"
            $runner = Join-Path $scriptDir "script\bash\check-battery_stand.sh"
            if (Test-Path $runner) {
                $bashExe = Get-Command "bash.exe" -ErrorAction SilentlyContinue
                if ($bashExe) { & bash $runner } else { Write-Host "Bash runtime not found in PATH." -ForegroundColor Yellow }
            }
        }
        # 2. BAT
        "2" {
            Add-ActionHistory "2" "Start Chrome CWP (bat)"
            $runner = Join-Path $scriptDir "script\bat\start-chrome-cwp_stand.bat"
            if (Test-Path $runner) { & cmd.exe /c $runner }
        }
        # 3. GITBASH
        "3" {
            Add-ActionHistory "3" "Git Manager (gitbash)"
            $runner = Join-Path $scriptDir "script\gitbash\git-manage_stand.sh"
            if (Test-Path $runner) {
                $bashExe = Get-Command "bash.exe" -ErrorAction SilentlyContinue
                if ($bashExe) { & bash $runner $currentTarget } else { Write-Host "Git Bash runtime not found in PATH." -ForegroundColor Yellow }
            }
        }
        # 4. JAVASCRIPT
        "4" {
            Add-ActionHistory "4" "Codebase Auditor (js)"
            $runner = Join-Path $scriptDir "script\javascript\audit-codebase_stand.js"
            if (Test-Path $runner) { node $runner $currentTarget }
        }
        # 5. POWERSHELL
        "5" {
            Add-ActionHistory "5" "Git Manager (ps1)"
            $runner = Join-Path $scriptDir "script\powershell\git-manage_stand.ps1"
            if (Test-Path $runner) { & $runner -TargetDir $currentTarget }
        }
        "6" {
            Add-ActionHistory "6" "Submodule Hub (ps1)"
            $runner = Join-Path $scriptDir "script\powershell\git-submodule_stand.ps1"
            if (Test-Path $runner) { & $runner -Action "interactive" -Path $currentTarget }
        }
        "7" {
            Add-ActionHistory "7" "Diff Commits (ps1)"
            $runner = Join-Path $scriptDir "script\powershell\git-diff-commits_stand.ps1"
            if (Test-Path $runner) { & $runner }
        }
        "8" {
            Add-ActionHistory "8" "Web Dev Server (ps1)"
            $runner = Join-Path $scriptDir "script\powershell\start_stand.ps1"
            if (Test-Path $runner) { & $runner }
        }
        "9" {
            Add-ActionHistory "9" "Standalone Compilers (ps1)"
            $runner = Join-Path $scriptDir "script\powershell\standalone-compiler_stand.ps1"
            if (Test-Path $runner) { & $runner -All }
        }
        "10" {
            Add-ActionHistory "10" "Emoji Stripper (ps1)"
            $runner = Join-Path $scriptDir "script\powershell\remove-emoji.ps1"
            if (Test-Path $runner) { & $runner -TargetDir $currentTarget }
        }
        "11" {
            Add-ActionHistory "11" "Commit Renamer (ps1)"
            $runner = Join-Path $scriptDir "script\powershell\git-rename-commit_stand.ps1"
            if (Test-Path $runner) { & $runner -TargetDir $currentTarget }
        }
        # 6. PYTHON
        "12" {
            Add-ActionHistory "12" "Server Utility (py)"
            $runner = Join-Path $scriptDir "script\python\server_stand.py"
            if (Test-Path $runner) {
                $pyExe = Get-Command "python.exe" -ErrorAction SilentlyContinue
                if ($pyExe) { & python $runner } else { Write-Host "Python runtime not found in PATH." -ForegroundColor Yellow }
            }
        }
        default {
            Write-Host "Action key '$actionKey' is not recognized." -ForegroundColor Yellow
        }
    }
}

# Direct parameter invocation
if ($CheckUpstream) {
    Invoke-UpstreamCheck
    exit 0
}

if (-not [string]::IsNullOrWhiteSpace($ResetVersion)) {
    Invoke-VersionReset $ResetVersion
    exit 0
}

# Auto-generate & update _mainmenu.html based on live scripts directory (Rule #007)
Update-MainMenuHtml

$Host.UI.RawUI.WindowTitle = "All Lads Tool :: Master Cockpit"

while ($true) {
    $latestAction = if ($appState.history.Count -gt 0) { $appState.history[0] } else { $null }
    $latestDisplay = if ($latestAction) { "[$($latestAction.key)] $($latestAction.name)" } else { "Belum ada (Pilih opsi terlebih dahulu)" }

    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   [ALL LADS TOOL]  ::  DEVELOPER COCKPIT & DISPATCHER                 " -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " Toolchain Root : $scriptDir" -ForegroundColor DarkGray
    Write-Host " Launched By    : $launcherInfo" -ForegroundColor Magenta
    Write-Host " Active Target  : $currentTarget" -ForegroundColor White
    Write-Host " Active Slug    : $($appState.activeSlug)" -ForegroundColor Cyan
    Write-Host " Run Config     : $(if ($resolvedRunJson) { $resolvedRunJson } else { 'None (Direct Mode)' })" -ForegroundColor DarkGray
    Write-Host " Latest Action  : $latestDisplay" -ForegroundColor Green
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""

    # 1. BASH (🔴 RED)
    Write-Host " --- 1. BASH (script/bash/) --------------------------------------------" -ForegroundColor Red
    Write-Host "  [ 1 ]  Battery Telemetry  : Check Battery & Hardware Telemetry (sh)" -ForegroundColor Red
    Write-Host ""

    # 2. BAT (🟠 DARKYELLOW / ORANGE)
    Write-Host " --- 2. BAT (script/bat/) ----------------------------------------------" -ForegroundColor DarkYellow
    Write-Host "  [ 2 ]  Start Chrome CWP   : Launch Clean Web Project in Chrome (bat)" -ForegroundColor DarkYellow
    Write-Host ""

    # 3. GITBASH (🟡 YELLOW / GOLD)
    Write-Host " --- 3. GITBASH (script/gitbash/) --------------------------------------" -ForegroundColor Yellow
    Write-Host "  [ 3 ]  Git Manager (Bash) : Universal Git Manager in Git Bash (sh)" -ForegroundColor Yellow
    Write-Host ""

    # 4. JAVASCRIPT (🟢 GREEN)
    Write-Host " --- 4. JAVASCRIPT (script/javascript/) --------------------------------" -ForegroundColor Green
    Write-Host "  [ 4 ]  Codebase Auditor   : Rule #001 - #006 Compliance Auditor (js)" -ForegroundColor Green
    Write-Host ""

    # 5. POWERSHELL (🩵 CYAN)
    Write-Host " --- 5. POWERSHELL (script/powershell/) --------------------------------" -ForegroundColor Cyan
    Write-Host "  [ 5 ]  Git Manager (PS)   : Universal Git Operations & Reflog (ps1)" -ForegroundColor Cyan
    Write-Host "  [ 6 ]  Submodule Hub      : Manage, Add, Update, or Remove Submodules" -ForegroundColor Cyan
    Write-Host "  [ 7 ]  Diff Commits       : Compare Commit Sizes & Compiled Builds" -ForegroundColor Cyan
    Write-Host "  [ 8 ]  Web Dev Server     : Start Multi-threaded Local HTTP Server" -ForegroundColor Cyan
    Write-Host "  [ 9 ]  Standalone Comp    : Compile Modular Scripts to *_stand.*" -ForegroundColor Cyan
    Write-Host "  [ 10]  Emoji Stripper     : Remove Emojis (Modular: Markdown / All formats)" -ForegroundColor Cyan
    Write-Host "  [ 11]  Commit Renamer     : Rename HEAD/Historic Commits & Push (GitHub/GitLab)" -ForegroundColor Cyan
    Write-Host ""

    # 6. PYTHON (🔵 BLUE)
    Write-Host " --- 6. PYTHON (script/python/) ----------------------------------------" -ForegroundColor Blue
    Write-Host "  [ 12]  Python Server      : Multi-threaded Python HTTP Server (py)" -ForegroundColor Blue
    Write-Host ""

    Write-Host " ----------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ 0 ]  Re-Run Latest      : Ulangi aksi terakhir ($latestDisplay)" -ForegroundColor Green

    # Default shows only last 3 history items (-1, -2, -3)
    $hPreview = @()
    for ($i = 0; $i -lt [Math]::Min(3, $appState.history.Count); $i++) {
        $idx = -($i + 1)
        $hItem = $appState.history[$i]
        $hPreview += "[$idx] $($hItem.name)"
    }
    $hPreviewStr = if ($hPreview.Count -gt 0) { $hPreview -join "  " } else { "Kosong" }
    Write-Host "  [-1 ]  Recent History     : $hPreviewStr" -ForegroundColor DarkCyan
    Write-Host "  [ h ]  History More       : Lihat riwayat lengkap (-1 s/d -$($appState.history.Count))" -ForegroundColor DarkCyan
    Write-Host "  [ g ]  Open Web GUI       : Buka Drag & Drop GUI Dashboard (_mainmenu.html)" -ForegroundColor Yellow
    Write-Host "  [ t ]  Switch Target Dir  : Ganti folder target project aktif" -ForegroundColor Gray
    Write-Host "  [ q ]  Quit               : Keluar dari dispatcher" -ForegroundColor Gray
    Write-Host "========================================================================" -ForegroundColor Cyan

    $choice = Read-Host "Select option [0-12, g, -1, -2, -3, h, t, q] [Default: 0]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "0" }
    $choice = $choice.Trim()

    # Handle negative history index: -1, -2, -3 ...
    if ($choice -match "^-(\d+)$") {
        $offset = [int]$Matches[1]
        $targetIndex = $offset - 1
        if ($targetIndex -ge 0 -and $targetIndex -lt $appState.history.Count) {
            $selectedItem = $appState.history[$targetIndex]
            Write-Host "`n[*] Menjalankan aksi dari riwayat [-$offset]: $($selectedItem.name)..." -ForegroundColor Cyan
            Execute-ActionByKey $selectedItem.key
            continue
        } else {
            Write-Host "Riwayat [-$offset] tidak ditemukan. Riwayat tersedia: 1 s/d $($appState.history.Count)." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            continue
        }
    }

    # Handle Re-Run Latest (0)
    if ($choice -eq "0") {
        if ($appState.history.Count -gt 0) {
            $latest = $appState.history[0]
            Write-Host "`n[*] Re-running aksi terakhir: [$($latest.key)] $($latest.name)..." -ForegroundColor Green
            Execute-ActionByKey $latest.key
            continue
        } else {
            Write-Host "Belum ada riwayat aksi sebelumnya. Silakan pilih opsi 1-11 terlebih dahulu." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            continue
        }
    }

    # Handle History Viewer (h)
    if ($choice -eq "h") {
        Write-Host ""
        Write-Host "========================================================================" -ForegroundColor Cyan
        Write-Host "   FULL EXECUTION HISTORY LOG                                          " -ForegroundColor Yellow
        Write-Host "========================================================================" -ForegroundColor Cyan
        if ($appState.history.Count -eq 0) {
            Write-Host " Riwayat masih kosong." -ForegroundColor DarkGray
        } else {
            for ($i = 0; $i -lt $appState.history.Count; $i++) {
                $negIdx = -($i + 1)
                $item = $appState.history[$i]
                Write-Host "  [$negIdx] $($item.timestamp)  -->  $($item.name) (Key: $($item.key))" -ForegroundColor Cyan
            }
        }
        Write-Host "------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " Ketik nomor indeks (misal: -1, -2), [c] Clear History, atau [b] Kembali" -ForegroundColor White
        Write-Host "========================================================================" -ForegroundColor Cyan
        $hChoice = Read-Host "Pilihan History [Default: b]"
        if ([string]::IsNullOrWhiteSpace($hChoice)) { $hChoice = "b" }
        $hChoice = $hChoice.Trim()

        if ($hChoice -eq "c") {
            $appState.history.Clear()
            Save-AppState
            Write-Host "[OK] Seluruh riwayat telah dibersihkan." -ForegroundColor Green
            Start-Sleep -Seconds 1
        } elseif ($hChoice -match "^-(\d+)$") {
            $offset = [int]$Matches[1]
            $targetIndex = $offset - 1
            if ($targetIndex -ge 0 -and $targetIndex -lt $appState.history.Count) {
                $selectedItem = $appState.history[$targetIndex]
                Write-Host "`n[*] Menjalankan riwayat [-$offset]: $($selectedItem.name)..." -ForegroundColor Cyan
                Execute-ActionByKey $selectedItem.key
            } else {
                Write-Host "Indeks tidak valid." -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
        }
        continue
    }

    # Standard menu choices
    switch ($choice) {
        { $_ -in "1","2","3","4","5","6","7","8","9","10","11","12" } {
            Execute-ActionByKey $choice
        }
        "g" {
            Update-MainMenuHtml
            $guiPath = Join-Path $scriptDir "_mainmenu.html"
            if (Test-Path $guiPath) {
                Write-Host "[*] Membuka Drag & Drop GUI Dashboard di browser (File URL / Offline)..." -ForegroundColor Green
                $safeUrl = "file:///" + $guiPath.Replace('\', '/')
                if ($IsWindows -or ($env:OS -like "*Windows*")) {
                    Start-Process $safeUrl
                } elseif ($IsMacOS) {
                    & open $safeUrl
                } elseif ($IsLinux) {
                    & xdg-open $safeUrl
                } else {
                    Start-Process $safeUrl
                }
            } else {
                Write-Host "File _mainmenu.html tidak ditemukan." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 1
        }
        "t" {
            $inPath = Read-Host "Masukkan path direktori target project baru"
            if ($inPath -and (Test-Path $inPath)) {
                $currentTarget = (Resolve-Path $inPath).Path
                Save-AppState
                Write-Host "[OK] Target berhasil diganti ke: $currentTarget" -ForegroundColor Green
            } else {
                Write-Host "Path tidak valid atau direktori tidak ditemukan." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 1
        }
        "q" {
            Write-Host "Sampai jumpa! (_mainmenu exited)" -ForegroundColor Cyan
            break
        }
        default {
            Write-Host "Opsi tidak valid: '$choice'." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
