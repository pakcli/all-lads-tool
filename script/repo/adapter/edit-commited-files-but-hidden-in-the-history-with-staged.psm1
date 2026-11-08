<#
.SYNOPSIS
    Adapter Engine for Historical Commit File Overwrite (edit-commited-files-but-hidden-in-the-history-with-staged.psm1)
.DESCRIPTION
    Provides the 5-option file state & custom-path resolution engine (Options 1..4 2x2 matrix + Option 5 Custom Path
    with folder/file scope detection and new-file sub-prompt), pre-flight commit inspection,
    original-timestamp HEAD amend, and non-interactive autosquash rebase for replacing files
    inside an existing commit without adding extra fixup commits in git history.
#>

function Invoke-GitRepoCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string[]]$GitArgs
    )

    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        $rawOut = & git -C $RepoPath @GitArgs 2>&1
        $exitCode = $LASTEXITCODE
        $lines = @($rawOut | Where-Object { $null -ne $_ } | ForEach-Object { "$_" })
        return [PSCustomObject]@{
            Success  = ($exitCode -eq 0)
            ExitCode = $exitCode
            Output   = $lines
        }
    } catch {
        return [PSCustomObject]@{
            Success  = $false
            ExitCode = 1
            Output   = @("$_")
        }
    } finally {
        $ErrorActionPreference = $prevPref
    }
}

function Test-GitRepository {
    [CmdletBinding()]
    param(
        [string]$Path = ""
    )
    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path -PathType Container))) {
        return $false
    }
    if (Test-Path -LiteralPath (Join-Path $Path ".git")) {
        return $true
    }
    $check = Invoke-GitRepoCommand -RepoPath $Path -GitArgs @("rev-parse", "--is-inside-work-tree")
    return ($check.Success -and ($check.Output -join "").Trim() -eq "true")
}

function Get-DiscoveredGitRepositories {
    [CmdletBinding()]
    param(
        [string]$BasePath = ""
    )

    $rootsToScan = [System.Collections.Generic.List[string]]::new()
    if (-not [string]::IsNullOrWhiteSpace($BasePath) -and (Test-Path -LiteralPath $BasePath)) {
        $resolvedBase = (Resolve-Path -LiteralPath $BasePath).Path
        [void]$rootsToScan.Add($resolvedBase)
        $parentBase = Split-Path -Path $resolvedBase -Parent
        if ($parentBase -and (Test-Path -LiteralPath $parentBase)) {
            [void]$rootsToScan.Add($parentBase)
        }
    }

    $cwd = (Get-Location).Path
    if (-not $rootsToScan.Contains($cwd)) { [void]$rootsToScan.Add($cwd) }
    $cwdParent = Split-Path -Path $cwd -Parent
    if ($cwdParent -and (-not $rootsToScan.Contains($cwdParent))) { [void]$rootsToScan.Add($cwdParent) }

    $seenPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $repos = [System.Collections.Generic.List[object]]::new()

    foreach ($root in $rootsToScan) {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) { continue }

        if ((Test-GitRepository -Path $root) -and $seenPaths.Add($root)) {
            $branchRes = Invoke-GitRepoCommand -RepoPath $root -GitArgs @("rev-parse", "--abbrev-ref", "HEAD")
            $branchName = if ($branchRes.Success -and $branchRes.Output.Count -gt 0) { $branchRes.Output[0].Trim() } else { "HEAD" }
            [void]$repos.Add([PSCustomObject]@{
                Name       = Split-Path -Leaf $root
                FullPath   = $root
                BranchName = $branchName
            })
        }

        $subDirs = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $subDirs) {
            if ($dir.Name -in @("node_modules", "trash-bin", ".git", ".vs", "dist", "build")) { continue }
            if ((Test-GitRepository -Path $dir.FullName) -and $seenPaths.Add($dir.FullName)) {
                $branchRes = Invoke-GitRepoCommand -RepoPath $dir.FullName -GitArgs @("rev-parse", "--abbrev-ref", "HEAD")
                $branchName = if ($branchRes.Success -and $branchRes.Output.Count -gt 0) { $branchRes.Output[0].Trim() } else { "HEAD" }
                [void]$repos.Add([PSCustomObject]@{
                    Name       = $dir.Name
                    FullPath   = $dir.FullName
                    BranchName = $branchName
                })
            }
        }
    }

    return ,($repos | Sort-Object FullPath)
}

