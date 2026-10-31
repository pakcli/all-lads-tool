---
description: RULE #006 — ASCII Tree Codeblock Invariant & Interactive Typeable Sub-branch Standard
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE #006 — ASCII Tree Codeblock Invariant & Interactive Typeable Sub-branch Standard

## 1. Core Mandate: Clean Source vs. Rendered ASCII

In source/editing mode, codeblock text must remain clean, natural, and free of hardcoded branch characters. The ASCII branching structure is rendered dynamically by the engine.

> [!IMPORTANT]
> **SOURCE CODEBLOCK RULE (UNRENDERED)**:
> 1. **DO NOT** write hardcoded ASCII branch symbols (`├──`, `└──`, `│`) inside the raw codeblock text.
> 2. **ALWAYS USE TABS or 4-SPACE INDENTATION** to represent hierarchy.
> 3. The raw source text must remain pure, readable, and standard plain text.

### Visual Comparison: Source vs. Rendered

#### A. Source Mode (`ASCI-not rendered` / Raw Codeblock)
```text
item
	Item
	item
```

#### B. Basic Rendered Output (`TEXT` / Standard Tree)
```text
item
├── Item
└── item
```

---

## 2. Node Classification: File Suffix Rule (`.extension`)

Hierarchical behavior is strictly determined by the presence or absence of a file extension suffix: FOR EXAMOLE TABLE:

| Condition | Classification | Behavior |
| :--- | :--- | :--- |
| **With suffix `.extension`** (e.g. `.webp`, `.csv`, `.md`, `.pdf`) | **Leaf / File Node** | Terminal item. Cannot spawn children or sub-branch lines. |
| **Without suffix `.extension`** (e.g. `item`, `asset`, `player`) | **Parent / Directory Node** | Container item. Spawns child branches and triggers the extra typeable line rule. |

---

## 3. The Typeable Extra Sub-branch Rule (`└── ` Kosong)

Every parent branch (text without a `.extension` suffix) must **always** render with an interactive, typeable extra line at the end of its child list.

> [!NOTE]
> **KOSONG & TYPEABLE STANDARD**:
> 1. If a node is a parent (no `.extension`), the renderer **must append exactly 1 extra sub-branch line** (`└── `).
> 2. This extra line is initially empty (*kosong*) and directly **typeable**.
> 3. Clicking on this empty line focuses an in-place input, allowing users to type a new item directly into that folder branch.
> 4. Committing text on this empty line synchronizes it back to the source codeblock as an indented tabbed entry.

### Example: Rendered View with Interactive Typeable Sub-branches

```text
item
├── Item
│   └──                 <-- Kosong & typeable (allows typing 1st child)
├── Item
│   ├── item
│   └──                 <-- Kosong & typeable (always 1 extra line after existing children)
└── item
```

---

## 4. Summary Checklist for Codeblock Processors

- [x] **Source Integrity**: Never inject or require `├──`, `└──`, `│` in the raw codeblock markdown.
- [x] **Tab/Space Indentation**: Parse hierarchy purely from indentation depth.
- [x] **Suffix Check**: Automatically treat any node without `.ext` as a parent folder.
- [x] **Extra Sub-branch**: Always provide 1 empty, typeable `└── ` line for every parent branch.
- [x] **Bi-directional Sync**: Typing into the empty sub-branch immediately updates the active note codeblock with proper indentation.
