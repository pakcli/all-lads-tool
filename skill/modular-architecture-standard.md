---
description: RULE #000 – Master Modular Architecture, Pillar Boundaries, and Optional Toolchain Invariant
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE #000 – Master Modular Architecture & Pillar Boundaries Invariant

## 1. Core Mandate: The Optional & Decoupled Toolchain Standard

`all-lads-tool/` is an **OPTIONAL, modular developer toolchain and submodule**.

The primary application and build platform (`src/`, `apps/`, `public/`) must remain **100% SELF-CONTAINED** and must run cleanly **with or without** `all-lads-tool/` present.

> [!IMPORTANT]
> **ZERO CORE HARD-DEPENDENCY**:
> 1. **Independent Core Runtime**: The core platform, client-side rendering (CSR), and compiler engine (`src/modules/build-bundle.js`) must never require, import, or depend on files inside `all-lads-tool/`.
> 2. **Safe Removal & Submodule Ignored**: If `all-lads-tool/` is omitted, excluded from `.gitignore`, unmounted, or deleted, the web app must still build, preview, and run in production with zero errors.
> 3. **Enhanced When Present**: When `all-lads-tool/` IS present, it serves as an advanced developer cockpit (interactive dispatcher `_mainmenu.ps1`, Universal Git Manager `ps_git-manage.ps1`, automated compliance auditor, and asset compilers).

---

## 2. Definitive Boundary: `rule/` vs `skill/`

To prevent conceptual mixing and governance confusion, the boundary between `rule/` and `skill/` is strictly defined as follows:

| Dimension | `rule/` (Active Governance) | `skill/` (Capability Library) |
| :--- | :--- | :--- |
| **Definition** | **Enforced constraints & invariants** that apply strictly to the CURRENT `all-lads-tool` repository. | **A reusable library of skills**, operational runbooks, and domain procedures available for agents & developers. |
| **Scope** | Active, non-negotiable, and always-on rules governing all workspace files, naming, and architectures. | On-demand capability catalog. Skills are referenced or activated when a specific task is triggered. |
| **Intent** | *"What you MUST and MUST NOT do in this project right now."* | *"HOW to execute specialized tasks, techniques, and procedures."* |
| **Examples** | `001_skills-no-hardcoded-variables.md`<br/>`004_naming.md` | `markdown-obsidian-format-compatibility.md`<br/>`naming-convention-standard.md`<br/>`playwright-thumbnail-capture.md` |

> [!TIP]
> **Rule of Thumb**:
> - If it **restricts, prohibits, or dictates project-wide standards** for `all-lads-tool` $\rightarrow$ place it in `rule/`.
> - If it is a **reusable manual, procedural guide, or actionable technique** $\rightarrow$ place it in `skill/`.

---

## 3. The 4 Pillars Directory Categorization

Every asset inside `all-lads-tool/` is organized strictly under 4 functional pillars:

| Pillar Directory | Contents & Subfolders | Purpose |
| :--- | :--- | :--- |
| `rule/` | `*.md` files (numbered `000`–`009`) | Non-negotiable architectural invariants and active workspace constraints. |
| `skill/` | `*.md` files (kebab-case) | Modular capability library, agent skills, and specialized execution runbooks. |
| `script/` | `powershell/`, `javascript/`, `python/`, `bat/`, `bash/` | Executable automation scripts categorized strictly by language runtime. |
| `docs/` | `powershell/`, `javascript/`, `python/`, `bat/`, `bash/` | Mirror technical documentation (1 Markdown each with frontmatter & parameters). |

---

## 4. Structural Invariants

1. **Zero Upstream Couplings**: Files in `src/`, `apps/`, or `public/` must **NEVER** import or reference paths inside `all-lads-tool/`.
2. **No Root Script Clutter**: No standalone `.ps1`, `.js`, `.py`, `.sh`, or `.bat` files may reside at the repository root (except root orchestrators `_mainmenu.ps1` and `_mainmenu.json`).
3. **Mirroring Documentation**: Every tool must have a single canonical Markdown reference in `docs/<runtime>/<slug>.md` documenting both standalone (`_stand`) and modular editions. Do **NOT** create duplicate `_stand.md` files in `docs/`.
4. **Four Pillars Integrity**: Files must never sit unorganized at the root of `all-lads-tool/`. All assets must belong to one of the 4 pillars.