function Get-RepoRecentCommits {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [int]$Limit = 15
    )

    $headRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "HEAD")
    $headFull = if ($headRes.Success -and $headRes.Output.Count -gt 0) { $headRes.Output[0].Trim() } else { "" }

    $logRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @(
        "log", "-n", "$Limit", "--pretty=format:%h|%H|%ad|%an|%s", "--date=short"
    )
    $commits = [System.Collections.Generic.List[object]]::new()
    if (-not $logRes.Success) { return ,$commits.ToArray() }

    $idx = 1
    foreach ($line in $logRes.Output) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $parts = $line -split '\|', 5
        if ($parts.Count -ge 5) {
            $fullHash = $parts[1].Trim()
            [void]$commits.Add([PSCustomObject]@{
                Index     = $idx
                ShortHash = $parts[0].Trim()
                FullHash  = $fullHash
                Date      = $parts[2].Trim()
                Author    = $parts[3].Trim()
                Subject   = $parts[4].Trim()
                IsHead    = ($fullHash -eq $headFull)
            })
            $idx++
        }
    }
    return ,$commits.ToArray()
}

function Resolve-TargetCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$CommitInput,

        [array]$RecentCommits = @()
    )

    $cleanInput = $CommitInput.Trim()
    if ([string]::IsNullOrWhiteSpace($cleanInput)) {
        return $null
    }

    $targetRef = $cleanInput
    $parsedIdx = 0
    if ([int]::TryParse($cleanInput, [ref]$parsedIdx)) {
        $matchedFromList = $RecentCommits | Where-Object { $_.Index -eq $parsedIdx } | Select-Object -First 1
        if ($matchedFromList) {
            $targetRef = $matchedFromList.FullHash
        }
    }

    $verifyRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "--verify", "$targetRef^{commit}")
    if (-not $verifyRes.Success -or $verifyRes.Output.Count -eq 0) {
        return $null
    }
    $fullHash = $verifyRes.Output[0].Trim()

    $headRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "HEAD")
    $headFull = if ($headRes.Success -and $headRes.Output.Count -gt 0) { $headRes.Output[0].Trim() } else { "" }

    $metaRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @(
        "show", "-s", "--format=%h|%ad|%cI|%aI|%an|%s", "--date=short", $fullHash
    )
    if (-not $metaRes.Success -or $metaRes.Output.Count -eq 0) {
        return $null
    }
    $parts = $metaRes.Output[0] -split '\|', 6
    $remoteRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("branch", "-r", "--contains", $fullHash)
    $remoteBranches = @()
    if ($remoteRes.Success) {
        $remoteBranches = @($remoteRes.Output | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
    }

    $parentRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "--verify", "$fullHash~1")
    $isRootCommit = (-not $parentRes.Success)

    return [PSCustomObject]@{
        ShortHash      = $parts[0].Trim()
        FullHash       = $fullHash
        DateShort      = $parts[1].Trim()
        CommitDateIso  = $parts[2].Trim()
        AuthorDateIso  = $parts[3].Trim()
        Author         = $parts[4].Trim()
        Subject        = $parts[5].Trim()
        IsHead         = ($fullHash -eq $headFull)
        IsRootCommit   = $isRootCommit
        IsPushedRemote = ($remoteBranches.Count -gt 0)
        RemoteBranches = $remoteBranches
    }
}

