---
title: Clean Web Project Workspace Synchronizer
tool: ps_sync-cwp.ps1
category: workspace & sync
runtime: PowerShell 7+
aliases: [ps_sync-cwp, ps_sync-cwp-tool]
tags: [all-lads-tool, powershell, workspace]
---

# 🛠️ `ps_sync-cwp.ps1` — Clean Web Project Workspace Synchronizer

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Synchronizes shared clean web project assets, styles, and configurations across external sibling repositories.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\ps_sync-cwp.ps1 -DryRun
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Target` | string | No | `all` | Sync profile target defined in ps_sync-cwp.json |
| `-DryRun` | switch | No | `false` | Simulates copy and sync operations without writing |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/ps_sync-cwp.ps1`](..\../script/powershell/ps_sync-cwp.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
