---
title: Foldering Structure Updated Strictly No Markdown in Script & Docs File Name per Script
version: v01-03-02
status: canonical
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[naming-convention-standard]]"
  - "[[asci-tree-codeblock-standard]]"
---

# Brief v01-03-02: Foldering Structure (Strictly No Markdown in Script & Docs = File Name per Script)

## Status
- **Status**: Canonical / Active Standard (Current)
- **Version**: v01-03-02
- **Scope**: Hardened File Placement Invariants for `script/` and `docs/`

---

## 1. Core Invariants (The Two Immutable Rules)

> [!CAUTION]
> ### RULE A: STRICTLY ZERO MARKDOWN IN `script/`
> The `script/` directory and all its subdirectories (`script/<context>/`) are reserved **exclusively** for executable scripts (`.ps1`, `.py`, `.js`, `.cs`, `.bat`, `.sh`) and runtime version adapters (`adapter/*`).
> - **FORBIDDEN**: Creating or placing any `.md` file anywhere inside `script/`.
> - Any architectural notes, option breakdowns, or specifications must reside in `docs/`, never in `script/`.

> [!IMPORTANT]
> ### RULE B: `docs/` = EXACT FILE NAME PER SCRIPT (1:1 Canonical Mapping)
> Every technical document inside `docs/<context>/` must correspond **1:1** to an executable in `script/<context>/`:
> $$\text{script/<context>/<tool-slug>.<ext>} \longleftrightarrow \text{docs/<context>/<tool-slug>.md}$$
> - **FORBIDDEN**: Creating standalone/stray documentation files such as `options.md`, `details.md`, or `readme.md` inside `docs/<context>/`.
> - All option specifications, parameter schemas, and pre-flight briefed overview cards must be consolidated **directly inside** `docs/<context>/<tool-slug>.md`.

---

## 2. Canonical 1:1 Directory Topology

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
			detector-clipboard-4-mode.md   <--- 1:1 match for script/file/detector-clipboard-4-mode.ps1
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
			detector-clipboard-4-mode.ps1  <--- Executable (4-Mode Clipboard & Git Protocol Suite)
			detector-clipboard-4-mode.json <--- 1:1 State & history (save-option-as-exact-executor-name-json)
			dry-run.ps1
			batch-target-dir-rename.ps1
			file-merge-into-one.ps1
			file-one-to-multiple-files.ps1
			adapter
				detector-clipboard-4-mode.psm1
				clipboard-history-store.psm1
				clipboard-jit-inspector.psm1
				clipboard-mode-transformer.psm1
				drive-color-protocol.psm1
				ui-card-renderer.psm1
				panel-window-host.psm1
				cli-console-dashboard.psm1
		blender
			fbx-export.py
			adapter/
		unity
			asset-importer.cs
			adapter/
		website
			build-bundles.js
			adapter/
	skill/
	combo/
	_run.ps1
	_run.json
	_mainmenu.ps1
	_mainmenu.html
	README.md
	GUIDE.md
```

---

## 3. Git Clone Multi-Protocol Bridge (`detector-clipboard-4-mode` <---> `git-manage`)

When working with Git repositories, copying a URL from GitHub yields different protocols depending on the active tab:
- **HTTPS**: `https://github.com/<owner>/<repo>.git`
- **SSH**: `git@github.com:<owner>/<repo>.git`
- **GitHub CLI**: `gh repo clone <owner>/<repo>`
- **Git Clone CLI**: `git clone https://github.com/<owner>/<repo>.git`

### Unified Cross-Tool Protocol Behavior:
1. **`detector-clipboard-4-mode.ps1` (JIT Inspector & UI Panel)**:
   - When a Git URL or command is copied to clipboard, `Convert-ToGitRepoInfo` automatically parses the repository owner, slug, and host.
   - **CLI Mode**: Renders the 4 Git protocol options directly mapped to keys `[1-4]`.
   - **WPF GUI Panel**: Renders a dedicated pill-tab bar `[ HTTPS | SSH | GitHub CLI ]` with a selectable URL textbox and a `[📋]` copy button mirroring GitHub's repository clone widget.
2. **`git-manage.ps1` (Interactive Git Clone Wizard)**:
   - When the user selects option `[ 1 ] Clone remote repository`, the wizard inspects the system clipboard.
   - If a Git URL or `gh repo clone` command is detected, it auto-detects and suggests it as default input (`[DETECTED CLIPBOARD REPO] Found: <url>`), allowing immediate single-key confirmation (`Enter`).

---

## 4. Enforcement & Verification Checklist

Before creating or moving any file in the workspace, agents must verify:

