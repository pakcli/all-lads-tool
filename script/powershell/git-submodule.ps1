<#
.SYNOPSIS
    Vintage Computing Arcade - Git Submodule Manager (Modular Edition)
.DESCRIPTION
    Modular submodule management tool wired directly to module/git-submodule.psm1.
    Imports:
      - module/git-submodule.psm1
      - module/git-core.psm1
      - module/history.psm1
.PARAMETER Action
    Action to perform: 'add', 'update', 'sync', 'status', 'list', 'remove', 'interactive'
.PARAMETER Url
    Remote repository URL to clone as submodule
.PARAMETER Path
    Target path relative to repo root
.PARAMETER Branch
    Optional branch to track
.PARAMETER Force
    Force operation
#>

[CmdletBinding()]
param (
    [ValidateSet("add", "update", "sync", "status", "list", "remove", "interactive", "")]
    [string]$Action = "",

    [string]$Url = "",
    [string]$Path = "",
    [string]$Branch = "",
    [switch]$Force,
    [switch]$Help
)

# ------------------------------------------------------------------------------
# 1. WIRE UP INTERNAL MODULES
# ------------------------------------------------------------------------------
Import-Module "$PSScriptRoot\module\git-core.psm1" -Force
Import-Module "$PSScriptRoot\module\git-submodule.psm1" -Force
Import-Module "$PSScriptRoot\module\history.psm1" -Force

$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
if ($Path -and (Test-Path -LiteralPath $Path) -and (Test-Path -LiteralPath "$Path\.git")) {
    $repoRoot = (Resolve-Path -LiteralPath $Path).Path
}

