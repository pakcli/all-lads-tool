<#
.SYNOPSIS
    Single CSS to SCSS Compiler / Converter (compile-single-css-to-scss.ps1)
.DESCRIPTION
    Converts a single targeted .css file into structured, formatted .scss.
    Supports two modular conversion modes:
      Mode [0]: Direct 1:1 Syntax (Verbatim raw conversion)
      Mode [1]: Obsidian Theme Class Conversion (Compact AI-friendly SCSS)
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$SourceFile = "",

    [Parameter(Position = 1)]
    [string]$OutputFile = "",

    [Parameter(Position = 2)]
    [int]$Mode = -1,

    [switch]$Backup,
    [switch]$Watch,
    [switch]$Force,
    [switch]$Yes,
    [switch]$Agent
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
$converterJs = Join-Path $repoRoot "all-lads-tool\script\javascript\theme-syntax-converter.js"

function Resolve-ArcadePath ([string]$filePath) {
    if ([System.IO.Path]::IsPathRooted($filePath)) {
        return $filePath
    }
    return (Join-Path $repoRoot $filePath)
}

$defaultSource = "src/style/theme/vintage-computer/theme.css"

# ------------------------------------------------------------------------------
# 0. INTERACTIVE MODE SELECTION, TARGET PROMPTS & OVERWRITE CONFIRMATION
# ------------------------------------------------------------------------------
if (-not $Agent -and -not $Force -and -not $Yes) {
    # 0. Mode selection prompt
    if ($Mode -lt 0) {
        Write-Host ""
        Write-Host "==========================================================================" -ForegroundColor Magenta
        Write-Host "  SELECT CONVERSION MODE:                                                 " -ForegroundColor Magenta
        Write-Host "  [0] Direct 1:1 Syntax (Verbatim raw conversion)                         " -ForegroundColor DarkGray
        Write-Host "  [1] Obsidian Theme Class Conversion (Compact AI-friendly SCSS)          " -ForegroundColor Yellow
        Write-Host "==========================================================================" -ForegroundColor Magenta
        $userMode = Read-Host "Select mode [0 or 1, default: 1]"
        $Mode = if ($userMode -eq "0") { 0 } else { 1 }
    }

    # 1. Target CSS prompt
    if ([string]::IsNullOrWhiteSpace($SourceFile)) {
        Write-Host ""
        Write-Host "[1/3] TARGET CSS FILE:" -ForegroundColor Magenta
        $userSrc = Read-Host "      Enter target CSS file [default: $defaultSource]"
        $SourceFile = if (-not [string]::IsNullOrWhiteSpace($userSrc)) { $userSrc.Trim() } else { $defaultSource }
    }

    $resolvedSource = Resolve-ArcadePath $SourceFile

    # 2. Output SCSS prompt (side-by-side default)
    $sideBySideDefault = [System.IO.Path]::ChangeExtension($resolvedSource, ".scss")
    $relSide = if ($sideBySideDefault.StartsWith($repoRoot)) {
        $sideBySideDefault.Substring($repoRoot.Length).TrimStart('\', '/')
    } else {
        $sideBySideDefault
    }

    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        Write-Host "[2/3] OUTPUT SCSS TARGET (Side-by-side default):" -ForegroundColor Magenta
        $userOut = Read-Host "      Enter output SCSS target [default: $relSide]"
        $OutputFile = if (-not [string]::IsNullOrWhiteSpace($userOut)) { $userOut.Trim() } else { $sideBySideDefault }
    }

    $resolvedOutput = Resolve-ArcadePath $OutputFile

    # 3. Overwrite confirmation
    if (Test-Path $resolvedOutput) {
        Write-Host ""
        Write-Host "[3/3] OVERWRITE CONFIRMATION:" -ForegroundColor Yellow
        Write-Host "      Target file already exists: '$resolvedOutput'" -ForegroundColor DarkYellow
        $confirm = Read-Host "      Overwrite existing output? [Y/n]"
        if ($confirm -match "^(n|no)$") {
            Write-Host "`n[x] Conversion aborted by user (preserved existing file)." -ForegroundColor DarkGray
            exit 0
        }
    }
} else {
    if ($Mode -lt 0) { $Mode = 1 }
    if ([string]::IsNullOrWhiteSpace($SourceFile)) { $SourceFile = $defaultSource }
    $resolvedSource = Resolve-ArcadePath $SourceFile
    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        $OutputFile = [System.IO.Path]::ChangeExtension($resolvedSource, ".scss")
    }
    $resolvedOutput = Resolve-ArcadePath $OutputFile
}

