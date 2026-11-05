---
name: uiux-tree-file-interactive-explorer
aliases: [interactive-tree-explorer-combo, tree-explorer-suite, treepane-uiux-combo, file-tree-uiux-suite]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, meta-skill, uiux, tree-explorer, file-system, webview, vs-code]
description: Master composite standard for engineering interactive, multi-repository file tree explorers in VS Code & Electron, unifying multi-column adaptive layouts, multi-select interaction, cross-window drag-and-drop, inline renaming, and zero-flicker search filtering.
dependencies:
  - "[[tree-multiselect-interaction]]"
  - "[[electron-dragndrop]]"
  - "[[universal-drag-and-drop-cross-os]]"
  - "[[uiux-wireframe-via-text-ascii-codeblock]]"
  - "[[asci-tree-codeblock-standard]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[zero-hardcoded-variables]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[software-development-opensource]]"
  - "[[client-side-rendering]]"
pros:
  - "Unifies complete frontend UI/UX and extension host backend into a cohesive explorer architecture"
  - "Combines multi-pane responsive layouts (horizontal/vertical) with single-repo focus mode"
  - "Supports full desktop interaction model: multi-select, F2 inline rename, drag-to-terminal, and quick repo moves"
cons:
  - "Requires coordinating IPC messages between webview frontend and VS Code extension host"
  - "Requires maintaining synchronized selection and expansion state across re-renders"
---

# UI/UX Interactive File Tree Explorer Suite (`uiux-tree-file-interactive-explorer`)

> [!IMPORTANT]
> **THE MASTER TREE EXPLORER COMPOSITE STANDARD**:
> This meta-skill defines the architecture, interaction patterns, IPC protocol contracts, and visual styling required to build desktop-grade, multi-column file tree explorers in VS Code and Electron.

---

