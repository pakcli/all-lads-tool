<#
.SYNOPSIS
    Universal Active File Lock & Disk Activity Inspector (Context: File / all-lads-tool)
.DESCRIPTION
    Conforms strictly to Brief v01-03-02 (Foldering Structure: The Current Adapter Way).
    1:1 filename match with docs/file/detector-file-lock-process.md.
    Provides dual-mode inspection: Group by Application or Group by Drive & Directory Tree.
#>
[CmdletBinding()]
param (
    [ValidateSet("CLI", "Panel", "App", "DriveTree", "Inspect")]
    [string]$Mode = "CLI",

    [string]$Path = "",

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

# Import Adapter Module according to Brief v01-03-02
$adapterPath = Join-Path $PSScriptRoot "adapter\detector-file-lock-process.psm1"
Import-Module -Name $adapterPath -DisableNameChecking -Force

# Headless / Pipeline Dispatch
if ($Mode -eq "Panel") {
    $snapshot = Get-LockInspectorSnapshot -TargetScope $Path
    Show-FileLockPanel -AppLocks $snapshot.AppLocks -Drives $snapshot.Drives -InitialPath $Path
    exit 0
}

if ($Mode -eq "Inspect") {
    $snapshot = Get-LockInspectorSnapshot -TargetScope $Path
    if ($Json) {
        $snapshot | ConvertTo-Json -Depth 4
    } else {
        $snapshot | Format-List
    }
    exit 0
}

# Interactive Terminal CLI Mode
try {
    $Host.UI.RawUI.WindowTitle = "Active File Lock & Disk Inspector"
    [Console]::TreatControlCAsInput = $true
    [Console]::CursorVisible = $false
} catch {}

$currentView = if ($Mode -in "App", "DriveTree") { $Mode } else { "App" }
$snapshot = Get-LockInspectorSnapshot -TargetScope $Path
$selectedDrive = if ($snapshot.Drives.Count -gt 0) { $snapshot.Drives[0].DriveLetter } else { "C:" }
$lastMessage = "Ready. Press [TAB] to toggle view mode, [P] for WPF Panel."

while ($true) {
    Render-LockConsoleDashboard -ViewMode $currentView `
                                -AppLocks $snapshot.AppLocks `
                                -Drives $snapshot.Drives `
                                -SelectedDrive $selectedDrive `
                                -StatusMessage $lastMessage

    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            "Tab" {
                $currentView = if ($currentView -eq "App") { "DriveTree" } else { "App" }
                $lastMessage = "Switched view to: $currentView"
            }
            "R" {
                $lastMessage = "Refreshing active locks and drive inventory..."
                $snapshot = Get-LockInspectorSnapshot -TargetScope $Path
                $lastMessage = "Refreshed at $(Get-Date -Format 'HH:mm:ss')"
            }
            "P" {
                $lastMessage = "Launching WPF Card Panel..."
                Show-FileLockPanel -AppLocks $snapshot.AppLocks -Drives $snapshot.Drives
                $snapshot = Get-LockInspectorSnapshot -TargetScope $Path
                $lastMessage = "Returned from WPF Panel."
            }
            "Q" {
                Clear-Host
                Write-Host "Exited File Lock Inspector." -ForegroundColor Yellow
                exit 0
            }
        }
    }
    Start-Sleep -Milliseconds 150
}