function Get-OptionDescription {
    [CmdletBinding()]
    param(
        [int]$Option,
        [string]$CustomScopeSummary = ""
    )
    switch ($Option) {
        1 { return "Option 1: Overwrite staged files | type state: modified (Staged M only)" }
        2 { return "Option 2: Overwrite staged files | type state: all (Staged M/A/D/R)" }
        3 { return "Option 3: Overwrite all files    | type state: modified (Staged + Unstaged M only)" }
        4 { return "Option 4: Overwrite all files    | type state: all (All Staged + Unstaged + Untracked)" }
        5 {
            if ($CustomScopeSummary) {
                return "Option 5: Custom path ($CustomScopeSummary)"
            }
            return "Option 5: Custom path (Folder scope: path/subfolder | Exact file: path/subfolder/file.ext)"
        }
        default { return "Unknown Option" }
    }
}

function Resolve-CustomScopeTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$RawCustomPath
    )

    $clean = $RawCustomPath.Trim().Trim('"', "'")
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return [PSCustomObject]@{ IsValid = $false; ErrorMessage = "Custom path cannot be empty." }
    }

    $repoRootNorm = (Resolve-Path -LiteralPath $RepoPath).Path.TrimEnd('\', '/')
    $fullTarget = ""
    $relTarget = ""

    # Determine if input is a rooted path from drive (e.g. E:\proj\... or /...) or relative to repo
    if ([System.IO.Path]::IsPathRooted($clean) -and $clean -match '^[a-zA-Z]:[\\/]') {
        $candidateFull = [System.IO.Path]::GetFullPath($clean).TrimEnd('\', '/')
        if (-not $candidateFull.StartsWith($repoRootNorm, [System.StringComparison]::OrdinalIgnoreCase)) {
            return [PSCustomObject]@{
                IsValid      = $false
                ErrorMessage = "Rooted path '$candidateFull' is outside repository '$repoRootNorm'."
            }
        }
        $fullTarget = $candidateFull
        if ($candidateFull.Length -gt $repoRootNorm.Length) {
            $relTarget = $candidateFull.Substring($repoRootNorm.Length).TrimStart('\', '/') -replace '\\', '/'
        } else {
            $relTarget = "."
        }
    } else {
        $relClean = $clean -replace '^\.[\\/]', '' -replace '\\', '/'
        $relClean = $relClean.TrimStart('/').TrimEnd('/')
        if ([string]::IsNullOrWhiteSpace($relClean)) { $relClean = "." }
        $relTarget = $relClean
        $fullTarget = if ($relTarget -eq ".") { $repoRootNorm } else { Join-Path $repoRootNorm ($relTarget -replace '/', '\') }
    }

    # Determine Folder Scope vs. Exact Single-File Scope
    $scopeType = "Folder"
    if (Test-Path -LiteralPath $fullTarget -PathType Leaf) {
        $scopeType = "File"
    } elseif (Test-Path -LiteralPath $fullTarget -PathType Container) {
        $scopeType = "Folder"
    } else {
        # If deleted or not currently on disk, check whether path has a file extension or matches an exact tracked file
        $ext = [System.IO.Path]::GetExtension($relTarget)
        if (-not [string]::IsNullOrWhiteSpace($ext)) {
            $scopeType = "File"
        }
    }

    # Query git status for this path scope
    $gitArgs = if ($relTarget -eq ".") {
        @("status", "--porcelain=v1", "-uall")
    } else {
        @("status", "--porcelain=v1", "-uall", "--", $relTarget)
    }
    $statusRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs $gitArgs

    $allScopedFiles = [System.Collections.Generic.List[object]]::new()
    $modifiedOnlyFiles = [System.Collections.Generic.List[object]]::new()
    $newFilesDetected = [System.Collections.Generic.List[object]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    if ($statusRes.Success) {
        foreach ($line in $statusRes.Output) {
            if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) { continue }
            $xy = $line.Substring(0, 2)
            $xyTrim = $xy.Trim()
            $rawFile = $line.Substring(3).Trim().Trim('"')
            if ($rawFile -match ' -> (?<dest>.+)$') {
                $rawFile = $Matches['dest'].Trim().Trim('"')
            }

            # If ScopeType is File, enforce exact path match
            if ($scopeType -eq "File" -and ($rawFile -replace '\\', '/') -ne ($relTarget -replace '\\', '/')) {
                continue
            }

            if (-not $seen.Add($rawFile)) { continue }

            $isNewFile = ($xyTrim -eq "??" -or $xyTrim.StartsWith("A") -or $xy.EndsWith("A"))
            $isModifiedTracked = ($xyTrim -eq "M" -or $xyTrim -eq "MM")

            $itemObj = [PSCustomObject]@{
                RelativePath = $rawFile
                StateCode    = if ($xyTrim) { $xyTrim } else { "M" }
                ScopeSource  = if ($scopeType -eq "File") { "Custom Exact File ($relTarget)" } else { "Custom Folder Scope ($relTarget)" }
                IsNewFile    = $isNewFile
                IsModified   = $isModifiedTracked
            }

            [void]$allScopedFiles.Add($itemObj)
            if ($isNewFile) {
                [void]$newFilesDetected.Add($itemObj)
            }
            if ($isModifiedTracked) {
                [void]$modifiedOnlyFiles.Add($itemObj)
            }
        }
    }

    return [PSCustomObject]@{
        IsValid           = $true
        ScopeType         = $scopeType
        RelativeTarget    = $relTarget
        FullTarget        = $fullTarget
        AllScopedFiles    = ,$allScopedFiles.ToArray()
        ModifiedOnlyFiles = ,$modifiedOnlyFiles.ToArray()
        NewFilesDetected  = ,$newFilesDetected.ToArray()
        HasNewFiles       = ($newFilesDetected.Count -gt 0)
    }
}

function Get-CandidateFilesByOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 4)]
        [int]$Option
    )

    $results = [System.Collections.Generic.List[object]]::new()
    $seenFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    if ($Option -in @(1, 2)) {
        # Staged files only (Index)
        $stagedRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("diff", "--cached", "--name-status")
        if ($stagedRes.Success) {
            foreach ($line in $stagedRes.Output) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = $line -split "`t"
                if ($parts.Count -ge 2) {
                    $statusRaw = $parts[0].Trim()
                    $statusChar = $statusRaw.Substring(0, 1).ToUpperInvariant()
                    $filePath = if ($parts.Count -ge 3 -and ($statusChar -in @("R", "C"))) { $parts[2].Trim() } else { $parts[1].Trim() }

                    if ($Option -eq 1 -and $statusChar -ne "M") {
                        continue
                    }

                    if ($seenFiles.Add($filePath)) {
                        [void]$results.Add([PSCustomObject]@{
                            RelativePath = $filePath
                            StateCode    = $statusChar
                            ScopeSource  = "Staged (Index)"
                        })
                    }
                }
            }
        }
    } elseif ($Option -eq 3) {
        # All files (Staged + Working Tree) | type state: modified (M only)
        $stagedRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("diff", "--cached", "--name-status")
        if ($stagedRes.Success) {
            foreach ($line in $stagedRes.Output) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = $line -split "`t"
                if ($parts.Count -ge 2) {
                    $statusChar = $parts[0].Trim().Substring(0, 1).ToUpperInvariant()
                    $filePath = $parts[1].Trim()
                    if ($statusChar -eq "M" -and $seenFiles.Add($filePath)) {
                        [void]$results.Add([PSCustomObject]@{
                            RelativePath = $filePath
                            StateCode    = "M"
                            ScopeSource  = "Staged (Modified)"
                        })
                    }
                }
            }
        }

        $unstagedRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("diff", "--name-status")
        if ($unstagedRes.Success) {
            foreach ($line in $unstagedRes.Output) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = $line -split "`t"
                if ($parts.Count -ge 2) {
                    $statusChar = $parts[0].Trim().Substring(0, 1).ToUpperInvariant()
                    $filePath = $parts[1].Trim()
                    if ($statusChar -eq "M" -and $seenFiles.Add($filePath)) {
                        [void]$results.Add([PSCustomObject]@{
                            RelativePath = $filePath
                            StateCode    = "M"
                            ScopeSource  = "Working Tree (Modified)"
                        })
                    }
                }
            }
        }
    } elseif ($Option -eq 4) {
        # All files (Staged + Working Tree + Untracked) | type state: all
        $statusRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("status", "--porcelain=v1", "-uall")
        if ($statusRes.Success) {
            foreach ($line in $statusRes.Output) {
                if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) { continue }
                $xy = $line.Substring(0, 2).Trim()
                $rawPath = $line.Substring(3).Trim().Trim('"')
                if ($rawPath -match ' -> (?<dest>.+)$') {
                    $rawPath = $Matches['dest'].Trim().Trim('"')
                }
                if ($seenFiles.Add($rawPath)) {
                    [void]$results.Add([PSCustomObject]@{
                        RelativePath = $rawPath
                        StateCode    = if ($xy) { $xy } else { "M" }
                        ScopeSource  = "All Working Tree & Index"
                    })
                }
            }
        }
    }

    return ,$results.ToArray()
}

