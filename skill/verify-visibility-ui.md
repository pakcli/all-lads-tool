---
name: verify-visibility-ui
description: >-
  Standardized protocol for verifying UI/UX visibility, visual contrast, state changes,
  and layout integrity using automated headless Chromium screenshots, DOM state injection,
  and zero-scroll viewport audits across Desktop and Mobile viewports.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 👁️ UI/UX Visibility & Visual Integrity Verification Skill (`verify-visibility-ui`)

This skill defines the standardized protocol for diagnosing, capturing, analyzing, and proving UI visibility, contrast compliance, and layout integrity across the **Vintage Computing Arcade** web interfaces (`src/library.html`, `src/apps.html`, `src/playground.html`, and standalone app cartridges).

---

## 1. Core Principles & Verification Hierarchy

When fixing, auditing, or refactoring UI elements, never assume code changes look right without visual proof. Follow this 5-stage verification hierarchy:

1. **Static Analysis & CSS Trace**:
   - Trace cascading rules to identify collisions (e.g., `theme.css` declaring `background-color: var(--interactive-accent)` while an override stylesheet sets `color: var(--interactive-accent)` — causing green-on-green invisible text).
2. **State Injection Verification**:
   - Inject specific UI states (`is-pinned`, active sector filters, search queries, theme modes) to test all permutations, not just default uninitialized states.
3. **Headless Chromium Snapshot Capture**:
   - Execute modern Chromium in headless mode (`--headless=new`) with explicit viewport dimensions matching desktop and mobile breakpoints.
4. **Visual Inspection via Multimodal Tools**:
   - Load the rendered snapshot via `view_file` to visually verify contrast, typography, alignment, icons, and borders.
5. **Airgap & Local Protocol Validation (`file:///` vs `http://`)**:
   - Test directly under local `file:///` double-click protocol to catch CORS errors, blocked Blob downloads, missing base tags, or directory indexing bugs.

---

## 2. Automated Headless Chromium Screenshot Protocol

Use dynamic repository root resolution and environment variables to detect Chromium or Edge in PowerShell or Node.js without hardcoded machine paths:

### A. Desktop Viewport (`1280×800` or `1600×900`)
```powershell
# Resolve dynamic repo root and paths
$repoRoot = (Get-Item (Join-Path $PSScriptRoot "..\..")).FullName
$outPath = Join-Path $repoRoot "src\assets\verify_desktop.png"
$targetUrl = "file:///" + (Join-Path $repoRoot "public\apps.html").Replace('\', '/')

# Dynamically find Chromium/Chrome/Edge browser executable
$chromePath = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

Start-Process -FilePath $chromePath -ArgumentList @(
    "--headless=new",
    "--disable-gpu",
    "--disable-background-networking",
    "--hide-scrollbars",
    "--window-size=1280,800",
    "--screenshot=""$outPath""",
    """$targetUrl"""
) -Wait -PassThru -NoNewWindow
```

### B. Mobile Portrait Viewport (`375×812` - iPhone / Android)
```powershell
$repoRoot = (Get-Item (Join-Path $PSScriptRoot "..\..")).FullName
$outPath = Join-Path $repoRoot "src\assets\verify_mobile.png"
$targetUrl = "file:///" + (Join-Path $repoRoot "public\apps.html").Replace('\', '/')

$chromePath = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

Start-Process -FilePath $chromePath -ArgumentList @(
    "--headless=new",
    "--disable-gpu",
    "--disable-background-networking",
    "--hide-scrollbars",
    "--window-size=375,812",
    "--screenshot=""$outPath""",
    """$targetUrl"""
) -Wait -PassThru -NoNewWindow
```