function Show-Header {
    param ([string]$title)
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Show-InteractiveHub {
    while ($true) {
        $subs = Get-SubmoduleList -RepoPath $repoRoot
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "   GIT SUBMODULE HUB (MODULAR)  ::  all-lads-tool         " -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host " Target Repository : $repoRoot" -ForegroundColor Yellow
        Write-Host " Module Source     : module/git-submodule.psm1" -ForegroundColor DarkGray
        Write-Host " Registered Count  : $($subs.Count)" -ForegroundColor Gray
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        if ($subs.Count -gt 0) {
            Write-Host " Detected Submodules:" -ForegroundColor Green
            foreach ($s in $subs) {
                Write-Host ("   [{0}] {1}  ({2})" -f $s.Index, $s.Path, $s.Hash) -ForegroundColor White
            }
        } else {
            Write-Host "   (No submodules currently registered)" -ForegroundColor DarkGray
        }
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " Actions:" -ForegroundColor White
        Write-Host "  [<Git URL>]        : Paste Git URL to add submodule (auto folder extraction)" -ForegroundColor Green
        Write-Host "  [-<index>]         : Negative index to remove (e.g. -1, -2)" -ForegroundColor Red
        Write-Host "  [<index>]          : Positive index to sync/update (e.g. 1, 2)" -ForegroundColor Cyan
        Write-Host "  [all]              : Sync / update all submodules" -ForegroundColor Cyan
        Write-Host "  [1] Add Submodule  : Add submodule interactively" -ForegroundColor White
        Write-Host "  [2] Update All     : Update all submodules" -ForegroundColor White
        Write-Host "  [3] Status & List  : Show verbose git submodule status" -ForegroundColor White
        Write-Host "  [4] Sync URLs      : Sync submodule URLs" -ForegroundColor White
        Write-Host "  [5] Remove Submod  : Remove a submodule by path" -ForegroundColor White
        Write-Host "  [Q] Quit / Back    : Return to previous menu" -ForegroundColor DarkGray
        Write-Host "==========================================================" -ForegroundColor Cyan

        $choice = (Read-Host "Select [1-5, URL, -index, Q]").Trim()
        if ([string]::IsNullOrWhiteSpace($choice)) { return }

        if ($choice -match '^-(?<delIdx>\d+)$') {
            $num = [int]$Matches['delIdx']
            $targetSub = $subs | Where-Object { $_.Index -eq $num }
            if ($targetSub) {
                Write-Host "Removing submodule '$($targetSub.Path)'..." -ForegroundColor Yellow
                Remove-SubmoduleItem -RepoPath $repoRoot -SubPath $targetSub.Path
                Write-Host "Removed." -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Submodule index -$num not found in list." -ForegroundColor Red
            }
            continue
        }

        if ($choice -match '^(https?://|git@)') {
            $derivedName = ($choice.TrimEnd('/') -split '/')[-1] -replace '\.git$', ''
            $targetDest = "submodules/$derivedName"
            Write-Host "Adding submodule '$derivedName' into $targetDest..." -ForegroundColor Cyan
            Add-SubmoduleItem -RepoPath $repoRoot -Url $choice -Destination $targetDest
            continue
        }

        if ($choice -match '^(?<syncIdx>\d+)$') {
            $num = [int]$Matches['syncIdx']
            if ($num -ge 1 -and $num -le 5 -and ($subs.Count -eq 0 -or -not ($subs | Where-Object { $_.Index -eq $num }))) {
                # Fall through to menu switch
            } elseif ($subs | Where-Object { $_.Index -eq $num }) {
                $targetSub = $subs | Where-Object { $_.Index -eq $num }
                Write-Host "Updating submodule '$($targetSub.Path)'..." -ForegroundColor Cyan
                Sync-SubmoduleItem -RepoPath $repoRoot -SubPath $targetSub.Path
                continue
            }
        }

        switch ($choice.ToUpper()) {
            "1" {
                $urlInput = Read-Host "Enter Git Repository URL"
                if ($urlInput) {
                    $derivedName = ($urlInput.TrimEnd('/') -split '/')[-1] -replace '\.git$', ''
                    $destInput = Read-Host "Enter destination path [default: submodules/$derivedName]"
                    if (-not $destInput) { $destInput = "submodules/$derivedName" }
                    Add-SubmoduleItem -RepoPath $repoRoot -Url $urlInput -Destination $destInput
                }
            }
            "2" {
                Write-Host "Updating all submodules..." -ForegroundColor Cyan
                Sync-SubmoduleItem -RepoPath $repoRoot
            }
            "ALL" {
                Write-Host "Updating all submodules..." -ForegroundColor Cyan
                Sync-SubmoduleItem -RepoPath $repoRoot
            }
            "3" {
                Show-Header "GIT SUBMODULE STATUS"
                Invoke-GitCommand -RepoPath $repoRoot -Arguments @("submodule", "status")
                Pause
            }
            "4" {
                Show-Header "SYNCING SUBMODULE URLS"
                Invoke-GitCommand -RepoPath $repoRoot -Arguments @("submodule", "sync", "--recursive")
                Sync-SubmoduleItem -RepoPath $repoRoot
                Pause
            }
            "5" {
                $pathInput = Read-Host "Enter submodule relative path to remove"
                if ($pathInput) {
                    Remove-SubmoduleItem -RepoPath $repoRoot -SubPath $pathInput
                }
            }
            "Q" { return }
            default { Write-Host "Invalid option. Type 1-5, URL, -index, or Q." -ForegroundColor Yellow }
        }
    }
}

# --- Execution Router ---
switch ($Action.ToLower()) {
    "add" {
        if (-not $Path) {
            $derivedName = ($Url.TrimEnd('/') -split '/')[-1] -replace '\.git$', ''
            $Path = "submodules/$derivedName"
        }
        Add-SubmoduleItem -RepoPath $repoRoot -Url $Url -Destination $Path
    }
    "update" {
        Sync-SubmoduleItem -RepoPath $repoRoot -SubPath $Path
    }
    "status" {
        Invoke-GitCommand -RepoPath $repoRoot -Arguments @("submodule", "status")
    }
    "list" {
        Get-SubmoduleList -RepoPath $repoRoot
    }
    "sync" {
        Invoke-GitCommand -RepoPath $repoRoot -Arguments @("submodule", "sync", "--recursive")
        Sync-SubmoduleItem -RepoPath $repoRoot
    }
    "remove" {
        Remove-SubmoduleItem -RepoPath $repoRoot -SubPath $Path
    }
    "interactive" {
        Show-InteractiveHub
    }
    default {
        if ($Url) {
            if (-not $Path) {
                $derivedName = ($Url.TrimEnd('/') -split '/')[-1] -replace '\.git$', ''
                $Path = "submodules/$derivedName"
            }
            Add-SubmoduleItem -RepoPath $repoRoot -Url $Url -Destination $Path
        } else {
            Show-InteractiveHub
        }
    }
}
