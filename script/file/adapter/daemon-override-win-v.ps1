<#
.SYNOPSIS
    Win+V Full Override & System Clipboard History Engine (All-Lads-Tool)
    1. Records ALL clipboard items on the machine into polyclip-history.json (0% CPU via Win32 listener).
    2. Completely suppresses native Windows "Emoji & more / Clipboard" popup (TextInputHost).
    3. Opens PolyClip 4-Mode Panel on Win+V populated with the machine's entire clipboard history.
#>

[CmdletBinding()]
param (
    [switch]$DisableNativeOnly
)

# 1. Disable Windows Native Clipboard History in Registry & Policies
try {
    if (-not (Test-Path "HKCU:\Software\Microsoft\Clipboard")) {
        New-Item -Path "HKCU:\Software\Microsoft\Clipboard" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Clipboard" -Name "EnableClipboardHistory" -Value 0 -Type DWord -Force

    if (-not (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\System")) {
        New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\System" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowClipboardHistory" -Value 0 -Type DWord -Force

    Write-Host "[OK] Windows Native Clipboard History disabled via Registry & Policy." -ForegroundColor Green
} catch {
    Write-Warning "Could not update policy registry: $($_.Exception.Message)"
}

# Dismiss any active TextInputHost popup
Stop-Process -Name "TextInputHost" -ErrorAction SilentlyContinue

if ($DisableNativeOnly) {
    Write-Host "[DONE] Native popup is disabled." -ForegroundColor Green
    exit 0
}

# 2. Compile Win32 Key Interceptor & Clipboard Format Listener Hook
$csFile = Join-Path $PSScriptRoot "WinVInterceptor.cs"
if (-not (Test-Path $csFile)) {
    Write-Error "WinVInterceptor.cs not found at $csFile"
    exit 1
}

Add-Type -Path $csFile -ReferencedAssemblies "System.Windows.Forms"
Add-Type -AssemblyName System.Windows.Forms

$parentDir = Split-Path $PSScriptRoot -Parent
$panelScript = Join-Path $parentDir "detector-clipboard-4-mode.ps1"
if (-not (Test-Path $panelScript)) {
    $panelScript = Join-Path $PSScriptRoot "detector-clipboard-4-mode.ps1"
}

# Import snapshot engine module so daemon can capture without opening UI
$adapterModule = Join-Path $PSScriptRoot "detector-clipboard-4-mode.psm1"
Import-Module -Name $adapterModule -DisableNameChecking -Force

# 3. Callback A: When ANY copy event occurs on the machine (Zero-CPU WM_CLIPBOARDUPDATE)
[PolyClipHooks.WinVInterceptor]::OnClipboardChanged = [System.Action]{
    try {
        $snap = Get-ClipboardSnapshot
        # Saved to polyclip-history.json automatically
    } catch {}
}

# 4. Callback B: When Win+V is pressed
[PolyClipHooks.WinVInterceptor]::OnWinVPressed = [System.Action]{
    # Kill native popup if Windows Shell tried to spawn it
    Stop-Process -Name "TextInputHost" -ErrorAction SilentlyContinue

    # Launch PolyClip Panel
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$panelScript`" -Panel" -WindowStyle Hidden
}

[PolyClipHooks.WinVInterceptor]::Start()

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  POLYCLIP WIN+V OVERRIDE & HISTORY DAEMON IS ACTIVE!     " -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "1. Native popup (TextInputHost / Emoji and more) = DIBLOKIR." -ForegroundColor White
Write-Host "2. Machine Clipboard Recorder = AKTIF (0% CPU event-driven)." -ForegroundColor White
Write-Host "3. Tekan [Win + V] sekarang = PolyClip Panel langsung muncul!" -ForegroundColor Yellow
Write-Host "`nWindow ini menjaga hook tetap aktif. Boleh di-minimize." -ForegroundColor DarkGray
Write-Host "Tekan Ctrl+C di terminal ini untuk berhenti.`n" -ForegroundColor DarkGray

try {
    [System.Windows.Forms.Application]::Run()
} finally {
    [PolyClipHooks.WinVInterceptor]::Stop()
    Write-Host "`n[STOP] Win+V Hook stopped." -ForegroundColor Yellow
}
