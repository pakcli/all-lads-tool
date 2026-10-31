---
name: decoupled-engine-domain-isolation
aliases: [zero-hardcoded-domain-context, engine-satellite-isolation, domain-context-agnostic]
category: ARCHITECTURAL_GOVERNANCE
tags: [all-lads-tool, architecture, decoupling, rule-001, modularity, boundaries]
description: Strict architectural boundary enforcement prohibiting domain-specific context (e.g. sport, chemistry, app names) from leaking into decoupled framework engines or engine-level briefs.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 🛡️ Decoupled Engine & Domain Boundary Isolation (`decoupled-engine-domain-isolation`)

> [!IMPORTANT]
> **THE ENGINE-SATELLITE ISOLATION INVARIANT (Rule #001 Enforcement)**:
> A decoupled framework engine (e.g. `framework-quartz/quartz`) must remain **100% DOMAIN-AGNOSTIC, PORTABLE, AND CONTEXT-INDEPENDENT**.
> Domain-specific terminology, business taxonomies, satellite application names, and vault-specific features must **NEVER** leak into engine core code, engine stylesheets, or engine architectural briefs.

---

## 1. The Core Boundary Matrix

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   DECOUPLED ARCHITECTURE BOUNDARY MAP                  │
├────────────────────────────────────────────────────────────────────────┤
│ 1. FRAMEWORK ENGINE REPOSITORY (`framework-quartz/quartz/`)            │
│    - Role      : Reusable compiler, AST transformers, generic UI components│
│    - Scope     : Generic routing, layout frames, design tokens, export │
│    - Invariant : ZERO domain context (no "sports", "chemistry", app slugs) │
│    - Briefs    : `brief/vXX-XX_<generic-capability>.md`                │
├────────────────────────────────────────────────────────────────────────┤
│                                  │                                     │
│       ▲ STRICT ISOLATION         │ LOOSE INJECTION                     │
│       │ (No Upward Contamination)│ (Compiled as External Satellite)   │
│                                  ▼                                     │
├────────────────────────────────────────────────────────────────────────┤
│ 2. SATELLITE CONTENT VAULT (`framework-quartz-example-<domain>-library`)│
│    - Role      : Concrete content repository, markdown notes, taxonomies│
│    - Scope     : Sports positions, chemical molecules, custom metadata  │
│    - Invariant : Self-contained domain SSOT; no framework core code   │
│    - Briefs    : `brief/vXX-XX_<domain-milestone>.md`                  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Absolute Prohibitions

1. **No Domain Naming in Engine Briefs**:
   - ❌ **FORBIDDEN**: `brief/v01-03_sports-tactics-library-and-multiscope-print-export-engine.md` (Contaminates generic engine with specific satellite vault name).
   - ✅ **COMPLIANT**: `brief/v01-03_multiscope-print-export-toolbar-and-homepage-router.md` (Names only generic engine capabilities).

2. **No Hardcoded Domain Slugs or Filters in Engine Code**:
   - ❌ **FORBIDDEN**: `entries.filter(e => e.slug !== "sports/index" && e.slug !== "chemistry/index")`
   - ✅ **COMPLIANT**: `entries.filter(e => e.slug && !cfg.ignorePatterns.includes(e.slug))`

3. **No Domain Text in Generic Toolbars or Dialogs**:
   - ❌ **FORBIDDEN**: Hardcoded titles like `"Chemistry Garden - Dossier Ekspor"`.
   - ✅ **COMPLIANT**: Dynamic title resolution: `document.querySelector(".page-title a")?.textContent || cfg.pageTitle || "Document Export"`.

4. **No Domain-Specific Style Rules in Engine SCSS**:
   - ❌ **FORBIDDEN**: Hardcoding sport or chemical card layouts directly into `custom.scss`.
   - ✅ **COMPLIANT**: Generic layout primitives (`[data-frame="..."]`, `[data-paper="true"]`) driven declaratively by plugin manifests or theme presets.

---

## 3. Authoring Checklist for AI Coding Agents

Before saving any file or authoring a brief in a framework engine repository:

- [ ] **Check Path & Filename**: Does the brief filename contain domain terms (sport, chemistry, quiz, blog)? If yes, strip them immediately.
- [ ] **Check Frontmatter Title**: Is the brief titled around generic engine systems (router, parser, toolbar) rather than a satellite vault?
- [ ] **Scan AST/Code Changes**: Are there any string literals targeting specific folders or slugs belonging to a satellite vault? Replace with dynamic metadata or configuration options.
- [ ] **Relocate Domain Specifications**: Does this brief specify domain data schemas (e.g. athlete positions, moves dictionary, SMILES)? Move those sections into the satellite vault's own `brief/` folder.
- [ ] **Verify Portability**: Can the framework engine compile a completely unrelated satellite vault (e.g. a music database or legal encyclopedia) without carrying phantom leftovers of sports or chemistry?
