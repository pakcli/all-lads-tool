# ==============================================================================
# GIT REPO COMMIT SIZE & COMPILED DIFF ANALYZER (MODULAR)
# File: ps_diff-commits.ps1
#
# Mengukur dan membandingkan ukuran repositori antar-commit git secara modular:
#   [0] Current Working Directory (Live / Uncommitted State)
#   [1] Latest Commit (HEAD)
#   [2] HEAD~1
#   [3] HEAD~2 ... dst
#
# Menu Pilihan Analisis:
#   1. size src        - Analisis ukuran Source Code (src/)
#   2. public compile  - Analisis ukuran Build/Kompilasi (public/) di folder sandbox temp
#   3. both            - Analisis komprehensif src/ dan public/ side-by-side
#
# Format Input Komparasi (fleksibel dengan/tanpa spasi):
#   - Koma   : 1,2,3,4,5 atau 1, 2, 3, 4, 5
#   - 'vs'   : 2vs23 atau 2 vs 23 atau 0vs1 atau 2vs23vsdst
#   - Range  : 1-5 atau 0-3
#   - Alias  : current, latest, head
#
# Desain Modular:
#   - Tanpa hardcode: Dapat digunakan di proyek web development mana pun (React, Vue, Vanilla, dll.)
#   - Aman & Terisolasi: Kompilasi commit lain dilakukan di sandbox folder TEMP via 'git archive'
#     sehingga TIDAK PERNAH menyentuh, merusak, atau men-checkout working directory user.
# ==============================================================================

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

$ErrorActionPreference = "Continue"

# -- Auto-Detect Project Structure ---------------------------------------------
$RepoRoot = $PSScriptRoot
$RepoName = (Get-Item $RepoRoot).Name

# Deteksi folder Source
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

# Deteksi folder Dist / Output Kompilasi
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

# Direktori Sandbox Temp (Di luar repositori agar workspace tetap 100% bersih)
$TempBaseSandbox = Join-Path ([System.IO.Path]::GetTempPath()) "git_diff_sandbox_$RepoName"
if (-not (Test-Path $TempBaseSandbox)) {
    New-Item -ItemType Directory -Path $TempBaseSandbox -Force | Out-Null
}

# -- Helper: Format Byte Size --------------------------------------------------
function Format-ByteSize {
    param([int64]$Bytes)
    if ($Bytes -ge 1GB) {
        $val = [math]::Round($Bytes / 1GB, 2)
        return "$val GB"
    } elseif ($Bytes -ge 1MB) {
        $val = [math]::Round($Bytes / 1MB, 2)
        return "$val MB"
    } elseif ($Bytes -ge 1KB) {
        $val = [math]::Round($Bytes / 1KB, 1)
        return "$val KB"
    } else {
        return "$Bytes B"
    }
}

# -- Helper: Format Delta Size -------------------------------------------------
function Format-DeltaSize {
    param([int64]$DeltaBytes)
    if ($DeltaBytes -gt 0) {
        $kb = [math]::Round($DeltaBytes / 1KB, 1)
        return "+$kb KB"
    } elseif ($DeltaBytes -lt 0) {
        $kb = [math]::Round($DeltaBytes / 1KB, 1)
        return "$kb KB"
    } else {
        return "0 KB"
    }
}

