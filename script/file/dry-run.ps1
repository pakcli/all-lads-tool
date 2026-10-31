<#
.SYNOPSIS
    Non-Destructive Dry-Run Runner (Context: File)
.DESCRIPTION
    Simulates script execution without modifying the filesystem.
    Delegates simulation logic to adapter/universal.psm1.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ScriptPath
)

$ErrorActionPreference = 'Stop'
$adapter = Join-Path $PSScriptRoot "adapter\dry-run-simulator.psm1"
Import-Module -Name $adapter -Force

if (-not $ScriptPath) { $ScriptPath = Read-Host 'TARGET SCRIPT (Path skrip untuk simulasi dry-run)' }
$ScriptPath = $ScriptPath.Trim('"').Trim()

Invoke-ScriptDryRun -ScriptPath $ScriptPath
Write-Host "[OK] Simulasi dry-run selesai. Status aman: zero mutation." -ForegroundColor Green
