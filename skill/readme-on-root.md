---
description: RULE #005 — README.md Always on Root of the Project Repository
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE #005 — Root README.md Invariant

## 1. Core Invariant (The Root README Mandate)

A master, comprehensive `README.md` must **ALWAYS** exist directly at the root of the project repository (`./README.md`).

> [!IMPORTANT]
> **ROOT README INVARIANTS**:
> 1. **Primary Single Source of Truth**: The root `README.md` is the authoritative entry point for developers, users, and automated AI agents cloning or inspecting the repository.
> 2. **Immutability of Root Location**: `README.md` at root must **never** be deleted, moved into subdirectories, or replaced by symlinks.
> 3. **Subfolder Documentation Hierarchy**: Sub-documentation in subfolders (`docs/`, `all-lads-tool/docs/`, `apps/`) provides deep-dive technical references, but must always link back to the root `README.md`.

---

## 2. Mandatory Root README Structure (7 Essential Sections)

Every project root `README.md` must contain the following 7 core sections:

1. **Header & Project Identity**: Title, badges, quick summary, and visual preview.
2. **Overview & Vision**: Problem solved, core philosophy, and zero-dependency principles.
3. **Architecture Topology**: Visual directory tree showing `src/`, `apps/`, `public/`, and optional `all-lads-tool/`.
4. **Quickstart & Installation**: Prerequisites, installation commands, and build commands.
5. **Developer Cockpit & Toolchain**: Instructions for `main.ps1`, `main.env`, and automation dispatchers.
6. **Key Technical Specifications**: Core size metrics, Rule #001-#005 compliance, and offline/airgap capabilities.
7. **License & Credits**: Open source MIT license and author attribution.

---

## 3. Enforcement & Verification Checklist

Before completing any task or releasing a milestone:
- [ ] Verify that `README.md` exists directly at the repository root (`./README.md`).
- [ ] Verify that all internal links from root `README.md` point to valid relative repository paths.
- [ ] Ensure `all-lads-tool/` or other submodules have their own internal docs but do NOT strip the root `README.md`.
