---
name: prototype-emoji-icon-lifecycle
aliases: [prototype-emoji-icon, emoji-prototype-replacement, prototype-to-production-icons, emoji-icon-lifecycle]
category: UIUX_CONVENTION
tags: [all-lads-tool, ui, ux, prototype, emoji, icons, lucide, svg, lifecycle, convention]
description: Standard operating protocol for using UTF-8 emojis as zero-dependency visual icons during prototyping, and systematically replacing them with production-grade assets (Lucide, SVG, Design System tokens) upon setup and finalization.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 🎨 Prototype Emoji to Production Icon Lifecycle Skill (`prototype-emoji-icon-lifecycle`)

> [!INFO]
> **Domain**: UI/UX, CLI Dashboards, Obsidian Views, Documentation & Web Toolkits  
> **Core Principle**: **Rapid Emoji Prototyping $\rightarrow$ Structured Production Icon Migration**  
> **Status Invariant**: All modifications governed under the `donot-commit-yet` quarantine protocol.

---

## 1. Executive Summary & Philosophy

When developing tools, plugins, CLI menus, and user interfaces within `all-lads-tool`:

1. **In Prototype Phase (Speed & Frictionless Exploration)**:
   - Use native **UTF-8 Emojis** (`📁`, `⚙️`, `🚀`, `📦`, `🔍`, `🎨`, `⚠️`, `📌`, `🧩`, `👁️`) as immediate, zero-dependency visual placeholders.
   - Eliminates icon-bundling overhead, network requests, asset pipeline friction, and broken SVG paths during initial architecture spikes.
   - Emojis render out-of-the-box across Windows Terminal, PowerShell, Obsidian markdown, browser previews, and mobile viewports.

2. **In Setup / Production Phase (Refinement & Polished Delivery)**:
   - Once a feature or layout reaches the **Setup Milestone** (`status 1`, production bundle, community release, official theme setup), all temporary prototype emojis must be systematically replaced with **production-grade iconography** (e.g., Obsidian Lucide icons, vectorized SVGs, CSS mask sprites, or design system tokens).
   - Emojis may only remain if they are explicitly part of an intentional retro 8-bit / arcade design aesthetic (e.g. vintage computing arcade themes).

---

## 2. The Two-Phase Lifecycle Matrix

| Dimension | Phase 0 & 1: Prototype Spike (`status 0`) | Phase 2: Setup & Final Release (`status 1`) |
| :--- | :--- | :--- |
| **Primary Visual Asset** | UTF-8 Native Emojis (`📁`, `⚙️`, `🚀`) | Production Icons (`lucide:folder`, SVG, Vector Sprites) |
| **Asset Dependency** | **Zero** (Baked into Unicode system fonts) | Icon pack or inlined SVG bundle |
| **CLI / Terminal Support** | High (PowerShell 7+, Windows Terminal, Bash) | ANSI text glyphs, Nerd Font symbols, or clean ASCII tags |
| **Obsidian Integration** | Direct text string in markdown / ribbon | Native Obsidian `setIcon(el, 'icon-id')` / Lucide icons |
| **Web / Bento Layout** | Inline text nodes (`<span>🚀</span>`) | CSS mask-image or SVG symbol tags |
| **Performance Overhead** | 0 KB extra payload | Optimized SVG symbols or sprite atlas |
| **Replacement Rule** | Keep active while iterating | **Must replace before tagging setup / release** |

---

## 3. Universal Prototype Emoji to Production Icon Mapping

Use this authoritative dictionary to map prototype emojis to their standardized production equivalents:

| Semantic Intent | Prototype Emoji | Obsidian / Lucide ID | Web / SVG Standard | CLI Terminal Clean Fallback |
| :--- | :---: | :--- | :--- | :--- |
| **Folder / Directory** | 📁 / 📂 | `lucide:folder` / `lucide:folder-open` | `<svg ... folder-icon>` | `[DIR]` |
| **File / Document** | 📄 / 📝 | `lucide:file-text` | `<svg ... file-text>` | `[FILE]` |
| **Settings / Config** | ⚙️ / 🔧 | `lucide:settings` / `lucide:sliders` | `<svg ... cog-gear>` | `[CFG]` |
| **Launch / Run / Action** | 🚀 / ▶️ | `lucide:play` / `lucide:rocket` | `<svg ... play-icon>` | `[RUN]` |
| **Package / Submodule** | 📦 / 🗃️ | `lucide:package` / `lucide:box` | `<svg ... package-box>` | `[PKG]` |
| **Search / Inspection** | 🔍 / 🔎 | `lucide:search` | `<svg ... search-glass>` | `[FIND]` |
| **Git / Versioning** | 🌿 / 🔀 | `lucide:git-branch` / `lucide:git-merge` | `<svg ... git-branch>` | `[GIT]` |
| **Security / Auth / Mask** | 🔒 / 🛡️ | `lucide:lock` / `lucide:shield` | `<svg ... lock-padlock>` | `[SEC]` |
| **Reveal Eye Toggle** | 👁️ / 🕶️ | `lucide:eye` / `lucide:eye-off` | `<svg ... eye-toggle>` | `[SHOW]` |
| **Warning / Caution** | ⚠️ / 🚨 | `lucide:alert-triangle` | `<svg ... alert-tri>` | `[!WARN!]` |
| **Success / Validated** | ✅ / 🟢 | `lucide:check-circle` | `<svg ... checkmark>` | `[OK]` |
| **Failure / Error** | ❌ / 🔴 | `lucide:x-circle` | `<svg ... cross-x>` | `[ERR]` |
| **Terminal / CLI** | 💻 / ⌨️ | `lucide:terminal` | `<svg ... terminal>` | `[CLI]` |
| **History / Timeline** | ⏳ / 🕒 | `lucide:history` / `lucide:clock` | `<svg ... clock-history>` | `[TIME]` |
| **Design / Palette** | 🎨 / 🖼️ | `lucide:palette` / `lucide:image` | `<svg ... color-palette>` | `[THEME]` |

