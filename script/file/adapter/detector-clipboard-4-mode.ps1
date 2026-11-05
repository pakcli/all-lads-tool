<#
.SYNOPSIS
    Root Launcher for PolyClip 4-Mode Clipboard (Forwarder)
.DESCRIPTION
    Forwards execution to canonical path: script/file/detector-clipboard-4-mode.ps1
    Conforms strictly to Brief v01-03: Foldering Structure (The Current Adapter Way).
#>
[CmdletBinding()]
param (
    [ValidateSet("CLI", "Panel", "1", "2", "3", "4", "Inspect")]
    $Mode = "CLI",

    [switch]$Panel,
    [switch]$Inspect,
    [switch]$Json
)

$targetScript = Join-Path (Split-Path $PSScriptRoot -Parent) "detector-clipboard-4-mode.ps1"
if (-not (Test-Path -LiteralPath $targetScript)) {
    Write-Error "[ERROR] Canonical script not found: $targetScript"
    exit 1
}

& $targetScript @PSBoundParameters
