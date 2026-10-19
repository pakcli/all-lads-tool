---
title: CSS to SCSS Theme Converter
tool: compile-single-css-to-scss.ps1
category: style & theme
runtime: PowerShell 7+
aliases: [compile-single-css-to-scss, compile-single-css-to-scss-tool]
tags: [all-lads-tool, powershell, style]
---

# 🛠️ `compile-single-css-to-scss.ps1` — CSS to SCSS Theme Converter

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Converts single CSS stylesheets (such as Obsidian theme.css) to clean, compact AI-readable SCSS source format.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\compile-single-css-to-scss.ps1 -Source "src/style/theme.css"
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Source` | string | No | `theme.css` | Path to source CSS stylesheet |
| `-Mode` | int | No | `0` | Mode 0: Direct 1:1 conversion, Mode 1: Theme Compact SCSS |
| `-Backup` | switch | No | `true` | Preserves timestamped backup before conversion |
| `-Force` | switch | No | `false` | Overwrites existing target files without confirmation |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/compile-single-css-to-scss.ps1`](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/script/powershell/compile-single-css-to-scss.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/rule/001-skills-no-hardcoded-variables.md).
