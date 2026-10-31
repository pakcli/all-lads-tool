---
name: daftar-isi
aliases: [table-of-contents, toc-standard, toc-generator, daftar-isi-brief, markdown-toc]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, skill, documentation, daftar-isi, toc, table-of-contents, navigation, brief]
description: Standardized protocol for authoring, generating, and maintaining interactive Markdown Table of Contents (Daftar Isi) with GitHub-compatible slug anchors, bidirectional navigation, and hierarchical depth standards across architectural briefs and documentation.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 📑 Standardized Table of Contents Protocol (`daftar-isi`)

> [!INFO]
> **Specification Standard**: 100% Native Markdown & GitHub/Obsidian Compatible.  
> **Mandatory Anchor Standard**: GitHub-Flavored Slugification (`#heading-slug-in-kebab-case`).  
> **Position Mandate**: Sits immediately below Section 0 (Title & Metadata) in all architectural briefs.

This skill establishes the universal specification and authoring protocol for creating, formatting, and verifying an interactive **Daftar Isi (Table of Contents / TOC)** across all architectural briefs (`brief/vXX-XX_*.md`), engineering specifications, and long-form markdown documents.

---

## 1. Core Mandates & Structural Invariants

### 1.1 Invariant 1: Mandatory Placement in Briefs
In any architectural brief (`brief/vXX-XX_*.md`), the Daftar Isi is **NON-OPTIONAL**:
* Must sit directly below the top-level Title and Metadata Blockquote (Section 0).
* Must sit immediately before Section 1 (or the first foundational architectural section).
* Standardized Heading: `## 📑 DAFTAR ISI (TABLE OF CONTENTS)`.

