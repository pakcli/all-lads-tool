---
title: Automated Codebase Compliance Auditor
tool: audit-codebase.js
category: quality & audit
runtime: Node.js 18+
aliases: [audit-codebase, audit-tool, compliance-checker]
tags: [all-lads-tool, javascript, audit, compliance, verification]
---

# 🛠️ `audit-codebase.js` — Automated Codebase Compliance Auditor

> [!INFO]
> **Runtime**: Node.js 18+ | **Directory**: `all-lads-tool/script/javascript/`

Performs deep automated compliance scanning across files, auditing for hardcoded paths (Rule #001), strict naming conventions (Rule #004), Obsidian YAML frontmatter quote violations, and UI/UX ASCII monospace wireframe budgets.

---

## 1. Quick Syntax & Usage

```bash
# Audit all-lads-tool/ directory (default)
node all-lads-tool/script/javascript/audit-codebase.js

# Audit a specific target directory or app cartridge
node all-lads-tool/script/javascript/audit-codebase.js apps/radiansincostan
```

---

## 2. Verified Invariant Rules

| Metric | Target Rule | Invariant Constraint |
| :--- | :--- | :--- |
| **Rule #001** | [Zero Hardcoded Variables](..\../rule/001-skills-no-hardcoded-variables.md) | No disk drive letters (`D:\`, `C:\`) or static app arrays |
| **Rule #004** | [Repository Naming Conventions](..\../rule/004_naming.md) | Strict lowercase kebab-case for all files & directories |
| **Rule #005** | [Root README.md Invariant](..\../rule/005_readme-on-root.md) | Master README.md must always reside at repository root |
| **Obsidian** | [Obsidian Markdown Compatibility](..\../skill/markdown-obsidian-format-compatibility.md) | Zero double quotes (`"..."`) in YAML frontmatters |
| **UI/UX** | [Monospace ASCII Wireframes](..\../skill/uiux-wireframe-via-text-ascii-codeblock.md) | Monospace box boundary alignment, `<= 80` cols, zero wide emojis |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/javascript/audit-codebase.js`](..\../script/javascript/audit-codebase.js)
* **Skill Reference**: [`all-lads-tool/skill/codebase-compliance-audit.md`](..\../skill/codebase-compliance-audit.md)
