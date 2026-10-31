---
name: program-tostandalone-decombine
aliases: [standalone-decombiner, decompile-to-modular, unbundle-standalone]
category: COMPILATION_AND_BUNDLING
tags: [all-lads-tool, decombine, unbundle, reverse-compiler, modular]
description: Protocol and reverse-engineering specification for extracting inlined functions from a standalone executable (<program>_stand.<ext>) back into a modular source program (<program>.<ext>) and dedicated adapter/ files.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Program to Standalone Decombine Protocol (`program-tostandalone-decombine`)

> [!IMPORTANT]
> **THE REVERSE MODULARIZATION INVARIANT**:
> When maintaining, refactoring, or updating an old single-file standalone script (`<program>_stand.<ext>`), the decombiner splits the monolithic file back into its clean development pair:
> 1. The clean entry orchestrator: `<program>.<ext>`
> 2. The version-specific logic: `adapter/vxx-xx-xx.<ext>`

---

## 1. The Decombine Transformation

$$\text{script/<context>/<program>\_stand.<ext>} \xrightarrow{\text{decombine}} \begin{cases} \text{script/<context>/<program>.<ext>} \\ \text{script/<context>/adapter/vxx-xx-xx.<ext>} \end{cases}$$

---

## 2. Decombination Steps

1. **Header Identification**:
   - Locates compiler boundary comments:
     `# === INLINED FROM: adapter/vxx-xx-xx ===`
2. **Function Slicing**:
   - Extracts helper functions, environment checks, and versioned APIs into `adapter/vxx-xx-xx.<ext>`.
3. **Dispatcher Restoration**:
   - Restores the clean source entry point with relative imports (`Import-Module`, `from adapter import ...`).
4. **Verification**:
   - Tests that `<program>.<ext>` runs identically in development mode.
