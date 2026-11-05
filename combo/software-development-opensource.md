---
name: software-development-opensource
aliases: [opensource-dev-combo, software-dev-stack, open-source-standards, dev-combo]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, meta-skill, workflow, standards, open-source, architecture]
description: Master composite open-source engineering standard combining ASCII tree codeblocks, commit conventions, 2-octet architectural briefs, UI/UX text wireframes, zero-emoji serious mode, anti-overengineering protocols, and zero-hardcoded path invariants.
dependencies:
  - "[[asci-tree-codeblock-standard]]"
  - "[[commit-convention]]"
  - "[[briefing-0x-0x-version]]"
  - "[[uiux-wireframe-via-text-ascii-codeblock]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[donot-overengineer-instructions]]"
  - "[[zero-hardcoded-variables]]"
related:
  - "[[obsidian-wikilink-frontmatter-standard]]"
  - "[[modular-architecture-standard]]"
pros:
  - "Standardized execution and reproducible workflow across all sub-projects"
  - "Enforces strict decoupling, portability, and system stability"
  - "Combines architectural planning, coding, wireframing, and committing into one single source of truth"
cons:
  - "Requires upfront discipline and strict specification before writing code"
  - "Restricts ad-hoc unvetted modifications and scope creep"
---

# Open-Source Software Development Meta-Skill (`software-development-opensource`)

> [!IMPORTANT]
> **THE OPEN-SOURCE COMPOSITE STANDARD**:
> This meta-skill unifies the 7 fundamental disciplines of open-source software engineering into a single cohesive lifecycle: from specification and wireframing, to zero-hardcoded implementation, clean commit history, and zero-fluff communication.

---

## 1. The 7 Core Pillars Overview

```text
┌────────────────────────────────────────────────────────────────────────┐
│             OPEN-SOURCE SOFTWARE DEVELOPMENT WORKFLOW (COMBO)          │
├────────────────────────────────────────────────────────────────────────┤
│ 1. SPECIFICATION : [[briefing-0x-0x-version]]                          │
│    -> 8 compulsory sections, 2-octet versions (v0x-0x), strict SSOT    │
│                                                                        │
│ 2. WIREFRAMING   : [[uiux-wireframe-via-text-ascii-codeblock]]         │
│    -> Character-aligned box containers, atomic elements, width budget  │
│                                                                        │
│ 3. HIERARCHY     : [[asci-tree-codeblock-standard]]                    │
│    -> Tab-indented source mode, suffix rules, aligned '#' annotations  │
│                                                                        │
│ 4. PORTABILITY   : [[zero-hardcoded-variables]]                        │
│    -> Dynamic root resolution ($PSScriptRoot, __dirname), zero C:/ D:/ │
│                                                                        │
│ 5. SCOPE DISCIPLINE : [[donot-overengineer-instructions]]              │
│    -> Zero unsolicited features, minimal clean code, single objective  │
│                                                                        │
│ 6. PROFESSIONALISM  : [[zero-emoji-serious-mode]]                      │
│    -> Factual, direct, zero decorative fluff, serious execution        │
│                                                                        │
│ 7. TRACEABILITY  : [[commit-convention]]                               │
│    -> Canonical standard: vxx-xx-xx context(ngapain): catatan          │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Pillar Deep-Dives & Interaction Matrix

### 2.1 Specification Standard — `[[briefing-0x-0x-version]]`
Before touching code, author an architectural brief under `brief/v{MAJOR}-{MINOR}_{slug}.md`:
- **Strict 2-Octet Rule**: Only `v01-00`, `v01-01`, `v02-00`. Never 3-octet tags.
- **8 Compulsory Sections**: Metadata, Daftar Isi (TOC), Invariants, Topology, Data Models/IPC, Wireframes, Deep-Dives, Build Verification.
- Acts as the immutable contract between human designers and autonomous agents.

### 2.2 UI/UX Text Wireframing — `[[uiux-wireframe-via-text-ascii-codeblock]]`
Design interfaces using atomic ASCII/Unicode box characters (`┌ ─ ┐ │ └ ┘`):
- **Desktop Budget**: `<= 80` characters width.
- **Mobile Portrait Budget**: `<= 60` characters width (Rule #2 zero horizontal scroll).
- **Atomic Components**: Present containers, buttons, inputs, splitters, and cards in isolated, reusable monospace blocks.
- **Zero Wide Emojis in Boxes**: Never put wide emojis inside bordered lines to prevent character-width misalignment.

### 2.3 Directory Hierarchy & Trees — `[[asci-tree-codeblock-standard]]`
Document codebase directories using clean, unrendered tabbed hierarchies:
- **Clean Source**: Do not hardcode branch glyphs (`├──`, `└──`) in raw markdown text. Use pure tabs or 4-space indentation.
- **Suffix Rule**: Nodes with `.ext` are leaf files; nodes without `.ext` are container folders.
- **Aligned Annotations**: Align all inline `#` comments to `longest_line + 1 space`.

