<#
.SYNOPSIS
    Universal Git Commit Renamer (Standalone Edition).
.DESCRIPTION
    Self-contained executable to rename commit messages locally and synchronize
    with remote hosting (GitHub, GitLab) using --force-with-lease.
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

# ------------------------------------------------------------------------------
# INLINED MODULE LOGIC (commitrenamer)
# ------------------------------------------------------------------------------
function Get-RecentCommits {
    param([string]$RepoPath, [int]$Limit = 15)
    $raw = git -C $RepoPath log -n $Limit --pretty=format:"%H|%h|%s|%an|%cr" 2>$null
    $commits = [System.Collections.Generic.List[PSCustomObject]]::new()
    if ($raw) {
        $idx = 1
        foreach ($line in ($raw -split "`r?`n")) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $p = $line -split "\|", 5
                if ($p.Length -ge 5) {
                    $commits.Add([PSCustomObject]@{
                        Index      = $idx
                        FullHash   = $p[0]
                        ShortHash  = $p[1]
                        Subject    = $p[2]
                        Author     = $p[3]
                        Date       = $p[4]
                        IsHead     = ($idx -eq 1)
                    })
                    $idx++
                }
            }
        }
    }
    return $commits
}

function Get-GitRemoteHosting {
    param([string]$RepoPath)
    $branch = (git -C $RepoPath branch --show-current 2>$null).Trim()
    $remoteOut = git -C $RepoPath remote -v 2>$null
    $remoteName = "origin"
    $remoteUrl = ""
    $provider = "Local Only"

    if ($remoteOut) {
        $firstLine = ($remoteOut -split "`r?`n")[0]
        if ($firstLine -match '^(\S+)\s+(\S+)\s+\((?:fetch|push)\)$') {
            $remoteName = $matches[1]
            $remoteUrl  = $matches[2]
        }

        if ($remoteUrl -match 'github\.com') {
            $provider = "GitHub"
        } elseif ($remoteUrl -match 'gitlab\.com') {
            $provider = "GitLab"
        } elseif ($remoteUrl -match 'bitbucket\.org') {
            $provider = "Bitbucket"
        } elseif (-not [string]::IsNullOrWhiteSpace($remoteUrl)) {
            $provider = "Custom Git Remote"
        }
    }

    return [PSCustomObject]@{
        Provider   = $provider
        RemoteName = $remoteName
        RemoteUrl  = $remoteUrl
        Branch     = $branch
        HasRemote  = (-not [string]::IsNullOrWhiteSpace($remoteUrl))
    }
}

function Rename-HeadCommit {
    param([string]$RepoPath, [string]$NewMessage)
    $cleanMsg = $NewMessage.Trim()
    if ([string]::IsNullOrWhiteSpace($cleanMsg)) { throw "Commit message cannot be empty." }
    git -C $RepoPath commit --amend -m $cleanMsg
    if ($LASTEXITCODE -ne 0) { throw "git commit --amend failed with exit code $LASTEXITCODE." }
    return (git -C $RepoPath rev-parse --short HEAD).Trim()
}

