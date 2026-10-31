---
description: RULE #002 — Mobile View ZERO Horizontal Scroll on Portrait
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE #2 — Mobile View: ZERO Horizontal Scroll on Portrait (`overflow-x: clip`)

## Core Constraint
- On Mobile Portrait viewports (`320px` – `768px`), the page must **never** scroll horizontally (`document.documentElement.scrollWidth <= document.documentElement.clientWidth`).

## Mandatory Implementation Standards
1. **Viewport Horizontal Clip Lock (Sticky-Safe)**:
   - `html, body, .arcade-shell, .playground-shell` must enforce:
     ```css
     max-width: 100%;
     overflow-x: clip;
     box-sizing: border-box;
     ```
   - Always use `overflow-x: clip` instead of `overflow-x: hidden` on `html` and `body` so horizontal overflow is strictly blocked while `position: sticky` on the CLI Navbar (`header[data-role="sticky-navbar"]`) continues to work natively.

2. **Safe CSS Grid Tracks (`minmax(0, 1fr)`)**:
   - All CSS Grid layouts (`.app-cards-grid`, `.stage-split-grid`, `.hero-metric-row`, `.action-sub-grid`) must use `minmax(0, 1fr)` instead of bare `1fr` (e.g., `grid-template-columns: repeat(2, minmax(0, 1fr))` or `minmax(0, 1fr)`), and grid children must set `min-width: 0; max-width: 100%;` so child content (`<pre>`, tags, buttons, badges) never expands grid columns beyond the portrait viewport.

3. **Mobile Portrait 2-Column `GridView` vs 1-Column `DetailView`**:
   - In Mobile 2-Column `GridView` (`[⊞]`), only the 5 core elements are displayed inside each `.floppy-card` (**Pin Toggle always at top-right corner**, **Thumbnail**, **Title Text**, **Btn Download HTML**, **Btn Open Standalone**) to guarantee zero horizontal crowding.
   - The `#diskCounterBadge` (`💾 6/6`) and View Mode Toggle (`[⊞] | [▤]`) must sit on **one single line** using compact symbols.
