<#
.SYNOPSIS
    Single SCSS to CSS Compiler (compile-single-scss-to-css.ps1)
.DESCRIPTION
    Compiles a single targeted .scss file into standard CSS.
    Supports two modular compilation modes:
      Mode [0]: Direct 1:1 Syntax (Standard Sass compile)
      Mode [1]: Obsidian Theme CSS Class Conversion (Full expanded Obsidian theme specification)
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$SourceFile = "",

    [Parameter(Position = 1)]
    [string]$OutputFile = "",

    [Parameter(Position = 2)]
    [int]$Mode = -1,

    [switch]$Minify,
    [switch]$Watch,
    [switch]$SyncToPublic,
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

$defaultSource = "src/style/theme/vintage-computer/theme.scss"

# ------------------------------------------------------------------------------
# 0. INTERACTIVE MODE SELECTION, TARGET PROMPTS & OVERWRITE CONFIRMATION
# ------------------------------------------------------------------------------
if (-not $Agent -and -not $Force -and -not $Yes) {
    # 0. Mode selection prompt
    if ($Mode -lt 0) {
        Write-Host ""
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "  SELECT COMPILATION MODE:                                                " -ForegroundColor Cyan
        Write-Host "  [0] Direct 1:1 Syntax (Standard Sass compile)                           " -ForegroundColor DarkGray
        Write-Host "  [1] Obsidian Theme CSS Class Conversion (Full expanded Obsidian theme)  " -ForegroundColor Yellow
        Write-Host "==========================================================================" -ForegroundColor Cyan
        $userMode = Read-Host "Select mode [0 or 1, default: 1]"
        $Mode = if ($userMode -eq "0") { 0 } else { 1 }
    }

    # 1. Target SCSS prompt
    if ([string]::IsNullOrWhiteSpace($SourceFile)) {
        Write-Host ""
        Write-Host "[1/3] TARGET SCSS FILE:" -ForegroundColor Cyan
        $userSrc = Read-Host "      Enter target SCSS file [default: $defaultSource]"
        $SourceFile = if (-not [string]::IsNullOrWhiteSpace($userSrc)) { $userSrc.Trim() } else { $defaultSource }
    }

    $resolvedSource = Resolve-ArcadePath $SourceFile

    # 2. Output CSS prompt (side-by-side default)
    $sideBySideDefault = [System.IO.Path]::ChangeExtension($resolvedSource, ".css")
    $relSide = if ($sideBySideDefault.StartsWith($repoRoot)) {
        $sideBySideDefault.Substring($repoRoot.Length).TrimStart('\', '/')
    } else {
        $sideBySideDefault
    }

    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        Write-Host "[2/3] OUTPUT CSS TARGET (Side-by-side default):" -ForegroundColor Cyan
        $userOut = Read-Host "      Enter output CSS target [default: $relSide]"
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
            Write-Host "`n[x] Compilation aborted by user (preserved existing file)." -ForegroundColor DarkGray
            exit 0
        }
    }
} else {
    if ($Mode -lt 0) { $Mode = 1 }
    if ([string]::IsNullOrWhiteSpace($SourceFile)) { $SourceFile = $defaultSource }
    $resolvedSource = Resolve-ArcadePath $SourceFile
    if ([string]::IsNullOrWhiteSpace($OutputFile)) {
        $OutputFile = [System.IO.Path]::ChangeExtension($resolvedSource, ".css")
    }
    $resolvedOutput = Resolve-ArcadePath $OutputFile
}

$modeLabel = if ($Mode -eq 0) { "Direct 1:1 Syntax" } else { "Obsidian Theme CSS Class Conversion (Full Expanded)" }

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  VINTAGE COMPUTING ARCADE - SINGLE SCSS TO CSS COMPILER                  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "Repository Root : $repoRoot" -ForegroundColor DarkGray
Write-Host "Compile Mode    : [$Mode] $modeLabel" -ForegroundColor White
Write-Host "Source SCSS     : $resolvedSource" -ForegroundColor Yellow
Write-Host "Output CSS      : $resolvedOutput" -ForegroundColor Green
Write-Host "Minify          : $Minify | Watch: $Watch | SyncToPublic: $SyncToPublic" -ForegroundColor DarkGray
Write-Host ""

if (-not (Test-Path $resolvedSource)) {
    Write-Error "Source SCSS file not found: $resolvedSource"
    exit 1
}

# ------------------------------------------------------------------------------
# 1. CORE COMPILATION EXECUTION
# ------------------------------------------------------------------------------
function Execute-Compilation {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $srcItem = Get-Item $resolvedSource
    $srcSize = $srcItem.Length
    $srcKb = [math]::Round($srcSize / 1024, 2)
    $srcLeaf = Split-Path $resolvedSource -Leaf
    $dstLeaf = Split-Path $resolvedOutput -Leaf

    try {
        $minFlag = if ($Minify) { "true" } else { "false" }
        & node $converterJs scss-to-css "$resolvedSource" "$resolvedOutput" "$Mode" "$minFlag"
        $sw.Stop()

        if (Test-Path $resolvedOutput) {
            $dstItem = Get-Item $resolvedOutput
            $dstSize = $dstItem.Length
            $dstKb = [math]::Round($dstSize / 1024, 2)
            $srcLines = (Get-Content $resolvedSource).Count
            $dstLines = (Get-Content $resolvedOutput).Count

            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  SCSS -> CSS COMPILATION SUCCESSFUL" -ForegroundColor Green
            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "  Source SCSS  : $srcLeaf ($srcKb KB, $srcLines lines)" -ForegroundColor Yellow
            Write-Host "  Compiled CSS : $dstLeaf ($dstKb KB, $dstLines lines)" -ForegroundColor Green
            Write-Host "  Mode Applied : [$Mode] $modeLabel" -ForegroundColor DarkCyan
            Write-Host "  Duration     : $($sw.ElapsedMilliseconds) ms" -ForegroundColor DarkCyan

            # Optional mirror to public distribution (public/theme.css)
            if ($SyncToPublic) {
                $publicTheme = Join-Path $repoRoot "public/theme.css"
                $publicDir = Split-Path -Parent $publicTheme
                if (-not (Test-Path $publicDir)) {
                    New-Item -ItemType Directory -Path $publicDir -Force | Out-Null
                }
                Copy-Item -Path $resolvedOutput -Destination $publicTheme -Force
                Write-Host "  Public Sync  : Mirrored to public/theme.css" -ForegroundColor Yellow
            }
            Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
        } else {
            Write-Error "Compilation finished but output file was not created: $resolvedOutput"
        }
    } catch {
        Write-Error "SCSS compilation error: $_"
    }
}

Execute-Compilation

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
            Write-Host "`n[*] Change detected in $srcFileName. Recompiling SCSS -> CSS..." -ForegroundColor Cyan
            Execute-Compilation
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