function Rename-HistoricalCommit {
    param([string]$RepoPath, [string]$CommitHash, [string]$NewMessage)
    $cleanMsg = $NewMessage.Trim()
    if ([string]::IsNullOrWhiteSpace($cleanMsg)) { throw "Commit message cannot be empty." }

    $targetHash = (git -C $RepoPath rev-parse --verify "$CommitHash^{commit}" 2>$null)
    if (-not $targetHash) { throw "Commit '$CommitHash' not found in repository." }
    $targetHash = $targetHash.Trim()

    $headHash = (git -C $RepoPath rev-parse --verify "HEAD^{commit}").Trim()
    if ($targetHash -eq $headHash) {
        return (Rename-HeadCommit -RepoPath $RepoPath -NewMessage $cleanMsg)
    }

    $currentBranch = (git -C $RepoPath branch --show-current 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        throw "Cannot rebase historical commit while in detached HEAD state."
    }

    $rawReplay = git -C $RepoPath log --reverse --pretty=format:"%H" "$targetHash..HEAD" 2>$null
    $replayCommits = if ($rawReplay) { @($rawReplay -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) } else { @() }

    $targetTree   = (git -C $RepoPath rev-parse "$targetHash^{tree}").Trim()
    $targetParent = (git -C $RepoPath log -1 --format="%P" $targetHash).Trim()
    $authorName   = (git -C $RepoPath log -1 --format="%an" $targetHash).Trim()
    $authorEmail  = (git -C $RepoPath log -1 --format="%ae" $targetHash).Trim()
    $authorDate   = (git -C $RepoPath log -1 --format="%ad" $targetHash).Trim()

    $env:GIT_AUTHOR_NAME  = $authorName
    $env:GIT_AUTHOR_EMAIL = $authorEmail
    $env:GIT_AUTHOR_DATE  = $authorDate

    $parentArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($targetParent)) {
        foreach ($p in ($targetParent -split '\s+')) { $parentArgs += @("-p", $p) }
    }

    $allArgs = @("commit-tree", $targetTree) + $parentArgs + @("-m", $cleanMsg)
    $newParent = (git -C $RepoPath $allArgs).Trim()

    foreach ($cHash in $replayCommits) {
        $cTree   = (git -C $RepoPath rev-parse "$cHash^{tree}").Trim()
        $cMsg    = (git -C $RepoPath log -1 --format="%B" $cHash).Trim()
        $cName   = (git -C $RepoPath log -1 --format="%an" $cHash).Trim()
        $cEmail  = (git -C $RepoPath log -1 --format="%ae" $cHash).Trim()
        $cDate   = (git -C $RepoPath log -1 --format="%ad" $cHash).Trim()

        $env:GIT_AUTHOR_NAME  = $cName
        $env:GIT_AUTHOR_EMAIL = $cEmail
        $env:GIT_AUTHOR_DATE  = $cDate

        $newParent = (git -C $RepoPath commit-tree $cTree -p $newParent -m $cMsg).Trim()
    }

    Remove-Item env:GIT_AUTHOR_NAME -ErrorAction SilentlyContinue
    Remove-Item env:GIT_AUTHOR_EMAIL -ErrorAction SilentlyContinue
    Remove-Item env:GIT_AUTHOR_DATE -ErrorAction SilentlyContinue

    git -C $RepoPath update-ref "refs/heads/$currentBranch" $newParent
    if ($LASTEXITCODE -ne 0) { throw "Failed to update ref 'refs/heads/$currentBranch'." }

    return (git -C $RepoPath rev-parse --short HEAD).Trim()
}

function Push-ToRemoteWithLease {
    param([string]$RepoPath, [string]$RemoteName = "origin", [string]$Branch = "")
    $targetBranch = if ($Branch) { $Branch } else { (git -C $RepoPath branch --show-current 2>$null).Trim() }
    if ([string]::IsNullOrWhiteSpace($targetBranch)) { throw "Cannot push detached HEAD." }

    $output = git -C $RepoPath push --force-with-lease $RemoteName $targetBranch 2>&1
    $success = ($LASTEXITCODE -eq 0)

    return [PSCustomObject]@{
        Success = $success
        Output  = ($output -join "`n")
        Branch  = $targetBranch
        Remote  = $RemoteName
    }
}

# ------------------------------------------------------------------------------
# DISPATCHER EXECUTION
# ------------------------------------------------------------------------------
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

$isGit = git -C $resolvedTarget rev-parse --is-inside-work-tree 2>$null
if ($isGit -ne "true") {
    Write-Error "Directory is not a Git repository: $resolvedTarget"
    exit 1
}

$remoteInfo = Get-GitRemoteHosting -RepoPath $resolvedTarget

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "   GIT COMMIT RENAMER (STANDALONE)                                      " -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " Target Directory : $resolvedTarget" -ForegroundColor White
Write-Host " Active Branch    : $($remoteInfo.Branch)" -ForegroundColor White
Write-Host " Remote Host      : $($remoteInfo.Provider) ($($remoteInfo.RemoteName) -> $($remoteInfo.RemoteUrl))" -ForegroundColor $(if ($remoteInfo.HasRemote) { "Green" } else { "DarkGray" })
Write-Host " Mode             : Standalone Inlined Zero-Dependency" -ForegroundColor DarkGray
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

if ($CommitHash -and $NewMessage) {
    try {
        Write-Host "Renaming commit '$CommitHash'..." -ForegroundColor Cyan
        $newHead = Rename-HistoricalCommit -RepoPath $resolvedTarget -CommitHash $CommitHash -NewMessage $NewMessage
        Write-Host "[OK] Commit renamed. New HEAD: $newHead" -ForegroundColor Green

        if ($PushRemote -and $remoteInfo.HasRemote) {
            Write-Host "Pushing to $($remoteInfo.Provider) with lease..." -ForegroundColor Cyan
            $pushRes = Push-ToRemoteWithLease -RepoPath $resolvedTarget -RemoteName $remoteInfo.RemoteName -Branch $remoteInfo.Branch
            if ($pushRes.Success) {
                Write-Host "[OK] Successfully pushed to $($remoteInfo.Provider) ($($remoteInfo.Branch))." -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Push failed: $($pushRes.Output)" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
    exit 0
}

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
