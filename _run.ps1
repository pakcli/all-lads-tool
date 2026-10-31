# _run.ps1 - Portable Universal Launcher for all-lads-tool _mainmenu.ps1
# Can be placed anywhere on the drive. Caches chosen path, active slug, and history in _run.json.
# Loads environment configuration from _run.env if present.
# If multiple _mainmenu.ps1 files are found, presents an ASCII table view and prompts for selection.

param(
    [string]$TargetDir = "",
    [string]$Slug = "",
    [switch]$Rescan
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$configFile = Join-Path $scriptDir "_run.json"
$envFile = Join-Path $scriptDir "_run.env"

# 1. Parse _run.env if exists (supports multiline and numbered lists like 1.domain.com)
$envConfig = @{
    LOCAL_MACHINE_USER  = ""
    GITHUB_USERNAME     = ""
    GITHUB_EMAIL_PUBLIC = ""
    ACTIVE_SLUG         = ""
    ALLOWED_DOMAINS     = @()
}

if (Test-Path -LiteralPath $envFile) {
    $lines = Get-Content -LiteralPath $envFile -Encoding UTF8
    $inMultilineDomain = $false
    
    foreach ($rawLine in $lines) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#')) { continue }

        if ($line.StartsWith('ALLOWED_DOMAINS=')) {
            $val = $line.Substring('ALLOWED_DOMAINS='.Length).Trim()
            $inMultilineDomain = $true
            if ($val) {
                $clean = ($val -replace '^\d+\.\s*', '').TrimEnd(',')
                if ($clean) { $envConfig.ALLOWED_DOMAINS += $clean }
            }
            continue
        }

        if ($inMultilineDomain) {
            if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=') {
                $inMultilineDomain = $false
            } else {
                $item = ($line -replace '^\d+\.\s*', '').TrimEnd(',')
                if ($item) {
                    $envConfig.ALLOWED_DOMAINS += $item
                }
                continue
            }
        }

        if ($line -match '^([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $val = $matches[2].Trim()
            $envConfig[$key] = $val
        }
    }
}

# 2. Load _run.json cache if exists
$config = @{
    mainMenuPath = ""
    activeSlug   = if ($Slug) { $Slug } elseif ($envConfig.ACTIVE_SLUG) { $envConfig.ACTIVE_SLUG } else { "default" }
    history      = @()
}

if ((Test-Path -LiteralPath $configFile) -and (-not $Rescan)) {
    try {
        $raw = Get-Content -LiteralPath $configFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($raw) {
            $parsed = $raw | ConvertFrom-Json
            if ($parsed.mainMenuPath) { $config.mainMenuPath = $parsed.mainMenuPath }
            if ($parsed.activeSlug -and -not $Slug) { $config.activeSlug = $parsed.activeSlug }
            if ($parsed.history)      { $config.history      = @($parsed.history) }
        }
    } catch { }
}

if ($Slug) { $config.activeSlug = $Slug }

# 3. Check cached mainMenuPath or discover all candidates
$chosenPath = ""

