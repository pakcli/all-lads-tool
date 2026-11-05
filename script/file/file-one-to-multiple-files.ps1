<#
.SYNOPSIS
    File One To Multiple Files (Context: File / all-lads-tool)
.DESCRIPTION
    Splits a single monolithic Markdown document into multiple modular files
    based on heading boundaries (e.g. "## Heading"). Generates individual YAML frontmatter,
    formats kebab-case filenames, creates an automated index/TOC hub, and supports
    safe source archiving to trash-bin/.
.PARAMETER SourceFile
    Path to the monolithic Markdown file to split.
.PARAMETER OutputDir
    Destination directory where child files will be generated.
.PARAMETER SplitHeadingLevel
    Markdown heading level to use as partition boundaries (default: 2, i.e. "## ").
.PARAMETER GenerateIndex
    Creates an index.md table of contents linking all generated files.
.PARAMETER ArchiveSource
    Safely moves the original source file to trash-bin/ after successful split.
.PARAMETER DryRun
    Simulates the file split operation without writing or moving files.
#>
[CmdletBinding()]
param(
    [string]$SourceFile,
    [string]$OutputDir,
    [int]$SplitHeadingLevel = 2,
    [switch]$GenerateIndex = $true,
    [switch]$ArchiveSource,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Dynamic resolution following Skill: save-option-as-exact-executor-name-json
$scriptBaseName = if ($PSCommandPath) { [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) } else { "file-one-to-multiple-files" }
$optionsFile = Join-Path $PSScriptRoot "$scriptBaseName.json"

$savedOptions = @{}
if (Test-Path -LiteralPath $optionsFile) {
    try {
        $savedOptions = Get-Content -LiteralPath $optionsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {}
}

# Interactive prompt if parameters are missing (populated from saved options if available)
if (-not $SourceFile) {
    $promptHint = if ($savedOptions.SourceFile) { " [Default: $($savedOptions.SourceFile)]" } else { "" }
    Write-Host "`n=== FILE ONE TO MULTIPLE FILES (all-lads-tool) ===" -ForegroundColor Cyan
    $in = Read-Host "SOURCE FILE (Path file .md yang ingin dipecah)$promptHint"
    $SourceFile = if ([string]::IsNullOrWhiteSpace($in) -and $savedOptions.SourceFile) { $savedOptions.SourceFile } else { $in }
}
$SourceFile = $SourceFile.Trim('"').Trim()

if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) {
    Write-Error "[ERROR] File sumber tidak ditemukan: $SourceFile"
    exit 1
}

if (-not $OutputDir) {
    $fileItem = Get-Item -LiteralPath $SourceFile
    $defaultOut = if ($savedOptions.OutputDir) { $savedOptions.OutputDir } else { Join-Path $fileItem.DirectoryName $fileItem.BaseName }
    $inputOut = Read-Host "OUTPUT DIR (Folder tujuan untuk file-file pecahan) [Default: $defaultOut]"
    $OutputDir = if ([string]::IsNullOrWhiteSpace($inputOut)) { $defaultOut } else { $inputOut.Trim('"').Trim() }
}

# Save latest options to exact executor JSON
try {
    $toSave = [PSCustomObject]@{
        executor           = "$scriptBaseName.ps1"
        updatedAt          = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        SourceFile         = $SourceFile
        OutputDir          = $OutputDir
        SplitHeadingLevel  = $SplitHeadingLevel
        GenerateIndex      = [bool]$GenerateIndex
        ArchiveSource      = [bool]$ArchiveSource
    }
    Set-Content -LiteralPath $optionsFile -Value ($toSave | ConvertTo-Json -Depth 3) -Force -Encoding UTF8
} catch {}

$rawText = [System.IO.File]::ReadAllText($SourceFile, [System.Text.Encoding]::UTF8)

# Parse Master Frontmatter
$masterTags = @()
$masterTitle = (Get-Item -LiteralPath $SourceFile).BaseName
$bodyContent = $rawText

if ($rawText -match '(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$') {
    $fmYaml = $matches[1]
    $bodyContent = $matches[2]
    
    if ($fmYaml -match '(?m)^title:\s*["'']?(.*?)["'']?\s*$') {
        $masterTitle = $matches[1].Trim()
    }
    $tagMatches = [regex]::Matches($fmYaml, '(?m)^\s*-\s*([a-zA-Z0-9_\-]+)\s*$')
    foreach ($tm in $tagMatches) {
        $masterTags += $tm.Groups[1].Value.Trim()
    }
}

# Regex for target heading level
$headingHash = "#" * [Math]::Max(1, [Math]::Min(6, $SplitHeadingLevel))
$splitRegex = "(?m)^$headingHash\s+(.+)$"

$matchesList = [regex]::Matches($bodyContent, $splitRegex)
if ($matchesList.Count -eq 0) {
    Write-Warning "[WARN] Tidak ditemukan heading dengan level '$headingHash ' di dalam file."
    exit 0
}

Write-Host "`n[INFO] Ditemukan $($matchesList.Count) partisi heading di dalam: $SourceFile" -ForegroundColor Cyan

# Preamble (Content before first heading)
$preamble = ""
if ($matchesList[0].Index -gt 0) {
    $preamble = $bodyContent.Substring(0, $matchesList[0].Index).Trim()
}

# Extract Sections
$sections = [System.Collections.Generic.List[PSCustomObject]]::new()
for ($i = 0; $i -lt $matchesList.Count; $i++) {
    $currentMatch = $matchesList[$i]
    $headingTitle = $currentMatch.Groups[1].Value.Trim()
    
    $startIndex = $currentMatch.Index + $currentMatch.Length
    $endIndex = if ($i -lt $matchesList.Count - 1) {
        $matchesList[$i + 1].Index
    } else {
        $bodyContent.Length
    }
    
    $sectionBody = $bodyContent.Substring($startIndex, $endIndex - $startIndex).Trim()
    
    # Generate clean kebab-case filename (strip emojis and special characters)
    $cleanSlug = ($headingTitle -replace '[\p{So}\p{Sk}\p{Sm}]', '') # Strip symbols/emojis
    $cleanSlug = ($cleanSlug -replace '[^a-zA-Z0-9\s\-]', '').Trim()
    $cleanSlug = ($cleanSlug -replace '\s+', '-').ToLower()
    if ([string]::IsNullOrWhiteSpace($cleanSlug)) { $cleanSlug = "section-$($i + 1)" }
    $fileName = "$cleanSlug.md"
    
    $sections.Add([PSCustomObject]@{
        RawTitle  = $headingTitle
        Slug      = $cleanSlug
        FileName  = $fileName
        Body      = $sectionBody
        Index     = $i + 1
    })
}

# Dry Run Inspection
if ($DryRun) {
    Write-Host "`n[DRY-RUN] Simulasi pemecahan file ke: $OutputDir" -ForegroundColor Yellow
    foreach ($sec in $sections) {
        Write-Host "  -> [$($sec.Index)] $($sec.FileName) (Title: '$($sec.RawTitle)')" -ForegroundColor Yellow
    }
    if ($GenerateIndex) {
        Write-Host "  -> [INDEX] index.md (Master Table of Contents)" -ForegroundColor Yellow
    }
    return
}

# Ensure Output Directory Exists
if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$indexLinks = [System.Collections.Generic.List[string]]::new()

# Write Child Files
foreach ($sec in $sections) {
    $destPath = Join-Path $OutputDir $sec.FileName
    
    $fileDoc = [System.Text.StringBuilder]::new()
    $fileDoc.AppendLine("---") | Out-Null
    $fileDoc.AppendLine("title: `"$($sec.RawTitle)`"") | Out-Null
    $fileDoc.AppendLine("parent: `"$masterTitle`"") | Out-Null
    $fileDoc.AppendLine("order: $($sec.Index)") | Out-Null
    if ($masterTags.Count -gt 0) {
        $fileDoc.AppendLine("tags:") | Out-Null
        foreach ($t in $masterTags) {
            $fileDoc.AppendLine("  - $t") | Out-Null
        }
    }
    $fileDoc.AppendLine("---") | Out-Null
    $fileDoc.AppendLine("") | Out-Null
    $fileDoc.AppendLine("# $($sec.RawTitle)") | Out-Null
    $fileDoc.AppendLine("") | Out-Null
    $fileDoc.AppendLine($sec.Body) | Out-Null
    
    [System.IO.File]::WriteAllText($destPath, $fileDoc.ToString(), [System.Text.Encoding]::UTF8)
    Write-Host "  -> Created: $($sec.FileName)" -ForegroundColor DarkGray
    
    $indexLinks.Add("* [[$($sec.Slug)|$($sec.RawTitle)]]")
}

# Generate Index Hub
if ($GenerateIndex) {
    $indexPath = Join-Path $OutputDir "index.md"
    $indexDoc = [System.Text.StringBuilder]::new()
    $indexDoc.AppendLine("---") | Out-Null
    $indexDoc.AppendLine("title: `"$masterTitle`"") | Out-Null
    if ($masterTags.Count -gt 0) {
        $indexDoc.AppendLine("tags:") | Out-Null
        foreach ($t in $masterTags) {
            $indexDoc.AppendLine("  - $t") | Out-Null
        }
    }
    $indexDoc.AppendLine("---") | Out-Null
    $indexDoc.AppendLine("") | Out-Null
    $indexDoc.AppendLine("# $masterTitle") | Out-Null
    $indexDoc.AppendLine("") | Out-Null
    
    if (-not [string]::IsNullOrWhiteSpace($preamble)) {
        $indexDoc.AppendLine($preamble) | Out-Null
        $indexDoc.AppendLine("") | Out-Null
    }
    
    $indexDoc.AppendLine("## Sections & Modules") | Out-Null
    $indexDoc.AppendLine("") | Out-Null
    foreach ($il in $indexLinks) {
        $indexDoc.AppendLine($il) | Out-Null
    }
    
    [System.IO.File]::WriteAllText($indexPath, $indexDoc.ToString(), [System.Text.Encoding]::UTF8)
    Write-Host "  -> Created Index Hub: index.md" -ForegroundColor Green
}

Write-Host "`n[SUCCESS] Berhasil memecah $SourceFile menjadi $($sections.Count) file di: $OutputDir" -ForegroundColor Green

# Optional Archive Source
if ($ArchiveSource) {
    Write-Host "`n[ARCHIVE] Mengarsipkan file sumber ke trash-bin/..." -ForegroundColor Cyan
    $repoRoot = (Get-Item $SourceFile).DirectoryName
    $cursor = $repoRoot
    while ($cursor) {
        if (Test-Path (Join-Path $cursor ".git") -or (Test-Path (Join-Path $cursor "trash-bin"))) {
            $repoRoot = $cursor
            break
        }
        $parent = Split-Path $cursor -Parent
        if ($parent -eq $cursor) { break }
        $cursor = $parent
    }
    
    $trashBin = Join-Path $repoRoot "trash-bin"
    $rel = [System.IO.Path]::GetRelativePath($repoRoot, $SourceFile)
    $dest = Join-Path $trashBin $rel
    $destDir = Split-Path $dest -Parent
    if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    Move-Item -LiteralPath $SourceFile -Destination $dest -Force
    Write-Host "  -> Archived: $(Split-Path $SourceFile -Leaf) => $dest" -ForegroundColor DarkGray
}
