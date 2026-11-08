<#
.SYNOPSIS
    Master Adapter Aggregator for Active File Lock & Disk Activity Inspector
.DESCRIPTION
    Integrates inspector engines, drive scanners, CLI console, and WPF panel.
#>

$adapterDir = $PSScriptRoot

Import-Module -Name (Join-Path $adapterDir "file-lock-inspector.psm1") -DisableNameChecking -Force
Import-Module -Name (Join-Path $adapterDir "drive-activity-scanner.psm1") -DisableNameChecking -Force
Import-Module -Name (Join-Path $adapterDir "lock-console-dashboard.psm1") -DisableNameChecking -Force
Import-Module -Name (Join-Path $adapterDir "lock-panel-window.psm1") -DisableNameChecking -Force

function Get-LockInspectorSnapshot {
    [CmdletBinding()]
    param(
        [string]$TargetScope = ""
    )

    $drives = Get-SystemDrivesOverview
    $locks = [System.Collections.Generic.List[PSCustomObject]]::new()

    # Determine inspection candidates
    $candidatePaths = [System.Collections.Generic.List[string]]::new()

    if ($TargetScope -and (Test-Path -LiteralPath $TargetScope)) {
        $candidatePaths.Add((Resolve-Path -LiteralPath $TargetScope).Path)
    } else {
        # Default Auto-Discovery: Check trash-bin and current working directory
        $trashLocations = @(
            (Join-Path (Get-Location).Path "trash-bin"),
            (Join-Path (Split-Path (Get-Location).Path -Parent) "trash-bin"),
            "E:\proj\trash-bin",
            "D:\proj\trash-bin"
        )
        foreach ($tl in $trashLocations) {
            if (Test-Path -LiteralPath $tl -PathType Container) {
                if (-not $candidatePaths.Contains($tl)) { $candidatePaths.Add($tl) }
            }
        }
    }

    $lockedTargets = [System.Collections.Generic.List[string]]::new()

    foreach ($scope in $candidatePaths) {
        if (Test-Path -LiteralPath $scope -PathType Leaf) {
            if (Test-FileIsLocked -Path $scope) {
                $lockedTargets.Add($scope)
            }
        } else {
            # 1. Check directory lock on folder itself (only if not root trash-bin container)
            if ($scope -notmatch 'trash-bin[\\/]?$') {
                if (Test-FileIsLocked -Path $scope) {
                    $lockedTargets.Add($scope)
                }
            }

            # 2. Check child directories inside the folder (first 30)
            $subDirs = Get-ChildItem -LiteralPath $scope -Directory -ErrorAction SilentlyContinue | Select-Object -First 30
            foreach ($dir in $subDirs) {
                if (Test-FileIsLocked -Path $dir.FullName) {
                    if (-not $lockedTargets.Contains($dir.FullName)) {
                        $lockedTargets.Add($dir.FullName)
                    }
                }
            }

            # 3. Check leaf files directly inside the folder (first 30)
            $subFiles = Get-ChildItem -LiteralPath $scope -File -ErrorAction SilentlyContinue | Select-Object -First 30
            foreach ($item in $subFiles) {
                if (Test-FileIsLocked -Path $item.FullName) {
                    if (-not $lockedTargets.Contains($item.FullName)) {
                        $lockedTargets.Add($item.FullName)
                    }
                }
            }
        }
    }

    if ($lockedTargets.Count -gt 0) {
        $batchHandles = @()
        try {
            $batchHandles = [HandleScanOOP]::Scan($lockedTargets.ToArray())
        } catch {}

        foreach ($lt in $lockedTargets) {
            $found = Get-FileLockingProcesses -Path $lt -PreScannedHandles $batchHandles
            foreach ($f in $found) {
                $exists = $locks | Where-Object { $_.ProcessId -eq $f.ProcessId -and $_.FilePath -eq $f.FilePath }
                if (-not $exists) { $locks.Add($f) }
            }
        }
    }

    return [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Drives    = $drives
        AppLocks  = @($locks)
    }
}

Export-ModuleMember -Function Get-LockInspectorSnapshot, Render-LockConsoleDashboard, Show-FileLockPanel, Test-FileIsLocked, Get-FileLockingProcesses, Restart-WindowsExplorer, Unlock-FileOrFolder, Get-SystemDrivesOverview, Get-DirectoryTreeNode