if ($config.mainMenuPath -and (Test-Path -LiteralPath $config.mainMenuPath -PathType Leaf) -and (-not $Rescan)) {
    $chosenPath = $config.mainMenuPath
} else {
    Write-Host "[_run] Scanning for _mainmenu.ps1..." -ForegroundColor Yellow
    
    $driveRoot = (Get-Item $scriptDir).Root.FullName
    $allFound = @(Get-ChildItem -Path $driveRoot -Filter "_mainmenu.ps1" -Recurse -File -ErrorAction SilentlyContinue)

    if ($allFound.Count -eq 0) {
        Write-Error "[_run] ERROR: No _mainmenu.ps1 found on drive $driveRoot."
        exit 1
    }
    elseif ($allFound.Count -eq 1) {
        $chosenPath = $allFound[0].FullName
    }
    else {
        # Multiple mainmenu files found -> Show ASCII Table View
        Write-Host ""
        Write-Host "==========================================================================================" -ForegroundColor Cyan
        Write-Host " [ALERT] MULTIPLE _mainmenu.ps1 DETECTED ON DRIVE ($($allFound.Count) found)" -ForegroundColor Yellow
        Write-Host " Please select which mainmenu you want to execute and set as default." -ForegroundColor Cyan
        Write-Host "==========================================================================================" -ForegroundColor Cyan
        Write-Host ""

        $tableData = @()
        $idx = 1
        foreach ($item in $allFound) {
            $folder = $item.DirectoryName
            $latestInFolder = Get-ChildItem -Path $folder -File -ErrorAction SilentlyContinue | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 1

            $latestInfo = if ($latestInFolder) {
                "$($latestInFolder.Name) ($($latestInFolder.LastWriteTime.ToString('yyyy-MM-dd HH:mm')))"
            } else {
                "None"
            }

            $tableData += [PSCustomObject]@{
                "#"                  = "[$idx]"
                "MainMenu Path"      = $item.FullName
                "DateModified Time"  = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                "Latest File Update" = $latestInfo
            }
            $idx++
        }

        $tableData | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor White

        $selectedIdx = -1
        while ($selectedIdx -lt 1 -or $selectedIdx -gt $allFound.Count) {
            $inputVal = Read-Host "Select Main Menu [1-$($allFound.Count)] (Default: 1)"
            if ([string]::IsNullOrWhiteSpace($inputVal)) {
                $selectedIdx = 1
                break
            }
            if ($inputVal -match '^\d+$') {
                $selectedIdx = [int]$inputVal
            }
        }

        $chosenPath = $allFound[$selectedIdx - 1].FullName
        Write-Host "[_run] Selected: $chosenPath" -ForegroundColor Green
    }
}

# 4. Update history stack (0 = latest, 1 = previous latest, 2 = older, etc.)
$timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$currentOption = [PSCustomObject]@{
    timestamp = $timestamp
    slug      = $config.activeSlug
    targetDir = $TargetDir
}

$newHistory = [System.Collections.ArrayList]@()
[void]$newHistory.Add($currentOption)

if ($config.history) {
    foreach ($entry in $config.history) {
        if ($newHistory.Count -ge 30) { break }
        $newHistory.Add($entry) | Out-Null
    }
}

# 5. Save to _run.json (Cache chosen path, active slug, public github email, allowed domains, and history)
$savePayload = [PSCustomObject]@{
    mainMenuPath      = $chosenPath
    activeSlug        = $config.activeSlug
    githubUsername    = $envConfig.GITHUB_USERNAME
    githubEmailPublic = $envConfig.GITHUB_EMAIL_PUBLIC
    allowedDomains    = $envConfig.ALLOWED_DOMAINS
    history           = $newHistory
}

$savePayload | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $configFile -Encoding UTF8
Write-Host "[_run] Active _mainmenu.ps1 : $chosenPath" -ForegroundColor DarkCyan
Write-Host "[_run] Active Slug          : $($config.activeSlug)" -ForegroundColor DarkCyan
if ($envConfig.GITHUB_USERNAME) {
    Write-Host "[_run] GitHub Public Identity: $($envConfig.GITHUB_USERNAME) <$($envConfig.GITHUB_EMAIL_PUBLIC)>" -ForegroundColor DarkGray
}
if ($envConfig.ALLOWED_DOMAINS.Count -gt 0) {
    Write-Host "[_run] Allowed Domains ($($envConfig.ALLOWED_DOMAINS.Count))   : $($envConfig.ALLOWED_DOMAINS -join ', ')" -ForegroundColor DarkGray
}

# 6. Execute chosen _mainmenu.ps1 via _run.ps1 perantara
$env:ALL_LADS_LAUNCHER = "_run.ps1 ($scriptDir)"
if ($TargetDir) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $chosenPath -TargetDir $TargetDir -LaunchedBy "_run.ps1" -RunJsonPath $configFile
} else {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $chosenPath -LaunchedBy "_run.ps1" -RunJsonPath $configFile
}
