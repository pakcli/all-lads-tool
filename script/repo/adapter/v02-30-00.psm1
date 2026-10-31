<#
.SYNOPSIS
    Git Adapter for Git 2.30.0+ (Base LTS)
.DESCRIPTION
    Implements environment validation and core Git commands for Git 2.30+ LTS.
#>

function Test-GitEnvironment {
    param()
    $gitCmd = Get-Command "git.exe" -ErrorAction SilentlyContinue
    if (-not $gitCmd) { return $false }
    $verStr = (git --version) -replace '[^\d.]', ''
    Write-Host "[ADAPTER v02-30-00] Detected Git version: $verStr" -ForegroundColor DarkCyan
    return $true
}

function Invoke-GitStatus {
    param([string]$RepoPath = (Get-Location).Path)
    git -C $RepoPath status -s
}

function Invoke-GitBranchRename {
    param(
        [Parameter(Mandatory)]
        [string]$NewBranch,
        [string]$RepoPath = (Get-Location).Path,
        [string]$Remote = "origin"
    )
    $curr = (git -C $RepoPath rev-parse --abbrev-ref HEAD).Trim()
    Write-Host "[ADAPTER v02-30-00] Renaming branch '$curr' -> '$NewBranch'..." -ForegroundColor Cyan
    git -C $RepoPath branch -m $curr $NewBranch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Local branch renamed to '$NewBranch'." -ForegroundColor Green
    }
}

Export-ModuleMember -Function Test-GitEnvironment, Invoke-GitStatus, Invoke-GitBranchRename
