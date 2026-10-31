---
name: program-standalone
aliases: [standalone-executable-standard, single-file-distribution]
category: ARCHITECTURAL_PATTERN
tags: [all-lads-tool, standalone, distribution, zero-dependency, portability]
description: Standard architectural specification for compiled single-file executables (<program>_stand.<ext>) designed for zero-dependency portability and instant drag-and-drop execution.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Program Standalone Specification (`program-standalone`)

> [!IMPORTANT]
> **STANDALONE EXECUTABLE INVARIANT**:
> A `<program>_stand.<ext>` file is a compiled, immutable build distribution.
> It MUST contain all necessary runtime adapters, helpers, and syntax inlined within its single file boundary.
> It MUST run cleanly when moved outside the repository, with zero sibling folders required.

---

## 1. File Naming Standard

$$\text{<program-slug>\_stand.<extension>}$$

- **PowerShell**: `csv-to-frontmatter_stand.ps1`, `git-manage_stand.ps1`
- **Python**: `fbx-export_stand.py`
- **JavaScript**: `build-bundles_stand.js`
- **Batch**: `start-chrome-cwp_stand.bat`

---

## 2. Invariant Rules
1. **Zero External Module Imports**: Must not contain `Import-Module`, `from adapter import`, or `require()` to local sibling folders.
2. **Built-in Self-Diagnosis**: Includes its own embedded environment checker.
3. **Distribution Ready**: Suitable for emailing, flash drives, or copying directly into external target projects.
