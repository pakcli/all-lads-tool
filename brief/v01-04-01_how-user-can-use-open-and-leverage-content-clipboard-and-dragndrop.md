---
title: "User Usage, Content Opening & Leveraging Pipeline: Clipboard Web Ingestion & Downloadable Directory Drag-and-Drop"
version: v01-04-01
status: canonical
dependencies:
  - "[[brief/v01-04-00_refactor-foldering-universal-common-compiler-and-decompiler-architecture.md|v01-04-00]]"
  - "[[docs/file/detector-clipboard-4-mode.md|detector-clipboard-4-mode]]"
  - "[[docs/repo/git-manage.md|git-manage]]"
  - "[[skill/confirmation-to-proceed-brief-overview-options.md|confirmation-to-proceed-brief-overview-options]]"
  - "[[skill/save-option-as-exact-executor-name-json.md|save-option-as-exact-executor-name-json]]"
  - "[[skill/zero-hardcoded-sensitive-variables.md|zero-hardcoded-sensitive-variables]]"
  - "[[skill/asci-tree-codeblock-standard-without-branch.md|asci-tree-codeblock-standard-without-branch]]"
---

# Brief v01-04-01: How User Can Use, Open, and Leverage Content (Clipboard Web & Drag-and-Drop Ingestion)

## Status
- **Status**: Canonical Operational Specification
- **Version**: v01-04-01
- **Context**: `all-lads-tool` (Cross-Context Ingestion: `common`, `website`, `file`, `repo`)
- **Core Ingestion Modalities**:
  1. **Clipboard Web Ingestion**: Open website in browser -> Copy URL / payload -> Paste to terminal (or auto-detect via PolyClip) -> Parse, fetch, preview, and leverage.
  2. **Downloadable Directory Drag-and-Drop**: Download folder / archive from web -> Drag folder into terminal prompt -> Sanitize quotes and paths -> Ingest into `_run.json` -> Leverage via contextual tool matrix.
- **Reference Schemas Included**: Concrete, non-truncated examples for `docs`, `skill`, `combo`, and `json`.

---

## 1. Architectural Vision: The Two Ingestion Channels

The primary objective of `v01-04-01` is closing the ergonomic gap between web-based discovery and local terminal execution. Developers frequently browse tool catalogs, repositories, and documentation on the web, while their active compilation and git workflows reside in terminal cockpits.

