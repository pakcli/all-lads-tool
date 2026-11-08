<#
.SYNOPSIS
    Git Rollback and Soft Reset Engine (Context: Repo Adapter).
.DESCRIPTION
    Provides headless utilities to inspect recent commits for rollback checkpoints,
    execute safe git reset --soft while preserving local changes in the index,
    and optional remote force-push with lease.
#>
[CmdletBinding()]
param()

function Get-GitCommitCheckpoints ([string]$repoPath, [int]$count = 10) {
    Push-Location $repoPath
    try {
        $rawLogs = @(git log -n $count --pretty=format:"%h|%H|%s|%ar|%an" 2>$null)
        $list = @()
        $idx = 1
        foreach ($line in $rawLogs) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $parts = $line -split '\|', 5
            if ($parts.Length -ge 3) {
                $shortHash = $parts[0].Trim()
                $fullHash  = $parts[1].Trim()
                $subject   = $parts[2].Trim()
                $time      = if ($parts.Length -ge 4) { $parts[3].Trim() } else { "" }
                $author    = if ($parts.Length -ge 5) { $parts[4].Trim() } else { "" }

                $list += [PSCustomObject]@{
                    Index     = $idx
                    ShortHash = $shortHash
                    FullHash  = $fullHash
                    Subject   = $subject
                    Time      = $time
                    Author    = $author
                    IsHead    = ($idx -eq 1)
                }
                $idx++
            }
        }
        return $list
    } finally {
        Pop-Location
    }
}

function Resolve-GitCheckpointHash ([string]$repoPath, [string]$inputCommit) {
    if ([string]::IsNullOrWhiteSpace($inputCommit)) { return $null }
    $clean = $inputCommit.Trim().Trim('"').Trim("'")

    Push-Location $repoPath
    try {
        git rev-parse --verify "$clean^{commit}" 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            $fullHash = (git rev-parse "$clean").Trim()
            $shortHash = (git rev-parse --short "$clean").Trim()
            $subject = (git log -1 --pretty=format:"%s" "$fullHash").Trim()
            $diffCount = [int]((git rev-list --count "$fullHash..HEAD") | Out-String).Trim()
            return [PSCustomObject]@{
                FullHash  = $fullHash
                ShortHash = $shortHash
                Subject   = $subject
                DiffCount = $diffCount
            }
        }
        return $null
    } finally {
        Pop-Location
    }
}

function Invoke-GitSoftRollback ([string]$repoPath, [string]$targetFullHash) {
    Push-Location $repoPath
    try {
        $res = git reset --soft "$targetFullHash" 2>&1
        $code = $LASTEXITCODE
        return [PSCustomObject]@{
            Success  = ($code -eq 0)
            ExitCode = $code
            Output   = ($res -join "`n")
        }
    } finally {
        Pop-Location
    }
}

function Invoke-GitForcePushWithLease ([string]$repoPath, [string]$branch, [string]$remote = "origin") {
    Push-Location $repoPath
    try {
        $res = git push --force-with-lease $remote "$branch" 2>&1
        $code = $LASTEXITCODE
        return [PSCustomObject]@{
            Success  = ($code -eq 0)
            ExitCode = $code
            Output   = ($res -join "`n")
        }
    } finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Get-GitCommitCheckpoints, Resolve-GitCheckpointHash, Invoke-GitSoftRollback, Invoke-GitForcePushWithLease
