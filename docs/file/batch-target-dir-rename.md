---
title: Batch Target-Dir Markdown Renamer
tool: batch-target-dir-rename.ps1
category: file & batch rename
runtime: PowerShell 5.1+ / 7+
aliases: [batch-target-dir-rename, frontmatter-renamer, kebab-renamer]
tags: [all-lads-tool, file, frontmatter, kebab-case, rename, batch, markdown]
---

# `batch-target-dir-rename.ps1` — Batch Target-Dir Markdown Renamer

> [!INFO]
> **Context**: `file` | **Directory**: `all-lads-tool/script/file/`
> **Adapters**:
> - `adapter/batch-file-renamer.psm1`
> - `adapter/frontmatter-title-parser.psm1`
> - `adapter/kebab-case-converter.psm1`

Menyediakan otomasi penggantian nama file Markdown dalam sebuah direktori secara massal berdasarkan metadata `title:` yang tertulis di dalam YAML Frontmatter.

---

## 1. Varian Mode Eksekusi

### A. Master Interactive Cockpit
```powershell
.\all-lads-tool\script\file\batch-target-dir-rename.ps1 -TargetDir "vault/notes"
```

### B. Mode 1: Rename Berdasarkan Raw Title
```powershell
.\all-lads-tool\script\file\batch-target-dir-rename-based-on-frontmatter-markdown-title.ps1 -TargetDir "vault/notes" -DryRun
```

### C. Mode 2: Rename Berdasarkan Title -> Kebab-Case
```powershell
.\all-lads-tool\script\file\batch-target-dir-rename-based-on-frontmatter-markdown-title-kebab-case.ps1 -TargetDir "vault/notes"
```

### D. Mode 3: Rename Kebab-Case DAN Sinkronkan Frontmatter
```powershell
.\all-lads-tool\script\file\batch-target-dir-rename-frontmatter-markdown-kebab-case-and-rename-file.ps1 -TargetDir "vault/notes"
```

---

## 2. Invariants & Fitur Keamanan
- **Dry-Run Preview (`-DryRun`)**: Menampilkan tabel ASCII perbandingan nama lama vs nama baru tanpa menyentuh disk fisik.
- **Git-Aware (`git mv`)**: Jika direktori berada di bawah Git, file otomatis di-rename menggunakan `git mv` agar riwayat commit tidak terputus.
- **Collision Protection**: Otomatis mendeteksi jika nama tujuan sudah ada, mencegah file ter-overwrite secara tidak sengaja.
