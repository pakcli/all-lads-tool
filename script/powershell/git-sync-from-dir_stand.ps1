<#
.SYNOPSIS
    Overwrite the files of repo A with the files of directory B. The .git of A is never touched.
.DESCRIPTION
    Copies every file from B into A (newer or different files overwrite A's).
    Excludes .git directories and .git files at every level, so A keeps its own
    history, remote and identity. Files that exist only in A are left in place.
    A preview (no changes) is shown and confirmation is required before copying.
.PARAMETER TargetRepo
    A: the repo that receives the files.
.PARAMETER SourceDir
    B: the directory the files are copied from.
.PARAMETER Yes
    Skip the confirmation prompt.
#>
param(
    [string]$TargetRepo,
    [string]$SourceDir,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

if (-not $TargetRepo) { $TargetRepo = Read-Host 'A - target repo (receives files, its .git is kept)' }
if (-not $SourceDir)  { $SourceDir  = Read-Host 'B - source directory (files are copied from here)' }

$A = (Resolve-Path -LiteralPath $TargetRepo.Trim('"')).Path
$B = (Resolve-Path -LiteralPath $SourceDir.Trim('"')).Path

if ($A -eq $B) { throw 'A and B are the same directory.' }
if (-not (Test-Path -LiteralPath (Join-Path $A '.git'))) { throw "A is not a git repo (no .git): $A" }

$common = @('/E', '/XD', '.git', '/XF', '.git', '/NJH', '/NJS', '/NP', '/NDL')

Write-Host "A (target, .git kept): $A"
Write-Host "B (source)           : $B"
Write-Host ''
Write-Host 'Preview (no changes made):'
& robocopy $B $A @common '/L'
if ($LASTEXITCODE -ge 8) { throw "robocopy preview failed (exit $LASTEXITCODE)" }

if (-not $Yes) {
    $ans = Read-Host 'Overwrite files in A with B? [y/N]'
    if ($ans -notmatch '^(y|yes)$') { Write-Host 'Cancelled.'; exit 0 }
}

& robocopy $B $A @common
if ($LASTEXITCODE -ge 8) { throw "robocopy failed (exit $LASTEXITCODE)" }

Write-Host ''
Write-Host 'Done. A git status:'
& git -C $A status --short
