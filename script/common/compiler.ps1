<#
.SYNOPSIS
    Universal Toolchain Compiler & Bundler (Context: common / all-lads-tool)
.DESCRIPTION
    Conforms strictly to Brief v01-04-00 and Brief v01-04-01.
    Delegates all compilation, inlining, and packaging logic to:
      - adapter/compiler-engine.psm1
      - adapter/path-normalizer.psm1
      - adapter/run-json-bridge.psm1
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$ToolScript,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$OutputDir,

    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

# Global Crash / Error Guardrail
trap {
    $errText = $_.Exception.ToString()
    Write-Host "`n[FATAL SCRIPT ERROR]" -ForegroundColor Red
    Write-Host $errText -ForegroundColor DarkRed
    try {
        Set-Content -Path "$PSScriptRoot\last-error.log" -Value $errText -Force
    } catch {}
    Write-Host "`nError logged to last-error.log" -ForegroundColor Yellow
    exit 1
}

# Import Common Adapters
$adapterDir = Join-Path $PSScriptRoot "adapter"
Import-Module -Name (Join-Path $adapterDir "path-normalizer.psm1") -DisableNameChecking -Force
Import-Module -Name (Join-Path $adapterDir "run-json-bridge.psm1") -DisableNameChecking -Force
Import-Module -Name (Join-Path $adapterDir "compiler-engine.psm1") -DisableNameChecking -Force

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   UNIVERSAL TOOLCHAIN COMPILER (Context: common)         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Interactive prompt if ToolScript is not provided
if ([string]::IsNullOrWhiteSpace($ToolScript)) {
    Write-Host "`nEnter path to the modular runner script to compile" -ForegroundColor Yellow
    Write-Host "(e.g. script/repo/git-checkpoint-rollback.ps1 or drag & drop file):" -ForegroundColor DarkGray
    $rawInput = Read-Host "Tool Script Path"
    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        Write-Host "`n[CANCELLED] No script provided. Exiting." -ForegroundColor Yellow
        exit 0
    }
    $ToolScript = $rawInput
}

$canonicalScript = Convert-ToCanonicalPath -RawPath $ToolScript
if (-not (Test-ValidFile -Path $canonicalScript)) {
    Write-Host "`n[ERROR] File does not exist: $canonicalScript" -ForegroundColor Red
    exit 1
}

if (-not [string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Convert-ToCanonicalPath -RawPath $OutputDir
}

# Render Pre-Flight Briefed Card
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   COMPILER PRE-FLIGHT BRIEFED OVERVIEW                   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Source Script : $canonicalScript"
Write-Host " Output Dir    : $(if ($OutputDir) { $OutputDir } else { 'dist/<context>/ (Auto-resolved)' })"
Write-Host " Execution Mode: $(if ($DryRun) { 'DryRun (Preview Only)' } else { 'Compile to Standalone' })"
Write-Host " Safety Status : Source files remain strictly untouched (read-only)"
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not $Yes) {
    $confirm = Read-Host "`nProceed with compilation? (Type 'yes' to proceed, Enter to cancel)"
    if ($confirm.Trim().ToLowerInvariant() -ne "yes") {
        Write-Host "`n[ABORTED] Compilation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nCompiling modular tool..." -ForegroundColor Green
$result = Invoke-ScriptCompilation -ToolScriptPath $canonicalScript -OutputDir $OutputDir -DryRun:$DryRun

if ($result.Status -eq "Success") {
    Write-Host "`n[OK] Compilation completed successfully!" -ForegroundColor Green
    Write-Host " Target Standalone File : $($result.TargetFile)"
    Write-Host " Total Lines Compiled   : $($result.TotalLines)"
    Write-Host " Inlined Module Adapters: $($result.InlinedModules -join ', ')"
} else {
    Write-Host "`n[DRY-RUN] Compilation preview generated successfully." -ForegroundColor Yellow
    Write-Host " Target Standalone File : $($result.TargetFile)"
    Write-Host " Inlined Module Adapters: $($result.InlinedModules -join ', ')"
}
