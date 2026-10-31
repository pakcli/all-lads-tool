---
name: obsidian-wikilink-frontmatter-standard
aliases: [obsidian-wikilink-frontmatter, frontmatter-wikilinks, yaml-wikilinks]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, obsidian, frontmatter, wikilinks, yaml, metadata]
description: Standard operating protocol for formatting Obsidian-compatible wikilinks inside YAML frontmatter using double quotes and double brackets ("[[...]]") to enable native clickable chips and graph relations.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Obsidian Wikilink Frontmatter Standard (`obsidian-wikilink-frontmatter-standard`)

> [!IMPORTANT]
> **THE FRONTMATTER WIKILINK INVARIANT**:
> In Obsidian Markdown YAML Frontmatter, all wikilinks **MUST BE WRAPPED IN DOUBLE QUOTES**:
> `dependencies: - "[[target-note]]"`
> Without double quotes, raw YAML parsers treat unquoted `[[` as a syntax error (reserved flow sequence character).

---

## 1. Syntax Rules

### 1.1 List / Array Property Format (MANDATORY)

```yaml
---
title: My Document Title
dependencies:
  - "[[skill-one]]"
  - "[[skill-two]]"
related:
  - "[[note-a]]"
  - "[[note-b]]"
---
```

### 1.2 Single Scalar Property Format

```yaml
---
title: My Document Title
parent: "[[v01-00_main-idea]]"
primary-skill: "[[modular-versioned-dependency-checker]]"
---
```

---

## 2. Why Double Quotes Are Required in Frontmatter

| Syntax | Parser Behavior | Obsidian UI Status | Verdict |
| :--- | :--- | :--- | :--- |
| `[[my-note]]` | **CRASH / PARSE ERROR** (YAML reserved token `[` opens array) | Broken Metadata Header | ❌ **FORBIDDEN** |
| `my-note` | Plain string | Treated as plain text, **no clickable link** | ❌ **NON-FUNCTIONAL** |
| `"[[my-note]]"` | Valid YAML string | **Clickable chip, live graph edge, link preview works** | ✅ **MANDATORY** |

---

## 3. Inline vs. Frontmatter Difference

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        OBSIDIAN WIKILINK PLACEMENT                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. IN FRONTMATTER (YAML) : MUST use quotes  -->  "[[note-slug]]"       │
│ 2. IN BODY TEXT (MARKDOWN): NO quotes       -->  [[note-slug]]         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Verification Checklist

- [ ] Are all wikilinks in YAML properties wrapped in `"[[]]"`?
- [ ] Are list items formatted with standard YAML dashes (`- "[[...]]"`)?
- [ ] Does the YAML block parse without syntax errors in standard YAML validators?
- [ ] Does clicking the property chip in Obsidian navigate to the target note?
