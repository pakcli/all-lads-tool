---
name: read-architecture-markdown-preserve-exact-ui-outcome
aliases: [read-new-architecture-keep-exact-ui, architecture-migration-zero-ui-drift, preserve-exact-ui-outcome-during-refactor, refactor-architecture-keep-identical-ui]
category: IMPLEMENTATION_PROTOCOL
tags: [all-lads-tool, architecture, uiux, refactor, preservation, immutability, fidelity, protocol]
description: Definitive instruction protocol requiring agents to ingest new architectural markdowns, modernize URLs, data flows, and structural patterns, while strictly preserving 100% identical, pixel-faithful UI outcomes unless explicitly instructed to change the visual interface.
dependencies:
  - "[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]"
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[zero-hardcoded-variables]]"
related:
  - "[[say-sorry-agent-make-decision-not-based-on-brief-latest-version]]"
  - "[[uiux-wireframe-via-text-ascii-codeblock]]"
  - "[[immutable-theme-css]]"
pros:
  - "Eliminates visual regression and accidental UI destruction during architectural overhauls"
  - "Ensures clean decoupling between backend/routing refactors and frontend visual fidelity"
  - "Forces agents to adapt new data schemas to existing UI rather than breaking UI to fit data"
cons:
  - "Requires meticulous verification of before-and-after UI element parity"
  - "Prohibits unsolicited visual redesigns or layout simplifications"
---

# Read Architecture Markdown & Preserve Exact UI Outcome Protocol (`read-architecture-markdown-preserve-exact-ui-outcome`)

> [!IMPORTANT]
> **THE UI IMMUTABILITY INVARIANT DURING REFACTORING**:
> When instructed to read a new architectural specification (`brief/vXX-XX-XX_*.md` or design markdown) and implement it:
> 1. **WHAT CHANGES**: Only the underlying architecture, URLs, routing endpoints, modular adapters, and data pipelines.
> 2. **WHAT STAYS EXACTLY THE SAME**: The user-facing visual UI outcome (layout, dimensions, aspect ratios, styling, typography, buttons, interactive controls, and UX ergonomics).
> 
> **Unless the user explicitly states "change the UI layout" or "redesign the visual appearance", the UI outcome MUST remain 100% identical and faithful to the reference.**

---

## 1. The Core Problem: Architectural Scope Creep & UI Drift

A critical failure mode during agentic refactoring occurs when an agent:
1. Reads a new architectural specification focused on routing, folder structures, or API URLs.
2. Assumes that changing the architecture justifies altering, simplifying, or modernizing the visual interface.
3. Silently removes buttons, breaks established column ratios, alters aspect ratios (e.g. destroying 3:4 card containers or 16:9 media slots), or drops mobile width budgets.

Under this protocol, **architectural refactoring and visual redesign are strictly quarantined from each other**.

---

## 2. The 4-Phase Implementation Pipeline

```text
+-------------------------------------------------------------------------------+
|         ARCHITECTURE MIGRATION & UI PRESERVATION PIPELINE                    |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ STEP 1: ARCHITECTURAL MARKDOWN INGESTION ]                                 |
|  - Read the latest architectural brief in brief/vXX-XX-XX_*.md                |
|  - Isolate architectural targets: New URLs, updated paths, schema keys,       |
|    modular adapter boundaries, routing endpoints.                            |
|                                       |                                       |
|                                       v                                       |
|  [ STEP 2: BASELINE UI OUTCOME LOCK ]                                         |
|  - Inspect current visual outcome (DOM, CSS classes, terminal ASCII layout).   |
|  - Lock visual parameters:                                                    |
|    * Aspect ratios (3:4 card container, 16:9 media slot).                     |
|    * Character budgets (60 cols mobile, 72 cols desktop).                     |
|    * Button positions, labels, icons ([Copy], [Download], [ >_ ]).            |
|    * Typography, monospace borders, theme palette.                            |
|                                       |                                       |
|                                       v                                       |
|  [ STEP 3: SURGICAL UNDER-THE-HOOD REWIRING ]                                 |
|  - Update URLs, fetch pipelines, state bridges, and file paths.               |
|  - ADAPT DATA TO UI, NEVER BREAK UI TO FIT DATA:                              |
|    If the new architecture provides a new data structure, write an adapter    |
|    layer that maps the new data into the existing UI components.              |
|                                       |                                       |
|                                       v                                       |
|  [ STEP 4: EXACT OUTCOME VERIFICATION ]                                       |
|  - Compare Before vs After UI:                                                |
|    * Is every visual button, icon, and card still present?                    |
|    * Are layout widths and aspect ratios 100% identical?                      |
|    * Did any visual element change without explicit user request?             |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 3. Strict Boundary Rules

### Rule 1: Adapt Data to Existing UI, Do Not Break UI for Data
When new architecture introduces new JSON schemas, endpoints, or data objects, the agent must write an internal adapter function (transformer) that maps the new data into the exact format expected by the existing UI components.
- **Forbidden**: Deleting a UI badge because the new schema doesn't have that field.
- **Required**: Providing a clean fallback or mapping an equivalent property so the visual outcome is preserved.

### Rule 2: Zero Unsolicited Visual Modernization
Never "clean up", "streamline", or "improve" UI styling on your own initiative during an architectural task.
- If the current UI uses a retro terminal CRT aesthetic with monospace borders (`+`, `-`, `|`), preserve that exact aesthetic.
- If the current UI has a dual-action button group (`[Copy] [DL]`), retain both buttons with identical widths and spacing.

### Rule 3: URL and Path Modernization Scope
Changes must be strictly confined to:
- Updating distribution and clone URLs (e.g. updating repository remote paths).
- Updating directory pointers and modular adapter imports (`script/common/adapter/...`).
- Updating state bridges (`_run.json`) and configuration paths.
- Updating routing endpoints in fetch requests or links.

---

## 4. Verification Checklist Before Marking Complete

Before declaring an architectural implementation complete:

- [ ] **Markdown Source Verified**: Did I read and follow the highest canonical brief in `brief/`?
- [ ] **UI Parity Audit**: Is the rendered UI layout, column count, and aspect ratio identical to the pre-refactor state?
- [ ] **Component Audit**: Are all buttons, copy actions, modals, tabs, and status badges present and in the exact same positions?
- [ ] **Character Budget Verified**: Does the output still respect width limits (e.g. 60 cols mobile, 72 cols desktop)?
- [ ] **Zero Unasked Removals**: Did I verify compliance with `01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED`?
- [ ] **Architectural Integrity**: Are the new URLs, modular adapters, and state paths functioning properly behind the preserved UI?
