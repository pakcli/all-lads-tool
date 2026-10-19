---
name: architectural-brief-specification
description: >-
  Standardized protocol for structuring, writing, and maintaining monolithic-to-modular architectural brief documents (brief/vXX-XX_<name>.md) for AI coding assistants. Enforces mandatory sections, frontmatter metadata, Table of Contents (Daftar Isi), single source of truth directory trees, UI/UX monospace text wireframes, ASCII data flow diagrams, zero-backend constraints, code blocks with syntax highlighting, and lifecycle version bump synchronizations.
---

# 📐 Architectural Brief Specification & Authoring Standard

This skill establishes the mandatory blueprint and structural checklist for AI coding assistants authoring, refactoring, or updating architectural briefs (stored under `brief/vXX-XX_<milestone>.md`).

An architectural brief is the **immutable contract and single source of truth (SSOT)** between human designers, project owners, and autonomous AI programmer agents. Every brief must translate high-level vision into zero-ambiguity visual, behavioral, and structural engineering specifications.

---

## 1. Naming & Lifecycle Version Synchronization



- **File Path Pattern**: `brief/v{MAJOR}-{MINOR}_{slug-descriptor}.md` (Strictly 2 octets: `0x-0x`)
- **Strict 2-Octet Rule (`0x-0x`)**: Versions must strictly contain **no more than 2 octets** (`0x-0x` / `v0x-0x`), e.g., `v01-01`, `v01-02`, `v01-03`, `v01-04`, `v02-00`. Three-octet versions (such as `01-03.1` or `v01_03.2`) are strictly forbidden.
- **Examples**:
  - `brief/v01-01_uiux-impovment.md` (Master Floppy Hero & CLI Navbar)
  - `brief/v01-02_modular-slidev-hybrid.md` (Slidev Engine & Dynamic Markdown)
  - `brief/v01-03_bento-layout-playground.md` (Bento Split-Screen & Unified Build Pipeline)
- **Synchronization Rule**: Whenever a milestone or major architecture feature changes, the corresponding brief must be created or updated, referencing prior baseline briefs in its header.

---

## 2. Anatomy of a Compliant Brief: The 8 Compulsory Sections

Every architectural brief authored by an AI agent must contain the following 8 structural sections in exact sequential order:

```text
┌────────────────────────────────────────────────────────────────────────┐
│ SECTION 0: TITLE & METADATA BLOCK (Version, Baselines, Objectives)     │
├────────────────────────────────────────────────────────────────────────┤
│ SECTION 1: DAFTAR ISI / TABLE OF CONTENTS (Interactive GitHub Anchors) │
├────────────────────────────────────────────────────────────────────────┤
│ SECTION 2: ARCHITECTURAL DIRECTIVES & INVARIANTS (Rules)               │
├────────────────────────────────────────────────────────────────────────┤
│ SECTION 3: DIRECTORY TOPOLOGY & BOUNDARIES (Root vs. Src vs. Public)   │
├────────────────────────────────────────────────────────────────────────┤
│ SECTION 4: DATA MODELS & YAML FRONTMATTER ENGINE (Zero `id:` Standard) │
├────────────────────────────────────────────────────────────────────────┤
│ SECTION 5: UI/UX TEXT WIREFRAMES (Desktop & Mobile Portrait Monospace) │
├────────────────────────────────────────────────────────────────────────┤
│ SECTION 6: SUBSYSTEM DEEP-DIVES (CSS Grid, TTS, Sandboxes)             │
├────────────────────────────────────────────────────────────────────────┤
│ SECTION 7: UNIFIED BUILD PIPELINE & VERIFICATION (Build Script, Audit) │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Structural Standards for Each Section

### Section 0: Title & Metadata Block
Always begin with a top-level `#` title followed by a blockquote containing:
- **Version**: `vXX-XX`
- **Baseline References**: Clickable markdown links to previous briefs or skills.
- **Primary Objectives**: A numbered list (3 to 6 items) defining the core milestones of this brief.

```markdown
# Vintage Computing Arcade — Bento Split-Screen Playground (`v01-03_bento-layout-playground`)

> **Version**: `v01-03` (Minor Lifecycle UI/UX, Slidev Right Panel & Catalog Milestone)  
> **Baseline References**:  
> - [`brief/v01-01_uiux-impovment.md`](file:///path/to/brief/v01-01.md)  
> - [`brief/v01-02_modular-slidev-hybrid.md`](file:///path/to/brief/v01-02.md)  
> **Primary Objectives**:
> 1. Zero-Outer-Scroll 6-Cell Bento Split-Screen Playground.
> 2. Unified Compiler Engine (`src/modules/build-bundle.js`).
```

---

### Section 1: Table of Contents (`## 📑 DAFTAR ISI (TABLE OF CONTENTS)`)
- Must sit directly after the metadata block and before Section 1.
- Must link to every major heading (`##`) and sub-heading (`###`) using GitHub-compatible Markdown anchors.
- Ensures instant navigation for both human reviewers and AI agents reading line ranges.

