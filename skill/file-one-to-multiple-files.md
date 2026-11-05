---
name: file-one-to-multiple-files
aliases: [split-file, partition-document, promote-to-folder, single-file-to-folder]
category: FILE_TRANSFORMATION_PROTOCOL
tags: [all-lads-tool, protocol, file-management, partitioning, markdown, split, modularization]
trigger: on_demand
description: Partitions a monolithic Markdown document into multiple modular child notes based on heading boundaries, generating frontmatter, kebab-case filenames, and a master index hub.
---

# File One To Multiple Files Protocol (`file-one-to-multiple-files`)

## 1. Core Rule & Architectural Intent
* **Modular Partitioning**: Deconstructs a monolithic document into autonomous, first-class Markdown notes when sections achieve sufficient depth or need independent graph node identity.
* **Heading-Based Boundaries**: Splits content cleanly at specified heading thresholds (`## ` by default) while capturing any preamble text into an overview/index hub.
* **Automated Frontmatter & Naming**:
  * Sanitizes heading text into clean lowercase kebab-case filenames (stripping emojis/symbols safely).
  * Injects `title`, `parent`, `order`, and inherited master tags into each child note.
* **Master Index Generation**: Automatically creates an `index.md` linking to all generated child notes via standard Obsidian/Quartz wikilinks.
* **Non-Destructive Archiving**: Moves the original monolithic file to `trash-bin/` with 1:1 path mirroring when `-ArchiveSource` is specified.

---

## 2. When to Use (Folder Promotion Threshold)
1. **The Atomic Node Principle**: Sections require direct wikilinking, distinct metadata, unique tags, or independent graph relationships.
2. **Cardinality Shift**: A single section expands from a brief summary into a multi-part sub-system (1-to-many child data streams).
3. **Scroll Saturation**: A document exceeds comfortable viewport reading length and contains distinct logical sub-topics.
4. **Independent Mutation**: Sub-sections have divergent update cadences and need isolated version history.

---

## 3. Operational Standards & Syntax

### 3.1 PowerShell Execution (`all-lads-tool`)
```powershell
# Interactive mode
pwsh all-lads-tool/script/file/file-one-to-multiple-files.ps1

# Direct execution with parameters
pwsh all-lads-tool/script/file/file-one-to-multiple-files.ps1 `
    -SourceFile "path/to/monolith.md" `
    -OutputDir "path/to/modular-folder" `
    -SplitHeadingLevel 2 `
    -GenerateIndex `
    -ArchiveSource
```

### 3.2 Parameter Reference
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-SourceFile` | `string` | *(Prompt)* | Path to the monolithic file to partition. |
| `-OutputDir` | `string` | `<file-basename>/` | Target folder to store generated files. |
| `-SplitHeadingLevel`| `int`| `2` (`## `) | Heading level boundary for partitioning. |
| `-GenerateIndex` | `switch`| `$true` | Creates `index.md` linking all generated notes. |
| `-ArchiveSource`| `switch`| `$false` | Safely archives original file to `trash-bin/`. |
| `-DryRun` | `switch` | `$false` | Simulates file generation without writing to disk. |

---

## 4. Invariant Safety Guarantees
1. **Clean Kebab Slugs**: Emoji-safe slugification prevents invalid OS filesystem characters.
2. **Preamble Retention**: Content preceding the first split heading is preserved in `index.md`.
3. **Non-Destructive**: Original file is never hard-deleted; `-ArchiveSource` routes safely to `trash-bin/`.
