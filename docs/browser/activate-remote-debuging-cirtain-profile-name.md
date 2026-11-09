---
title: "Activate Browser Remote Debugging on a Certain Profile Name"
tool: "activate-remote-debuging-cirtain-profile-name.ps1"
context: "browser"
runtime: "PowerShell 5.1+ / 7+"
aliases: ["browser-remote-debugger", "activate-chrome-edge-debugging", "ai-browser-launcher"]
tags: ["all-lads-tool", "browser", "chrome", "edge", "brave", "devtools", "debugging", "profile", "automation"]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[save-option-as-exact-executor-name-json]]"
copy_to_terminal_snippet: |
  & .\script\browser\activate-remote-debuging-cirtain-profile-name.ps1 -Browser "Chrome" -ProfileName "ai-agent"
---

# `activate-remote-debuging-cirtain-profile-name.ps1` - Activate Browser Remote Debugging (Context: Browser)

> [!INFO]
> **Context**: `browser` | **Executable**: `script/browser/activate-remote-debuging-cirtain-profile-name.ps1`
> **Adapters**: `script/browser/adapter/chrome-launcher.psm1`
> **History JSON**: `script/browser/adapter/activate-remote-debuging-cirtain-profile-name.json`
> **Canonical Documentation**: `docs/browser/activate-remote-debuging-cirtain-profile-name.md` (Matches script filename 1:1)

Launches Chromium-based browsers (Google Chrome, Microsoft Edge, Brave, or Custom executable) with remote debugging enabled on a dedicated, completely isolated user profile directory (default: `ai-agent`). This allows Antigravity AI agents, Playwright, and Puppeteer subagents to automate web browsing, inspect DOM, and take screenshots without accessing or interfering with personal browsing sessions, extensions, cookies, or tabs.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive mode (prompts for browser and profile, Enter selects defaults: Chrome & 'ai-agent')
.\script\browser\activate-remote-debuging-cirtain-profile-name.ps1

# Launch with Microsoft Edge and dedicated profile
.\script\browser\activate-remote-debuging-cirtain-profile-name.ps1 -Browser "Edge" -ProfileName "ai-agent"

# Specify custom target URL and force clean session
.\script\browser\activate-remote-debuging-cirtain-profile-name.ps1 -Browser "Chrome" -ProfileName "ai-agent" -Url "https://www.google.com" -KillExisting -Yes
```

---

## 2. Interactive Selection Flow

When running without `-Yes`:

### Step 1: Browser Selection (Default = Chrome on Enter)
```text
Pilih browser yang ingin digunakan:
  [ 1 ] Chrome (Default - tekan Enter)
  [ 2 ] Edge   (Microsoft Edge)
  [ 3 ] Brave
  [ 4 ] Custom (Masukkan path browser Chromium sendiri)

Pilih opsi browser [1/2/3/4] (default: 1):
```

### Step 2: Profile Selection & Existence Audit (Default = ai-agent on Enter)
```text
Enter profile name (press Enter for default 'ai-agent'):
```
If the profile directory does not exist on disk, the tool immediately provides a 3-choice decision gate:
```text
[NOTICE] Profile 'ai-agent' does not exist yet for Chrome.
Pilihan tindakan:
  1. create      - Buat direktori profil baru dan lanjutkan
  2. anothername - Masukkan nama profil lain
  3. cancel      - Batalkan dan keluar

Pilih opsi [1/2/3] (default: 1):
```

---

## 3. Command Line Parameters Matrix

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-ProfileName` | `[string]` | No | `"ai-agent"` | Name of the dedicated profile. Sanitized into user data folder. |
| `-Browser` | `[string]` | No | `"Chrome"` | Target browser: `Chrome`, `Edge`, `Brave`, or `Custom`. |
| `-Port` | `[int]` | No | `9222` | Remote debugging port for DevTools protocol connection. |
| `-Url` | `[string]` | No | `"https://www.google.com"` | Initial web page URL to open upon launch. |
| `-KillExisting` | `[switch]` | No | `$false` | Terminates existing processes listening on the target debugging port. |
| `-Headless` | `[switch]` | No | `$false` | Launches browser in modern headless mode for background runs. |
| `-Yes` | `[switch]` | No | `$false` | Bypasses interactive confirmation gating for automated workflows. |

---

## 4. Pre-Flight Briefed Overview Card

Before launching, the tool renders a pre-flight overview card:

```text
==========================================================
   PRE-FLIGHT BRIEFED OVERVIEW: REMOTE DEBUGGER
==========================================================
 Target Browser   : Chrome
 Browser Path     : <ProgramFiles>\Google\Chrome\Application\chrome.exe
 Target Profile   : ai-agent
 Remote Port      : 9222 [PORT AVAILABLE]
 Isolated Data Dir: <LOCALAPPDATA>\Google\Chrome\User Data - ai-agent
 Initial URL      : https://www.google.com
 Mode             : GUI Window (Interactive)
 Safety Guarantee : 100% isolated from personal browser data and cookies
==========================================================

Launch Chrome with profile 'ai-agent'? (Type 'yes' to proceed, Enter to cancel):
```

---

## 5. Troubleshooting Matrix

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| Port 9222 already in use | Another browser instance or debugger is attached | Use `-KillExisting` to restart or choose attach option `[A]`. |
| Browser executable not found | Browser not installed in standard directory | Choose option `[ 4 ] Custom` and provide explicit path. |
| `DevToolsActivePort` not found | Browser closed immediately or permissions error | Ensure user data directory is writable and not locked by another process. |