1. [ ] Is the destination inside `script/`? If yes, is the file an executable (`.ps1`, `.py`, `.js`, `.cs`, `.bat`) or adapter (`adapter/*`)? **If it is a `.md` file, STOP. Move it to `docs/<context>/`.**
2. [ ] Is the destination inside `docs/<context>/`? Does the filename match an existing script in `script/<context>/` (`<tool-slug>.md`)? **If the name does not match a script (e.g. `options.md`), STOP. Consolidate into `<tool-slug>.md`.**
3. [ ] Is the destination inside `brief/`? Does the filename strictly follow the versioned prefix format (`v0x-0x-...`)? **If it is a loose file without versioning, STOP.**
4. [ ] Does the document contain any hardcoded drive letters (`E:\`, `C:\`)? **If yes, replace with `<workspace_root>/` or relative paths per Rule #001.**


---
title: Branch Structuring Standard and Language Parity Protocol
version: v01-03-03
status: canonical
dependencies:
  - "[[brief-revisions-to-perfection]]"
  - "[[branch-structure-flat-prefix-isolation]]"
  - "[[docs-same-file-name-script]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
---

# Brief v01-03-03: Branch Structuring & 1:1 Language Parity Protocol

## Status
- **Status**: Canonical / Active Architectural Brief
- **Version**: v01-03-03
- **Scope**: Git Branch Hierarchy, Casual-Formal English Main Trunk, and Casual-Formalist 1:1 Localization Branches
- **Standard Applied**: `[[brief-revisions-to-perfection]]`

---

## 1. Executive Summary & Perfection Metrics

```text
================================================================================
REVISIONS TO PERFECTION BRIEFING: Branch Structuring (v01-03-03)
================================================================================
BASELINE EVALUATION : 7.6 / 10 (Ad-hoc branch naming, mixed language codebases)
TARGET STATE        : 10.0 / 10 (Flawless, deterministic multi-branch topology)
PRIMARY FOCUS       : English Trunk + Casual-Formalist Tone + 1:1 Filename Parity
================================================================================
```

This brief establishes the canonical 3-tier Git branch topology and linguistic register for the ecosystem:
1. **`main` (Production & Shared Integration Trunk - Non-Personal)**:
   - **Language**: Strictly **English** for all variable names, function identifiers, parameters, and documentation.
   - **Tone**: **Casual & Formal English** (approachable, clear, and direct, yet technically rigorous and precise).
   - **Identifiers**: Flexible (*bebas*) naming styles (camelCase, kebab-case, PascalCase), but 100% English vocabulary.
2. **`main-<username>` (Personal Developer Sandboxes)**:
   - Personal developer branches (e.g. `main-pakcli`, `main-fsl`) for uncommitted working-tree experimentation and rapid prototyping before merging into `main`.
3. **`lang-<language>` (Localization Branches)**:
   - **Language**: Strictly in that target language (*strictly with that bahasa*, e.g. `lang-id-id` in Bahasa Indonesia, `lang-ja` in Japanese).
   - **Tone**: **Casual-Formalist** in that specific language (santai namun formal, baku, dan lugas).
   - **1:1 Parity**: **Every file name must be 100% identical to `main`**. Only the internal prose/content is localized.

---

## 2. The 3-Tier Branch Topology & Linguistic Matrix

```text
+-------------------------------------------------------------------------------+
|                 THE 3-TIER BRANCH TOPOLOGY & LINGUISTIC MATRIX                |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ 1. main ] : Canonical Production Trunk (Non-Personal)                      |
|  - Language Rule     : STRICTLY ENGLISH (All variables, functions, files)     |
|  - Tone & Register   : CASUAL & FORMAL (Approachable, precise, serious mode)  |
|  - Naming Style      : Flexible ("bebas"), but 100% English vocabulary        |
|  - Stability         : Production-ready, passes all CI tests                  |
|                                                                               |
|  [ 2. main-<username> ] : Personal Developer Sandboxes                        |
|  - Examples          : main-pakcli, main-fsl, main-lead                       |
|  - Role              : Rapid iteration, pre-commit staging, personal sandbox  |
|  - Sync Invariant    : Must regularly pull/merge from main to prevent drift   |
|                                                                               |
|  [ 3. lang-<language> ] : Strict 1:1 Localization Branches                    |
|  - Examples          : lang-id-id, lang-en-us, lang-ja                        |
|  - Language Rule     : STRICTLY IN THAT TARGET BAHASA (e.g. 100% Indonesian)  |
|  - Tone & Register   : CASUAL-FORMALIST (Santai namun formal dan terstruktur) |
|  - 1:1 Parity Rule   : EXACT SAME FILE NAMES as main branch                   |
|  - Content Policy    : Only body text/prose is localized; topology unchanged  |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 3. The 3 Immutable Invariants

