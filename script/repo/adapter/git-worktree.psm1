<#
.SYNOPSIS
    Git Worktree Management Module (Context: Repo Adapter).
.DESCRIPTION
    Provides headless worktree listing, creation, removal, and pruning.
#>
[CmdletBinding()]
param()

function Get-GitWorktrees ([string]$dir) {
    Push-Location $dir
    try {
        $raw = git worktree list 2>$null
        $list = @()
        if ($raw) {
            foreach ($line in $raw) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = -split $line
                if ($parts.Length -ge 2) {
                    $wtPath = $parts[0]
                    $head = $parts[1]
                    $branch = if ($parts.Length -ge 3) { ($parts[2..($parts.Length - 1)] -join " ").Trim('[]') } else { "" }
                    $list += [PSCustomObject]@{
                        Path   = $wtPath
                        Head   = $head
                        Branch = $branch
                        Raw    = $line
                    }
                }
            }
        }
        return $list
    } finally {
        Pop-Location
    }
}

function Add-GitWorktree ([string]$dir, [string]$branch, [string]$targetPath) {
    Push-Location $dir
    try {
        $branchExists = (git branch --list $branch 2>$null)
        if ($branchExists) {
            git worktree add $targetPath $branch
        } else {
            git worktree add -b $branch $targetPath
        }
        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
    }
}

function Remove-GitWorktree ([string]$dir, [string]$worktreePath) {
    Push-Location $dir
    try {
        git worktree remove $worktreePath
        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
    }
}

function Prune-GitWorktrees ([string]$dir) {
    Push-Location $dir
    try {
        git worktree prune -v
        return ($LASTEXITCODE -eq 0)
    } finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Get-GitWorktrees, Add-GitWorktree, Remove-GitWorktree, Prune-GitWorktrees
