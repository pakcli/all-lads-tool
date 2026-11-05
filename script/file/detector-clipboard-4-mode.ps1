<#
.SYNOPSIS
    Universal 4-Mode Clipboard Suite (Context: File / all-lads-tool)
.DESCRIPTION
    Conforms strictly to Brief v01-03: Foldering Structure (The Current Adapter Way).
    Delegates all engine, snapshot, and GUI panel logic to adapter/detector-clipboard-4-mode.psm1.
#>
[CmdletBinding()]
param (
    [ValidateSet("CLI", "Panel", "1", "2", "3", "4", "Inspect")]
    $Mode = "CLI",

    [switch]$Panel,
    [switch]$Inspect,
    [switch]$Json
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
    Write-Host "`nPesan error telah dicatat ke last-error.log" -ForegroundColor Yellow
    Read-Host "Tekan Enter untuk menutup..."
    exit 1
}

if ($Panel) { $Mode = "Panel" }
if ($Inspect) { $Mode = "Inspect" }

# Import Adapter Module according to Brief v01-03
$adapterPath = Join-Path $PSScriptRoot "adapter\detector-clipboard-4-mode.psm1"
Import-Module -Name $adapterPath -DisableNameChecking -Force

# Headless / Pipeline Dispatch
if ($Mode -eq "Panel") {
    Show-LightweightPanel
    exit 0
}

if ($Mode -in "1", "2", "3", "4") {
    $snap = Get-ClipboardSnapshot
    $res = Invoke-ApplyMode -TargetMode [int]$Mode -Snapshot $snap
    Write-Host $res -ForegroundColor Green
    exit 0
}

if ($Mode -eq "Inspect") {
    $snap = Get-ClipboardSnapshot
    if ($Json) { $snap | ConvertTo-Json -Depth 3 } else { $snap | Format-List }
    exit 0
}

# Interactive Terminal CLI Mode
try {
    $Host.UI.RawUI.WindowTitle = "PolyClip CLI Dashboard"
    [Console]::TreatControlCAsInput = $true
    [Console]::CursorVisible = $false
} catch {}

$snapshot = Get-ClipboardSnapshot
$lastMessage = "Ready. Press [P] for Panel, [SPACE] to Refresh."

while ($true) {
    Render-CLI -Snap $snapshot -Msg $lastMessage

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "P" {
                $lastMessage = "Launching Panel..."
                Show-LightweightPanel
                $snapshot = Get-ClipboardSnapshot
                $lastMessage = "Returned from Panel."
            }
            "Spacebar" {
                $snapshot = Get-ClipboardSnapshot
                $lastMessage = "Snapshot refreshed."
            }
            "D1" { $lastMessage = Invoke-ApplyMode -TargetMode 1 -Snapshot $snapshot }
            "D2" { $lastMessage = Invoke-ApplyMode -TargetMode 2 -Snapshot $snapshot }
            "D3" { $lastMessage = Invoke-ApplyMode -TargetMode 3 -Snapshot $snapshot }
            "D4" { $lastMessage = Invoke-ApplyMode -TargetMode 4 -Snapshot $snapshot }
            "Q" {
                [Console]::CursorVisible = $true
                Write-Host "`n[PolyClip] Exiting."
                exit 0
            }
        }
    }
    Start-Sleep -Milliseconds 100
}
