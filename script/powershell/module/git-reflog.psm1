<#
.SYNOPSIS
    Git Reflog Parsing and Surgical Recovery Module.
#>
[CmdletBinding()]
param()

function Get-ReflogCommits ([string]$dir, [int]$maxCount = 20) {
    Push-Location $dir
    try {
        $reflogRaw = git reflog -n $maxCount --pretty=format:"%h|%gd|%cr|%s" 2>$null
        $list = @()
        if ($reflogRaw) {
            foreach ($entry in $reflogRaw) {
                $parts = $entry -split "\|", 4
                if ($parts.Length -ge 4) {
                    $hash = $parts[0]
                    $isLost = $false
                    $branchesContaining = git branch --contains $hash 2>$null
                    if (-not $branchesContaining) { $isLost = $true }

                    $list += [PSCustomObject]@{
                        Hash   = $hash
                        Ref    = $parts[1]
                        Time   = $parts[2]
                        Msg    = $parts[3]
                        IsLost = $isLost
                    }
                }
            }
        }
        return $list
    }
    finally {
        Pop-Location
    }
}

function Restore-ReflogCommitFiles ([string]$dir, [string]$commitHash, [string[]]$files) {
    Push-Location $dir
    try {
        foreach ($f in $files) {
            git checkout $commitHash -- $f 2>$null
        }
        return $true
    }
    catch {
        return $false
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Get-ReflogCommits, Restore-ReflogCommitFiles