> [!IMPORTANT]
> ### INVARIANT 1: `main` IS NON-PERSONAL, CASUAL-FORMAL, AND STRICTLY ENGLISH
> - The `main` trunk belongs to no single individual; it is the shared canonical integration branch.
> - All code, variable names, function identifiers, parameters, configuration keys, file names, and comments in `main` must be written **exclusively in English**.
> - Naming conventions remain flexible (*bebas* - camelCase, kebab-case, PascalCase as appropriate per runtime language).
> - Documentation tone in `main` must adhere to **Casual-Formal English**: accessible, direct, and conversational without academic stiffness, while retaining technical rigor and zero emojis.

> [!IMPORTANT]
> ### INVARIANT 2: `main-<username>` ISOLATION
> - Every contributor maintains an isolated sandbox branch formatted as `main-<username>` (e.g. `main-pakcli`).
> - Work in progress sits safely uncommitted or committed in the personal sandbox without breaking `main`.
> - Merging from sandbox to `main` requires verifying English-only variable naming and passing the 1:1 file parity audit.

> [!IMPORTANT]
> ### INVARIANT 3: `lang-<language>` IS CASUAL-FORMALIST, STRICTLY IN THAT BAHASA, WITH 1:1 FILE PARITY
> In any localization branch (`lang-id-id`, `lang-ja`, etc.):
> - **Strict Language Integrity**: The content must be written **100% in that target language** (*strictly with that bahasa*). Mixing languages within prose or leaving half-translated sections is prohibited.
> - **Casual-Formalist Tone**: Written in a natural, communicative yet formal and structured register (e.g. Bahasa Indonesia yang santai, lugas, namun tetap baku dan profesional).
> - **1:1 File Name Parity**: **File names must be 100% identical to `main`**:
>   $$\text{file in } \texttt{main} \longleftrightarrow \text{exact same filename in } \texttt{lang-<language>}$$
> - Translating file names (e.g. renaming `docs/repo/git-manage.md` to `docs/repo/manajemen-git.md`) is **STRICTLY PROHIBITED**. Directory structures and file names remain permanently locked to `main`.

---

## 4. The Casual-Formalist Tone & Linguistic Protocol

### 4.1 What "Casual & Formal" Means in Practice
The casual-formal register bridges developer accessibility with production precision:
- **Casual Dimension**: Direct sentences, active voice, pragmatic explanations, and clear mental models without unnecessarily dense academic prose.
- **Formal Dimension**: Exact technical parameter schemas, strict type definitions, unambiguous CLI syntax, and zero decorative fluff or emojis (per `[[zero-emoji-serious-mode]]`).

### 4.2 Linguistic Examples by Branch

#### Branch: `main` (Casual-Formal English)
```markdown
# Git Repository Manager (`git-manage.ps1`)

Welcome to the Git repository orchestration tool. This tool handles multi-version Git workflows, interactive branch management, and automated Git cloning with pre-flight briefed overview cards.

## Quickstart
Run the script directly from your terminal:
```powershell
.\script\repo\git-manage.ps1
```
```

#### Branch: `lang-id-id` (Casual-Formalist Bahasa Indonesia)
```markdown
# Manajer Repositori Git (`git-manage.ps1`)

Selamat datang di utilitas orkestrasi repositori Git. Tool ini menangani alur kerja Git multi-versi, manajemen branch interaktif, dan panduan kloning Git otomatis dengan kartu ringkasan pre-flight.

## Panduan Cepat
Jalankan skrip langsung dari terminal Anda:
```powershell
.\script\repo\git-manage.ps1
```
*(Catatan: Nama berkas tetap `docs/repo/git-manage.md`, persis sama dengan branch main).*
```

---

## 5. The 4-Phase Roadmap to Perfection (Per `brief-revisions-to-perfection`)

### Phase 0: Critical Stabilization (P0 - Immediate Blockers)
- **Eliminate Slash Nesting**: Disallow slash-separated branches (`feature/add-auth`, `lang/id`). All branches must be flat hyphenated strings (`main-<user>`, `lang-<language>`).
- **Sanitize Drive Paths**: Confirm zero machine paths exist in branch management scripts per Rule #001.

### Phase 1: Architectural Hardening (P1 - Structural Integrity)
- **English Vocabulary Invariant in `main`**:
  Audit all scripts in `script/` on `main` to ensure variable declarations and function members use English terminology:
  ```powershell
  # FORBIDDEN ON main (Mixed language variables):
  $daftarFile = Get-ChildItem # VIOLATION: Non-English variable name
  function Ambil-Data { ... } # VIOLATION: Non-English function identifier

  # MANDATORY ON main (Strictly English variables & identifiers):
  $fileList = Get-ChildItem   # COMPLIANT: English variable
  function Get-Data { ... }   # COMPLIANT: English function
  ```
- **1:1 Localization Parity Verification**:
  Establish automated cross-branch file tree parity checking between `main` and all `lang-*` branches.

