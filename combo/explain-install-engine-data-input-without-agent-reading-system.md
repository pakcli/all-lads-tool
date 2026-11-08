---
name: explain-install-engine-data-input-without-agent-reading-system
aliases: [architecture-runbook-without-system-read, zero-system-read-5-pillars, where-explain-install-engine-data-input-no-system-read]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, meta-skill, architecture, runbook, security, containment, zero-system-read]
description: Master composite architecture runbook addressing the 5 core developer questions (Where Explain, Where Installation, Where Engine, Where Data, How to Input) under the Agent System-Read Quarantine standard, strictly prohibiting AI agents from reading or probing host OS partitions while enforcing username censoring in system documentation.
dependencies:
  - "[[zero-hardcoded-sensitive-variables-without-agent-reading-sistem]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[modular-architecture-standard]]"
  - "[[save-option-as-exact-executor-name-json]]"
related:
  - "[[explain-install-engine-data-input-bounded-relative]]"
  - "[[update-readme-and-guide-and-what-commit-message-donot-commit-yet]]"
  - "[[donot-code-yet]]"
pros:
  - "Completely shields host operating system partitions from autonomous agent inspection"
  - "Answers the 5 foundational architecture questions in a single self-contained runbook"
  - "Enforces username masking whenever system paths are documented"
cons:
  - "Requires upfront discipline to prevent tools or agents from making host-level read calls"
---

# Architecture Runbook: The 5 Pillars Under Agent System-Read Quarantine (`explain-install-engine-data-input-without-agent-reading-system`)