### Critical Flags Explanation:
- `--headless=new`: Uses the modern Chrome rendering engine (supporting modern CSS Grid, OKLCH colors, and `@container` queries).
- `--disable-gpu`: Prevents shader compilation hangs on headless environments.
- `--disable-background-networking`: Disables GCM/Google sync background tasks that cause process lingering or timeouts.
- `--screenshot=""$outPath""`: In PowerShell `-ArgumentList`, double quotes must be doubled to escape correctly.

---

## 3. Testing Dynamic & Stateful UI Components

Many UI defects only manifest in non-default states (e.g. pinned items, search results, modal open). Test state transitions using ephemeral test wrappers:

### Testing LocalStorage States (e.g. Pinned Cartridges):
```powershell
$repoRoot = (Get-Item (Join-Path $PSScriptRoot "..\..")).FullName
$appsHtmlPath = Join-Path $repoRoot "public\apps.html"
$testHtmlPath = Join-Path $repoRoot "public\test_state.html"
$outPath = Join-Path $repoRoot "src\assets\verify_state.png"
$targetUrl = "file:///" + $testHtmlPath.Replace('\', '/')

$html = Get-Content $appsHtmlPath -Raw
# Inject active state before app boots
$html = $html -replace "<script>", "<script>localStorage.setItem('arcade_pinned_apps', '[`"vibe-arcade-deck`"]');"
Set-Content -Path $testHtmlPath -Value $html -Encoding UTF8

$chromePath = @(
    "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
    "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
    "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
    "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

# Snapshot
Start-Process -FilePath $chromePath -ArgumentList @(
    "--headless=new",
    "--disable-gpu",
    "--disable-background-networking",
    "--window-size=1280,800",
    "--screenshot=""$outPath""",
    """$targetUrl"""
) -Wait -PassThru -NoNewWindow

# Always clean up temporary state test files
Remove-Item $testHtmlPath -Force
```

---

## 4. Visual Inspection Checklist (What to Look For)

When viewing snapshots via `view_file`, verify against this checklist:

| Category | Verification Item | Common Failure Mode | Fix Target |
| :--- | :--- | :--- | :--- |
| **Color & Contrast** | Text readability against surfaces | Text color identical to background (e.g., green text on green button) | `src/theme/flopydisk-cornercut.css` |
| **Icons & Badges** | Pin toggles, status pills | Star `★` or Pin `📌` missing, glyph rendering as blank box | Add explicit text color, line-height, and drop-shadow |
| **Zero Horizontal Scroll** | Mobile portrait width compliance | Outer horizontal scrollbar appears (`scrollWidth > clientWidth`) | Rule #2: `overflow-x: clip; minmax(0, 1fr)` |
| **Bento Viewport Lock** | Desktop layout (`>= 900px`) | Page scrolls vertically instead of locking stage to `100dvh` | Bento Rule: `height: 100dvh; overflow: hidden;` |
| **Local File Navigation** | Local `file:///` execution | Navigating to directory opens Apache/Chrome folder index | Target `playground.html?app=<id>` directly |
| **Download Execution** | Single-file `.html` download | Clicking download triggers infinite loop or CORS error | Add `data-bypass-arcade="true"` and local file pass-through |
| **Category Frontmatter** | Dynamic sector tabs count | Tabs display static labels without detected counts | Execute `syncCategoryTabsUI()` from parsed MD frontmatters |

---

## 5. Automated Build-Time Screenshot Integration

During production builds (`compile-arctitecture-bundledjs.ps1`), automated desktop screenshots are captured for all live app cartridges and stored in `assets/thumbnails/<appId>.png`:

```json
"screenshots": {
  "output": "assets/thumbnails",
  "windowSize": "1280,720",
  "targets": [
    { "id": "vibe-arcade-deck", "source": "apps/vibe-arcade-deck_standalone_slidev.html" },
    { "id": "ksi", "source": "apps/radiansincostan.html" }
  ]
}
```
If a cartridge is missing or an external bookmark, the catalog automatically renders the retro CRT fallback:
`[preview not found]` with `📺` icon and `▶` launch trigger.
