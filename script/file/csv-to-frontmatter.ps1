<#
.SYNOPSIS
    CSV to Frontmatter Converter (Context: File)
.DESCRIPTION
    Converts tabular CSV rows into Obsidian-compatible Markdown files with YAML frontmatters.
    Delegates parsing logic to adapter/universal.psm1.
#>
[CmdletBinding()]
param(
    [string]$TargetDir,
    [string]$TargetCsv
)

$ErrorActionPreference = 'Stop'
$adapter = Join-Path $PSScriptRoot "adapter\csv-to-frontmatter.psm1"
Import-Module -Name $adapter -Force

if (-not $TargetDir) { $TargetDir = Read-Host 'TARGET DIR (Folder output file .md)' }
if (-not $TargetCsv) { $TargetCsv = Read-Host 'TARGET CSV (Path file .csv)' }
$TargetDir = $TargetDir.Trim('"').Trim()
$TargetCsv = $TargetCsv.Trim('"').Trim()

$count = Export-CsvToMarkdownFiles -CsvPath $TargetCsv -OutputDir $TargetDir
Write-Host "[OK] Selesai: $count file .md berhasil ditulis ke '$TargetDir'." -ForegroundColor Green
