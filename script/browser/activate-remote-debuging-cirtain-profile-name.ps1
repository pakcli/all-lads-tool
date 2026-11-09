<#
.SYNOPSIS
    Activate Browser Remote Debugging on a Certain Profile Name (Context: browser)
.DESCRIPTION
    Launches Chromium-based browsers (Chrome, Edge, Brave, or Custom) with
    remote debugging enabled on an isolated profile (default: 'ai-agent') to allow
    Antigravity and AI agents to automate browsing without touching personal sessions.
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$ProfileName = "ai-agent",

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$Browser = "Chrome",

    [Parameter(Position = 2, Mandatory = $false)]
    [int]$Port = 9222,

    [Parameter(Position = 3, Mandatory = $false)]
    [string]$Url = "https://www.google.com",

    [switch]$KillExisting,
    [switch]$Headless,
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

# Global Crash / Error Guardrail
trap {
    $errText = $_.Exception.ToString()
    Write-Host "`n[FATAL SCRIPT ERROR]" -ForegroundColor Red
    Write-Host $errText -ForegroundColor DarkRed
    try {
        Set-Content -Path "$PSScriptRoot\last-error.log" -Value $errText -Force
    } catch {}
    Write-Host "`nError logged to last-error.log" -ForegroundColor Yellow
    exit 1
}

# Import Browser Adapter
$adapterPath = Join-Path $PSScriptRoot "adapter\chrome-launcher.psm1"
Import-Module -Name $adapterPath -DisableNameChecking -Force

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   BROWSER REMOTE DEBUGGING LAUNCHER (Context: browser)  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# Interactive Browser Selection (DEFAULT = Chrome on Enter)
$resolvedBrowser = $Browser
$customExePath = $null

if (-not $Yes) {
    Write-Host "`nPilih browser yang ingin digunakan:" -ForegroundColor Yellow
    Write-Host "  [ 1 ] Chrome (Default - tekan Enter)"
    Write-Host "  [ 2 ] Edge   (Microsoft Edge)"
    Write-Host "  [ 3 ] Brave"
    Write-Host "  [ 4 ] Custom (Masukkan path browser Chromium sendiri)"

    $bChoice = Read-Host "`nPilih opsi browser [1/2/3/4] (default: 1)"
    if ([string]::IsNullOrWhiteSpace($bChoice)) { $bChoice = "1" }
    $bChoice = $bChoice.Trim()

    switch ($bChoice) {
        "1" { $resolvedBrowser = "Chrome" }
        "2" { $resolvedBrowser = "Edge" }
        "3" { $resolvedBrowser = "Brave" }
        "4" {
            $resolvedBrowser = "Custom"
            $customExePath = Read-Host "`nMasukkan path lengkap executable browser"
            while (-not (Test-Path -LiteralPath $customExePath)) {
                Write-Host "[ERROR] Path tidak ditemukan: $customExePath" -ForegroundColor Red
                $customExePath = Read-Host "Masukkan path valid atau ketik 'cancel'"
                if ($customExePath.Trim().ToLowerInvariant() -eq "cancel") {
                    Write-Host "`n[CANCELLED] Operasi dibatalkan." -ForegroundColor Yellow
                    exit 0
                }
            }
        }
        default {
            Write-Host "`nPilihan tidak dikenal, menggunakan default: Chrome." -ForegroundColor DarkGray
            $resolvedBrowser = "Chrome"
        }
    }
}

# Locate Browser Executable
$browserExe = Find-BrowserExecutable -BrowserType $resolvedBrowser -CustomPath $customExePath
if (-not $browserExe) {
    Write-Host "`n[ERROR] Browser '$resolvedBrowser' executable was not found on this system." -ForegroundColor Red
    Write-Host "Pastikan browser tersebut terinstal atau gunakan opsi browser lain." -ForegroundColor Yellow
    exit 1
}

# Interactive Profile Resolution (DEFAULT = 'ai-agent' on Enter)
$resolvedProfile = $ProfileName
if (-not $Yes) {
    while ($true) {
        Write-Host "`nEnter profile name (press Enter for default 'ai-agent'):" -ForegroundColor Yellow
        $promptInput = Read-Host "Profile Name"
        if ([string]::IsNullOrWhiteSpace($promptInput)) {
            $resolvedProfile = "ai-agent"
        } else {
            $resolvedProfile = $promptInput.Trim()
        }

        # Check if profile directory already exists
        $profileExists = Test-ProfileExists -ProfileName $resolvedProfile -BrowserType $resolvedBrowser
        if (-not $profileExists) {
            Write-Host "`n[NOTICE] Profile '$resolvedProfile' does not exist yet for $resolvedBrowser." -ForegroundColor Yellow
            Write-Host "Pilihan tindakan:" -ForegroundColor DarkGray
            Write-Host "  1. create      - Buat direktori profil baru dan lanjutkan"
            Write-Host "  2. anothername - Masukkan nama profil lain"
            Write-Host "  3. cancel      - Batalkan dan keluar"

            $actionChoice = Read-Host "`nPilih opsi [1/2/3] (default: 1)"
            if ([string]::IsNullOrWhiteSpace($actionChoice)) { $actionChoice = "1" }
            $actionChoice = $actionChoice.Trim()

            switch ($actionChoice) {
                "1" {
                    Write-Host "`n[OK] Profil '$resolvedProfile' akan dibuat baru." -ForegroundColor Green
                    break
                }
                "2" {
                    Write-Host "`nSilakan masukkan nama profil lain..." -ForegroundColor Cyan
                    continue
                }
                "3" {
                    Write-Host "`n[CANCELLED] Peluncuran profil dibatalkan oleh pengguna." -ForegroundColor Yellow
                    exit 0
                }
                default {
                    Write-Host "`n[CANCELLED] Pilihan tidak valid. Keluar." -ForegroundColor Yellow
                    exit 0
                }
            }
            break
        } else {
            Write-Host "`n[OK] Profil '$resolvedProfile' ditemukan di disk." -ForegroundColor Green
            break
        }
    }
}

