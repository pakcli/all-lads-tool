<#
.SYNOPSIS
    Modular Architecture Bundler & Compaction Orchestrator
    Script: compile-arctitecture-bundledjs.ps1
.DESCRIPTION
    100% Modular & Declarative Pipeline Orchestrator.
    Dynamically loads all PowerShell modules from ./modules/*.ps1 and executes
    the build manifest without any hardcoded filenames, paths, or asset names.
#>

[CmdletBinding()]
param (
    [string]$ConfigFile = "",
    [string]$SourcePath = "",
    [string]$OutputPath = "",
    [string]$AppsSource = "",
    [switch]$Minify,
    [switch]$Watch,
    [switch]$Clean,
    [switch]$Yes
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot  = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path

# ------------------------------------------------------------------------------
# 1. DYNAMICALLY LOAD ALL MODULAR POWERSHELL ENGINES (./modules/*.ps1)
# ------------------------------------------------------------------------------
$modulesDir = Join-Path $scriptDir "modules"
if (Test-Path $modulesDir) {
    Get-ChildItem -Path $modulesDir -Filter "*.ps1" -File | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
} else {
    Write-Error "Required PowerShell modules directory not found: $modulesDir"
    exit 1
}

# ------------------------------------------------------------------------------
# 2. AUTO-DISCOVER DECLARATIVE MANIFEST JSON
# ------------------------------------------------------------------------------
$resolvedConfigPath = $null
if (-not [string]::IsNullOrWhiteSpace($ConfigFile)) {
    $candidate = if ([System.IO.Path]::IsPathRooted($ConfigFile)) { $ConfigFile } else { Join-Path $repoRoot $ConfigFile }
    if (Test-Path $candidate) { $resolvedConfigPath = $candidate }
}

if (-not $resolvedConfigPath) {
    # Check default build.json directly first (Single Source of Truth)
    $defaultBuildJson = Join-Path $repoRoot "build.json"
    if (Test-Path $defaultBuildJson) {
        $resolvedConfigPath = $defaultBuildJson
    } else {
        $discoveredJson = Get-ChildItem -Path $repoRoot -Filter "*.json" -File |
            Where-Object { 
                $_.Name -notmatch "schema|package|tsconfig|main|permission|^\." -and 
                $_.Name -match "build|manifest|arcade"
            } |
            Select-Object -First 1
        if ($discoveredJson) {
            $resolvedConfigPath = $discoveredJson.FullName
        }
    }
}

if (-not $resolvedConfigPath -or -not (Test-Path $resolvedConfigPath)) {
    Write-Error "No build manifest JSON found in $repoRoot"
    exit 1
}

try {
    $buildConfig = (Get-Content -Path $resolvedConfigPath -Raw -Encoding UTF8) | ConvertFrom-Json
} catch {
    Write-Error "Failed to parse manifest $resolvedConfigPath : $_"
    exit 1
}

# ------------------------------------------------------------------------------
# 3. RESOLVE CONTEXT PATHS FROM MANIFEST OR CLI OVERRIDES
# ------------------------------------------------------------------------------
$sourceRel = if ($SourcePath) { $SourcePath } else { if ($buildConfig.paths -and $buildConfig.paths.source) { $buildConfig.paths.source } else { "src" } }
$outputRel = if ($OutputPath) { $OutputPath } else { if ($buildConfig.paths -and $buildConfig.paths.output) { $buildConfig.paths.output } else { "public" } }
$appsRel   = if ($AppsSource) { $AppsSource } else { if ($buildConfig.paths -and $buildConfig.paths.apps)   { $buildConfig.paths.apps }   else { "apps" } }

$resolvedSource = if ([System.IO.Path]::IsPathRooted($sourceRel)) { $sourceRel } else { Join-Path $repoRoot $sourceRel }
$resolvedOutput = if ([System.IO.Path]::IsPathRooted($outputRel)) { $outputRel } else { Join-Path $repoRoot $outputRel }
$resolvedApps   = if ([System.IO.Path]::IsPathRooted($appsRel))   { $appsRel }   else { Join-Path $repoRoot $appsRel }

$PipelineContext = [PSCustomObject]@{
    RepoRoot       = $repoRoot
    ManifestPath   = $resolvedConfigPath
    Manifest       = $buildConfig
    ResolvedSource = $resolvedSource
    ResolvedOutput = $resolvedOutput
    ResolvedApps   = $resolvedApps
    Minify         = [bool]$Minify
    Clean          = [bool]$Clean
    AuditReport    = [System.Collections.Generic.List[PSCustomObject]]::new()
}

# ------------------------------------------------------------------------------
# 4. DISPLAY DETECTED CONFIGURATION & OPTIONAL INTERACTIVE CONFIRMATION
# ------------------------------------------------------------------------------
Write-Host "==========================================================================" -ForegroundColor Yellow
Write-Host "  MODULAR ARCHITECTURE BUNDLER & COMPACTOR ($($buildConfig.project) v$($buildConfig.version))" -ForegroundColor Yellow
Write-Host "==========================================================================" -ForegroundColor Yellow
Write-Host "  + Manifest : $($PipelineContext.ManifestPath)" -ForegroundColor White
Write-Host "  + Source   : $($PipelineContext.ResolvedSource)" -ForegroundColor White
Write-Host "  + Output   : $($PipelineContext.ResolvedOutput)" -ForegroundColor White
Write-Host "  + Apps     : $($PipelineContext.ResolvedApps)" -ForegroundColor White
Write-Host ""

if (-not $Yes) {
    $answer = Read-Host "Proceed with modular compilation? [Y/n] (default: Y)"
    if (-not [string]::IsNullOrWhiteSpace($answer) -and $answer -notmatch "^(y|yes)$") {
        Write-Host "[-] Compilation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

# ------------------------------------------------------------------------------
# 5. EXECUTE MODULAR PIPELINE STAGES
# ------------------------------------------------------------------------------
function Invoke-ModularPipeline {
    param ([Parameter(Mandatory = $true)][PSCustomObject]$Ctx)

    $coreBuildScript = Join-Path $repoRoot "src\modules\build-bundle.js"
    if (Test-Path $coreBuildScript) {
        node $coreBuildScript
    } else {
        $Ctx.AuditReport.Clear()
        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        Initialize-PipelineDirectories -Context $Ctx
        Invoke-CartridgeBundlesStage   -Context $Ctx
        Invoke-SlidevBundlesStage      -Context $Ctx
        Invoke-ScriptBundlesStage      -Context $Ctx
        Invoke-StyleBundlesStage       -Context $Ctx
        Invoke-HtmlBundlesStage        -Context $Ctx
        Invoke-MediaBundlesStage       -Context $Ctx
        Invoke-AppScreenshotsStage     -Context $Ctx

        $sw.Stop()
        Show-AuditReportTable -AuditList $Ctx.AuditReport -Context $Ctx
        Write-Host "[OK] Modular pipeline finished in $($sw.ElapsedMilliseconds)ms!`n" -ForegroundColor Green
    }
}

Invoke-ModularPipeline -Ctx $PipelineContext

# ------------------------------------------------------------------------------
# 6. OPTIONAL WATCH MODE
# ------------------------------------------------------------------------------
if ($Watch) {
    Write-Host "[*] Watching $($PipelineContext.ResolvedSource) for changes ([CTRL+C] to stop)..." -ForegroundColor Yellow
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $PipelineContext.ResolvedSource
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true
    $watcher.Filter = "*.*"

    $action = {
        param($source, $eventArgs)
        Write-Host "[Change Detected] $($eventArgs.Name) -> Re-running modular pipeline..." -ForegroundColor Magenta
        Invoke-ModularPipeline -Ctx $PipelineContext
    }

    Register-ObjectEvent $watcher 'Changed' -Action $action | Out-Null
    Register-ObjectEvent $watcher 'Created' -Action $action | Out-Null

    try {
        while ($true) { Start-Sleep -Seconds 1 }
    } finally {
        $watcher.EnableRaisingEvents = $false
        $watcher.Dispose()
    }
}
