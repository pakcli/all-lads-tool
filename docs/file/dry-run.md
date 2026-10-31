---
title: Dry-Run Script Simulator
tool: dry-run.ps1
category: safety & simulation
runtime: PowerShell 5.1+ / 7+
aliases: [dry-run, script-simulator]
tags: [all-lads-tool, file, safety, dry-run, simulation]
---

# `dry-run.ps1` — Non-Destructive Script Simulator

> [!INFO]
> **Context**: `file` | **Directory**: `all-lads-tool/script/file/`
> **Adapter**: `all-lads-tool/script/file/adapter/universal.psm1`

Menjalankan simulasi skrip secara non-destruktif untuk memvalidasi alur tanpa menyentuh disk fisik, sesuai protokol `run-dry`.

---

## 1. Penggunaan

```powershell
.\all-lads-tool\script\file\dry-run.ps1 -ScriptPath ".\script\repo\git-branch-rename.ps1"
```
