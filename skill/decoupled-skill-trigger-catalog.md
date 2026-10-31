---
name: decoupled-skill-trigger-catalog
aliases: [skill-trigger-catalog, decoupled-triggers, external-metadata-catalog]
category: METADATA_MANAGEMENT
tags: [all-lads-tool, skills, catalog, metadata, wikilinks, csv, json]
description: Protocol for decoupling agent execution triggers from markdown skill frontmatters into centralized _catalog.csv and _catalog.json files using Obsidian-compatible wikilinks.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Decoupled Skill Trigger Catalog Standard (`decoupled-skill-trigger-catalog`)

> [!IMPORTANT]
> **ZERO HARDCODED TRIGGER INVARIANT**:
> Never hardcode execution trigger modes (such as `trigger: always_on` or `trigger: on_demand`) directly inside individual Markdown skill frontmatters.
> All execution policies and triggers must be stored in external **Single Source of Truth** catalogs: `_catalog.csv` and `_catalog.json`.

---

## 1. Core Architecture

```text
all-lads-tool/
└── skill/
    ├── _catalog.csv        # Tabular trigger catalog with native Obsidian wikilinks
    ├── _catalog.json       # Machine-readable structured trigger registry
    ├── skill-alpha.md      # Clean markdown (zero trigger properties)
    └── skill-beta.md       # Clean markdown (zero trigger properties)
```

---

## 2. Catalog Specifications

### 2.1 The Tabular Catalog (`_catalog.csv`)
The CSV format uses double-quoted Obsidian wikilinks (`"[[...]]"`) in the first column to allow direct clicking in Obsidian and preview tables:

```csv
skill,trigger
"[[asci-tree-codeblock-standard]]",always_on
"[[cross-os-zero-localhost]]",always_on
"[[csv-to-frontmatter-compatible-parser]]",on_demand
"[[git-commit-convention]]",always_on
```

### 2.2 The Machine Registry (`_catalog.json`)
The JSON file provides runtime discovery for runners, agents, and automation scripts:

```json
[
  {
    "skill": "[[asci-tree-codeblock-standard]]",
    "slug": "asci-tree-codeblock-standard",
    "trigger": "always_on"
  },
  {
    "skill": "[[csv-to-frontmatter-compatible-parser]]",
    "slug": "csv-to-frontmatter-compatible-parser",
    "trigger": "on_demand"
  }
]
```

---

## 3. Benefits of Decoupled Catalogs

1. **Clean Skill Frontmatters**:
   - Skills focus purely on capability definition, tags, aliases, and pros/cons.
2. **Centralized Configuration**:
   - Changing a skill from `on_demand` to `always_on` requires editing only 1 line in `_catalog.csv`, without mutating 50+ individual documentation files.
3. **Auditability**:
   - Gives developers an instant overview of which skills are active and running at any given moment.

---

## 4. Verification Checklist

- [ ] Are individual skill frontmatters free of `trigger:` properties?
- [ ] Is `_catalog.csv` formatted with clickable `"[[]]"` wikilinks?
- [ ] Does `_catalog.json` match the live list of `.md` files in `skill/`?
- [ ] Can external runners discover trigger modes without parsing raw markdown text?