```text
+-------------------------------------------------------------------------------+
|                      END-TO-END INGESTION TOPOLOGY                            |
+-------------------------------------------------------------------------------+
|                                                                               |
|   CHANNEL 1: CLIPBOARD WEB INGESTION                                          |
|   +-----------------------------------------------------------------------+   |
|   | 1. User browses web catalog or remote repository in web browser       |   |
|   | 2. User copies URL, clone string, or tool snippet to OS clipboard     |   |
|   | 3. User pastes into active terminal prompt (or PolyClip auto-detects)  |   |
|   | 4. Terminal sanitizes payload, inspects target, and opens / executes  |   |
|   +-----------------------------------------------------------------------+   |
|                                      |                                        |
|                                      v                                        |
|   CHANNEL 2: DOWNLOADABLE DIRECTORY DRAG-AND-DROP                             |
|   +-----------------------------------------------------------------------+   |
|   | 1. User downloads zip archive, git clone, or folder from website      |   |
|   | 2. User extracts to <download_dir>/extracted-target                   |   |
|   | 3. User drags folder directly from File Explorer into terminal        |   |
|   | 4. path-normalizer.psm1 strips quotes and resolves canonical path     |   |
|   | 5. Persists targetDir to _run.json for cross-tool inheritance         |   |
|   +-----------------------------------------------------------------------+   |
|                                      |                                        |
|                                      v                                        |
|   [ EXECUTION & LEVERAGING COCKPIT ]                                          |
|   - Pre-Flight Briefed Overview card rendered                                 |
|   - Explicit confirmation required ('yes' to proceed)                         |
|   - Contextual dispatch: git-manage, compiler, decompiler, or runner          |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 2. Channel 1: Clipboard Open Website & Paste to Terminal

### 2.1 The Problem
When users browse GitHub, GitLab, internal wikis, or the web catalog, copying a URL or snippet often carries invisible formatting errors, surrounding quotes, or accidental newlines. Manually switching to the terminal, typing `git clone`, and handling credentials causes friction.

### 2.2 Operational Flow

```text
+-------------------------------------------------------------------------------+
|               CHANNEL 1: CLIPBOARD WEB INGESTION STEP-BY-STEP                 |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ STEP 1: WEB COPY ]                                                         |
|  Developer selects one of the following on the website:                       |
|  - Repository Web URL:     https://github.com/pakcli/web-app_sims-homebox     |
|  - SSH Clone String:       git@github.com:pakcli/web-app_sims-homebox.git     |
|  - GitHub CLI Command:     gh repo clone pakcli/web-app_sims-homebox          |
|  - One-Line Web Runner:    irm https://domain/tools/common/compiler.ps1 | iex |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 2: TERMINAL INGESTION ]                                               |
|  Path A: Interactive Terminal Prompt                                          |
|          User runs .\script\repo\git-manage.ps1                               |
|          User selects menu [ 7 ] Clone Remote Repository                      |
|          Terminal checks [System.Windows.Forms.Clipboard]::GetText()          |
|          Prompt displays: [Target URL (default from clipboard)]: <URL>        |
|          User presses Enter to accept clipboard URL immediately               |
|                                                                               |
|  Path B: Background PolyClip Suite (detector-clipboard-4-mode.ps1)            |
|          PolyClip monitors clipboard changes in memory                        |
|          Detects Web URL -> Categorizes as Mode 1 (Web / Git HTTPS)           |
|          Developer presses [P] for WPF panel or passes to terminal pipeline   |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 3: SANITIZATION & INSPECTION ]                                        |
|  - Trims leading/trailing whitespace and surrounding quotation marks          |
|  - Matches against known URL patterns:                                        |
|    - Git Remote:   Clones or connects to local worktree                       |
|    - Web Doc/Page: Opens in browser or parses markdown into docs/             |
|    - Web API Spec: Fetches JSON schema into adapter/                          |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 4: PRE-FLIGHT BRIEFED CARD ]                                          |
|  ========================================================================     |
|  PRE-FLIGHT BRIEFED OVERVIEW: WEB REPOSITORY CLONE                            |
|  ------------------------------------------------------------------------     |
|  Source Web URL   : https://github.com/pakcli/web-app_sims-homebox            |
|  Detected Context : repo / Git Remote                                         |
|  Target Directory : <workspace_root>/web-app_sims-homebox                     |
|  Clone Strategy   : Standard Full Clone (Default Branch: main)                |
|  Command Preview  : git clone https://github.com/pakcli/web-app_sims-homebox  |
|  ------------------------------------------------------------------------     |
|  Confirm clone action? (Type 'yes' to proceed, Enter to cancel):              |
|  ========================================================================     |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 5: LEVERAGING THE CONTENT ]                                           |
|  - Repository cloned cleanly into <workspace_root>/web-app_sims-homebox       |
|  - Target directory automatically written into _run.json                      |
|  - git-manage dashboard instantly opens focused on the new repository         |
+-------------------------------------------------------------------------------+
```

### 2.3 Terminal-to-Web Bidirectional Opening
In addition to pasting web content into the terminal, the suite supports launching the web view directly from the terminal:
- **`git-manage.ps1` [ w ] Open Remote Web**:
  Extracts the `origin` remote URL from `git remote get-url origin`, transforms SSH syntax (`git@github.com:owner/repo.git`) into HTTPS (`https://github.com/owner/repo`), and invokes `Start-Process $webUrl` to open the repository in the user's default browser.
- **`detector-clipboard-4-mode.ps1` Web Link Open**:
  When a clipboard entry is identified as an HTTP/HTTPS URL, pressing `[W]` opens the webpage directly.

