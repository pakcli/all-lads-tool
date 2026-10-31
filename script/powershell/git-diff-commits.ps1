<#
.SYNOPSIS
    Git Repo Commit Size & Compiled Diff Analyzer (Modular Edition).
.DESCRIPTION
    Modular commit size and diff analyzer wired directly to module/git-diffengine.psm1.
    Imports:
      - module/git-diffengine.psm1
      - module/git-core.psm1
      - module/history.psm1
.PARAMETER Compare
    Commit indexes or range to compare (e.g. 0,1,2 or 0vs1 or 1-5).
.PARAMETER Mode
    Analysis mode: 'src', 'public', or 'both'.
.PARAMETER SrcFolder
    Target source folder to measure (default auto-detected).
.PARAMETER DistFolder
    Target output/distribution folder (default auto-detected).
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Compare = "",

    [Parameter(Position = 1)]
    [string]$Mode = "",

    [string]$SrcFolder = "",
    [string]$DistFolder = "",
    [switch]$NoCache
)

# ------------------------------------------------------------------------------
# 1. WIRE UP INTERNAL MODULES
# ------------------------------------------------------------------------------
Import-Module "$PSScriptRoot\module\git-diffengine.psm1" -Force
Import-Module "$PSScriptRoot\module\git-core.psm1" -Force
Import-Module "$PSScriptRoot\module\history.psm1" -Force

$ErrorActionPreference = "Continue"

# -- Auto-Detect Project Structure ---------------------------------------------
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$RepoName = (Get-Item $RepoRoot).Name

