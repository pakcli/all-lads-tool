<#
.SYNOPSIS
    Master Adapter Aggregator for Active File Lock & Disk Activity Inspector
.DESCRIPTION
    Integrates inspector engines, drive scanners, CLI console, and WPF panel.
#>

$adapterDir = $PSScriptRoot
$script:optionsJsonPath = Join-Path $adapterDir "detector-file-lock-process.json"

function Save-LockInspectorOptions {
    [CmdletBinding()]
    param(
        [string]$TargetScope = "",
        [int]$DetectedLocksCount = 0
    )
    try {
        $nowIso = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $histList = [System.Collections.Generic.List[object]]::new()
        if (Test-Path -LiteralPath $script:optionsJsonPath) {
            $raw = Get-Content -LiteralPath $script:optionsJsonPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $existing = $raw | ConvertFrom-Json
                if ($existing -and $existing.history) {
                    foreach ($h in @($existing.history | Select-Object -Last 19)) {
                        [void]$histList.Add($h)
                    }
                }
            }
        }
        [void]$histList.Add([PSCustomObject]@{
            timestamp          = $nowIso
            targetScope        = if ($TargetScope) { $TargetScope } else { "Auto-Discovery (E:\proj\trash-bin + E:\proj)" }
            detectedLocksCount = $DetectedLocksCount
        })
        $payload = [PSCustomObject]@{
            executor  = "detector-file-lock-process.ps1"
            updatedAt = $nowIso
            options   = [PSCustomObject]@{
                lastTargetScope = $TargetScope
            }
            history   = ,$histList.ToArray()
        }
        Set-Content -LiteralPath $script:optionsJsonPath -Value ($payload | ConvertTo-Json -Depth 6) -Force -Encoding UTF8
    } catch {}
}

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
        $resolvedTarget = (Resolve-Path -LiteralPath $TargetScope).Path
        $candidatePaths.Add($resolvedTarget)
        $subTrash = Join-Path $resolvedTarget "trash-bin"
        if (($resolvedTarget -notmatch 'trash-bin[\\/]?$') -and (Test-Path -LiteralPath $subTrash -PathType Container)) {
            $candidatePaths.Add($subTrash)
        }
    } else {
        # Default Auto-Discovery: Check trash-bin and workspace directories
        $cwdPath = (Get-Location).Path
        $discoveryLocations = @(
            "E:\proj\trash-bin",
            "E:\proj",
            (Join-Path $cwdPath "trash-bin"),
            $cwdPath,
            "D:\proj\trash-bin"
        )

        foreach ($loc in $discoveryLocations) {
            if ($loc -and (Test-Path -LiteralPath $loc -PathType Container)) {
                $resLoc = (Resolve-Path -LiteralPath $loc).Path
                if (-not $candidatePaths.Contains($resLoc)) { $candidatePaths.Add($resLoc) }
            }
        }
    }

    $lockedTargets = [System.Collections.Generic.List[string]]::new()

    foreach ($scope in $candidatePaths) {
        if (Test-Path -LiteralPath $scope -PathType Leaf) {
            if (Test-FileIsLocked -Path $scope) {
                if (-not $lockedTargets.Contains($scope)) {
                    $lockedTargets.Add($scope)
                }
            }
        } else {
            # 1. Check directory lock on folder itself ONLY when user explicitly targeted that single folder
            $isRootContainer = ($scope -match 'trash-bin[\\/]?$' -or $scope -match '^[A-Za-z]:[\\/]proj[\\/]?$' -or $scope -match '^[A-Za-z]:[\\/]$')
            if ($TargetScope -and (-not $isRootContainer) -and ($scope -eq $candidatePaths[0])) {
                if (Test-FileIsLocked -Path $scope) {
                    if (-not $lockedTargets.Contains($scope)) {
                        $lockedTargets.Add($scope)
                    }
                }
            }

            # 2. Check all child directories inside the folder
            $subDirs = Get-ChildItem -LiteralPath $scope -Directory -ErrorAction SilentlyContinue
            foreach ($dir in $subDirs) {
                if ($dir.Name -eq 'trash-bin' -and $candidatePaths.Contains($dir.FullName)) { continue }
                if (Test-FileIsLocked -Path $dir.FullName) {
                    if (-not $lockedTargets.Contains($dir.FullName)) {
                        $lockedTargets.Add($dir.FullName)
                    }
                }
            }

            # 3. Check leaf files directly inside the folder (first 50)
            $subFiles = Get-ChildItem -LiteralPath $scope -File -ErrorAction SilentlyContinue | Select-Object -First 50
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

        $batchCwds = @()
        try {
            $batchCwds = [ProcessCwdReader]::FindProcessesInPaths($lockedTargets.ToArray())
        } catch {}

        $batchProcs = @()
        try {
            $batchProcs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
                $_.ProcessId -ne $PID -and $_.Name -notmatch '^(explorer|svchost|csrss|lsass)\.exe$'
            })
        } catch {}

        foreach ($lt in $lockedTargets) {
            $found = Get-FileLockingProcesses -Path $lt -PreScannedHandles $batchHandles -PreScannedCwds $batchCwds -PreScannedProcs $batchProcs
            foreach ($f in $found) {
                $exists = $locks | Where-Object { $_.ProcessId -eq $f.ProcessId -and $_.FilePath -eq $f.FilePath }
                if (-not $exists) { $locks.Add($f) }
            }
        }
    }

    Save-LockInspectorOptions -TargetScope $TargetScope -DetectedLocksCount $locks.Count

    return [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        Drives    = $drives
        AppLocks  = @($locks)
    }
}

Export-ModuleMember -Function Get-LockInspectorSnapshot, Save-LockInspectorOptions, Render-LockConsoleDashboard, Show-FileLockPanel, Test-FileIsLocked, Get-FileLockingProcesses, Restart-WindowsExplorer, Unlock-FileOrFolder, Get-SystemDrivesOverview, Get-DirectoryTreeNode
