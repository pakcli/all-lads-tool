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

# Dynamic resolution following Skill: save-option-as-exact-executor-name-json
$scriptBaseName = if ($PSCommandPath) { [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) } else { "csv-to-frontmatter" }
$optionsFile = Join-Path $PSScriptRoot "$scriptBaseName.json"

$savedOptions = @{}
if (Test-Path -LiteralPath $optionsFile) {
    try {
        $savedOptions = Get-Content -LiteralPath $optionsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {}
}

$adapter = Join-Path $PSScriptRoot "adapter\csv-to-frontmatter.psm1"
Import-Module -Name $adapter -Force

if (-not $TargetDir) {
    $promptHint = if ($savedOptions.TargetDir) { " [Default: $($savedOptions.TargetDir)]" } else { "" }
    $in = Read-Host "TARGET DIR (Folder output file .md)$promptHint"
    $TargetDir = if ([string]::IsNullOrWhiteSpace($in) -and $savedOptions.TargetDir) { $savedOptions.TargetDir } else { $in }
}
if (-not $TargetCsv) {
    $promptHint = if ($savedOptions.TargetCsv) { " [Default: $($savedOptions.TargetCsv)]" } else { "" }
    $in = Read-Host "TARGET CSV (Path file .csv)$promptHint"
    $TargetCsv = if ([string]::IsNullOrWhiteSpace($in) -and $savedOptions.TargetCsv) { $savedOptions.TargetCsv } else { $in }
}
$TargetDir = $TargetDir.Trim('"').Trim()
$TargetCsv = $TargetCsv.Trim('"').Trim()

# Save latest options to exact executor JSON
try {
    $toSave = [PSCustomObject]@{
        executor   = "$scriptBaseName.ps1"
        updatedAt  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        TargetDir  = $TargetDir
        TargetCsv  = $TargetCsv
    }
    Set-Content -LiteralPath $optionsFile -Value ($toSave | ConvertTo-Json -Depth 3) -Force -Encoding UTF8
} catch {}

$count = Export-CsvToMarkdownFiles -CsvPath $TargetCsv -OutputDir $TargetDir
Write-Host "[OK] Selesai: $count file .md berhasil ditulis ke '$TargetDir'." -ForegroundColor Green