---

## 3. Channel 2: Drag-and-Drop on Downloadable Directory to Terminal

### 3.1 The Problem
When developers download project folders, zip extractions, or assets from a website, they want to inspect or operate on that folder immediately. Dragging a folder from Windows Explorer into a PowerShell or CMD terminal window causes shell formatting artifacts:
1. Windows shell wraps the dropped folder in quotes: `"<download_dir>\my-repo"`.
2. Dragging a folder with a trailing backslash results in an escaped quote: `"<download_dir>\my-repo\"` which breaks PowerShell parameter parsing.
3. Relative paths or drive letter root paths must be handled safely without leaking local machine structures into project files.

### 3.2 Operational Flow

```text
+-------------------------------------------------------------------------------+
|           CHANNEL 2: DOWNLOADABLE DIRECTORY DRAG-AND-DROP PIPELINE            |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ STEP 1: USER DOWNLOADS & DRAGS ]                                           |
|  1. User downloads package from website into <download_dir>/cartridge-v1      |
|  2. User opens terminal with running runner or compiler:                      |
|     .\script\common\compiler.ps1                                              |
|     or .\script\repo\git-manage.ps1                                           |
|  3. Terminal prompts:                                                         |
|     [TARGET DIRECTORY]: Drag & drop folder here, or press Enter for current   |
|  4. User drags folder from Windows Explorer into the terminal window          |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 2: RAW STRING RECEPTION & SANITIZATION ]                              |
|  Terminal receives raw string from OS drop event:                             |
|  Raw Input: "\"<download_dir>\\cartridge-v1\\\""                              |
|                                                                               |
|  path-normalizer.psm1 executes:                                               |
|  1. Trim outer quotation marks: $clean = $raw.Trim('"').Trim("'")             |
|  2. Trim trailing slashes:      $clean = $clean.TrimEnd('\').TrimEnd('/')     |
|  3. Resolve full canonical:     $resolved = (Resolve-Path $clean).Path        |
|  4. Validate folder existence:  Test-Path -LiteralPath $resolved -PathType Container
|                                      |                                        |
|                                      v                                        |
|  [ STEP 3: CONTEXT & PAYLOAD AUTO-DETECTION ]                                 |
|  The system inspects the target directory contents:                           |
|  +---------------------------+----------------------------------------------+ |
|  | Detected Signature        | Resolved Target Context & Action             | |
|  +---------------------------+----------------------------------------------+ |
|  | Contains .git/ folder     | Context: repo (Launches git-manage dashboard)| |
|  | Contains script/ folder   | Context: suite (Launches compiler/decompiler)| |
|  | Contains package.json     | Context: website / node application          | |
|  | Contains .blend files     | Context: blender asset pipeline              | |
|  | Contains Assets/ folder   | Context: unity game project                  | |
|  | Contains .md files only   | Context: file (Launches frontmatter renamer) | |
|  +---------------------------+----------------------------------------------+ |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 4: STATE SYNCHRONIZATION VIA _run.json ]                              |
|  run-json-bridge.psm1 updates _run.json:                                      |
|  {                                                                            |
|    "targetDir": "<download_dir>/cartridge-v1",                                |
|    "lastIngestionType": "drag-and-drop",                                      |
|    "detectedContext": "repo",                                                 |
|    "timestamp": "2026-11-08T23:30:00Z"                                        |
|  }                                                                            |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 5: PRE-FLIGHT BRIEFED OVERVIEW CARD ]                                 |
|  ========================================================================     |
|  PRE-FLIGHT BRIEFED OVERVIEW: DIRECTORY INGESTION                             |
|  ------------------------------------------------------------------------     |
|  Ingestion Method : Drag-and-Drop Terminal Input                              |
|  Resolved Path    : <download_dir>/cartridge-v1                               |
|  Target Context   : repo (Git Repository Detected)                            |
|  Branch / Status  : main | Clean Working Tree (Commit: a1b2c3d)               |
|  Active Action    : Switch Active Working Context to Target                   |
|  ------------------------------------------------------------------------     |
|  Proceed with this target? (Type 'yes' to proceed, Enter to cancel):          |
|  ========================================================================     |
|                                      |                                        |
|                                      v                                        |
|  [ STEP 6: LEVERAGING THE DROPPED CONTENT ]                                   |
|  - The active terminal switches context seamlessly to the dropped directory  |
|  - User can immediately inspect status, run rollback, compile, or sync       |
|  - Subsequent tool runs reuse the targetDir from _run.json automatically      |
+-------------------------------------------------------------------------------+
```

