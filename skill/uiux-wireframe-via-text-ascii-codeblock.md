---
name: uiux-wireframe-via-text-ascii-codeblock
description: >-
  Standardized rules and atomic element grammar for drafting UI/UX wireframes using
  monospace text ASCII/Unicode codeblocks. Enforces strict character-width alignment,
  Rule #2 mobile constraints (<=60 cols), and atomic uncombined element syntax.
---

# 📐 UI/UX Monospace ASCII Wireframe Rules (`uiux-wireframe-via-text-ascii-codeblock`)

This skill establishes the core formatting rules and atomic element grammar for drafting UI/UX wireframes in monospace codeblocks (````text` or ````ascii`).

It enforces **atomic, uncombined elements**—avoiding fragile, full-page mockups that break monospace alignment.

---

## 1. Core Invariants (Basic Rules)

1. **Strict Monospace Boundary Alignment**:
   - Every bordered box MUST be a closed rectangle where **every line has the exact same character length**.
   - No jagged borders, broken vertical walls, or mismatched end characters.
   - **Zero Wide Emojis in Boxes**: Do not use variable-width emojis (e.g. ⚡, 💾, 📱) inside bordered lines; they render inconsistently across font renderers (1 vs 2 columns), breaking vertical alignment. Use standard ASCII/Unicode glyphs (`[*]`, `[+]`, `[x]`, `>`).

2. **Viewport Width Budgets**:
   - **Mobile Portrait (Rule #2)**: Strictly **<= 60 characters width** (prevents horizontal scrolling on 320px–768px screens).
   - **Desktop / Wide**: **<= 80 characters width**.

3. **Atomic Elements Only (Not Combined)**:
   - Present UI elements in isolation (atoms and components).
   - Do NOT construct massive, combined full-page screens inside skill files.

---

## 2. Character Library

```text
Box Single:    ┌  ─  ┐  │  └  ┘  ├  ┤  ┬  ┴  ┼
Box Double:    ╔  ═  ╗  ║  ╚  ╝  ╠  ╣  ╦  ╩  ╬
Dividers:      ─ (Horizontal)    │ (Vertical)    ║ (Splitter Gutter)
Pointers:      > _ (Prompt)      ^   v   <   >   <--->
```

---

## 3. Atomic Element Specifications (Uncombined)

### A. Containers & Bounding Boxes

Single line container (26 cols):
```text
┌────────────────────────┐
│ Container Title        │
│ Content line goes here │
└────────────────────────┘
```

Double line container (26 cols):
```text
╔════════════════════════╗
║ Header / Highlight     ║
╚════════════════════════╝
```

---

### B. Buttons & Keycaps

```text
[ Button ]   [ Primary Action ]   [ Cancel ]   [ X ]
```

---

### C. Input Fields & Prompts

Text input (40 cols):
```text
[ Type value here...                   ]
```

Search input (40 cols):
```text
[ Search query...                    v ]
```

Terminal / CLI Prompt:
```text
> [ Command input...                   ]
```

---

### D. Selection, Toggles & Tabs

Checkboxes:
```text
[X] Option selected       [ ] Option unselected
```

Radio Buttons:
```text
(*) Choice active         ( ) Choice inactive
```

Dropdown / Select (30 cols):
```text
[ Select an option          v ]
```

Tabs / Segmented Control:
```text
[ Tab 1 (Active) ] | Tab 2 | Tab 3
```

Toggles:
```text
[ ON |*]   [*| OFF ]
```

---

### E. Badges & Status Indicators

```text
(Badge)   [Active]   [Idle]   [Disabled]
```

---

### F. Split Column Layout (Atomic, 50 cols)

```text
┌──────────────────────┬───┬─────────────────────┐
│ Left Column (60%)    │ ║ │ Right Column (40%)  │
└──────────────────────┴───┴─────────────────────┘
```

---

### G. Card Item Component (Atomic, 50 cols)

```text
┌────────────────────────────────────────────────┐
│ Card Title                          [ Badge ]  │
├────────────────────────────────────────────────┤
│ Preview / Content Slot                         │
│ Description text line                          │
├────────────────────────────────────────────────┤
│ [ Action 1 ]                    [ Action 2 ]   │
└────────────────────────────────────────────────┘
```

---

## 4. Agent Pre-Flight Checklist

Before outputting any text wireframe:
- [ ] Are all lines in the box the exact same character count?
- [ ] Is the width <= 60 characters for mobile views?
- [ ] Are variable-width emojis excluded from bordered lines to protect alignment?
- [ ] Are elements kept atomic rather than pasted into fragile full-page mockups?
