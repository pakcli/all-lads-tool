---
title: "Universal Common Layer, 2-Way Distribution, Compiler/Decompiler & Multi-Artifact Schemas"
version: v01-04-00
status: canonical
dependencies:
  - "[[brief/v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md|v01-03-02]]"
  - "[[brief/v01-03-04_repo-edit-commited-files-but-hidden-in-the-history-with-staged.md|v01-03-04]]"
  - "[[brief/v01-03-05_feat_repo-edit-commited-files-all-commit-state and other git manage.md|v01-03-05]]"
  - "[[docs/repo/git-manage.md|git-manage]]"
  - "[[docs/repo/git-checkpoint-rollback.md|git-checkpoint-rollback]]"
  - "[[skill/docs-same-file-name-script.md|docs-same-file-name-script]]"
  - "[[skill/confirmation-to-proceed-brief-overview-options.md|confirmation-to-proceed-brief-overview-options]]"
  - "[[skill/save-option-as-exact-executor-name-json.md|save-option-as-exact-executor-name-json]]"
  - "[[skill/asci-tree-codeblock-standard-without-branch.md|asci-tree-codeblock-standard-without-branch]]"
---

# Brief v01-04-00: Universal Common Layer, 2-Way Distribution & Multi-Artifact Schema Specifications

## Status
- **Status**: Canonical Milestone Architecture Specification
- **Version**: v01-04-00
- **Context**: `all-lads-tool` (Universal Suite: `common`, `repo`, `file`, `blender`, `unity`, `website`)
- **Key Deliverables**:
  - `script/common/compiler.ps1` & `docs/common/compiler.md`
  - `script/common/decompiler.ps1` & `docs/common/decompiler.md`
  - `script/common/adapter/path-normalizer.psm1`
  - `script/common/adapter/version-resolver.psm1`
  - `script/common/adapter/run-json-bridge.psm1`
  - Full Canonical Reference Schemas for: `docs`, `skill`, `combo`, and `json` artifacts

---

## 1. Architectural Vision: The 2-Way Consumption Modality

Modern developer workflows demand zero-friction execution without abandoning clean modular engineering. Brief `v01-04-00` establishes a dual-modality architecture powered by an automated compilation toolchain:

```text
+-------------------------------------------------------------------------------+
|             MODAL A: STATIC WEB CATALOG (COPY-PASTE RUNTIME)                  |
+-------------------------------------------------------------------------------+
|  1. Developer browses tools inside the static retro web catalog.              |
|  2. Clicks "Copy for Terminal" on any tool card.                              |
|  3. Pastes snippet directly into PowerShell / Terminal.                       |
|  4. Tool executes immediately in memory (100% self-contained, zero installs). |
+-------------------------------------------------------------------------------+

+-------------------------------------------------------------------------------+
|             MODAL B: LOCAL DRAG-AND-DROP (FILESYSTEM TO TERMINAL)             |
+-------------------------------------------------------------------------------+
|  1. Developer drags script file into PowerShell / CMD.                        |
|  2. Script launches interactive cockpit with safety confirmation gates.       |
|  3. Developer drags target project folder into prompt input.                  |
|  4. Tool sanitizes dropped path (strips quotes, resolves full/relative path). |
|  5. Displays Pre-Flight Briefed Overview card; requires explicit 'yes'.       |
+-------------------------------------------------------------------------------+
```

### The Role of the Compiler & Decompiler Pipeline:
- **Modular Source of Truth**: All source code remains strictly modular in `script/<context>/` and `script/<context>/adapter/`.
- **Compiler (`script/common/compiler.ps1`)**:
  - Inlines modular adapter dependencies into a single portable executable `<tool>_stand.ps1`.
  - Inlines standardized boundary markers (`# [STANDALONE-MODULE: ...]`).
  - Emits self-executing JSON payloads for the static web catalog.
- **Decompiler (`script/common/decompiler.ps1`)**:
  - Losslessly extracts standalone boundary markers back into individual `adapter/*.psm1` files.

---

## 2. Universal Common Engine Topology (`script/common/`)

