---
name: electron-dragndrop
aliases: [electron-dnd, webview-drag-and-drop, electron-cross-window-drag, advance-path-drag]
category: INTERACTION_STANDARD
tags: [all-lads-tool, skill, electron, vs-code, drag-and-drop, webview, cross-window]
description: Technical standard for Electron and VS Code Webview drag-and-drop operations escaping iframe boundaries to drop into external windows, integrated terminals, and editors with Copy Path Advance URI formatting and native context menu suppression.
pros:
  - "Cross-window escape allowing drops into terminal, editor tabs, and OS windows"
  - "Precision Copy Path Advance serialization with percent-encoded drive letters"
  - "Bulletproof native context menu suppression using capture-phase event interception"
  - "Bidirectional decode support converting advanced URI payloads back to local filesystem paths"
cons:
  - "Requires HTML5 drag-and-drop API instead of pure DOM pointer events"
  - "Requires -webkit-user-drag CSS rules for cross-platform Chromium consistency"
---

# Electron Webview Drag-and-Drop Standard (`electron-dragndrop`)

> [!IMPORTANT]
> **THE ELECTRON WEBVIEW BOUNDARY INVARIANT**:
> Webview sandboxes run inside isolated `<iframe>` elements hosted by Electron. Pure DOM pointer event drags (`pointerdown`, `pointermove`, `pointerup`) are strictly bounded by the iframe viewport and cannot cross into the host window (integrated terminals, editor tabs, or external OS windows).
> To enable cross-window drops, the implementation MUST use native HTML5 Drag and Drop (`draggable="true"` and `-webkit-user-drag: element !important`) and populate standard OS clipboard transfer formats.

---

## 1. Architectural Topology: Iframe Boundary Escape

```text
+-------------------------------------------------------------------------------+
|                       ELECTRON / VS CODE HOST WINDOW                          |
|                                                                               |
|  +---------------------------+      [Cross-Window Native OS Drag Session]     |
|  | Webview Pane (iframe)     | --------------------------------------------+  |
|  |                           |                                             |  |
|  |  [File Tree Node]         |                                             |  |
|  |  draggable="true"         |                                             |  |
|  |  -webkit-user-drag        |                                             |  |
|  |                           |                                             |  |
|  |  dragstart:               |                                             |  |
|  |  setData('text/plain',    |                                             |  |
|  |    advancePath)           |                                             |  |
|  +---------------------------+                                             |  |
|                |                                                           |  |
|    (Blocked by iframe border)                                              |  |
|    x- Pointer drag trapped -x                                              |  |
|                                                                            |  |
|                                                                            v  |
|  +---------------------------+  +----------------------+  +----------------+  |
|  | Integrated Terminal       |  | Editor Document Tabs |  | External App   |  |
|  | (text/plain inserted)     |  | (text/uri-list drop) |  | (Notepad/etc.) |  |
|  +---------------------------+  +----------------------+  +----------------+  |
+-------------------------------------------------------------------------------+
```

---

## 2. Copy Path Advance Serialization Protocol

When a node is dragged out of the webview or copied via context menu, the `text/plain` payload MUST follow the **Copy Path Advance** specification:

