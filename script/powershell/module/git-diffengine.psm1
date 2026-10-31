<#
.SYNOPSIS
    Git Commit Size & Sandbox Diff Engine Module.
.DESCRIPTION
    Headless analysis engine for comparing source tree and compile sizes across Git commits.
#>
[CmdletBinding()]
param()

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

function Get-FolderSizeKb ([string]$folderPath) {
    if (-not (Test-Path $folderPath)) { return 0 }
    $measure = Get-ChildItem -Path $folderPath -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
    if ($measure.Sum) {
        return [Math]::Round($measure.Sum / 1KB, 1)
    }
    return 0
}

function Measure-DirectoryBytes ([string]$dirPath, [string[]]$excludeExts = @(), [string[]]$excludeDirs = @()) {
    if (-not (Test-Path $dirPath)) {
        return @{ TotalBytes = 0; FileCount = 0 }
    }
    $allFiles = Get-ChildItem -Path $dirPath -Recurse -File -Force -ErrorAction SilentlyContinue
    $total = 0
    $count = 0
    foreach ($file in $allFiles) {
        $skip = $false
        foreach ($d in $excludeDirs) {
            if ($file.FullName -match "[\\/]$d([\\/]|$)") { $skip = $true; break }
        }
        if ($skip -or ($file.Extension -in $excludeExts)) { continue }
        $total += $file.Length
        $count++
    }
    return @{ TotalBytes = $total; FileCount = $count }
}

function Invoke-SandboxArchiveExtract ([string]$repoDir, [string]$commitRef, [string]$targetSandboxDir) {
    if (-not (Test-Path $targetSandboxDir)) {
        New-Item -ItemType Directory -Path $targetSandboxDir -Force | Out-Null
    }
    Push-Location $repoDir
    try {
        git archive $commitRef | tar -x -C $targetSandboxDir 2>$null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
    finally {
        Pop-Location
    }
}

Export-ModuleMember -Function Format-ByteSize, Format-DeltaSize, Get-FolderSizeKb, Measure-DirectoryBytes, Invoke-SandboxArchiveExtract