$modeLabel = if ($Mode -eq 0) { "Direct 1:1 Syntax" } else { "Obsidian Theme Class Conversion (Compact AI)" }

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "  VINTAGE COMPUTING ARCADE - SINGLE CSS TO SCSS CONVERTER                 " -ForegroundColor Magenta
Write-Host "==========================================================================" -ForegroundColor Magenta
Write-Host "Repository Root : $repoRoot" -ForegroundColor DarkGray
Write-Host "Conversion Mode : [$Mode] $modeLabel" -ForegroundColor White
Write-Host "Source CSS      : $resolvedSource" -ForegroundColor Yellow
Write-Host "Output SCSS     : $resolvedOutput" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $resolvedSource)) {
    Write-Error "Source CSS file not found: $resolvedSource"
    exit 1
}

# ------------------------------------------------------------------------------
# 1. CORE COMPILATION EXECUTION
# ------------------------------------------------------------------------------
function Execute-Conversion {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $srcItem = Get-Item $resolvedSource
    $srcSize = $srcItem.Length
    $srcKb = [math]::Round($srcSize / 1024, 2)
    $srcLeaf = Split-Path $resolvedSource -Leaf
    $dstLeaf = Split-Path $resolvedOutput -Leaf

    try {
        if ($Backup -and (Test-Path $resolvedOutput)) {
            $bakFile = "$resolvedOutput.bak"
            Copy-Item -Path $resolvedOutput -Destination $bakFile -Force
            Write-Host "  Backup       : Created $bakFile" -ForegroundColor DarkGray
        }

        & node $converterJs css-to-scss "$resolvedSource" "$resolvedOutput" "$Mode"
        $sw.Stop()

        if (Test-Path $resolvedOutput) {
            $dstItem = Get-Item $resolvedOutput
            $dstSize = $dstItem.Length
            $dstKb = [math]::Round($dstSize / 1024, 2)
            $srcLines = (Get-Content $resolvedSource).Count
            $dstLines = (Get-Content $resolvedOutput).Count

            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  CSS -> SCSS CONVERSION SUCCESSFUL" -ForegroundColor Green
            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  Source CSS   : $srcLeaf ($srcKb KB, $srcLines lines)" -ForegroundColor Yellow
            Write-Host "  Compiled SCSS: $dstLeaf ($dstKb KB, $dstLines lines)" -ForegroundColor Cyan
            Write-Host "  Mode Applied : [$Mode] $modeLabel" -ForegroundColor DarkCyan
            Write-Host "  Duration     : $($sw.ElapsedMilliseconds) ms" -ForegroundColor DarkCyan
            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
        } else {
            Write-Error "Conversion finished but output file was not created: $resolvedOutput"
        }
    } catch {
        Write-Error "CSS to SCSS conversion error: $_"
    }
}

Execute-Conversion

# ------------------------------------------------------------------------------
# 2. LIVE WATCH MODE (OPTIONAL)
# ------------------------------------------------------------------------------
if ($Watch) {
    Write-Host ""
    Write-Host "WATCH MODE ACTIVE: Monitoring changes to $resolvedSource..." -ForegroundColor Yellow
    Write-Host "Press [Ctrl+C] to stop file watching." -ForegroundColor DarkGray

    $srcFolder = Split-Path -Parent $resolvedSource
    $srcFileName = Split-Path -Leaf $resolvedSource

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $srcFolder
    $watcher.Filter = $srcFileName
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

    $lastChange = [DateTime]::MinValue
    $action = {
        $now = [DateTime]::UtcNow
        if (($now - $lastChange).TotalMilliseconds -gt 500) {
            $lastChange = $now
            Write-Host "`n[*] Change detected in $srcFileName. Re-converting CSS -> SCSS..." -ForegroundColor Magenta
            Execute-Conversion
        }
    }

    Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null

    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    } finally {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
        Write-Host "`n[x] Watcher terminated." -ForegroundColor DarkGray
    }
}
