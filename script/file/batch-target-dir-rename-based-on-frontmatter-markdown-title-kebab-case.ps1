<#
.SYNOPSIS
    Batch Rename Markdown Files Based on Frontmatter Title in Kebab-Case
.DESCRIPTION
    Scans a target directory, extracts frontmatter titles, converts to clean lowercase kebab-case,
    and renames the markdown files accordingly.
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

Invoke-BatchTargetDirRename -TargetDir $TargetDir -KebabCase:$true -SyncFrontmatter:$false -DryRun:$DryRun
