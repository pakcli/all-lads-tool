---
name: universal-drag-and-drop-cross-os
aliases: [drag-and-drop-cross-os, universal-file-drag, cross-tree-dnd, dnd-to-another-app]
category: INTERACTION_STANDARD
tags: [all-lads-tool, skill, drag-and-drop, cross-os, webview, vs-code, file-system]
description: Universal cross-OS drag-and-drop interaction standard governing intra-tree sorting, inter-tree file relocation, and drag-to-external-app interoperability across Windows, macOS, and Linux.
pros:
  - "Universal MIME and protocol alignment across Windows, macOS, and Linux"
  - "Zero-conflict separation between container reordering and file transfers"
  - "Native external application interoperability (VS Code editors, desktop, terminals)"
cons:
  - "Requires explicit RFC 8089 file URI normalization"
  - "Must enforce strict circular hierarchy prevention on directory transfers"
---

# Universal Cross-OS Drag-and-Drop Standard (`universal-drag-and-drop-cross-os`)

> [!IMPORTANT]
> **THE UNIVERSAL DRAG-AND-DROP INVARIANT**:
> All file trees, explorer panes, and webview tools across `all-lads-tool` must provide three synchronized tiers of drag-and-drop capabilities:
> 1. **Intra-Tree Sorting**: Reordering items within the same parent folder or tree.
> 2. **Inter-Tree Relocation**: Moving or copying files and directories between different trees or repositories.
> 3. **Drag to External Apps**: Dragging files directly out of webview panes into external applications (VS Code editor tabs, terminals, desktop, and OS file managers).

---

## 1. Interaction Hierarchy & Topology

```text
+------------------------------------------------------------------------+
|             UNIVERSAL CROSS-OS DRAG-AND-DROP ARCHITECTURE              |
+------------------------------------------------------------------------+
|                                                                        |
|  [ Tree Pane A ]                      [ Tree Pane B ]                  |
|  +- folder_a/                         +- folder_b/                     |
|  |  |- GUIDE.md ---[Drag Tier 1]--->  |  |- target/                    |
|  |  |  (Sort in same folder)          |  |                             |
|  |  |                                 |  |                             |
|  |  +--[Drag Tier 2: Inter-Tree Move/Copy]----------------> target/    |
|  |                                                                     |
|  +-----[Drag Tier 3: External App / OS Native Drag-Out]--------------+ |
|                                                                      | |
|                                                                      v v
|  +---------------------+  +---------------------+  +-----------------+ |
|  | VS Code Editor Tabs |  | Desktop / Explorer  |  | Shell Terminal  | |
|  | (text/uri-list)     |  | (DownloadURL)       |  | (text/plain)    | |
|  +---------------------+  +---------------------+  +-----------------+ |
+------------------------------------------------------------------------+
```

---

## 2. Universal MIME & Payload Protocol Matrix

To ensure flawless drag-and-drop execution across Windows, macOS, and Linux, every drag payload must simultaneously populate standard MIME types:

| MIME Type / DataTransfer Key | Value Format | Target Consumer / Operating System |
| :--- | :--- | :--- |
| `text/uri-list` | `file:///E:/proj/GUIDE.md` (RFC 8089) | VS Code Editor Tabs, Chat, Obsidian, Browsers |
| `text/plain` | Absolute system path (e.g., `E:\proj\GUIDE.md`) | Terminal consoles, search boxes, text inputs |
| `DownloadURL` | `application/octet-stream:<name>:<fileUri>` | Chromium / Electron native drag to desktop & Explorer |
| `application/vnd.code.tree.treepane` | Encoded JSON metadata `{ sourcePath, isDirectory }` | Internal TreePane intra-tree and inter-tree ops |
| `application/vnd.code.treepane.reorder` | Encoded pane ID (`pane_123`) | Layout container sorting (isolated from file drops) |

---

## 3. RFC 8089 File URI Normalization (Cross-OS)

Every file path must be normalized to forward-slashes and prefixed with standard `file:///` protocol before setting `text/uri-list` or `DownloadURL`:

```javascript
function toFileUri(filePath) {
  let p = filePath.replace(/\\/g, '/');
  if (!p.startsWith('/')) {
    p = '/' + p;
  }
  return 'file://' + encodeURI(p);
}
```

- **Windows**: `E:\proj\all-lads-tool\GUIDE.md` -> `file:///E:/proj/all-lads-tool/GUIDE.md`
- **macOS / Linux**: `/home/user/proj/GUIDE.md` -> `file:///home/user/proj/GUIDE.md`

---

## 4. The Three Drag Tiers Specification

### Tier 1: Intra-Tree Sorting & Reordering
- **Trigger**: Dragging a node over an adjacent file node within the same directory.
- **Visual Feedback**:
  - Top half of node: `.drag-over-top` (solid accent insertion line at top edge).
  - Bottom half of node: `.drag-over-bottom` (solid accent insertion line at bottom edge).
- **Execution**: Updates in-memory tree child array without disk write, preserving immediate visual order.

### Tier 2: Inter-Tree Move & Copy
- **Trigger**: Dragging a node from Tree Pane A and dropping onto Tree Pane B (folder node or empty pane background).
- **Modifiers**:
  - **Standard Drop**: Moves file/folder (`moveItem` via `vscode.workspace.fs.rename`).
  - **Alt / Ctrl + Drop**: Copies file/folder (`copyItem` via `vscode.workspace.fs.copy`).
- **Visual Feedback**:
  - Folder target: `.drag-over-folder` (translucent accent fill + dashed border).
  - Pane background: `.drag-over-pane` (container border glow).
- **Auto-Refresh**: Dispatches updated tree structures to both source and target panes.

### Tier 3: Drag to External Applications
- **Trigger**: Dragging a node outside the webview boundary.
- **VS Code Editor Area**: Receives `text/uri-list` and opens the file in an active or split editor tab.
- **OS Desktop / Explorer**: Electron handles `DownloadURL` and creates a physical copy or shortcut.
- **CLI / Terminals**: Receives `text/plain` and pastes the clean unquoted absolute path.

---

## 5. Security & Safety Invariants

1. **Circular Hierarchy Guard**:
   Never allow moving or copying a directory into itself or any of its subdirectories:
   ```typescript
   if (normTargetDir === normSource || normTargetDir.startsWith(normSource + '/')) {
     throw new Error("Cannot move directory into its own hierarchy.");
   }
   ```
2. **Name Collision Management**:
   If target file already exists, present an interactive modal option: `[Overwrite]`, `[Keep Both]`, `[Cancel]`. Never silently discard or overwrite user data without confirmation.
3. **MIME Type Isolation**:
   Container reordering (`:::`) must use a dedicated MIME key (`application/vnd.code.treepane.reorder`) so pane reordering never intercepts or blocks file tree drag events.
