<#
.SYNOPSIS
    Batch Rename Files to Kebab-Case AND Synchronize Frontmatter Title
.DESCRIPTION
    Scans a target directory, extracts frontmatter titles, converts to clean lowercase kebab-case,
    renames the files, and updates the title property inside the YAML frontmatter.
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

Invoke-BatchTargetDirRename -TargetDir $TargetDir -KebabCase:$true -SyncFrontmatter:$true -DryRun:$DryRun