```text
all-lads-tool                                                                               # Workspace root
    brief                                                                                   # Architecture specifications
        v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md # 1:1 doc parity standard
        v01-03-04_repo-edit-commited-files-but-hidden-in-the-history-with-staged.md         # Overwrite commit files brief
        v01-03-05_feat_repo-edit-commited-files-all-commit-state and other git manage.md    # Full git-manage matrix brief
        v01-04-00_universal-common-compiler-and-decompiler-architecture.md                 # Master milestone v01-04 brief
    docs                                                                                    # Canonical documentation root (1:1 parity with script/)
        common                                                                              # Common tools documentation
            compiler.md                                                                     # 1:1 documentation for compiler.ps1
            decompiler.md                                                                   # 1:1 documentation for decompiler.ps1
        repo                                                                                # Repo context documentation
            git-manage.md                                                                   # 1:1 documentation for git-manage.ps1
            git-manage.sh.md                                                                # 1:1 documentation for git-manage.sh
            git-checkpoint-rollback.md                                                      # 1:1 documentation for git-checkpoint-rollback.ps1
            git-checkpoint-rollback.sh.md                                                   # 1:1 documentation for git-checkpoint-rollback.sh
    script                                                                                  # Executable scripts root (strictly zero markdown)
        common                                                                              # Universal cross-context engine
            compiler.ps1                                                                    # Standalone compiler & bundler
            decompiler.ps1                                                                  # Standalone unbundler
            adapter                                                                         # Shared common adapters
                path-normalizer.psm1                                                        # Drag-and-drop sanitization engine
                version-resolver.psm1                                                       # Git/OS/Node runtime detector
                run-json-bridge.psm1                                                        # Universal _run.json synchronization
        repo                                                                                # Domain: Git & Repository Orchestration
            git-manage.ps1                                                                  # Master Git interactive cockpit
            git-manage.sh                                                                   # Master Git POSIX companion
            git-checkpoint-rollback.ps1                                                     # Safe soft reset checkpoint rollback
            git-checkpoint-rollback.sh                                                      # Safe soft reset POSIX companion
            adapter                                                                         # Domain-specific modular adapters
                git-core.psm1 & git-core.sh                                                 # Git process execution wrapper
                git-status.psm1 & git-status.sh                                             # Working tree & dirty file inspector
                git-rollback.psm1 & git-rollback.sh                                         # Safe soft reset & lease push engine
                git-reflog.psm1 & git-reflog.sh                                             # Reflog traversal & recovery engine
                git-submodule.psm1 & git-submodule.sh                                       # Submodule hub management engine
                git-worktree.psm1                                                           # Branch worktree engine
```

---

## 3. Canonical Full Concrete Codeblock - Markdown Type 1: `docs`

Every document inside `docs/<context>/<tool-slug>.md` MUST implement this exact frontmatter, structure, and column specification:

```markdown
---
title: "Universal Git Checkpoint Rollback & Safe Reset"
tool: "git-checkpoint-rollback.ps1"
context: "repo"
runtime: "PowerShell 5.1+ / 7+"
aliases: ["checkpoint-rollback", "git-rollback", "safe-rollback"]
tags: ["all-lads-tool", "repo", "git", "rollback", "soft-reset", "checkpoint", "options"]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
copy_to_terminal_snippet: |
  & { $b="main"; git reset --soft HEAD~1; Write-Host "[OK] Rolled back 1 commit safely to staging." -ForegroundColor Green }
---

# `git-checkpoint-rollback.ps1` - Universal Git Checkpoint Rollback (Context: Repo)

> [!INFO]
> **Context**: `repo` | **Executable**: `script/repo/git-checkpoint-rollback.ps1`
> **Adapters**: `script/repo/adapter/git-rollback.psm1`, `script/repo/adapter/git-status.psm1`
> **Canonical Documentation**: `docs/repo/git-checkpoint-rollback.md` (Matches script filename 1:1)

Rolls back local git history to a chosen previous commit using `git reset --soft`, guaranteeing that 100% of your working code is kept safe in the Git Staging Area (index) rather than deleted. Offers optional remote synchronization with `--force-with-lease`.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive mode (prompts for target repo and commit checkpoint)
.\script\repo\git-checkpoint-rollback.ps1

# Specify target repository directly (supports relative or drag-and-drop paths)
.\script\repo\git-checkpoint-rollback.ps1 -TargetDir "web-app_sims-homebox"

# Headless non-interactive rewind to commit #2 with remote sync
.\script\repo\git-checkpoint-rollback.ps1 -TargetDir "web-app_sims-homebox" -TargetCommit "2" -ForcePush
```