---

## 4. Implementation Guidelines by Target Surface

### 4.1 Surface A: Obsidian Plugins & Markdown Panels

* **Prototype State**:
  ```typescript
  // Fast prototype: emoji directly inserted in button text
  buttonEl.setText("⚙️ Settings");
  ribbonEl.createSpan({ text: "🚀" });
  ```

* **Setup / Production State (Migrated)**:
  ```typescript
  // Production setup: native Obsidian Lucide API
  import { setIcon } from "obsidian";
  
  const iconContainer = buttonEl.createSpan({ cls: "nav-action-icon" });
  setIcon(iconContainer, "settings");
  buttonEl.createSpan({ text: "Settings" });
  ```

---

### 4.2 Surface B: Web Applications & Bento Split-Screen Playgrounds

* **Prototype State**:
  ```html
  <button class="action-btn">
    <span class="btn-icon">📦</span>
    <span class="btn-label">Bundle Module</span>
  </button>
  ```

* **Setup / Production State (Migrated)**:
  ```html
  <button class="action-btn" aria-label="Bundle Module">
    <svg class="btn-icon" width="16" height="16" aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M16.5 9.4 7.55 4.24a1.78 1.78 0 0 0-2.5 1.55v12.42a1.78 1.78 0 0 0 2.5 1.55L16.5 14.6a1.78 1.78 0 0 0 0-3.2z"/>
    </svg>
    <span class="btn-label">Bundle Module</span>
  </button>
  ```

---

### 4.3 Surface C: PowerShell & CLI Terminal Menus (`git-manage_stand.ps1`, `_mainmenu.ps1`)

* **Prototype State**:
  ```powershell
  Write-Host "  [1] 📊 Git Status & Working Tree" -ForegroundColor Cyan
  Write-Host "  [2] 📦 Submodule Manager Hub" -ForegroundColor Cyan
  Write-Host "  [3] ⚡ Standalone Compilers" -ForegroundColor Cyan
  ```

* **Setup / Production State (Migrated)**:
  ```powershell
  # Clean, cross-terminal compatible formatting without font-glitch risks
  Write-Host "  [1] [STATUS] Git Status & Working Tree" -ForegroundColor Cyan
  Write-Host "  [2] [MODULE] Submodule Manager Hub" -ForegroundColor Cyan
  Write-Host "  [3] [STAND]  Standalone Compilers" -ForegroundColor Cyan
  ```

---

## 5. Audit & Detection: Automated Scanner Script

To detect any remaining prototype emojis before tagging a setup release, run this automated inspection script:

```powershell
# Scan workspace for prototype emojis requiring replacement before setup
Get-ChildItem -Path . -Recurse -Include *.ts,*.js,*.html,*.css,*.ps1 -Exclude node_modules,dist,trash-bin | ForEach-Object {
    $file = $_
    $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -match '[\u{1F300}-\u{1F9FF}]') {
        [PSCustomObject]@{
            File    = $file.FullName.Replace((Get-Location).Path + "\", "")
            Status  = "Needs Setup Icon Replacement"
        }
    }
} | Format-Table -AutoSize
```

---

## 6. Verification Checklist Before Marking Feature "Setup Complete"

- [ ] All prototype emojis in interactive UI buttons converted to `setIcon(el, '...')` or vector `<svg>`.
- [ ] No inconsistent platform-specific emoji rendering (e.g. Android vs iOS vs Windows emoji differences).
- [ ] Screen readers / accessibility: all icons accompanied by `aria-label` or `sr-only` text.
- [ ] All changes remain **uncommitted in working tree** under the `donot-commit-yet` quarantine protocol.
