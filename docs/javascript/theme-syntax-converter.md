---
title: Obsidian Theme CSS/SCSS Syntax Converter
tool: theme-syntax-converter.js
category: style & syntax
runtime: Node.js
aliases: [theme-syntax-converter, theme-syntax-converter-tool]
tags: [all-lads-tool, javascript, style]
---

# 🛠️ `theme-syntax-converter.js` — Obsidian Theme CSS/SCSS Syntax Converter

> [!INFO]
> **Runtime**: Node.js | **Directory**: `all-lads-tool/script/javascript/`

Bidirectional syntax converter between heavy Obsidian theme CSS rules and compact AI-readable SCSS format.

---

## 1. Quick Syntax & Usage

```powershell
node all-lads-tool/script/javascript/theme-syntax-converter.js --mode css2scss --input theme.css
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `--mode` | string | Yes | `css2scss` | Conversion mode: css2scss or scss2css |
| `--input` | string | Yes | `""` | Source file path |
| `--output` | string | No | `stdout` | Destination file path |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/javascript/theme-syntax-converter.js`](..\../script/javascript/theme-syntax-converter.js)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
