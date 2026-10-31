<#
.SYNOPSIS
    Git Branch Renamer (Context: Repo)
.DESCRIPTION
    Lean orchestrator that renames branch safely using dynamic adapter dispatch.
#>
[CmdletBinding()]
param(
    [string]$NewBranch,
    [string]$TargetDir = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'

$gitVersionRaw = git --version 2>$null
$versionNumber = [regex]::Match($gitVersionRaw, '\d+\.\d+').Value
$adapterFile = if ([version]$versionNumber -ge [version]"2.40") {
    "v02-40-00.psm1"
} else {
    "v02-30-00.psm1"
}

$adapterPath = Join-Path $PSScriptRoot "adapter\$adapterFile"
Import-Module -Name $adapterPath -Force

if (-not $NewBranch) {
    $NewBranch = Read-Host "TARGET BRANCH NAME (Nama branch baru)"
}
$NewBranch = $NewBranch.Trim()

Invoke-GitBranchRename -NewBranch $NewBranch -RepoPath $TargetDir
