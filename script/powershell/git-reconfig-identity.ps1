<#
.SYNOPSIS
    Reconfigure a repo's local Git identity to match its GitHub/GitLab remote owner (Modular Edition).
.DESCRIPTION
    Reads the remote URL, extracts the owner account, and sets repo-local user.name / user.email.
    Local config only. No commit is created and no history is rewritten.
.PARAMETER TargetDir
    Target repository (default: current directory).
.PARAMETER Remote
    Remote to read the owner from (default: origin).
.PARAMETER Name
    Override user.name. Default: the remote owner login.
.PARAMETER Email
    Override user.email. Default: global email if it belongs to the owner, else owner@users.noreply.github.com.
.PARAMETER DryRun
    Show the planned change without writing config.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [string]$Remote = "origin",
    [string]$Name = "",
    [string]$Email = "",
    [switch]$DryRun
)

$modulePath = Join-Path $PSScriptRoot "module\git-identity.psm1"
if (-not (Test-Path -LiteralPath $modulePath)) {
    Write-Error "Required module not found: $modulePath"
    exit 1
}
Import-Module -Name $modulePath -Force

$repo = if ([string]::IsNullOrWhiteSpace($TargetDir)) { (Get-Location).Path } else { $TargetDir }
if (-not (Test-Path -LiteralPath $repo)) {
    Write-Error "Target directory does not exist: $repo"
    exit 1
}
$repo = (Resolve-Path -LiteralPath $repo).Path

if ((git -C $repo rev-parse --is-inside-work-tree 2>$null) -ne "true") {
    Write-Error "Not a Git repository: $repo"
    exit 1
}

$info = Get-RemoteOwner -RepoPath $repo -Remote $Remote
if (-not $info) {
    Write-Error "Remote '$Remote' not found or URL could not be parsed."
    exit 1
}

$before = Get-GitIdentity -RepoPath $repo -Scope effective
$target = Resolve-TargetIdentity -RepoPath $repo -Owner $info.Owner -Name $Name -Email $Email

Write-Host "Repository : $repo"
Write-Host "Remote     : $($info.Remote) -> $($info.Url) [$($info.Provider)]"
Write-Host "Owner      : $($info.Owner)"
Write-Host ""
Write-Host "Before     : $($before.Name) <$($before.Email)>"
Write-Host "After      : $($target.Name) <$($target.Email)>"

if ($before.Name -eq $target.Name -and $before.Email -eq $target.Email) {
    Write-Host "`nAlready aligned. Nothing to change."
    exit 0
}

if ($DryRun) {
    Write-Host "`n[DRY-RUN] No config written."
    exit 0
}

Set-LocalGitIdentity -RepoPath $repo -Name $target.Name -Email $target.Email | Out-Null
Write-Host "`n[OK] Local identity updated (repo-local config only). Existing commits are unchanged."
