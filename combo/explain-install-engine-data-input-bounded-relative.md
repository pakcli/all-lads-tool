---
name: explain-install-engine-data-input-bounded-relative
aliases: [architecture-runbook-bounded-relative, root-bounded-5-pillars, where-explain-install-engine-data-input-bounded]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, meta-skill, architecture, runbook, security, containment, bounded-relative-paths]
description: Master composite architecture runbook answering the 5 core developer questions (Where Explain, Where Installation, Where Engine, Where Data, How to Input) under the Root-Bounded Relative Path Standard, allowing relative navigation to local or sibling projects within an authorized workspace root while strictly prohibiting traversal above the root boundary.
dependencies:
  - "[[zero-hardcoded-sensitive-variables]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[modular-architecture-standard]]"
  - "[[save-option-as-exact-executor-name-json]]"
related:
  - "[[explain-install-engine-data-input-without-agent-reading-system]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[donot-code-yet]]"
pros:
  - "Supports modular multi-project orchestration and sibling repository workflows via relative paths"
  - "Enforces strict path jail checking to guarantee paths never ascend above the workspace root"
  - "Provides clear answers to the 5 architectural questions with concrete code examples"
cons:
  - "Requires runtime boundary validation on all relative path calculations"
---

# Architecture Runbook: The 5 Pillars Under Root-Bounded Relative Navigation (`explain-install-engine-data-input-bounded-relative`)

> [!IMPORTANT]
> **THE 5-PILLAR ROOT-BOUNDED ARCHITECTURAL CONTRACT**:
> Every developer, script, and AI agent operating in this repository must understand:
> 1. **Where Explain** (The Documentation & Architectural SSOT)
> 2. **Where Installation** (The Multi-Project Workspace Setup & Boundary Jail)
> 3. **Where is the Engine** (The Execution Core, Orchestrators, and Dynamic Resolvers)
> 4. **Where is my Data** (Atomic JSON Persistence, Sibling Project State, and Cache)
> 5. **How do I Input it** (Relative Path Ingestion, Path Jail Guards, and Masked Secrets)
>
> All 5 pillars are strictly bounded under the **Root-Bounded Relative Path Standard** (`zero-hardcoded-sensitive-variables`): relative paths between local subfolders (`./script/repo/`) and adjacent sibling projects (`../sibling-project/`) within the authorized multi-project workspace root are permitted, but paths are **strictly forbidden from ascending above the top-level workspace root boundary** (`wont go above level to root`).

---

## 1. Monospace 5-Pillar Architecture & Root Boundary Diagram

```text
+-----------------------------------------------------------------------------------------------+
|         THE 5 ARCHITECTURAL PILLARS (ROOT-BOUNDED RELATIVE NAVIGATION STANDARD)               |
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|  [ DISK ROOT / SYSTEM PARTITION (C:\, E:\, /) - OUTSIDE AUTHORIZED BOUNDARY ]                 |
|  - Traversing above workspace root : STRICTLY FORBIDDEN (Blocked by Path Jail)                |
|                                                                                               |
|  ===========================================================================================  |
|                                                                                               |
|  [ TOP-LEVEL AUTHORIZED WORKSPACE ROOT: <workspace_root>/ ]                                   |
|  |                                                                                            |
|  +---> project-a/ (all-lads-tool)                                                             |
|  |     |                                                                                      |
|  |     +--- 1. WHERE EXPLAIN : Architectural SSOT                                             |
|  |     |    +--- README.md                             (Master hub & context index)           |
|  |     |    +--- GUIDE.md                              (Complete operational & CLI manual)    |
|  |     |    +--- brief/vXX-XX-XX_<name>.md             (Versioned architectural briefs)       |
|  |     |    +--- docs/<context>/<tool-slug>.md         (1:1 technical tool documentation)     |
|  |     |                                                                                      |
|  |     +--- 2. WHERE INSTALLATION : Project Deployment                                        |
|  |     |    +--- Git clone location                    (<workspace_root>/all-lads-tool)       |
|  |     |    +--- Local script execution                (RemoteSigned CurrentUser)             |
|  |     |                                                                                      |
|  |     +--- 3. WHERE IS THE ENGINE : Execution Core                                           |
|  |     |    +--- Portable launcher                     (_run.ps1 & _mainmenu.ps1)             |
|  |     |    +--- Context orchestrators                 (script/<context>/<tool-slug>.<ext>)   |
|  |     |    +--- Flat versioned adapters               (script/<context>/adapter/*.psm1)      |
|  |     |                                                                                      |
|  |     +--- 4. WHERE IS MY DATA : Atomic Persistence Stores                                   |
|  |          +--- Tool state & history                  (script/<context>/<tool-slug>.json)    |
|  |          +--- Launcher configuration                (_run.json)                            |
|  |          +--- Git-ignored environment stores        (.env, _run.env)                       |
|  |                                                                                            |
|  +---> project-b/ (sibling-repository, e.g. pakcli-plugin)                                     |
|  |     +--- [ ALLOWED ]: Relative reference: Resolve-Path "../pakcli-plugin"                  |
|  |                                                                                            |
|  +---> 5. HOW DO I INPUT IT : Sanitized Ingestion Protocols                                   |
|        +--- Relative path validation                   (Test-PathWithinRoot guard)            |
|        +--- Sibling navigation                         (Permitted within <workspace_root>)    |
|        +--- Traversal escape rejection                 (../../.. -> BLOCKED)                  |
|        +--- 2-Letter privacy masking                   (dc******@domain.com, pa****)          |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+
```

