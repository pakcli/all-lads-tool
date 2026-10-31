<#
.SYNOPSIS
    Git Commit Renamer and Remote Push Module.
.DESCRIPTION
    Plumbing-level commit message renamer for HEAD and historical commits,
    with remote provider detection (GitHub/GitLab) and safe force-with-lease push.
#>
[CmdletBinding()]
param()

function Get-RecentCommits {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [int]$Limit = 15
    )

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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$NewMessage
    )

    $cleanMsg = $NewMessage.Trim()
    if ([string]::IsNullOrWhiteSpace($cleanMsg)) {
        throw "Commit message cannot be empty."
    }

    git -C $RepoPath commit --amend -m $cleanMsg
    if ($LASTEXITCODE -ne 0) {
        throw "git commit --amend failed with exit code $LASTEXITCODE."
    }

    $newHash = (git -C $RepoPath rev-parse --short HEAD).Trim()
    return $newHash
}

function Rename-HistoricalCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$CommitHash,

        [Parameter(Mandatory = $true)]
        [string]$NewMessage
    )

    $cleanMsg = $NewMessage.Trim()
    if ([string]::IsNullOrWhiteSpace($cleanMsg)) {
        throw "Commit message cannot be empty."
    }

    # Verify commit exists
    $targetHash = (git -C $RepoPath rev-parse --verify "$CommitHash^{commit}" 2>$null)
    if (-not $targetHash) {
        throw "Commit '$CommitHash' not found in repository."
    }
    $targetHash = $targetHash.Trim()

    $headHash = (git -C $RepoPath rev-parse --verify "HEAD^{commit}").Trim()
    if ($targetHash -eq $headHash) {
        return (Rename-HeadCommit -RepoPath $RepoPath -NewMessage $cleanMsg)
    }

    $currentBranch = (git -C $RepoPath branch --show-current 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($currentBranch)) {
        throw "Cannot rebase historical commit while in detached HEAD state."
    }

    # Get chronological commits between target and HEAD: target..HEAD
    $rawReplay = git -C $RepoPath log --reverse --pretty=format:"%H" "$targetHash..HEAD" 2>$null
    $replayCommits = if ($rawReplay) { @($rawReplay -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) } else { @() }

    # 1. Read target commit properties
    $targetTree   = (git -C $RepoPath rev-parse "$targetHash^{tree}").Trim()
    $targetParent = (git -C $RepoPath log -1 --format="%P" $targetHash).Trim()
    $authorName   = (git -C $RepoPath log -1 --format="%an" $targetHash).Trim()
    $authorEmail  = (git -C $RepoPath log -1 --format="%ae" $targetHash).Trim()
    $authorDate   = (git -C $RepoPath log -1 --format="%ad" $targetHash).Trim()

    # Set author environment for rewritten commit
    $env:GIT_AUTHOR_NAME  = $authorName
    $env:GIT_AUTHOR_EMAIL = $authorEmail
    $env:GIT_AUTHOR_DATE  = $authorDate

    $parentArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($targetParent)) {
        foreach ($p in ($targetParent -split '\s+')) {
            $parentArgs += @("-p", $p)
        }
    }

    $allArgs = @("commit-tree", $targetTree) + $parentArgs + @("-m", $cleanMsg)
    $newParent = (git -C $RepoPath $allArgs).Trim()

    # 2. Replay all subsequent commits on top of newParent
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

    # 3. Clean author env
    Remove-Item env:GIT_AUTHOR_NAME -ErrorAction SilentlyContinue
    Remove-Item env:GIT_AUTHOR_EMAIL -ErrorAction SilentlyContinue
    Remove-Item env:GIT_AUTHOR_DATE -ErrorAction SilentlyContinue

    # 4. Atomically update ref to current branch
    git -C $RepoPath update-ref "refs/heads/$currentBranch" $newParent
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to update ref 'refs/heads/$currentBranch' to $newParent."
    }

    return (git -C $RepoPath rev-parse --short HEAD).Trim()
}

function Push-ToRemoteWithLease {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [string]$RemoteName = "origin",
        [string]$Branch = ""
    )

    $targetBranch = if ($Branch) { $Branch } else { (git -C $RepoPath branch --show-current 2>$null).Trim() }
    if ([string]::IsNullOrWhiteSpace($targetBranch)) {
        throw "Cannot push detached HEAD."
    }

    $output = git -C $RepoPath push --force-with-lease $RemoteName $targetBranch 2>&1
    $success = ($LASTEXITCODE -eq 0)

    return [PSCustomObject]@{
        Success = $success
        Output  = ($output -join "`n")
        Branch  = $targetBranch
        Remote  = $RemoteName
    }
}

Export-ModuleMember -Function Get-RecentCommits, Get-GitRemoteHosting, Rename-HeadCommit, Rename-HistoricalCommit, Push-ToRemoteWithLease
