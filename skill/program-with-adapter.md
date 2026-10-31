---
name: program-with-adapter
aliases: [modular-adapter-pattern, dev-mode-architecture]
category: ARCHITECTURAL_PATTERN
tags: [all-lads-tool, modular, adapter, architecture, versioning, development]
description: Architectural standard for authoring modular development programs (<program>.<ext>) that delegate version-specific syntax and breaking API changes to self-contained files under adapter/vxx-xx-xx.<ext>.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Program with Adapter Specification (`program-with-adapter`)

> [!IMPORTANT]
> **MODULAR ADAPTER INVARIANT**:
> The development source file (`<program>.<ext>`) must remain lean, readable, and free of massive `if-else` version branching.
> All version-specific logic, breaking API formulas, and environment checks must reside inside `adapter/vxx-xx-xx.<ext>`.

---

## 1. Directory Layout

```text
script/<context>/
├── <program>.<ext>                # Clean orchestrator (< 50 lines)
└── adapter/
    ├── v03-06-00.<ext>            # Full adapter for version 3.6
    └── v04-02-00.<ext>            # Full adapter for version 4.2
```

---

## 2. Dynamic Dispatch Pattern

The source program identifies the active environment version at runtime and dynamically imports the matching adapter:

```powershell
# PowerShell Example:
$adapterPath = Join-Path $PSScriptRoot "adapter\$resolvedVersion.psm1"
Import-Module -LiteralPath $adapterPath
Invoke-PipelineAction
```

---

## 3. Maintenance Rules
- When supporting a new software version (e.g. Blender 5.0 or Unity 6), developers **ONLY add a new adapter file** (`adapter/v05-00-00.ext`).
- The base `<program>.<ext>` orchestrator remains untouched, preventing regressions.
