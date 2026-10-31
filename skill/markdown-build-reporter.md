---
name: markdown-build-reporter
description: >-
  Standardized Markdown build reporter skill generating self-documenting BUILD_REPORT.md reports.
  Features YAML frontmatter metadata, heading-based app brief with 3 openable files (HTML, lightmode WebP,
  darkmode WebP), Obsidian wikilink properties, 4 core build sizes, clean retro ASCII architecture diagrams,
  and embedded CSV audit logs in fenced codeblocks.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 📊 Markdown Build Reporter (Frontmatter, Apps Brief, 4 Sizes, ASCII & CSV)

This skill specifies the standard for generating **self-documenting Markdown build reports** (`BUILD_REPORT.md`). It emphasizes simplicity, clarity, terminal-friendly retro aesthetics, and full integration with Obsidian properties:
1. **Frontmatter Metadata**: `version-build`, `version-build-by`, `note`, and `commit` change groups.
2. **Heading-Based Apps Brief**: Each cartridge listed as a markdown heading with 3 directly openable files and Obsidian wikilinks.
3. **Four Core Build Sizes**: `src`, `apps`, `build include apps`, `build compacted include apps`.
4. **Simple Retro ASCII Diagram**: Raw sources -> Compiled bundles -> Final compacted distribution.
5. **Embedded CSV Codeblock**: Machine-readable payload audit data.

---

## 1. Core Principles & Architecture

1. **Self-Documenting Standalone Output**:
   Every build produces `BUILD_REPORT.md` (at repo root and `public/BUILD_REPORT.md`), giving developers, CI/CD, and Obsidian users an instant executive and file-level summary.
2. **Frontmatter Metadata**:
   Enables automated tooling, Obsidian properties, and git lineage tracking directly at the top of the report:
   ```yaml
   ---
   version-build: 2.1.0
   version-build-by: agent # or me
   note: Automated production build report
   commit:
     feat:
       - New feature description
     chore:
       - Maintenance description
     remove:
       - Removed element description
   ---
   ```
3. **Heading-Based Apps Brief (3 Openable Files)**:
   Instead of an unclickable ASCII tree, use structured markdown headings (`### 1. Title (slug)`) for each app. Under each heading, provide direct clickable links to:
   * 🌐 **Standalone HTML App**: `[slug.html](apps/slug.html)`
   * ☀️ **Playwright Light Mode Preview**: `[slug_img-lightmode.webp](apps/slug_img-lightmode.webp)`
   * 🌙 **Playwright Dark Mode Preview**: `[slug_img-darkmode.webp](apps/slug_img-darkmode.webp)`
4. **Obsidian WikiLink Properties Compatibility**:
   In app markdown files (`apps/*.md`), the `img` frontmatter property uses Obsidian wikilinks:
   ```yaml
   img: [[slug_img-lightmode.webp]], [[slug_img-darkmode.webp]]
   ```
   Obsidian natively renders these as interactive hoverable/clickable file previews. The build engine sanitizes them for clean web runtime paths.
5. **Embedded CSV Codeblock**:
   Embed raw CSV data directly in a fenced ````csv codeblock for immediate copy-pasting or automated ingestion.

---

## 2. Standard Report Structure (`BUILD_REPORT.md`)

