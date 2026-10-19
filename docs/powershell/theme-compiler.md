---
title: Master Theme SCSS Compiler
tool: theme-compiler.ps1
category: style & theme
runtime: PowerShell 7+
aliases: [theme-compiler, theme-compiler-tool]
tags: [all-lads-tool, powershell, style]
---

# 🛠️ `theme-compiler.ps1` — Master Theme SCSS Compiler

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Compiles theme SCSS tokens, winget styles, and cornercut floppy disk borders into production distribution.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\theme-compiler.ps1 -Target all
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Target` | string | No | `all` | Compilation target: all, theme, winget, sync |
| `-SourcePath` | string | No | `src/style` | Source SCSS directory |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/theme-compiler.ps1`](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/script/powershell/theme-compiler.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/rule/001-skills-no-hardcoded-variables.md).
