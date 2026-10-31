<#
.SYNOPSIS
    Git Lost / Detached Commit Recovery Tool (ps_recover.ps1)
.DESCRIPTION
    Lists recent commits from git reflog (including orphaned/detached commits),
    lets you pick one (0 = latest, 1 = prior to latest, etc.),
    and selectively or completely restore/overwrite files into your working tree.
    (Powered by ps_git-manage.ps1 engine)
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$Action = "Recover"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$gitManageScript = Join-Path $scriptDir "ps_git-manage.ps1"

if (Test-Path $gitManageScript) {
    & $gitManageScript -TargetDir $TargetDir -Action $Action
} else {
    Write-Host "Error: Universal Git Manager engine not found at: $gitManageScript" -ForegroundColor Red
}