```markdown
---
version-build: 2.1.0
version-build-by: agent
note: Core production build report with standalone bundling, zero-ID compliance, Playwright preview audits, and CSV metrics.
commit:
  feat:
    - Standalone core build engine (src/modules/build-bundle.js)
    - Apps brief using Markdown headings format with 3 openable files per app
  chore:
    - Obsidian-compatible wikilink frontmatter properties (img: [[light.webp]], [[dark.webp]])
    - Synchronize public and root apps catalog and build metrics
  remove:
    - Hardcoded all-script dependency from core build engine
---

# 🕹️ Vintage Computing Arcade — Production Build Report

## 📝 1. Architectural Brief & Build Overview
* **Project**: `<PROJECT_NAME>`
* **Timestamp**: ISO-8601 Timestamp
* **Build Engine**: `src/modules/build-bundle.js` (100% Standalone Core, Zero-Backend)
* **Architecture Rules**:
  * Rule #1 (Theme Immutability): `theme.css` is preserved with 0 edits / 100% byte fidelity.
  * Rule #2 (Mobile Zero Horizontal Scroll): `overflow-x: clip` across all viewports.
  * Rule #3 (Zero Hardcoded Variables): Dynamic resolution from root.
  * Zero-ID Standard: Slugs derived strictly from basenames.

---

## 🕹️ 2. Standalone Apps & Cartridges Brief

### 1. 📐 Unit Circle Resolver (`radiansincostan`)
* **Category / Sector**: `MATH & CANVAS` (`edu`)
* **Overview**: Interactive trigonometric unit circle calculator. Drag dynamic angle point to solve real-time sin, cos, and tan with exact radical fractions.
* **Obsidian Frontmatter `img`**: `[[radiansincostan_img-lightmode.webp]], [[radiansincostan_img-darkmode.webp]]`
* **Direct Openable Artifacts (3 Files)**:
  1. 🌐 **Standalone HTML App**: [radiansincostan.html](apps/radiansincostan.html)
  2. ☀️ **Playwright Light Mode Preview**: [radiansincostan_img-lightmode.webp](apps/radiansincostan_img-lightmode.webp)
  3. 🌙 **Playwright Dark Mode Preview**: [radiansincostan_img-darkmode.webp](apps/radiansincostan_img-darkmode.webp)
  *(Source Markdown: [radiansincostan.md](apps/radiansincostan.md))*

---

## 🎯 3. Four Core Build Sizes

| Metric | Size (KB) | Description | Status |
| :--- | :--- | :--- | :--- |
| **[1] `src`** | **... KB** | Raw source code in `src/` | Uncompiled Source |
| **[2] `apps`** | **... KB** | Standalone cartridges in `apps/` | Isolated Apps |
| **[3] `build include apps`** | **... KB** | Total compiled distribution in `public/` | Raw Build |
| **[4] `build compacted include apps`** | **... KB** | Compacted distribution in `public/` | **Optimized Output** |

---

## 🏗️ 4. Build Architecture Flow (ASCII Diagram)

```text
===================================================================================
                       RAW SOURCES (src/ & apps/)
  [src/modules/*.js] (379 KB)      [src/style/*.css] (180 KB)      [apps/*] (494 KB)
===================================================================================
             |                                 |                          |
             |  Concatenation & Routing        |  Combine & Scope         |  Cartridge CSR
             v                                 v                          v
+---------------------------------------------------------------------------------+
|                       COMPILED BUNDLES (public/)                                |
|  -> page-apps.js       (12 modules: Catalog, Navigation, Markdown, Downloader)  |
|  -> page-playground.js (12 modules: Dual-panel sandbox, Slidev, Speech, TTS)    |
|  -> winget.js          (Standalone Floating Quick Nav Pod)                      |
|  -> theme.css          (Verbatim Obsidian Retro Theme -- RULE #1 SAFE)          |
|  -> style.css          (Combined Floppy cut + Terminal cursor + Winget modals)  |
|  -> public/apps/*      (Standalone HTMLs, WebP thumbnails, _catalog.json)       |
+---------------------------------------------------------------------------------+
                                       |
                                       |  Terser / Regex Compaction & Strip
                                       v
===================================================================================
                  FINAL COMPACTED DISTRIBUTION (public/)
   Total Distribution: 1606.22 KB | Zero-Backend Ready | 100% Airgap Static
===================================================================================
```

---

## 📊 5. Build Audit CSV Data

```csv
Metric,Size_KB,Description
src,1542.71,Total raw source code size (src/)
apps,498.86,Total cartridges directory size (apps/)
build_include_apps,1720.21,Total compiled distribution size including apps (public/)
build_compacted_include_apps,1606.22,Total compacted distribution size including apps (public/)
...
```

---

## 📋 6. Detailed Payload Audit Table

| File Name | Source / Type | Compiled | Compacted | Reduction |
| :--- | :--- | :--- | :--- | :--- |
| `apps/radiansincostan.md` | 7.25 KB | 7.25 KB | 7.25 KB | -0.0% |
| ... | ... | ... | ... | ... |

---

> [!NOTE]
> **RULE #1 VERIFICATION**: `theme.css` byte length = `90924` bytes. Matched upstream Obsidian theme verbatim with zero mutations.
```