### 2.4 Zero-Hardcoded Variables — `[[zero-hardcoded-variables]]`
Enforce absolute portability across all scripts (`.js`, `.ps1`, `.py`, `.sh`, `.bat`):
- **Zero Absolute Paths**: Never hardcode disk letters (`C:\`, `E:\`, `D:\`) or local user profile paths (`/Users/...`, `/home/...`).
- **Dynamic Resolution**: Resolve relative to current script root:
  - Node.js: `path.resolve(__dirname, '..', '..')`
  - PowerShell: `$PSScriptRoot` / `Resolve-Path (Join-Path $PSScriptRoot "..")`
  - Python: `Path(__file__).resolve().parent`
- **Dynamic Discovery**: Scan filesystem or query single source of truth catalogs (`_catalog.json`) rather than hardcoding static arrays.

### 2.5 Scope Discipline & Anti-Overengineering — `[[donot-overengineer-instructions]]`
- **Strict Scope Adherence**: Execute exactly what was commanded. Never invent or inject unrequested features.
- **Boundary Separation**: Keep documentation separate from code; keep dispatchers minimal and single-responsibility.
- **Propose First**: If a refactor or optimization is identified, propose it in text first; never build without explicit user consent.

### 2.6 Zero-Emoji Serious Mode — `[[zero-emoji-serious-mode]]`
- In technical execution, debugging, code comments, and formal responses: omit decorative emojis and superficial padding.
- Maintain direct, factual, and dignified technical communication.

### 2.7 Git Commit Convention — `[[commit-convention]]`
Format every git commit following the canonical standard:
```text
vxx-xx-xx context(ngapain): catatan
```
- **Contexts**: `repo`, `file`, `website`, `blender`, `unity`, `rule`, `skill`, `brief`.
- **Example**:
  ```bash
  git commit -m "v01-01-00 repo(multi-tree): implement drag-and-drop pane reordering"
  ```

---

## 3. Open-Source Execution Lifecycle Checklist

When developing or updating any open-source tool or component:

- [ ] **Frontmatter Compliance**: Are all dependencies formatted as double-quoted wikilinks (`- "[[...]]"`) per `[[obsidian-wikilink-frontmatter-standard]]`?
- [ ] **Architectural Brief**: Has a corresponding 2-octet brief (`brief/vXX-XX_*.md`) been updated per `[[briefing-0x-0x-version]]`?
- [ ] **Tree Codeblocks**: Are all file trees tab-indented with aligned `#` comments per `[[asci-tree-codeblock-standard]]`?
- [ ] **Text Wireframes**: Are interface diagrams character-aligned within width budgets per `[[uiux-wireframe-via-text-ascii-codeblock]]`?
- [ ] **Zero Hardcoded Paths**: Are all directory paths dynamically resolved relative to script roots per `[[zero-hardcoded-variables]]`?
- [ ] **Minimal Scope**: Did you build strictly what was requested with zero over-engineering per `[[donot-overengineer-instructions]]`?
- [ ] **Serious Tone**: Is the delivery factual, direct, and free of decorative emojis per `[[zero-emoji-serious-mode]]`?
- [ ] **Commit Standard**: Is the Git commit message structured as `vxx-xx-xx context(ngapain): catatan` per `[[commit-convention]]`?
