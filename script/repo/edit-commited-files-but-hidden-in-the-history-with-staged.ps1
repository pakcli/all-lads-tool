<#
.SYNOPSIS
    Historical Commit File Overwrite Engine (Context: Repo)
.DESCRIPTION
    Replaces files inside an existing commit (HEAD, historical commit SHA, or 'L'/'all' = All Commit State)
    without creating extra fixup commits in git log.
    Enforces strict Zero-Default-Enter across all interactive prompts via modular adapter functions:
      Step 1. target repo (1..20 default, 'more' for +20)
      Step 2. commit id / L / all (1..20 default, 'more' for +20 and +20)
      Step 3. 5 opsi (1..5)
      Step 4. Pre-Flight Briefed Overview confirmation ('yes')
#>
[CmdletBinding()]
param(
    [string]$Repo = "",
    [string]$CommitId = "",
    [int]$Option = 0,
    [string]$CustomPath = "",
    [int]$CustomNewFileAction = 0,
    [int]$PageSize = 20,
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

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  COMMITTED FILE OVERWRITE (HIDDEN IN HISTORY WITH STAGED / WORKING TREE)       " -ForegroundColor White
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "  Rule: Strict No-Default-Enter. Default page size: 1..$PageSize (type 'more' for +$PageSize)." -ForegroundColor DarkGray
Write-Host ""

# ==============================================================================
# STEP 1: SELECT TARGET REPO (1..20 default, 'more' for +20, No Default Enter)
# ==============================================================================
$resolvedRepoPath = Select-TargetRepositoryInteractive -RepoParam $Repo -PageSize $PageSize
if (-not $resolvedRepoPath) {
    Write-Host "  [ABORTED] Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

$branchCheck = Invoke-GitRepoCommand -RepoPath $resolvedRepoPath -GitArgs @("rev-parse", "--abbrev-ref", "HEAD")
$activeBranch = if ($branchCheck.Success -and $branchCheck.Output.Count -gt 0) { $branchCheck.Output[0].Trim() } else { "HEAD" }

Write-Host "  [SELECTED REPO] $resolvedRepoPath (branch: $activeBranch)" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# STEP 2: SELECT COMMIT ID / 'more' (+20) / 'L' or 'all' (No Default Enter)
# ==============================================================================
$targetCommitObj = Select-TargetCommitInteractive -RepoPath $resolvedRepoPath -CommitIdParam $CommitId -PageSize $PageSize
if (-not $targetCommitObj) {
    Write-Host "  [ABORTED] Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

$headLabel = if ($targetCommitObj.IsAllCommits) {
    "ALL COMMIT STATE"
} elseif ($targetCommitObj.IsHead) {
    "HEAD (Latest Commit)"
} else {
    "Historical Commit"
}
Write-Host "  [SELECTED COMMIT] $($targetCommitObj.ShortHash) [$headLabel] - `"$($targetCommitObj.Subject)`"" -ForegroundColor Green
Write-Host ""

# ==============================================================================
# STEP 3: SELECT OPSI 1..5 (No Default Enter)
# ==============================================================================
$optionSelection = Select-OverwriteOptionInteractive `
    -RepoPath $resolvedRepoPath `
    -OptionParam $Option `
    -CustomPathParam $CustomPath `
    -CustomNewFileActionParam $CustomNewFileAction `
    -IsAllCommits ([bool]$targetCommitObj.IsAllCommits)

if (-not $optionSelection) {
    Write-Host "  [ABORTED] Operation cancelled by user." -ForegroundColor Yellow
    exit 0
}

$selectedOption = $optionSelection.SelectedOption
$candidateFiles = @($optionSelection.CandidateFiles)
$chosenCustomRelPath = $optionSelection.ChosenCustomRelPath
$chosenSubAction = $optionSelection.ChosenSubAction

if (-not $candidateFiles -or $candidateFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "  [EMPTY FILE SET] Opsi $selectedOption matched 0 changed files in '$resolvedRepoPath'." -ForegroundColor Red
    Write-Host "  Nothing to overwrite into commit $($targetCommitObj.ShortHash). Exiting cleanly." -ForegroundColor Yellow
    exit 1
}

# ==============================================================================
# STEP 4: PRE-FLIGHT BRIEFED OVERVIEW & EXPLICIT CONFIRMATION (No Default Enter)
# ==============================================================================
$confirmed = Confirm-CommitOverwriteOverview `
    -RepoPath $resolvedRepoPath `
    -ActiveBranch $activeBranch `
    -TargetCommit $targetCommitObj `
    -OptionSelection $optionSelection `
    -OptionsJsonPath $optionsJsonPath `
    -AutoConfirm:$Yes

if (-not $confirmed) {
    Write-Host "  [ABORTED] Commit file overwrite cancelled. Zero changes made to commit history." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "  [EXECUTING] Updating $($candidateFiles.Count) file(s) inside $($targetCommitObj.ShortHash)..." -ForegroundColor Cyan
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
