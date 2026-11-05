<#
.SYNOPSIS
    File Merge Into One (Context: File / all-lads-tool)
.DESCRIPTION
    Merges multiple Markdown files from a source directory into a single consolidated
    document. Strips sub-file frontmatter, promotes titles to structured headings,
    generates an optional Table of Contents, rewrites cross-file links to anchor tags,
    and supports safe archiving to trash-bin/.
.PARAMETER SourceDir
    Directory containing Markdown files to merge.
.PARAMETER OutputFile
    Path of the consolidated output file.
.PARAMETER Pattern
    Search pattern for files (default: "*.md").
.PARAMETER HeadingLevel
    Heading level to assign to each merged file section (default: 2, i.e. "## ").
.PARAMETER IncludeTOC
    Generates a Table of Contents with anchor links at the top of the output.
.PARAMETER ArchiveSources
    Safely moves merged source files to trash-bin/ preserving directory structure.
.PARAMETER DryRun
    Simulates the merge operation without modifying or creating files on disk.
#>
[CmdletBinding()]
param(
    [string]$SourceDir,
    [string]$OutputFile,
    [string]$Pattern = "*.md",
    [int]$HeadingLevel = 2,
    [switch]$IncludeTOC,
    [switch]$ArchiveSources,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Dynamic resolution following Skill: save-option-as-exact-executor-name-json
$scriptBaseName = if ($PSCommandPath) { [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) } else { "file-merge-into-one" }
$optionsFile = Join-Path $PSScriptRoot "$scriptBaseName.json"

$savedOptions = @{}
if (Test-Path -LiteralPath $optionsFile) {
    try {
        $savedOptions = Get-Content -LiteralPath $optionsFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {}
}

# Interactive prompt if parameters are missing (populated from saved options if available)
if (-not $SourceDir) {
    $promptHint = if ($savedOptions.SourceDir) { " [Default: $($savedOptions.SourceDir)]" } else { "" }
    Write-Host "`n=== FILE MERGE INTO ONE (all-lads-tool) ===" -ForegroundColor Cyan
    $in = Read-Host "SOURCE DIR (Folder berisi file yang ingin digabung)$promptHint"
    $SourceDir = if ([string]::IsNullOrWhiteSpace($in) -and $savedOptions.SourceDir) { $savedOptions.SourceDir } else { $in }
}
$SourceDir = $SourceDir.Trim('"').Trim()

if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
    Write-Error "[ERROR] Direktori sumber tidak ditemukan: $SourceDir"
    exit 1
}

if (-not $OutputFile) {
    $defaultOut = if ($savedOptions.OutputFile) { $savedOptions.OutputFile } else { Join-Path $SourceDir "merged-output.md" }
    $inputOut = Read-Host "OUTPUT FILE (Path file hasil gabungan) [Default: $defaultOut]"
    $OutputFile = if ([string]::IsNullOrWhiteSpace($inputOut)) { $defaultOut } else { $inputOut.Trim('"').Trim() }
}

# Save latest options to exact executor JSON
try {
    $toSave = [PSCustomObject]@{
        executor     = "$scriptBaseName.ps1"
        updatedAt    = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        SourceDir    = $SourceDir
        OutputFile   = $OutputFile
        Pattern      = $Pattern
        HeadingLevel = $HeadingLevel
        IncludeTOC   = [bool]$IncludeTOC
    }
    Set-Content -LiteralPath $optionsFile -Value ($toSave | ConvertTo-Json -Depth 3) -Force -Encoding UTF8
} catch {}

# Resolve files
$files = Get-ChildItem -LiteralPath $SourceDir -Filter $Pattern -File | Where-Object {
    $_.FullName -ne (Resolve-Path $OutputFile -ErrorAction SilentlyContinue).Path
} | Sort-Object Name

if (-not $files -or $files.Count -eq 0) {
    Write-Warning "[WARN] Tidak ada file dengan pola '$Pattern' ditemukan di: $SourceDir"
    exit 0
}

Write-Host "`n[INFO] Ditemukan $($files.Count) file untuk digabungkan:" -ForegroundColor Cyan
foreach ($f in $files) {
    Write-Host "  -> $($f.Name)" -ForegroundColor DarkGray
}

$headingPrefix = "#" * [Math]::Max(1, [Math]::Min(6, $HeadingLevel))
$mergedSections = [System.Collections.Generic.List[string]]::new()
$tocItems = [System.Collections.Generic.List[string]]::new()
$allTags = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($file in $files) {
    $rawContent = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    
    # Extract Frontmatter
    $body = $rawContent
    $title = $file.BaseName
    
    if ($rawContent -match '(?s)^---\r?\n(.*?)\r?\n---\r?\n(.*)$') {
        $fmYaml = $matches[1]
        $body = $matches[2]
        
        # Try extracting title from frontmatter
        if ($fmYaml -match '(?m)^title:\s*["'']?(.*?)["'']?\s*$') {
            $parsedTitle = $matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($parsedTitle)) {
                $title = $parsedTitle
            }
        }
        
        # Collect tags
        $tagMatches = [regex]::Matches($fmYaml, '(?m)^\s*-\s*([a-zA-Z0-9_\-]+)\s*$')
        foreach ($tm in $tagMatches) {
            [void]$allTags.Add($tm.Groups[1].Value.Trim())
        }
    }
    
    # Strip any top-level H1 that duplicates the title
    $bodyTrimmed = $body.Trim()
    if ($bodyTrimmed -match "^#\s+(.*?)\r?\n") {
        $bodyTrimmed = $bodyTrimmed -replace "^#\s+.*?\r?\n+", ""
    }
    
    # Anchor slug for TOC
    $slug = ($title.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    $tocItems.Add("- [$title](#$slug)")
    
    # Build section
    $sectionText = "$headingPrefix $title`n`n$bodyTrimmed"
    $mergedSections.Add($sectionText)
}

# Construct Final Document
$outputDoc = [System.Text.StringBuilder]::new()

# Master Frontmatter
$folderName = Split-Path $SourceDir -Leaf
$outputDoc.AppendLine("---") | Out-Null
$outputDoc.AppendLine("title: `"Consolidated $folderName`"") | Out-Null
if ($allTags.Count -gt 0) {
    $outputDoc.AppendLine("tags:") | Out-Null
    foreach ($t in $allTags) {
        $outputDoc.AppendLine("  - $t") | Out-Null
    }
}
$outputDoc.AppendLine("merged_date: `"$([System.DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))`"") | Out-Null
$outputDoc.AppendLine("source_file_count: $($files.Count)") | Out-Null
$outputDoc.AppendLine("---") | Out-Null
$outputDoc.AppendLine("") | Out-Null
$outputDoc.AppendLine("# Consolidated $folderName") | Out-Null
$outputDoc.AppendLine("") | Out-Null

# Optional TOC
if ($IncludeTOC -or (-not $PSBoundParameters.ContainsKey('IncludeTOC'))) {
    $outputDoc.AppendLine("## Table of Contents") | Out-Null
    $outputDoc.AppendLine("") | Out-Null
    foreach ($item in $tocItems) {
        $outputDoc.AppendLine($item) | Out-Null
    }
    $outputDoc.AppendLine("") | Out-Null
    $outputDoc.AppendLine("---") | Out-Null
    $outputDoc.AppendLine("") | Out-Null
}

# Append Sections
for ($i = 0; $i -lt $mergedSections.Count; $i++) {
    $outputDoc.AppendLine($mergedSections[$i]) | Out-Null
    if ($i -lt $mergedSections.Count - 1) {
        $outputDoc.AppendLine("") | Out-Null
        $outputDoc.AppendLine("---") | Out-Null
        $outputDoc.AppendLine("") | Out-Null
    }
}

$finalContent = $outputDoc.ToString()

if ($DryRun) {
    Write-Host "`n[DRY-RUN] Simulasi penggabungan selesai:" -ForegroundColor Yellow
    Write-Host "  -> File target: $OutputFile" -ForegroundColor Yellow
    Write-Host "  -> Total bagian: $($files.Count)" -ForegroundColor Yellow
    Write-Host "  -> Karakter total: $($finalContent.Length)" -ForegroundColor Yellow
    return
}

# Write Output File
$outParent = Split-Path $OutputFile -Parent
if ($outParent -and (-not (Test-Path $outParent))) {
    New-Item -ItemType Directory -Path $outParent -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutputFile, $finalContent, [System.Text.Encoding]::UTF8)
Write-Host "`n[SUCCESS] Berhasil menggabungkan $($files.Count) file ke: $OutputFile" -ForegroundColor Green

# Optional Archive to Trash-Bin
if ($ArchiveSources) {
    Write-Host "`n[ARCHIVE] Mengarsipkan file sumber ke trash-bin/..." -ForegroundColor Cyan
    # Discover repo root
    $repoRoot = $SourceDir
    $cursor = $SourceDir
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
    foreach ($f in $files) {
        $rel = [System.IO.Path]::GetRelativePath($repoRoot, $f.FullName)
        $dest = Join-Path $trashBin $rel
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Move-Item -LiteralPath $f.FullName -Destination $dest -Force
        Write-Host "  -> Archived: $($f.Name) => $dest" -ForegroundColor DarkGray
    }
}
