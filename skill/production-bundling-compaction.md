---
name: production-bundling-compaction
description: >-
  Standardized production build pipeline enforcing JavaScript variable mangling via Terser CLI,
  high-performance CSS regex compaction, HTML minification, binary asset pass-through, and
  before/after size audit reporting for the Vintage Computing Arcade.
---

# ⚡ Production Bundling, Terser Mangling & Asset Compaction

This skill governs the production build, minification, and obfuscation pipeline for `fadhlisl-my-id`, transforming modular source code in `src/` into the compact, airgap-ready 7-file distribution in `public/`.

---

## 1. Core Pipeline Components

### A. JavaScript Compaction & Variable Mangling (Terser CLI)
* **Command**: `npx --yes terser <input.js> -o <output.js> --module --mangle --compress passes=2`
* **Mandatory Flags**:
  * `--module`: Guarantees native ES Module (`import` / `export`) syntax remains 100% valid.
  * `--mangle`: Scrambles local variable names, function arguments, and internal iterators into single characters (`a`, `b`, `c`), protecting logic from inspection.
  * `--compress passes=2`:
    * Dead code elimination (removes uncalled functions and unused variables).
    * Compresses `if-else` branches into compact ternary operators.
    * Strips all single-line (`//`) and block (`/* ... */`) comments.
    * Removes all redundant whitespace and newline characters.

### B. CSS Compactor & Space Reducer
* **Mechanism**: High-performance regex parser that collapses CSS rules.
* **Transformations**:
  1. Strip all comment blocks: `/\*.*?\*/` ➔ `""`
  2. Remove whitespace around operators: `\s*([{};:,>+~])\s*` ➔ `$1`
  3. Strip redundant trailing semicolons: `;}` ➔ `}`
  4. Collapse multiple spaces into single stream.
* **Target Reduction**: 30% – 45% file size savings.

### C. HTML Minifier
* **Mechanism**: Cleans up markup distributions (`apps.html`, `playground.html`, `index.html`).
* **Transformations**:
  1. Strip standard HTML comments: `<!--.*?-->` ➔ `""`
  2. Collapse whitespace between tags: `>\s+<` ➔ `><`
  3. Strip redundant indentation without altering `<pre>` or `<code>` blocks.

### D. Media & Binary Pass-Through
* Binary assets (`.png`, `.jpg`, `.webp`, `.svg`, `.ico`) in `src/assets/` and `src/icons/` are copied directly using binary streams, ensuring zero image corruption or metadata loss.

---

## 2. Before/After Size Audit Report

Upon every build execution, the pipeline calculates exact byte counts and displays a formatted audit table:

```text
==========================================================================
  [*] PRODUCTION BUILD & COMPACTION AUDIT REPORT
==========================================================================
  File Name          | Original    | Compacted   | Reduction
  -------------------+-------------+-------------+------------
  script.js          | 45.50 KB    | 24.20 KB    | -46.8%  [*]
  navigation-url.js  |  8.20 KB    |  4.80 KB    | -41.5%  [*]
  winget.js          |  6.10 KB    |  3.70 KB    | -39.3%  [*]
  style.css          | 32.40 KB    | 19.80 KB    | -38.9%  [*]
  winget.css         |  5.30 KB    |  3.40 KB    | -35.8%  [*]
  apps.html          | 52.40 KB    | 36.10 KB    | -31.1%  [*]
  playground.html    | 35.20 KB    | 24.60 KB    | -30.1%  [*]
  -------------------+-------------+-------------+------------
  TOTAL PAYLOAD      | 185.10 KB   | 116.60 KB   | -37.0%  (SAVED 68.5 KB)
==========================================================================
```

---

## 3. Automation Tooling

The companion PowerShell script `all-script/powershell/compile-arctitecture-bundledjs.ps1` executes this complete specification, reading declarative targets from `build.json`.
