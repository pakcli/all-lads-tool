<#
.SYNOPSIS
    Git Adapter for Git 2.40.0+ (Modern)
.DESCRIPTION
    Implements environment validation and advanced Git features for Git 2.40+.
#>

function Test-GitEnvironment {
    param()
    $gitCmd = Get-Command "git.exe" -ErrorAction SilentlyContinue
    if (-not $gitCmd) { return $false }
    $verStr = (git --version) -replace '[^\d.]', ''
    Write-Host "[ADAPTER v02-40-00] Detected Git version: $verStr (Modern 2.40+ Features Active)" -ForegroundColor DarkCyan
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
    $curr = (git -C $RepoPath branch --show-current 2>$null)
    if (-not $curr) {
        $curr = (git -C $RepoPath symbolic-ref --short HEAD 2>$null)
    }
    if ($curr) { $curr = $curr.Trim() } else { $curr = "HEAD" }
    Write-Host "[ADAPTER v02-40-00] Renaming branch '$curr' -> '$NewBranch'..." -ForegroundColor Cyan
    git -C $RepoPath branch -m $NewBranch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Local branch renamed to '$NewBranch'." -ForegroundColor Green
    }
}

function Invoke-GitClone {
    param(
        [Parameter(Mandatory)] [string]$Url,
        [Parameter(Mandatory)] [string]$DestinationPath,
        [string]$Branch = "",
        [int]$Depth = 0
    )
    $argsList = [System.Collections.Generic.List[string]]::new()
    $argsList.Add("clone")
    if ($Branch) {
        $argsList.Add("--branch")
        $argsList.Add($Branch)
    }
    if ($Depth -gt 0) {
        $argsList.Add("--depth")
        $argsList.Add("$Depth")
    }
    $argsList.Add($Url)
    $argsList.Add($DestinationPath)

    Write-Host "[ADAPTER v02-40-00] Executing: git $($argsList -join ' ')" -ForegroundColor DarkCyan
    & git @argsList
    return ($LASTEXITCODE -eq 0)
}

Export-ModuleMember -Function Test-GitEnvironment, Invoke-GitStatus, Invoke-GitBranchRename, Invoke-GitClone
