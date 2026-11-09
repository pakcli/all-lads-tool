<#
.SYNOPSIS
    Universal Standalone Decompiler & Slicer (Context: common / all-lads-tool)
.DESCRIPTION
    Conforms strictly to Brief v01-04-00 and Brief v01-04-01.
    Delegates all decompilation and unbundling logic to:
      - adapter/decompiler-engine.psm1
      - adapter/path-normalizer.psm1
      - adapter/run-json-bridge.psm1
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$StandaloneScript,

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$TargetDir,

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
Import-Module -Name (Join-Path $adapterDir "decompiler-engine.psm1") -DisableNameChecking -Force

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   UNIVERSAL STANDALONE DECOMPILER (Context: common)      " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Interactive prompt if StandaloneScript is not provided
if ([string]::IsNullOrWhiteSpace($StandaloneScript)) {
    Write-Host "`nEnter path to the compiled standalone script to decompile" -ForegroundColor Yellow
    Write-Host "(or drag & drop the standalone .ps1 file here):" -ForegroundColor DarkGray
    $rawInput = Read-Host "Standalone Script Path"
    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        Write-Host "`n[CANCELLED] No script provided. Exiting." -ForegroundColor Yellow
        exit 0
    }
    $StandaloneScript = $rawInput
}

$canonicalScript = Convert-ToCanonicalPath -RawPath $StandaloneScript
if (-not (Test-ValidFile -Path $canonicalScript)) {
    Write-Host "`n[ERROR] File does not exist: $canonicalScript" -ForegroundColor Red
    exit 1
}

if (-not [string]::IsNullOrWhiteSpace($TargetDir)) {
    $TargetDir = Convert-ToCanonicalPath -RawPath $TargetDir
}

# Render Pre-Flight Briefed Card
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   DECOMPILER PRE-FLIGHT BRIEFED OVERVIEW                 " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Standalone Script : $canonicalScript"
Write-Host " Target Directory  : $(if ($TargetDir) { $TargetDir } else { 'Source Directory (Auto-resolved)' })"
Write-Host " Execution Mode    : $(if ($DryRun) { 'DryRun (Preview Only)' } else { 'Extract to Modular Structure' })"
Write-Host " Safety Status     : Reconstructs adapter/*.psm1 modules safely"
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not $Yes) {
    $confirm = Read-Host "`nProceed with decompilation? (Type 'yes' to proceed, Enter to cancel)"
    if ($confirm.Trim().ToLowerInvariant() -ne "yes") {
        Write-Host "`n[ABORTED] Decompilation cancelled by user." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nDecompiling standalone script..." -ForegroundColor Green
$result = Invoke-ScriptDecompilation -StandaloneScriptPath $canonicalScript -TargetDir $TargetDir -DryRun:$DryRun

if ($result.Status -eq "Success") {
    Write-Host "`n[OK] Decompilation completed successfully!" -ForegroundColor Green
    Write-Host " Target Directory   : $($result.TargetDirectory)"
    Write-Host " Reconstructed Body : $($result.HasRunnerBody)"
    Write-Host " Extracted Adapters : $($result.ExtractedAdapters -join ', ')"
} else {
    Write-Host "`n[DRY-RUN] Decompilation preview generated successfully." -ForegroundColor Yellow
    Write-Host " Target Directory   : $($result.TargetDirectory)"
    Write-Host " Extracted Adapters : $($result.ExtractedAdapters -join ', ')"
}