> [!IMPORTANT]
> **THE 5-PILLAR SYSTEM-ISOLATED ARCHITECTURAL CONTRACT**:
> Every developer, contributor, and AI agent operating in this repository must understand the exact location and boundaries of:
> 1. **Where Explain** (The Documentation & Architectural SSOT)
> 2. **Where Installation** (The Local Workspace Deployment & Runtime Setup)
> 3. **Where is the Engine** (The Central Orchestration Core & Context Adapters)
> 4. **Where is my Data** (Atomic JSON Persistence, Working State, and Cache Stores)
> 5. **How do I Input it** (Safe Input Methods, Secure Parameters, and 2-Letter Privacy Masking)
>
> All 5 pillars are strictly bounded under the **Agent System-Read Quarantine** (`zero-hardcoded-sensitive-variables-without-agent-reading-sistem`): AI agents are forbidden from executing read or inspection operations against host OS directories (`C:\`, `C:\Users\`, `/etc/`), and documentation referencing system paths must use generic tokens (`%APPDATA%`, `%USERPROFILE%`) or censored usernames (`C:\Users\us****\...`).

---

## 1. Monospace 5-Pillar Architecture & Quarantine Diagram

```text
+-----------------------------------------------------------------------------------------------+
|         THE 5 ARCHITECTURAL PILLARS (AGENT SYSTEM-READ QUARANTINE STANDARD)                   |
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|  [ HOST OS ROOT PARTITION (C:\, /etc/, /var/) - STRICT READ QUARANTINE ]                      |
|  - Agent Read / Probe Tools : BLOCKED / PROHIBITED (Zero host file inspection)                |
|  - Documentation Policy     : Generic tokens (%APPDATA%) or censored (C:\Users\us****\...)    |
|                                                                                               |
|  ===========================================================================================  |
|                                                                                               |
|  [ AUTHORIZED WORKSPACE ROOT: <workspace_root>/ ]                                             |
|                                                                                               |
|  1. WHERE EXPLAIN : Architectural SSOT Hub                                                    |
|     +--- README.md                             (Master hub & context index)                   |
|     +--- GUIDE.md                              (Complete operational & CLI manual)            |
|     +--- brief/vXX-XX-XX_<name>.md             (Versioned architectural briefs)               |
|     +--- docs/<context>/<tool-slug>.md         (1:1 technical tool documentation)             |
|                                                                                               |
|  2. WHERE INSTALLATION : Local Deployment Boundary                                            |
|     +--- Portable clone location               (<workspace_root>/all-lads-tool)               |
|     +--- Zero global OS package pollutions     (All dependencies project-local)               |
|     +--- Execution policy                      (Set-ExecutionPolicy -Scope CurrentUser)       |
|                                                                                               |
|  3. WHERE IS THE ENGINE : Execution Core & Adapters                                           |
|     +--- Portable launcher                     (_run.ps1 & _mainmenu.ps1)                     |
|     +--- 5 Domain Context orchestrators        (script/<context>/<tool-slug>.<ext>)           |
|     +--- Flat versioned adapters               (script/<context>/adapter/<adapter>.psm1)      |
|                                                                                               |
|  4. WHERE IS MY DATA : Atomic Persistence Stores                                              |
|     +--- Tool state & history                  (script/<context>/<tool-slug>.json)            |
|     +--- Launcher configuration                (_run.json)                                    |
|     +--- Git-ignored environment stores        (.env, _run.env)                               |
|                                                                                               |
|  5. HOW DO I INPUT IT : Sanitized Ingestion Protocols                                         |
|     +--- Environment injection                 ($env:TOOL_INPUT, process.env)                 |
|     +--- Interactive CLI prompt                (Read-Host with SecureString/default)          |
|     +--- 2-Letter privacy masking              (dc******@domain.com, pa****)                  |
|     +--- Zero-system-read containment          (All path inputs resolved within workspace)    |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+
```

---

## 2. Pillar 1: Where Explain (Documentation & Architectural SSOT)

The explanatory layer is organized hierarchically so that both human developers and AI agents find complete documentation without guessing or scanning random directories:

### 2.1 The Master Hubs
- **[`README.md`](file:///<workspace_root>/README.md)**: The top-level entry point explaining the philosophy, 5-context architecture overview, quickstart commands, and feature matrix.
- **[`GUIDE.md`](file:///<workspace_root>/GUIDE.md)**: The comprehensive technical manual detailing exact CLI switches, interaction modes, WPF GUI layouts, and troubleshooting solutions.

### 2.2 Versioned Architectural Briefs (`brief/`)
- Located strictly in `brief/vXX-XX-XX_<name>.md`.
- Milestone briefs (e.g. `brief/v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md`) define immutable topology decisions, dependency rules, and folder invariants.

### 2.3 1:1 Tool Documentation (`docs/<context>/`)
- Every executable script in `script/<context>/<tool-slug>.<ext>` has an exact 1:1 documentation file in `docs/<context>/<tool-slug>.md` (per `[[docs-same-file-name-script]]`).
- **Zero Markdown in Script**: No `.md` files are permitted inside `script/`. All option tables, parameters, and briefed overview cards are consolidated inside `docs/<context>/<tool-slug>.md`.

### 2.4 Explaining System Paths Without Leaking Identity
When documentation explains operating system integration, global runtimes, or system shortcuts:
- Use platform environment tokens: `%APPDATA%`, `%USERPROFILE%`, `$env:LOCALAPPDATA`, or `$HOME`.
- Use generic program paths: `C:\Program Files\nodejs\node.exe`, `C:\Program Files\Git\bin\git.exe`.
- When illustrating user-specific paths, personal usernames must be strictly masked: `C:\Users\us****\AppData\Local\...`.

---

## 3. Pillar 2: Where Installation (Deployment & Runtime Setup)

### 3.1 Local Workspace Clone
Installation is entirely local and portable. No global system files are altered:
```powershell
# Clone into an authorized workspace folder:
git clone https://github.com/pakcli/all-lads-tool.git
cd all-lads-tool
```

### 3.2 Agent System-Read Quarantine During Installation
- Agents must **NEVER** probe host OS directories (`dir C:\Users`, `Test-Path C:\Windows\System32`) to detect installed software.
- Runtime detection must rely strictly on standard system `PATH` resolution (`Get-Command git`, `node --version`, `python --version`):

```powershell
# CORRECT: Detecting runtime availability via system PATH without probing host directories:
$gitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
if (-not $gitAvailable) {
    Write-Warning "Git CLI is not found in system PATH. Please ensure Git is installed."
}

# FORBIDDEN (VIOLATION): Probing hardcoded system directories:
$gitCheck = Test-Path "C:\Program Files\Git\bin\git.exe" # VIOLATION: REJECTED!
$userCheck = Get-ChildItem "C:\Users"                  # VIOLATION: STRICTLY FORBIDDEN!
```

### 3.3 Execution Policy Configuration
To allow local PowerShell scripts to execute without altering system-wide machine registries:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## 4. Pillar 3: Where is the Engine (Execution Core & Adapters)

The execution engine is structured in 3 decoupled, portable tiers:

### 4.1 Portable Launcher Tier
- **`_run.ps1`**: The universal entry point. Scans the active drive for `_mainmenu.ps1`, caches the selection in `_run.json`, and maintains the quick-rerun history stack (`0 = latest`).
- **`_mainmenu.ps1`**: The central CLI cockpit providing indexed A-Z access to all automation tools across all contexts.

### 4.2 Context Orchestrator Tier (`script/<context>/`)
Each domain context houses standalone, executable orchestrators:
- `script/file/detector-clipboard-4-mode.ps1`: PolyClip 4-mode clipboard suite and Git multi-protocol bridge.
- `script/file/csv-to-frontmatter.ps1`: Bidirectional CSV and YAML Frontmatter transformer.
- `script/repo/git-manage.ps1`: Interactive Git manager and Git clone wizard.
- `script/repo/git-branch-rename.ps1`: Flat git branch renaming automation.
- `script/website/build-bundles.js`: Client-side bundling engine.
- `script/blender/fbx-export.py`: 3D asset export pipeline.
- `script/unity/asset-importer.cs`: Game engine asset importer.

### 4.3 Flat Versioned Adapter Tier (`script/<context>/adapter/`)
Per `brief/v01-03-02`, all engine subsystems and version handlers are flattened directly inside `script/<context>/adapter/` as first-class modules:
- No nested subdirectories (`modules/dependencies-checker/` is eliminated).
- Adapters are dot-sourced or imported dynamically via `$PSScriptRoot`.

```text
script/file/
	detector-clipboard-4-mode.ps1            # Main Orchestrator
	detector-clipboard-4-mode.json           # Atomic 1:1 State Store
	adapter/
		detector-clipboard-4-mode.psm1       # Master Facade
		clipboard-history-store.psm1         # Persistence Service
		clipboard-jit-inspector.psm1         # JIT Probing & Git Parsing
		clipboard-mode-transformer.psm1     # 4-Mode Dispatcher
		drive-color-protocol.psm1           # Palette Protocol
		ui-card-renderer.psm1               # WPF Row Cards & Git Pill Tabs
		panel-window-host.psm1              # Full-Dark Window Host
		cli-console-dashboard.psm1          # ANSI Terminal Dashboard
```

---

## 5. Pillar 4: Where is my Data (Atomic Persistence Stores)

User data, state, history, and configuration files are **NEVER** written to host OS paths (`C:\Users\...`, `AppData\Roaming\...`). All data sits strictly inside the authorized workspace:

### 5.1 Atomic 1:1 State Files (`<executor-name>.json`)
Per `[[save-option-as-exact-executor-name-json]]`, every tool persists its session defaults, parameters, and history in a JSON file named identically to its script base filename:
- Script: `script/file/detector-clipboard-4-mode.ps1`
- Data Store: `script/file/detector-clipboard-4-mode.json`

### 5.2 Launcher State (`_run.json`)
The portable launcher records:
- `mainMenuPath`: Dynamically resolved path to `_mainmenu.ps1`.
- `history`: Array of past executions (`key`, `name`, `timestamp`).
- `targetDir`: Currently active target directory.

### 5.3 Git-Ignored Configuration Files
Private workspace configuration is isolated in git-ignored files:
- `_run.env` (mirrored from `_run.env.example`).
- `.env.local` for local secrets.

---

## 6. Pillar 5: How do I Input it (Sanitized Ingestion Protocols)

To input data, parameters, and sensitive credentials safely without risking system leaks:

### 6.1 Environment Variable Injection
Pass sensitive tokens via process environment variables rather than hardcoding in scripts:
```powershell
# Set in current terminal session (ephemeral):
$env:TOOL_API_TOKEN = "my-secure-token"

# In PowerShell script:
$token = if ($env:TOOL_API_TOKEN) { $env:TOOL_API_TOKEN } else { "" }
```

### 6.2 Interactive CLI Input with Masking
When interactive scripts require user credentials or sensitive inputs:
```powershell
# Secure masked entry for passwords/tokens:
$secureToken = Read-Host "Enter Secret Token" -AsSecureString
```

### 6.3 Two-Letter Default Privacy Masking
When displaying saved configurations, tokens, or email addresses in CLI output or WPF panels, apply the 2-letter exposure rule:
```powershell
function Mask-SensitiveValue ([string]$val) {
    if ([string]::IsNullOrWhiteSpace($val)) { return "" }
    if ($val.Length -le 2) { return "**" }
    return $val.Substring(0, 2) + ("*" * ($val.Length - 2))
}
# Output: dc******@domain.com, ghp_************************
```

### 6.4 Enforcement of Zero-System-Read During Input
If an input parameter is a file path:
- Validate that the target path does NOT point to a host system root partition (`C:\Windows`, `/etc/`).
- Verify that the path resides safely within `<workspace_root>/`.

---

## 7. Verification & Compliance Checklist

Before committing changes or deploying tools under this standard:

- [ ] **Where Explain**: Confirm that tool documentation exists 1:1 in `docs/<context>/<tool-slug>.md` and contains zero hardcoded machine paths.
- [ ] **Where Installation**: Confirm that setup instructions rely on system `PATH` rather than probing host system directories.
- [ ] **Where is the Engine**: Confirm that all scripts and adapters resolve paths dynamically via `$PSScriptRoot` or `__dirname` without hardcoded drive letters.
- [ ] **Where is my Data**: Confirm that data files follow `<executor-name>.json` and are placed alongside the script in the workspace.
- [ ] **How do I Input it**: Confirm that sensitive inputs use environment variables or masked prompts, and that agents performed zero reads on host OS partitions.