### Specification Rules
1. Encapsulated in opening `(file;file://` and closing `)`.
2. Windows drive letters must be lowercase and percent-encoded (e.g., `e:` becomes `e%3A`).
3. Backslashes (`\`) must be normalized to forward slashes (`/`).
4. Path must start with a leading slash `/` after `file;file://`.

### Example Outputs
- **Windows File**: `E:\proj\all-lads-tool\GUIDE.md`
  $$\longrightarrow$$ `(file;file:///e%3A/proj/all-lads-tool/GUIDE.md)`
- **Windows Directory**: `E:\proj\vault_example-chemistry-library`
  $$\longrightarrow$$ `(file;file:///e%3A/proj/vault_example-chemistry-library)`
- **POSIX / macOS / Linux**: `/home/developer/proj/GUIDE.md`
  $$\longrightarrow$$ `(file;file:///home/developer/proj/GUIDE.md)`

### Reference Implementation
```javascript
function toAdvancedFilePath(filePath) {
  let norm = filePath.replace(/\\/g, '/');
  norm = norm.replace(/^([a-zA-Z]):/, (_, drive) => `${drive.toLowerCase()}%3A`);
  if (!norm.startsWith('/')) {
    norm = '/' + norm;
  }
  return `(file;file://${norm})`;
}
```

---

## 3. Native Electron Context Menu Suppression

By default, VS Code's Electron host preload injects native Cut, Copy, and Paste context menus over webview elements. Standard `e.preventDefault()` inside bubble-phase listeners fails because host listeners fire in the capture phase.

### Two-Step Suppression Solution

#### Step 1: HTML Context Tagging
Add `data-vscode-context` attribute containing `{"preventDefaultContextMenuItems": true}` to the root HTML, body, and interactive container elements:
```html
<html lang="en" data-vscode-context='{"preventDefaultContextMenuItems": true}'>
<body data-vscode-context='{"preventDefaultContextMenuItems": true}'>
  <div class="tree-node" data-vscode-context='{"preventDefaultContextMenuItems": true}'>...</div>
</body>
</html>
```

#### Step 2: JavaScript Capture-Phase Trapping
Listen on the `contextmenu` event in the **capture phase** (`useCapture: true`) and immediately invoke `stopImmediatePropagation()`:
```javascript
window.addEventListener('contextmenu', (e) => {
  e.preventDefault();
  e.stopImmediatePropagation();

  const targetNode = e.target.closest('.tree-node');
  if (targetNode) {
    showCustomContextMenu(e, targetNode);
    return;
  }

  closeCustomContextMenu();
}, true); // Crucial: true ensures this handler runs BEFORE host listeners
```

---

## 4. Multi-Payload DataTransfer Registry

To support drops into multiple heterogeneous targets simultaneously, the `dragstart` event must populate multiple MIME representations:

| Target Environment | MIME Type | Value Example |
| :--- | :--- | :--- |
| **Shell Terminal / Console** | `text/plain` | `(file;file:///e%3A/proj/all-lads-tool/GUIDE.md)` |
| **VS Code Editor / Tabs** | `text/uri-list` | `file:///E:/proj/all-lads-tool/GUIDE.md` |
| **Webview Intra-Tree Engine** | `application/vnd.code.tree.treepane` | `{"sourcePath":"...","isDirectory":false}` |
| **Direct Path Consumer** | `text/x-treepane-path` | `E:/proj/all-lads-tool/GUIDE.md` |

```javascript
nodeEl.addEventListener('dragstart', (e) => {
  if (e.target.closest('.tree-arrow')) {
    e.preventDefault();
    return;
  }

  const advancePath = toAdvancedFilePath(node.path);
  const uri = encodeURI('file:///' + node.path.replace(/\\/g, '/').replace(/^\/+/, ''));
  const internalData = { sourcePath: node.path, sourcePaneId: paneId, isDirectory: node.isDirectory };

  e.dataTransfer.setData('text/plain', advancePath);
  e.dataTransfer.setData('text/uri-list', uri);
  e.dataTransfer.setData('application/vnd.code.tree.treepane', JSON.stringify(internalData));
  e.dataTransfer.setData('text/x-treepane-path', node.path);

  e.dataTransfer.effectAllowed = 'copyMove';
  nodeEl.classList.add('dragging');
});
```

---

## 5. Bidirectional Advanced Path Decoder

When files are dropped back into the webview or parsed from clipboard input, advanced URI formatted strings must be reliably converted back into native filesystem paths:

```javascript
function decodeAdvancedFilePath(str) {
  if (!str) return str;
  const match = str.trim().match(/^\(file;file:\/\/\/?([^)]+)\)$/i);
  if (match) {
    let p = decodeURIComponent(match[1]);
    // Strip leading forward slash before drive letter on Windows (e.g. /e:/path -> e:/path)
    if (/^\/[a-zA-Z]:/.test(p)) {
      p = p.substring(1);
    }
    return p;
  }
  return str.trim();
}
```

---

## 6. CSS Rules for Chromium Drag Consistency

Chromium on Windows can fail to initiate drag events if `touch-action` is disabled or child elements intercept mouse clicks:

```css
/* Container node must declare element dragging */
.tree-node {
  display: flex;
  align-items: center;
  cursor: grab;
  user-select: none;
  -webkit-user-select: none;
  -webkit-user-drag: element !important;
}

.tree-node:active {
  cursor: grabbing;
}

/* Child elements must not interfere with row drag */
.tree-icon,
.tree-label,
.tree-indent {
  pointer-events: none;
  user-select: none;
  -webkit-user-select: none;
  -webkit-user-drag: none;
}

/* Expansion toggles remain interactive */
.tree-arrow {
  pointer-events: auto;
  cursor: pointer;
  -webkit-user-drag: none;
}
```
