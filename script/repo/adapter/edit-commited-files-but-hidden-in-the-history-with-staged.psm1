<#
.SYNOPSIS
    Adapter Engine for Historical Commit File Overwrite (edit-commited-files-but-hidden-in-the-history-with-staged.psm1)
.DESCRIPTION
    Provides the 5-option + 'L'/'all' (All Commit State) file state & custom-path resolution engine,
    pre-flight commit inspection, original-timestamp HEAD amend, non-interactive autosquash rebase,
    and full-history index-filter rewrite ('L' / 'all') for replacing files across single or all commits
    in git history.
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

    return @($repos | Sort-Object FullPath)
}

function Get-RepoTotalCommitCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    $countRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-list", "--count", "HEAD")
    if ($countRes.Success -and $countRes.Output.Count -gt 0) {
        $parsed = 0
        if ([int]::TryParse($countRes.Output[0].Trim(), [ref]$parsed)) {
            return $parsed
        }
    }
    return 0
}

function Get-RepoRecentCommits {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [int]$Limit = 20,

        [int]$Skip = 0
    )

    $headRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "HEAD")
    $headFull = if ($headRes.Success -and $headRes.Output.Count -gt 0) { $headRes.Output[0].Trim() } else { "" }

    $logArgs = [System.Collections.Generic.List[string]]::new()
    [void]$logArgs.Add("log")
    if ($Skip -gt 0) {
        [void]$logArgs.Add("--skip=$Skip")
    }
    if ($Limit -gt 0) {
        [void]$logArgs.Add("-n")
        [void]$logArgs.Add("$Limit")
    }
    [void]$logArgs.Add("--pretty=format:%h|%H|%ad|%an|%s")
    [void]$logArgs.Add("--date=short")

    $logRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs $logArgs.ToArray()
    $commits = [System.Collections.Generic.List[object]]::new()
    if (-not $logRes.Success) { return @() }

    $idx = $Skip + 1
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
    return $commits.ToArray()
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

    # Check if user entered 'L' or 'all' -> ALL COMMIT STATE (Rewrite across all commits in branch history)
    if ($cleanInput -ieq "L" -or $cleanInput -ieq "all") {
        $headRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "HEAD")
        if (-not $headRes.Success -or $headRes.Output.Count -eq 0) { return $null }
        $headFull = $headRes.Output[0].Trim()

        $countRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-list", "--count", "HEAD")
        $totalCount = if ($countRes.Success -and $countRes.Output.Count -gt 0) { [int]($countRes.Output[0].Trim()) } else { 1 }

        $metaRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @(
            "show", "-s", "--format=%h|%ad|%cI|%aI|%an|%s", "--date=short", $headFull
        )
        $parts = if ($metaRes.Success -and $metaRes.Output.Count -gt 0) {
            $metaRes.Output[0] -split '\|', 6
        } else {
            @("ALL", (Get-Date -Format "yyyy-MM-dd"), (Get-Date -Format "o"), (Get-Date -Format "o"), "", "All Commits")
        }

        $remoteRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("branch", "-r", "--contains", $headFull)
        $remoteBranches = @()
        if ($remoteRes.Success) {
            $remoteBranches = @($remoteRes.Output | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" })
        }

        return [PSCustomObject]@{
            ShortHash      = "ALL ($totalCount commits)"
            FullHash       = $headFull
            DateShort      = $parts[1].Trim()
            CommitDateIso  = $parts[2].Trim()
            AuthorDateIso  = $parts[3].Trim()
            Author         = $parts[4].Trim()
            Subject        = "All Commit State - Overwrite across all $totalCount commit(s) in history"
            IsHead         = $false
            IsAllCommits   = $true
            TotalCommits   = $totalCount
            IsRootCommit   = $true
            IsPushedRemote = ($remoteBranches.Count -gt 0)
            RemoteBranches = $remoteBranches
        }
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
        IsAllCommits   = $false
        TotalCommits   = 1
        IsRootCommit   = $isRootCommit
        IsPushedRemote = ($remoteBranches.Count -gt 0)
        RemoteBranches = $remoteBranches
    }
}

