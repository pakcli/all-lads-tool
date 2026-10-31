<#
.SYNOPSIS
    Direct Git Branch Renamer (Interactive Target & Name)
.DESCRIPTION
    Renames active local branch and directly pushes it to remote.
    Interactively prompts for Target Directory (if invalid) and New Branch Name.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$NewBranch = "",

    [Parameter()]
    [string]$Remote = "origin"
)

Import-Module "$PSScriptRoot\module\git-core.psm1" -Force
Import-Module "$PSScriptRoot\module\git-status.psm1" -Force

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

# 1. RESOLVE TARGET DIRECTORY (INTERACTIVE LOOP JIKA BUKAN REPO)
$currentTarget = if ([string]::IsNullOrWhiteSpace($TargetDir)) { (Get-Location).Path } else { Normalize-InputPath $TargetDir }

while ($true) {
    $summary = Get-GitStatusSummary $currentTarget
    if (-not $summary.IsRepo) {
        Write-Host "Directory is NOT a Git repo: $currentTarget" -ForegroundColor Yellow
        $inputPath = Read-PromptDefault -Prompt "Enter target Git repository folder (or 'q' to quit)" -Default ""
        if ([string]::IsNullOrWhiteSpace($inputPath) -or $inputPath -eq "q") {
            Write-Host "Cancelled." -ForegroundColor DarkGray
            return
        }
        $currentTarget = Normalize-InputPath $inputPath
        continue
    }
    break
}

$oldBranch = (Invoke-GitCommand -RepoPath $currentTarget -Arguments @("branch", "--show-current")).Trim()
if ([string]::IsNullOrWhiteSpace($oldBranch)) {
    Write-Host "Detached HEAD state. Aborted." -ForegroundColor Red
    return
}

Write-Host "`nTarget Directory : $currentTarget" -ForegroundColor Cyan
Write-Host "Active Branch    : $oldBranch" -ForegroundColor Yellow

# 2. ASK NEW BRANCH NAME
$newName = $NewBranch
while ([string]::IsNullOrWhiteSpace($newName) -or $newName -eq $oldBranch) {
    $newName = Read-PromptDefault -Prompt "Enter new branch name (e.g. main/pakcli)" -Default ""
    if ([string]::IsNullOrWhiteSpace($newName)) {
        Write-Host "Branch name cannot be empty." -ForegroundColor Red
        continue
    }
    if ($newName -eq $oldBranch) {
        Write-Host "New name cannot be the same as current name." -ForegroundColor Red
        $newName = ""
        continue
    }
}

Write-Host "`nActions to execute directly:" -ForegroundColor Cyan
Write-Host "  1. git branch -m $oldBranch $newName" -ForegroundColor White
Write-Host "  2. git push -u $Remote $newName" -ForegroundColor White

$go = Read-PromptDefault -Prompt "Execute now? (Y/n)" -Default "y"
if ($go.ToLower() -ne "y") { 
    Write-Host "Cancelled." -ForegroundColor DarkGray
    return 
}

# 3. EXECUTE LOCAL RENAME
Write-Host "Renaming local branch to $newName..." -ForegroundColor Cyan
$out1 = Invoke-GitCommand -RepoPath $currentTarget -Arguments @("branch", "-m", $oldBranch, $newName)
Write-Host "[OK] Local branch renamed." -ForegroundColor Green

# 4. EXECUTE REMOTE PUSH
Write-Host "Pushing $newName to $Remote..." -ForegroundColor Cyan
$out2 = Invoke-GitCommand -RepoPath $currentTarget -Arguments @("push", "-u", $Remote, $newName)
if ($out2) { Write-Host $out2 }
Write-Host "[OK] Done!" -ForegroundColor Green
