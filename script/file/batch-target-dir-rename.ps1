<#
.SYNOPSIS
    Batch Target-Dir Markdown Renamer (Context: File)
.DESCRIPTION
    Interactively or via parameters renames Markdown files in a target directory
    based on their YAML frontmatter title, with options for kebab-case and frontmatter synchronization.
.PARAMETER TargetDir
    Directory containing Markdown files to inspect and rename.
.PARAMETER KebabCase
    Converts title into strict lowercase kebab-case (e.g. "My Note" -> "my-note.md").
.PARAMETER SyncFrontmatter
    Updates frontmatter title inside the file to match the kebab-case name.
.PARAMETER DryRun
    Simulates renames without modifying files on disk.
#>
[CmdletBinding()]
param(
    [string]$TargetDir,
    [switch]$KebabCase,
    [switch]$SyncFrontmatter,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$adapterPath = Join-Path $PSScriptRoot "adapter\batch-file-renamer.psm1"
Import-Module -Name $adapterPath -Force

if (-not $TargetDir) {
    $TargetDir = Read-Host "TARGET DIR (Folder berisi file .md yang ingin di-rename)"
}
$TargetDir = $TargetDir.Trim('"').Trim()

if (-not (Test-Path -LiteralPath $TargetDir -PathType Container)) {
    Write-Error "[ERROR] Direktori target tidak ditemukan: $TargetDir"
    exit 1
}

# If no flags passed, offer interactive mode
if (-not $KebabCase -and -not $SyncFrontmatter) {
    Write-Host "`nPilih Mode Rename:" -ForegroundColor Cyan
    Write-Host "  [ 1 ] Rename berdasarkan Raw Title (apa adanya di frontmatter)" -ForegroundColor White
    Write-Host "  [ 2 ] Rename berdasarkan Title -> Kebab-Case (huruf kecil & strip)" -ForegroundColor White
    Write-Host "  [ 3 ] Rename Title -> Kebab-Case DAN Sinkronkan isi Frontmatter" -ForegroundColor White
    Write-Host "  [ 0 ] Batal" -ForegroundColor DarkGray
    $modeChoice = Read-Host "Pilihan [1-3, Default: 2]"
    if ([string]::IsNullOrWhiteSpace($modeChoice)) { $modeChoice = "2" }

    switch ($modeChoice.Trim()) {
        "1" { $KebabCase = $false; $SyncFrontmatter = $false }
        "2" { $KebabCase = $true;  $SyncFrontmatter = $false }
        "3" { $KebabCase = $true;  $SyncFrontmatter = $true }
        default {
            Write-Host "[BATAL] Operasi dibatalkan." -ForegroundColor Yellow
            exit 0
        }
    }
}

Invoke-BatchTargetDirRename -TargetDir $TargetDir -KebabCase:$KebabCase -SyncFrontmatter:$SyncFrontmatter -DryRun:$DryRun