---

## 4. Required Concrete Reference Examples

Per canonical standard, this brief provides complete, non-truncated concrete implementations for each artifact type: `docs`, `skill`, `combo`, and `json`.

---

### 4.1 Concrete Example: `docs` Artifact (`docs/website/clipboard-web-ingestion.md`)

```markdown
---
name: clipboard-web-ingestion
context: website
version: v01-04-01
description: Operational manual for ingesting web repository URLs, documentation links, and downloadable cartridges from web browsers into terminal workflows.
tags: [all-lads-tool, website, clipboard, terminal, drag-and-drop, ingestion]
pros:
  - "Zero-typing URL and path ingestion eliminates human copy-paste errors"
  - "Sanitizes Windows OS quoting and backslash escaping artifacts automatically"
  - "Integrates with Pre-Flight Briefed Cards and explicit confirmation gating"
cons:
  - "Requires active terminal window focus during drag-and-drop actions"
  - "Requires OS clipboard access permissions when running headless"
---

# Web & Drag-and-Drop Ingestion Manual (`clipboard-web-ingestion`)

## 1. Overview
The Web Ingestion Suite bridges external web assets (GitHub repositories, web tool catalogs, documentation wikis) and local terminal execution. It eliminates manual path typing through two high-speed channels:
1. **Clipboard Web Ingestion**: Directly consumes web links copied from web browsers.
2. **Downloadable Directory Drag-and-Drop**: Resolves and sanitizes directories dropped into the terminal.

## 2. CLI Invocation & Syntax

### Interactive Mode
```powershell
.\script\file\detector-clipboard-4-mode.ps1 -Mode CLI
```

### Direct Terminal Parameter Ingestion
```powershell
.\script\common\compiler.ps1 -TargetDir "<download_dir>/my-downloaded-project"
```

## 3. Parameter Reference

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Mode` | String | No | `CLI` | Runtime mode: `CLI`, `Panel`, `Inspect`, or mode number `1..4`. |
| `-TargetDir` | String | No | `_run.json` | Explicit path or drag-and-dropped directory to ingest. |
| `-Panel` | Switch | No | `False` | Launches the WPF lightweight floating card dashboard. |
| `-Inspect` | Switch | No | `False` | Dumps current clipboard snapshot diagnostics to console. |
| `-Json` | Switch | No | `False` | Emits machine-readable JSON representation of clipboard data. |

## 4. Pre-Flight Safety Confirmation Card
Before any dropped path or web clone action is executed, the terminal presents a Pre-Flight Briefed Card:

```text
========================================================================
PRE-FLIGHT BRIEFED OVERVIEW: DIRECTORY INGESTION
------------------------------------------------------------------------
Target Path      : <download_dir>/sample-cartridge
Detected Context : repo (Git Repository)
Current Branch   : main (Clean)
Operation        : Ingest into _run.json and open git-manage dashboard
------------------------------------------------------------------------
Type 'yes' to proceed, or press Enter to cancel:
========================================================================
```

