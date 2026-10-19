<#
.SYNOPSIS
    Finds and displays processes holding locks or watching files/directories on Windows.
.DESCRIPTION
    Scans a targeted directory for:
    1. Active file handles via Windows Restart Manager API (rstrtmgr.dll).
    2. Processes actively executing scripts from within the targeted folder.
    
    Rule #3 Compliant: Zero hardcoded machine paths or usernames. Dynamic resolution throughout.
.PARAMETER TargetPath
    Path to directory or file to check. Defaults to "all-script" relative to repository root.
.PARAMETER Kill
    Optional switch to kill the locking processes.
.EXAMPLE
    .\all-script\powershell\find-folder-lockers.ps1 -TargetPath ".\all-script"
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetPath = "",

    [Parameter()]
    [switch]$Kill
)

# 1. Dynamic Root & Path Resolution (Rule #3 Compliant)
$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path

if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $resolvedTarget = Join-Path $repoRoot "all-script"
} elseif ([System.IO.Path]::IsPathRooted($TargetPath)) {
    $resolvedTarget = $TargetPath
} else {
    $resolvedTarget = Resolve-Path (Join-Path (Get-Location) $TargetPath) -ErrorAction SilentlyContinue
    if (-not $resolvedTarget) {
        $resolvedTarget = Join-Path $repoRoot $TargetPath
    } else {
        $resolvedTarget = $resolvedTarget.Path
    }
}

