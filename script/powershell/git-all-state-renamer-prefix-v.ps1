#Requires -Version 5.1
<#
.SYNOPSIS
    Git All-State Prefix Renamer (Modular Edition)
    Location: all-lads-tool/script/powershell/git-all-state-renamer-prefix-v.ps1

.DESCRIPTION
    Safely renames candidate files (e.g. legacy 'brief-*.md') to Rule #004 compliant
    two-octet versioned prefixes ('v01-0x_*') using 'git mv' to preserve commit
    lineage and avoid rewriting git history.
    Conforms strictly to Rule #000, Rule #001 (Zero Hardcoded Paths), and Rule #004.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TargetDir,

    [Parameter(Mandatory = $false)]
    [string]$Filter = "brief-*.md",

    [Parameter(Mandatory = $false)]
    [string]$StripPrefix,

    [Parameter(Mandatory = $false)]
    [int]$StripLength = 0,

    [Parameter(Mandatory = $false)]
    [string]$VersionPrefix = "v01",

    [Parameter(Mandatory = $false)]
    [int]$StartIndex = 1,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ANSI color codes
$CYAN   = "`e[1;36m"
$GREEN  = "`e[1;32m"
$YELLOW = "`e[1;33m"
$RED    = "`e[1;31m"
$GRAY   = "`e[0;90m"
$RESET  = "`e[0m"

# 1. Dynamic Root Resolution (Rule #001 - Zero Hardcoded Paths)
$scriptDir = $PSScriptRoot
$repoRoot  = Split-Path -Parent (Split-Path -Parent $scriptDir)

Write-Host "${CYAN}=== Git All-State Prefix Renamer ===${RESET}"
Write-Host "${GRAY}Script: all-lads-tool/script/powershell/git-all-state-renamer-prefix-v.ps1${RESET}`n"

# 2. Interactive Discovery & Prompting (if not fully parameterized)
if (-not $TargetDir) {
    if (-not $NonInteractive) {
        $defaultCandidate = Join-Path $repoRoot "local" "docs"
        $relCandidate = if (Test-Path $defaultCandidate) { "local/docs" } else { "." }
        
        Write-Host "Select target directory containing files to rename."
        $inputDir = Read-Host "Target Directory [Default: $relCandidate]"
        $TargetDir = if ([string]::IsNullOrWhiteSpace($inputDir)) { $relCandidate } else { $inputDir }
    } else {
        $TargetDir = "."
    }
}

# Resolve target directory absolute path dynamically
$resolvedTarget = if ([System.IO.Path]::IsPathRooted($TargetDir)) {
    $TargetDir
} else {
    Join-Path $repoRoot $TargetDir
}

if (-not (Test-Path $resolvedTarget -PathType Container)) {
    Write-Host "${RED}❌ Error: Target directory does not exist: $resolvedTarget${RESET}"
    exit 1
}

# Find Git repository root containing target directory
$gitRepoDir = $resolvedTarget
while ($gitRepoDir -and -not (Test-Path (Join-Path $gitRepoDir ".git"))) {
    $parent = Split-Path -Parent $gitRepoDir
    if ($parent -eq $gitRepoDir) { $gitRepoDir = $null; break }
    $gitRepoDir = $parent
}

$isGitRepo = ($null -ne $gitRepoDir)

# 3. Interactive Configuration Prompts
if (-not $NonInteractive) {
    if ([string]::IsNullOrWhiteSpace($Filter)) {
        $inputFilter = Read-Host "File search pattern [Default: brief-*.md]"
        $Filter = if ([string]::IsNullOrWhiteSpace($inputFilter)) { "brief-*.md" } else { $inputFilter }
    }

    if ([string]::IsNullOrWhiteSpace($StripPrefix) -and $StripLength -eq 0) {
        Write-Host "`nChoose strip/removal strategy:"
        Write-Host "  [1] Strip exact string prefix (e.g. 'brief-')"
        Write-Host "  [2] Strip first N characters (e.g. 4 or 6 chars)"
        Write-Host "  [3] Keep full original name (only prepend prefix)"
        $choice = Read-Host "Select [Default: 1]"
        $choice = if ([string]::IsNullOrWhiteSpace($choice)) { "1" } else { $choice.Trim() }

        switch ($choice) {
            "1" {
                $p = Read-Host "Exact prefix to strip [Default: brief-]"
                $StripPrefix = if ([string]::IsNullOrWhiteSpace($p)) { "brief-" } else { $p }
            }
            "2" {
                $l = Read-Host "Number of leading characters to strip [Default: 6]"
                $StripLength = if ([string]::IsNullOrWhiteSpace($l)) { 6 } else { [int]$l }
            }
            default {
                $StripPrefix = ""
                $StripLength = 0
            }
        }
    }

    $inputVersion = Read-Host "Version prefix (Rule #004, e.g. v01, v02) [Default: $VersionPrefix]"
    if (-not [string]::IsNullOrWhiteSpace($inputVersion)) {
        $VersionPrefix = $inputVersion.Trim()
    }

    $inputStart = Read-Host "Starting index number [Default: $StartIndex]"
    if (-not [string]::IsNullOrWhiteSpace($inputStart)) {
        $StartIndex = [int]$inputStart
    }
}