# -- Compiler: Generic Web Minifier Engine (HTML, CSS, JS, Assets) -------------
function Minify-GenericHtml {
    param([string]$Html)
    $min = [System.Text.RegularExpressions.Regex]::Replace($Html, "<!--(?!\[if)[\s\S]*?-->", "")
    $min = [System.Text.RegularExpressions.Regex]::Replace($min, ">\s+<", "><")
    return $min.Trim()
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

    # 1. Coba gunakan Terser jika terinstal
    $terserCmd = "npx --no-install terser `"$SourcePath`" --module --compress passes=2,drop_console=false --mangle -o `"$DestPath`""
    $terserOut = cmd.exe /c "$terserCmd" 2>&1

    if ($LASTEXITCODE -eq 0 -and (Test-Path $DestPath) -and (Get-Item $DestPath).Length -gt 0) {
        return
    }

    # 2. Fallback: Minifikasi Regex Cepat & Aman (Zero-dependency)
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
    param(
        [string]$SourceDir,
        [string]$OutputDir
    )

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
        # Cek apakah berada dalam folder yang diabaikan
        $skip = $false
        foreach ($id in $ignoreDirs) {
            if ($file.FullName -match "[\\/]$id([\\/]|$)") { $skip = $true; break }
        }
        if ($skip -or ($file.Extension -in $ignoreExts)) { continue }

        $rel = $file.FullName.Substring($SourceDir.Length).TrimStart('\', '/')
        $targetFile = Join-Path $OutputDir $rel
        $targetParent = Split-Path $targetFile -Parent
        if (-not (Test-Path $targetParent)) { New-Item -ItemType Directory -Path $targetParent -Force | Out-Null }

        $ext = $file.Extension.ToLower()

        if ($ext -in @(".html", ".htm")) {
            $raw = Get-Content $file.FullName -Raw -Encoding UTF8
            $min = Minify-GenericHtml -Html $raw
            [System.IO.File]::WriteAllText($targetFile, $min, [System.Text.Encoding]::UTF8)
        } elseif ($ext -eq ".css") {
            $raw = Get-Content $file.FullName -Raw -Encoding UTF8
            $min = Minify-GenericCss -Css $raw
            [System.IO.File]::WriteAllText($targetFile, $min, [System.Text.Encoding]::UTF8)
        } elseif ($ext -in @(".js", ".mjs")) {
            Minify-GenericJs -SourcePath $file.FullName -DestPath $targetFile
        } else {
            # File aset biner/gambar/font/json disalin langsung
            Copy-Item -Path $file.FullName -Destination $targetFile -Force
        }
    }

    # Hitung total hasil kompilasi
    $compFiles = Get-ChildItem -Path $OutputDir -Recurse -File -ErrorAction SilentlyContinue
    $totalBytes = 0
    $count = 0
    foreach ($f in $compFiles) {
        $totalBytes += $f.Length
        $count++
    }

    return @{ TotalBytes = $totalBytes; FileCount = $count }
}

