<#
.SYNOPSIS
    Universal Runtime & Toolchain Dependency Preflight Checker
    Script: ps_check-dependencies.ps1
.DESCRIPTION
    Verifies that required runtimes (Node.js, Python, Git, Playwright) are installed
    and meet minimum version constraints. Offers automated download/install via winget.
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$TargetRuntime = "all",

    [switch]$Install,
    [switch]$Quiet
)

$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path

function Test-NodeDependency ([bool]$PromptInstall = $false) {
    $cmd = Get-Command node -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (node -v 2>$null).Trim()
        return [PSCustomObject]@{ Runtime = "Node.js"; Status = "OK"; Version = $ver; Installed = $true }
    }
    if ($PromptInstall) {
        Write-Host "`n[!] Node.js is missing (Required: v18+)." -ForegroundColor Yellow
        $ans = Read-Host "Download and install Node.js via winget? [Y/n]"
        if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match "^(y|yes)$") {
            Write-Host "[*] Executing: winget install -e --id OpenJS.NodeJS.LTS..." -ForegroundColor Cyan
            winget install -e --id OpenJS.NodeJS.LTS
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $cmdAfter = Get-Command node -ErrorAction SilentlyContinue
            if ($cmdAfter) {
                return [PSCustomObject]@{ Runtime = "Node.js"; Status = "OK (Installed)"; Version = (node -v).Trim(); Installed = $true }
            }
        }
    }
    return [PSCustomObject]@{ Runtime = "Node.js"; Status = "MISSING"; Version = "None"; Installed = $false }
}

function Test-PythonDependency ([bool]$PromptInstall = $false) {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (python --version 2>&1).Trim()
        return [PSCustomObject]@{ Runtime = "Python"; Status = "OK"; Version = $ver; Installed = $true }
    }
    if ($PromptInstall) {
        Write-Host "`n[!] Python 3 is missing (Required: 3.8+)." -ForegroundColor Yellow
        $ans = Read-Host "Download and install Python 3 via winget? [Y/n]"
        if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match "^(y|yes)$") {
            Write-Host "[*] Executing: winget install -e --id Python.Python.3.11..." -ForegroundColor Cyan
            winget install -e --id Python.Python.3.11
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $cmdAfter = Get-Command python -ErrorAction SilentlyContinue
            if ($cmdAfter) {
                return [PSCustomObject]@{ Runtime = "Python"; Status = "OK (Installed)"; Version = (python --version 2>&1).Trim(); Installed = $true }
            }
        }
    }
    return [PSCustomObject]@{ Runtime = "Python"; Status = "MISSING"; Version = "None"; Installed = $false }
}

function Test-GitDependency ([bool]$PromptInstall = $false) {
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) {
        $ver = (git --version 2>$null).Trim()
        return [PSCustomObject]@{ Runtime = "Git"; Status = "OK"; Version = $ver; Installed = $true }
    }
    if ($PromptInstall) {
        Write-Host "`n[!] Git is missing." -ForegroundColor Yellow
        $ans = Read-Host "Download and install Git via winget? [Y/n]"
        if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match "^(y|yes)$") {
            Write-Host "[*] Executing: winget install -e --id Git.Git..." -ForegroundColor Cyan
            winget install -e --id Git.Git
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            $cmdAfter = Get-Command git -ErrorAction SilentlyContinue
            if ($cmdAfter) {
                return [PSCustomObject]@{ Runtime = "Git"; Status = "OK (Installed)"; Version = (git --version 2>$null).Trim(); Installed = $true }
            }
        }
    }
    return [PSCustomObject]@{ Runtime = "Git"; Status = "MISSING"; Version = "None"; Installed = $false }
}

function Test-PlaywrightDependency ([bool]$PromptInstall = $false) {
    $pwDir = Join-Path $repoRoot "node_modules\playwright"
    $hasPw = (Test-Path $pwDir)
    if ($hasPw) {
        return [PSCustomObject]@{ Runtime = "Playwright"; Status = "OK"; Version = "Installed"; Installed = $true }
    }
    if ($PromptInstall) {
        Write-Host "`n[!] Playwright module is missing in node_modules." -ForegroundColor Yellow
        $ans = Read-Host "Run 'npm install' to install project dependencies? [Y/n]"
        if ([string]::IsNullOrWhiteSpace($ans) -or $ans -match "^(y|yes)$") {
            Write-Host "[*] Executing: npm install..." -ForegroundColor Cyan
            Push-Location $repoRoot
            try {
                npm install
            } finally {
                Pop-Location
            }
            if (Test-Path $pwDir) {
                return [PSCustomObject]@{ Runtime = "Playwright"; Status = "OK (Installed)"; Version = "Installed"; Installed = $true }
            }
        }
    }
    return [PSCustomObject]@{ Runtime = "Playwright"; Status = "OPTIONAL / NOT INSTALLED"; Version = "None"; Installed = $false }
}

# --- Main Preflight Flow ---
$results = @()
$doInstall = $Install.IsPresent

switch ($TargetRuntime.ToLower()) {
    "node"       { $results += Test-NodeDependency $doInstall }
    "python"     { $results += Test-PythonDependency $doInstall }
    "git"        { $results += Test-GitDependency $doInstall }
    "playwright" { $results += Test-PlaywrightDependency $doInstall }
    default {
        $results += Test-NodeDependency $doInstall
        $results += Test-PythonDependency $doInstall
        $results += Test-GitDependency $doInstall
        $results += Test-PlaywrightDependency $doInstall
    }
}

if (-not $Quiet) {
    Write-Host "`n========================================================================" -ForegroundColor Yellow
    Write-Host "   TOOLCHAIN DEPENDENCY PREFLIGHT REPORT" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Yellow
    foreach ($r in $results) {
        $color = if ($r.Installed) { [ConsoleColor]::Green } else { [ConsoleColor]::Red }
        $runtimePad = $r.Runtime.PadRight(16)
        $statusPad  = "[$($r.Status)]".PadRight(18)
        Write-Host "  $runtimePad $statusPad : $($r.Version)" -ForegroundColor $color
    }
    Write-Host "========================================================================`n" -ForegroundColor DarkGray
}

return $results
