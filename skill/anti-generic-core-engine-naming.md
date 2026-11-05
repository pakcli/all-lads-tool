---
name: anti-generic-core-engine-naming
aliases: [no-core-engine-naming, domain-specific-submodule-naming, anti-core-engine-anti-pattern, explicit-capability-naming]
category: MODULAR_SCRIPTING_STANDARDS
tags: [all-lads-tool, architecture, naming-convention, modularity, anti-pattern, adapter]
trigger: always_on
description: Prohibits ambiguous, catch-all names like 'core-engine', 'engine', 'core', or 'manager' in modular adapter scripting; mandates domain-specific, capability-driven nomenclature for all submodules.
pros:
  - "Eliminates ambiguous catch-all files where unrelated code accumulates"
  - "Ensures instant cognitive clarity: each file name describes its exact capability"
  - "Fosters true single-responsibility modular architecture in adapter scripts"
cons:
  - "Requires upfront precision in naming domain responsibilities"
---

# Anti-Generic "Core Engine" Naming Standard (`anti-generic-core-engine-naming`)

> [!CRITICAL]
> **THE ANTI-CORE-ENGINE INVARIANT**:
> **NEVER** name any file, module, script, class, or service `core-engine`, `core_engine`, `engine`, `core`, or `manager`.
> Catch-all names are ambiguous, obscure architectural intent, and act as "junk-drawers" where unrelated logic silently metastasizes.
> Every submodule in modular adapter scripting **MUST** be named with explicit, domain-specific, capability-driven terminology.

---

## 1. The Architectural Rationale

In modular scripting (e.g. decomposing a large monolithic `.psm1` or `.py` adapter into sub-components), naming a component `core-engine` introduces severe engineering debt:

1. **Ambiguity**: "Core Engine" tells the engineer nothing about what data structures, protocols, APIs, or system boundaries it manages.
2. **Junk-Drawer Attraction**: Engineers who cannot decide where a function belongs will instinctively dump it into whatever is labeled "core" or "engine", rapidly re-creating the exact monolith you sought to decompose.
3. **Impediment to Refactoring**: It is impossible to isolate or mock a module whose scope is undefined ("core").

---

## 2. Naming Matrix: Forbidden vs. Domain-Specific Replacements

| Forbidden Generic Name | Why It Is Rejected | Required Domain-Specific Name | Exact Responsibility |
| :--- | :--- | :--- | :--- |
| `core-engine.ps1` / `engine.ps1` | Ambiguous catch-all | `clipboard-jit-inspector.ps1` | Inspects OS clipboard formats (`CF_HDROP`, text) on demand. |
| `core-engine.ps1` / `core.ps1` | Obscures persistence | `clipboard-history-store.ps1` | Handles JSON serialization & loading to executor options. |
| `core-engine.ps1` / `engine.py` | Vague transformation | `clipboard-mode-transformer.ps1` | Converts snapshot objects to 4 target modes & injects. |
| `engine-colors.ps1` | Vague coloring | `drive-color-protocol.ps1` | Maps drive letters (`C:` red, `D:` blue, `E:`+ green). |
| `ui-engine.ps1` / `manager.ps1` | Generic UI dumping | `ui-card-renderer.ps1` | Builds WPF row cards, accordion cells, and badges. |
| `main-engine.ps1` / `host.ps1` | Ambiguous window logic | `panel-window-host.ps1` | Instantiates WPF XAML window and dispatcher timer loop. |

---

## 3. Modular Adapter Decomposition Rule

When a monolithic adapter script (e.g. `detector-clipboard-4-mode.psm1`) needs to be broken down (*dipotong-potong*):

1. **Dedicated Sub-directory**:
   Place sub-components inside a folder named after the tool without generic words:
   `script/<context>/adapter/<tool-slug>/`
2. **Explicit Capability Files**:
   Divide the responsibilities strictly into granular files:
   - `<domain>-<capability>-store.<ext>` (Persistence / State)
   - `<domain>-<capability>-inspector.<ext>` (Detection / JIT Analysis)
   - `<domain>-<capability>-transformer.<ext>` (Transformation / Conversion)
   - `<domain>-<capability>-protocol.<ext>` (Business Rules / Color Coding)
   - `<domain>-<capability>-renderer.<ext>` (Visual Presentation / UI Components)
   - `<domain>-<capability>-host.<ext>` (Host Window / Lifecycle)
3. **Facade Module**:
   The primary adapter `.psm1` acts as a clean, declarative facade that dot-sources the specific submodules and exports public members.
