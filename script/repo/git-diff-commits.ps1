<#
.SYNOPSIS
    Git Repo Commit Size & Compiled Diff Analyzer (Context: Repo)
.DESCRIPTION
    Modular commit size and diff analyzer wired directly to adapter/git-diffengine.psm1.
    Imports:
      - adapter/git-diffengine.psm1
      - adapter/git-core.psm1
      - adapter/history.psm1
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
# 1. WIRE UP INTERNAL ADAPTER MODULES
# ------------------------------------------------------------------------------
Import-Module "$PSScriptRoot\adapter\git-diffengine.psm1" -Force
Import-Module "$PSScriptRoot\adapter\git-core.psm1" -Force
Import-Module "$PSScriptRoot\adapter\history.psm1" -Force

$ErrorActionPreference = "Continue"

# -- Auto-Detect Project Structure ---------------------------------------------
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$RepoName = (Get-Item -LiteralPath $RepoRoot).Name

if ([string]::IsNullOrWhiteSpace($SrcFolder)) {
    $srcCandidates = @("src", "source", "app", "client", ".")
    foreach ($c in $srcCandidates) {
        $p = Join-Path $RepoRoot $c
        if ($c -ne "." -and (Test-Path -LiteralPath $p -PathType Container)) {
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
        if (Test-Path -LiteralPath $p -PathType Container) {
            $DistFolder = $c
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($DistFolder)) { $DistFolder = "public" }
}

$TempBaseSandbox = Join-Path ([System.IO.Path]::GetTempPath()) "git_diff_sandbox_$RepoName"
if (-not (Test-Path -LiteralPath $TempBaseSandbox)) {
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
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    try {
        $raw = Get-Content -LiteralPath $SourcePath -Raw -Encoding UTF8
        $clean = [System.Text.RegularExpressions.Regex]::Replace($raw, "(?m)^\s*//.*$", "")
        $clean = [System.Text.RegularExpressions.Regex]::Replace($clean, "/\*[\s\S]*?\*/", "")
        $clean = [System.Text.RegularExpressions.Regex]::Replace($clean, "(?m)^\s*`r?`n", "")
        [System.IO.File]::WriteAllText($DestPath, $clean.Trim(), [System.Text.Encoding]::UTF8)
    } catch {
        Copy-Item -LiteralPath $SourcePath -Destination $DestPath -Force
    }
}

function Invoke-GenericCompileTree {
    param([string]$SourceDir, [string]$OutputDir)
    if (Test-Path -LiteralPath $OutputDir) {
        Remove-Item -LiteralPath $OutputDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

    if (-not (Test-Path -LiteralPath $SourceDir)) {
        return @{ TotalBytes = 0; FileCount = 0 }
    }

    $allFiles = Get-ChildItem -LiteralPath $SourceDir -Recurse -File
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
        if (-not (Test-Path -LiteralPath $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }

        if ($file.Extension -in @(".js", ".mjs")) {
            Minify-GenericJs -SourcePath $file.FullName -DestPath $dest
        } elseif ($file.Extension -in @(".css")) {
            $rawCss = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
            $minCss = Minify-GenericCss -Css $rawCss
            [System.IO.File]::WriteAllText($dest, $minCss, [System.Text.Encoding]::UTF8)
        } else {
            Copy-Item -LiteralPath $file.FullName -Destination $dest -Force
        }
    }

    return (Measure-DirectoryBytes -dirPath $OutputDir)
}

function Get-GitCommitList {
    param([int]$MaxCount = 20)
    $list = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. LIVE Virtual Node (Index 0)
    $list.Add([PSCustomObject]@{
        Index     = 0
        Hash      = "LIVE"
        ShortHash = "LIVE"
        Date      = "Working Tree"
        Message   = "Live Uncommitted State"
        IsLive    = $true
        SrcBytes  = $null
        PubBytes  = $null
    })

    # 2. Historical Git Commits
    Push-Location $RepoRoot
    try {
        $rawLog = git log -n $MaxCount --pretty=format:"%H|%h|%cd|%s" --date=format:"%Y-%m-%d %H:%M" 2>$null
        if ($rawLog) {
            $idx = 1
            foreach ($line in ($rawLog -split "`r?`n")) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    $parts = $line.Split('|', 4)
                    $list.Add([PSCustomObject]@{
                        Index     = $idx
                        Hash      = $parts[0]
                        ShortHash = $parts[1]
                        Date      = $parts[2]
                        Message   = $parts[3]
                        IsLive    = $false
                        SrcBytes  = $null
                        PubBytes  = $null
                    })
                    $idx++
                }
            }
        }
    } finally {
        Pop-Location
    }
    return $list
}

function Measure-CommitSize {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$CommitObj,
        [string]$TargetMode = "both"
    )

    $srcPath = Join-Path $RepoRoot $SrcFolder
    $distPath = Join-Path $RepoRoot $DistFolder

    if ($CommitObj.IsLive) {
        if ($TargetMode -in @("src", "both")) {
            $srcMeas = Measure-DirectoryBytes -dirPath $srcPath -excludeDirs @(".git", "node_modules", ".vscode")
            $CommitObj.SrcBytes = $srcMeas.TotalBytes
        }
        if ($TargetMode -in @("public", "both")) {
            if (Test-Path -LiteralPath $distPath) {
                $pubMeas = Measure-DirectoryBytes -dirPath $distPath
                $CommitObj.PubBytes = $pubMeas.TotalBytes
            } else {
                $tempLiveOut = Join-Path $TempBaseSandbox "live_compiled"
                $compiled = Invoke-GenericCompileTree -SourceDir $srcPath -OutputDir $tempLiveOut
                $CommitObj.PubBytes = $compiled.TotalBytes
            }
        }
    } else {
        $commitSandbox = Join-Path $TempBaseSandbox $CommitObj.ShortHash
        $extractSuccess = $true
        if (-not (Test-Path -LiteralPath $commitSandbox) -or $NoCache) {
            Write-Host -NoNewline "  Extracting $($CommitObj.ShortHash)... " -ForegroundColor DarkGray
            $extractSuccess = Invoke-SandboxArchiveExtract -repoDir $RepoRoot -commitRef $CommitObj.Hash -targetSandboxDir $commitSandbox
            if ($extractSuccess) {
                Write-Host "Done" -ForegroundColor Green
            } else {
                Write-Host "Failed" -ForegroundColor Red
            }
        }

        if ($extractSuccess) {
            $subSrc = Join-Path $commitSandbox $SrcFolder
            $subDist = Join-Path $commitSandbox $DistFolder

            if ($TargetMode -in @("src", "both")) {
                $meas = Measure-DirectoryBytes -dirPath $subSrc -excludeDirs @(".git", "node_modules", ".vscode")
                $CommitObj.SrcBytes = $meas.TotalBytes
            }

            if ($TargetMode -in @("public", "both")) {
                if (Test-Path -LiteralPath $subDist) {
                    $meas = Measure-DirectoryBytes -dirPath $subDist
                    $CommitObj.PubBytes = $meas.TotalBytes
                } else {
                    $sandboxOut = Join-Path $commitSandbox "_compiled_dist"
                    Write-Host -NoNewline "  Compiling $($CommitObj.ShortHash)... " -ForegroundColor DarkGray
                    $compiled = Invoke-GenericCompileTree -SourceDir $subSrc -OutputDir $sandboxOut
                    $CommitObj.PubBytes = $compiled.TotalBytes
                    $sizeStr = Format-ByteSize -Bytes $CommitObj.PubBytes
                    Write-Host " Done ($sizeStr)" -ForegroundColor Green
                }
            }
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
Write-Host " Engine     : adapter/git-diffengine.psm1" -ForegroundColor DarkGray
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