---

## 2. Command Line Parameters Matrix

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-TargetDir` | `[string]` | No | `_run.json` / Current Directory | Absolute or relative path to target Git repository. Auto-sanitizes outer quotes. |
| `-TargetCommit` | `[string]` | No | Interactive Prompt | Checkpoint commit index (`1..10`) or commit SHA hash to roll back into. |
| `-ForcePush` | `[switch]` | No | `$false` | When passed, automatically syncs remote branch via `git push --force-with-lease`. |

---

## 3. Pre-Flight Briefed Overview Card

Before executing any history mutation, the tool renders a high-contrast pre-flight overview card requiring explicit confirmation:

```text
==========================================================
   GIT CHECKPOINT ROLLBACK PRE-FLIGHT OVERVIEW
==========================================================
 Target Repo      : <workspace_root>/web-app_sims-homebox
 Branch Aktif     : main
 Mundur ke Commit : dd8c673 ("feat: 3-radio layout...")
 Commit Dicopot   : 1 commit terbaru dari history
 Kodingan Lokal   : 100% AMAN (masuk ke Staging Area via reset --soft)
 Perintah Git     : git reset --soft dd8c673
==========================================================

Lanjutkan proses mundur ini? (y/N):
```

---

## 4. Implementation Sources

- **PowerShell Runner**: [`script/repo/git-checkpoint-rollback.ps1`](../../script/repo/git-checkpoint-rollback.ps1)
- **Modular Adapter**: [`script/repo/adapter/git-rollback.psm1`](../../script/repo/adapter/git-rollback.psm1)
- **POSIX Companion**: [`script/repo/git-checkpoint-rollback.sh`](../../script/repo/git-checkpoint-rollback.sh)
```

---

## 4. Canonical Full Concrete Codeblock - Markdown Type 2: `skill`

Every skill inside `skill/<skill-slug>.md` MUST implement this exact YAML frontmatter and structural schema:

```markdown
---
name: confirmation-to-proceed-brief-overview-options
aliases: ["pre-flight-briefed-card", "confirmation-gating-standard", "options-overview-card"]
category: SAFETY_PROTOCOL
tags: ["all-lads-tool", "safety", "cli", "pre-flight", "confirmation", "workflow", "protocol"]
description: Standardized CLI pre-flight pattern requiring interactive scripts to render a high-contrast Briefed Overview card of all resolved parameters, target paths, and command previews, followed by mandatory explicit confirmation gating (yes to proceed) before execution.
dependencies:
  - "[[donot-code-yet]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[save-option-as-exact-executor-name-json]]"
  - "[[docs-same-file-name-script]]"
pros:
  - "Prevents catastrophic unintended execution on wrong branches or directories"
  - "Gives user 100% visibility over resolved parameters before mutations occur"
  - "Eliminates ambiguous prompt behaviors through explicit confirmation gating"
cons:
  - "Requires extra interactive prompt roundtrip before execution"
---

# Pre-Flight Briefed Overview & Confirmation Standard (`confirmation-to-proceed-brief-overview-options`)

> [!IMPORTANT]
> **CARDINAL PROTOCOL - ZERO BLIND MUTATIONS**:
> Any automation script, CLI orchestrator, or tool that performs state mutation (file deletion, git rewriting, commit overwriting, branch resets, or build executions) **MUST NEVER** execute silently. It MUST render a high-contrast Briefed Overview card and require explicit confirmation.

---

## 1. Context & Activation Triggers

This skill triggers automatically whenever:
1. An automation tool resolves parameters from multiple sources (CLI flags, defaults, history JSON, or clipboard).
2. An operation mutates file system state, git history, or environment variables.
3. A tool offers multiple operational modes or scopes (e.g. Opsi 1..5 in commit overwrite).

---

## 2. Card Specification & Invariant Formatting

The Pre-Flight card MUST be rendered with clear borders and key-value columns:

```text
==========================================================
   <TOOL_NAME_UPPERCASE> PRE-FLIGHT BRIEFED OVERVIEW
