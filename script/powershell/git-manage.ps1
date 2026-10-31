<#
.SYNOPSIS
    Universal Git Manager & Recovery Tool (Modular Edition).
.DESCRIPTION
    Modular interactive Git management tool wired directly to module/* libraries.
    Imports:
      - module/git-status.psm1 (Live dashboard & status queries)
      - module/git-reflog.psm1    (Reflog parsing & surgical commit recovery)
      - module/git-submodule.psm1 (Submodule automation engine)
      - module/git-core.psm1   (Process execution engine)
      - module/history.psm1   (Infinite counter JSON state tracker)
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$Action = ""
)

# ------------------------------------------------------------------------------
# 1. WIRE UP INTERNAL MODULES
# ------------------------------------------------------------------------------
Import-Module "$PSScriptRoot\module\git-core.psm1" -Force
Import-Module "$PSScriptRoot\module\git-status.psm1" -Force
Import-Module "$PSScriptRoot\module\git-reflog.psm1" -Force
Import-Module "$PSScriptRoot\module\git-submodule.psm1" -Force
Import-Module "$PSScriptRoot\module\history.psm1" -Force

$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path

function Normalize-InputPath ([string]$rawPath) {
    if ([string]::IsNullOrWhiteSpace($rawPath)) { return "" }
    $clean = $rawPath.Trim().Trim('"').Trim("'")
    if ([System.IO.Path]::IsPathRooted($clean)) {
        if (Test-Path $clean) { return (Resolve-Path $clean).Path }
        return $clean
    } else {
        $resolved = Join-Path $repoRoot $clean
        if (Test-Path $resolved) { return (Resolve-Path $resolved).Path }
        return $resolved
    }
}

function Read-PromptDefault {
    param([string]$Prompt, [string]$Default = "")
    $suffix = if ($Default) { " [Default: $Default]: " } else { ": " }
    Write-Host "$Prompt$suffix" -NoNewline -ForegroundColor White
    $inputVal = [Console]::ReadLine()
    if ([string]::IsNullOrWhiteSpace($inputVal)) { return $Default }
    return $inputVal.Trim().Trim('"').Trim("'")
}

# Resolve active target directory
$currentTarget = if ([string]::IsNullOrWhiteSpace($TargetDir)) { $repoRoot } else { Normalize-InputPath $TargetDir }
if (-not (Test-Path $currentTarget)) { $currentTarget = $repoRoot }

$Host.UI.RawUI.WindowTitle = "Git Manager (Modular) :: all-lads-tool"

function Invoke-ModularCommit ([string]$dir) {
    Write-Host "`n=== [2] COMMIT ===" -ForegroundColor Cyan
    $statusOut = Invoke-GitCommand -RepoPath $dir -Arguments @("status", "-s")
    if (-not $statusOut) {
        Write-Host "Working tree is clean. Nothing to commit." -ForegroundColor Green
        return
    }

    Write-Host "Current Status:" -ForegroundColor Yellow
    foreach ($line in ($statusOut -split "`r?`n")) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            Write-Host "  $line" -ForegroundColor Yellow
        }
    }

    Write-Host "`nStaging Options:" -ForegroundColor Cyan
    Write-Host "  [1] Stage all changes (git add -A) [Default]"
    Write-Host "  [2] Cancel"
    $stageOpt = Read-PromptDefault -Prompt "Select staging option" -Default "1"
    if ($stageOpt -eq "1") {
        Invoke-GitCommand -RepoPath $dir -Arguments @("add", "-A")
        Write-Host "[OK] All changes staged." -ForegroundColor Green
    } else {
        Write-Host "Commit cancelled." -ForegroundColor DarkGray
        return
    }

    $msg = Read-PromptDefault -Prompt "Enter commit message (e.g. feat: add something)" -Default ""
    if ([string]::IsNullOrWhiteSpace($msg)) {
        Write-Host "Commit message cannot be empty. Aborted." -ForegroundColor Red
        return
    }

    Invoke-GitCommand -RepoPath $dir -Arguments @("commit", "-m", $msg)
    Write-Host "[OK] Commit created successfully!" -ForegroundColor Green
}

function Invoke-ModularPush ([string]$dir) {
    Write-Host "`n=== [3] PUSH ===" -ForegroundColor Cyan
    $branch = Invoke-GitCommand -RepoPath $dir -Arguments @("branch", "--show-current")
    if ([string]::IsNullOrWhiteSpace($branch)) {
        Write-Host "Cannot push in detached HEAD state." -ForegroundColor Red
        return
    }
    $branch = $branch.Trim()
    Write-Host "Pushing active branch '$branch' to origin..." -ForegroundColor Cyan
    Invoke-GitCommand -RepoPath $dir -Arguments @("push", "--set-upstream", "origin", $branch)
    Write-Host "[OK] Push executed." -ForegroundColor Green
}

function Invoke-ModularPull ([string]$dir) {
    Write-Host "`n=== [4] PULL / SYNC ===" -ForegroundColor Cyan
    Write-Host "Pulling updates with linear rebase..." -ForegroundColor Cyan
    Invoke-GitCommand -RepoPath $dir -Arguments @("pull", "--rebase")
    Write-Host "[OK] Sync complete." -ForegroundColor Green
}

function Invoke-ModularDiscard ([string]$dir) {
    Write-Host "`n=== [-1] DISCARD ALL CHANGES ===" -ForegroundColor Red
    Write-Host "Type 'DISCARD' to confirm rolling back all uncommitted changes: " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    if ($confirm -eq "DISCARD") {
        Invoke-GitCommand -RepoPath $dir -Arguments @("restore", ".")
        Invoke-GitCommand -RepoPath $dir -Arguments @("clean", "-fd")
        Write-Host "[OK] Working tree clean." -ForegroundColor Green
    } else {
        Write-Host "Discard cancelled." -ForegroundColor DarkGray
    }
}

while ($true) {
    $summary = Get-GitStatusSummary $currentTarget
    $statusText = if ($summary.IsRepo) {
        "INITIALIZED (Branch: $($summary.Branch)) | Remotes: $($summary.Remote) | Dirty Files: $($summary.DirtyCount)"
    } else {
        "NOT A GIT REPO"
    }

    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   UNIVERSAL GIT MANAGER (MODULAR EDITION)  ::  all-lads-tool" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " Target Directory : $currentTarget" -ForegroundColor White
    Write-Host " Git Status       : $statusText" -ForegroundColor $(if ($summary.IsRepo) { "Green" } else { "Yellow" })
    Write-Host " Mode             : Modular (Connected to module/*)" -ForegroundColor DarkGray
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [-1 ]  Discard All   : Rollback uncommitted changes safely" -ForegroundColor Red
    Write-Host "  [ 0 ]  Status        : Dashboard (branch, remotes, status, recent log)" -ForegroundColor White
    Write-Host "  [ 1 ]  Recover       : Reflog browser (module/git-reflog.psm1)" -ForegroundColor Yellow
    Write-Host "  [ 2 ]  Commit        : Git status staging & commit message" -ForegroundColor Green
    Write-Host "  [ 3 ]  Push          : Push branch to remote with upstream tracking" -ForegroundColor Green
    Write-Host "  [ 4 ]  Pull / Sync   : Smart pull (Rebase)" -ForegroundColor Cyan
    Write-Host "  [ 11]  Submodule     : Manage git submodules (module/git-submodule.psm1)" -ForegroundColor Green
    Write-Host ""
    Write-Host " ----------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ t ]  Target Dir    : Ganti target (Root, apps/<cartridge>, Custom)" -ForegroundColor Gray
    Write-Host "  [ q ]  Quit          : Keluar" -ForegroundColor Gray
    Write-Host "========================================================================" -ForegroundColor Cyan

    $choice = Read-Host "Select option [-1, 0-4, 11, t, q] [Default: 0]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "0" }
    $choice = $choice.Trim()

    switch ($choice) {
        "-1" {
            Invoke-ModularDiscard $currentTarget
            Pause
        }
        "0" {
            Write-Host "`n=== [0] LIVE STATUS DASHBOARD ===" -ForegroundColor Cyan
            Write-Host "Active Branch: $($summary.Branch)" -ForegroundColor Yellow
            Write-Host "Dirty Files  : $($summary.DirtyCount) (~$($summary.TotalDirtyKb) KB)" -ForegroundColor Yellow
            if ($summary.RecentLog) {
                Write-Host "`nRecent Commit History:" -ForegroundColor Green
                foreach ($c in $summary.RecentLog) {
                    Write-Host "  $($c.Hash) ($($c.Time)) - $($c.Msg)" -ForegroundColor Gray
                }
            }
            Write-Host "`nUncommitted Changes:" -ForegroundColor Green
            if ($summary.Uncommitted) {
                foreach ($l in $summary.Uncommitted) { Write-Host "  $l" -ForegroundColor Yellow }
            } else {
                Write-Host "  Working tree clean." -ForegroundColor DarkGray
            }
            Pause
        }
        "1" {
            Write-Host "`n=== [1] REFLOG COMMITS (Via module/git-reflog.psm1) ===" -ForegroundColor Cyan
            $reflogList = Get-ReflogCommits -dir $currentTarget -maxCount 15
            for ($i = 0; $i -lt $reflogList.Count; $i++) {
                $c = $reflogList[$i]
                $tag = if ($c.IsLost) { "[LOST]  " } else { "[BRANCH]" }
                Write-Host "[$i] $($c.Hash) $($c.Time) $tag $($c.Msg)" -ForegroundColor $(if ($c.IsLost) { "Yellow" } else { "White" })
            }
            Pause
        }
        "2" {
            Invoke-ModularCommit $currentTarget
            Pause
        }
        "3" {
            Invoke-ModularPush $currentTarget
            Pause
        }
        "4" {
            Invoke-ModularPull $currentTarget
            Pause
        }
        "11" {
            $subRunner = Join-Path $scriptDir "git-submodule.ps1"
            if (-not (Test-Path $subRunner)) { $subRunner = Join-Path $scriptDir "git-submodule_stand.ps1" }
            & $subRunner -Action "interactive" -Path $currentTarget
        }
        "t" {
            $inputTarget = Read-Host "Enter new target path or drag & drop folder"
            if ($inputTarget) { $currentTarget = Normalize-InputPath $inputTarget }
        }
        "q" {
            Write-Host "Exiting modular Git Manager." -ForegroundColor DarkGray
            break
        }
        default {
            $cleanDropped = Normalize-InputPath $choice
            if (Test-Path $cleanDropped) {
                $currentTarget = if (Test-Path $cleanDropped -PathType Container) { $cleanDropped } else { Split-Path $cleanDropped }
                Write-Host "Switched to: $currentTarget" -ForegroundColor Green
            }
        }
    }
}
