---
trigger: always_on
description: RULE #003 — Immutable Theme CSS (Do Not Edit src/theme/theme.css)
---

# RULE #1 — DO NOT EDIT `src/theme/theme.css` (or `src/theme/theme.scss`)

## Core Constraint
- `src/theme/theme.css` (and `src/theme/theme.scss`) is the **immutable master Obsidian theme stylesheet** and must remain **100% untouched** (`0` edits allowed).
- Never modify, reformat, or overwrite `src/theme/theme.css` or `src/theme/theme.scss` directly.

## Allowed Extension & Override Targets
All visual fixes, surface fill restorations, CSS custom property overrides, and responsive layout rules must be implemented strictly in the following modular consumer files:

1. **`src/modules/theme-engine.js`** — Runtime CSS Custom Property injection (e.g., computing valid hex values for `--base-accent`, `--accent-1`, `--accent-2`, and `--interactive-accent` on `document.documentElement` and `document.body`).
2. **`src/theme/winget.css`** — Modal, Widget, and Global Shell surface overrides (`.arcade-modal-window`, `.workspace-leaf`, global `overflow-x: clip`).
3. **`src/theme/flopydisk-cornercut.css`** — Physical 3.5" Floppy Diskette card skeuomorphism, 45° DIY rotated bevel bracket (`.floppy-corner-cut`), and Mobile `GridView` / `DetailView` card layout rules.
4. **`src/library.html` & `src/playground.html`** — Page-specific DOM structure, inline `<style>` layout blocks, and view-mode toggle logic.