if ([string]::IsNullOrWhiteSpace($SrcFolder)) {
    $srcCandidates = @("src", "source", "app", "client", ".")
    foreach ($c in $srcCandidates) {
        $p = Join-Path $RepoRoot $c
        if ($c -ne "." -and (Test-Path $p -PathType Container)) {
            $SrcFolder = $c
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($SrcFolder)) { $SrcFolder = "src" }
}

if ([string]::IsNullOrWhiteSpace($DistFolder)) {
    $distCandidates = @("public", "dist", "build", "out", "output", "wwwroot")
    foreach ($c in $distCandidates) {
        $p = Join-Path $RepoRoot $c
        if (Test-Path $p -PathType Container) {
            $DistFolder = $c
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($DistFolder)) { $DistFolder = "public" }
}

$TempBaseSandbox = Join-Path ([System.IO.Path]::GetTempPath()) "git_diff_sandbox_$RepoName"
if (-not (Test-Path $TempBaseSandbox)) {
    New-Item -ItemType Directory -Path $TempBaseSandbox -Force | Out-Null
}

function Minify-GenericCss {
    param([string]$Css)
    $min = [System.Text.RegularExpressions.Regex]::Replace($Css, "/\*[\s\S]*?\*/", "")
    $min = [System.Text.RegularExpressions.Regex]::Replace($min, "\s+", " ")
    $min = [System.Text.RegularExpressions.Regex]::Replace($min, "\s*([{}:;,])\s*", '$1')
    $min = [System.Text.RegularExpressions.Regex]::Replace($min, ";\}", "}")
    return $min.Trim()
}

function Minify-GenericJs {
    param([string]$SourcePath, [string]$DestPath)
    $parent = Split-Path $DestPath -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    try {
        $raw = Get-Content $SourcePath -Raw -Encoding UTF8
        $clean = [System.Text.RegularExpressions.Regex]::Replace($raw, "(?m)^\s*//.*$", "")
        $clean = [System.Text.RegularExpressions.Regex]::Replace($clean, "/\*[\s\S]*?\*/", "")
        $clean = [System.Text.RegularExpressions.Regex]::Replace($clean, "(?m)^\s*`r?`n", "")
        [System.IO.File]::WriteAllText($DestPath, $clean.Trim(), [System.Text.Encoding]::UTF8)
    } catch {
        Copy-Item -Path $SourcePath -Destination $DestPath -Force
    }
}

function Invoke-GenericCompileTree {
    param([string]$SourceDir, [string]$OutputDir)
    if (Test-Path $OutputDir) {
        Remove-Item -Path $OutputDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    if (-not (Test-Path $SourceDir)) {
        return @{ TotalBytes = 0; FileCount = 0 }
    }

    $allFiles = Get-ChildItem -Path $SourceDir -Recurse -File
    $ignoreExts = @(".md", ".map", ".bak", ".log", ".tmp")
    $ignoreDirs = @(".git", "node_modules", ".vscode", "docs", "brief")

    foreach ($file in $allFiles) {
        $skip = $false
        foreach ($id in $ignoreDirs) {
            if ($file.FullName -match "[\\/]$id([\\/]|$)") { $skip = $true; break }
        }
        if ($skip -or ($file.Extension -in $ignoreExts)) { continue }

        $rel = $file.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
        $dest = Join-Path $OutputDir $rel
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

        if ($file.Extension -in @(".js", ".mjs")) {
            Minify-GenericJs -SourcePath $file.FullName -DestPath $dest
        } elseif ($file.Extension -in @(".css")) {
            $rawCss = Get-Content $file.FullName -Raw -Encoding UTF8
            [System.IO.File]::WriteAllText($dest, (Minify-GenericCss $rawCss), [System.Text.Encoding]::UTF8)
        } else {
            Copy-Item -Path $file.FullName -Destination $dest -Force
        }
    }

    return (Measure-DirectoryBytes -dirPath $OutputDir)
}

function Get-GitCommitList {
    param([int]$MaxCount = 30)
    $commits = @()
    $commits += [PSCustomObject]@{
        Index       = 0
        Hash        = "CURRENT"
        ShortHash   = "CURRENT"
        Date        = "Live State"
        Message     = "Working Directory (Live / Uncommitted Changes)"
        SrcBytes    = $null
        SrcFiles    = $null
        PubBytes    = $null
        PubFiles    = $null
        IsLive      = $true
    }

    $logOutput = Invoke-GitCommand -RepoPath $RepoRoot -Arguments @("log", '--pretty=format:%H|%h|%cd|%s', '--date=format:%Y-%m-%d %H:%M', "-n", "$MaxCount")
    if ($logOutput) {
        $idx = 1
        foreach ($line in ($logOutput -split "`r?`n")) {
            if (-not [string]::IsNullOrWhiteSpace($line)) {
                $parts = $line.Split('|')
                if ($parts.Count -ge 4) {
                    $commits += [PSCustomObject]@{
                        Index       = $idx
                        Hash        = $parts[0]
                        ShortHash   = $parts[1]
                        Date        = $parts[2]
                        Message     = $parts[3]
                        SrcBytes    = $null
                        SrcFiles    = $null
                        PubBytes    = $null
                        PubFiles    = $null
                        IsLive      = $false
                    }
                    $idx++
                }
            }
        }
    }
    return $commits
}

function Measure-CommitSize {
    param(
        [PSCustomObject]$CommitObj,
        [string]$TargetMode
    )

    $measureSrc = ($TargetMode -in @("src", "both"))
    $measurePub = ($TargetMode -in @("public", "both"))

    if ($measureSrc -and $null -eq $CommitObj.SrcBytes) {
        if ($CommitObj.IsLive) {
            $srcPath = Join-Path $RepoRoot $SrcFolder
            $m = Measure-DirectoryBytes -dirPath $srcPath
            $CommitObj.SrcBytes = $m.TotalBytes
            $CommitObj.SrcFiles = $m.FileCount
        } else {
            $rawLs = Invoke-GitCommand -RepoPath $RepoRoot -Arguments @("ls-tree", "-r", "-l", $CommitObj.Hash, $SrcFolder)
            if (-not $rawLs) {
                $rawLs = Invoke-GitCommand -RepoPath $RepoRoot -Arguments @("ls-tree", "-r", "-l", $CommitObj.Hash)
            }
            $sBytes = 0
            $sCount = 0
            if ($rawLs) {
                foreach ($l in ($rawLs -split "`r?`n")) {
                    if ($l -match '^\d+\s+blob\s+[0-9a-f]+\s+(\d+)\t') {
                        $sBytes += [int64]$matches[1]
                        $sCount++
                    }
                }
            }
            $CommitObj.SrcBytes = $sBytes
            $CommitObj.SrcFiles = $sCount
        }
    }

    if ($measurePub -and $null -eq $CommitObj.PubBytes) {
        $cacheDir = Join-Path $TempBaseSandbox "cache_$($CommitObj.ShortHash)"
        $cacheDist = Join-Path $cacheDir "dist"
        $isCached = (Test-Path $cacheDist) -and (-not $NoCache) -and (-not $CommitObj.IsLive)

        if ($isCached) {
            $m = Measure-DirectoryBytes -dirPath $cacheDist
            $CommitObj.PubBytes = $m.TotalBytes
            $CommitObj.PubFiles = $m.FileCount
        } else {
            Write-Host "  [BUILD] Compiling [$($CommitObj.Index)] $($CommitObj.ShortHash) via sandbox..." -ForegroundColor DarkCyan -NoNewline
            if ($CommitObj.IsLive) {
                $liveSrc = Join-Path $RepoRoot $SrcFolder
                $res = Invoke-GenericCompileTree -SourceDir $liveSrc -OutputDir $cacheDist
                $CommitObj.PubBytes = $res.TotalBytes
                $CommitObj.PubFiles = $res.FileCount
            } else {
                $extractDir = Join-Path $cacheDir "src_extracted"
                $ok = Invoke-SandboxArchiveExtract -repoDir $RepoRoot -commitRef $CommitObj.Hash -targetSandboxDir $extractDir
                if ($ok) {
                    $compileSrc = Join-Path $extractDir $SrcFolder
                    if (-not (Test-Path $compileSrc)) { $compileSrc = $extractDir }
                    $res = Invoke-GenericCompileTree -SourceDir $compileSrc -OutputDir $cacheDist
                    $CommitObj.PubBytes = $res.TotalBytes
                    $CommitObj.PubFiles = $res.FileCount
                } else {
                    $CommitObj.PubBytes = 0
                    $CommitObj.PubFiles = 0
                }
            }
            $sizeStr = Format-ByteSize -Bytes $CommitObj.PubBytes
            Write-Host " Done ($sizeStr)" -ForegroundColor Green
        }
    }
}

function Parse-CommitInput {
    param([string]$inputStr, [int]$maxIndex)
    $clean = $inputStr.Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { return @() }

    $clean = $clean -ireplace '\bcurrent\b', '0'
    $clean = $clean -ireplace '\blatest\b', '1'
    $clean = $clean -ireplace '\bhead\b', '1'
    $clean = $clean -ireplace '\s*vs\s*', ','
    $clean = $clean -replace '\s+', ','

    $indexes = [System.Collections.Generic.List[int]]::new()
    $chunks = $clean.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries)

    foreach ($chunk in $chunks) {
        if ($chunk -match '^\d+$') {
            $val = [int]$chunk
            if ($val -le $maxIndex -and -not $indexes.Contains($val)) { $indexes.Add($val) }
        } elseif ($chunk -match '^(\d+)\s*-\s*(\d+)$') {
            $start = [int]$matches[1]
            $end = [int]$matches[2]
            $step = if ($start -le $end) { 1 } else { -1 }
            for ($i = $start; $i -ne ($end + $step); $i += $step) {
                if ($i -ge 0 -and $i -le $maxIndex -and -not $indexes.Contains($i)) {
                    $indexes.Add($i)
                }
            }
        }
    }
    return $indexes.ToArray()
}

# ------------------------------------------------------------------------------
# 2. INTERACTIVE DASHBOARD / CLI EXECUTION
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   GIT COMMIT SIZE & COMPILED DIFF ANALYZER (MODULAR)  ::  all-lads-tool         " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host " Repository : $RepoName ($RepoRoot)" -ForegroundColor Yellow
Write-Host " Source Dir : $SrcFolder/ | Dist Dir : $DistFolder/" -ForegroundColor DarkGray
Write-Host " Engine     : module/git-diffengine.psm1" -ForegroundColor DarkGray
Write-Host "================================================================================" -ForegroundColor Cyan

$commits = Get-GitCommitList -MaxCount 25
if ($commits.Count -le 1) {
    Write-Host "[INFO] Repository has no commits yet. Only Live working tree available." -ForegroundColor Yellow
}

if ([string]::IsNullOrWhiteSpace($Mode)) { $Mode = "both" }

if (-not [string]::IsNullOrWhiteSpace($Compare)) {
    $selectedIndices = Parse-CommitInput -inputStr $Compare -maxIndex ($commits.Count - 1)
} else {
    Write-Host "`nRecent Commit Log:" -ForegroundColor Green
    foreach ($c in $commits) {
        $prefix = if ($c.IsLive) { "[ LIVE ]" } else { "[$($c.Index)]" }
        Write-Host ("  {0,-8} {1,-8} {2,-16} {3}" -f $prefix, $c.ShortHash, $c.Date, $c.Message) -ForegroundColor Gray
    }
    Write-Host ""
    $inputVal = Read-Host "Enter commits to compare (e.g. 0,1 or 0vs1 or 1-3) [Default: 0,1]"
    if ([string]::IsNullOrWhiteSpace($inputVal)) { $inputVal = "0,1" }
    $selectedIndices = Parse-CommitInput -inputStr $inputVal -maxIndex ($commits.Count - 1)
}

if ($selectedIndices.Count -eq 0) {
    Write-Host "[ERROR] No valid commits selected." -ForegroundColor Red
    exit 1
}

Write-Host "`nMeasuring selected commits ($($selectedIndices -join ', '))..." -ForegroundColor Cyan
$evalCommits = @()
foreach ($idx in $selectedIndices) {
    $targetCommit = $commits | Where-Object { $_.Index -eq $idx }
    if ($targetCommit) {
        Measure-CommitSize -CommitObj $targetCommit -TargetMode $Mode
        $evalCommits += $targetCommit
    }
}

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host " DIFF COMPARISON REPORT (Mode: $Mode)" -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan

for ($i = 0; $i -lt $evalCommits.Count; $i++) {
    $c = $evalCommits[$i]
    $tag = if ($c.IsLive) { "[0] CURRENT" } else { "[$($c.Index)] $($c.ShortHash)" }
    $srcStr = if ($c.SrcBytes -ne $null) { Format-ByteSize $c.SrcBytes } else { "N/A" }
    $pubStr = if ($c.PubBytes -ne $null) { Format-ByteSize $c.PubBytes } else { "N/A" }

    $deltaStr = ""
    if ($i -gt 0) {
        $prev = $evalCommits[$i - 1]
        if ($c.PubBytes -ne $null -and $prev.PubBytes -ne $null) {
            $diff = $c.PubBytes - $prev.PubBytes
            $deltaStr = " (Delta: " + (Format-DeltaSize $diff) + ")"
        }
    }

    Write-Host ("  {0,-16} | Src: {1,-10} | Public: {2,-10}{3} | {4}" -f $tag, $srcStr, $pubStr, $deltaStr, $c.Message) -ForegroundColor White
}
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
