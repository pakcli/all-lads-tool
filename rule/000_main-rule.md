---
trigger: always_on
description: RULE #000 — Master Modular Architecture and Optional Standalone Toolchain Invariant
---

# RULE #000 — Master Modular Architecture & Optional Toolchain Invariant

## 1. Core Mandate: The Optional & Decoupled Toolchain Standard

`all-lads-tool/` is an **OPTIONAL, modular developer toolchain and submodule**.

The primary application and build platform (`src/`, `apps/`, `public/`) must remain **100% SELF-CONTAINED** and must run cleanly **with or without** `all-lads-tool/` present.

> [!IMPORTANT]
> **ZERO CORE HARD-DEPENDENCY**:
> 1. **Independent Core Runtime**: The core platform, client-side rendering (CSR), and compiler engine (`src/modules/build-bundle.js`) must never require, import, or depend on files inside `all-lads-tool/`.
> 2. **Safe Removal & Submodule Ignored**: If `all-lads-tool/` is omitted, excluded from `.gitignore`, unmounted, or deleted, the web app must still build, preview, and run in production with zero errors.
> 3. **Enhanced When Present**: When `all-lads-tool/` IS present, it serves as an advanced developer cockpit (interactive dispatcher `main.ps1`, Universal Git Manager, automated compliance auditor, and asset compilers).

---

## 2. The 4 Pillars Directory Categorization

Every asset inside `all-lads-tool/` is organized strictly under 4 functional pillars:

| Pillar Directory | Contents & Subfolders | Purpose |
| :--- | :--- | :--- |
| `skill/` | `*.md` files | Modular AI agent skills and operational runbooks |
| `rule/` | `*.md` files | Architectural invariants, non-negotiable coding rules, and constraints |
| `script/` | `powershell/`, `javascript/`, `python/`, `bat/` | Executable automation scripts categorized strictly by language runtime |
| `docs/` | `powershell/`, `javascript/`, `python/`, `bat/` | Versi 3 technical documentation (1 Markdown each with frontmatter & parameters) |

---

## 3. Structural Invariants

1. **Zero Upstream Couplings**: Files in `src/`, `apps/`, or `public/` must **NEVER** import or reference paths inside `all-lads-tool/`.
2. **No Root Script Clutter**: No standalone `.ps1`, `.js`, or `.bat` files may reside at the repository root (except root orchestrators `main.ps1` and `main.json`).
3. **Mirroring Documentation**: Every script inside `script/<runtime>/` must have a corresponding Markdown reference in `docs/<runtime>/<name>.md`.
4. **Four Pillars Integrity**: Files must never sit unorganized at the root of `all-lads-tool/`. All assets must belong to one of the 4 pillars.