function Invoke-CommitFileOverwrite {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TargetCommit,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 5)]
        [int]$Option,

        [Parameter(Mandatory = $true)]
        [array]$CandidateFiles
    )

    if (-not $CandidateFiles -or $CandidateFiles.Count -eq 0) {
        return [PSCustomObject]@{
            Success = $false
            Message = "No matching files found for Option $Option."
        }
    }

    $headRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "HEAD")
    $origHead = if ($headRes.Success -and $headRes.Output.Count -gt 0) { $headRes.Output[0].Trim() } else { "" }

    # 1. Create a deterministic safety backup ref before mutating history
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupRef = "refs/backup/commit-overwrite-$timestamp"
    if ($origHead) {
        [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("update-ref", $backupRef, $origHead))
    }

    $relPaths = @($CandidateFiles | ForEach-Object { $_.RelativePath })
    $relPathSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($rp in $relPaths) { [void]$relPathSet.Add(($rp -replace '\\', '/')) }
    $excludedStagedPaths = @()

    try {
        # 2. Prepare staging area strictly according to Option (1..5)
        if ($Option -eq 1) {
            # Option 1: Staged M only -> temporarily unstage any non-M staged files
            $allStagedRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("diff", "--cached", "--name-status")
            if ($allStagedRes.Success) {
                foreach ($line in $allStagedRes.Output) {
                    $parts = $line -split "`t"
                    if ($parts.Count -ge 2) {
                        $sc = $parts[0].Trim().Substring(0, 1).ToUpperInvariant()
                        $fp = if ($parts.Count -ge 3 -and ($sc -in @("R", "C"))) { $parts[2].Trim() } else { $parts[1].Trim() }
                        if ($sc -ne "M") {
                            $excludedStagedPaths += $fp
                        }
                    }
                }
            }
            foreach ($exPath in $excludedStagedPaths) {
                [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("reset", "HEAD", "--", $exPath))
            }
        } elseif ($Option -eq 2) {
            # Option 2: All currently staged files are already in the index
        } elseif ($Option -in @(3, 5)) {
            # Option 3 (All Modified M) & Option 5 (Custom Path Scoped):
            # Temporarily unstage any staged file that is NOT in $relPaths, then stage every file in $relPaths
            $allStagedRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("diff", "--cached", "--name-status")
            if ($allStagedRes.Success) {
                foreach ($line in $allStagedRes.Output) {
                    $parts = $line -split "`t"
                    if ($parts.Count -ge 2) {
                        $sc = $parts[0].Trim().Substring(0, 1).ToUpperInvariant()
                        $fp = if ($parts.Count -ge 3 -and ($sc -in @("R", "C"))) { $parts[2].Trim() } else { $parts[1].Trim() }
                        if (-not $relPathSet.Contains(($fp -replace '\\', '/'))) {
                            $excludedStagedPaths += $fp
                        }
                    }
                }
            }
            foreach ($exPath in $excludedStagedPaths) {
                [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("reset", "HEAD", "--", $exPath))
            }
            foreach ($rp in $relPaths) {
                [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("add", "-A", "--", $rp))
            }
        } elseif ($Option -eq 4) {
            # Option 4: Stage all files (modified, added, deleted, untracked)
            [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("add", "-A"))
        }

        # 3. Execute Commit File Overwrite (Case A: HEAD vs. Case B: Historical Commit)
        $prevCommitterDate = $env:GIT_COMMITTER_DATE
        $prevSeqEditor = $env:GIT_SEQUENCE_EDITOR

        try {
            if ($TargetCommit.IsHead) {
                # Fast-path HEAD Amend preserving original CommitDate
                $env:GIT_COMMITTER_DATE = $TargetCommit.CommitDateIso
                $amendArgs = @("commit", "--amend", "--no-edit")

                $amendRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs $amendArgs
                if (-not $amendRes.Success) {
                    return [PSCustomObject]@{
                        Success   = $false
                        BackupRef = $backupRef
                        Message   = "git commit --amend failed: $($amendRes.Output -join ' ')"
                    }
                }
            } else {
                # Historical Commit Overwrite via Fixup + Non-Interactive Autosquash Rebase
                $fixupArgs = @("commit", "--fixup=$($TargetCommit.FullHash)")

                $fixupRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs $fixupArgs
                if (-not $fixupRes.Success) {
                    return [PSCustomObject]@{
                        Success   = $false
                        BackupRef = $backupRef
                        Message   = "Failed to create temporary fixup commit: $($fixupRes.Output -join ' ')"
                    }
                }

                $env:GIT_SEQUENCE_EDITOR = "true"
                $rebaseBaseArgs = @(
                    "-c", "sequence.editor=true",
                    "rebase", "-i", "--autosquash", "--autostash", "--committer-date-is-author-date"
                )
                if ($TargetCommit.IsRootCommit) {
                    $rebaseBaseArgs += "--root"
                } else {
                    $rebaseBaseArgs += "$($TargetCommit.FullHash)~1"
                }

                $rebaseRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs $rebaseBaseArgs
                if (-not $rebaseRes.Success) {
                    # Automatically abort failed rebase and restore pre-fixup state
                    [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rebase", "--abort"))
                    [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("reset", "--soft", $origHead))
                    return [PSCustomObject]@{
                        Success   = $false
                        BackupRef = $backupRef
                        Message   = "Rebase conflict encountered while rewriting $($TargetCommit.ShortHash). Automatically aborted and restored state. Details: $($rebaseRes.Output -join ' ')"
                    }
                }
            }
        } finally {
            $env:GIT_COMMITTER_DATE = $prevCommitterDate
            $env:GIT_SEQUENCE_EDITOR = $prevSeqEditor
        }

        # 4. Re-stage any excluded staged files if Option 1, 3, or 5 was used
        foreach ($exPath in $excludedStagedPaths) {
            if (Test-Path -LiteralPath (Join-Path $RepoPath $exPath)) {
                [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("add", "--", $exPath))
            }
        }

        $newHeadRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "--short", "HEAD")
        $newHeadShort = if ($newHeadRes.Success -and $newHeadRes.Output.Count -gt 0) { $newHeadRes.Output[0].Trim() } else { "HEAD" }

        return [PSCustomObject]@{
            Success      = $true
            NewHeadShort = $newHeadShort
            BackupRef    = $backupRef
            Message      = "Successfully overwrote $($CandidateFiles.Count) file(s) into commit $($TargetCommit.ShortHash) (New HEAD: $newHeadShort)."
        }
    } catch {
        return [PSCustomObject]@{
            Success   = $false
            BackupRef = $backupRef
            Message   = "Unexpected exception during commit file overwrite: $_"
        }
    }
}

