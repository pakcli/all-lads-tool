<#
.SYNOPSIS
    Git Status and Repository Inspection Module.
#>
[CmdletBinding()]
param()

function Test-IsGitRepo ([string]$dir) {
    if ([string]::IsNullOrWhiteSpace($dir) -or -not (Test-Path $dir)) { return $false }
    $gitDir = Join-Path $dir ".git"
    return (Test-Path $gitDir)
}

function Get-GitStatusSummary ([string]$dir) {
    if (-not (Test-IsGitRepo $dir)) {
        return [PSCustomObject]@{
            IsRepo        = $false
            Branch        = "N/A"
            Remote        = "None"
            DirtyCount    = 0
            TotalDirtyKb  = 0
            RecentLog     = @()
            Uncommitted   = @()
        }
    }

    Push-Location $dir
    try {
        $branch = (git branch --show-current 2>$null)
        if ([string]::IsNullOrWhiteSpace($branch)) {
            $branch = (git rev-parse --short HEAD 2>$null)
            if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "empty" } else { $branch = "(detached: $branch)" }
        }

        $remotes = (git remote -v 2>$null) | Select-Object -First 1
        $remoteName = if ($remotes) { ($remotes -split "\s+")[0] } else { "None" }

        $statusLines = @(git status -s 2>$null)
        $dirtyCount = if ($statusLines) { $statusLines.Count } else { 0 }

        $totalDirtyBytes = 0
        if ($statusLines) {
            foreach ($line in $statusLines) {
                if ($line.Length -gt 3) {
                    $rawPath = $line.Substring(3).Trim()
                    if ($rawPath -match '->\s*(.+)$') {
                        $rawPath = $matches[1].Trim()
                    }
                    $rawPath = $rawPath.Trim('"')
                    $fullPath = Join-Path $dir $rawPath
                    if (Test-Path $fullPath -PathType Leaf) {
                        $totalDirtyBytes += (Get-Item $fullPath).Length
                    }
                }
            }
        }
        $totalDirtyKb = [Math]::Round($totalDirtyBytes / 1KB, 1)

        $recentLog = @()
        $logOutput = (git log -n 5 --pretty=format:"%h|%cr|%s" 2>$null)
        if ($logOutput) {
            foreach ($item in $logOutput) {
                $p = $item -split "\|", 3
                if ($p.Length -ge 3) {
                    $recentLog += [PSCustomObject]@{
                        Hash = $p[0]
                        Time = $p[1]
                        Msg  = $p[2]
                    }
                }
            }
        }

        return [PSCustomObject]@{
            IsRepo        = $true
            Branch        = $branch
            Remote        = $remoteName
            DirtyCount    = $dirtyCount
            TotalDirtyKb  = $totalDirtyKb
            RecentLog     = $recentLog
            Uncommitted   = $statusLines
        }
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Test-IsGitRepo, Get-GitStatusSummary
