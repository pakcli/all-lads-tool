---
title: SCSS to CSS Theme Compiler
tool: compile-single-scss-to-css.ps1
category: style & theme
runtime: PowerShell 7+
aliases: [compile-single-scss-to-css, compile-single-scss-to-css-tool]
tags: [all-lads-tool, powershell, style]
---

# 🛠️ `compile-single-scss-to-css.ps1` — SCSS to CSS Theme Compiler

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Compiles single SCSS stylesheets back into production-grade CSS while enforcing theme immutability rules.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\compile-single-scss-to-css.ps1 -Source "src/style/theme.scss"
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Source` | string | No | `theme.scss` | Target SCSS file to compile |
| `-Mode` | int | No | `0` | Compilation mode: Direct vs Obsidian theme processor |
| `-Minify` | switch | No | `false` | Minifies output CSS eliminating redundant whitespace |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/compile-single-scss-to-css.ps1`](..\../script/powershell/compile-single-scss-to-css.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