# 4. Scan Candidate Files
$candidateFiles = Get-ChildItem -Path $resolvedTarget -Filter $Filter -File | Sort-Object Name

if ($candidateFiles.Count -eq 0) {
    Write-Host "${YELLOW}⚠️ No files matched pattern '$Filter' in: $resolvedTarget${RESET}"
    exit 0
}

Write-Host "`n${CYAN}Scanning Candidate Files in: ${resolvedTarget}${RESET}"
Write-Host "Total matches: $($candidateFiles.Count) files.`n"

# 5. Build Renaming Plan & Collision Checks
$plan = [System.Collections.Generic.List[PSCustomObject]]::new()
$counter = $StartIndex

foreach ($file in $candidateFiles) {
    $baseName = $file.BaseName
    $ext = $file.Extension

    # Apply strip strategy
    $trimmedName = $baseName
    if (-not [string]::IsNullOrWhiteSpace($StripPrefix) -and $trimmedName.StartsWith($StripPrefix)) {
        $trimmedName = $trimmedName.Substring($StripPrefix.Length)
    } elseif ($StripLength -gt 0 -and $trimmedName.Length -ge $StripLength) {
        $trimmedName = $trimmedName.Substring($StripLength)
    }

    # Clean leading dashes or underscores if any remain
    $trimmedName = $trimmedName.TrimStart('-', '_')

    # Construct new 2-octet name: v01-01_<slug>.md (Rule #004)
    $formattedIndex = "{0:D2}" -f $counter
    $newName = "${VersionPrefix}-${formattedIndex}_${trimmedName}${ext}"
    $destPath = Join-Path $file.DirectoryName $newName

    $hasCollision = (Test-Path $destPath) -and ($destPath -ne $file.FullName)

    $plan.Add([PSCustomObject]@{
        Index         = $counter
        OldName       = $file.Name
        NewName       = $newName
        SourcePath    = $file.FullName
        DestPath      = $destPath
        HasCollision  = $hasCollision
    })

    $counter++
}

# 6. Display Plan Table
Write-Host ("{0,-5} | {1,-45} | {2,-45} | {3}" -f "No", "Original File", "New Rule #004 Name", "Status")
Write-Host ("-" * 115)

foreach ($item in $plan) {
    $statusText = if ($item.HasCollision) {
        "${RED}COLLISION (File Exists)${RESET}"
    } else {
        "${GREEN}Ready${RESET}"
    }

    Write-Host ("{0,-5} | {1,-45} | {2,-45} | {3}" -f $item.Index, $item.OldName, $item.NewName, $statusText)
}

$collisionCount = ($plan | Where-Object { $_.HasCollision }).Count
if ($collisionCount -gt 0) {
    Write-Host "`n${RED}❌ Aborted: $collisionCount file(s) would collide with existing files! Resolve collisions first.${RESET}"
    exit 1
}

# 7. Dry-Run or Confirmation
if ($DryRun) {
    Write-Host "`n${YELLOW}ℹ️ Dry-Run mode active. No files were modified.${RESET}"
    exit 0
}

if (-not $NonInteractive) {
    Write-Host ""
    $confirm = Read-Host "Proceed with renaming $($plan.Count) files via git mv? (y/N)"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "${GRAY}Operation cancelled by user.${RESET}"
        exit 0
    }
}

# 8. Execution Loop
Write-Host "`n${CYAN}Executing Renames...${RESET}"
$successCount = 0
$failCount = 0

foreach ($item in $plan) {
    try {
        if ($isGitRepo) {
            # Execute git mv within the target git repository
            $relOld = Resolve-Path -Relative -Path $item.SourcePath
            $relNew = Resolve-Path -Relative -Path $item.DestPath
            
            $gitOut = git -C $gitRepoDir mv "$($item.SourcePath)" "$($item.DestPath)" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✔ git mv: $($item.OldName) -> $($item.NewName)" -ForegroundColor Green
                $successCount++
            } else {
                # Fallback to Move-Item if file is untracked
                Move-Item -Path $item.SourcePath -Destination $item.DestPath -Force
                Write-Host "✔ Move-Item (untracked): $($item.OldName) -> $($item.NewName)" -ForegroundColor Yellow
                $successCount++
            }
        } else {
            Move-Item -Path $item.SourcePath -Destination $item.DestPath -Force
            Write-Host "✔ Move-Item: $($item.OldName) -> $($item.NewName)" -ForegroundColor Green
            $successCount++
        }
    } catch {
        Write-Host "❌ Failed to rename '$($item.OldName)': $_" -ForegroundColor Red
        $failCount++
    }
}

Write-Host "`n${GREEN}=== Renaming Complete ===${RESET}"
Write-Host "Successful: $successCount" -ForegroundColor Green
if ($failCount -gt 0) {
    Write-Host "Failed: $failCount" -ForegroundColor Red
}
Write-Host "${CYAN}Note: All changes remain safely staged or modified in your working tree per 'donot-commit-yet'.${RESET}"
Write-Host "${GRAY}Review changes with 'git status' before committing.${RESET}"