---

## 2. Pillar 1: Where Explain (Documentation & Architectural SSOT)

The documentation architecture guarantees discoverability across the entire workspace while maintaining strict 1:1 parity and zero hardcoded paths:

### 2.1 Master Entry Points
- **[`README.md`](file:///<workspace_root>/README.md)**: High-level overview, 5 Domain Contexts, and project capabilities.
- **[`GUIDE.md`](file:///<workspace_root>/GUIDE.md)**: Complete operational guide, CLI parameters, UI/UX layouts, and troubleshooting matrix.

### 2.2 Versioned Architectural Briefs (`brief/`)
- Stored as `brief/vXX-XX-XX_<name>.md`.
- Acts as the Single Source of Truth (SSOT) for milestone versions, directory topology, and architectural invariants (e.g. `v01-03-02`).

### 2.3 1:1 Tool Documentation (`docs/<context>/`)
- Every script in `script/<context>/<tool-slug>.<ext>` corresponds **1:1** to `docs/<context>/<tool-slug>.md` (enforced by `[[docs-same-file-name-script]]`).
- **Zero Markdown in Script**: No `.md` files in `script/`. Option parameters and pre-flight briefed overview specifications are consolidated inside `docs/<context>/<tool-slug>.md`.

### 2.4 Relative Cross-Document References
- Use repository-relative links: `[git-manage.md](docs/repo/git-manage.md)`.
- Sibling project documentation references use bounded relative paths: `[agent-skills](../pakcli-plugin/.agents/skills/)`.
- Never include machine partition letters (`C:\`, `E:\`) or user profile paths in documentation.

---

## 3. Pillar 2: Where Installation (Multi-Project Workspace Setup)

### 3.1 Bounded Workspace Deployment
Installations sit inside a designated workspace directory:
```text
<workspace_root>/
	all-lads-tool/          <--- Target tool repository
	pakcli-plugin/          <--- Sibling plugin repository
	web-app_sims/           <--- Sibling web application
```

```powershell
# Navigate to your designated workspace root:
cd <workspace_root>

# Clone the repository:
git clone https://github.com/pakcli/all-lads-tool.git
```

### 3.2 Defining the Authorized Workspace Boundary
The root boundary is established at the parent of the project cluster:
```powershell
# Dynamic resolution of the workspace root:
$workspaceRoot = Split-Path $PSScriptRoot -Parent
```
Tools can orchestrate actions across `all-lads-tool` and `pakcli-plugin`, but the boundary prevents ascending above `<workspace_root>`.

---

## 4. Pillar 3: Where is the Engine (Execution Core & Dynamic Resolvers)

The engine lives in modular scripts and adapters that resolve their execution environment dynamically without hardcoded machine paths:

### 4.1 Orchestrator Scripts (`script/<context>/`)
Every automation tool is directly runnable from its context directory:
- `script/file/detector-clipboard-4-mode.ps1`
- `script/repo/git-manage.ps1`
- `script/file/csv-to-frontmatter.ps1`
- `script/repo/git-branch-rename.ps1`

### 4.2 Dynamic Root Resolution (PowerShell)
Engine scripts resolve their root dynamically from `$PSScriptRoot`:
```powershell
# Dynamic resolver for script directory and workspace root:
$scriptDir = $PSScriptRoot
$contextDir = Split-Path $scriptDir -Parent          # e.g., .../script
$projectRoot = Split-Path $contextDir -Parent        # e.g., .../all-lads-tool
$workspaceRoot = Split-Path $projectRoot -Parent      # e.g., .../workspace
```

### 4.3 Dynamic Root Resolution (Node.js)
```javascript
const path = require('path');
const scriptDir = __dirname;
const projectRoot = path.resolve(scriptDir, '..', '..');
const workspaceRoot = path.resolve(projectRoot, '..');
```

### 4.4 Flat Adapters (`script/<context>/adapter/`)
Per `brief/v01-03-02`, multi-version handlers and internal services are flattened as `.psm1` modules in `adapter/`, dot-sourced dynamically by the orchestrator.

---

## 5. Pillar 4: Where is my Data (Atomic Persistence Stores)

Data is persisted deterministically inside the workspace tree and never written to arbitrary disk locations:

### 5.1 Atomic 1:1 State Store (`<executor-name>.json`)
Per `[[save-option-as-exact-executor-name-json]]`, options and history are stored right next to the executor:
- Script: `<workspace_root>/all-lads-tool/script/file/detector-clipboard-4-mode.ps1`
- Data Store: `<workspace_root>/all-lads-tool/script/file/detector-clipboard-4-mode.json`

### 5.2 Sibling Data Interaction (Bounded)
When an automation script needs to read or write data in an adjacent sibling project:
- The path is resolved relatively: `Join-Path $workspaceRoot "sibling-project/data"`
- The path is validated against the workspace root before any read or write operation is executed.

### 5.3 Local Configuration
- `_run.json`: Stores user choice and history stack.
- `_run.env` / `.env.local`: Stores local environment variables (git-ignored).

---

## 6. Pillar 5: How do I Input it (Relative Path Ingestion & Jail Guards)

When providing input parameters, target directories, or credentials:

### 6.1 Path Boundary Validation Guard (`Test-PathWithinRoot`)
Every script accepting a `-TargetDir` or relative path input must run the path jail check:

```powershell
function Test-PathWithinRoot {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [string]$RootBoundary = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent)
    )

    try {
        $resolvedRoot = [System.IO.Path]::GetFullPath($RootBoundary)
        $combinedTarget = [System.IO.Path]::Combine($resolvedRoot, $TargetPath)
        $resolvedTarget = [System.IO.Path]::GetFullPath($combinedTarget)

        $sep = [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedRoot.EndsWith($sep)) {
            $resolvedRoot += $sep
        }

        # Must reside within root or match root exactly
        $isSubdir = $resolvedTarget.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)
        $isExactRoot = ($resolvedTarget.TrimEnd($sep) -eq $resolvedRoot.TrimEnd($sep))

        return ($isSubdir -or $isExactRoot)
    } catch {
        return $false
    }
}