## 5. Troubleshooting Matrix

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| Dropped path contains trailing `\"` | Windows terminal escapes trailing backslash before end quote | `path-normalizer.psm1` strips quotes and trims trailing slashes automatically. |
| Clipboard URL not detected | Web page copied rich HTML format instead of plain URL | PolyClip JIT inspector unwraps HTML envelopes to extract raw `href`. |
| Target path shows drive letter | User dragged from external local volume | `path-normalizer.psm1` maps to canonical root-bounded path. |
```

---

### 4.2 Concrete Example: `skill` Artifact (`skill/clipboard-web-and-download-dragndrop-ingestion.md`)

```markdown
---
name: clipboard-web-and-download-dragndrop-ingestion
aliases: [web-clipboard-ingest, dragndrop-terminal-ingest, user-leverage-content-pipeline]
category: USER_INTERACTION_PROTOCOL
tags: [all-lads-tool, skill, clipboard, drag-and-drop, terminal, ingestion, web]
description: Canonical protocol governing the ingestion and leveraging of web clipboard content and downloaded directory drag-and-drop events inside terminal runners.
pros:
  - "Ensures consistent path sanitization across PowerShell, CMD, and Bash"
  - "Enforces mandatory Pre-Flight Briefed Overview cards before disk execution"
  - "Guarantees state persistence to _run.json for seamless tool chaining"
cons:
  - "Requires explicit user confirmation gating, preventing fully unattended runs"
  - "Enforces strict validation, rejecting missing or invalid directory paths"
---

# Clipboard Web & Download Drag-and-Drop Ingestion Protocol

## 1. Core Principles

1. **Zero-Trust Input Normalization**:
   All strings originating from clipboard paste or terminal drag-and-drop must be treated as untrusted raw inputs. They must pass through `path-normalizer.psm1` before passing to any filesystem or process API.

2. **Pre-Flight Briefed Overview Mandatory**:
   No cloned repository, dropped directory, or web script may be executed without first rendering a high-contrast Briefed Overview card detailing:
   - Ingestion Source (Clipboard Web URL or Dropped Local Directory).
   - Resolved Canonical Path.
   - Target Context (`repo`, `common`, `file`, `website`, `blender`, `unity`).
   - Planned Action Preview.

3. **Explicit Confirmation Gating ('yes' to Proceed)**:
   The prompt must default to abort upon pressing Enter. Execution proceeds only when the user explicitly inputs `yes`.

4. **Zero Hardcoded Machine Paths**:
   Paths displayed in logs, documentation, and briefs must use `<workspace_root>`, `<download_dir>`, or relative notations. Never expose drive letters or local user directories.

## 2. Ingestion Execution Checklist

