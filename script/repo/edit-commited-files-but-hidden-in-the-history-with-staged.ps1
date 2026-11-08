<#
.SYNOPSIS
    Historical Commit File Overwrite Engine (Context: Repo)
.DESCRIPTION
    Replaces files inside an existing commit (HEAD or any historical commit SHA)
    without creating extra fixup commits in git log.
    Enforces strict Zero-Default-Enter across all interactive prompts:
      1. repo
      2. commit id
      3. opsi (1..5: Staged vs. All Files x Modified vs. All States, or 5 = Custom Path)
      4. Pre-Flight Briefed Overview confirmation ('yes')
#>
[CmdletBinding()]
param(
    [string]$Repo = "",
    [string]$CommitId = "",
    [int]$Option = 0,
    [string]$CustomPath = "",
    [int]$CustomNewFileAction = 0,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot
$executorBaseName = if ($PSCommandPath) {
    [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
} else {
    "edit-commited-files-but-hidden-in-the-history-with-staged"
}
$adapterPath = Join-Path $scriptDir "adapter\$executorBaseName.psm1"
$optionsJsonPath = Join-Path $scriptDir "adapter\$executorBaseName.json"

if (-not (Test-Path -LiteralPath $adapterPath)) {
    Write-Error "[ERROR] Required adapter module not found at: $adapterPath"
    exit 1
}
Import-Module -Name $adapterPath -Force

# Load persisted executor options from adapter/<executor>.json (save-option-as-exact-executor-name-json)
$persistedState = Import-CommitOverwriteOptions -ExecutorBaseName $executorBaseName

# Verify git availability
$gitVer = git --version 2>$null
if (-not $gitVer) {
    Write-Error "[ERROR] Git CLI is not installed or not on PATH."
    exit 1
}

function Read-RequiredInput {
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

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  COMMITTED FILE OVERWRITE (HIDDEN IN HISTORY WITH STAGED / WORKING TREE)       " -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  Rule: Strict No-Default-Enter. Every prompt requires an explicit selection." -ForegroundColor DarkGray
Write-Host ""

# ==============================================================================
# STEP 1: PROMPT FOR REPO (No Default Enter)
# ==============================================================================
$resolvedRepoPath = ""
$discoveredRepos = @(Get-DiscoveredGitRepositories -BasePath (Get-Location).Path)

if (-not [string]::IsNullOrWhiteSpace($Repo)) {
    if (Test-GitRepository -Path $Repo) {
        $resolvedRepoPath = (Resolve-Path -LiteralPath $Repo).Path
    } else {
        Write-Error "[ERROR] Provided -Repo path is not a valid Git repository: $Repo"
        exit 1
    }
} else {
    Write-Host "  [ STEP 1 / 3 ] SELECT TARGET GIT REPOSITORY" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
    if ($discoveredRepos.Count -gt 0) {
        for ($i = 0; $i -lt $discoveredRepos.Count; $i++) {
            $r = $discoveredRepos[$i]
            $num = $i + 1
            Write-Host ("    [ {0,2} ] {1,-28} ({2}) [branch: {3}]" -f $num, $r.Name, $r.FullPath, $r.BranchName) -ForegroundColor Gray
        }
        Write-Host ""
    }

    while (-not $resolvedRepoPath) {
        $repoInput = Read-RequiredInput -PromptText "  >> Enter repo number [1..$($discoveredRepos.Count)] or full repository path (or 'q' to quit): "
        if ($repoInput -ieq "q" -or $repoInput -ieq "quit") {
            Write-Host "  [ABORTED] Operation cancelled by user." -ForegroundColor Yellow
            exit 0
        }

        $idx = 0
        if ([int]::TryParse($repoInput, [ref]$idx) -and $idx -ge 1 -and $idx -le $discoveredRepos.Count) {
            $resolvedRepoPath = $discoveredRepos[$idx - 1].FullPath
            break
        }

        $cleanCandidate = $repoInput.Trim('"', "'")
        if (Test-GitRepository -Path $cleanCandidate) {
            $resolvedRepoPath = (Resolve-Path -LiteralPath $cleanCandidate).Path
            break
        }

        Write-Host "  [INVALID REPO] '$repoInput' is not a valid index or Git repository path." -ForegroundColor Red
    }
}

$branchCheck = Invoke-GitRepoCommand -RepoPath $resolvedRepoPath -GitArgs @("rev-parse", "--abbrev-ref", "HEAD")
$activeBranch = if ($branchCheck.Success -and $branchCheck.Output.Count -gt 0) { $branchCheck.Output[0].Trim() } else { "HEAD" }

Write-Host "  [SELECTED REPO] $resolvedRepoPath (branch: $activeBranch)" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# STEP 2: PROMPT FOR COMMIT ID (No Default Enter)
# ==============================================================================
$recentCommits = @(Get-RepoRecentCommits -RepoPath $resolvedRepoPath -Limit 15)
if ($recentCommits.Count -eq 0) {
    Write-Error "[ERROR] Repository '$resolvedRepoPath' has no commits yet."
    exit 1
}

$targetCommitObj = $null
if (-not [string]::IsNullOrWhiteSpace($CommitId)) {
    $targetCommitObj = Resolve-TargetCommit -RepoPath $resolvedRepoPath -CommitInput $CommitId -RecentCommits $recentCommits
    if (-not $targetCommitObj) {
        Write-Error "[ERROR] Could not resolve Commit ID '$CommitId' in repository '$resolvedRepoPath'."
        exit 1
    }
} else {
    Write-Host "  [ STEP 2 / 3 ] SELECT TARGET COMMIT ID TO OVERWRITE INTO" -ForegroundColor Cyan
    Write-Host "  ------------------------------------------------------------------------------" -ForegroundColor DarkGray
    foreach ($c in $recentCommits) {
        $headTag = if ($c.IsHead) { " (HEAD)" } else { "       " }
        Write-Host ("    [ {0,2} ] {1}{2} | {3} | {4}" -f $c.Index, $c.ShortHash, $headTag, $c.Date, $c.Subject) -ForegroundColor Gray
    }
    Write-Host ""

    while (-not $targetCommitObj) {
        $commitInput = Read-RequiredInput -PromptText "  >> Enter commit id (SHA / HEAD) or list number [1..$($recentCommits.Count)] (or 'q' to quit): "
        if ($commitInput -ieq "q" -or $commitInput -ieq "quit") {
            Write-Host "  [ABORTED] Operation cancelled by user." -ForegroundColor Yellow
            exit 0
        }

        $targetCommitObj = Resolve-TargetCommit -RepoPath $resolvedRepoPath -CommitInput $commitInput -RecentCommits $recentCommits
        if (-not $targetCommitObj) {
            Write-Host "  [INVALID COMMIT] '$commitInput' did not match any commit SHA or list index." -ForegroundColor Red
        }
    }
}

$headLabel = if ($targetCommitObj.IsHead) { "HEAD (Latest Commit)" } else { "Historical Commit" }
Write-Host "  [SELECTED COMMIT] $($targetCommitObj.ShortHash) [$headLabel] - `"$($targetCommitObj.Subject)`"" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# STEP 3: PROMPT FOR OPSI 1..5 (No Default Enter)
# ==============================================================================
$opt1Files = @(Get-CandidateFilesByOption -RepoPath $resolvedRepoPath -Option 1)
$opt2Files = @(Get-CandidateFilesByOption -RepoPath $resolvedRepoPath -Option 2)
$opt3Files = @(Get-CandidateFilesByOption -RepoPath $resolvedRepoPath -Option 3)
$opt4Files = @(Get-CandidateFilesByOption -RepoPath $resolvedRepoPath -Option 4)

$selectedOption = 0
if ($Option -ge 1 -and $Option -le 5) {
    $selectedOption = $Option
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
            Write-Host "  [ABORTED] Operation cancelled by user." -ForegroundColor Yellow
            exit 0
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
    # ==========================================================================
    # STEP 3B: CUSTOM PATH INPUT & CONDITIONAL NEW-FILE SUB-PROMPT
    # ==========================================================================
    $resolvedScope = $null
    if (-not [string]::IsNullOrWhiteSpace($CustomPath)) {
        $resolvedScope = Resolve-CustomScopeTarget -RepoPath $resolvedRepoPath -RawCustomPath $CustomPath
        if (-not $resolvedScope.IsValid) {
            Write-Error "[ERROR] $($resolvedScope.ErrorMessage)"
            exit 1
        }
    } else {
        Write-Host ""
        Write-Host "  [ OPSI 5: CUSTOM PATH SCOPE ]" -ForegroundColor Cyan
        Write-Host "    - Enter 'path/subfolder' for Folder Scope, or 'path/subfolder/file.md' for Exact Single-File Scope." -ForegroundColor DarkGray
        Write-Host "    - Accepts either repo-relative path or full path from drive root." -ForegroundColor DarkGray
        while (-not $resolvedScope) {
            $rawCustom = Read-RequiredInput -PromptText "  >> Enter custom path (relative or full drive path, or 'q' to quit): "
            if ($rawCustom -ieq "q" -or $rawCustom -ieq "quit") {
                Write-Host "  [ABORTED] Operation cancelled by user." -ForegroundColor Yellow
                exit 0
            }
            $candScope = Resolve-CustomScopeTarget -RepoPath $resolvedRepoPath -RawCustomPath $rawCustom
            if ($candScope.IsValid) {
                $resolvedScope = $candScope
            } else {
                Write-Host "  [INVALID PATH] $($candScope.ErrorMessage)" -ForegroundColor Red
            }
        }
    }

    $chosenCustomRelPath = $resolvedScope.RelativeTarget
    Write-Host "  [CUSTOM SCOPE] Type: $($resolvedScope.ScopeType) | Target: $($resolvedScope.RelativeTarget)" -ForegroundColor Green

    # Check if new/untracked/added files exist inside this custom scope
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
        if ($CustomNewFileAction -ge 1 -and $CustomNewFileAction -le 3) {
            $subChoice = $CustomNewFileAction
        } else {
            while ($subChoice -lt 1 -or $subChoice -gt 3) {
                $subInput = Read-RequiredInput -PromptText "  >> Select scoped state mode [1 / 2 / 3] (No Default Enter): "
                if ($subInput -ieq "q" -or $subInput -ieq "quit" -or $subInput -eq "3" -or $subInput -ieq "cancel") {
                    Write-Host "  [CANCELLED] Custom scope operation cancelled by user." -ForegroundColor Yellow
                    exit 0
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
            Write-Host "  [CANCELLED] Custom scope operation cancelled by user." -ForegroundColor Yellow
            exit 0
        } elseif ($subChoice -eq 1) {
            $candidateFiles = $resolvedScope.AllScopedFiles
            $customScopeSummary = "$($resolvedScope.ScopeType): $($resolvedScope.RelativeTarget) | Sub-mode: 1. all"
        } elseif ($subChoice -eq 2) {
            $candidateFiles = $resolvedScope.ModifiedOnlyFiles
            $customScopeSummary = "$($resolvedScope.ScopeType): $($resolvedScope.RelativeTarget) | Sub-mode: 2. modified only"
        }
    } else {
        $candidateFiles = $resolvedScope.AllScopedFiles
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

if (-not $candidateFiles -or $candidateFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "  [EMPTY FILE SET] Opsi $selectedOption matched 0 changed files in '$resolvedRepoPath'." -ForegroundColor Red
    Write-Host "  Nothing to overwrite into commit $($targetCommitObj.ShortHash). Exiting cleanly." -ForegroundColor Yellow
    exit 1
}

# ==============================================================================
# STEP 4: PRE-FLIGHT BRIEFED OVERVIEW & EXPLICIT CONFIRMATION (No Default Enter)
# ==============================================================================
$strategyText = if ($targetCommitObj.IsHead) {
    "Fast-Path HEAD Amend (git commit --amend --no-edit + original CommitDate)"
} else {
    "Historical Fixup + Non-Interactive Autosquash Rebase (--committer-date-is-author-date)"
}

$remoteWarning = if ($targetCommitObj.IsPushedRemote) {
    "PUSHED TO REMOTE ($($targetCommitObj.RemoteBranches -join ', ')) -> Will require 'git push --force-with-lease'"
} else {
    "Local Commit Only (Not yet pushed to remote)"
}

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "              COMMITTED FILE OVERWRITE - PRE-FLIGHT BRIEFED OVERVIEW            " -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  Repository Path   : $resolvedRepoPath" -ForegroundColor White
Write-Host "  Active Branch     : $activeBranch" -ForegroundColor White
Write-Host "  Target Commit ID  : $($targetCommitObj.ShortHash) ($($targetCommitObj.FullHash))" -ForegroundColor Green
Write-Host "  Commit Subject    : `"$($targetCommitObj.Subject)`" ($($targetCommitObj.DateShort))" -ForegroundColor Gray
Write-Host "  Selected Opsi     : $(Get-OptionDescription -Option $selectedOption -CustomScopeSummary $customScopeSummary)" -ForegroundColor Cyan
Write-Host "  Rewrite Strategy  : $strategyText" -ForegroundColor Gray
Write-Host "  Commit Timestamp  : Preserve Original CommitDate ($($targetCommitObj.CommitDateIso))" -ForegroundColor Gray
Write-Host "  Remote Status     : $remoteWarning" -ForegroundColor $(if ($targetCommitObj.IsPushedRemote) { "Yellow" } else { "Green" })
Write-Host "  Options JSON      : $optionsJsonPath" -ForegroundColor DarkGray
Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Files To Overwrite Into Commit ($($candidateFiles.Count)):" -ForegroundColor White
foreach ($cf in $candidateFiles) {
    Write-Host ("    [{0,-2}] {1} ({2})" -f $cf.StateCode, $cf.RelativePath, $cf.ScopeSource) -ForegroundColor Gray
}
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not $Yes) {
    while ($true) {
        $confirmInput = Read-RequiredInput -PromptText "  >> Confirm commit file overwrite? Type 'yes' to proceed or 'no' to abort (No Default Enter): "
        if ($confirmInput -ceq "yes" -or $confirmInput -ieq "yes") {
            break
        }
        if ($confirmInput -ieq "no" -or $confirmInput -ieq "n" -or $confirmInput -ieq "q" -or $confirmInput -ieq "abort") {
            Write-Host "  [ABORTED] Commit file overwrite cancelled. Zero changes made to commit history." -ForegroundColor Yellow
            exit 0
        }
        Write-Host "  [INVALID CONFIRMATION] Type strictly 'yes' to execute or 'no' to cancel." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  [EXECUTING] Updating $($candidateFiles.Count) file(s) inside commit $($targetCommitObj.ShortHash)..." -ForegroundColor Cyan
$execResult = Invoke-CommitFileOverwrite `
    -RepoPath $resolvedRepoPath `
    -TargetCommit $targetCommitObj `
    -Option $selectedOption `
    -CandidateFiles $candidateFiles

if ($execResult.Success) {
    $savedJson = Save-CommitOverwriteOptions `
        -ExecutorBaseName $executorBaseName `
        -RepoPath $resolvedRepoPath `
        -CommitId $targetCommitObj.ShortHash `
        -Option $selectedOption `
        -CustomPath $chosenCustomRelPath `
        -CustomNewFileAction $chosenSubAction `
        -FilesCount $candidateFiles.Count `
        -BackupRef $execResult.BackupRef

    Write-Host "  [SUCCESS] $($execResult.Message)" -ForegroundColor Green
    Write-Host "  [STATE]   Saved executor options to: $savedJson" -ForegroundColor DarkGray
    Write-Host "  [BACKUP]  Safety rollback ref saved at: $($execResult.BackupRef)" -ForegroundColor DarkGray
    Write-Host ""
} else {
    Write-Host "  [FAILED]  $($execResult.Message)" -ForegroundColor Red
    if ($execResult.BackupRef) {
        Write-Host "  [BACKUP]  Safety rollback ref: $($execResult.BackupRef)" -ForegroundColor Yellow
    }
    exit 1
}
