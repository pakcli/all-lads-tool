<#
.SYNOPSIS
    Universal Emoji Stripper & Text Sanitizer (Modular Edition).
.DESCRIPTION
    Scans files in a directory and strips all Unicode emojis.
    Supports interactive mode (prompts for directory, markdown only vs all file formats)
    as well as CLI headless execution.
    Modular edition connected directly to module/emojistripper.psm1 (NOT standalone).
.PARAMETER TargetDir
    Target directory to scan (default: current directory).
.PARAMETER Filter
    File pattern to match (default: "*.md").
.PARAMETER AllExtensions
    When specified, scans all common text formats (*.md, *.txt, *.js, *.ts, *.ps1, *.json, *.html, *.css, *.sh, *.bat, *.yaml, *.yml).
.PARAMETER AllFiles
    When specified, scans all files (*.*).
.PARAMETER DryRun
    Previews changes and counts emojis without writing modifications to disk.
.PARAMETER NormalizeSpaces
    Collapses multiple horizontal spaces left by removed emojis into a single space.
.PARAMETER Interactive
    Forces interactive prompt wizard.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$Filter = "",

    [switch]$AllExtensions,
    [switch]$AllFiles,
    [switch]$DryRun,
    [switch]$NormalizeSpaces,
    [switch]$Interactive
)

$scriptDir = $PSScriptRoot
$modulePath = Join-Path $scriptDir "module\emojistripper.psm1"

if (-not (Test-Path -LiteralPath $modulePath)) {
    Write-Error "Required module not found: $modulePath"
    exit 1
}

Import-Module -Name $modulePath -Force

# Determine if we should run interactively
$isCli = $PSBoundParameters.ContainsKey("TargetDir") -or 
         $PSBoundParameters.ContainsKey("Filter") -or 
         $AllExtensions -or 
         $AllFiles -or 
         $DryRun -or 
         $NormalizeSpaces

if (-not $isCli -or $Interactive) {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   UNIVERSAL EMOJI STRIPPER  ::  MODULAR POWERSHELL                     " -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " Engine  : module\emojistripper.psm1 (Modular - Non-standalone)" -ForegroundColor DarkGray
    Write-Host " Status  : Interactive Wizard" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""

    # 1. Target Directory Prompt
    $defaultTarget = if ($TargetDir) { $TargetDir } else { (Get-Location).Path }
    Write-Host " [1] Target Directory to Scan:" -ForegroundColor White
    Write-Host "     Default : $defaultTarget" -ForegroundColor DarkGray
    $inputDir = Read-Host "     Enter path (or press [Enter] to use default)"
    if (-not [string]::IsNullOrWhiteSpace($inputDir)) {
        $TargetDir = $inputDir.Trim('"', "'", " ")
    } else {
        $TargetDir = $defaultTarget
    }

    # 2. Scope / File format prompt: "markdown aja, all file format?"
    Write-Host ""
    Write-Host " [2] File Format Scope:" -ForegroundColor White
    Write-Host "     [ 1 ] Markdown Saja (*.md)                   [Default]" -ForegroundColor Green
    Write-Host "     [ 2 ] Semua Format Teks (md, txt, json, ts, js, html, css, ps1, yaml)" -ForegroundColor Yellow
    Write-Host "     [ 3 ] Semua File (*.*)" -ForegroundColor Magenta
    Write-Host "     [ 4 ] Custom Extension Filter (misal: *.csv, *.mdx)" -ForegroundColor Cyan
    $scopeChoice = Read-Host "     Pilih opsi [1/2/3/4] [Default: 1]"
    $scopeChoice = $scopeChoice.Trim()

    switch ($scopeChoice) {
        "2" {
            $AllExtensions = $true
            $Filter = ""
        }
        "3" {
            $AllFiles = $true
            $Filter = "*.*"
        }
        "4" {
            $customFilter = Read-Host "     Ketik pola filter (contoh: *.yaml atau *.txt)"
            $Filter = if ([string]::IsNullOrWhiteSpace($customFilter)) { "*.md" } else { $customFilter.Trim() }
        }
        default {
            $Filter = "*.md"
        }
    }

    # 3. Execution Mode prompt (Apply vs Dry-Run)
    Write-Host ""
    Write-Host " [3] Mode Eksekusi:" -ForegroundColor White
    Write-Host "     [ 1 ] Apply   : Langsung hapus emoji & simpan file [Default]" -ForegroundColor Green
    Write-Host "     [ 2 ] Dry-Run : Preview daftar file & hitung emoji tanpa ubah disk" -ForegroundColor Yellow
    $modeChoice = Read-Host "     Pilih mode [1/2] [Default: 1]"
    if ($modeChoice.Trim() -eq "2") {
        $DryRun = $true
    }

    # 4. Spacing normalization prompt
    Write-Host ""
    $normChoice = Read-Host " [4] Normalize spasi ganda sisa penghapusan emoji? [Y/N] [Default: Y]"
    if ($normChoice.Trim() -match "^[nN]") {
        $NormalizeSpaces = $false
    } else {
        $NormalizeSpaces = $true
    }
} else {
    # If Filter not specified in CLI, default to *.md unless AllExtensions or AllFiles
    if (-not $Filter -and -not $AllExtensions -and -not $AllFiles) {
        $Filter = "*.md"
    }
}

