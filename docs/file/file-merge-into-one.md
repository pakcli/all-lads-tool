---
title: File Merge Into One
tool: file-merge-into-one.ps1
category: file & transformation
runtime: PowerShell 5.1+ / 7+
aliases: [file-merge, consolidate-files, combine-markdown]
tags: [all-lads-tool, file, merge, markdown, consolidation, single-file]
---

# `file-merge-into-one.ps1` — File Consolidation Engine

> [!INFO]
> **Context**: `file` | **Directory**: `all-lads-tool/script/file/`  
> **Skill**: `all-lads-tool/skill/file-merge-into-one.md`

Menggabungkan banyak catatan Markdown dari satu folder menjadi satu dokumen utuh yang terstruktur, dengan ekstraksi frontmatter otomatis, promosi heading, dan pembuatan daftar isi (TOC) terhubung.

---

## 1. Penggunaan

```powershell
# Mode Interaktif (Wizard CLI)
.\all-lads-tool\script\file\file-merge-into-one.ps1

# Direct CLI
.\all-lads-tool\script\file\file-merge-into-one.ps1 `
    -SourceDir "vault/notes/small-sections" `
    -OutputFile "vault/notes/consolidated-overview.md" `
    -HeadingLevel 2 `
    -IncludeTOC `
    -ArchiveSources
```

## 2. Fitur Utama
* **Frontmatter Aggregation**: Menyatukan tags unik dan metadata ke master frontmatter dokumen hasil gabungan.
* **TOC Generator**: Membuat daftar isi Markdown dengan anchor link (`#slug-heading`) otomatis.
* **Safe Archiving**: Menyimpan file sumber asli ke `trash-bin/` tanpa risiko permanent data loss.
