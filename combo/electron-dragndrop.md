---
name: electron-dragndrop
aliases: [electron-dnd-combo, webview-drag-and-drop-suite, electron-cross-window-combo]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, meta-skill, electron, vs-code, drag-and-drop, webview, cross-os]
description: Master composite standard for Electron and VS Code Webview drag-and-drop integration, combining cross-window iframe boundary escape, Copy Path Advance serialization, bulletproof capture-phase context menu suppression, and 3-tier file system movement.
dependencies:
  - "[[electron-dragndrop]]"
  - "[[universal-drag-and-drop-cross-os]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[zero-hardcoded-variables]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[software-development-opensource]]"
  - "[[decoupled-engine-domain-isolation]]"
pros:
  - "Seamless integration between Electron webview sandbox and native OS host windows"
  - "Standardizes cross-window transfer formats for terminals, editors, and external tools"
  - "Eliminates native Electron context menu conflicts without breaking accessibility"
  - "Guarantees cross-OS path normalization across Windows, macOS, and Linux"
cons:
  - "Requires strict HTML5 drag event wiring rather than lightweight DOM pointers"
  - "Requires bidirectional path parsers in both frontend webview and extension backend"
---

# Electron Webview Drag-and-Drop Suite (`electron-dragndrop`)

> [!IMPORTANT]
> **THE COMPOSITE WEBVIEW INTEGRATION STANDARD**:
> This meta-skill unifies the technical disciplines required to build production-grade, multi-window drag-and-drop explorers within Electron and VS Code Webview environments. It bridges the gap between isolated browser sandbox runtimes and the operating system desktop.

---

## 1. Architectural Blueprint & System Topology

```text
+-------------------------------------------------------------------------------+
|                   ELECTRON WEBVIEW DRAG & DROP COMBO PIPELINE                 |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ 1. FRONTEND WEBVIEW SANDBOX ]                                              |
|  +-------------------------------------------------------------------------+  |
|  | .tree-node [draggable="true", -webkit-user-drag: element !important]    |  |
|  | data-vscode-context='{"preventDefaultContextMenuItems": true}'          |  |
|  |                                                                         |  |
|  | [Event: dragstart]                                                      |  |
|  |   |-- text/plain              -> (file;file:///e%3A/proj/GUIDE.md)      |  |
|  |   |-- text/uri-list          -> file:///e:/proj/GUIDE.md               |  |
|  |   |-- application/vnd.treepane -> { sourcePath, paneId }                |  |
|  |                                                                         |  |
|  | [Event: contextmenu (useCapture: true)]                                 |  |
|  |   |-- e.preventDefault() & e.stopImmediatePropagation()                |  |
|  |   \-- renderCustomMenu(Copy Path, Copy Relative, Copy Advance)          |  |
|  +-------------------------------------------------------------------------+  |
|                          |                            |                       |
|           (Internal Intra/Inter Drag)        (External Drag-Out)              |
|                          |                            |                       |
|                          v                            v                       |
|  [ 2. TREEPANE BACKEND ENGINE ]              [ 3. EXTERNAL OS / HOST APPS ]   |
|  +-------------------------------------+     +-----------------------------+  |
|  | decodeAdvancedFilePath(str)         |     | Integrated Terminal Window  |  |
|  | FileSystemService.moveItem()        |     | (Receives advanced path)    |  |
|  | FileSystemService.copyItem()        |     |                             |  |
|  | Refresh affected pane trees via IPC |     | Editor Document Tabs        |  |
|  +-------------------------------------+     | (Opens document via URI)    |  |
|                                              +-----------------------------+  |
+-------------------------------------------------------------------------------+
```

---

## 2. Core Pillars of the Suite

### 2.1 The Iframe Escape Standard — `[[electron-dragndrop]]`
Webviews in VS Code and Electron exist as isolated `<iframe>` elements. Standard DOM pointer events (`pointerdown`, `pointermove`) are physically trapped inside the webview boundary.
- **Rule**: Never use pointer-based synthetic dragging for cross-window items.
- **Enforcement**: Always assign `draggable="true"` to tree node elements and set `-webkit-user-drag: element !important;` in CSS.

