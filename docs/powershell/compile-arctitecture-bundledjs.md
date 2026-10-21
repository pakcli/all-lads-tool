---
title: Architecture & Bundled JS Compactor
tool: compile-arctitecture-bundledjs.ps1
category: build & compaction
runtime: PowerShell 7+
aliases: [compile-arctitecture-bundledjs, compile-arctitecture-bundledjs-tool]
tags: [all-lads-tool, powershell, build]
---

# 🛠️ `compile-arctitecture-bundledjs.ps1` — Architecture & Bundled JS Compactor

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Compiles and minifies modular client JS architecture into compact public distribution bundles reading declarative targets from build.json.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\compile-arctitecture-bundledjs.ps1 -Target all -CompactionLevel ultra
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Target` | string | No | `all` | Build target: all, apps, playground, or winget |
| `-CompactionLevel` | string | No | `normal` | Compaction intensity (normal, ultra, none) |
| `-Report` | switch | No | `true` | Generates detailed file-size audit table in terminal |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/compile-arctitecture-bundledjs.ps1`](..\../script/powershell/compile-arctitecture-bundledjs.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
