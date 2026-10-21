---
title: Clean Web Project Workspace Opener
tool: ps_open-cwp.ps1
category: workspace
runtime: PowerShell 7+
aliases: [ps_open-cwp, ps_open-cwp-tool]
tags: [all-lads-tool, powershell, workspace]
---

# 🛠️ `ps_open-cwp.ps1` — Clean Web Project Workspace Opener

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Launches project workspace with isolated browser profiles and development server bindings.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\ps_open-cwp.ps1
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Port` | int | No | `8080` | Target local HTTP server port |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/ps_open-cwp.ps1`](..\../script/powershell/ps_open-cwp.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
