---
name: bento-layout-playground
description: >-
  Enforce the Zero-Outer-Scroll Bento Split-Screen Playground architecture (>= 900px Desktop
  threshold including 900x900+, 60% Left / 40% Right draggable & expandable split, inverse-dimension
  iframe zoom, collapsible guided steps, conditional Markdown GitHub button, and fault-tolerant
  language-aware Text-to-Speech).
---

# 🍱 Bento Split-Screen Playground Skill (`bento-layout-playground`)

This skill defines the mandatory CSS Grid, Flexbox, Viewport Lock, Resizable Split, and Audio TTS engineering rules for the **Vintage Computing Arcade Playground** (`src/playground.html` at `domain/playground/<namatitle>`).

---

## 1. Core Invariants (Non-Negotiable Rules)

1. **`>= 900px` Desktop Detection (`900x900` and Higher)**:
   - Desktop Split-Screen mode MUST activate at **`@media (min-width: 900px)`** (never `960px` or `1024px`), ensuring any `900×900` or larger window renders the full 2-Column Bento Split-Screen.
   - Mobile/Portrait 1-Column Stack activates strictly at **`@media (max-width: 899px)`**.

2. **Zero Horizontal AND Zero Vertical Outer Scroll on Desktop (`>= 900px`)**:
   - On `@media (min-width: 900px)`, the outer document and `.playground-shell` MUST be locked to the viewport height (`100dvh` with `100vh` fallback) with **zero outer scrollbars**:
     ```css
     @media (min-width: 900px) {
       html, body {
         height: 100vh;
         height: 100dvh;
         max-height: 100dvh;
         overflow: hidden !important;
       }
       .playground-shell {
         height: 100vh;
         height: 100dvh;
         max-height: 100dvh;
         overflow: hidden !important;
         display: flex;
         flex-direction: column;
         box-sizing: border-box;
       }
       .stage-split-grid {
         flex: 1 1 0%;
         min-height: 0;
         min-width: 0;
         overflow: hidden;
       }
     }
     ```
   - Every flex/grid child in the Left and Right Bento columns MUST set `min-width: 0; min-height: 0;` so child content (`<iframe>`, `<pre><code>`) never forces the outer page to scroll horizontally or vertically.
   - Only **Cell `R2` (`.bento-slide-body`)** is allowed internal vertical scrolling (`overflow-y: auto; overflow-x: hidden;`).

3. **Default `60% Left / 40% Right` Draggable & Expandable Split**:
   - Default CSS Custom Property on `.stage-split-grid`: `--bento-left-pct: 60%;`
   - Desktop Grid Template:
     ```css
     grid-template-columns:
       minmax(0, var(--bento-left-pct, 60%))
       10px
       minmax(0, calc(100% - var(--bento-left-pct, 60%) - 10px));
     ```
   - **Iframe Pointer Shield During Drag**:
     While dragging `#bentoSplitResizer`, add `.is-resizing` to `.playground-shell`:
     ```css
     .playground-shell.is-resizing iframe {
       pointer-events: none !important;
       user-select: none !important;
     }
     ```
   - **Clamp Range**: `30%` minimum to `78%` maximum; double-clicking `#bentoSplitResizer` resets to `60%` Left / `40%` Right.

---

## 2. The 6 Bento Cells (`L1–L3` Left, `R1–R3` Right)

### Left Column (`60%` Default — Interactive Stage)
- **`L1` Stage Header (`flex-shrink: 0`)**:
  - Contains `📺 LIVE STAGE` title + `[📱 Mobile | 💻 Desktop]` toggle + `[ − | 100% | + ]` Screen Zoom pill + `[ ◧ 60:40 ]` Expand toggle + `[ ⟲ ]` Reload.
- **`L2` Live Screen (`flex: 1 1 0%; min-height: 0;`)**:
  - Uses Inverse-Dimension CSS Scaling (`width: calc(100% / var(--stage-zoom, 1))`, `height: calc(100% / var(--stage-zoom, 1))`, `transform: scale(var(--stage-zoom, 1))`, `transform-origin: 0 0`).
  - Automatically expands to fill 100% of the Left Column height when `L3` is collapsed.
- **`L3` Guided Steps (`flex-shrink: 0`, Collapsible)**:
  - Header bar includes `[◀]` `[▶]` and `[▾ Hide]` / `[▸ Steps]`.
  - Adding `.is-collapsed` hides `.tutorial-body` so `L2` claims the freed vertical space immediately.

### Right Column (`40%` Default — Slidev Content & Controls)
- **`R1` Title & Slide Header (`flex-shrink: 0`)**:
  - Cartridge Name, Component/Slide Tag (`#slidevElementTag`), Slide Heading (`#slidevHeading`), and Counter (`01 / 04`).
- **`R2` Current Slide Content (`flex: 1 1 0%; min-height: 0; overflow-y: auto;`)**:
  - Narrative description (`#slidevDescription`) + Code X-Ray block (`#codeFilename`, `#codeSnippetBody`, `[📋 Copy]`).
- **`R3` Unified Control Dock (`flex-shrink: 0`)**:
  - **Row 1 (Slide & TTS)**: `[ ◀ Prev ]` | `[ 🔊 Speak / ⏹ Stop ]` + `[ 🌐 ID | EN ]` | `[ Next ▶ ]`
  - **Row 2 (Cartridge Actions)**:
    - `[ ⬇️ Download ]`
    - `[ 🐙 GitHub ]` *(Conditional: rendered in 3-col grid if `githubUrl` exists in Markdown/metadata; hidden in 2-col grid if absent)*
    - `[ ↗ Open Live ]`

---

## 3. Verification Checklist
- [ ] At `900×900` viewport: `window.innerWidth >= 900` renders the 2-column `60% / 40%` Bento Split-Screen.
- [ ] At `>= 900px` viewport: `document.documentElement.scrollHeight <= document.documentElement.clientHeight` AND `document.documentElement.scrollWidth <= document.documentElement.clientWidth` (zero outer scrollbars).
- [ ] At `375×667` mobile portrait: `document.documentElement.scrollWidth <= document.documentElement.clientWidth` (zero horizontal scroll).
- [ ] Collapsing `L3` Guided Steps expands `L2` Live Screen smoothly without page overflow.
- [ ] Dragging `#bentoSplitResizer` resizes Left/Right panes smoothly without getting stuck over the `<iframe>`.
