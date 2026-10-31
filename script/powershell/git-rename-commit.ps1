<#
.SYNOPSIS
    Universal Git Commit Renamer (Modular Edition).
.DESCRIPTION
    Safely renames commit messages locally (HEAD or historical commits) using plumbing operations,
    and provides optional synchronized push to remote hosting (GitHub, GitLab) using --force-with-lease.
.PARAMETER TargetDir
    Target Git repository directory (default: current directory).
.PARAMETER CommitHash
    Specific commit hash to rename (default: interactive prompt or HEAD).
.PARAMETER NewMessage
    New commit message.
.PARAMETER PushRemote
    When specified, pushes the rewritten history to the remote provider with lease.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$CommitHash = "",

    [Parameter(Position = 2)]
    [string]$NewMessage = "",

    [switch]$PushRemote
)

$scriptDir = $PSScriptRoot
$modulePath = Join-Path $scriptDir "module\git-commitrenamer.psm1"

if (-not (Test-Path -LiteralPath $modulePath)) {
    Write-Error "Required module not found: $modulePath"
    exit 1
}

Import-Module -Name $modulePath -Force

# Resolve target directory
$resolvedTarget = if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    (Get-Location).Path
} elseif ([System.IO.Path]::IsPathRooted($TargetDir)) {
    $TargetDir
} else {
    Join-Path (Get-Location).Path $TargetDir
}

if (-not (Test-Path -LiteralPath $resolvedTarget)) {
    Write-Error "Target directory does not exist: $resolvedTarget"
    exit 1
}

$resolvedTarget = (Resolve-Path -LiteralPath $resolvedTarget).Path

# Verify git repo
$isGit = git -C $resolvedTarget rev-parse --is-inside-work-tree 2>$null
if ($isGit -ne "true") {
    Write-Error "Directory is not a Git repository: $resolvedTarget"
    exit 1
}

