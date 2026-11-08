<#
.SYNOPSIS
    Git Lost / Detached Commit Recovery Tool (Context: Repo)
.DESCRIPTION
    Lists recent commits from git reflog (including orphaned/detached commits),
    allows inspection of lost commit contents, and restores files or checks out
    commits cleanly without data loss.
    Wired directly to adapter/git-reflog.psm1.
.PARAMETER TargetDir
    Target Git repository directory (default: current working directory).
.PARAMETER CommitHash
    Specific commit SHA to inspect or recover.
.PARAMETER MaxCount
    Number of reflog entries to display (default: 20).
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$CommitHash = "",

    [int]$MaxCount = 20
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

$adapterPath = Join-Path $scriptDir "adapter\git-reflog.psm1"
if (-not (Test-Path -LiteralPath $adapterPath)) {
    Write-Error "[ERROR] Required adapter module not found at: $adapterPath"
    exit 1
}
Import-Module -Name $adapterPath -Force

$repo = if ([string]::IsNullOrWhiteSpace($TargetDir)) { (Get-Location).Path } else { $TargetDir }
if (-not (Test-Path -LiteralPath $repo)) {
    Write-Error "[ERROR] Target directory does not exist: $repo"
    exit 1
}
$repo = (Resolve-Path -LiteralPath $repo).Path

if ((git -C $repo rev-parse --is-inside-work-tree 2>$null) -ne "true") {
    Write-Error "[ERROR] Directory is not a Git repository: $repo"
    exit 1
}

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "   GIT REFLOG RECOVERY TOOL (CONTEXT: REPO)                             " -ForegroundColor Yellow
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " Target Repository : $repo" -ForegroundColor White
Write-Host " Adapter           : adapter/git-reflog.psm1" -ForegroundColor DarkGray
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

$reflogEntries = Get-ReflogCommits -dir $repo -maxCount $MaxCount
if (-not $reflogEntries -or $reflogEntries.Count -eq 0) {
    Write-Host "[INFO] No reflog entries found in repository '$repo'." -ForegroundColor Yellow
    exit 0
}

Write-Host "Recent Git Reflog Timeline (including detached/lost commits):" -ForegroundColor Green
Write-Host ("{0,-4} | {1,-8} | {2,-16} | {3,-12} | {4}" -f "No", "Hash", "Reference", "Time", "Message") -ForegroundColor Gray
Write-Host ("-" * 72) -ForegroundColor DarkGray

$i = 0
foreach ($entry in $reflogEntries) {
    $lostMarker = if ($entry.IsLost) { "[LOST]" } else { "      " }
    Write-Host ("{0,-4} | {1,-8} | {2,-16} | {3,-12} | {4} {5}" -f $i, $entry.Hash, $entry.Ref, $entry.Time, $lostMarker, $entry.Msg) -ForegroundColor $(if ($entry.IsLost) { "Yellow" } else { "White" })
    $i++
}
Write-Host ""

$selectedHash = $CommitHash
if ([string]::IsNullOrWhiteSpace($selectedHash)) {
    $inputVal = Read-Host "Enter index number [0..$($reflogEntries.Count - 1)] or commit hash to inspect (or 'q' to quit)"
    if ([string]::IsNullOrWhiteSpace($inputVal) -or $inputVal -ieq "q") {
        Write-Host "Operation cancelled by user." -ForegroundColor Gray
        exit 0
    }

    $idx = 0
    if ([int]::TryParse($inputVal.Trim(), [ref]$idx) -and $idx -ge 0 -and $idx -lt $reflogEntries.Count) {
        $selectedHash = $reflogEntries[$idx].Hash
    } else {
        $selectedHash = $inputVal.Trim()
    }
}

Write-Host "`nInspecting commit '$selectedHash'..." -ForegroundColor Cyan
git -C $repo show --stat $selectedHash

Write-Host ""
Write-Host "Recovery Options:" -ForegroundColor Yellow
Write-Host "  [1] Checkout commit in detached HEAD mode (git checkout $selectedHash)" -ForegroundColor White
Write-Host "  [2] Create a new branch at this commit (git branch <branch-name> $selectedHash)" -ForegroundColor White
Write-Host "  [3] Restore specific file from this commit into working tree" -ForegroundColor White
Write-Host "  [q] Cancel and return" -ForegroundColor Gray
Write-Host ""

$opt = Read-Host "Select recovery action [1 / 2 / 3 / q] [Default: 1]"
if ([string]::IsNullOrWhiteSpace($opt)) { $opt = "1" }

switch ($opt.Trim()) {
    "1" {
        Write-Host "Checking out commit '$selectedHash' in detached mode..." -ForegroundColor Cyan
        git -C $repo checkout $selectedHash
        Write-Host "[OK] Checked out $selectedHash. Use 'git checkout -b <branch>' if you want to keep changes." -ForegroundColor Green
    }
    "2" {
        $branchName = Read-Host "Enter new branch name for recovered commit"
        if (-not [string]::IsNullOrWhiteSpace($branchName)) {
            git -C $repo branch $branchName.Trim() $selectedHash
            Write-Host "[OK] Created branch '$branchName' at commit $selectedHash." -ForegroundColor Green
            $switchNow = Read-Host "Switch to '$branchName' now? [y/N]"
            if ($switchNow -match '^[Yy]$') {
                git -C $repo checkout $branchName.Trim()
            }
        }
    }
    "3" {
        $relFile = Read-Host "Enter relative file path to restore (e.g. src/index.html)"
        if (-not [string]::IsNullOrWhiteSpace($relFile)) {
            $success = Restore-ReflogCommitFiles -dir $repo -commitHash $selectedHash -files @($relFile.Trim())
            if ($success) {
                Write-Host "[OK] File '$relFile' restored from commit $selectedHash." -ForegroundColor Green
            } else {
                Write-Host "[FAIL] Could not restore '$relFile' from commit $selectedHash." -ForegroundColor Red
            }
        }
    }
    default {
        Write-Host "Recovery operation cancelled." -ForegroundColor Gray
    }
}