## 1. Monospace UI/UX Architecture & Wireframe

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ TREEPANE EXPLORER [2 trees]           [Repos (2/11) v] [Focus] [+ Add Tree]  │
├──────────────────────────────────────┬───────────────────────────────────────┤
│ ::: #1 proj              [1st] [<] [>] x│ ::: #2 proj/all-lads-tool [GIT] [1st] x│
├──────────────────────────────────────┼───────────────────────────────────────┤
│ > Filter files (*.ts, /regex/) Aa ab *│ > Filter files (*.ts, /regex/) Aa ab *│
├──────────────────────────────────────┼───────────────────────────────────────┤
│ v .vscode                            │ v brief                               │
│ > all-agenting-notes                 │ > combo                               │
│ v all-lads-tool                      │ v docs                                │
│   > brief                            │ > script                              │
│   > combo                            │ v skill                               │
│   v skill                            │   [ ] _mainmenu.html                  │
│     [x] electron-dragndrop.md (sel)  │   [x] _mainmenu.ps1           (sel)   │
│     [x] tree-multiselect.md   (sel)  │   [x] _run.ps1                (sel)   │
│   | GUIDE.md                         │   | GUIDE.md                          │
│   | [ README_new.md                ] │   | README.md                         │
│     (Inline Rename F2 Active)        │                                       │
│ > obsidian-plugin_local              │   +-------------------------------+   │
│ > quartz                             │   | Context Menu (Right-Click)    |   │
│ > trash-bin                          │   | Copy Path (2 items)           |   │
│ > vault_example-chemistry-library    │   | Copy Relative Path            |   │
│                                      │   | Copy Path Advance (2 items)   |   │
│                                      │   | ----------------------------- |   │
│                                      │   | Rename                     F2 |   │
│                                      │   | Move to Repo...     (2 items) |   │
│                                      │   | ----------------------------- |   │
│                                      │   | Reveal in File Explorer       |   │
│                                      │   +-------------------------------+   │
└──────────────────────────────────────┴───────────────────────────────────────┘
```

---

## 2. The 6 Core Engineering Pillars

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                    THE 6 PILLARS OF INTERACTIVE EXPLORER                     │
├──────────────────────────────────────────────────────────────────────────────┤
│ 1. ADAPTIVE TOPOLOGY : Multi-column horizontal/vertical layout & focus view  │
│ 2. MULTI-SELECT      : Ctrl discrete toggle, Shift range select, UI sync     │
│ 3. CROSS-WINDOW DND  : HTML5 iframe escape, Copy Path Advance serialization  │
│ 4. DIRECT MUTATIONS  : F2 inline input rename, overwrite protection          │
│ 5. REPO MANAGEMENT   : Dynamic discovery, QuickPick Move to Repo, batch ops  │
│ 6. SEARCH & FILTER   : In-memory Trie/Regex matchers with match highlighting │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 2.1 Pillar 1: Adaptive Topology & View Modes
- **Multi-Split Mode**: Independent panes arranged side-by-side (horizontal) or stacked (vertical) with draggable splitters.
- **Focus Mode**: Fast keyboard toggle to expand a single repository tree full-width, hiding other columns without destroying their collapse or scroll state.
- **Dynamic Repo Discovery**: Automatically scans workspace folders 1 level down, detecting `.git` markers and grouping root directories.

### 2.2 Pillar 2: Multi-Selection Interaction — `[[tree-multiselect-interaction]]`
- **`Ctrl` / `Cmd + Click`**: Toggles discrete nodes in the selection set without triggering directory expansion or opening documents.
- **`Shift + Click`**: Evaluates continuous range selection against all visible DOM nodes between the anchor node and the clicked node in that pane.
- **Selection State Persistence**: Preserved across filtering and expansion toggles using an active path `Set()`.

### 2.3 Pillar 3: Cross-Window Drag & Drop — `[[electron-dragndrop]]`
- **Iframe Escape**: Utilizes native HTML5 `draggable="true"` and `-webkit-user-drag: element !important` so drag operations cross the sidebar boundary into VS Code terminal and editor windows.
- **Copy Path Advance Serialization**:
  `text/plain` is set to `(file;file:///e%3A/proj/all-lads-tool/GUIDE.md)`, joining multi-selected items with newlines.
- **3-Tier Movement**: Supports intra-tree sorting (visual lines), inter-tree relocation, and drag-out into external applications.

### 2.4 Pillar 4: Direct Inline Renaming (`F2`)
- Replaces `.tree-label` with an inline input element `<input class="tree-rename-input" />`.
- Automatically selects the filename while excluding the file extension (`[GUIDE].md`).
- **Enter**: Commits changes via `vscode.workspace.fs.rename` and auto-refreshes all affected panes.
- **Escape**: Restores original HTML label without modifying filesystem.

### 2.5 Pillar 5: Cross-Repository Organization (`Move to Repo...`)
- Context menu action that queries `vscode.window.showQuickPick` with all workspace repositories.
- Dispatches batch `FileSystemService.moveItems()` to migrate one or multiple files/directories across repository boundaries in a single action.

### 2.6 Pillar 6: Real-Time Fuzzy & Regex Filtering
- Real-time search bar per tree pane supporting plain substrings, wildcards (`*.ts`), case-sensitivity (`Aa`), whole-word (`ab`), and regex (`.*`).
- Auto-expands parent nodes matching search criteria and highlights matching characters.

---

## 3. Bidirectional IPC Contract Matrix

| Message Command | Direction | Payload Schema | Action Performed |
| :--- | :--- | :--- | :--- |
| `ready` | Webview $\rightarrow$ Host | `{ command: 'ready' }` | Discovers repos and initiates pane trees |
| `openFile` | Webview $\rightarrow$ Host | `{ command: 'openFile', filePath }` | Opens document in editor tab |
| `renameItem` | Webview $\rightarrow$ Host | `{ command: 'renameItem', oldPath, newName? }` | Renames file/folder and refreshes trees |
| `moveItems` | Webview $\rightarrow$ Host | `{ command: 'moveItems', sourcePaths: [], targetDirPath }` | Moves multiple items into target directory |
| `copyItems` | Webview $\rightarrow$ Host | `{ command: 'copyItems', sourcePaths: [], targetDirPath }` | Copies multiple items into target directory |
| `moveToRepo` | Webview $\rightarrow$ Host | `{ command: 'moveToRepo', sourcePaths: [], sourcePaneId? }` | Shows QuickPick and moves items to selected repo |
| `copyToClipboard` | Webview $\rightarrow$ Host | `{ command: 'copyToClipboard', text }` | Writes to clipboard with status message |
| `revealInOS` | Webview $\rightarrow$ Host | `{ command: 'revealInOS', filePath }` | Highlights item in Windows Explorer / Finder |
| `renderTree` | Host $\rightarrow$ Webview | `{ command: 'renderTree', paneId, tree }` | Sends updated directory tree model to webview |

---

## 4. Implementation Verification Checklist

- [x] Webview root contains `data-vscode-context='{"preventDefaultContextMenuItems": true}'`.
- [x] Right-click listener registered with `useCapture: true` calling `e.stopImmediatePropagation()`.
- [x] Node dragstart sets `text/plain` to `(file;file:///...)` using `toAdvancedFilePath()`.
- [x] Multi-selection supported with `Ctrl+Click` (toggle) and `Shift+Click` (range).
- [x] Dragging a selected node bundles all selected items for batch drop.
- [x] Inline renaming triggered via `F2` or context menu with extension-aware preselection.
- [x] Context menu includes `Move to Repo...` powered by host QuickPick.
- [x] Zero hardcoded drive letters or absolute paths in CSS, JS, or extension host services.
- [x] Clean zero-emoji technical interfaces adhering to professional standards.
