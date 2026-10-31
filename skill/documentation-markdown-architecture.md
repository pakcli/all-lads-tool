---
name: documentation-markdown-architecture
aliases: [doc-architecture, doc-markdown-standards, markdown-architecture-spec]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, skill, documentation, architecture, brief, guide, readme, docs, bilingual-rules]
description: Authoritative specification for repository documentation architecture defining the 4 core tiers (brief/, docs/, guide.md, README.md) and strict language invariants (bilingual for README/GUIDE; strictly English for brief/ and docs/).
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 📚 Repository Documentation Markdown Architecture (`documentation-markdown-architecture`)

> [!INFO]
> **Core Architecture**: The 4-Tier Documentation Standard.  
> **Strict Language Invariant**:  
> - **Bilingual (English Default + Indonesian Secondary)**: ONLY `README.md` and `GUIDE.md` (filename MUST be all-caps).  
> - **Strictly English**: `brief/` and `docs/`.

This skill defines the universal documentation typology, directory boundaries, and language rules across all projects and repositories.

---

## 1. The 4-Tier Documentation Architecture

Every repository enforces a clean separation of concerns across 4 distinct document tiers:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   REPOSITORY DOCUMENTATION TYPOLOGY                    │
├────────────────────────────────────────────────────────────────────────┤
│ 1. README.md           : Front door, product pitch, overview & license │
│ 2. GUIDE.md            : Actionable runbook, install, usage & debug    │
│ 3. brief/v0x-0x_*.md   : Architectural contracts, topologies, SSOT RFC │
│ 4. docs/<per-module>/  : Deep-dive technical references & API specs    │
└────────────────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> **ALL CAPS INVARIANT**: The filename for the user guide must strictly be in all caps: **`GUIDE.md`**, perfectly mirroring **`README.md`** at the repository root.

---

## 2. Strict Language Policy & Invariants

To maintain global accessibility while supporting local development teams, language scope is strictly bounded:

| Document Tier | File Path Standard | Language Policy | Navigation Header Requirement |
| :--- | :--- | :---: | :--- |
| **Front Door** | `./README.md` (Root) | **Bilingual** (English 1st, Indo 2nd) | `[English](#-english) \| [Bahasa Indonesia](#-bahasa-indonesia)` |
| **User Guide** | `./GUIDE.md` (Root, All-Caps) | **Bilingual** (English 1st, Indo 2nd) | `[English](#-english) \| [Bahasa Indonesia](#-bahasa-indonesia)` |
| **Architectural Brief** | `brief/v0x-0x_<slug>.md` | **Strictly English** (100%) | Single English Table of Contents |
| **Technical Specs** | `docs/<module>/<slug>.md`| **Strictly English** (100%) | Single English Table of Contents |

> [!CAUTION]
> **Zero Indonesian in `brief/` and `docs/`**:  
> Architectural briefs and per-module technical documentation must be written **100% in professional English**.  
> Indonesian translation is strictly quarantined to `README.md` and `guide.md`.

---

## 3. Tier-by-Tier Specification

### Tier 1: `README.md` (Repository Root)
* **Mission**: Welcomes users, explains *what* the project is, *why* it matters, and *who* it is for.
* **4 Pillars**:
  1. Overview: Target audience ("Untuk Siapa"), value proposition ("Bagus Kenapa"), example use cases ("Case Contoh").
  2. Features: Key highlights (3–6 bullets).
  3. How It Works: Short flow/diagram + prominent direct link to `guide.md`.
  4. License: Open-source license terms.
* **Language Layout**: Full English section first (`## 🇬🇧 English`), horizontal divider (`---`), followed by full Indonesian section (`## 🇮🇩 Bahasa Indonesia`).

### Tier 2: `guide.md` (Repository Root)
* **Mission**: The hands-on operational runbook for developers, operators, and users.
* **Core Content**:
  1. Prerequisites (minimum tool versions).
  2. 60-Second Quickstart.
  3. Granular Step-by-Step execution walkthroughs (Mode 1, Mode 2, Mode 3, etc.).
  4. Build-time environment variables & custom configurations.
  5. Troubleshooting & FAQ (exact error messages and copy-paste resolutions).
* **Language Layout**: Full English runbook first (`## 🇬🇧 English Guide`), followed by full Indonesian translation (`## 🇮🇩 Panduan Operasional`).

### Tier 3: `brief/v0x-0x_<name>.md` (Quarantined Architectural Contracts)
* **Mission**: Single Source of Truth (SSOT) engineering contracts between humans and AI programmer agents.
* **Naming**: Strictly 2-octet versioning (`v01-01_<name>.md`, `v01-02_<name>.md`). 3-octet versions are prohibited.
* **Language**: **Strictly English**.
* **Table of Contents**: Formatted as `## 📑 Table of Contents` with return links `[⬆️ Back to Table of Contents](#-table-of-contents)`.
* **Quarantine Invariant**: Always excluded from public production static HTML (`ignorePatterns: ["brief"]`).

### Tier 4: `docs/<module-or-element>/<slug>.md` (Technical Deep-Dives)
* **Mission**: 1-to-1 mirror technical documentation for specific scripts, runtime engines, modules, or UI elements.
* **Structure**: Command-line parameter tables, return codes, input/output contracts, code block implementations.
* **Language**: **Strictly English**.

---

## 4. Pre-Commit Compliance Checklist

Before finalizing any documentation PR or task:
- [ ] `README.md` is bilingual (English 1st, Indonesian 2nd) with working anchor jump links.
- [ ] `guide.md` is bilingual (English 1st, Indonesian 2nd) with working anchor jump links.
- [ ] All files in `brief/` match `v0x-0x_<name>.md` and are **100% strictly English**.
- [ ] All files in `docs/` are **100% strictly English**.
- [ ] No installation shell scripts or long terminal walkthroughs pollute `brief/` (they are in `guide.md`).
- [ ] `README.md` and `guide.md` reside at the repository ROOT.
