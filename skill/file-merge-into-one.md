---
name: file-merge-into-one
aliases: [merge-files, consolidate-files, combine-markdown-files, folder-to-single-file]
category: FILE_TRANSFORMATION_PROTOCOL
tags: [all-lads-tool, protocol, file-management, consolidation, markdown, merge, single-file]
trigger: on_demand
description: Consolidates multiple discrete Markdown notes from a directory into a single unified document with automated frontmatter aggregation, heading promotion, TOC anchor generation, and safe archiving.
---

# File Merge Into One Protocol (`file-merge-into-one`)

## 1. Core Rule & Architectural Intent
* **Consolidation**: Merges a collection of sibling notes into a single cohesive document when their individual granularity causes fragmentation or when a unified comparative view is required.
* **Frontmatter Aggregation**: Automatically extracts and deduplicates tags, merges metadata, and attaches audit timestamps (`merged_date`, `source_file_count`).
* **Heading Promotion**: Sub-note titles are promoted to structured section headers (`## <Title>`) with duplicate H1 headings stripped from note bodies.
* **Anchor Integrity**: Generates a linked Table of Contents (TOC) pointing to newly created slug anchors (`#section-slug`).
* **Non-Destructive Archiving**: Preserves source files or safely archives them to `trash-bin/` following the [trash-bin-inroot-same-structure](trash-bin-inroot-same-structure.md) protocol.

---

## 2. When to Use
1. **Low-Cardinality Compaction**: Sibling files contain brief descriptions (e.g. 3-5 lines per file) and are better synthesized as a single overview or comparative matrix.
2. **Export Preparation**: Preparing a multi-note chapter or module for unified PDF print export or single-document distribution.
3. **De-fragmentation**: Collapsing an over-engineered folder into a single clean reference guide.

---

## 3. Operational Standards & Syntax

### 3.1 PowerShell Execution (`all-lads-tool`)
```powershell
# Interactive mode
pwsh all-lads-tool/script/file/file-merge-into-one.ps1

# Direct execution with parameters
pwsh all-lads-tool/script/file/file-merge-into-one.ps1 `
    -SourceDir "path/to/notes" `
    -OutputFile "path/to/notes/consolidated-overview.md" `
    -HeadingLevel 2 `
    -IncludeTOC `
    -ArchiveSources
```

### 3.2 Parameter Reference
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-SourceDir` | `string` | *(Prompt)* | Directory containing Markdown files to merge. |
| `-OutputFile` | `string` | `merged-output.md` | Destination path for the consolidated document. |
| `-Pattern` | `string` | `*.md` | File matching filter. |
| `-HeadingLevel`| `int` | `2` (`## `) | Markdown heading level for merged note titles. |
| `-IncludeTOC` | `switch` | `$true` | Prepends an anchor-linked Table of Contents. |
| `-ArchiveSources`| `switch`| `$false` | Safely moves merged files to `trash-bin/`. |
| `-DryRun` | `switch` | `$false` | Simulates the merge without modifying files. |

---

## 4. Invariant Safety Guarantees
1. **Zero Hardcoded Paths**: Dynamic path resolution relative to workspace root.
2. **UTF-8 Clean**: Preserves emojis, special symbols, and foreign character scripts.
3. **Collision Safety**: Excludes the target output file itself from the input file stream.
