---
title: Git Manager
tool: git-manage.ps1
category: repo & git
runtime: PowerShell 5.1+ / 7+
aliases: [git-manage, repo-manager]
tags: [all-lads-tool, repo, git, adapter, clone, options]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[git-clone-briefed-overview]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
---

# `git-manage.ps1` — Universal Git Manager (Context: Repo)

> [!INFO]
> **Context**: `repo` | **Executable**: `script/repo/git-manage.ps1`
> **Adapters**: `script/repo/adapter/v02-30-00.psm1` (Git 2.30+), `script/repo/adapter/v02-40-00.psm1` (Git 2.40+)
> **Canonical Documentation**: `docs/repo/git-manage.md` (Matches script filename 1:1)

Orchestrator Git yang mendeteksi versi Git runtime di mesin pengembang secara dinamis dan memuat adapter yang sesuai. Mendukung status repositori real-time, branch rename, log inspect, interaktif retargeting ke direktori lain, dan remote repository cloning dengan pre-flight Briefed Overview.

---

## 1. System Options Overview

The Git Manager (`script/repo/git-manage.ps1`) exposes the following operations in its interactive cockpit:

```text
+-------------------------------------------------------------------------------+
|                       GIT MANAGER INTERACTIVE COCKPIT                         |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ 1 ] Refresh Status                                                         |
|        - Re-evaluates working tree status using `Invoke-GitStatus`.           |
|        - Queries branch and latest commit without throwing on fresh repos.    |
|                                                                               |
|  [ 2 ] Branch Rename (Invoke-GitBranchRename)                                 |
|        - Renames local active branch using `git branch -m <name>`.            |
|                                                                               |
|  [ 3 ] Recent Commits (git log -5)                                            |
|        - Pretty-prints topological commit graph with author, date, and hash.  |
|                                                                               |
|  [ 4 ] Git Clone Remote Repository (Invoke-GitClone)                          |
|        - Launches the interactive Git Clone Wizard with Briefed Overview.     |
|        - Auto-retargets active workspace to the newly cloned repository.      |
|                                                                               |
|  [ t ] Retarget Directory (Switch Git Repo)                                   |
|        - Scans parent workspace for sibling Git repositories.                |
|        - Allows entering custom paths or triggering Git Clone directly.       |
|                                                                               |
|  [ q ] Quit                                                                   |
|        - Exits the Git Manager cleanly.                                       |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 2. Non-Git Directory Retargeting Protocol

When `git-manage.ps1` starts on a non-Git directory, or when retargeting (`t`) points to a non-Git path:

1. **Non-Destructive Alert**: The system signals `[ALERT] '<path>' is not a git repository.`
2. **Action Dispatcher**:
   - `[ 1 ] Clone a remote repository here (Git Clone Wizard)`: Assigns the folder as clone destination.
   - `[ 2 ] Select another Git repository from workspace`: Re-opens the workspace scanner.
   - `[ 3 ] Initialize a fresh Git repository here (git init)`: Runs `git init` and synchronizes target.
   - `[ q ] Quit`: Aborts without side effects.

---

## 3. URL Ingestion & Normalization Engine

The clone engine accepts all four standard GitHub clone formats:

```text
+---------------------+---------------------------------------------------------+-------------------------------------------------------------+
| INPUT FORMAT        | EXAMPLE RAW INPUT                                       | PARSED PROTOCOL & NORMALIZED TARGET                         |
+---------------------+---------------------------------------------------------+-------------------------------------------------------------+
| HTTPS URL           | https://github.com/pakcli/absolute-home-inventory.git    | HTTPS: https://github.com/pakcli/absolute-home-inventory.git|
| SSH URL             | git@github.com:pakcli/absolute-home-inventory.git        | SSH: git@github.com:pakcli/absolute-home-inventory.git     |
| GitHub CLI Command  | gh repo clone pakcli/absolute-home-inventory            | CLI: https://github.com/pakcli/absolute-home-inventory.git  |
| Short-Form Slug     | pakcli/absolute-home-inventory                          | SLUG: https://github.com/pakcli/absolute-home-inventory.git |
+---------------------+---------------------------------------------------------+-------------------------------------------------------------+
```

---

## 4. Destination Strategies

- **Mode A: In-Place Clone (`.`)**:
  - Permitted only if the target directory exists and is completely clean (zero files/subfolders).
  - Clones repository root directly into the specified directory without creating an extra subfolder level.
- **Mode B: Subdirectory Clone (`<target>/<repo-name>`)**:
  - Default when target directory is non-empty or when cloning from within a parent workspace.
  - Automatically infers the repository name from the URL slug (e.g., `absolute-home-inventory`).
- **Mode C: Custom Directory**:
  - Allows manual override of destination path.

---

## 5. Pre-Flight Briefed Overview Card

Before executing `Invoke-GitClone`, the tool renders the Briefed Overview card:

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

### Confirmation Gating Rules:
1. Only explicit `y` or `yes` (case-insensitive) advances execution.
2. Pressing `Enter`, typing `n`, `no`, or any other key immediately cancels the operation with `[CANCELLED] Git clone aborted by user confirmation check.`
3. On successful clone:
   - Validates `.git` exists in target.
   - Calls `Update-RunJsonTarget` to persist new target in `_run.json`.
   - Switches the active session to the new repository and displays its status.
