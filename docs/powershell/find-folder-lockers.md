---
title: Windows Process & Folder Lock Detector
tool: find-folder-lockers.ps1
category: system & debugging
runtime: PowerShell 7+
aliases: [find-folder-lockers, find-folder-lockers-tool]
tags: [all-lads-tool, powershell, system]
---

# 🛠️ `find-folder-lockers.ps1` — Windows Process & Folder Lock Detector

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Scans for file handles, open Restart Manager locks, and process current working directories (CWD) blocking folder renames or deletions.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\find-folder-lockers.ps1 -TargetPath ".\all-lads-tool"
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-TargetPath` | string | No | `repo root` | Path to directory or file being locked |
| `-Kill` | switch | No | `false` | Interactively terminates detected locking processes |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/find-folder-lockers.ps1`](..\../script/powershell/find-folder-lockers.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
