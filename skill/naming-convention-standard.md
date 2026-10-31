---
description: RULE #004 – Repository Naming Conventions and Identification Standards
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE #004 – Repository Naming Conventions & Identification Standards

> [!INFO]
> **Authoritative Specification Skill**: [[all-lads-tool/skill/naming-convention-standard.md|naming-convention-standard]]
> **Core Syntax**: Strict Lowercase | `word-word` Same Instance | `nama_stand.extension` Standalone

---

## 1. Strict 2-Octet Versioning Standard (`0x-0x`)
All version tags, milestone documents, and `.agent.json` version declarations must strictly follow the **2-OCTET FORMAT** (`0x-0x` / `v0x-0x`):
- **Allowed**: `01-01`, `01-02`, `01-03`, `v01-03`, `02-00`.
- **Prohibited**: Three-octet or fragmented versions (e.g., `01-03.1`, `v01_03.2`, `1.0.0.1`).
- **Single Declaration**: In `.agent.json`, the version must be declared **ONLY ONCE AT THE ROOT LEVEL**. Individual file lineage entries must never repeat or diverge the version number.

---

## 2. Universal Instance & Word Syntax

All repository files, slugs, documents, and tools must follow the **Universal Instance Syntax**:

1. **Strict Lowercase**: All names must be lowercase (`[a-z0-9]`). Zero camelCase, zero PascalCase.
2. **Same Instance Separation (`word-word`)**: Words within the same conceptual instance must use hyphens (`-`):
   - Example: `git-submodule`, `check-battery`, `unit-circle`.
3. **Multi-Instance Separation (`instance_instance`)**: Different semantic layers or scopes must be separated by an underscore (`_`):
   - Example: `version_title.ext` (`v01-01_file-structure.md`).
   - Example: `index_rule.ext` (`004_naming.md`).

---

## 3. Standalone Tool Suffix Standard (`nama_stand.namaextension`)
All standalone executable scripts that can start by themselves and accept drag-and-drop must strictly enforce the **`_stand` suffix**:
$$\text{<tool-slug>\_stand.<extension>}$$
- **PowerShell**: `git-manage_stand.ps1`, `git-submodule_stand.ps1`, `bump-version_stand.ps1`, `find-folder-lockers_stand.ps1`.
- **Windows Batch**: `start-chrome-cwp_stand.bat`, `standalone-compiler_stand.bat`.
- **Bash / Unix**: `check-battery_stand.sh`, `standalone-compiler_stand.sh`.
- **Python**: `screenshot_stand.py`, `server_stand.py`, `screenshot-projects_stand.py`.
- **JavaScript**: `audit-codebase_stand.js`, `build-bundles_stand.js`, `capture-thumbnails_stand.js`.

---

## 4. Headless Module Standard (`module/*`)
Files located within the `module/` subfolder are shared headless libraries that **are unable to start by themselves**. They **MUST NOT** include the `_stand` suffix:
- Examples: `module/history.psm1`, `module/git-submodule.psm1`, `module/git-core.psm1`, `module/bundle-processor.ps1`, `module/compactor-engine.ps1`.

---

## 5. Documentation Canonical Standard (`docs/<runtime>/<tool-slug>.md`)
Dokumentasi teknis di dalam `docs/<runtime>/` bertindak sebagai **Single Source of Truth** untuk seluruh varian suatu tool:
- ❌ **DILARANG**: Membuat berkas dokumentasi terpisah berakhiran `_stand.md` (misal `docs/powershell/git-manage_stand.md`).
- ✅ **MANDATORY**: Gunakan nama kanonikal tool tanpa suffix fisik (`docs/<runtime>/<tool-slug>.md`, misal `docs/powershell/git-manage.md`).
- **Cakupan Terpadu**: Berkas `docs/<runtime>/<tool-slug>.md` mendokumentasikan kedua edisi sekaligus:
  1. **Standalone Edition** (`<tool-slug>_stand.<ext>`): Runner interaktif / drag-and-drop zero-dependency.
  2. **Modular Edition** (`<tool-slug>.<ext>`): Panggilan headless programmatic / import modul.

---

## 6. Git Tool Prefix Standard (`git-<slug>`)
Every script, module, and doc whose purpose is Git (history, commits, submodules, identity, recovery, remotes) **MUST** start with the `git-` prefix. The prefix is part of the slug, so it combines with the `_stand` suffix and the `docs/` rule above:
- ✅ `git-manage_stand.ps1`, `git-manage.ps1`, `git-rename-commit_stand.ps1`, `git-reconfig-identity.ps1`
- ✅ `module/git-core.psm1`, `module/git-status.psm1`
- ✅ `docs/powershell/git-manage.md`
- ❌ `manage-git_stand.ps1`, `rename-commit.ps1`, `module/gitcore.psm1`
- The prefix applies across all runtimes (`powershell/`, `gitbash/`, `bash/`, `javascript/`, `python/`).

---

## 7. Strict ZERO `id:` Standard for Cartridges
- All cartridge IDs are derived exclusively from the file basename:
  ```javascript
  const slug = filename.replace(/\.md$/, '');
  ```
- YAML frontmatter in `apps/*.md` must **NEVER** include an `id:` key. Any existing `id:` attribute in frontmatters must be stripped during compilation.
