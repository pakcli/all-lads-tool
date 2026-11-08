---
name: git-clone-briefed-overview
aliases: [git-clone-wizard, git-clone-options, git-retarget-clone, git-briefed-overview]
category: REPO_MANAGEMENT
tags: [all-lads-tool, skill, git, clone, repo, workflow, interactive]
description: Interactive Git clone orchestration and non-git directory retargeting standard with mandatory pre-flight briefed overview, multi-protocol URL parsing (HTTPS, SSH, GitHub CLI), and explicit confirmation gating before execution.
dependencies:
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[git-commit-convention]]"
  - "[[decoupled-engine-domain-isolation]]"
pros:
  - "Eliminates accidental file overwrites through pre-flight target directory inspection"
  - "Accepts all four standard remote repository formats (HTTPS, SSH, GitHub CLI, and short slugs)"
  - "Allows seamless onboarding of fresh directories by assigning non-git folders as clone targets"
  - "Mandates explicit affirmative confirmation (yes-to-proceed) before executing network transfers"
cons:
  - "Requires interactive terminal prompt for user confirmation in standard interactive mode"
  - "Requires network connectivity to validate and clone remote repositories"
---

# Git Clone with Briefed Overview Standard (`git-clone-briefed-overview`)

> [!IMPORTANT]
> **THE PRE-FLIGHT BRIEFED OVERVIEW INVARIANT**:
> No repository clone operation may proceed without displaying an upfront Briefed Overview card detailing the parsed remote URL, target local path, clone strategy (in-place vs. subdirectory), branch, and full command preview. The operation must require an explicit affirmative response (`y` or `yes`) to proceed.

---

## 1. Interaction Pipeline & Topology

```text
+-------------------------------------------------------------------------------+
|                 GIT CLONE & RETARGET BRIEFED OVERVIEW PIPELINE                |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ User Input / Trigger ]                                                     |
|  - Explicit Command (Option 4 / c)                                            |
|  - Non-Git Directory Retarget (t -> Select non-git folder)                     |
|  - Tool Startup on Non-Git Directory                                          |
|                                |                                              |
|                                v                                              |
|  [ 1. MULTI-PROTOCOL URL PARSING & NORMALIZATION ]                            |
|  - HTTPS: https://github.com/owner/repo.git                                   |
|  - SSH: git@github.com:owner/repo.git                                         |
|  - GitHub CLI: gh repo clone owner/repo -> parsed to https://github.com/...   |
|  - Slug: owner/repo -> expanded to https://github.com/owner/repo.git          |
|                                |                                              |
|                                v                                              |
|  [ 2. TARGET DESTINATION RESOLUTION ]                                         |
|  - Target Clean & Empty? -> Option to clone In-Place (.)                      |
|  - Target Non-Empty?     -> Infer Subdirectory (<repo-name>)                  |
|  - Custom Path Override  -> User-specified target directory                   |
|                                |                                              |
|                                v                                              |
|  [ 3. CONFIGURATION SELECTION ]                                               |
|  - Branch: Optional custom branch (default: remote HEAD)                      |
|  - Depth : Optional shallow clone (--depth 1 for fast downloads)             |
|                                |                                              |
|                                v                                              |
|  [ 4. PRE-FLIGHT BRIEFED OVERVIEW CARD ]                                      |
|  +-------------------------------------------------------------------------+  |
|  | Remote URL    : https://github.com/pakcli/absolute-home-inventory.git    |  |
|  | Target Path   : <workspace_root>/absolute-home-inventory                  |  |
|  | Clone Mode    : New Subdirectory                                        |  |
|  | Branch        : (Remote Default HEAD)                                   |  |
|  | Command       : git clone <url> "<path>"                                |  |
|  +-------------------------------------------------------------------------+  |
|                                |                                              |
|                                v                                              |
|  [ 5. EXPLICIT YES-TO-PROCEED GATING ]                                        |
|  - Prompt: "Proceed with git clone? [y/N]"                                    |
|  - Input === 'y' | 'yes' -> Proceed to Step 6                                 |
|  - Any other input       -> Immediate cancellation with zero side-effects     |
|                                |                                              |
|                                v                                              |
|  [ 6. EXECUTE CLONE (ADAPTER DISPATCH) ]                                      |
|  - Invoke-GitClone via detected Git version adapter                           |
|  - Real-time stderr/stdout streaming                                          |
|                                |                                              |
|                                v                                              |
|  [ 7. POST-CLONE SYNCHRONIZATION ]                                            |
|  - Verify target contains valid .git/                                         |
|  - Auto-retarget active workspace context                                     |
|  - Update targetDir in _run.json                                              |
|  - Enter Git Cockpit on new repository                                        |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 2. Multi-Protocol URL Normalization Rules

The parser cleans quotation marks and automatically resolves variations:

1. **GitHub CLI Command Ingestion**:
   - Input: `gh repo clone pakcli/absolute-home-inventory`
   - Resolution: Extracted slug `pakcli/absolute-home-inventory` expanded to `https://github.com/pakcli/absolute-home-inventory.git`.
2. **Short-Form Slug**:
   - Input: `pakcli/absolute-home-inventory`
   - Resolution: Automatically prepends `https://github.com/` and appends `.git`.
3. **Native HTTPS / SSH**:
   - Input: `https://github.com/...` or `git@github.com:...`
   - Resolution: Preserved and sanitized.

---

## 3. Non-Git Directory Retarget Assignment

When a user retargets (`t`) to a directory or launches the tool in a folder that is not yet a Git repository:

```text
==========================================================
   TARGET IS NOT A GIT REPOSITORY
==========================================================
 Current Directory : <workspace_root>/my-empty-project

 Available Actions:
  [ 1 ] Clone a remote repository here (Git Clone Wizard)
  [ 2 ] Select another Git repository from workspace
  [ 3 ] Initialize a fresh Git repository here (git init)
  [ q ] Quit
==========================================================
```

- Selecting `[ 1 ]` immediately engages the Clone Wizard with the chosen directory as the prefilled destination.
- If the chosen directory is completely empty, the wizard offers **In-Place Clone** (`git clone <url> .`), avoiding redundant nested folders.
- If the directory contains files, the wizard defaults to a subfolder named after the repository.

---

## 4. Pre-Flight Briefed Overview Specification

The Briefed Overview must display all parameters in high-contrast monospace formatting:

```text
==========================================================
   GIT CLONE PRE-FLIGHT BRIEFED OVERVIEW
==========================================================
 Remote URL    : https://github.com/pakcli/absolute-home-inventory.git
 Target Path   : <workspace_root>/absolute-home-inventory
 Clone Mode    : New Subdirectory
 Branch        : (Remote Default HEAD)
 History Depth : Full History
 Command       : git clone https://github.com/pakcli/absolute-home-inventory.git "<workspace_root>/absolute-home-inventory"
==========================================================

Proceed with git clone? [y/N] (Type 'y' or 'yes' to proceed): 
```

### Safety Gating Invariants:
1. Default selection on `Enter` is `N` (Cancellation).
2. Only matching `^(y|yes)$` triggers the network clone.
3. Failures in network or invalid repository URLs are captured without crashing the tool session.

---

## 5. Implementation Reference

- Script Entrypoint: `script/repo/git-manage.ps1`
- Options Specification: `docs/repo/git-manage.md`
- Modern Git Adapter: `script/repo/adapter/v02-40-00.psm1`
- LTS Git Adapter: `script/repo/adapter/v02-30-00.psm1`