if (-not (Test-Path $resolvedTarget)) {
    Write-Error "Target path does not exist: $resolvedTarget"
    exit 1
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  [*] WINDOWS FILE AND FOLDER LOCK DETECTOR" -ForegroundColor Yellow
Write-Host "  Target: $resolvedTarget" -ForegroundColor Gray
Write-Host "==========================================================================" -ForegroundColor Cyan

# 2. Windows Restart Manager API Definition
$rmType = @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class WinRestartManager {
    [StructLayout(LayoutKind.Sequential)]
    public struct RM_UNIQUE_PROCESS {
        public int dwProcessId;
        public System.Runtime.InteropServices.ComTypes.FILETIME ProcessStartTime;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct RM_PROCESS_INFO {
        public RM_UNIQUE_PROCESS Process;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string strAppName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
        public string strServiceShortName;
        public int ApplicationType;
        public uint AppStatus;
        public uint TSSessionId;
        [MarshalAs(UnmanagedType.Bool)]
        public bool bRestartable;
    }

    [DllImport("rstrtmgr.dll", CharSet = CharSet.Auto)]
    public static extern int RmStartSession(out uint pSessionHandle, int dwSessionFlags, string strSessionKey);

    [DllImport("rstrtmgr.dll")]
    public static extern int RmEndSession(uint pSessionHandle);

    [DllImport("rstrtmgr.dll", CharSet = CharSet.Auto)]
    public static extern int RmRegisterResources(uint pSessionHandle, uint nFiles, string[] rgsFilenames,
        uint nApplications, RM_UNIQUE_PROCESS[] rgApplications, uint nServices, string[] rgsServiceNames);

    [DllImport("rstrtmgr.dll", CharSet = CharSet.Auto)]
    public static extern int RmGetList(uint pSessionHandle, out uint pnProcInfoNeeded,
        ref uint pnProcInfo, [In, Out] RM_PROCESS_INFO[] rgAffectedApps, ref uint lpdwRebootReasons);

    public static List<int> GetLockingPids(string[] filePaths) {
        var pids = new List<int>();
        uint handle;
        string key = Guid.NewGuid().ToString();
        int res = RmStartSession(out handle, 0, key);
        if (res != 0) return pids;

        try {
            res = RmRegisterResources(handle, (uint)filePaths.Length, filePaths, 0, null, 0, null);
            if (res != 0) return pids;

            uint nProcInfoNeeded = 0;
            uint nProcInfo = 0;
            uint lpdwRebootReasons = 0;

            res = RmGetList(handle, out nProcInfoNeeded, ref nProcInfo, null, ref lpdwRebootReasons);
            if (res == 234) {
                RM_PROCESS_INFO[] processInfo = new RM_PROCESS_INFO[nProcInfoNeeded];
                nProcInfo = nProcInfoNeeded;
                res = RmGetList(handle, out nProcInfoNeeded, ref nProcInfo, processInfo, ref lpdwRebootReasons);
                if (res == 0) {
                    for (int i = 0; i < nProcInfo; i++) {
                        pids.Add(processInfo[i].Process.dwProcessId);
                    }
                }
            }
        } finally {
            RmEndSession(handle);
        }
        return pids;
    }
}
'@

if (-not ([System.Management.Automation.PSTypeName]'WinRestartManager').Type) {
    Add-Type -TypeDefinition $rmType
}

$detectedLockers = [System.Collections.Generic.List[PSCustomObject]]::new()
$normalizedTarget = $resolvedTarget.TrimEnd('\').ToLower()

# 3. Check Active File Handles (Restart Manager)
Write-Host "Scanning file handles..." -ForegroundColor DarkGray
$sampleFiles = @($resolvedTarget)
if (Test-Path $resolvedTarget -PathType Container) {
    $files = Get-ChildItem -Path $resolvedTarget -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 100 -ExpandProperty FullName
    if ($files) { $sampleFiles += $files }
}

$handlePids = [WinRestartManager]::GetLockingPids($sampleFiles) | Select-Object -Unique

foreach ($pidItem in $handlePids) {
    $proc = Get-Process -Id $pidItem -ErrorAction SilentlyContinue
    $detectedLockers.Add([PSCustomObject]@{
        PID         = $pidItem
        ProcessName = if ($proc) { $proc.ProcessName } else { "Unknown" }
        LockType    = "File Handle Lock"
        Detail      = "Holding open file handle in directory"
    })
}

# 4. Check Processes Running from or Referencing Target Path
Write-Host "Scanning process command lines..." -ForegroundColor DarkGray
$allProcs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue

foreach ($p in $allProcs) {
    $cmd = $p.CommandLine
    if ([string]::IsNullOrWhiteSpace($cmd)) { continue }

    if ($cmd.ToLower().Contains($normalizedTarget)) {
        if ($p.ProcessId -eq $PID) { continue }

        $detectedLockers.Add([PSCustomObject]@{
            PID         = $p.ProcessId
            ProcessName = $p.Name
            LockType    = "Active Command/Script"
            Detail      = ($cmd -replace '\s+', ' ').Trim()
        })
    }
}

# 5. Display Findings
Write-Host ""
if ($detectedLockers.Count -eq 0) {
    Write-Host "[OK] No direct process locks or executing scripts detected on: $resolvedTarget" -ForegroundColor Green
    Write-Host ""
    Write-Host "Note: If rename still gives EPERM, it is typically held by:" -ForegroundColor Yellow
    Write-Host "  1. VS Code / Antigravity file watchers on open tabs (Reload Window to clear: Ctrl+Shift+P > Reload Window)." -ForegroundColor Gray
    Write-Host "  2. An interactive terminal CWD sitting inside the folder (run 'cd ..' or close terminal)." -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "[!] FOUND $($detectedLockers.Count) LOCKING / WATCHING PROCESS(ES):" -ForegroundColor Red
    Write-Host ""
    
    $detectedLockers | Format-Table -Property @(
        @{ Label = "PID"; Expression = { $_.PID }; Width = 8 },
        @{ Label = "Process Name"; Expression = { $_.ProcessName }; Width = 18 },
        @{ Label = "Lock Type"; Expression = { $_.LockType }; Width = 22 },
        @{ Label = "Detail"; Expression = { $_.Detail } }
    ) -Wrap

    if ($Kill) {
        Write-Host "Attempting to terminate locking processes..." -ForegroundColor Yellow
        foreach ($item in $detectedLockers) {
            try {
                Stop-Process -Id $item.PID -Force -ErrorAction Stop
                Write-Host "  [KILLED] Process ID $($item.PID) ($($item.ProcessName))" -ForegroundColor Green
            } catch {
                Write-Host "  [FAILED] Could not terminate PID $($item.PID): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Tip: Run with -Kill to automatically terminate these processes:" -ForegroundColor Cyan
        Write-Host "  .\all-script\powershell\find-folder-lockers.ps1 -TargetPath `"$resolvedTarget`" -Kill" -ForegroundColor White
        Write-Host ""
    }
}
