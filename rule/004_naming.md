---
trigger: always_on
description: RULE #004 — Repository Naming Conventions and Identification Standards
---

# RULE #0 — Repository Naming Conventions & Identification Standards

## 1. Strict 2-Octet Versioning Standard (`0x-0x`)
All version tags, milestone documents, and `.agent.json` version declarations must strictly follow the **2-OCTET FORMAT** (`0x-0x` / `v0x-0x`):
- **Allowed**: `01-01`, `01-02`, `01-03`, `v01-03`, `02-00`.
- **Prohibited**: Three-octet or fragmented versions (e.g., `01-03.1`, `v01_03.2`, `1.0.0.1`).
- **Single Declaration**: In `.agent.json`, the version must be declared **ONLY ONCE AT THE ROOT LEVEL**. Individual file lineage entries must never repeat or diverge the version number.

---

## 2. File & Directory Naming (Kebab-Case)
- All script files, skill documents, markdown briefs, and assets must use lowercase **kebab-case**:
  - `all-lads-tool/skill/bento-layout-playground-skill.md`
  - `all-lads-tool/script/javascript/capture-thumbnails.js`
  - `apps/family-quiz.html`
- Avoid camelCase, PascalCase, or whitespace in filenames.

---

## 3. Strict ZERO `id:` Standard for Cartridges
- All cartridge IDs are derived exclusively from the file basename:
  ```javascript
  const slug = filename.replace(/\.md$/, '');
  ```
- YAML frontmatter in `apps/*.md` must **NEVER** include an `id:` key. Any existing `id:` attribute in frontmatters must be stripped during compilation.
