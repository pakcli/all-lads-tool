<#
.SYNOPSIS
    All Lads Tool - Master Dispatcher & Main Menu
.DESCRIPTION
    Zero-hardcoded central launcher for all toolchain scripts in all-lads-tool.
    Organized strictly by context according to Canonical v01-03 standard:
    repo, file, blender, unity, website.
    Features state persistence in _run.json, interactive target switching [t],
    negative history stack indexing (-1, -2, -3), and deep history viewer (h).
.PARAMETER TargetDir
    Target project directory (default: parent workspace or saved target in _run.json).
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
$scriptPath = if ($PSCommandPath) { $PSCommandPath } elseif ($MyInvocation.MyCommand.Path) { $MyInvocation.MyCommand.Path } else { Join-Path $scriptDir "_mainmenu.ps1" }

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
            if ($parsed.targetDir -and (Test-Path -LiteralPath $parsed.targetDir)) { $appState.lastTarget = $parsed.targetDir }
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
                ($_.Extension -in ".ps1", ".js", ".py", ".sh", ".bat", ".cs" -and $_.Directory.Name -ne "module" -and $_.Directory.Name -ne "modules" -and $_.Directory.Name -ne "adapter")
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
      --tag-repo: #bc8cff;
      --tag-file: #7ee787;
      --tag-web: #ffa657;
      --tag-3d: #ff7b72;
    }
    body {
      margin: 0;
      padding: 24px;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }
    .header {
      margin-bottom: 24px;
      border-bottom: 1px solid var(--border);
      padding-bottom: 16px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
      gap: 16px;
    }
    .card {
      background: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 16px;
    }
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 8px;
    }
    .card-title {
      font-weight: 600;
      font-size: 1.1em;
    }
    .tag {
      font-size: 0.75em;
      padding: 2px 8px;
      border-radius: 12px;
      font-weight: 600;
      text-transform: uppercase;
    }
    .tag-repo { background: rgba(188, 140, 255, 0.15); color: var(--tag-repo); }
    .tag-file { background: rgba(126, 231, 135, 0.15); color: var(--tag-file); }
    .tag-web  { background: rgba(255, 166, 87, 0.15); color: var(--tag-web); }
    .tag-3d   { background: rgba(255, 123, 114, 0.15); color: var(--tag-3d); }
    .card-desc {
      font-size: 0.85em;
      color: #8b949e;
      margin-bottom: 16px;
      word-break: break-all;
    }
    .btn {
      width: 100%;
      background: #21262d;
      color: var(--text);
      border: 1px solid var(--border);
      padding: 8px 16px;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 500;
    }
    .btn:hover {
      background: #30363d;
      border-color: #8b949e;
    }
  </style>
</head>
<body>
  <div class="header">
    <h1>All Lads Tool :: Interactive Cockpit</h1>
    <p>Auto-generated on $generatedTimestamp | Active Tools: $totalCount</p>
  </div>
  <div class="grid">
$cardsHtml
  </div>
  <script>
    function executeTool(fileName) {
      alert("Selected tool: " + fileName + "\\nRun via PowerShell CLI (_mainmenu.ps1) for execution.");
    }
  </script>
</body>
</html>
"@

    try {
        [System.IO.File]::WriteAllText($htmlPath, $fullHtml, [System.Text.Encoding]::UTF8)
    } catch { }
}

