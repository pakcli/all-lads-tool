<#
.SYNOPSIS
    Universal Git Manager (Context: Repo)
.DESCRIPTION
    Lean orchestrator that detects Git runtime version and loads the matching adapter from adapter/.
#>
[CmdletBinding()]
param(
    [string]$TargetDir = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

# Detect Git version
$gitVersionRaw = git --version 2>$null
if (-not $gitVersionRaw) {
    Write-Error "[ERROR] Git CLI tidak ditemukan pada sistem."
    exit 1
}

$versionNumber = [regex]::Match($gitVersionRaw, '\d+\.\d+').Value
$adapterFile = if ([version]$versionNumber -ge [version]"2.40") {
    "v02-40-00.psm1"
} else {
    "v02-30-00.psm1"
}

$adapterPath = Join-Path $PSScriptRoot "adapter\$adapterFile"
Import-Module -Name $adapterPath -Force

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   GIT MANAGER (CONTEXT: REPO)                            " -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Target : $TargetDir" -ForegroundColor White
Write-Host "Adapter: $adapterFile" -ForegroundColor DarkGray
Write-Host ""

Invoke-GitStatus -RepoPath $TargetDir
