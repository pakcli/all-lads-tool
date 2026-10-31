---
title: Emoji Stripper & Text Sanitizer
tool: remove-emoji.ps1
category: sanitization & formatting
runtime: PowerShell 7+ / 5.1
aliases: [remove-emoji, strip-emoji, emoji-stripper]
tags: [all-lads-tool, powershell, emoji, sanitization, markdown, modular]
---

# `remove-emoji.ps1` — Emoji Stripper & Text Sanitizer

> [!INFO]
> **Runtime**: PowerShell 7+ / Windows PowerShell 5.1 | **Directory**: `all-lads-tool/script/powershell/`  
> **Architecture**: Modular Edition (Connected to `module/emojistripper.psm1`)  
> **Scope**: Defaults to Markdown (`*.md`), configurable to all formats via `-AllExtensions` or custom `-Filter`.

Scans directories recursively and strips all Unicode emojis, astral surrogates, variation selectors, and dingbats while preserving document formatting and text structure.

---

## 1. Quick Syntax & Usage

```powershell
# 1. Default: Strip emojis from all Markdown files (*.md) in current directory
.\all-lads-tool\script\powershell\remove-emoji.ps1

# 2. Preview without modifying files (DryRun)
.\all-lads-tool\script\powershell\remove-emoji.ps1 -TargetDir "docs" -DryRun

# 3. Strip emojis across all supported text formats
.\all-lads-tool\script\powershell\remove-emoji.ps1 -TargetDir "." -AllExtensions -NormalizeSpaces

# 4. Custom filter
.\all-lads-tool\script\powershell\remove-emoji.ps1 -TargetDir "src" -Filter "*.ts"
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-TargetDir` | string | No | Current Directory | Path to folder to inspect recursively. |
| `-Filter` | string | No | `*.md` | File pattern to match ("markdown aja"). |
| `-AllExtensions` | switch | No | `false` | Scans all text formats (`*.md`, `*.txt`, `*.js`, `*.ts`, `*.ps1`, `*.json`, `*.html`, `*.css`, `*.sh`, `*.bat`). |
| `-DryRun` | switch | No | `false` | Previews files with emojis without modifying them. |
| `-NormalizeSpaces` | switch | No | `false` | Collapses leftover double spaces into single spaces. |

---

## 3. Modular Architecture

* **Executable Runner**: [`script/powershell/remove-emoji.ps1`](../../script/powershell/remove-emoji.ps1) (Modular edition, no `_stand` suffix)
* **Underlying Engine**: [`script/powershell/module/emojistripper.psm1`](../../script/powershell/module/emojistripper.psm1) (Exports `Test-HasEmoji`, `Remove-EmojiFromText`, `Get-EmojiCountInText`, `Invoke-EmojiStripOnFile`)
