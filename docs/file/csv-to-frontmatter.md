---
title: CSV to Frontmatter Converter
tool: csv-to-frontmatter.ps1
category: file & transformation
runtime: PowerShell 5.1+ / 7+
aliases: [csv-to-frontmatter, frontmatter-converter]
tags: [all-lads-tool, file, csv, yaml, frontmatter, obsidian]
---

# `csv-to-frontmatter.ps1` — CSV to YAML Frontmatter Converter

> [!INFO]
> **Context**: `file` | **Directory**: `all-lads-tool/script/file/`
> **Adapter**: `all-lads-tool/script/file/adapter/universal.psm1`

Mengonversi baris tabel CSV menjadi dokumen Markdown individual dengan YAML frontmatter yang 100% kompatibel dengan Obsidian.

---

## 1. Penggunaan

```powershell
# Interaktif
.\all-lads-tool\script\file\csv-to-frontmatter.ps1

# Direct CLI
.\all-lads-tool\script\file\csv-to-frontmatter.ps1 -TargetDir "vault/notes" -TargetCsv "data.csv"
```
