---
name: tree-multiselect-interaction
aliases: [multiselect-tree-item, tree-multiselect, shift-ctrl-tree-select, batch-tree-selection]
category: INTERACTION_STANDARD
tags: [all-lads-tool, skill, uiux, multi-select, tree-view, keyboard-navigation, webview]
description: Interactive multi-selection standard for tree views and file explorers, defining discrete Ctrl-click toggling, continuous Shift-click range selection, batch drag-and-drop bundling, and multi-item context menu execution.
pros:
  - "Intuitive desktop-grade multi-selection matching OS file manager standards"
  - "Zero-flicker range selection algorithm evaluated over visible DOM nodes"
  - "Seamless bundling of multiple items for batch moves, copies, and clipboard operations"
  - "Preserves primary double/single click open semantics without selection collision"
cons:
  - "Requires active DOM query caching to prevent layout thrashing on huge trees (>10k items)"
  - "Requires anchor node synchronization when tree branches expand or collapse"
---

# Tree Multi-Selection Interaction Standard (`tree-multiselect-interaction`)

> [!IMPORTANT]
> **THE MULTI-SELECTION INVARIANT**:
> All tree explorers must support standard desktop modifier semantics:
> 1. **`Ctrl` / `Cmd + Click`**: Toggles individual node presence in the selection cluster without opening files or collapsing folders.
> 2. **`Shift + Click`**: Computes a continuous range from the last anchor node to the clicked target within the active pane container.
> 3. **Normal Click**: Collapses multi-selection into a single active selection and executes the primary action (open file or expand folder).
> 4. **Batch Operations**: Initiating a drag or context action on any selected node executes across all currently selected items.

---

## 1. Interaction State Machine & Topology

```text
+-------------------------------------------------------------------------------+
|                      TREE MULTI-SELECTION STATE MACHINE                       |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ User Input ]                                                               |
|        |                                                                      |
|        +---- (Ctrl / Cmd + Click) -------> [ Toggle Set Membership ]          |
|        |                                   - selectedPaths.add/delete(path)   |
|        |                                   - lastAnchor = current             |
|        |                                   - updateSelectionUI()              |
|        |                                                                      |
|        +---- (Shift + Click) ------------> [ Range Selection Query ]          |
|        |                                   - Find index(anchor) & index(tgt)  |
|        |                                   - selectedPaths = slice(min, max)  |
|        |                                   - updateSelectionUI()              |
|        |                                                                      |
|        \---- (Standard Click) -----------> [ Single Select & Action ]         |
|                                            - selectedPaths = [current]        |
|                                            - lastAnchor = current             |
|                                            - Open file / Toggle directory     |
|                                                                               |
|  [ Downstream Actions on Selection Set ]                                      |
|        |                                                                      |
|        +---- Dragstart ------------------> Bundles all paths in DataTransfer  |
|        +---- Context Menu ---------------> Applies Copy/Move to all items     |
|        \---- Inline Rename (F2) ---------> Operates on primary active node    |
+-------------------------------------------------------------------------------+
```

---

## 2. Range Selection Algorithm (DOM Order)

When `Shift + Click` is triggered:
1. Locate the parent pane or tree container.
2. Query all rendered, visible `.tree-node` elements in that pane.
3. Identify `indexAnchor` of `lastAnchorNode.path`.
4. Identify `indexTarget` of the clicked node.
5. If both exist, clear the existing selection set and add all node paths from `Math.min(idxA, idxT)` to `Math.max(idxA, idxT)`.