### 1.2 Invariant 2: Bidirectional Navigation Architecture
A compliant document must provide seamless two-way jump links:
1. **Forward Navigation**: Clicking any item in the Daftar Isi jumps directly to the corresponding section header.
2. **Return Navigation (Back to Top)**: At the end of each major section (`##`), include an anchor link jumping back to the Daftar Isi:
   ```markdown
   [⬆️ Kembali ke Daftar Isi](#-daftar-isi-table-of-contents)
   ```

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   BIDIRECTIONAL NAVIGATION LIFECYCLE                   │
├────────────────────────────────────────────────────────────────────────┤
│ ┌────────────────────────────────────────────────────────────────────┐ │
│ │ SECTION 0: Title & Frontmatter Metadata                            │ │
│ └─────────────────────────────────┬──────────────────────────────────┘ │
│                                   │                                    │
│ ┌─────────────────────────────────▼──────────────────────────────────┐ │
│ │ ## 📑 DAFTAR ISI (TABLE OF CONTENTS)                               │ │
│ │   ├── 1. [Section Title](#1-section-title) ──────┐                 │ │
│ │   └── 2. [Deep Dive](#2-deep-dive) ────────────┐ │                 │ │
│ └─────────────────────────────────▲──────────────┼─┼─────────────────┘ │
│                                   │              │ │                   │
│                                   │ JUMP BACK    │ │ DIRECT JUMP       │
│                                   │              │ │                   │
│ ┌─────────────────────────────────┴──────────────│─▼─────────────────┐ │
│ │ ## 1. Section Title <──────────────────────────┘                   │ │
│ │ Content body ...                                                   │ │
│ │ [⬆️ Kembali ke Daftar Isi](#-daftar-isi-table-of-contents)         │ │
│ └─────────────────────────────────▲──────────────────────────────────┘ │
│                                   │                                    │
│ ┌─────────────────────────────────┴──────────────────────────────────┐ │
│ │ ## 2. Deep Dive <──────────────────────────────┘                   │ │
│ │ Content body ...                                                   │ │
│ │ [⬆️ Kembali ke Daftar Isi](#-daftar-isi-table-of-contents)         │ │
│ └────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. GitHub-Compatible Slugification Algorithm

To guarantee 100% link resolution across GitHub web preview, Obsidian, and static site generators (Quartz, VitePress, Astro), slug anchors must be computed using the following normalization rules:

$$\text{Slug} = \text{TrimHyphens}\left(\text{RegexReplace}\left(\text{Lowercase}(\text{Heading}), \text{ForbiddenChars}, \text{"-"}\right)\right)$$

### 2.1 The 6 Slugification Rules

1. **Lowercase**: Convert the entire heading text to lowercase (`[a-z0-9]`).
2. **Strip Emojis & Visual Fluff**: Remove all Unicode emojis (`📌`, `📑`, `🛡️`, `⚙️`, `🚀`, `💡`, etc.).
3. **Strip Special Characters**: Remove colons (`:`), question marks (`?`), exclamation marks (`!`), parentheses (`()`), brackets (`[]`), quotes (`"`, `'`), commas (`,`), periods (`.`), and forward/backward slashes (`/\`).
4. **Hyphenate Separators**: Convert spaces, tabs, and ampersands (`&`) to single hyphens (`-`).
5. **Collapse Redundant Hyphens**: Replace multi-consecutive hyphens (`---`) with a single hyphen (`-`).
6. **Trim Edges**: Remove any leading or trailing hyphens.

### 2.2 Canonical Transformation Examples

| Raw Markdown Heading | Normalized Anchor Target | Rendered Markdown Link |
| :--- | :--- | :--- |
| `## 📌 1. Engine Definition & Ecosystem Role` | `#1-engine-definition--ecosystem-role` | `* [1. Engine Definition & Ecosystem Role](#1-engine-definition--ecosystem-role)` |
| `### 3.1 Mode 1: Local -> Local (Zero-Cloud)` | `#31-mode-1-local---local-zero-cloud` | `  * [3.1 Mode 1: Local ➔ Local](#31-mode-1-local---local-zero-cloud)` |
| `## 📑 DAFTAR ISI (TABLE OF CONTENTS)` | `#-daftar-isi-table-of-contents` | `[⬆️ Kembali ke Daftar Isi](#-daftar-isi-table-of-contents)` |
| `## 5. Internal Quarantine (`brief/`)` | `#5-internal-quarantine-brief` | `* [5. Internal Quarantine (`brief/`)](#5-internal-quarantine-brief)` |

---

## 3. Hierarchical Nesting & Indentation Standard

TOC items must mirror the exact heading levels of the document:

```markdown
## 📑 DAFTAR ISI (TABLE OF CONTENTS)

1. [1. Engine Definition & Ecosystem Role](#1-engine-definition--ecosystem-role)
2. [2. The 3 Decoupled Execution & Compilation Modes](#2-the-3-decoupled-execution--compilation-modes)
3. [3. Step-by-Step Execution Runbook for Each Mode](#3-step-by-step-execution-runbook-for-each-mode)
   * [3.1 How to Execute Mode 1: Local ➔ Local](#31-how-to-execute-mode-1-local--local-zero-cloud--pure-offline-development)
   * [3.2 How to Execute Mode 2: Local ➔ GitHub Server](#32-how-to-execute-mode-2-local--framework-in-github-server-desktop-to-cloud-remote-staging)
   * [3.3 How to Execute Mode 3: Repo Markdown ➔ GitHub Pages](#33-how-to-execute-mode-3-repo-markdown--framework-in-github-server-github-to-github-native-cicd)
4. [4. Dynamic Homepage Entrypoint Resolution](#4-dynamic-homepage-entrypoint-resolution)
5. [5. Internal Documentation Quarantine (`brief/`)](#5-internal-documentation-quarantine-brief)
6. [6. Implemented Features: Dual Graph View](#6-implemented-features-dual-graph-view)
```

* Top-level sections (`##`) use numbered lists (`1.`, `2.`, `3.`) or bullet points (`*`).
* Sub-sections (`###`) are indented by 3 spaces (`   *`).
* Sub-sub-sections (`####`) are indented by 6 spaces (`      -`).

---

## 4. Zero-Dependency Generator Snippet (PowerShell & Node.js)

### 4.1 Standalone PowerShell TOC Extractor
When writing or refactoring markdown files, developers can generate or verify the Daftar Isi dynamically:

```powershell
function Get-MarkdownToc {
    param (
        [Parameter(Mandatory=$true)][string]$FilePath
    )
    $lines = Get-Content $FilePath
    $toc = @("## 📑 DAFTAR ISI (TABLE OF CONTENTS)`n")
    foreach ($line in $lines) {
        if ($line -match '^(#{2,4})\s+(.*)$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            if ($title -match 'DAFTAR ISI|TABLE OF CONTENTS') { continue }
            
            # Clean title of emojis and compute GitHub-compatible anchor
            $cleanTitle = $title -replace '[\p{Cs}\p{So}\p{Sk}]', '' -replace '`', ''
            $slug = $cleanTitle.ToLower() -replace '[^a-z0-9\s-]', '' -replace '\s+', '-' -replace '-+', '-'
            $slug = $slug.Trim('-')
            
            $indent = "  " * ($level - 2)
            $toc += "$indent* [$cleanTitle](#$slug)"
        }
    }
    return ($toc -join "`n")
}
```

---

## 5. Pre-Commit Verification Checklist for Daftar Isi

Before completing any task or document refactoring:
- [ ] **Placement Verified**: Daftar Isi is positioned immediately after the Section 0 metadata block.
- [ ] **Zero Dead Anchors**: Every link in the TOC corresponds to an existing `##`, `###`, or `####` heading.
- [ ] **Slug Accuracy**: Emoji and punctuation characters are stripped from anchor links.
- [ ] **Bidirectional Links**: Core sections provide a return link to `[⬆️ Kembali ke Daftar Isi](#-daftar-isi-table-of-contents)`.
- [ ] **Section Synchronization**: Every heading added or renamed in the document is reflected in the Daftar Isi.
