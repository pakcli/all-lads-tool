---
title: Git Submodule Manager
tool: manage-submodule.ps1
category: git & submodules
runtime: PowerShell 7+
aliases: [manage-submodule, manage-submodule-tool]
tags: [all-lads-tool, powershell, git]
---

# 🛠️ `manage-submodule.ps1` — Git Submodule Manager

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Zero-hardcoded-path Git Submodule utility supporting adding, updating, syncing, listing, and cleanly removing submodule repositories.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\manage-submodule.ps1 -Action list
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Action` | string | Yes | `""` | Operation: add, update, sync, status, list, remove |
| `-Url` | string | Cond | `""` | Git repository URL when adding submodules |
| `-Path` | string | Cond | `""` | Destination directory relative to repo root |
| `-Branch` | string | No | `main` | Target branch to track for updates |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/manage-submodule.ps1`](..\../script/powershell/manage-submodule.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
