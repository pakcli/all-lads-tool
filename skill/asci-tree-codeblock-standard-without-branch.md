---
name: asci-tree-codeblock-standard-without-branch
aliases: [clean-indented-tree-standard, branchless-tree-codeblock, pure-tabbed-tree]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, tree, standard, ascii, indentation, branchless, notes]
description: Specification for clean, branchless indented tree codeblocks using pure tab or 4-space indentation, node suffix classification, and vertically column-aligned inline documentation notes.
pros:
  - "Eliminates visual noise from box-drawing and ASCII branch characters"
  - "100% portable plain text across all editors, terminals, and web renderers"
  - "Strict vertical column alignment for inline documentation notes"
cons:
  - "Requires consistent tab or 4-space indentation discipline"
---

# Clean Indented Tree Standard Without Branches (`asci-tree-codeblock-standard-without-branch`)

## 1. Core Mandate: Pure Indented Tree (Zero Branch Characters)

In clean source documents and documentation codeblocks, tree hierarchies must remain pure, readable, and free of noisy branch characters.

> [!IMPORTANT]
> **THE ZERO-BRANCH INVARIANT**:
> 1. **DO NOT** use branch symbols of any kind (`├──`, `└──`, `│`, `+--`, `|--`, `\--`).
> 2. **ALWAYS USE TABS or 4-SPACE INDENTATION** to represent hierarchical depth.
> 3. The raw source text must remain pure, clean, and standard plain text.

### Example: Pure Indented Tree
```text
workspace
	folder
		subfolder
			file.md
		asset.webp
	script.ps1
```

---

## 2. Node Classification: File Suffix Rule (`.extension`)

Hierarchical node classification is strictly determined by the presence or absence of a file extension suffix:

| Condition | Classification | Behavior |
| :--- | :--- | :--- |
| **With suffix `.extension`** (e.g. `.json`, `.yaml`, `.ps1`, `.md`, `.js`) | **Leaf / File Node** | Terminal item. Cannot contain child nodes. |
| **Without suffix `.extension`** (e.g. `src`, `data`, `brief`, `public`) | **Parent / Directory Node** | Container item. Spawns child indented lines. |

---

## 3. Inline Annotation Standard (`# Notes / General Functions`)

Nodes in the tree include inline documentation describing their general function using the hash symbol (`#`):

> [!NOTE]
> **INLINE COMMENT & ALIGNMENT SPECIFICATION**:
> 1. **Syntax**: `[indent]<node_name> # <general function / functional description>`
> 2. **Token Parsing**:
>    - **Left Token**: Node name and extension (trimmed of trailing whitespace). Governs hierarchy and file/folder classification.
>    - **Right Token**: Annotation text (trimmed of leading/trailing whitespace). Treated as an explanatory comment.
> 3. **Strict Vertical Column Alignment (`Longest + 1 Space`)**:
>    - All `#` note indicators within a tree codeblock **MUST align vertically to the exact same column**.
>    - **Calculation**: Determine the visual length of the longest line (where 1 tab = 4 spaces). The `#` column is set to `max_visual_length + 1 space`.
>    - Shorter lines are padded with spaces between the node name and `#` so that every `#` begins at that exact visual column.
> 4. **Visual Rhythm**:
>    ```text
>    line                     # note
>          line               # note
>           linepanjang       # note
>    ```

---

## 4. Canonical Example: Clean Branchless Tree with Aligned Notes

```text
web-app_sport-club                      # Direktori utama aplikasi web klub voli
	data                                # Wadah data aplikasi
		daftar-pemain.json              # Roster atlet voli
		jadwal-pertandingan.json        # Jadwal dan skor pertandingan
	src                                 # Kode sumber frontend
		app.js                          # Router SPA dan penampil data
		index.html                      # Halaman beranda
		style.css                       # Desain tema dan tata letak
	public                              # Target distribusi statis
```

---

## 5. Summary Checklist

- [x] **Zero Branches**: Never use `├──`, `└──`, `│`, `+--`, or other branch artifacts.
- [x] **Pure Indentation**: Hierarchy is conveyed solely through consistent indentation.
- [x] **Extension Suffix**: Nodes with `.ext` are files; nodes without `.ext` are directories.
- [x] **Strict Note Alignment**: Align all `#` comments to `longest_line + 1 space` across the entire codeblock.