==========================================================
 Target Path   : <resolved_absolute_path>
 Active Branch : <resolved_git_branch>
 Action Mode   : <resolved_mode_or_opsi>
 Scope Count   : <number_of_affected_items>
 Safety Status : <data_preservation_guarantee>
 Command       : <exact_underlying_command_preview>
==========================================================

Proceed with execution? [y/N] (Type 'y' or 'yes' to proceed):
```

### Confirmation Gating Rules:
1. **Explicit Proceed**: Only `y`, `yes`, `Y`, or `YES` advances execution.
2. **Safe Cancellation**: Pressing `Enter` on an empty prompt, typing `n`, `no`, `q`, or any other key immediately aborts the operation cleanly with exit code `0`.
3. **No Default Enter**: Empty `Enter` must NEVER trigger execution.
```

---

## 5. Canonical Full Concrete Codeblock - Markdown Type 3: `combo`

Every combo meta-skill inside `combo/<combo-slug>.md` MUST implement this exact multi-skill composite schema:

```markdown
---
name: universal-dragndrop-terminal-workflow
aliases: ["dnd-terminal-pipeline", "drag-drop-cli-combo", "universal-path-sanitizer-combo"]
category: META_SKILL_COMBO
tags: ["all-lads-tool", "combo", "meta-skill", "terminal", "drag-and-drop", "cross-os", "workflow"]
description: Master composite standard unifying native OS Explorer drag-and-drop path ingestion, quote stripping, full-drive path normalization, and pre-flight card confirmation across all interactive CLI tools in all-lads-tool.
dependencies:
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[zero-hardcoded-variables]]"
  - "[[save-option-as-exact-executor-name-json]]"
  - "[[docs-same-file-name-script]]"
related:
  - "[[electron-dragndrop]]"
  - "[[decoupled-engine-domain-isolation]]"
pros:
  - "Zero-friction developer ergonomics: drag folders directly into terminal prompts"
  - "Eliminates manual path typing errors and broken backslash escape sequences"
  - "Standardizes quote sanitization across Windows CMD, PowerShell, and Git Bash"
cons:
  - "Requires dedicated path normalizer module in common adapter layer"
---

# Universal Drag-and-Drop Terminal Workflow Suite (`universal-dragndrop-terminal-workflow`)

> [!IMPORTANT]
> **THE COMPOSITE ERGONOMICS STANDARD**:
> Unifies the ingestion of filesystem paths dragged directly from Windows Explorer, macOS Finder, or desktop panels into interactive command-line prompts. Eliminates terminal escape bugs and normalizes path formats before underlying scripts execute.

---

## 1. System Pipeline Architecture

```text
+-------------------------------------------------------------------------------+
|               UNIVERSAL DRAG-AND-DROP PIPELINE ARCHITECTURE                   |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ 1. USER ACTION: DRAG & DROP ]                                              |
|  +-------------------------------------------------------------------------+  |
|  | User drags folder '<workspace_root>/my-app' into PowerShell / CMD prompt   |  |
|  | Terminal receives raw string: "\"<workspace_root>\\my-app\""               |  |
|  +-------------------------------------------------------------------------+  |
|                                       |                                       |
|                                       v                                       |
|  [ 2. SANITIZATION LAYER: path-normalizer.psm1 ]                              |
|  +-------------------------------------------------------------------------+  |
|  | 1. Trim outer single & double quotes: .Trim('"').Trim("'")               |  |
|  | 2. Detect path format: IsPathRooted() vs Relative                       |  |
|  | 3. Validate existence via Test-Path -LiteralPath                        |  |
|  | 4. Resolve canonical absolute path: (Resolve-Path).Path                 |  |
|  +-------------------------------------------------------------------------+  |
|                                       |                                       |
|                                       v                                       |
|  [ 3. STATE PERSISTENCE: _run.json ]                                          |
|  +-------------------------------------------------------------------------+  |
|  | Persist targetDir into _run.json for session inheritance across tools   |  |
|  +-------------------------------------------------------------------------+  |
|                                       |                                       |
|                                       v                                       |
|  [ 4. CONFIRMATION GATING: Pre-Flight Card ]                                  |
|  +-------------------------------------------------------------------------+  |
|  | Render briefed card with target path and require explicit 'yes'         |  |
|  +-------------------------------------------------------------------------+  |
+-------------------------------------------------------------------------------+
```

---

## 2. Multi-Context Implementation Matrix

| Context | Target Runner | Ingestion Method | Handled Dropped Types |
| :--- | :--- | :--- | :--- |
| `repo` | `git-manage.ps1` | Main menu prompt & footer `[t]` | Git repositories, apps cartridges, worktrees |
| `repo` | `git-checkpoint-rollback.ps1` | Initial `TARGET REPO DIRECTORY` prompt | Target Git repositories |
| `file` | `detector-clipboard-4-mode.ps1` | `TargetDir` parameter & menu input | Source code directories & vaults |
| `common` | `compiler.ps1` | `-ToolScript` parameter & prompt | Single `.ps1` modular runner files |
```