### Phase 2: Ergonomics & Validation Tooling (P2 - Developer Experience)
- Integrate branch validation directly into [`script/repo/git-manage.ps1`](file:///<workspace_root>/script/repo/git-manage.ps1).
- Provide an automated PowerShell script `Test-BranchParity.ps1` to detect filename divergence between `main` and localization branches.

### Phase 3: Edge-Case Fortification (P3 - Polish & Flawless 10/10)
- Add merge conflict prevention runbook for syncing documentation updates across `main` and `lang-*` branches.
- Implement pre-push validation preventing non-English variable commits to `main`.

---

## 6. Surgical Revision Specifications

### Revision Item REV-01: Branch Naming Normalizer & Validator
- **Target File**: `script/repo/adapter/v02-40-00.psm1`
- **Problem Statement**: Previous branch utilities allowed arbitrary branch names including nested slashes and unstandardized prefixing.
- **Root Cause**: Absence of a regex validator enforcing `main`, `main-<user>`, `fn-<feat>`, `bn-<feat>`, and `lang-<lang>` topology.
- **Proposed Solution**: Implement `Test-ValidBranchName` and integrate it into the branch creation workflow.
- **Code Implementation**:
  ```powershell
  function Test-ValidBranchName {
      param ([string]$BranchName)
      if ([string]::IsNullOrWhiteSpace($BranchName)) { return $false }
      
      $clean = $BranchName.Trim()
      
      # Canonical Branch Patterns:
      # 1. main
      # 2. main-<username> (e.g. main-pakcli, main-fsl)
      # 3. lang-<language> (e.g. lang-en-us, lang-id-id, lang-ja)
      # 4. fn-<feature>     (e.g. fn-3d-editor, fn-file-viewer)
      # 5. bn-<feature>     (e.g. bn-auth-service, bn-sync-engine)
      $pattern = '^(main|main-[a-z0-9_\-]+|lang-[a-z0-9_\-]+|fn-[a-z0-9_\-]+|bn-[a-z0-9_\-]+)$'
      
      return ($clean -match $pattern)
  }
  ```

### Revision Item REV-02: 1:1 Language Branch File Parity Validator
- **Target File**: `script/repo/adapter/v02-40-00.psm1`
- **Problem Statement**: Translators often translate file names, causing broken links and missing files when merging updates between `main` and language branches.
- **Root Cause**: Lack of automated verification ensuring `lang-*` branches maintain identical file paths to `main`.
- **Proposed Solution**: Create a branch comparison function comparing the file tree of `main` against `lang-<language>`:
  ```powershell
  function Test-LanguageBranchParity {
      param (
          [string]$TargetLangBranch,
          [string]$BaseBranch = "main"
      )

      # Get file list from base branch
      $baseFiles = git ls-tree -r --name-only $BaseBranch
      $langFiles = git ls-tree -r --name-only $TargetLangBranch

      $missingInLang = $baseFiles | Where-Object { $_ -notin $langFiles }
      $strayInLang   = $langFiles | Where-Object { $_ -notin $baseFiles }

      if ($missingInLang.Count -gt 0 -or $strayInLang.Count -gt 0) {
          Write-Error "[PARITY ERROR] File names between $BaseBranch and $TargetLangBranch do not match 1:1."
          if ($missingInLang) { Write-Host "Missing in $TargetLangBranch`:`n$($missingInLang -join "`n")" -ForegroundColor Red }
          if ($strayInLang)   { Write-Host "Stray / Renamed in $TargetLangBranch`:`n$($strayInLang -join "`n")" -ForegroundColor Yellow }
          return $false
      }

      Write-Host "[PASS] 1:1 Filename parity confirmed between $BaseBranch and $TargetLangBranch." -ForegroundColor Green
      return $true
  }
  ```

---

## 7. Verification & Audit Checklist

- [ ] Confirm that `main` is non-personal and uses **Casual & Formal English** throughout documentation and CLI outputs.
- [ ] Confirm that `main` contains **strictly English** variables, function names, parameter definitions, and script identifiers.
- [ ] Confirm that developer sandboxes strictly follow the `main-<username>` pattern (e.g. `main-pakcli`).
- [ ] Confirm that all localization branches strictly follow `lang-<language>` (e.g. `lang-id-id`, `lang-ja`).
- [ ] Confirm that `lang-<language>` branches use a **Casual-Formalist tone strictly in that target bahasa**.
- [ ] Verify that every file in `lang-<language>` has an **identically named counterpart in `main`** (Zero file translation / 1:1 parity).
- [ ] Verify zero hardcoded machine drive letters exist in all branch scripts per Rule #001.
- [ ] Confirm zero emojis per `zero-emoji-serious-mode`.
