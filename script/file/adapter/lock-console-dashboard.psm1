<#
.SYNOPSIS
    CLI UI: Interactive Console Dashboard for File Locks & Drive Trees
.DESCRIPTION
    Renders high-contrast, dual-mode tables and directory trees for the CLI terminal.
#>

function Render-LockConsoleDashboard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("App", "DriveTree")]
        [string]$ViewMode,

        [array]$AppLocks = @(),
        [array]$Drives = @(),
        [string]$SelectedDrive = "C:",
        [string]$StatusMessage = "Ready. Press [TAB] to Switch View, [R] to Refresh."
    )

    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host " [ACTIVE FILE LOCK & DISK ACTIVITY INSPECTOR] " -ForegroundColor Yellow -NoNewline
    Write-Host " - VIEW: $ViewMode" -ForegroundColor White
    Write-Host "================================================================================" -ForegroundColor Cyan

    if ($ViewMode -eq "App") {
        Write-Host " MODE A: GROUP BY APPLICATION & PROCESS ID" -ForegroundColor DarkCyan
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

        if ($AppLocks.Count -eq 0) {
            Write-Host "`n  [INFO] No active sharing violation or locked files detected in scanned scope." -ForegroundColor Green
            Write-Host "  Everything is clear and unlocked.`n" -ForegroundColor DarkGray
        } else {
            $grouped = $AppLocks | Group-Object -Property ProcessName
            foreach ($grp in $grouped) {
                Write-Host "`n > Application: $($grp.Name) (Count: $($grp.Count))" -ForegroundColor Yellow
                foreach ($item in $grp.Group) {
                    Write-Host "   |-- File: " -NoNewline -ForegroundColor DarkGray
                    Write-Host "$($item.FileName)" -ForegroundColor White -NoNewline
                    Write-Host " (PID: $($item.ProcessId))" -ForegroundColor Cyan
                    Write-Host "       Path: $($item.FilePath)" -ForegroundColor DarkGray
                }
            }
        }
    } else {
        Write-Host " MODE B: GROUP BY DRIVE & DIRECTORY TREE" -ForegroundColor DarkCyan
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray

        foreach ($d in $Drives) {
            $isCur = if ($d.DriveLetter -eq $SelectedDrive) { "[*]" } else { "[ ]" }
            $bar = "Free: $($d.FreeGB) GB / $($d.TotalGB) GB ($($d.PercentFree)%)"
            Write-Host " $isCur $($d.DriveLetter) [$($d.VolumeLabel)] - $bar" -ForegroundColor $(if ($d.DriveLetter -eq $SelectedDrive) { "Yellow" } else { "White" })
        }

        Write-Host "`n DIRECTORY TREE PREVIEW (Drive $SelectedDrive):" -ForegroundColor DarkCyan
        Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
        $rootPath = "$SelectedDrive\"
        $topDirs = Get-ChildItem -LiteralPath $rootPath -Directory -ErrorAction SilentlyContinue | Select-Object -First 12
        foreach ($td in $topDirs) {
            Write-Host "   +-- [DIR]  $($td.Name)" -ForegroundColor Cyan
        }
        $topFiles = Get-ChildItem -LiteralPath $rootPath -File -ErrorAction SilentlyContinue | Select-Object -First 8
        foreach ($tf in $topFiles) {
            Write-Host "   |-- [FILE] $($tf.Name)" -ForegroundColor DarkGray
        }
    }

    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host " Actions: [TAB] Switch View  [P] Open WPF Panel  [R] Refresh  [Q] Exit" -ForegroundColor Yellow
    Write-Host " Status : $StatusMessage" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Cyan
}

Export-ModuleMember -Function Render-LockConsoleDashboard