---

## 6. Canonical Full Concrete Codeblock - JSON Artifact Schemas

Below are the exact schemas and complete field specifications for all non-adapter JSON metadata files across the workspace:

### Schema 1: Workspace Session State (`_run.json`)
Located at workspace root `_run.json`. Governs current active target directory, domain access, and session history:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "RunConfigurationState",
  "type": "object",
  "required": ["mainMenuPath", "activeSlug", "targetDir", "history"],
  "properties": {
    "mainMenuPath": {
      "type": "string",
      "description": "Absolute canonical path to the root interactive menu runner."
    },
    "activeSlug": {
      "type": "string",
      "description": "Currently active tool or workspace cartridge identifier."
    },
    "allowedDomains": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Whitelisted network domains for API or documentation queries."
    },
    "targetDir": {
      "type": "string",
      "description": "Active target repository or working directory inherited across all CLI tools."
    },
    "history": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["key", "name", "timestamp"],
        "properties": {
          "key": { "type": "string", "description": "Menu selection key triggered." },
          "name": { "type": "string", "description": "Human-readable tool name." },
          "timestamp": { "type": "string", "description": "ISO 8601 or formatted execution timestamp." }
        }
      }
    }
  }
}
```

#### Concrete `_run.json` Example:
```json
{
  "mainMenuPath": "<workspace_root>\\all-lads-tool\\_mainmenu.ps1",
  "activeSlug": "all-lads-tool",
  "allowedDomains": [
    "domain.com",
    "github.com"
  ],
  "history": [
    {
      "key": "1",
      "name": "Git Manager (ps1)",
      "timestamp": "2026-11-08 22:15:00"
    },
    {
      "key": "2",
      "name": "Git Checkpoint Rollback (ps1)",
      "timestamp": "2026-11-08 22:25:00"
    }
  ],
  "targetDir": "<workspace_root>\\web-app_sims-homebox"
}
```

---

### Schema 2: Skill Catalog Registry (`skill/_catalog.json`)
Located at `skill/_catalog.json`. Governs skill discovery, wikilink mapping, and activation triggers:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "SkillCatalogRegistry",
  "type": "array",
  "items": {
    "type": "object",
    "required": ["skill", "slug", "trigger"],
    "properties": {
      "skill": {
        "type": "string",
        "description": "Obsidian wikilink formatted reference to the skill document."
      },
      "slug": {
        "type": "string",
        "description": "Exact unique kebab-case slug identifying the skill."
      },
      "trigger": {
        "type": "string",
        "enum": ["always_on", "on_demand", "pre_flight", "quarantine"],
        "description": "Activation policy determining when the skill invariants take effect."
      }
    }
  }
}
```

#### Concrete `skill/_catalog.json` Example:
```json
[
  {
    "skill": "[[asci-tree-codeblock-standard-without-branch]]",
    "slug": "asci-tree-codeblock-standard-without-branch",
    "trigger": "always_on"
  },
  {
    "skill": "[[confirmation-to-proceed-brief-overview-options]]",
    "slug": "confirmation-to-proceed-brief-overview-options",
    "trigger": "always_on"
  },
  {
    "skill": "[[docs-same-file-name-script]]",
    "slug": "docs-same-file-name-script",
    "trigger": "always_on"
  },
  {
    "skill": "[[donot-code-yet]]",
    "slug": "donot-code-yet",
    "trigger": "pre_flight"
  },
  {
    "skill": "[[save-option-as-exact-executor-name-json]]",
    "slug": "save-option-as-exact-executor-name-json",
    "trigger": "always_on"
  }
]
```

