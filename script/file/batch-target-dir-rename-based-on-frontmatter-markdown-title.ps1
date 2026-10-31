<#
.SYNOPSIS
    Batch Rename Markdown Files Based on Frontmatter Title (Raw Title Mode)
.DESCRIPTION
    Scans a target directory and renames files to match their frontmatter title.
#>
[CmdletBinding()]
param(
    [string]$TargetDir,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$adapterPath = Join-Path $PSScriptRoot "adapter\batch-file-renamer.psm1"
Import-Module -Name $adapterPath -Force

if (-not $TargetDir) {
    $TargetDir = Read-Host "TARGET DIR (Folder berisi file .md)"
}
$TargetDir = $TargetDir.Trim('"').Trim()

Invoke-BatchTargetDirRename -TargetDir $TargetDir -KebabCase:$false -SyncFrontmatter:$false -DryRun:$DryRun
