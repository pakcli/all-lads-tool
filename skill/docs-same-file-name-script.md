---
name: docs-same-file-name-script
aliases: [docs-same-name-as-script, one-to-one-docs-script-topology, zero-markdown-in-script, docs-script-parity]
category: ARCHITECTURAL_STANDARD
tags: [all-lads-tool, skill, architecture, documentation, topology, naming-convention, zero-markdown-in-script]
description: Enforces strictly zero markdown files in script/ and guarantees a 1:1 matching file name between script/<context>/<tool-slug>.<ext> and docs/<context>/<tool-slug>.md, eliminating stray markdown files like options.md.
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[naming-convention-standard]]"
  - "[[asci-tree-codeblock-standard-without-branch]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[git-clone-briefed-overview]]"
  - "[[brief-revisions-to-perfection]]"
pros:
  - "Eliminates documentation clutter and ambiguous placement across code folders"
  - "Enforces deterministic discoverability: knowing the script name immediately identifies its documentation"
  - "Guarantees clean script/ directories reserved exclusively for runnable code and runtime adapters"
cons:
  - "Requires consolidating options, flags, and specifications into the main tool doc rather than creating standalone auxiliary markdown files"
---

# Documentation Same File Name as Script (`docs-same-file-name-script`)

> [!IMPORTANT]
> **THE 1:1 TOPOLOGY & ZERO MARKDOWN IN SCRIPT INVARIANT**:
> 1. Under no circumstance may any `.md` file be created, committed, or located inside the `script/` hierarchy. The `script/` tree is strictly reserved for runnable code and runtime version adapters.
> 2. Every documentation file under `docs/<context>/` must mirror its corresponding executable script in `script/<context>/` by exact file name (`<tool-slug>.md` matching `<tool-slug>.<ext>`).
> 3. Standalone, auxiliary, or stray markdown files (such as `options.md`, `details.md`, `help.md`, or `readme.md`) are strictly forbidden inside `docs/<context>/`. All option specifications, schemas, and usage instructions must be consolidated directly inside `docs/<context>/<tool-slug>.md`.

---

## 1. Architectural Topology & Invariants

```text
+-------------------------------------------------------------------------------+
|                       1:1 CANONICAL TOPOLOGY ENFORCEMENT                      |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ INVARIANT A: STRICTLY ZERO MARKDOWN IN script/ ]                           |
|  - script/<context>/ is reserved EXCLUSIVELY for runnable code and adapters.  |
|  - All .md files are strictly forbidden anywhere in the script/ tree.         |
|                                                                               |
|  [ INVARIANT B: docs/ = EXACT FILE NAME PER SCRIPT (1:1 Matching) ]           |
|  - Every file in docs/<context>/ corresponds 1:1 with script/<context>/       |
|    script/repo/git-manage.ps1        <---> docs/repo/git-manage.md            |
|    script/repo/git-branch-rename.ps1 <---> docs/repo/git-branch-rename.md    |
|    script/file/csv-to-frontmatter.ps1<---> docs/file/csv-to-frontmatter.md    |
|                                                                               |
|  [ INVARIANT C: ZERO STRAY MARKDOWN FILES ]                                   |
|  - Zero stray documentation files (options.md, details.md, readme.md).       |
|  - Option breakdowns and parameter tables must be embedded inside             |
|    docs/<context>/<tool-slug>.md.                                             |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 2. Canonical Directory Structure

```text
all-lads-tool
	brief
		v01-00_main-idea.md
		v01-01_foldering-structure.md
		v01-02_foldering-structure.md
		v01-03_foldering-structure.md
		v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md
	docs
		repo
			git-manage.md          <--- 1:1 match for script/repo/git-manage.ps1
			git-branch-rename.md   <--- 1:1 match for script/repo/git-branch-rename.ps1
		file
			batch-target-dir-rename.md
			csv-to-frontmatter.md
			dry-run.md
			file-merge-into-one.md
			file-one-to-multiple-files.md
		blender
			fbx-export.md
		unity
			asset-importer.md
		website
			build-bundles.md
	script
		repo
			git-manage.ps1         <--- Executable
			git-branch-rename.ps1  <--- Executable
			adapter
				v02-30-00.psm1     <--- LTS Version Adapter
				v02-40-00.psm1     <--- Modern Version Adapter
		file
			csv-to-frontmatter.ps1
			dry-run.ps1
			batch-target-dir-rename.ps1
			file-merge-into-one.ps1
			file-one-to-multiple-files.ps1
			adapter/
		blender
			fbx-export.py
			adapter/
		unity
			asset-importer.cs
			adapter/
		website
			build-bundles.js
			adapter/
	skill
		docs-same-file-name-script.md
		confirmation-to-proceed-brief-overview-options.md
		git-clone-briefed-overview.md
		zero-hardcoded-variables.md
		zero-emoji-serious-mode.md