$ProfileName = $resolvedProfile
$userDataDir = Get-ProfileDataDir -ProfileName $ProfileName -BrowserType $resolvedBrowser
$isPortBusy = Test-DebuggingPort -Port $Port

# Render Pre-Flight Briefed Card
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   PRE-FLIGHT BRIEFED OVERVIEW: REMOTE DEBUGGER           " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Target Browser   : $resolvedBrowser"
Write-Host " Browser Path     : $browserExe"
Write-Host " Target Profile   : $ProfileName"
Write-Host " Remote Port      : $Port $(if ($isPortBusy) { '[PORT CURRENTLY ACTIVE]' } else { '[PORT AVAILABLE]' })"
Write-Host " Isolated Data Dir: $userDataDir"
Write-Host " Initial URL      : $Url"
Write-Host " Mode             : $(if ($Headless) { 'Headless' } else { 'GUI Window (Interactive)' })"
Write-Host " Safety Guarantee : 100% isolated from personal browser data and cookies"
Write-Host "==========================================================" -ForegroundColor Cyan

# Check if port is already running
if ($isPortBusy -and -not $KillExisting -and -not $Yes) {
    Write-Host "`n[NOTICE] Port $Port is already active." -ForegroundColor Yellow
    Write-Host "An existing browser session or debugging agent may already be listening." -ForegroundColor DarkGray
    $choice = Read-Host "`nAttach to existing session [A], Restart with clean session [R], or Cancel [C] (default: A)"
    if ($choice.Trim().ToUpperInvariant() -eq "R") {
        $KillExisting = $true
    } elseif ($choice.Trim().ToUpperInvariant() -eq "C") {
        Write-Host "`n[CANCELLED] Operation aborted by user." -ForegroundColor Yellow
        exit 0
    }
}

if (-not $Yes -and -not $isPortBusy) {
    $confirm = Read-Host "`nLaunch $resolvedBrowser with profile '$ProfileName'? (Type 'yes' to proceed, Enter to cancel)"
    if ($confirm.Trim().ToLowerInvariant() -ne "yes") {
        Write-Host "`n[CANCELLED] Launcher aborted by user." -ForegroundColor Yellow
        exit 0
    }
}

Write-Host "`nLaunching $resolvedBrowser with remote debugging enabled..." -ForegroundColor Green

$launchResult = Start-BrowserRemoteDebugger `
    -BrowserPath $browserExe `
    -BrowserType $resolvedBrowser `
    -ProfileName $ProfileName `
    -Port $Port `
    -Url $Url `
    -Headless:$Headless `
    -ForceRestart:$KillExisting

# Update History Options JSON
try {
    $jsonPath = Join-Path $PSScriptRoot "adapter\activate-remote-debuging-cirtain-profile-name.json"
    $opt = [ordered]@{
        defaultBrowser     = $resolvedBrowser
        defaultProfileName = $ProfileName
        defaultPort        = $Port
        defaultUrl         = $Url
        lastLaunched       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    $optJson = $opt | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($jsonPath, $optJson, [System.Text.Encoding]::UTF8)
} catch {}

if ($launchResult.Status -eq "Running") {
    Write-Host "`n[SUCCESS] $resolvedBrowser is running with remote debugging active!" -ForegroundColor Green
    Write-Host " Process ID   : $($launchResult.ProcessId)"
    Write-Host " Debug Port   : $Port"
    Write-Host " Profile Name : $ProfileName"
    Write-Host " User Data Dir: $userDataDir"
    Write-Host "`nAntigravity subagents can now connect automatically to port $Port." -ForegroundColor Cyan
} elseif ($launchResult.Status -eq "AlreadyRunning") {
    Write-Host "`n[ATTACHED] Connected to existing $resolvedBrowser debugging session on port $Port." -ForegroundColor Green
    Write-Host " Profile Name : $ProfileName"
    Write-Host " Ready for Antigravity browser automation." -ForegroundColor Cyan
} else {
    Write-Host "`n[WARNING] $resolvedBrowser launched (PID: $($launchResult.ProcessId)), but port $Port was not verified within 5s." -ForegroundColor Yellow
    Write-Host "Check if browser window opened successfully on your screen." -ForegroundColor DarkGray
}
