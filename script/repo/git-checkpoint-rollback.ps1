<#
.SYNOPSIS
    Interactive Checkpoint Rollback and Safe Reset (Keep Local Work).
.DESCRIPTION
    Rolls back local git history to a chosen commit checkpoint using git reset --soft.
    Guarantees 100% of your working code is kept safe in the Git Staging Area (index).
    Features interactive target repository detection, numbered checkpoint selector,
    pre-flight Briefed Overview confirmation, and optional remote force-push with lease.
    Modular edition backed by adapter/git-rollback.psm1.
.PARAMETER TargetDir
    Path to the target Git repository folder (default: asks interactively or uses _run.json/current repo).
.PARAMETER TargetCommit
    Target commit index (e.g. 1-10) or specific commit hash.
.PARAMETER ForcePush
    Automatically force-pushes with lease to the remote branch.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$TargetCommit = "",

    [Parameter()]
    [switch]$ForcePush
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot
$adapterDir = Join-Path $scriptDir "adapter"

# ------------------------------------------------------------------------------
# 1. LOAD MODULAR ADAPTERS
# ------------------------------------------------------------------------------
if (-not (Test-Path -LiteralPath $adapterDir)) {
    Write-Error "[ERROR] Adapter directory not found: $adapterDir"
    exit 1
}