function Get-OptionDescription {
    [CmdletBinding()]
    param(
        [int]$Option,
        [string]$CustomScopeSummary = "",
        [bool]$IsAllCommits = $false
    )
    $suffix = if ($IsAllCommits) { " [ALL COMMITS STATE]" } else { "" }
    switch ($Option) {
        1 { return "Option 1: Overwrite staged files | type state: modified (Staged M only)$suffix" }
        2 { return "Option 2: Overwrite staged files | type state: all (Staged M/A/D/R)$suffix" }
        3 { return "Option 3: Overwrite all files    | type state: modified (Staged + Unstaged M only)$suffix" }
        4 { return "Option 4: Overwrite all files    | type state: all (All Staged + Unstaged + Untracked)$suffix" }
        5 {
            if ($CustomScopeSummary) {
                return "Option 5: Custom path ($CustomScopeSummary)$suffix"
            }
            return "Option 5: Custom path (Folder scope: path/subfolder | Exact file: path/subfolder/file.ext)$suffix"
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
        [string]$RawCustomPath,

        [bool]$AllowCleanTrackedFiles = $false
    )

    $clean = $RawCustomPath.Trim().Trim('"', "'")
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return [PSCustomObject]@{ IsValid = $false; ErrorMessage = "Custom path cannot be empty." }
    }

    $repoRootNorm = (Get-Item -LiteralPath $RepoPath -Force).FullName.TrimEnd('\', '/')
    $repoLeafName = Split-Path -Leaf $repoRootNorm
    $fullTarget = ""
    $relTarget = ""

    # 1. Check if input is a Full Drive Path (e.g. E:\proj\repo\sub\file.md or E:/proj/repo/sub)
    #    or a drive-root path (\proj\repo\sub\file.md) that resolves inside $repoRootNorm
    $isDriveRooted = ($clean -match '^[a-zA-Z]:[\\/]')
    $isSlashRootedInsideRepo = $false
    if (-not $isDriveRooted -and $clean -match '^[\\/]') {
        try {
            $probeRooted = [System.IO.Path]::GetFullPath(($clean -replace '/', '\')).TrimEnd('\', '/')
            if ($probeRooted -ieq $repoRootNorm -or $probeRooted.StartsWith("$repoRootNorm\", [System.StringComparison]::OrdinalIgnoreCase)) {
                $isSlashRootedInsideRepo = $true
            }
        } catch {}
    }

    if ($isDriveRooted -or $isSlashRootedInsideRepo) {
        $candidateFull = [System.IO.Path]::GetFullPath(($clean -replace '/', '\')).TrimEnd('\', '/')
        if (Test-Path -LiteralPath $candidateFull) {
            $candidateFull = (Get-Item -LiteralPath $candidateFull -Force).FullName.TrimEnd('\', '/')
        }
        $isInsideRepo = ($candidateFull -ieq $repoRootNorm) -or $candidateFull.StartsWith("$repoRootNorm\", [System.StringComparison]::OrdinalIgnoreCase)
        if (-not $isInsideRepo) {
            return [PSCustomObject]@{
                IsValid      = $false
                ErrorMessage = "Full drive path '$candidateFull' is outside selected repository '$repoRootNorm'."
            }
        }
        $fullTarget = $candidateFull
        if ($candidateFull.Length -gt $repoRootNorm.Length) {
            $relTarget = $candidateFull.Substring($repoRootNorm.Length).TrimStart('\', '/') -replace '\\', '/'
        } else {
            $relTarget = "."
        }
    } else {
        # 2. Repo-Relative Path (e.g. brief\file.md, brief/file.md, .\brief\file.md)
        #    or Workspace-Relative Path with repo prefix (e.g. repo-name\brief\file.md)
        $relClean = $clean -replace '^\.[\\/]', '' -replace '\\', '/'
        $relClean = $relClean.TrimStart('/').TrimEnd('/')
        if ([string]::IsNullOrWhiteSpace($relClean)) { $relClean = "." }

        if ($relClean -ieq $repoLeafName) {
            $relClean = "."
        } elseif ($relClean.StartsWith("$repoLeafName/", [System.StringComparison]::OrdinalIgnoreCase)) {
            $directInsideRepo = Join-Path $repoRootNorm ($relClean -replace '/', '\')
            if (-not (Test-Path -LiteralPath $directInsideRepo)) {
                $relClean = $relClean.Substring($repoLeafName.Length + 1).TrimStart('/')
                if ([string]::IsNullOrWhiteSpace($relClean)) { $relClean = "." }
            }
        } else {
            $directInsideRepo = Join-Path $repoRootNorm ($relClean -replace '/', '\')
            if (-not (Test-Path -LiteralPath $directInsideRepo)) {
                try {
                    $cwdCandidate = [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path ($clean -replace '/', '\'))).TrimEnd('\', '/')
                    if ($cwdCandidate -ieq $repoRootNorm -or $cwdCandidate.StartsWith("$repoRootNorm\", [System.StringComparison]::OrdinalIgnoreCase)) {
                        if ($cwdCandidate.Length -gt $repoRootNorm.Length) {
                            $relClean = $cwdCandidate.Substring($repoRootNorm.Length).TrimStart('\', '/') -replace '\\', '/'
                        } else {
                            $relClean = "."
                        }
                    }
                } catch {}
            }
        }

        $candidateRepoFull = if ($relClean -eq ".") { $repoRootNorm } else { Join-Path $repoRootNorm ($relClean -replace '/', '\') }
        if (Test-Path -LiteralPath $candidateRepoFull) {
            $exactDiskFull = (Get-Item -LiteralPath $candidateRepoFull -Force).FullName.TrimEnd('\', '/')
            $fullTarget = $exactDiskFull
            if ($exactDiskFull.Length -gt $repoRootNorm.Length) {
                $relTarget = $exactDiskFull.Substring($repoRootNorm.Length).TrimStart('\', '/') -replace '\\', '/'
            } else {
                $relTarget = "."
            }
        } else {
            $relTarget = $relClean
            $fullTarget = $candidateRepoFull
        }
    }

    $scopeType = "Folder"
    if (Test-Path -LiteralPath $fullTarget -PathType Leaf) {
        $scopeType = "File"
    } elseif (Test-Path -LiteralPath $fullTarget -PathType Container) {
        $scopeType = "Folder"
    } else {
        $ext = [System.IO.Path]::GetExtension($relTarget)
        if (-not [string]::IsNullOrWhiteSpace($ext)) {
            $scopeType = "File"
        }
    }

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

            if ($scopeType -eq "File" -and ($rawFile -replace '\\', '/') -ine ($relTarget -replace '\\', '/')) {
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

    if ($allScopedFiles.Count -eq 0 -and $AllowCleanTrackedFiles -and (Test-Path -LiteralPath $fullTarget)) {
        $lsArgs = if ($relTarget -eq ".") { @("ls-files") } else { @("ls-files", "--", $relTarget) }
        $lsRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs $lsArgs
        if ($lsRes.Success) {
            foreach ($trackedLine in $lsRes.Output) {
                $tf = $trackedLine.Trim().Trim('"')
                if ([string]::IsNullOrWhiteSpace($tf)) { continue }
                if ($scopeType -eq "File" -and ($tf -replace '\\', '/') -ine ($relTarget -replace '\\', '/')) { continue }
                if (-not $seen.Add($tf)) { continue }
                $itemObj = [PSCustomObject]@{
                    RelativePath = $tf
                    StateCode    = "M"
                    ScopeSource  = if ($scopeType -eq "File") { "Custom Exact File ($relTarget)" } else { "Custom Folder Scope ($relTarget)" }
                    IsNewFile    = $false
                    IsModified   = $true
                }
                [void]$allScopedFiles.Add($itemObj)
                [void]$modifiedOnlyFiles.Add($itemObj)
            }
        }
    }

    if ($allScopedFiles.Count -eq 0) {
        if (-not (Test-Path -LiteralPath $fullTarget)) {
            return [PSCustomObject]@{
                IsValid      = $false
                ErrorMessage = "Custom path '$relTarget' was not found inside repository '$repoRootNorm'."
            }
        }
        return [PSCustomObject]@{
            IsValid      = $false
            ErrorMessage = "Custom path '$relTarget' has 0 modified/staged/untracked files in git status."
        }
    }

    return [PSCustomObject]@{
        IsValid           = $true
        ScopeType         = $scopeType
        RelativeTarget    = $relTarget
        FullTarget        = $fullTarget
        AllScopedFiles    = $allScopedFiles.ToArray()
        ModifiedOnlyFiles = $modifiedOnlyFiles.ToArray()
        NewFilesDetected  = $newFilesDetected.ToArray()
        HasNewFiles       = ($newFilesDetected.Count -gt 0)
    }
}

function Get-CandidateFilesByOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 5)]
        [int]$Option
    )

    $effectiveOpt = $Option
    $results = [System.Collections.Generic.List[object]]::new()
    $seenFiles = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    if ($effectiveOpt -in @(1, 2)) {
        $stagedRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("diff", "--cached", "--name-status")
        if ($stagedRes.Success) {
            foreach ($line in $stagedRes.Output) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = $line -split "`t"
                if ($parts.Count -ge 2) {
                    $statusRaw = $parts[0].Trim()
                    $statusChar = $statusRaw.Substring(0, 1).ToUpperInvariant()
                    $filePath = if ($parts.Count -ge 3 -and ($statusChar -in @("R", "C"))) { $parts[2].Trim() } else { $parts[1].Trim() }

                    if ($effectiveOpt -eq 1 -and $statusChar -ne "M") {
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
    } elseif ($effectiveOpt -eq 3) {
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
    } elseif ($effectiveOpt -eq 4) {
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

    return $results.ToArray()
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
        # ======================================================================
        # CASE C: ALL COMMIT STATE ($TargetCommit.IsAllCommits == $true)
        # Overwrites the matched files across ALL commits in branch history
        # ======================================================================
        if ($TargetCommit.IsAllCommits) {
            $filterStatements = [System.Collections.Generic.List[string]]::new()

            foreach ($cf in $CandidateFiles) {
                $normRel = ($cf.RelativePath -replace '\\', '/')
                $fullDiskPath = Join-Path $RepoPath ($cf.RelativePath -replace '/', '\')

                if (Test-Path -LiteralPath $fullDiskPath -PathType Leaf) {
                    $hashRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("hash-object", "-w", "--", $fullDiskPath)
                    if ($hashRes.Success -and $hashRes.Output.Count -gt 0) {
                        $blobSha = $hashRes.Output[0].Trim()
                        # Replace blob in every commit where this path exists in the commit's index
                        [void]$filterStatements.Add("if git rev-parse -q --verify `":$normRel`" >/dev/null 2>&1; then git update-index --add --cacheinfo 100644,$blobSha,`"$normRel`"; fi")
                    }
                } else {
                    # File was deleted -> remove from index across commits where it existed
                    [void]$filterStatements.Add("git rm --cached --ignore-unmatch -- `"$normRel`" >/dev/null 2>&1")
                }
            }

            if ($filterStatements.Count -gt 0) {
                $indexFilterScript = $filterStatements -join "; "
                $prevSquelch = $env:FILTER_BRANCH_SQUELCH_WARNING
                $env:FILTER_BRANCH_SQUELCH_WARNING = "1"
                try {
                    $fbRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @(
                        "filter-branch", "-f", "--index-filter", $indexFilterScript, "--", "HEAD"
                    )
                    if (-not $fbRes.Success) {
                        return [PSCustomObject]@{
                            Success   = $false
                            BackupRef = $backupRef
                            Message   = "All-commit-state filter-branch failed: $($fbRes.Output -join ' ')"
                        }
                    }
                } finally {
                    $env:FILTER_BRANCH_SQUELCH_WARNING = $prevSquelch
                }
            }

            # Also ensure HEAD has any newly added files from $CandidateFiles staged and amended into HEAD
            foreach ($rp in $relPaths) {
                [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("add", "-A", "--", $rp))
            }
            $stagedCheck = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("diff", "--cached", "--name-only")
            if ($stagedCheck.Success -and $stagedCheck.Output.Count -gt 0) {
                $prevCommitterDate = $env:GIT_COMMITTER_DATE
                $env:GIT_COMMITTER_DATE = $TargetCommit.CommitDateIso
                try {
                    [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("commit", "--amend", "--no-edit"))
                } finally {
                    $env:GIT_COMMITTER_DATE = $prevCommitterDate
                }
            }

            $newHeadRes = Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("rev-parse", "--short", "HEAD")
            $newHeadShort = if ($newHeadRes.Success -and $newHeadRes.Output.Count -gt 0) { $newHeadRes.Output[0].Trim() } else { "HEAD" }

            return [PSCustomObject]@{
                Success      = $true
                NewHeadShort = $newHeadShort
                BackupRef    = $backupRef
                Message      = "Successfully overwrote $($CandidateFiles.Count) file(s) across ALL commits in branch history (New HEAD: $newHeadShort)."
            }
        }

        # ======================================================================
        # SINGLE COMMIT MODE (Options 1..5 on HEAD or specific historical SHA)
        # ======================================================================
        if ($Option -eq 1) {
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
            [void](Invoke-GitRepoCommand -RepoPath $RepoPath -GitArgs @("add", "-A"))
        }

        $prevCommitterDate = $env:GIT_COMMITTER_DATE
        $prevSeqEditor = $env:GIT_SEQUENCE_EDITOR

        try {
            if ($TargetCommit.IsHead) {
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
        history   = $histList.ToArray()
    }

    try {
        $json = $payload | ConvertTo-Json -Depth 6
        Set-Content -LiteralPath $jsonPath -Value $json -Force -Encoding UTF8
    } catch {}
    return $jsonPath
}

function Read-RequiredInput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PromptText
    )
    while ($true) {
        Write-Host -NoNewline "$PromptText" -ForegroundColor Yellow
        $raw = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            return $raw.Trim()
        }
        Write-Host "  [REQUIRED] Empty Enter is disabled (No Default Enter). Please provide an explicit value or type 'q' to quit." -ForegroundColor Red
    }
}

function Select-TargetRepositoryInteractive {
    [CmdletBinding()]
    param(
        [string]$RepoParam = "",
        [int]$PageSize = 20
    )

    if (-not [string]::IsNullOrWhiteSpace($RepoParam)) {
        if (Test-GitRepository -Path $RepoParam) {
            return (Resolve-Path -LiteralPath $RepoParam).Path
        }
        throw "[ERROR] Provided -Repo path is not a valid Git repository: $RepoParam"
    }

    $discoveredRepos = @(Get-DiscoveredGitRepositories -BasePath (Get-Location).Path)
    $shownCount = [Math]::Min($PageSize, $discoveredRepos.Count)

    Write-Host "  [ STEP 1 / 3 ] SELECT TARGET GIT REPOSITORY" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
    if ($discoveredRepos.Count -gt 0) {
        for ($i = 0; $i -lt $shownCount; $i++) {
            $r = $discoveredRepos[$i]
            $num = $i + 1
            Write-Host ("    [ {0,2} ] {1,-28} ({2}) [branch: {3}]" -f $num, $r.Name, $r.FullPath, $r.BranchName) -ForegroundColor Gray
        }
        if ($shownCount -lt $discoveredRepos.Count) {
            Write-Host ("    [ more ] Load +{0} more repositories (showing 1..{1} of {2})" -f $PageSize, $shownCount, $discoveredRepos.Count) -ForegroundColor DarkCyan
        }
        Write-Host ""
    }

    while ($true) {
        $moreHint = if ($shownCount -lt $discoveredRepos.Count) { " / 'more' (+$PageSize)" } else { "" }
        $repoInput = Read-RequiredInput -PromptText "  >> Enter repo number [1..$shownCount]$moreHint or full repository path (or 'q' to quit): "
        if ($repoInput -ieq "q" -or $repoInput -ieq "quit") {
            return $null
        }

        if ($repoInput -ieq "more") {
            if ($shownCount -ge $discoveredRepos.Count) {
                Write-Host "  [INFO] All $($discoveredRepos.Count) discovered repositories are already displayed [1..$shownCount]." -ForegroundColor Yellow
                continue
            }
            $prevShown = $shownCount
            $shownCount = [Math]::Min($shownCount + $PageSize, $discoveredRepos.Count)
            for ($i = $prevShown; $i -lt $shownCount; $i++) {
                $r = $discoveredRepos[$i]
                $num = $i + 1
                Write-Host ("    [ {0,2} ] {1,-28} ({2}) [branch: {3}]" -f $num, $r.Name, $r.FullPath, $r.BranchName) -ForegroundColor Gray
            }
            if ($shownCount -lt $discoveredRepos.Count) {
                Write-Host ("    [ more ] Load +{0} more repositories (showing 1..{1} of {2})" -f $PageSize, $shownCount, $discoveredRepos.Count) -ForegroundColor DarkCyan
            }
            Write-Host ""
            continue
        }

        $idx = 0
        if ([int]::TryParse($repoInput, [ref]$idx) -and $idx -ge 1 -and $idx -le $shownCount) {
            return $discoveredRepos[$idx - 1].FullPath
        }

        $cleanCandidate = $repoInput.Trim('"', "'")
        if (Test-GitRepository -Path $cleanCandidate) {
            return (Resolve-Path -LiteralPath $cleanCandidate).Path
        }

        Write-Host "  [INVALID REPO] '$repoInput' is not a valid index [1..$shownCount] or Git repository path." -ForegroundColor Red
    }
}

function Select-TargetCommitInteractive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [string]$CommitIdParam = "",

        [int]$PageSize = 20
    )

    $totalCommits = Get-RepoTotalCommitCount -RepoPath $RepoPath
    if ($totalCommits -le 0) {
        throw "[ERROR] Repository '$RepoPath' has no commits yet."
    }

    $currentLimit = $PageSize
    $loadedCommits = @(Get-RepoRecentCommits -RepoPath $RepoPath -Limit $currentLimit -Skip 0)

    if (-not [string]::IsNullOrWhiteSpace($CommitIdParam)) {
        $resolvedDirect = Resolve-TargetCommit -RepoPath $RepoPath -CommitInput $CommitIdParam -RecentCommits $loadedCommits
        if (-not $resolvedDirect) {
            throw "[ERROR] Could not resolve Commit ID '$CommitIdParam' in repository '$RepoPath'."
        }
        return $resolvedDirect
    }

    Write-Host "  [ STEP 2 / 3 ] SELECT TARGET COMMIT ID TO OVERWRITE INTO (1..$($loadedCommits.Count) of $totalCommits)" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
    foreach ($c in $loadedCommits) {
        $headTag = if ($c.IsHead) { " (HEAD)" } else { "       " }
        Write-Host ("    [ {0,3} ] {1}{2} | {3} | {4}" -f $c.Index, $c.ShortHash, $headTag, $c.Date, $c.Subject) -ForegroundColor Gray
    }
    Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
    if ($loadedCommits.Count -lt $totalCommits) {
        $remaining = $totalCommits - $loadedCommits.Count
        $nextBatchCount = [Math]::Min($PageSize, $remaining)
        Write-Host ("    [ more    ] Load +{0} older commits (showing 1..{1} of {2})" -f $nextBatchCount, $loadedCommits.Count, $totalCommits) -ForegroundColor DarkCyan
    }
    Write-Host ("    [ L / all ] ALL COMMIT STATE (Overwrite file(s) across ALL {0} commits in history)" -f $totalCommits) -ForegroundColor Cyan
    Write-Host ""

    while ($true) {
        $morePromptTag = if ($loadedCommits.Count -lt $totalCommits) { " / 'more' (+$PageSize)" } else { "" }
        $commitInput = Read-RequiredInput -PromptText "  >> Enter commit id (SHA / HEAD / [1..$($loadedCommits.Count)]$morePromptTag / 'L' or 'all' for All Commit State, or 'q' to quit): "
        if ($commitInput -ieq "q" -or $commitInput -ieq "quit") {
            return $null
        }

        if ($commitInput -ieq "more") {
            if ($loadedCommits.Count -ge $totalCommits) {
                Write-Host "  [INFO] All $totalCommits commit(s) in branch history are already displayed [1..$($loadedCommits.Count)]." -ForegroundColor Yellow
                continue
            }

            $prevCount = $loadedCommits.Count
            $nextBatch = @(Get-RepoRecentCommits -RepoPath $RepoPath -Limit $PageSize -Skip $prevCount)
            if ($nextBatch.Count -eq 0) {
                Write-Host "  [INFO] No additional commits found beyond #$prevCount." -ForegroundColor Yellow
                continue
            }

            $loadedCommits = @($loadedCommits + $nextBatch)
            Write-Host ""
            Write-Host ("  [ +$($nextBatch.Count) MORE COMMITS LOADED: #$($prevCount + 1) .. #$($loadedCommits.Count) of $totalCommits ]" ) -ForegroundColor Cyan
            Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
            foreach ($c in $nextBatch) {
                $headTag = if ($c.IsHead) { " (HEAD)" } else { "       " }
                Write-Host ("    [ {0,3} ] {1}{2} | {3} | {4}" -f $c.Index, $c.ShortHash, $headTag, $c.Date, $c.Subject) -ForegroundColor Gray
            }
            Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
            if ($loadedCommits.Count -lt $totalCommits) {
                $remaining = $totalCommits - $loadedCommits.Count
                $nextBatchCount = [Math]::Min($PageSize, $remaining)
                Write-Host ("    [ more    ] Load +{0} older commits (showing 1..{1} of {2})" -f $nextBatchCount, $loadedCommits.Count, $totalCommits) -ForegroundColor DarkCyan
            } else {
                Write-Host ("    [ END     ] All {0} commits in branch history are now loaded [1..{0}]" -f $totalCommits) -ForegroundColor DarkGreen
            }
            Write-Host ("    [ L / all ] ALL COMMIT STATE (Overwrite file(s) across ALL {0} commits in history)" -f $totalCommits) -ForegroundColor Cyan
            Write-Host ""
            continue
        }

        $targetCommitObj = Resolve-TargetCommit -RepoPath $RepoPath -CommitInput $commitInput -RecentCommits $loadedCommits
        if ($targetCommitObj) {
            return $targetCommitObj
        }

        Write-Host "  [INVALID COMMIT] '$commitInput' did not match any commit SHA, list index [1..$($loadedCommits.Count)], 'more', or 'L'/'all'." -ForegroundColor Red
    }
}

function Select-OverwriteOptionInteractive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [int]$OptionParam = 0,

        [string]$CustomPathParam = "",

        [int]$CustomNewFileActionParam = 0,

        [bool]$IsAllCommits = $false
    )

    $opt1Files = @(Get-CandidateFilesByOption -RepoPath $RepoPath -Option 1)
    $opt2Files = @(Get-CandidateFilesByOption -RepoPath $RepoPath -Option 2)
    $opt3Files = @(Get-CandidateFilesByOption -RepoPath $RepoPath -Option 3)
    $opt4Files = @(Get-CandidateFilesByOption -RepoPath $RepoPath -Option 4)

    $selectedOption = 0
    if ($OptionParam -ge 1 -and $OptionParam -le 5) {
        $selectedOption = $OptionParam
    } else {
        Write-Host "  [ STEP 3 / 3 ] SELECT FILE OVERWRITE OPSI (1..5)" -ForegroundColor Cyan
        Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ("    [ 1 ] Overwrite staged files | type state: modified   ({0} matching file(s))" -f $opt1Files.Count) -ForegroundColor Gray
        Write-Host ("    [ 2 ] Overwrite staged files | type state: all        ({0} matching file(s))" -f $opt2Files.Count) -ForegroundColor Gray
        Write-Host ("    [ 3 ] Overwrite all files    | type state: modified   ({0} matching file(s))" -f $opt3Files.Count) -ForegroundColor Gray
        Write-Host ("    [ 4 ] Overwrite all files    | type state: all        ({0} matching file(s))" -f $opt4Files.Count) -ForegroundColor Gray
        Write-Host ("    [ 5 ] Custom path            | relative or drive root (folder scope or exact file)") -ForegroundColor Gray
        Write-Host ""

        while ($selectedOption -lt 1 -or $selectedOption -gt 5) {
            $optInput = Read-RequiredInput -PromptText "  >> Enter opsi [1 / 2 / 3 / 4 / 5] (or 'q' to quit): "
            if ($optInput -ieq "q" -or $optInput -ieq "quit") {
                return $null
            }

            $parsedOpt = 0
            if ([int]::TryParse($optInput, [ref]$parsedOpt) -and $parsedOpt -ge 1 -and $parsedOpt -le 5) {
                $selectedOption = $parsedOpt
            } else {
                Write-Host "  [INVALID OPSI] Please enter strictly 1, 2, 3, 4, or 5 (No Default Enter)." -ForegroundColor Red
            }
        }
    }

    $customScopeSummary = ""
    $chosenCustomRelPath = ""
    $chosenSubAction = 0
    $candidateFiles = @()

    if ($selectedOption -eq 5) {
        $resolvedScope = $null
        if (-not [string]::IsNullOrWhiteSpace($CustomPathParam)) {
            $resolvedScope = Resolve-CustomScopeTarget -RepoPath $RepoPath -RawCustomPath $CustomPathParam -AllowCleanTrackedFiles $IsAllCommits
            if (-not $resolvedScope.IsValid) {
                throw "[ERROR] $($resolvedScope.ErrorMessage)"
            }
        } else {
            Write-Host ""
            Write-Host "  [ OPSI 5: CUSTOM PATH SCOPE ]" -ForegroundColor Cyan
            Write-Host "    - Enter 'path/subfolder' for Folder Scope, or 'path/subfolder/file.md' for Exact Single-File Scope." -ForegroundColor DarkGray
            Write-Host "    - Accepts repo-relative path, workspace-relative path (repo\sub\file.md), or full path from drive root." -ForegroundColor DarkGray
            while (-not $resolvedScope) {
                $rawCustom = Read-RequiredInput -PromptText "  >> Enter custom path (relative or full drive path, or 'q' to quit): "
                if ($rawCustom -ieq "q" -or $rawCustom -ieq "quit") {
                    return $null
                }
                $candScope = Resolve-CustomScopeTarget -RepoPath $RepoPath -RawCustomPath $rawCustom -AllowCleanTrackedFiles $IsAllCommits
                if ($candScope.IsValid) {
                    $resolvedScope = $candScope
                } else {
                    Write-Host "  [INVALID PATH] $($candScope.ErrorMessage)" -ForegroundColor Red
                }
            }
        }

        $chosenCustomRelPath = $resolvedScope.RelativeTarget
        Write-Host "  [CUSTOM SCOPE] Type: $($resolvedScope.ScopeType) | Target: $($resolvedScope.RelativeTarget)" -ForegroundColor Green

        if ($resolvedScope.HasNewFiles) {
            Write-Host ""
            Write-Host "  [SCOPED NEW FILE DETECTED] Found $($resolvedScope.NewFilesDetected.Count) new/untracked file(s) inside '$($resolvedScope.RelativeTarget)':" -ForegroundColor Yellow
            foreach ($nf in $resolvedScope.NewFilesDetected) {
                Write-Host "    [$($nf.StateCode)] $($nf.RelativePath)" -ForegroundColor DarkYellow
            }
            Write-Host ""
            Write-Host "    [ 1 ] all           (include new + modified files in scope: $($resolvedScope.AllScopedFiles.Count) file(s))" -ForegroundColor Gray
            Write-Host "    [ 2 ] modified only (M only, exclude new files: $($resolvedScope.ModifiedOnlyFiles.Count) file(s))" -ForegroundColor Gray
            Write-Host "    [ 3 ] cancel        (abort operation)" -ForegroundColor Gray
            Write-Host ""

            $subChoice = 0
            if ($CustomNewFileActionParam -ge 1 -and $CustomNewFileActionParam -le 3) {
                $subChoice = $CustomNewFileActionParam
            } else {
                while ($subChoice -lt 1 -or $subChoice -gt 3) {
                    $subInput = Read-RequiredInput -PromptText "  >> Select scoped state mode [1 / 2 / 3] (No Default Enter): "
                    if ($subInput -ieq "q" -or $subInput -ieq "quit" -or $subInput -eq "3" -or $subInput -ieq "cancel") {
                        return $null
                    }
                    $parsedSub = 0
                    if ([int]::TryParse($subInput, [ref]$parsedSub) -and $parsedSub -in @(1, 2, 3)) {
                        $subChoice = $parsedSub
                    } else {
                        Write-Host "  [INVALID CHOICE] Please enter strictly 1 (all), 2 (modified only), or 3 (cancel)." -ForegroundColor Red
                    }
                }
            }

            $chosenSubAction = $subChoice
            if ($subChoice -eq 3) {
                return $null
            } elseif ($subChoice -eq 1) {
                $candidateFiles = @($resolvedScope.AllScopedFiles)
                $customScopeSummary = "$($resolvedScope.ScopeType): $($resolvedScope.RelativeTarget) | Sub-mode: 1. all"
            } elseif ($subChoice -eq 2) {
                $candidateFiles = @($resolvedScope.ModifiedOnlyFiles)
                $customScopeSummary = "$($resolvedScope.ScopeType): $($resolvedScope.RelativeTarget) | Sub-mode: 2. modified only"
            }
        } else {
            $candidateFiles = @($resolvedScope.AllScopedFiles)
            $customScopeSummary = "$($resolvedScope.ScopeType): $($resolvedScope.RelativeTarget) (Modified only, 0 new files)"
        }
    } else {
        $candidateFiles = switch ($selectedOption) {
            1 { $opt1Files }
            2 { $opt2Files }
            3 { $opt3Files }
            4 { $opt4Files }
        }
    }

    return [PSCustomObject]@{
        SelectedOption      = $selectedOption
        CandidateFiles      = @($candidateFiles)
        CustomScopeSummary  = $customScopeSummary
        ChosenCustomRelPath = $chosenCustomRelPath
        ChosenSubAction     = $chosenSubAction
    }
}

function Confirm-CommitOverwriteOverview {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$ActiveBranch,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TargetCommit,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$OptionSelection,

        [Parameter(Mandatory = $true)]
        [string]$OptionsJsonPath,

        [switch]$AutoConfirm
    )

    $selectedOption = $OptionSelection.SelectedOption
    $candidateFiles = @($OptionSelection.CandidateFiles)
    $customScopeSummary = $OptionSelection.CustomScopeSummary

    $strategyText = if ($TargetCommit.IsAllCommits) {
        "All-Commit-State Index Filter (git filter-branch --index-filter across all $($TargetCommit.TotalCommits) commit(s))"
    } elseif ($TargetCommit.IsHead) {
        "Fast-Path HEAD Amend (git commit --amend --no-edit + original CommitDate)"
    } else {
        "Historical Fixup + Non-Interactive Autosquash Rebase (--committer-date-is-author-date)"
    }

    $remoteWarning = if ($TargetCommit.IsPushedRemote) {
        "PUSHED TO REMOTE ($($TargetCommit.RemoteBranches -join ', ')) -> Will require 'git push --force-with-lease'"
    } else {
        "Local Commit Only (Not yet pushed to remote)"
    }

    Write-Host ""
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "              COMMITTED FILE OVERWRITE - PRE-FLIGHT BRIEFED OVERVIEW            " -ForegroundColor Yellow
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  Repository Path   : $RepoPath" -ForegroundColor White
    Write-Host "  Active Branch     : $ActiveBranch" -ForegroundColor White
    Write-Host "  Target Commit ID  : $($TargetCommit.ShortHash) ($($TargetCommit.FullHash))" -ForegroundColor Green
    Write-Host "  Commit Subject    : `"$($TargetCommit.Subject)`" ($($TargetCommit.DateShort))" -ForegroundColor Gray
    Write-Host "  Selected Opsi     : $(Get-OptionDescription -Option $selectedOption -CustomScopeSummary $customScopeSummary -IsAllCommits ([bool]$TargetCommit.IsAllCommits))" -ForegroundColor Cyan
    Write-Host "  Rewrite Strategy  : $strategyText" -ForegroundColor Gray
    Write-Host "  Commit Timestamp  : Preserve Original CommitDate ($($TargetCommit.CommitDateIso))" -ForegroundColor Gray
    Write-Host "  Remote Status     : $remoteWarning" -ForegroundColor $(if ($TargetCommit.IsPushedRemote) { "Yellow" } else { "Green" })
    Write-Host "  Options JSON      : $OptionsJsonPath" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  Files To Overwrite ($($candidateFiles.Count)):" -ForegroundColor White
    foreach ($cf in $candidateFiles) {
        Write-Host ("    [{0,-2}] {1} ({2})" -f $cf.StateCode, $cf.RelativePath, $cf.ScopeSource) -ForegroundColor Gray
    }
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""

    if ($AutoConfirm) {
        return $true
    }

    while ($true) {
        $confirmInput = Read-RequiredInput -PromptText "  >> Confirm commit file overwrite? Type 'yes' to proceed or 'no' to abort (No Default Enter): "
        if ($confirmInput -ceq "yes" -or $confirmInput -ieq "yes") {
            return $true
        }
        if ($confirmInput -ieq "no" -or $confirmInput -ieq "n" -or $confirmInput -ieq "q" -or $confirmInput -ieq "abort") {
            return $false
        }
        Write-Host "  [INVALID CONFIRMATION] Type strictly 'yes' to execute or 'no' to cancel." -ForegroundColor Red
    }
}

Export-ModuleMember -Function @(
    'Invoke-GitRepoCommand',
    'Test-GitRepository',
    'Get-DiscoveredGitRepositories',
    'Get-RepoTotalCommitCount',
    'Get-RepoRecentCommits',
    'Resolve-TargetCommit',
    'Get-OptionDescription',
    'Resolve-CustomScopeTarget',
    'Get-CandidateFilesByOption',
    'Invoke-CommitFileOverwrite',
    'Get-CommitOverwriteOptionsJsonPath',
    'Import-CommitOverwriteOptions',
    'Save-CommitOverwriteOptions',
    'Read-RequiredInput',
    'Select-TargetRepositoryInteractive',
    'Select-TargetCommitInteractive',
    'Select-OverwriteOptionInteractive',
    'Confirm-CommitOverwriteOverview'
)