### Reference Implementation
```javascript
let selectedPaths = new Set();
let lastAnchorNode = null; // { path, paneId, nodeEl }

function handleNodeClick(e, node, nodeEl, paneId) {
  e.stopPropagation();
  if (isNodeDragging) return;

  // Arrow click expands/collapses without affecting selection
  if (e.target.closest('.tree-arrow')) {
    toggleNodeDirectory(node, nodeEl);
    return;
  }

  const isCtrl = e.ctrlKey || e.metaKey;
  const isShift = e.shiftKey;

  // 1. Ctrl / Cmd: Discrete toggle
  if (isCtrl) {
    if (selectedPaths.has(node.path)) {
      selectedPaths.delete(node.path);
    } else {
      selectedPaths.add(node.path);
    }
    lastAnchorNode = { path: node.path, paneId, nodeEl };
    updateSelectionUI();
    return;
  }

  // 2. Shift: Continuous range selection
  if (isShift && lastAnchorNode && lastAnchorNode.paneId === paneId) {
    const paneEl = nodeEl.closest('.tree-pane') || document.getElementById(`pane_el_${paneId}`);
    if (paneEl) {
      const allNodes = Array.from(paneEl.querySelectorAll('.tree-node'));
      const idxAnchor = allNodes.findIndex((el) => el.dataset.path === lastAnchorNode.path);
      const idxTarget = allNodes.indexOf(nodeEl);

      if (idxAnchor !== -1 && idxTarget !== -1) {
        const start = Math.min(idxAnchor, idxTarget);
        const end = Math.max(idxAnchor, idxTarget);
        selectedPaths.clear();
        for (let i = start; i <= end; i++) {
          selectedPaths.add(allNodes[i].dataset.path);
        }
        updateSelectionUI();
        return;
      }
    }
  }

  // 3. Normal Click: Single select
  selectedPaths.clear();
  selectedPaths.add(node.path);
  lastAnchorNode = { path: node.path, paneId, nodeEl };
  updateSelectionUI();

  if (node.isDirectory) {
    toggleNodeDirectory(node, nodeEl);
  } else {
    vscode.postMessage({ command: 'openFile', filePath: node.path });
  }
}
```

---

## 3. Multi-Item Drag & Drop Bundling

When initiating a drag on a tree node:
- **Rule**: If the dragged node is already part of `selectedPaths`, drag **all** items in `selectedPaths`.
- If the dragged node is unselected, collapse selection to only that node.
- Populate `DataTransfer` with multi-line strings for `text/plain` and `text/uri-list`:

```javascript
nodeEl.addEventListener('dragstart', (e) => {
  if (!selectedPaths.has(node.path)) {
    selectedPaths.clear();
    selectedPaths.add(node.path);
    lastAnchorNode = { path: node.path, paneId, nodeEl };
    updateSelectionUI();
  }

  const activePaths = Array.from(selectedPaths);
  const advancePaths = activePaths.map(toAdvancedFilePath).join('\n');
  const uriList = activePaths.map(toFileUri).join('\n');

  currentDragSource = {
    sourcePaths: activePaths,
    sourcePath: node.path,
    sourcePaneId: paneId,
    isDirectory: node.isDirectory
  };

  e.dataTransfer.setData('text/plain', advancePaths);
  e.dataTransfer.setData('text/uri-list', uriList);
  e.dataTransfer.setData('application/vnd.code.tree.treepane', JSON.stringify(currentDragSource));
  e.dataTransfer.setData('text/x-treepane-path', activePaths.join('\n'));

  // Mark all selected DOM elements with .dragging class
  activePaths.forEach((p) => {
    document.querySelectorAll(`.tree-node[data-path="${CSS.escape(p)}"]`).forEach((el) => {
      el.classList.add('dragging');
    });
  });
});
```

---

## 4. Multi-Item Context Menu Execution

When right-clicking a node that belongs to an active multi-selection (`selectedPaths.size > 1`):
1. **Dynamic Labels**: Update labels with count badges (e.g. `Copy Path (3 items)`).
2. **Batch Move to Repo**: Move all selected paths into target repo in a single transaction.
3. **Multi-Path Copy**: Join all serialized paths with newlines (`\n`) for clean paste into editors and terminals.
4. **Single-Target Boundary**: Operations that only make sense on a single item (like `Rename` or `Open File`) operate strictly on the right-clicked node or are hidden.

---

## 5. CSS Visual Standards

```css
/* Multi-selection highlighting */
.tree-node.selected {
  background-color: var(--vscode-list-activeSelectionBackground, rgba(59, 130, 246, 0.22)) !important;
  outline: 1px solid var(--vscode-list-activeSelectionOutline, rgba(59, 130, 246, 0.45));
  outline-offset: -1px;
}

.tree-node.selected:hover {
  background-color: rgba(59, 130, 246, 0.32) !important;
}

/* Primary active/focused item in selection */
.tree-node.selected.active {
  background-color: rgba(59, 130, 246, 0.38) !important;
  outline: 1.5px solid var(--accent);
}
```