Import-Module (Join-Path $adapterDir "git-rollback.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $adapterDir "git-status.psm1") -Force -DisableNameChecking

# ------------------------------------------------------------------------------
# 2. RUN.JSON & PATH HELPERS
# ------------------------------------------------------------------------------
function Get-RunJsonPath {
    $candidates = @(
        (Join-Path $scriptDir "..\..\_run.json"),
        (Join-Path $scriptDir "..\..\..\_run.json")
    )
    foreach ($cand in $candidates) {
        if (Test-Path -LiteralPath $cand) {
            return (Resolve-Path $cand).Path
        }
    }
    return ""
}

function Update-RunJsonTarget ([string]$newTarget) {
    $jsonPath = Get-RunJsonPath
    if ($jsonPath -and (Test-Path -LiteralPath $jsonPath)) {
        try {
            $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
            $data = $raw | ConvertFrom-Json
            $data | Add-Member -MemberType NoteProperty -Name "targetDir" -Value $newTarget -Force
            $json = $data | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText($jsonPath, $json, [System.Text.Encoding]::UTF8)
        } catch { }
    }
}

function Normalize-TargetRepoPath ([string]$rawPath, [string]$baseDir) {
    if ([string]::IsNullOrWhiteSpace($rawPath)) { return "" }
    $clean = $rawPath.Trim().Trim('"').Trim("'")
    if ([System.IO.Path]::IsPathRooted($clean)) {
        if (Test-Path -LiteralPath $clean) {
            return (Resolve-Path -LiteralPath $clean).Path
        }
        return $clean
    } else {
        $resolved = Join-Path $baseDir $clean
        if (Test-Path -LiteralPath $resolved) {
            return (Resolve-Path -LiteralPath $resolved).Path
        }
        return $resolved
    }
}

# ------------------------------------------------------------------------------
# 3. RESOLVE TARGET REPOSITORY
# ------------------------------------------------------------------------------
$activeTarget = ""
if (-not [string]::IsNullOrWhiteSpace($TargetDir)) {
    $activeTarget = Normalize-TargetRepoPath $TargetDir (Get-Location).Path
} else {
    $savedPath = ""
    $jsonPath = Get-RunJsonPath
    if ($jsonPath) {
        try {
            $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
            $parsed = $raw | ConvertFrom-Json
            if ($parsed.targetDir) { $savedPath = $parsed.targetDir }
        } catch { }
    }

    $candidate = if ($savedPath -and (Test-Path -LiteralPath $savedPath) -and (Test-IsGitRepo $savedPath)) {
        $savedPath
    } elseif (Test-IsGitRepo (Get-Location).Path) {
        (Get-Location).Path
    } else {
        ""
    }

    $promptDefault = if ($candidate) { " [Default: $candidate]" } else { "" }
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   GIT CHECKPOINT ROLLBACK (SOFT RESET - KEEP LOCAL WORK) " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    $inputDir = Read-Host "TARGET REPO DIRECTORY$promptDefault"

    if ([string]::IsNullOrWhiteSpace($inputDir)) {
        $activeTarget = $candidate
    } else {
        $activeTarget = Normalize-TargetRepoPath $inputDir (Get-Location).Path
    }
}

if ([string]::IsNullOrWhiteSpace($activeTarget) -or -not (Test-Path -LiteralPath $activeTarget)) {
    Write-Host "`n[ERROR] Path direktori target tidak ditemukan: '$activeTarget'`n" -ForegroundColor Red
    exit 1
}

if (-not (Test-IsGitRepo $activeTarget)) {
    Write-Host "`n[ERROR] Folder '$activeTarget' bukan repositori Git yang valid (tidak ada .git)!`n" -ForegroundColor Red
    exit 1
}

Update-RunJsonTarget $activeTarget

# ------------------------------------------------------------------------------
# 4. INSPECT RECENT COMMITS & SELECT TARGET CHECKPOINT
# ------------------------------------------------------------------------------
Push-Location -LiteralPath $activeTarget
try {
    $branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    $checkpoints = Get-GitCommitCheckpoints -repoPath $activeTarget -count 10

    if (-not $checkpoints -or $checkpoints.Count -eq 0) {
        Write-Host "`n[ERROR] Tidak ada commit di repository ini.`n" -ForegroundColor Red
        exit 1
    }

    Write-Host "`n Target Repo : $activeTarget" -ForegroundColor Green
    Write-Host " Branch Aktif: $branch" -ForegroundColor Cyan
    Write-Host "`nDaftar Commit Terakhir (Pilih nomor untuk rollback):" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------------------------" -ForegroundColor DarkGray

    $commitMap = @{}
    foreach ($c in $checkpoints) {
        $commitMap["$($c.Index)"] = $c.FullHash
        $commitMap[$c.ShortHash]  = $c.FullHash
        $commitMap[$c.FullHash]   = $c.FullHash

        $idxTag = " [$($c.Index)]".PadRight(6)
        $hashTag = "$($c.ShortHash)".PadRight(9)

        if ($c.IsHead) {
            Write-Host $idxTag -NoNewline -ForegroundColor White
            Write-Host $hashTag -NoNewline -ForegroundColor Red
            Write-Host "- `"$($c.Subject)`" " -NoNewline -ForegroundColor White
            Write-Host "(HEAD Saat Ini)" -ForegroundColor Yellow
        } else {
            Write-Host $idxTag -NoNewline -ForegroundColor White
            Write-Host $hashTag -NoNewline -ForegroundColor Green
            Write-Host "- `"$($c.Subject)`" " -NoNewline -ForegroundColor White
            Write-Host "($($c.Time))" -ForegroundColor Cyan
        }
    }
    Write-Host "------------------------------------------------------------------------------`n" -ForegroundColor DarkGray

    # Input target commit
    $userChoice = $TargetCommit
    if ([string]::IsNullOrWhiteSpace($userChoice)) {
        Write-Host "Pilih nomor commit target (misal: 2 untuk mundur ke 1 commit sebelum ini)" -ForegroundColor Magenta
        Write-Host "atau ketik hash commit target (atau 'q' untuk batal):" -ForegroundColor Magenta
        $userChoice = Read-Host "TARGET COMMIT [1-$($checkpoints.Count) atau Hash]"
    }

    $userChoice = if ($userChoice) { $userChoice.Trim().Trim('"').Trim("'") } else { "" }
    if ([string]::IsNullOrWhiteSpace($userChoice) -or $userChoice.ToLower() -eq 'q') {
        Write-Host "`n[BATAL] Operasi rollback dibatalkan.`n" -ForegroundColor DarkGray
        exit 0
    }

    # Resolve target hash
    $resolvedTarget = ""
    if ($commitMap.ContainsKey($userChoice)) {
        $resolvedTarget = $commitMap[$userChoice]
    } else {
        $resolvedTarget = $userChoice
    }

    $info = Resolve-GitCheckpointHash -repoPath $activeTarget -inputCommit $resolvedTarget
    if (-not $info) {
        Write-Host "`n[ERROR] Commit '$resolvedTarget' tidak valid atau tidak ditemukan!`n" -ForegroundColor Red
        exit 1
    }

    if ($info.DiffCount -eq 0) {
        Write-Host "`n[WARNING] Posisi repo sudah berada di commit tersebut ($($info.ShortHash)). Tidak ada yang perlu dimundurkan.`n" -ForegroundColor Yellow
        exit 0
    }

    # --------------------------------------------------------------------------
    # 5. PRE-FLIGHT BRIEFED OVERVIEW & EXPLICIT CONFIRMATION
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   GIT CHECKPOINT ROLLBACK PRE-FLIGHT OVERVIEW            " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Target Repo      : $activeTarget" -ForegroundColor White
    Write-Host " Branch Aktif     : $branch" -ForegroundColor White
    Write-Host " Mundur ke Commit : $($info.ShortHash) (`"$($info.Subject)`")" -ForegroundColor Green
    Write-Host " Commit Dicopot   : $($info.DiffCount) commit terbaru dari history" -ForegroundColor Red
    Write-Host " Kodingan Lokal   : 100% AMAN (masuk ke Staging Area via reset --soft)" -ForegroundColor Green
    Write-Host " Perintah Git     : git reset --soft $($info.ShortHash)" -ForegroundColor DarkGray
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""

    $confirmStep = Read-Host "Lanjutkan proses mundur ini? (y/N)"
    if ($confirmStep -notmatch '^[Yy](es)?$') {
        Write-Host "`n[BATAL] Proses rollback dibatalkan oleh user.`n" -ForegroundColor DarkGray
        exit 0
    }

    # --------------------------------------------------------------------------
    # 6. EXECUTE SOFT ROLLBACK (Code 100% Preserved in Staging Area)
    # --------------------------------------------------------------------------
    Write-Host "`n[*] Menjalankan safe rollback..." -ForegroundColor Cyan
    $rbRes = Invoke-GitSoftRollback -repoPath $activeTarget -targetFullHash $info.FullHash

    if (-not $rbRes.Success) {
        Write-Host "`n[ERROR] Gagal menjalankan soft rollback: $($rbRes.Output)" -ForegroundColor Red
        exit 1
    }

    Write-Host "[OK] LOKAL SELESAI: History lokal berhasil dimundurkan ke $($info.ShortHash)." -ForegroundColor Green
    Write-Host "     Semua file kodingan tetap aman di Staging Area (index).`n" -ForegroundColor White

    # --------------------------------------------------------------------------
    # 7. OPTIONAL REMOTE SYNCHRONIZATION (--force-with-lease)
    # --------------------------------------------------------------------------
    $confirmPush = $ForcePush
    if (-not $confirmPush) {
        Write-Host "Apakah Anda ingin remote (origin/$branch) juga diselaraskan ke checkpoint ini?" -ForegroundColor Magenta
        $pushAns = Read-Host "Force-push ke origin/$branch sekarang? (y/N) [Default: N]"
        if ($pushAns -match '^[Yy](es)?$') {
            $confirmPush = $true
        }
    }

    if ($confirmPush) {
        Write-Host "`n[*] Mengupdate remote origin/$branch dengan --force-with-lease..." -ForegroundColor Cyan
        $pushRes = Invoke-GitForcePushWithLease -repoPath $activeTarget -branch $branch -remote "origin"

        if ($pushRes.Success) {
            Write-Host "[SEMPURNA] Remote GitHub dan Lokal sudah sama-sama berada di save-an target." -ForegroundColor Green
            Write-Host "           Perubahan kodingan Anda siap dicek dengan 'git status'.`n" -ForegroundColor White
        } else {
            Write-Host "[ERROR] Gagal push ke remote: $($pushRes.Output)" -ForegroundColor Red
            Write-Host "        Pastikan koneksi aman dan tidak ada conflict tak terduga.`n" -ForegroundColor Yellow
        }
    } else {
        Write-Host "[INFO] Remote belum diupdate. Untuk update manual nanti, jalankan:" -ForegroundColor Yellow
        Write-Host "       git push --force-with-lease origin $branch`n" -ForegroundColor Cyan
    }
}
finally {
    Pop-Location
}