# -- Sandbox: Ekstrak Commit Tertentu Tanpa Mengubah Working Tree ---------------
function Extract-CommitToSandbox {
    param(
        [string]$CommitHash,
        [string]$TargetExtractDir
    )

    if (Test-Path $TargetExtractDir) {
        Remove-Item -Path $TargetExtractDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $TargetExtractDir -Force | Out-Null

    $hasTar = $null -ne (Get-Command "tar.exe" -ErrorAction SilentlyContinue)
    $success = $false

    if ($hasTar) {
        try {
            cmd.exe /c "git archive --format=tar $CommitHash | tar -xf - -C `"$TargetExtractDir`"" 2>$null
            if ($LASTEXITCODE -eq 0 -and (Get-ChildItem $TargetExtractDir).Count -gt 0) {
                $success = $true
            }
        } catch {}
    }

    if (-not $success) {
        $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "git_archive_$CommitHash.zip"
        cmd.exe /c "git archive --format=zip $CommitHash -o `"$tempZip`"" 2>$null
        if (Test-Path $tempZip) {
            Expand-Archive -Path $tempZip -DestinationPath $TargetExtractDir -Force
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
            $success = $true
        }
    }

    return $success
}

# -- Function: Get Commit List from Git ----------------------------------------
function Get-GitCommitList {
    param([int]$MaxCount = 30)

    $commits = @()

    # Slot [0]: Current Working Directory (Live Uncommitted State)
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

    # Slot [1..N]: Git History Commits
    $logLines = git log --pretty=format:"%H|%h|%cd|%s" --date=format:"%Y-%m-%d %H:%M" -n $MaxCount
    $idx = 1
    foreach ($line in $logLines) {
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

    return $commits
}

# -- Function: Measure Size (Src and/or Compiled Public) -----------------------
function Measure-CommitSize {
    param(
        [PSCustomObject]$CommitObj,
        [string]$TargetMode # "src", "public", "both"
    )

    $measureSrc = ($TargetMode -in @("src", "both"))
    $measurePub = ($TargetMode -in @("public", "both"))

    # 1. Ukur Ukuran SRC
    if ($measureSrc -and $null -eq $CommitObj.SrcBytes) {
        if ($CommitObj.IsLive) {
            $srcPath = Join-Path $RepoRoot $SrcFolder
            if (Test-Path $srcPath) {
                $files = Get-ChildItem -Path $srcPath -Recurse -File -ErrorAction SilentlyContinue
                $sBytes = 0
                $sCount = 0
                foreach ($f in $files) { $sBytes += $f.Length; $sCount++ }
                $CommitObj.SrcBytes = $sBytes
                $CommitObj.SrcFiles = $sCount
            } else {
                $CommitObj.SrcBytes = 0
                $CommitObj.SrcFiles = 0
            }
        } else {
            # Dari tree git
            $lines = git ls-tree -r -l $CommitObj.Hash $SrcFolder 2>$null
            if (-not $lines) {
                # Fallback jika folder src belum ada di commit lama
                $lines = git ls-tree -r -l $CommitObj.Hash 2>$null
            }
            $sBytes = 0
            $sCount = 0
            foreach ($l in $lines) {
                if ($l -match '^\d+\s+blob\s+[0-9a-f]+\s+(\d+)\t') {
                    $sBytes += [int64]$matches[1]
                    $sCount++
                }
            }
            $CommitObj.SrcBytes = $sBytes
            $CommitObj.SrcFiles = $sCount
        }
    }

    # 2. Ukur Ukuran PUBLIC (Hasil Kompilasi Sandbox)
    if ($measurePub -and $null -eq $CommitObj.PubBytes) {
        $cacheDir = Join-Path $TempBaseSandbox "cache_$($CommitObj.ShortHash)"
        $cacheDist = Join-Path $cacheDir "dist"

        $isCached = (Test-Path $cacheDist) -and (-not $NoCache) -and (-not $CommitObj.IsLive)

        if ($isCached) {
            $cachedFiles = Get-ChildItem -Path $cacheDist -Recurse -File -ErrorAction SilentlyContinue
            $pBytes = 0
            $pCount = 0
            foreach ($f in $cachedFiles) { $pBytes += $f.Length; $pCount++ }
            $CommitObj.PubBytes = $pBytes
            $CommitObj.PubFiles = $pCount
        } else {
            Write-Host "  [BUILD] Mengompilasi [$($CommitObj.Index)] $($CommitObj.ShortHash) di sandbox temp..." -ForegroundColor DarkCyan -NoNewline

            if ($CommitObj.IsLive) {
                # Kompilasi dari Live Source
                $liveSrc = Join-Path $RepoRoot $SrcFolder
                $res = Invoke-GenericCompileTree -SourceDir $liveSrc -OutputDir $cacheDist
                $CommitObj.PubBytes = $res.TotalBytes
                $CommitObj.PubFiles = $res.FileCount
            } else {
                # Ekstrak commit ke sandbox, lalu kompilasi
                $extractDir = Join-Path $cacheDir "src_extracted"
                $ok = Extract-CommitToSandbox -CommitHash $CommitObj.Hash -TargetExtractDir $extractDir
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
            Write-Host " Selesai ($sizeStr)" -ForegroundColor Green
        }
    }
}

# -- Helper: Parse User Input String -------------------------------------------
function Parse-CommitInput {
    param(
        [string]$inputStr,
        [int]$maxIndex
    )

    $clean = $inputStr.Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) { return @() }

    # Alias keywords
    $clean = $clean -ireplace '\bcurrent\b', '0'
    $clean = $clean -ireplace '\blatest\b', '1'
    $clean = $clean -ireplace '\bhead\b', '1'

    # Range syntax (e.g. 1-5 atau 0-3)
    if ($clean -match '^\s*(\d+)\s*-\s*(\d+)\s*$') {
        $start = [int]$matches[1]
        $end = [int]$matches[2]
        $range = if ($start -le $end) { ($start..$end) } else { ($start..$end) }
        return ($range | Where-Object { $_ -ge 0 -and $_ -le $maxIndex })
    }

    # Ganti 'vs' (case-insensitive, dengan/tanpa spasi) menjadi koma
    $clean = [regex]::Replace($clean, '(?i)\s*vs\s*', ',')
    # Ganti multiple spasi menjadi koma
    $clean = [regex]::Replace($clean, '[\s,]+', ',')

    $tokens = $clean.Split(',', [System.StringSplitOptions]::RemoveEmptyEntries)
    $results = @()
    foreach ($t in $tokens) {
        $val = 0
        if ([int]::TryParse($t.Trim(), [ref]$val)) {
            if ($val -ge 0 -and $val -le $maxIndex) {
                if ($results -notcontains $val) {
                    $results += $val
                }
            } else {
                Write-Host "  [!] Peringatan: Indeks [$val] di luar jangkauan (0 - $maxIndex), diabaikan." -ForegroundColor Yellow
            }
        }
    }

    return $results
}

# -- View: Banner Header -------------------------------------------------------
function Show-Banner {
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   GIT COMMIT SIZE & COMPILED DIFF ANALYZER (MODULAR)" -ForegroundColor Yellow
    Write-Host "   Repositori  : $RepoName" -ForegroundColor White
    Write-Host "   Source Dir  : $SrcFolder/   |   Dist Target : $DistFolder/" -ForegroundColor DarkCyan
    Write-Host "   Sandbox     : $TempBaseSandbox" -ForegroundColor DarkGray
    Write-Host "========================================================================" -ForegroundColor Cyan
}

# -- View: Menu Pemilihan Mode -------------------------------------------------
function Prompt-ModeMenu {
    Write-Host "`nPILIH COMMAND / MODE PENGUKURAN:" -ForegroundColor Cyan
    Write-Host "  [1] size src        - Analisis ukuran Source Code ($SrcFolder/)" -ForegroundColor White
    Write-Host "  [2] public compile  - Analisis ukuran hasil build ($DistFolder/) di sandbox temp" -ForegroundColor White
    Write-Host "  [3] both            - Analisis keduanya ($SrcFolder/ vs $DistFolder/) side-by-side" -ForegroundColor White
    Write-Host "  [q] Keluar" -ForegroundColor Gray
    Write-Host ""

    while ($true) {
        Write-Host "Pilih mode (1/2/3/q) [Default: 3]: " -ForegroundColor Yellow -NoNewline
        $ans = Read-Host
        if ([string]::IsNullOrWhiteSpace($ans)) { return "both" }
        $ans = $ans.Trim().ToLower()
        if ($ans -in @("1", "src", "size src")) { return "src" }
        if ($ans -in @("2", "pub", "public", "compile", "public compile")) { return "public" }
        if ($ans -in @("3", "both", "semua")) { return "both" }
        if ($ans -in @("q", "quit", "exit")) { return "quit" }
        Write-Host "Pilihan tidak valid. Silakan masukkan 1, 2, 3, atau q." -ForegroundColor Red
    }
}

# -- View: Commit Menu List ----------------------------------------------------
function Show-CommitMenu {
    param($commits, [string]$ActiveMode)

    $modeTitle = switch ($ActiveMode) {
        "src"    { "SIZE SRC ($SrcFolder/)" }
        "public" { "PUBLIC COMPILE ($DistFolder/)" }
        "both"   { "BOTH (SRC & PUBLIC COMPILE)" }
    }

    Write-Host "`nDAFTAR COMMIT REPOSITORI (25 Terakhir) | MODE: $modeTitle" -ForegroundColor Cyan
    Write-Host ("-" * 72) -ForegroundColor DarkGray

    foreach ($c in $commits) {
        $msg = $c.Message
        if ($msg.Length -gt 45) { $msg = $msg.Substring(0, 42) + "..." }

        if ($c.Index -eq 0) {
            Write-Host ("  [{0,2}] {1,-9} | {2,-16} | {3}" -f $c.Index, $c.ShortHash, $c.Date, $msg) -ForegroundColor Green
        } elseif ($c.Index -eq 1) {
            Write-Host ("  [{0,2}] {1,-9} | {2,-16} | (HEAD) {3}" -f $c.Index, $c.ShortHash, $c.Date, $msg) -ForegroundColor Yellow
        } else {
            Write-Host ("  [{0,2}] {1,-9} | {2,-16} | {3}" -f $c.Index, $c.ShortHash, $c.Date, $msg) -ForegroundColor Gray
        }
    }
    Write-Host ("-" * 72) -ForegroundColor DarkGray
    Write-Host "Format input: " -ForegroundColor DarkCyan -NoNewline
    Write-Host "1,2,3,4,5" -ForegroundColor Yellow -NoNewline
    Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
    Write-Host "2vs23" -ForegroundColor Yellow -NoNewline
    Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
    Write-Host "0 vs 1" -ForegroundColor Yellow -NoNewline
    Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
    Write-Host "1-5" -ForegroundColor Yellow -NoNewline
    Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
    Write-Host "m (ganti mode)" -ForegroundColor Cyan
}

# -- View: Render Comparison Report --------------------------------------------
function Show-ComparisonReport {
    param(
        $commits,
        [int[]]$selectedIndices,
        [string]$ActiveMode
    )

    if ($selectedIndices.Count -eq 0) {
        Write-Host "Tidak ada indeks commit valid yang dipilih." -ForegroundColor Red
        return
    }

    Write-Host "`nMEMPROSES DATA UKURAN COMMIT TERPILIH..." -ForegroundColor Cyan

    $selectedCommits = @()
    foreach ($idx in $selectedIndices) {
        $c = $commits | Where-Object { $_.Index -eq $idx }
        if ($c) {
            Measure-CommitSize -CommitObj $c -TargetMode $ActiveMode
            $selectedCommits += $c
        }
    }

    # 1. TABEL UTAMA SESUAI MODE
    if ($ActiveMode -eq "src") {
        # MODE 1: SIZE SRC
        Write-Host "`nTABEL UKURAN SOURCE CODE ($SrcFolder/):" -ForegroundColor Yellow
        Write-Host ("=" * 86) -ForegroundColor Cyan
        Write-Host ("{0,-6} | {1,-9} | {2,-16} | {3,6} | {4,10} | {5,12} | {6}" -f "INDEX", "HASH", "TANGGAL", "FILES", "SRC SIZE", "DELTA SRC", "PESAN COMMIT") -ForegroundColor White
        Write-Host ("=" * 86) -ForegroundColor Cyan

        for ($i = 0; $i -lt $selectedCommits.Count; $i++) {
            $curr = $selectedCommits[$i]
            $deltaStr = "-"
            if ($i -lt ($selectedCommits.Count - 1)) {
                $next = $selectedCommits[$i + 1]
                $deltaStr = Format-DeltaSize -DeltaBytes ($curr.SrcBytes - $next.SrcBytes)
            }
            $sizeStr = Format-ByteSize -Bytes $curr.SrcBytes
            $msgSnippet = if ($curr.Message.Length -gt 24) { $curr.Message.Substring(0, 21) + "..." } else { $curr.Message }
            $rowColor = if ($curr.Index -eq 0) { "Green" } elseif ($curr.Index -eq 1) { "Yellow" } else { "White" }

            Write-Host ("[{0,2}]   | {1,-9} | {2,-16} | {3,6} | {4,10} | {5,12} | {6}" -f $curr.Index, $curr.ShortHash, $curr.Date, $curr.SrcFiles, $sizeStr, $deltaStr, $msgSnippet) -ForegroundColor $rowColor
        }
        Write-Host ("=" * 86) -ForegroundColor Cyan

    } elseif ($ActiveMode -eq "public") {
        # MODE 2: PUBLIC COMPILE
        Write-Host "`nTABEL UKURAN HASIL KOMPILASI ($DistFolder/):" -ForegroundColor Yellow
        Write-Host ("=" * 88) -ForegroundColor Cyan
        Write-Host ("{0,-6} | {1,-9} | {2,-16} | {3,6} | {4,12} | {5,12} | {6}" -f "INDEX", "HASH", "TANGGAL", "FILES", "COMPILED PUB", "DELTA PUB", "PESAN COMMIT") -ForegroundColor White
        Write-Host ("=" * 88) -ForegroundColor Cyan

        for ($i = 0; $i -lt $selectedCommits.Count; $i++) {
            $curr = $selectedCommits[$i]
            $deltaStr = "-"
            if ($i -lt ($selectedCommits.Count - 1)) {
                $next = $selectedCommits[$i + 1]
                $deltaStr = Format-DeltaSize -DeltaBytes ($curr.PubBytes - $next.PubBytes)
            }
            $sizeStr = Format-ByteSize -Bytes $curr.PubBytes
            $msgSnippet = if ($curr.Message.Length -gt 24) { $curr.Message.Substring(0, 21) + "..." } else { $curr.Message }
            $rowColor = if ($curr.Index -eq 0) { "Green" } elseif ($curr.Index -eq 1) { "Yellow" } else { "White" }

            Write-Host ("[{0,2}]   | {1,-9} | {2,-16} | {3,6} | {4,12} | {5,12} | {6}" -f $curr.Index, $curr.ShortHash, $curr.Date, $curr.PubFiles, $sizeStr, $deltaStr, $msgSnippet) -ForegroundColor $rowColor
        }
        Write-Host ("=" * 88) -ForegroundColor Cyan

    } else {
        # MODE 3: BOTH (SRC & PUBLIC SIDE-BY-SIDE)
        Write-Host "`nTABEL KOMPARASI KOMPREHENSIF (SRC vs COMPILED PUBLIC):" -ForegroundColor Yellow
        Write-Host ("=" * 96) -ForegroundColor Cyan
        Write-Host ("{0,-6} | {1,-9} | {2,10} | {3,12} | {4,9} | {5,12} | {6}" -f "INDEX", "HASH", "SRC SIZE", "COMPILED PUB", "SUSUT %", "DELTA PUB", "PESAN COMMIT") -ForegroundColor White
        Write-Host ("=" * 96) -ForegroundColor Cyan

        for ($i = 0; $i -lt $selectedCommits.Count; $i++) {
            $curr = $selectedCommits[$i]
            $deltaStr = "-"
            if ($i -lt ($selectedCommits.Count - 1)) {
                $next = $selectedCommits[$i + 1]
                $deltaStr = Format-DeltaSize -DeltaBytes ($curr.PubBytes - $next.PubBytes)
            }
            $srcStr = Format-ByteSize -Bytes $curr.SrcBytes
            $pubStr = Format-ByteSize -Bytes $curr.PubBytes
            $pctSusut = if ($curr.SrcBytes -gt 0) { [math]::Round((1 - ($curr.PubBytes / $curr.SrcBytes)) * 100, 1) } else { 0 }
            $susutStr = "$pctSusut%"
            $msgSnippet = if ($curr.Message.Length -gt 26) { $curr.Message.Substring(0, 23) + "..." } else { $curr.Message }
            $rowColor = if ($curr.Index -eq 0) { "Green" } elseif ($curr.Index -eq 1) { "Yellow" } else { "White" }

            Write-Host ("[{0,2}]   | {1,-9} | {2,10} | {3,12} | {4,9} | {5,12} | {6}" -f $curr.Index, $curr.ShortHash, $srcStr, $pubStr, $susutStr, $deltaStr, $msgSnippet) -ForegroundColor $rowColor
        }
        Write-Host ("=" * 96) -ForegroundColor Cyan
    }

    # 2. DETAIL HEAD-TO-HEAD (Jika dipilih 2 commit)
    if ($selectedCommits.Count -eq 2) {
        $cA = $selectedCommits[0]
        $cB = $selectedCommits[1]

        Write-Host "`nHEAD-TO-HEAD DETAIL: [$($cA.Index)] $($cA.ShortHash) VS [$($cB.Index)] $($cB.ShortHash)" -ForegroundColor Yellow
        Write-Host ("-" * 72) -ForegroundColor DarkGray

        if ($ActiveMode -in @("src", "both")) {
            $deltaSrc = $cA.SrcBytes - $cB.SrcBytes
            $pctSrc = if ($cB.SrcBytes -gt 0) { [math]::Round(($deltaSrc / $cB.SrcBytes) * 100, 2) } else { 0 }
            $signSrc = if ($deltaSrc -ge 0) { "+" } else { "" }
            $colSrc = if ($deltaSrc -gt 0) { "Green" } elseif ($deltaSrc -lt 0) { "Red" } else { "Yellow" }
            Write-Host "  * Ukuran Source ($SrcFolder/)     : $(Format-ByteSize $cB.SrcBytes) -> $(Format-ByteSize $cA.SrcBytes) " -NoNewline
            Write-Host "($signSrc$(Format-ByteSize ([math]::Abs($deltaSrc))) / $signSrc$pctSrc%)" -ForegroundColor $colSrc
        }

        if ($ActiveMode -in @("public", "both")) {
            $deltaPub = $cA.PubBytes - $cB.PubBytes
            $pctPub = if ($cB.PubBytes -gt 0) { [math]::Round(($deltaPub / $cB.PubBytes) * 100, 2) } else { 0 }
            $signPub = if ($deltaPub -ge 0) { "+" } else { "" }
            $colPub = if ($deltaPub -gt 0) { "Green" } elseif ($deltaPub -lt 0) { "Red" } else { "Yellow" }
            Write-Host "  * Ukuran Compiled ($DistFolder/)  : $(Format-ByteSize $cB.PubBytes) -> $(Format-ByteSize $cA.PubBytes) " -NoNewline
            Write-Host "($signPub$(Format-ByteSize ([math]::Abs($deltaPub))) / $signPub$pctPub%)" -ForegroundColor $colPub
        }

        # Git diff --stat
        Write-Host "`n  STATISTIK PERUBAHAN BERKAS (GIT DIFF --STAT):" -ForegroundColor Cyan
        $diffTargetA = if ($cA.IsLive) { "" } else { $cA.Hash }
        $diffTargetB = if ($cB.IsLive) { "" } else { $cB.Hash }

        if ($cB.IsLive -and $cA.IsLive) {
            Write-Host "    (Perbandingan working directory dengan dirinya sendiri: 0 perbedaan)" -ForegroundColor DarkGray
        } elseif ($cA.IsLive) {
            $statOutput = git diff --stat $diffTargetB
            if ($statOutput) {
                $statOutput | Select-Object -First 12 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkCyan }
                if ($statOutput.Count -gt 12) { Write-Host "    ... (dan $($statOutput.Count - 12) berkas lainnya)" -ForegroundColor DarkGray }
            } else { Write-Host "    (Tidak ada perbedaan berkas terdeteksi)" -ForegroundColor DarkGray }
        } elseif ($cB.IsLive) {
            $statOutput = git diff --stat $diffTargetA
            if ($statOutput) {
                $statOutput | Select-Object -First 12 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkCyan }
                if ($statOutput.Count -gt 12) { Write-Host "    ... (dan $($statOutput.Count - 12) berkas lainnya)" -ForegroundColor DarkGray }
            } else { Write-Host "    (Tidak ada perbedaan berkas terdeteksi)" -ForegroundColor DarkGray }
        } else {
            $statOutput = git diff --stat $diffTargetB $diffTargetA
            if ($statOutput) {
                $statOutput | Select-Object -First 12 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkCyan }
                if ($statOutput.Count -gt 12) { Write-Host "    ... (dan $($statOutput.Count - 12) berkas lainnya)" -ForegroundColor DarkGray }
            } else { Write-Host "    (Tidak ada perbedaan berkas terdeteksi)" -ForegroundColor DarkGray }
        }
    }
}