---

### Section 2: Architectural Directives & Invariants
Enforce the project's non-negotiable rules. In this repository, that includes:
- **RULE #1**: Theme stylesheet (`src/style/theme/vintage-computer/theme.css`) is **100% UNTOUCHED (0 edits allowed)**.
- **RULE #2**: Mobile Portrait (`320px – 768px`) requires **ZERO Horizontal Scroll** (`overflow-x: clip; minmax(0, 1fr)`).
- **RULE #3**: Modular Skill-Rules: **ZERO hardcoded project-specific or machine-specific variables** (`d:/0pro/...`, hardcoded lists, session states). All modules must be dynamically discovered and parameterized.
- **Strict ZERO `id:` Standard**: All identifiers derived strictly from file basenames (`slug = filename.replace(/\.md$/, '')`).

---

### Section 3: Directory Topology & Boundary Definitions
Always provide an ASCII directory tree with file-level comments separating:
1. **Root Source of Truth** (`apps/` in root, never in `src/`).
2. **Platform Source** (`src/` containing shells, components, modules, styles).
3. **Production Distribution** (`public/` containing compiled bundles, HTML shells, and compiled catalogs).

```text
fadhlisl-my-id/
├── apps/                        # Single Source of Truth (Root Directory)
│   ├── radiansincostan/         # Self-contained cartridge subfolders
│   └── vibe-arcade-deck/
├── src/                         # Source Code only (Zero apps/ directory)
│   ├── modules/build-bundle.js  # Compiler engine script
│   └── modules/catalog-core.js  # Dynamic CSR catalog loader
└── public/                      # Production compiled artifacts
    ├── apps/_catalog.json       # Master compiled index
    └── page-apps.js             # Client distribution bundle
```

---

### Section 4: Data Models & Frontmatter Specification
Document the YAML frontmatter format with before/after comparisons, explaining the parsing logic and client-side rendering (CSR) lifecycle:
- Provide explicit YAML snippets.
- Show the Mermaid state diagram or flowchart illustrating how raw markdown or JSON flows to the DOM.

---

### Section 5: UI/UX Monospace Text Wireframes
A brief without wireframes causes AI design drift. Every brief **MUST** include monospace ASCII text wireframes for:
1. **Desktop Viewport (`>= 900px`)**: Showing complete grid layouts, headers, sidebars, resizer gutters, and status docks.
2. **Mobile Portrait Viewport (`320px – 768px`)**: Showing stacked single-column or 2-column compact grid views, tap targets, and pinned elements.

#### Wireframe Formatting Rules:
- Use Unicode box-drawing characters: `┌ ─ ┐ │ └ ┘ ├ ┤ ┬ ┴ ┼ ╻ ┃ ╹ ◀ ▶ ▲ ▼`.
- Label interactive elements clearly: `[ Button ]`, `[⌕ Search]`, `[★ PIN]`.
- Note responsive behaviors inline (e.g. `(Flex: 1 — Zero Scrollbars)`).

---

### Section 6: Subsystem Deep-Dives
Provide focused, concrete technical breakdowns for every complex subsystem introduced in the milestone:
- **CSS Layout Algorithms**: Grid template rules, flex shrink/grow factors, inverse-dimension zoom math (`calc(100% / var(--zoom))`).
- **JavaScript State Engines**: Caching tiers (Public ➔ LocalStorage ➔ Dynamic Tokenizer), FNV-1a hash calculation, event delegation.
- **Component Code Snippets**: Real, working code snippets demonstrating implementation standards.

---

### Section 7: Unified Build Pipeline & Verification
Every brief must conclude with explicit compilation instructions and syntax verification commands:
- The exact node or build command:
  ```bash
  node src/modules/build-bundle.js
  ```
- Output bundle audit table with filenames, module contents, and expected byte sizes.
- Static verification commands:
  ```bash
  node -c public/page-apps.js public/page-playground.js public/winget.js
  ```
- Pass criteria: Zero warnings, zero syntax errors, and zero console exceptions.

---

## 4. AI Programmer Agent Checklist

Before completing any brief-authoring or brief-updating task, verify:
- [ ] Is there an interactive **Table of Contents (Daftar Isi)** at the top?
- [ ] Are all references to superseded identifiers (e.g. legacy `id:` values like `ksi`) eliminated in favor of clean slugs (`radiansincostan`)?
- [ ] Are the directory trees completely aligned with root `apps/`, zero `src/apps/`, and compiled `public/apps/`?
- [ ] Are both Desktop and Mobile UI/UX wireframes drawn with monospace box characters?
- [ ] Are the non-negotiables (Rule #1 immutable theme, Rule #2 zero horizontal scroll) prominently reinforced?
- [ ] Did you test and execute the build pipeline (`node src/modules/build-bundle.js`) to guarantee the documented files exist and pass syntax validation?