---

### Schema 3: Atomic Multi-Mode Clipboard Store (`script/file/detector-clipboard-4-mode.json`)
Located at `script/file/detector-clipboard-4-mode.json`. Stores clipboard history and operating modes:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ClipboardStoreData",
  "type": "object",
  "required": ["activeMode", "lastUpdated", "history"],
  "properties": {
    "activeMode": {
      "type": "string",
      "enum": ["RAW_TEXT", "GIT_URL", "ABSOLUTE_PATH", "CODE_SNIPPET"],
      "description": "Currently active parsing and transformation mode."
    },
    "lastUpdated": {
      "type": "string",
      "description": "ISO 8601 timestamp of the most recent clipboard ingestion."
    },
    "history": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "timestamp", "mode", "content"],
        "properties": {
          "id": { "type": "integer" },
          "timestamp": { "type": "string" },
          "mode": { "type": "string" },
          "content": { "type": "string" }
        }
      }
    }
  }
}
```

#### Concrete `detector-clipboard-4-mode.json` Example:
```json
{
  "activeMode": "GIT_URL",
  "lastUpdated": "2026-11-08T22:20:00Z",
  "history": [
    {
      "id": 1,
      "timestamp": "2026-11-08T22:18:00Z",
      "mode": "GIT_URL",
      "content": "https://github.com/pakcli/web-app_sims-homebox.git"
    },
    {
      "id": 2,
      "timestamp": "2026-11-08T22:19:30Z",
      "mode": "ABSOLUTE_PATH",
      "content": "<workspace_root>\\web-app_sims-homebox"
    }
  ]
}
```

---

### Schema 4: Static Web Catalog Tool Payload (`catalog-tool-entry.json`)
Feeds directly into `web-app_catalog-style-retro` to render tool cards with the "Copy for Terminal" button:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "WebCatalogToolEntry",
  "type": "object",
  "required": ["id", "title", "context", "description", "terminalCommand", "tags"],
  "properties": {
    "id": { "type": "string", "description": "Unique kebab-case slug of the tool." },
    "title": { "type": "string", "description": "Display title in web catalog UI." },
    "context": { "type": "string", "description": "Domain context (repo, file, blender, etc.)." },
    "description": { "type": "string", "description": "Brief description of the tool's capability." },
    "terminalCommand": { "type": "string", "description": "Self-contained one-liner copied to clipboard." },
    "tags": { "type": "array", "items": { "type": "string" } },
    "docsUrl": { "type": "string", "description": "Relative link to canonical markdown documentation." }
  }
}
```

#### Concrete `catalog-tool-entry.json` Example:
```json
{
  "id": "git-checkpoint-rollback",
  "title": "Git Checkpoint Rollback (Safe Reset)",
  "context": "repo",
  "description": "Rewinds local git history to previous checkpoint via git reset --soft while keeping 100% of working code safely staged.",
  "terminalCommand": "& { $h=Read-Host 'Enter target commit hash'; if($h){ git reset --soft $h; Write-Host '[OK] Rolled back safely.' -ForegroundColor Green } }",
  "tags": ["git", "rollback", "soft-reset", "safety"],
  "docsUrl": "docs/repo/git-checkpoint-rollback.md"
}
```

---

## 7. Pre-Flight Verification & Quality Checklist

- [x] Zero non-ASCII characters across entire brief (100% pure ASCII).
- [x] Strictly zero markdown files inside `script/`.
- [x] Exact 1:1 filename matching between `script/<context>/<tool-slug>.<ext>` and `docs/<context>/<tool-slug>.md`.
- [x] All uncommitted working tree changes maintained under `donot-commit-yet`.
- [x] All removed artifacts routed safely to `trash-bin/` (zero `Remove-Item -Force`).
- [x] Zero branch symbols (`|--`, `\--`, `+--`, `---`, `---`) inside any codeblock.
- [x] Full non-truncated concrete codeblocks provided for `docs`, `skill`, `combo`, and all `json` schemas.
