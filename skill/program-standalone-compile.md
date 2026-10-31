---
name: program-standalone-compile
aliases: [standalone-compiler, bundle-to-standalone, inline-modules-compiler]
category: COMPILATION_AND_BUNDLING
tags: [all-lads-tool, compiler, standalone, bundler, inliner, distribution]
description: Protocol and compiler specification for packaging modular programs and their versioned adapters into single-file zero-dependency executables (<program>_stand.<ext>).
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Program Standalone Compile Protocol (`program-standalone-compile`)

> [!IMPORTANT]
> **THE STANDALONE BUNDLING INVARIANT**:
> The standalone compiler parses a modular source program (`<program>.<ext>`), resolves all imported files from `adapter/vxx-xx-xx.<ext>`, and inlines their contents directly into a single self-contained distribution file: `<program>_stand.<ext>`.

---

## 1. The Compilation Transformation

$$\text{script/<context>/<program>.<ext>} + \text{adapter/vxx-xx-xx.<ext>} \xrightarrow{\text{compile}} \text{script/<context>/<program>\_stand.<ext>}$$

```text
┌────────────────────────────────────────────────────────────────────────┐
│                     STANDALONE COMPILATION PIPELINE                    │
├────────────────────────────────────────────────────────────────────────┤
│ 1. READ SOURCE        : Reads modular <program>.<ext>                  │
│ 2. DETECT IMPORTS     : Identifies relative calls to adapter/ & core   │
│ 3. INLINE DEFINITIONS : Flattens functions/classes into file body      │
│ 4. INJECT HEADER      : Prepends build timestamp and target metadata   │
│ 5. WRITE STANDALONE   : Writes self-contained <program>_stand.<ext>    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Inlining Rules Across Runtimes

1. **PowerShell (`.ps1`)**:
   - Matches: `Import-Module "$PSScriptRoot/adapter/vxx-xx-xx.psm1"`
   - Action: Strips `Export-ModuleMember`, embeds function scriptblocks directly.
2. **Python (`.py`)**:
   - Matches: `from adapter.vxx_xx_xx import ...`
   - Action: Inlines helper classes/functions directly into the standalone file body.
3. **JavaScript (`.js`)**:
   - Matches: `import { ... } from './adapter/vxx-xx-xx.js'`
   - Action: Bundles into an IIFE / single self-executing script with zero `node_modules`.

---

## 3. Distribution Characteristics
* `<program>_stand.<ext>` requires **zero subfolders** or external libraries to execute.
* Can be copied to any computer, USB drive, or remote server and executed directly via drag-and-drop.