function Save-AppState {
    if (-not $resolvedRunJson) { return }
    try {
        $appState.lastTarget = $currentTarget
        $data = [PSCustomObject]@{
            mainMenuPath   = $scriptPath
            activeSlug     = $appState.activeSlug
            targetDir      = $currentTarget
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
        # 1. REPO
        "1" {
            Add-ActionHistory "1" "Git Manager (ps1)"
            $runner = Join-Path $scriptDir "script\repo\git-manage.ps1"
            if (Test-Path $runner) {
                & $runner -TargetDir $currentTarget
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }
        "2" {
            Add-ActionHistory "2" "Git Branch Rename (ps1)"
            $runner = Join-Path $scriptDir "script\repo\git-branch-rename.ps1"
            if (Test-Path $runner) {
                & $runner -TargetDir $currentTarget
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }

        # 2. FILE
        "3" {
            Add-ActionHistory "3" "Batch Target Rename (ps1)"
            $runner = Join-Path $scriptDir "script\file\batch-target-dir-rename.ps1"
            if (Test-Path $runner) {
                & $runner -TargetDir $currentTarget
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }
        "4" {
            Add-ActionHistory "4" "CSV to Frontmatter (ps1)"
            $runner = Join-Path $scriptDir "script\file\csv-to-frontmatter.ps1"
            if (Test-Path $runner) {
                & $runner -TargetDir $currentTarget
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }
        "5" {
            Add-ActionHistory "5" "Dry-Run Simulator (ps1)"
            $runner = Join-Path $scriptDir "script\file\dry-run.ps1"
            if (Test-Path $runner) {
                & $runner
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }
        "6" {
            Add-ActionHistory "6" "File Merge into One (ps1)"
            $runner = Join-Path $scriptDir "script\file\file-merge-into-one.ps1"
            if (Test-Path $runner) {
                & $runner -SourceDir $currentTarget
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }
        "7" {
            Add-ActionHistory "7" "File One to Multi (ps1)"
            $runner = Join-Path $scriptDir "script\file\file-one-to-multiple-files.ps1"
            if (Test-Path $runner) {
                & $runner -OutputDir $currentTarget
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }

        # 3. BLENDER
        "8" {
            Add-ActionHistory "8" "Blender FBX Export (py)"
            $runner = Join-Path $scriptDir "script\blender\fbx-export.py"
            if (Test-Path $runner) {
                $pyExe = Get-Command "python.exe" -ErrorAction SilentlyContinue
                if ($pyExe) { & python $runner } else { Write-Host "Python runtime not found in PATH." -ForegroundColor Yellow }
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }

        # 4. UNITY
        "9" {
            Add-ActionHistory "9" "Unity Asset Import (cs)"
            $runner = Join-Path $scriptDir "script\unity\asset-importer.cs"
            if (Test-Path $runner) {
                Write-Host "[*] Unity asset importer script located at: $runner" -ForegroundColor Cyan
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
            }
        }

        # 5. WEBSITE
        "10" {
            Add-ActionHistory "10" "Build Bundles (js)"
            $runner = Join-Path $scriptDir "script\website\build-bundles.js"
            if (Test-Path $runner) {
                $nodeExe = Get-Command "node.exe" -ErrorAction SilentlyContinue
                if ($nodeExe) { & node $runner $currentTarget } else { Write-Host "Node.js runtime not found in PATH." -ForegroundColor Yellow }
            } else {
                Write-Host "[ERROR] Script not found: $runner" -ForegroundColor Red
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

    # 1. REPO (script/repo/) (🟣 MAGENTA / CYAN)
    Write-Host " --- 1. REPO (script/repo/) --------------------------------------------" -ForegroundColor Cyan
    Write-Host "  [ 1 ]  Git Manager        : Universal Git Operations & Status (ps1)" -ForegroundColor Cyan
    Write-Host "  [ 2 ]  Git Branch Rename  : Rename local & upstream branch (ps1)" -ForegroundColor Cyan
    Write-Host ""

    # 2. FILE (script/file/) (🟢 GREEN)
    Write-Host " --- 2. FILE (script/file/) --------------------------------------------" -ForegroundColor Green
    Write-Host "  [ 3 ]  Batch Target Rename: Rename MD files by frontmatter title (ps1)" -ForegroundColor Green
    Write-Host "  [ 4 ]  CSV to Frontmatter : Convert tabular CSV rows to MD files (ps1)" -ForegroundColor Green
    Write-Host "  [ 5 ]  Dry-Run Simulator  : Non-destructive script dry-run runner (ps1)" -ForegroundColor Green
    Write-Host "  [ 6 ]  File Merge into One: Consolidate multiple MD files into one (ps1)" -ForegroundColor Green
    Write-Host "  [ 7 ]  File One to Multi  : Split monolith MD file into modules (ps1)" -ForegroundColor Green
    Write-Host ""

    # 3. BLENDER (script/blender/) (🟠 ORANGE / YELLOW)
    Write-Host " --- 3. BLENDER (script/blender/) ---------------------------------------" -ForegroundColor Yellow
    Write-Host "  [ 8 ]  Blender FBX Export : Universal FBX exporter via LTS adapter (py)" -ForegroundColor Yellow
    Write-Host ""

    # 4. UNITY (script/unity/) (🔵 BLUE)
    Write-Host " --- 4. UNITY (script/unity/) -------------------------------------------" -ForegroundColor Blue
    Write-Host "  [ 9 ]  Unity Asset Import : Universal Asset Importer via adapter (cs)" -ForegroundColor Blue
    Write-Host ""

    # 5. WEBSITE (script/website/) (🟣 MAGENTA)
    Write-Host " --- 5. WEBSITE (script/website/) ---------------------------------------" -ForegroundColor Magenta
    Write-Host "  [ 10]  Build Bundles      : Client modular bundle compiler (js)" -ForegroundColor Magenta
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
    Write-Host "  [ t ]  Switch Target Dir  : Ganti folder target project aktif (Retargeting)" -ForegroundColor White
    Write-Host "  [ q ]  Quit               : Keluar dari dispatcher" -ForegroundColor Gray
    Write-Host "========================================================================" -ForegroundColor Cyan

    $choice = Read-Host "Select option [0-10, g, -1, -2, -3, h, t, q] [Default: 0]"
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
            Write-Host "Belum ada riwayat aksi sebelumnya. Silakan pilih opsi 1-10 terlebih dahulu." -ForegroundColor Yellow
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
        { $_ -in "1","2","3","4","5","6","7","8","9","10" } {
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
            Write-Host ""
            Write-Host "========================================================================" -ForegroundColor Cyan
            Write-Host "   SWITCH TARGET DIRECTORY (RETARGETING)                                " -ForegroundColor Yellow
            Write-Host "========================================================================" -ForegroundColor Cyan
            Write-Host " Active Target: $currentTarget" -ForegroundColor White

            $detectedDirs = @()
            $searchRoots = @($parentDir, $currentTarget) | Select-Object -Unique
            foreach ($sr in $searchRoots) {
                if (Test-Path $sr) {
                    $found = Get-ChildItem -Path $sr -Directory -ErrorAction SilentlyContinue |
                        Where-Object { 
                            (Test-Path (Join-Path $_.FullName ".git")) -or 
                            $_.Name -like "web-app*" -or 
                            $_.Name -like "obsidian-*" -or 
                            $_.Name -like "vault_*" -or 
                            $_.Name -like "quartz*" 
                        }
                    if ($found) { $detectedDirs += $found }
                }
            }
            $detectedDirs = $detectedDirs | Sort-Object FullName -Unique

            if ($detectedDirs.Count -gt 0) {
                Write-Host "`n Detected Projects / Repositories in Workspace:" -ForegroundColor DarkCyan
                for ($i = 0; $i -lt $detectedDirs.Count; $i++) {
                    $isGit = if (Test-Path (Join-Path $detectedDirs[$i].FullName ".git")) { "[GIT]" } else { "     " }
                    Write-Host "  [$($i + 1)] $isGit $($detectedDirs[$i].Name) ($($detectedDirs[$i].FullName))" -ForegroundColor White
                }
            }

            Write-Host "`n Enter number [1-$($detectedDirs.Count)], custom path, or drag & drop folder:" -ForegroundColor White
            $inPath = Read-Host " Target Dir"
            $inPath = if ($inPath) { $inPath.Trim().Trim('"').Trim("'") } else { "" }

            if ($inPath -match '^\d+$' -and [int]$inPath -ge 1 -and [int]$inPath -le $detectedDirs.Count) {
                $currentTarget = $detectedDirs[[int]$inPath - 1].FullName
                $appState.lastTarget = $currentTarget
                Save-AppState
                Write-Host "[OK] Target berhasil diganti ke: $currentTarget" -ForegroundColor Green
            } elseif ($inPath -and (Test-Path $inPath)) {
                $currentTarget = (Resolve-Path $inPath).Path
                $appState.lastTarget = $currentTarget
                Save-AppState
                Write-Host "[OK] Target berhasil diganti ke: $currentTarget" -ForegroundColor Green
            } elseif ([string]::IsNullOrWhiteSpace($inPath)) {
                Write-Host "Retargeting dibatalkan." -ForegroundColor DarkGray
            } else {
                Write-Host "Path tidak valid atau direktori tidak ditemukan: $inPath" -ForegroundColor Yellow
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