- [ ] Capture raw string via `Read-Host` or clipboard API.
- [ ] Strip outer double (`"`) and single (`'`) quotation marks.
- [ ] Remove trailing backslashes (`\`) and forward slashes (`/`).
- [ ] Check existence using `Test-Path -LiteralPath $cleanPath`.
- [ ] Detect payload context: Git remote URL, local Git repo, script file, or workspace directory.
- [ ] Update `_run.json` with resolved `targetDir` and `lastIngestionType`.
- [ ] Display Pre-Flight Briefed Card.
- [ ] Await explicit `yes` confirmation before triggering target action.
```

---

### 4.3 Concrete Example: `combo` Artifact (`combo/web-clipboard-to-terminal-and-dragndrop-directory.md`)

```markdown
---
name: web-clipboard-to-terminal-and-dragndrop-directory
aliases: [clipboard-to-terminal-combo, web-to-local-dragndrop-runbook]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, clipboard, drag-and-drop, terminal, web, runbook]
description: Master composite operational runbook orchestrating web clipboard ingestion and downloaded directory drag-and-drop into active terminal tool workflows.
dependencies:
  - "[[skill/clipboard-web-and-download-dragndrop-ingestion]]"
  - "[[skill/confirmation-to-proceed-brief-overview-options]]"
  - "[[skill/save-option-as-exact-executor-name-json]]"
  - "[[skill/zero-hardcoded-sensitive-variables]]"
related:
  - "[[docs/website/clipboard-web-ingestion]]"
  - "[[docs/repo/git-manage]]"
pros:
  - "Seamless end-to-end user experience from web browser to terminal execution"
  - "Unified pipeline handling both remote URLs and local dropped files"
  - "Full auditability via _run.json and terminal pre-flight reviews"
cons:
  - "Multi-step flow requires user focus transition between browser, explorer, and shell"
---

# Web Clipboard to Terminal & Drag-and-Drop Directory Runbook

## 1. Workflow Pipeline Diagram

```text
+-------------------------------------------------------------------------------+
|         WEB CLIPBOARD TO TERMINAL & DRAG-AND-DROP WORKFLOW PIPELINE           |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ TRIGGER: USER ACTION IN BROWSER OR FILE EXPLORER ]                         |
|  - Case A: User copies URL / git clone from website                           |
|  - Case B: User downloads cartridge / directory to <download_dir>             |
|                                  |                                            |
|                                  v                                            |
|  +-------------------------------------------------------------------------+  |
|  | STAGE 1: TERMINAL INGESTION                                             |  |
|  | - If Clipboard: Auto-read via [Windows.Forms.Clipboard]::GetText()     |  |
|  | - If Drag & Drop: User drops directory into active Read-Host prompt     |  |
|  +-------------------------------------------------------------------------+  |
|                                  |                                            |
|                                  v                                            |
|  +-------------------------------------------------------------------------+  |
|  | STAGE 2: SANITIZATION & NORMALIZATION                                   |  |
|  | - Strip leading/trailing quotes and trailing slashes                    |  |
|  | - Convert to canonical literal path via Resolve-Path                   |  |
|  | - Detect context: repo, common, file, website, blender, unity          |  |
|  +-------------------------------------------------------------------------+  |
|                                  |                                            |
|                                  v                                            |
|  +-------------------------------------------------------------------------+  |
|  | STAGE 3: PERSISTENCE & PRE-FLIGHT GATING                                |  |
|  | - Save state into _run.json (targetDir, context, timestamp)             |  |
|  | - Render high-contrast Pre-Flight Card with action preview              |  |
|  | - Require explicit 'yes' confirmation to proceed                       |  |
|  +-------------------------------------------------------------------------+  |
|                                  |                                            |
|                                  v                                            |
|  +-------------------------------------------------------------------------+  |
|  | STAGE 4: CONTEXTUAL DISPATCH & EXECUTION                                |  |
|  | - repo: Launch git-manage.ps1 or git-checkpoint-rollback.ps1           |  |
|  | - common: Launch compiler.ps1 or decompiler.ps1                         |  |
|  | - file: Launch batch-target-dir-rename.ps1 or detector-clipboard        |  |
|  +-------------------------------------------------------------------------+  |
|                                  |                                            |
|                                  v                                            |
|  [ RESULT: WORKSPACE CONTEXT LOADED & OPERATION COMPLETE ]                    |
|                                                                               |
+-------------------------------------------------------------------------------+
```

## 2. Step-by-Step Execution Runbook

### Step 1: Initiating Terminal Ingestion
The user runs the target tool without parameters:
```powershell
.\script\repo\git-manage.ps1
```

### Step 2: Ingesting Web Clipboard URL
When the tool detects a Git URL in the OS clipboard, it suggests it as the default input:
```text
Detected Git URL in clipboard: https://github.com/pakcli/web-app_sims-homebox.git
[ 7 ] Clone Remote Repository -> Press Enter to accept clipboard URL.
```

### Step 3: Ingesting Dropped Directory
If switching target directory via option `[ t ]`, the user drags the target folder into the console:
```text
Enter target directory path (or drag & drop folder here):
> "<download_dir>\sample-project\"
```

### Step 4: Confirming Pre-Flight Card
The tool normalizes the path and presents the confirmation gate:
```text
========================================================================
PRE-FLIGHT BRIEFED OVERVIEW
------------------------------------------------------------------------
Target Path      : <download_dir>/sample-project
Context Detected : repo (Git Repository)
Current Branch   : main (Clean)
Proceed? (Type 'yes' to proceed, Enter to cancel): yes
========================================================================
```
```

---

### 4.4 Concrete Example: `json` Artifacts

