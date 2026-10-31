<#
.SYNOPSIS
    Standalone Compiler & Module Inliner for PowerShell.
.DESCRIPTION
    Scans a modular PowerShell script, resolves all relative Import-Module statements
    from the module/ subfolder, and inlines their function definitions directly into
    a self-contained, zero-dependency standalone script (<name>_stand.ps1).
.PARAMETER SourceFile
    Path to the modular PowerShell script to compile.
.PARAMETER OutputFile
    Optional destination path for the compiled standalone script.
.PARAMETER All
    Compiles all modular scripts in script/powershell/ to *_stand.ps1 in the same directory.
#>
[CmdletBinding()]
param(
    [string]$SourceFile = "",
    [string]$OutputFile = "",
    [switch]$All
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

function Compile-PowerShellScript {
    param (
        [string]$Path,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "[ERROR] Source file not found: $Path" -ForegroundColor Red
        return
    }

    Write-Host "[*] Compiling: $(Split-Path $Path -Leaf) -> $(Split-Path $Destination -Leaf) ..." -ForegroundColor Cyan
    $lines = Get-Content -LiteralPath $Path -Encoding UTF8
    $inlinedOutput = [System.Collections.Generic.List[string]]::new()

    $inlinedOutput.Add("# ==========================================================================")
    $inlinedOutput.Add("# COMPILED STANDALONE SCRIPT - ALL-LADS-TOOL")
    $inlinedOutput.Add("# Source: $(Split-Path $Path -Leaf) | Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    $inlinedOutput.Add("# ==========================================================================`n")

    foreach ($line in $lines) {
        # Check if line imports a module from module\*.psm1 or module\*.ps1
        if ($line -match 'Import-Module\s+["'']\$PSScriptRoot[\\/]module[\\/]([^"'']+)["''](\s+-Force)?') {
            $modName = $matches[1]
            $modPath = Join-Path $scriptDir "module\$modName"

            if (Test-Path -LiteralPath $modPath) {
                $inlinedOutput.Add("# --- [INLINED MODULE: $modName] ---")
                $modContent = Get-Content -LiteralPath $modPath -Encoding UTF8
                foreach ($mLine in $modContent) {
                    # Strip Export-ModuleMember since it's now inlined
                    if ($mLine -notmatch '^\s*Export-ModuleMember') {
                        $inlinedOutput.Add($mLine)
                    }
                }
                $inlinedOutput.Add("# --- [END INLINED MODULE: $modName] ---`n")
            } else {
                $inlinedOutput.Add($line)
            }
        } else {
            $inlinedOutput.Add($line)
        }
    }

    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    $inlinedOutput -join "`r`n" | Set-Content -LiteralPath $Destination -Encoding UTF8
    Write-Host "[OK] Standalone script generated successfully: $Destination" -ForegroundColor Green
}

if ($All) {
    Write-Host "=== BATCH COMPILING MODULAR POWERSHELL SCRIPTS TO STANDALONE ===" -ForegroundColor Yellow
    Get-ChildItem -Path $scriptDir -Filter "*.ps1" | Where-Object { 
        $_.Name -notlike "*_stand.ps1" -and $_.Name -notlike "*compiler*" 
    } | ForEach-Object {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        $dest = Join-Path $scriptDir "${base}_stand.ps1"
        Compile-PowerShellScript -Path $_.FullName -Destination $dest
    }
} elseif ($SourceFile) {
    if (-not $OutputFile) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($SourceFile)
        $ext = [System.IO.Path]::GetExtension($SourceFile)
        $cleanBase = $baseName -replace '_stand$', ''
        $OutputFile = Join-Path (Split-Path -Parent $SourceFile) "${cleanBase}_stand$ext"
    }
    Compile-PowerShellScript -Path $SourceFile -Destination $OutputFile
} else {
    Write-Host "Usage: .\standalone-compiler_stand.ps1 -SourceFile <script.ps1> [-OutputFile <out_stand.ps1>]" -ForegroundColor Yellow
    Write-Host "       .\standalone-compiler_stand.ps1 -All" -ForegroundColor Yellow
}