# Resolve target directory
$resolvedTarget = if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    (Get-Location).Path
} elseif ([System.IO.Path]::IsPathRooted($TargetDir)) {
    $TargetDir
} else {
    Join-Path (Get-Location).Path $TargetDir
}

if (-not (Test-Path -LiteralPath $resolvedTarget)) {
    Write-Error "Target directory does not exist: $resolvedTarget"
    exit 1
}

$resolvedTarget = (Resolve-Path -LiteralPath $resolvedTarget).Path

# Determine scan patterns
$searchFilters = if ($AllFiles) {
    @("*.*")
} elseif ($AllExtensions) {
    @("*.md", "*.txt", "*.json", "*.ts", "*.js", "*.html", "*.css", "*.ps1", "*.bat", "*.sh", "*.yaml", "*.yml")
} else {
    @($Filter)
}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "   EMOJI STRIPPER & SANITIZER (MODULAR)                                 " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " Target Directory : $resolvedTarget" -ForegroundColor White
Write-Host " File Scope       : $(if ($AllFiles) { 'All Files (*.*)' } elseif ($AllExtensions) { 'All Common Text Formats' } else { $Filter })" -ForegroundColor White
Write-Host " Mode             : $(if ($DryRun) { '[DRY-RUN] Preview Only' } else { '[APPLY] Write In-Place' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Green" })
Write-Host " Normalize Spaces : $(if ($NormalizeSpaces) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
Write-Host " Engine Module    : module\emojistripper.psm1" -ForegroundColor DarkGray
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

$excludeDirs = @(".git", "node_modules", "trash-bin", "dist")

$filesToScan = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach ($pat in $searchFilters) {
    $found = Get-ChildItem -Path $resolvedTarget -Filter $pat -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object {
            $fPath = $_.FullName
            $skip = $false
            foreach ($ex in $excludeDirs) {
                if ($fPath -like "*\$ex\*" -or $fPath -like "*/$ex/*") {
                    $skip = $true
                    break
                }
            }
            -not $skip
        }
    if ($found) {
        foreach ($f in $found) {
            # Avoid duplicate files if patterns overlap
            if (-not ($filesToScan | Where-Object { $_.FullName -eq $f.FullName })) {
                $filesToScan.Add($f)
            }
        }
    }
}

if ($filesToScan.Count -eq 0) {
    Write-Host "No matching files found in target scope." -ForegroundColor Yellow
    exit 0
}

Write-Host "Scanning $($filesToScan.Count) files..." -ForegroundColor Cyan

$processedCount = 0
$modifiedCount  = 0
$totalEmojis    = 0
$results        = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($file in $filesToScan) {
    $res = Invoke-EmojiStripOnFile -FilePath $file.FullName -DryRun:$DryRun -NormalizeSpaces:$NormalizeSpaces
    $processedCount++

    if ($res.EmojiCount -gt 0) {
        $modifiedCount++
        $totalEmojis += $res.EmojiCount
        $relPath = $file.FullName.Replace($resolvedTarget, "").TrimStart("\", "/")

        $results.Add([PSCustomObject]@{
            File       = $relPath
            EmojiCount = $res.EmojiCount
            Status     = $res.Status
        })

        Write-Host "  [$($res.Status)] $relPath ($($res.EmojiCount) emojis)" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Green" })
    }
}

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "   SUMMARY REPORT                                                       " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " Total Files Inspected : $processedCount" -ForegroundColor White
Write-Host " Files With Emojis     : $modifiedCount" -ForegroundColor $(if ($modifiedCount -gt 0) { "Yellow" } else { "Green" })
Write-Host " Total Emojis Found    : $totalEmojis" -ForegroundColor $(if ($totalEmojis -gt 0) { "Yellow" } else { "Green" })
Write-Host " Execution State       : $(if ($DryRun) { 'DryRun Complete (No files modified)' } else { 'Files Sanitized In-Place' })" -ForegroundColor Green
Write-Host "========================================================================" -ForegroundColor Cyan