# -- Execution Flow ------------------------------------------------------------
$commitHistory = Get-GitCommitList -MaxCount 30
$maxAvailableIndex = $commitHistory.Count - 1

# 1. Tentukan Mode
$currentMode = $Mode.ToLower()
if ($currentMode -in @("1", "src", "size src")) { $currentMode = "src" }
elseif ($currentMode -in @("2", "pub", "public", "compile", "public compile")) { $currentMode = "public" }
elseif ($currentMode -in @("3", "both", "semua")) { $currentMode = "both" }
else { $currentMode = "" }

# Mode Non-Interaktif jika parameter diberikan
if (-not [string]::IsNullOrWhiteSpace($Compare)) {
    if ([string]::IsNullOrWhiteSpace($currentMode)) { $currentMode = "both" }
    Show-Banner
    $parsed = Parse-CommitInput -inputStr $Compare -maxIndex $maxAvailableIndex
    Show-ComparisonReport -commits $commitHistory -selectedIndices $parsed -ActiveMode $currentMode
    exit 0
}

# Mode Interaktif
Clear-Host
Show-Banner

if ([string]::IsNullOrWhiteSpace($currentMode)) {
    $currentMode = Prompt-ModeMenu
    if ($currentMode -eq "quit") {
        Write-Host "Dibatalkan oleh user.`n" -ForegroundColor DarkGray
        exit 0
    }
}

