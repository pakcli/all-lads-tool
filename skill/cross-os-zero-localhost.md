---
description: RULE #007 — Universal Cross-OS File URL & Zero-Localhost Browser Automation Invariant
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE #007 — Universal Cross-OS & Zero-Localhost Browser Automation

> [!IMPORTANT]
> **THE ZERO-LOCALHOST & CROSS-OS INVARIANT**:
> All interactive HTML tools, cockpits, and visual dashboards across `all-lads-tool` must be **100% OFFLINE, STATIC FILE-BASED (`file:///`), AND PORT-AGNOSTIC**.
> **NEVER require a local HTTP web server (`localhost`, `127.0.0.1`, or fixed ports) to view or operate a dashboard.**

---

## 1. Absolute Prohibitions

1. **ZERO Hardcoded Localhost**: Never bind, open, or poll `http://localhost:<PORT>` or `http://127.0.0.1:<PORT>` for dashboard cockpits.
2. **ZERO Server Pre-requisite**: Viewing dashboards must never require starting Node.js servers, Python HTTP servers, or PowerShell TCP listeners.
3. **ZERO Platform-Specific Path Separators in HTML**: HTML links, asset references, and browser URL invocations must never use Windows backslashes (`\`).

---

## 2. Cross-OS Path & Browser Launch Standards

When generating or opening HTML files from PowerShell scripts across Windows, macOS, and Linux:

### 2.1 File URL Normalization
Always normalize local file paths to forward-slashes with the `file:///` protocol:
```powershell
# CORRECT: Universal cross-OS browser URL normalization
$safeUrl = "file:///" + $fullPath.Replace('\', '/')
```

### 2.2 Cross-Platform Browser Launcher Pattern
Different operating systems use different command binaries to launch the default web browser. Always handle OS detection gracefully:

```powershell
function Open-BrowserFile {
    param([Parameter(Mandatory)][string]$HtmlFilePath)
    
    $resolvedPath = (Resolve-Path $HtmlFilePath).Path
    $fileUrl = "file:///" + $resolvedPath.Replace('\', '/')
    
    if ($IsWindows -or ($env:OS -like "*Windows*")) {
        Start-Process $fileUrl
    }
    elseif ($IsMacOS) {
        & open $fileUrl
    }
    elseif ($IsLinux) {
        & xdg-open $fileUrl
    }
    else {
        # Fallback for Windows PowerShell 5.1 (where $IsWindows automatic variable does not exist)
        Start-Process $fileUrl
    }
}
```

---

## 3. Dynamic HTML Generation Standards

When PowerShell generates HTML (such as `_mainmenu.html` from `_mainmenu.ps1`):
1. **UTF-8 Encoding Without BOM**: Always write using `[System.Text.Encoding]::UTF8` via `[System.IO.File]::WriteAllText()`.
2. **Self-Contained Client Architecture**: All drag-and-drop logic, card filtering, and UI interactions must run via pure Vanilla JavaScript embedded directly in the HTML file.
3. **Single Source of Truth**: HTML dashboards must be generated dynamically from the live filesystem scan of `script/`, never hand-coded.

---

## 4. Verification & Audit Checklist

- [ ] Does the HTML file open directly via double-click (`file:///...`) with zero server running?
- [ ] Are all path references inside HTML using normalized forward-slashes (`/`)?
- [ ] Does browser launching detect Windows (`Start-Process`), macOS (`open`), and Linux (`xdg-open`)?
- [ ] Is the generated file completely free of `localhost` or fixed port requirements?