```

---

## 3. Anti-Patterns vs. Canonical Implementations

### Anti-Pattern 1: Markdown Files Inside `script/`

```text
[FORBIDDEN]
script/
  repo/
    git-manage.ps1
    options.md       <--- VIOLATION: Markdown file inside script/
    notes.md         <--- VIOLATION: Markdown file inside script/
```

**Resolution**: Move all documentation content to `docs/repo/git-manage.md`. Never place `.md` files inside `script/`.

### Anti-Pattern 2: Stray Auxiliary Markdown Files Inside `docs/`

```text
[FORBIDDEN]
docs/
  repo/
    git-manage.md
    options.md       <--- VIOLATION: Stray markdown file with no corresponding script
    details.md       <--- VIOLATION: Stray markdown file with no corresponding script
```

**Resolution**: Consolidate options, parameter definitions, and architectural notes directly into `docs/repo/git-manage.md`.

### Canonical Form: 1:1 Strict Parity

```text
[CANONICAL]
script/repo/git-manage.ps1   <==== 1:1 ====> docs/repo/git-manage.md
script/repo/git-manage.ps1 options embedded in docs/repo/git-manage.md
```

---

## 4. Automated Compliance Verification Script

To verify that a repository strictly follows this standard, run the following PowerShell validation check:

```powershell
# Verify zero markdown files in script/
$scriptMdFiles = Get-ChildItem -Path "<workspace_root>/script" -Recurse -Filter "*.md" -ErrorAction SilentlyContinue
if ($scriptMdFiles.Count -gt 0) {
    Write-Error "[FAIL] Found $($scriptMdFiles.Count) markdown file(s) in script/:"
    $scriptMdFiles | ForEach-Object { Write-Host " - $($_.FullName)" -ForegroundColor Red }
    exit 1
} else {
    Write-Host "[PASS] Zero markdown files in script/." -ForegroundColor Green
}

# Verify 1:1 correspondence between docs/ and script/
$contexts = Get-ChildItem -Path "<workspace_root>/docs" -Directory
foreach ($ctx in $contexts) {
    $docFiles = Get-ChildItem -Path $ctx.FullName -Filter "*.md"
    foreach ($doc in $docFiles) {
        $baseName = $doc.BaseName
        $matchingScript = Get-ChildItem -Path "<workspace_root>/script/$($ctx.Name)" -File | Where-Object { $_.BaseName -eq $baseName }
        if (-not $matchingScript) {
            Write-Error "[FAIL] Stray doc found without matching script: docs/$($ctx.Name)/$($doc.Name)"
            exit 1
        }
    }
}
Write-Host "[PASS] All docs match 1:1 with corresponding scripts." -ForegroundColor Green
```

---

## 5. Revision Checklist for Contributors & Agents

- [ ] Ensure **zero `.md` files** exist in `script/` or any of its subdirectories.
- [ ] For every new executable script `script/<context>/<tool-name>.<ext>`, create exactly one matching documentation file `docs/<context>/<tool-name>.md`.
- [ ] Ensure **no standalone `options.md`** or `details.md` files exist; embed all option tables and parameter descriptions directly into `docs/<context>/<tool-name>.md`.
- [ ] Ensure all path references use portable relative paths or `<workspace_root>/` placeholders per `zero-hardcoded-variables`.
- [ ] Maintain serious technical documentation standards per `zero-emoji-serious-mode`.