while ($true) {
    Show-CommitMenu -commits $commitHistory -ActiveMode $currentMode

    Write-Host "`nMasukkan pilihan perbandingan " -NoNewline -ForegroundColor Cyan
    Write-Host "(contoh: " -NoNewline -ForegroundColor DarkGray
    Write-Host "0 vs 1" -ForegroundColor Yellow -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "1,2,3,4,5" -ForegroundColor Yellow -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "2vs23" -ForegroundColor Yellow -NoNewline
    Write-Host " | " -ForegroundColor DarkGray -NoNewline
    Write-Host "m" -ForegroundColor Cyan -NoNewline
    Write-Host " ganti mode | " -ForegroundColor DarkGray -NoNewline
    Write-Host "q" -ForegroundColor Red -NoNewline
    Write-Host " keluar): " -ForegroundColor DarkGray -NoNewline

    $userInput = Read-Host

    if ([string]::IsNullOrWhiteSpace($userInput)) { continue }

    $trimmed = $userInput.Trim()
    if ($trimmed -in @("q", "quit", "exit", "keluar")) {
        Write-Host "`nSelesai. Terima kasih!`n" -ForegroundColor Cyan
        break
    }

    if ($trimmed -in @("m", "mode", "menu")) {
        $newMode = Prompt-ModeMenu
        if ($newMode -ne "quit") { $currentMode = $newMode }
        Clear-Host
        Show-Banner
        continue
    }

    $parsedIndices = Parse-CommitInput -inputStr $userInput -maxIndex $maxAvailableIndex

    if ($parsedIndices.Count -gt 0) {
        Show-ComparisonReport -commits $commitHistory -selectedIndices $parsedIndices -ActiveMode $currentMode
        Write-Host "`nTekan ENTER untuk input lain, atau 'm' untuk ganti mode... " -ForegroundColor DarkGray -NoNewline
        $nextAction = Read-Host
        if ($nextAction.Trim() -in @("m", "mode")) {
            $newMode = Prompt-ModeMenu
            if ($newMode -ne "quit") { $currentMode = $newMode }
        }
        Clear-Host
        Show-Banner
    } else {
        Write-Host "`nFormat input tidak valid. Silakan coba lagi (contoh: '0 vs 1' atau '1,2,3')." -ForegroundColor Red
    }
}