$remoteInfo = Get-GitRemoteHosting -RepoPath $resolvedTarget

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "   GIT COMMIT RENAMER (MODULAR)                                         " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " Target Directory : $resolvedTarget" -ForegroundColor White
Write-Host " Active Branch    : $($remoteInfo.Branch)" -ForegroundColor White
Write-Host " Remote Host      : $($remoteInfo.Provider) ($($remoteInfo.RemoteName) -> $($remoteInfo.RemoteUrl))" -ForegroundColor $(if ($remoteInfo.HasRemote) { "Green" } else { "DarkGray" })
Write-Host " Module           : module/git-commitrenamer.psm1" -ForegroundColor DarkGray
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# Non-interactive execution if both CommitHash and NewMessage are provided
if ($CommitHash -and $NewMessage) {
    try {
        Write-Host "Renaming commit '$CommitHash'..." -ForegroundColor Cyan
        $newHead = Rename-HistoricalCommit -RepoPath $resolvedTarget -CommitHash $CommitHash -NewMessage $NewMessage
        Write-Host "[OK] Commit renamed. New HEAD: $newHead" -ForegroundColor Green

        if ($PushRemote) {
            if (-not $remoteInfo.HasRemote) {
                Write-Host "[WARN] No remote repository configured to push." -ForegroundColor Yellow
            } else {
                Write-Host "Pushing to $($remoteInfo.Provider) with lease..." -ForegroundColor Cyan
                $pushRes = Push-ToRemoteWithLease -RepoPath $resolvedTarget -RemoteName $remoteInfo.RemoteName -Branch $remoteInfo.Branch
                if ($pushRes.Success) {
                    Write-Host "[OK] Successfully pushed to $($remoteInfo.Provider) ($($remoteInfo.Branch))." -ForegroundColor Green
                } else {
                    Write-Host "[ERROR] Push failed: $($pushRes.Output)" -ForegroundColor Red
                }
            }
        }
    } catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# Interactive Mode
$commits = Get-RecentCommits -RepoPath $resolvedTarget -Limit 10
if ($commits.Count -eq 0) {
    Write-Host "No commits found in repository." -ForegroundColor Yellow
    exit 0
}

Write-Host "Recent Commits in Branch '$($remoteInfo.Branch)':" -ForegroundColor White
foreach ($c in $commits) {
    $tag = if ($c.IsHead) { "[HEAD] " } else { "       " }
    Write-Host "  [$($c.Index)] $tag$($c.ShortHash) ($($c.Date)) : $($c.Subject)" -ForegroundColor $(if ($c.IsHead) { "Yellow" } else { "White" })
}
Write-Host ""

$selection = Read-Host "Select commit to rename [1-$($commits.Count), or commit hash] [Default: 1]"
if ([string]::IsNullOrWhiteSpace($selection)) { $selection = "1" }
$selection = $selection.Trim()

$selectedCommit = $null
if ($selection -match '^\d+$') {
    $idx = [int]$selection
    $selectedCommit = $commits | Where-Object { $_.Index -eq $idx }
} else {
    $selectedCommit = $commits | Where-Object { $_.ShortHash -eq $selection -or $_.FullHash -eq $selection }
    if (-not $selectedCommit) {
        # Check rev-parse
        $full = git -C $resolvedTarget rev-parse --verify "$selection^{commit}" 2>$null
        if ($full) {
            $subj = (git -C $resolvedTarget log -1 --format="%s" $full).Trim()
            $selectedCommit = [PSCustomObject]@{ FullHash = $full.Trim(); ShortHash = $full.Substring(0, 7); Subject = $subj; IsHead = $false }
        }
    }
}

if (-not $selectedCommit) {
    Write-Host "Invalid commit selection." -ForegroundColor Red
    exit 1
}

Write-Host "`nSelected: $($selectedCommit.ShortHash) - '$($selectedCommit.Subject)'" -ForegroundColor Cyan
$newMsgInput = Read-Host "Enter new commit message"
if ([string]::IsNullOrWhiteSpace($newMsgInput)) {
    Write-Host "Aborted: Message cannot be empty." -ForegroundColor Yellow
    exit 0
}

try {
    Write-Host "`nApplying commit rename locally..." -ForegroundColor Cyan
    $newHead = Rename-HistoricalCommit -RepoPath $resolvedTarget -CommitHash $selectedCommit.FullHash -NewMessage $newMsgInput
    Write-Host "[OK] Commit renamed successfully locally. New HEAD: $newHead" -ForegroundColor Green

    Write-Host "`nUpdated Commit Log:" -ForegroundColor White
    git -C $resolvedTarget log -n 5 --oneline
    Write-Host ""

    # Remote Push Prompt
    if ($remoteInfo.HasRemote) {
        Write-Host "Remote detected: $($remoteInfo.Provider) ($($remoteInfo.RemoteName) -> $($remoteInfo.RemoteUrl))" -ForegroundColor Cyan
        Write-Host "Pushing rewritten history requires --force-with-lease on branch '$($remoteInfo.Branch)'." -ForegroundColor Yellow
        $pushConfirm = Read-Host "Push changes to $($remoteInfo.Provider)? [y/N]"
        if ($pushConfirm -match '^(y|yes)$') {
            Write-Host "Pushing to $($remoteInfo.Provider)..." -ForegroundColor Cyan
            $pushRes = Push-ToRemoteWithLease -RepoPath $resolvedTarget -RemoteName $remoteInfo.RemoteName -Branch $remoteInfo.Branch
            if ($pushRes.Success) {
                Write-Host "[OK] Remote successfully updated on $($remoteInfo.Provider)!" -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Remote push failed: $($pushRes.Output)" -ForegroundColor Red
            }
        } else {
            Write-Host "Remote push skipped. Changes remain local." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "No remote configured. Changes remain local." -ForegroundColor DarkGray
    }
} catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
