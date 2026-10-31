<#
.SYNOPSIS
    Modular Vintage Theme & SCSS Compiler (v2.0.0)
.DESCRIPTION
    Compiles SCSS stylesheets (theme.scss, winget.scss) from src/reference-theme/
    into production-ready CSS for both src/ and public/ (style.css, winget.css).
    Supports Dart Sass, NPX Sass, Python LibSass, native CSS fallback, and live Watch mode.
#>

[CmdletBinding()]
param (
    [ValidateSet("all", "theme", "winget", "sync")]
    [string]$Target = "all",

    [string]$SourcePath = "src/theme",
    [string]$OutputPath = "public",

    [switch]$Watch,
    [switch]$Minify,
    [string]$VaultPath = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path

# Resolve custom source directory (defaults to src/theme, fallback to src/reference-theme)
$sourceDir = if ([System.IO.Path]::IsPathRooted($SourcePath)) {
    $SourcePath
} elseif (Test-Path (Join-Path $repoRoot $SourcePath)) {
    Join-Path $repoRoot $SourcePath
} elseif (Test-Path (Join-Path $repoRoot "src/reference-theme")) {
    Join-Path $repoRoot "src/reference-theme"
} else {
    Join-Path $repoRoot $SourcePath
}

# Resolve custom output directory (defaults to public)
$publicDir = if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath
} else {
    Join-Path $repoRoot $OutputPath
}

$themeScss  = Join-Path $sourceDir "theme.scss"
$themeCss   = Join-Path $sourceDir "theme.css"
$publicCss  = Join-Path $publicDir "style.css"

$wingetScss = Join-Path $sourceDir "winget.scss"
$publicWingetCss = Join-Path $publicDir "winget.css"

Write-Host "==========================================================================" -ForegroundColor Yellow
Write-Host "  🕹️ VINTAGE COMPUTING ARCADE — MODULAR THEME COMPILER                    " -ForegroundColor Yellow
Write-Host "==========================================================================" -ForegroundColor Yellow
Write-Host "Repository Root : $repoRoot" -ForegroundColor DarkGray
Write-Host "Source Dir      : $sourceDir" -ForegroundColor DarkGray
Write-Host "Target Target   : $Target | Minify: $Minify | Watch: $Watch" -ForegroundColor DarkGray
Write-Host ""

# ------------------------------------------------------------------------------
# 1. AUTO-DETECT SASS COMPILER ENGINE
# ------------------------------------------------------------------------------
$compilerType = $null
$compilerCmd  = $null

if (Get-Command sass -ErrorAction SilentlyContinue) {
    $compilerType = "Dart Sass (Global CLI)"
    $compilerCmd  = {
        param($src, $dst, $isMin)
        $styleFlag = if ($isMin) { "--style=compressed" } else { "--style=expanded" }
        & sass "$src" "$dst" $styleFlag --no-source-map
    }
} elseif (Get-Command npx -ErrorAction SilentlyContinue) {
    $compilerType = "NPX Dart Sass (Node.js)"
    $compilerCmd  = {
        param($src, $dst, $isMin)
        $styleFlag = if ($isMin) { "--style=compressed" } else { "--style=expanded" }
        & npx --yes sass "$src" "$dst" $styleFlag --no-source-map
    }
} elseif (Get-Command python -ErrorAction SilentlyContinue) {
    $hasLibSass = & python -c "import sass; print('OK')" 2>$null
    if ($hasLibSass -match "OK") {
        $compilerType = "Python LibSass Engine"
        $compilerCmd  = {
            param($src, $dst, $isMin)
            $outputStyle = if ($isMin) { "compressed" } else { "expanded" }
            $pyCode = "import sass; open(r'$dst', 'w', encoding='utf-8').write(sass.compile(filename=r'$src', output_style='$outputStyle'))"
            & python -c "$pyCode"
        }
    }
}