# Example Usage:
$inputDir = "../sibling-project/notes"
if (Test-PathWithinRoot -TargetPath $inputDir) {
    Write-Host "[OK] Target directory is within authorized workspace root." -ForegroundColor Green
} else {
    Write-Error "[SECURITY VIOLATION] Target path escapes workspace root: $inputDir"
    exit 1
}
```

### 6.2 Pre-Flight Briefed Overview with Gating
Per `[[confirmation-to-proceed-brief-overview-options]]`, all resolved paths and commands must be displayed in a high-contrast card with explicit `[y/N]` confirmation before execution:

```text
==========================================================
   ACTION PRE-FLIGHT BRIEFED OVERVIEW
==========================================================
 Target Path     : <workspace_root>/sibling-project/notes
 Action Mode     : Bounded Relative Processing
 Command Preview : .\script\file\csv-to-frontmatter.ps1 -TargetDir "../sibling-project/notes"
==========================================================
Proceed with execution? [y/N] [Default: N]:
```

### 6.3 Sensitive Secrets & Privacy Masking
- Sensitive credentials must be injected via environment variables (`$env:API_KEY`) or git-ignored local configs.
- Frontends and logs must default to 2-letter masking (`dc******@domain.com`).

---

## 7. Verification & Compliance Checklist

- [ ] **Where Explain**: All documentation conforms 1:1 (`docs/<context>/<tool-slug>.md`) and uses relative links.
- [ ] **Where Installation**: Workspace is bounded within an authorized root without global OS pollution.
- [ ] **Where is the Engine**: Dynamic path resolvers (`$PSScriptRoot`, `__dirname`) eliminate all hardcoded drive letters.
- [ ] **Where is my Data**: History and state files sit in 1:1 `<executor-name>.json` stores.
- [ ] **How do I Input it**: All relative path inputs are validated via `Test-PathWithinRoot` to ensure they never escape the workspace root.