#### A. State Persistence Schema (`_run.json`)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "RunStateBridge",
  "description": "Cross-tool state persistence file synchronizing active target paths and ingestion history.",
  "type": "object",
  "properties": {
    "targetDir": {
      "type": "string",
      "description": "Active target workspace or repository directory.",
      "default": "<workspace_root>"
    },
    "lastIngestionType": {
      "type": "string",
      "enum": ["clipboard-web", "drag-and-drop", "manual-cli", "default-workspace"],
      "description": "Channel used to provide the active target directory."
    },
    "lastWebUrl": {
      "type": "string",
      "description": "Last clipboard URL ingested from browser.",
      "default": "https://github.com/pakcli/web-app_sims-homebox.git"
    },
    "detectedContext": {
      "type": "string",
      "enum": ["common", "repo", "file", "website", "blender", "unity"],
      "description": "Resolved tool context for the target directory."
    },
    "lastUpdated": {
      "type": "string",
      "description": "ISO-8601 UTC timestamp of last modification."
    }
  },
  "required": ["targetDir", "lastIngestionType", "detectedContext", "lastUpdated"]
}
```

#### B. Concrete Instance (`_run.json`)

```json
{
  "targetDir": "<download_dir>/cartridge-v1",
  "lastIngestionType": "drag-and-drop",
  "lastWebUrl": "https://github.com/pakcli/web-app_sims-homebox.git",
  "detectedContext": "repo",
  "lastUpdated": "2026-11-08T23:30:00Z"
}
```

#### C. Web Catalog Ingestion Schema (`web-catalog-entry.json`)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "WebCatalogEntry",
  "description": "Payload definition for tools published on the web catalog with copy-paste terminal runners.",
  "type": "object",
  "properties": {
    "toolSlug": {
      "type": "string",
      "description": "Unique identifier matching the script name."
    },
    "context": {
      "type": "string",
      "enum": ["common", "repo", "file", "website", "blender", "unity"]
    },
    "title": {
      "type": "string",
      "description": "Human-readable display name."
    },
    "description": {
      "type": "string",
      "description": "Short summary of capabilities."
    },
    "oneLinerCommand": {
      "type": "string",
      "description": "One-line terminal snippet for instant execution."
    },
    "downloadArchiveUrl": {
      "type": "string",
      "description": "URL to download standalone zip/tarball for local drag-and-drop."
    }
  },
  "required": ["toolSlug", "context", "title", "description", "oneLinerCommand", "downloadArchiveUrl"]
}
```

#### D. Concrete Instance (`web-catalog-entry.json`)

```json
{
  "toolSlug": "compiler",
  "context": "common",
  "title": "Universal Toolchain Compiler",
  "description": "Bundles modular adapter components into self-contained single-file production runners.",
  "oneLinerCommand": "irm https://raw.githubusercontent.com/pakcli/all-lads-tool/main/dist/common/compiler.ps1 | iex",
  "downloadArchiveUrl": "https://github.com/pakcli/all-lads-tool/releases/download/v01-04-00/compiler-standalone.zip"
}
```

---

## 5. Architectural Verification & Compliance Checklist

- [x] **Zero Hardcoded Sensitive Variables**: Verified 0 drive letters and 0 local username references. Root-bounded placeholders (`<workspace_root>`, `<download_dir>`) used exclusively.
- [x] **Pure ASCII Formatting**: Verified 0 non-ASCII unicode box-drawing characters. Standard ASCII delimiters (`+`, `-`, `|`) used across all diagrams.
- [x] **Non-Truncated Concrete Examples**: Complete frontmatter, tables, diagrams, and full JSON payloads provided for `docs`, `skill`, `combo`, and `json`.
- [x] **Ground Truth Parity**: All parameters, module names, and script references align with real scripts (`detector-clipboard-4-mode.ps1`, `git-manage.ps1`, `path-normalizer.psm1`, `_run.json`).
- [x] **Safety Invariant**: Strict Pre-Flight Briefed Card with explicit confirmation gating (`yes` to proceed) documented as mandatory.
