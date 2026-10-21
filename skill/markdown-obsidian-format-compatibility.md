---
name: markdown-obsidian-format-compatibility
description: >-
  Standardized rules and conventions for authoring Markdown files (.md) with 100% native
  Obsidian compatibility. Enforces zero-quote YAML frontmatters, native wikilinks ([[...]]),
  quick-switcher optimization via aliases, zero-id invariants, and folder-cartridge layouts.
---

# 📓 Obsidian-Compatible Markdown Specification (`markdown-obsidian-format-compatibility`)

This skill establishes the authoritative formatting standards for creating, updating, and maintaining Markdown documents across the repository with **100% native Obsidian compatibility**, seamless build-engine parsing, and zero maintenance friction.

---

## 1. Core Invariants (Non-Negotiable Rules)

### 1.1 Invariant 1: ZERO Quotes (`"`) in YAML Frontmatter
Obsidian v1.4+ introduces visual **Properties (Metadata Editor)**. Wrapping YAML values in double quotes (`"..."`) forces Obsidian to interpret them as literal escaped strings, breaking native wikilink chips and tags.

* ❌ **FORBIDDEN (Quoted Values)**:
  ```yaml
  title: "Unit Circle Resolver"
  img: "[[img.webp]]"
  tags: ["math", "canvas"]
  file-size: "6.8 KB"
  ```
*  **MANDATORY (Zero-Quote Pure Obsidian YAML)**:
  ```yaml
  title: Unit Circle Resolver
  img: [[img.webp]]
  tags: [math, canvas]
  file-size: 6.8 KB
  ```

---

### 1.2 Invariant 2: Quick-Switcher Optimization via `aliases:`
When using the modular folder structure (`apps/<slug>/index.md`), naming notes `index.md` can cause ambiguity in Obsidian's Quick Switcher (`Ctrl + O`).

To solve this, **every `index.md` must include an `aliases:` array** declaring the app slug and human-readable titles:

```yaml
title: Unit Circle Resolver
aliases: [radiansincostan, unit-circle]
```

> [!TIP]
> With `aliases` defined, typing `radians` or `unit circle` in Obsidian's `Ctrl + O` or open prompt instantly resolves to `apps/radiansincostan/index.md` without typing "index".

---

### 1.3 Invariant 3: Native Obsidian Wikilinks for Local Media
All media attachments located inside the same cartridge directory must be referenced using raw Obsidian wikilinks without path prefixes:

* Frontmatter: `img: [[img-lightmode.webp]], [[img-darkmode.webp]]`
* Note Body: `![[img.webp|450]]`
* Standalone Links: `[Launch App](index.html)`

The core build pipeline (`src/modules/build-bundle.js`) parses `\[\[(.*?)\]\]` automatically into public distribution URLs.

---

### 1.4 Invariant 4: Strict ZERO `id:` Standard
Frontmatter must **never** contain an `id:` property. The unique slug is strictly derived from the parent directory basename (`slug = path.basename(dir)`).

---

### 1.5 Invariant 5: Rule #3 (Zero Hardcoded Variables)
Per [`all-lads-tool/rules/001-skills-no-hardcoded-variables.md`](../rules/001-skills-no-hardcoded-variables.md):
* Never include machine drive letters (`D:\`, `C:\`, `d:/`) in Markdown links or code examples.
* Use relative navigation: `index.html`, `index_playground.html`, `../_catalog.json`.

---

## 2. Standard Cartridge File Layout

Every modular application cartridge inside `apps/<slug>/` adheres to this self-contained, submodule-ready structure:

```text
apps/<slug>/
├── index.html            # Standalone Vanilla / WebGL application
├── index.md              # Obsidian-compatible documentation & metadata
├── img.webp              # Default cover / fallback thumbnail
├── img-darkmode.webp     # High-contrast dark theme screenshot
└── img-lightmode.webp    # Crisp light theme screenshot
```

---

## 3. Canonical `index.md` Template

```markdown
---
title: Unit Circle Resolver
aliases: [radiansincostan, unit-circle]
sector: edu
category: MATH & CANVAS
scope: [edu, math, canvas]
file-size: 6.8 KB
tags: [arcade, math, zero-backend]
overview: Interactive trigonometric unit circle calculator. Drag dynamic angle point to solve real-time sin, cos, and tan with exact radical fractions.
link-github: https://github.com/fadhlisl/fadhlisl-my-id
img: [[img-lightmode.webp]], [[img-darkmode.webp]]
badge: v2.4
---

# 📐 Unit Circle Resolver

> [!INFO]
> **Cartridge Status**: Active | **Runtime**: Vanilla JS Canvas2D | **Zero-Backend**

## 1. Quick Navigation
* 🚀 **Launch Standalone**: [Launch App](index.html)
* 📐 **Bento Sandbox Dock**: [Open Playground](index_playground.html)

---

## 2. Visual Snapshot
![[img.webp|450]]

---

## 3. Architecture & Functional Specification
* **Trigonometric Solver**: Real-time evaluation of radian angles and exact radical fractions.
* **Viewport Lock**: Complies with Rule #2 (zero horizontal scroll across mobile viewports).
```

---

## 4. Obsidian Dataview Query Compatibility

Because properties follow consistent types without quote noise, dynamic library views can be rendered in Obsidian using Dataview:

````markdown
```dataview
TABLE
  category as "Category",
  sector as "Sector",
  file-size as "Size",
  tags as "Tags"
FROM "apps"
WHERE file.name = "index"
SORT file.folder ASC
```
````

---

## 5. Verification Checklist

Before saving any `.md` file intended for `apps/` or `docs/`:
- [ ] Are all YAML properties free of wrapping double quotes (`"`)?
- [ ] Are local images referenced as wikilinks (`[[img.webp]]` / `![[img.webp]]`)?
- [ ] Does `index.md` declare `aliases:` with the slug and clean title?
- [ ] Is `id:` completely omitted from the frontmatter?
- [ ] Are all relative links using forward slashes with zero hardcoded machine paths?