function Get-CommitOverwriteOptionsJsonPath {
    [CmdletBinding()]
    param(
        [string]$ExecutorBaseName = "edit-commited-files-but-hidden-in-the-history-with-staged"
    )
    return (Join-Path $PSScriptRoot "$ExecutorBaseName.json")
}

function Import-CommitOverwriteOptions {
    [CmdletBinding()]
    param(
        [string]$ExecutorBaseName = "edit-commited-files-but-hidden-in-the-history-with-staged"
    )
    $jsonPath = Get-CommitOverwriteOptionsJsonPath -ExecutorBaseName $ExecutorBaseName
    if (Test-Path -LiteralPath $jsonPath) {
        try {
            $raw = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                return ($raw | ConvertFrom-Json)
            }
        } catch {}
    }
    return [PSCustomObject]@{
        executor  = "$ExecutorBaseName.ps1"
        updatedAt = ""
        options   = [PSCustomObject]@{
            lastRepo                = ""
            lastCommitId            = ""
            lastOption              = 0
            lastCustomPath          = ""
            lastCustomNewFileAction = 0
        }
        history   = @()
    }
}

function Save-CommitOverwriteOptions {
    [CmdletBinding()]
    param(
        [string]$ExecutorBaseName = "edit-commited-files-but-hidden-in-the-history-with-staged",
        [string]$RepoPath = "",
        [string]$CommitId = "",
        [int]$Option = 0,
        [string]$CustomPath = "",
        [int]$CustomNewFileAction = 0,
        [int]$FilesCount = 0,
        [string]$BackupRef = ""
    )

    $jsonPath = Get-CommitOverwriteOptionsJsonPath -ExecutorBaseName $ExecutorBaseName
    $existing = Import-CommitOverwriteOptions -ExecutorBaseName $ExecutorBaseName
    $histList = [System.Collections.Generic.List[object]]::new()
    if ($existing -and $existing.history) {
        foreach ($h in @($existing.history | Select-Object -Last 19)) {
            [void]$histList.Add($h)
        }
    }

    $nowIso = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    [void]$histList.Add([PSCustomObject]@{
        timestamp           = $nowIso
        repo                = $RepoPath
        commitId            = $CommitId
        option              = $Option
        customPath          = $CustomPath
        customNewFileAction = $CustomNewFileAction
        filesCount          = $FilesCount
        backupRef           = $BackupRef
    })

    $payload = [PSCustomObject]@{
        executor  = "$ExecutorBaseName.ps1"
        updatedAt = $nowIso
        options   = [PSCustomObject]@{
            lastRepo                = $RepoPath
            lastCommitId            = $CommitId
            lastOption              = $Option
            lastCustomPath          = $CustomPath
            lastCustomNewFileAction = $CustomNewFileAction
        }
        history   = ,$histList.ToArray()
    }

    try {
        $json = $payload | ConvertTo-Json -Depth 6
        Set-Content -LiteralPath $jsonPath -Value $json -Force -Encoding UTF8
    } catch {}
    return $jsonPath
}

Export-ModuleMember -Function @(
    'Invoke-GitRepoCommand',
    'Test-GitRepository',
    'Get-DiscoveredGitRepositories',
    'Get-RepoRecentCommits',
    'Resolve-TargetCommit',
    'Get-OptionDescription',
    'Resolve-CustomScopeTarget',
    'Get-CandidateFilesByOption',
    'Invoke-CommitFileOverwrite',
    'Get-CommitOverwriteOptionsJsonPath',
    'Import-CommitOverwriteOptions',
    'Save-CommitOverwriteOptions'
)
