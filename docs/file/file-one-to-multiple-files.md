---
title: File One to Multiple Files
tool: file-one-to-multiple-files.ps1
category: file & transformation
runtime: PowerShell 5.1+ / 7+
aliases: [file-split, partition-markdown, promote-to-folder]
tags: [all-lads-tool, file, split, markdown, modularization, folder-promotion]
---

# `file-one-to-multiple-files.ps1` — Document Partitioning & Folder Promotion Engine

> [!INFO]
> **Context**: `file` | **Directory**: `all-lads-tool/script/file/`  
> **Skill**: `all-lads-tool/skill/file-one-to-multiple-files.md`

Memecah dokumen monolitik panjang menjadi file-file modular otonom berdasarkan pembatas heading (default `## `), menghasilkan frontmatter otomatis, nama file kebab-case bersih, dan hub navigasi `index.md`.

---

## 1. Penggunaan

```powershell
# Mode Interaktif (Wizard CLI)
.\all-lads-tool\script\file\file-one-to-multiple-files.ps1

# Direct CLI
.\all-lads-tool\script\file\file-one-to-multiple-files.ps1 `
    -SourceFile "vault/notes/big-overview.md" `
    -OutputDir "vault/notes/modular-folder" `
    -SplitHeadingLevel 2 `
    -GenerateIndex `
    -ArchiveSource
```

## 2. Fitur Utama
* **Safe Kebab Slugs**: Mengonversi judul heading menjadi nama file kebab-case tanpa merusak simbol atau emoji.
* **Index Hub Generator**: Membangun `index.md` otomatis berisi tautan wikilink ke semua file pecahan.
* **Preamble Protection**: Teks pembuka sebelum heading pertama disimpan rapi di dalam `index.md`.