### 2.2 Universal 3-Tier Drag Architecture — `[[universal-drag-and-drop-cross-os]]`
A complete explorer must handle 3 distinct drop scenarios simultaneously:
1. **Tier 1 (Intra-Tree Reordering)**: Reordering items in the same folder via top/bottom drop insertion lines (`.drag-over-top`, `.drag-over-bottom`).
2. **Tier 2 (Inter-Tree Relocation)**: Moving or copying files across panes and repositories via drag modifiers (`Ctrl`/`Alt` for copy).
3. **Tier 3 (External Drag-Out)**: Dragging files directly out of the webview into integrated terminals, editor tabs, or other desktop applications.

### 2.3 Bulletproof Context Menu Trapping
VS Code's host webview runner injects default Electron Cut/Copy/Paste items unless trapped before host execution:
- **HTML Contract**: Set `data-vscode-context='{"preventDefaultContextMenuItems": true}'` on `<html>`, `<body>`, containers, and custom context menu DOM.
- **JavaScript Contract**: Listen on `window` in the **capture phase** (`useCapture: true`), invoking `e.stopImmediatePropagation()` and `e.preventDefault()`.

### 2.4 Precision Advanced Path Serialization & Parsing
- **Outbound Format**: `(file;file:///${encodedDrive}%3A/${restOfPath})`
- **Inbound Decoding**: `decodeAdvancedFilePath()` decodes percent-encoded colons and normalizes Windows drive letters when strings are dragged or pasted back into the application.

### 2.5 Strict Engineering Discipline — `[[zero-emoji-serious-mode]]` & `[[zero-hardcoded-variables]]`
- Context menu options, tooltips, and console outputs must remain technical and direct with zero emoji clutter in production interfaces.
- All filesystem operations must dynamically resolve paths without hardcoded absolute drive letters (`C:\`, `E:\`), ensuring full portability across any developer workstation.

---

## 3. Implementation Verification Checklist

- [x] Node elements declare `draggable="true"` and `-webkit-user-drag: element !important`.
- [x] Child elements (`.tree-icon`, `.tree-label`, `.tree-indent`) have `pointer-events: none` and `-webkit-user-drag: none`.
- [x] Expand/collapse arrows declare `pointer-events: auto` to prevent accidental drag triggers.
- [x] Drag payload sets `text/plain` using `toAdvancedFilePath()`.
- [x] Drag payload sets `text/uri-list` with RFC 8089 URI formatting.
- [x] Drag payload sets application-specific JSON MIME type for internal tree tracking.
- [x] Drop handlers call `decodeAdvancedFilePath()` to safely unpack advanced URI payloads.
- [x] Right-click contextmenu event uses `{ capture: true }` and `e.stopImmediatePropagation()`.
- [x] Custom context menu provides: Copy Path, Copy Relative Path, Copy Path Advance, and Reveal in File Explorer.
- [x] Root HTML and body contain `data-vscode-context='{"preventDefaultContextMenuItems": true}'`.

---

## 4. Troubleshooting Matrix

| Symptom | Root Cause | Solution |
| :--- | :--- | :--- |
| Ghost chip stops at sidebar edge | Using DOM pointer events instead of HTML5 drag | Switch to native HTML5 `draggable="true"` |
| Native Cut/Copy/Paste appears over menu | Event listener in bubble phase; host listener fires first | Register `contextmenu` with `useCapture: true` and call `stopImmediatePropagation()` |
| Terminal pastes nothing on drop | `text/plain` missing in `dataTransfer` | Populate `e.dataTransfer.setData('text/plain', advancePath)` in `dragstart` |
| Drive letter doubled or missing colon | Path normalization regex error | Use `norm.replace(/^([a-zA-Z]):/, (_, d) => d.toLowerCase() + '%3A')` |
| Internal drag fails after advanced format | Drop zone expecting raw filesystem path | Wrap drop parsing with `decodeAdvancedFilePath(rawString)` |