if (-not $compilerCmd) {
    Write-Host "[!] No Sass compiler found on PATH (sass, npx, or python-libsass)." -ForegroundColor Yellow
    Write-Host "[*] Fallback: Using direct native CSS copy..." -ForegroundColor Magenta
    $compilerType = "Native CSS Copy (Fallback)"
    $compilerCmd  = {
        param($src, $dst, $isMin)
        Copy-Item -Path $src -Destination $dst -Force
    }
}

Write-Host "✔ Active Compiler: $compilerType" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# 2. MODULAR COMPILATION FUNCTIONS
# ------------------------------------------------------------------------------
function Compile-File ($src, $dst, $label) {
    if (-not (Test-Path $src)) {
        Write-Host "[-] Skipping $label: Source file not found ($src)" -ForegroundColor DarkGray
        return $false
    }

    $parentDir = Split-Path -Parent $dst
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        & $compilerCmd $src $dst $Minify
        $sw.Stop()

        $fileSize = (Get-Item $dst).Length
        $sizeKb = [math]::Round($fileSize / 1024, 2)
        Write-Host "  ✔ $label -> $(Split-Path $dst -Leaf) ($sizeKb KB in $($sw.ElapsedMilliseconds)ms)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ❌ Failed compiling $label: $_" -ForegroundColor Red
        return $false
    }
}

function Invoke-ModularBuild {
    Write-Host "[*] Starting compilation run at $(Get-Date -Format 'HH:mm:ss')..." -ForegroundColor Cyan

    # 1. Compile Main Theme
    if ($Target -in @("all", "theme", "sync")) {
        Compile-File $themeScss $themeCss "Master Theme (src)"
        # Also sync to public/style.css
        if (Test-Path $themeCss) {
            Copy-Item -Path $themeCss -Destination $publicCss -Force
            Write-Host "  ✔ Synced -> public/style.css" -ForegroundColor Green
        }
    }

    # 2. Compile Winget Stylesheet
    if ($Target -in @("all", "winget")) {
        if (Test-Path $wingetScss) {
            Compile-File $wingetScss $publicWingetCss "Widget Styles (public/winget.css)"
        }
    }

    # 3. Optional Obsidian Vault Sync
    if ($Target -eq "sync" -or $VaultPath) {
        Sync-ObsidianVault
    }

    Write-Host "[✔] Compilation batch completed.`n" -ForegroundColor Green
}

function Sync-ObsidianVault {
    $target = $VaultPath
    $vaultConfigFile = Join-Path $sourceDir "vault_path.txt"

    if (-not $target -and (Test-Path $vaultConfigFile)) {
        $target = (Get-Content $vaultConfigFile -Raw).Trim()
    }

    if ($target -and (Test-Path $target)) {
        $dest = Join-Path $target "theme.css"
        Copy-Item -Path $themeCss -Destination $dest -Force
        Write-Host "  ✔ Synced to Obsidian Vault: $dest" -ForegroundColor Magenta
    }
}

# ------------------------------------------------------------------------------
# 3. EXECUTION DISPATCHER
# ------------------------------------------------------------------------------
if ($Watch) {
    Write-Host "[*] Entering Live Watch Mode on: $sourceDir" -ForegroundColor Yellow
    Write-Host "    Press Ctrl+C to terminate watch mode." -ForegroundColor DarkGray
    Invoke-ModularBuild

    $watcher = [System.IO.FileSystemWatcher]::new($sourceDir)
    $watcher.Filter = "*.scss"
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    $action = {
        Write-Host "`n[*] File change detected. Recompiling..." -ForegroundColor Yellow
        Invoke-ModularBuild
    }

    Register-ObjectEvent $watcher "Changed" -Action $action | Out-Null

    try {
        while ($true) {
            Start-Sleep -Seconds 1
        }
    } finally {
        Unregister-Event -SourceIdentifier $watcher.ToString() -ErrorAction SilentlyContinue
        $watcher.Dispose()
    }
} else {
    Invoke-ModularBuild
}
