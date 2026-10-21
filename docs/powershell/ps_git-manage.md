---
title: Universal Git Manager & Recovery Engine
tool: ps_git-manage.ps1
category: git & versioning
runtime: PowerShell 7+
aliases: [ps_git-manage, ps_git-manage-tool, git-manager]
tags: [all-lads-tool, powershell, git, cartridges]
---

# 🛠️ `ps_git-manage.ps1` — Universal Git Manager & Recovery Engine

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Interactive, target-directory-aware Git operations toolkit. Supports managing either the workspace root or individual cartridge subfolders (`apps/<slug>/`).

---

## 1. Quick Syntax & Usage

```powershell
# Interactive Master Menu (defaults to workspace root)
.\all-lads-tool\script\powershell\ps_git-manage.ps1

# Target a specific cartridge subfolder
.\all-lads-tool\script\powershell\ps_git-manage.ps1 -TargetDir "apps/radiansincostan"

# Direct Action invocation
.\all-lads-tool\script\powershell\ps_git-manage.ps1 -Action "Recover"
.\all-lads-tool\script\powershell\ps_git-manage.ps1 -Action "Status"
```

---

## 2. Command Matrix (-1 to 9 & Footer)

| Key | Action | Description | Safety Level |
| :--- | :--- | :--- | :--- |
| `[-1]` | **Discard All** | Reverts uncommitted changes (`git restore .` + `git clean -fd`) | ⚠️ Protected (requires typing `DISCARD`) |
| `[ 0]` | **Status** | Live dashboard of branch, remotes, dirty file counts, and recent commits | Read-Only |
| `[ 1]` | **Recover** | Reflog browser with detached commit detection & surgical/full restore | Non-destructive preview |
| `[ 2]` | **Commit** | Status preview, staging options (All/Selective), & Conventional Commit prefix helper | Standard |
| `[ 3]` | **Push** | Pushes active branch to upstream remote with auto tracking setup | Standard |
| `[ 4]` | **Pull / Sync** | Smart pull (Rebase, Fast-Forward only, or Merge) | Standard |
| `[ 5]` | **Assign Git** | Initializes Git repo (`git init -b main`), adds remote, creates `.gitignore`, initial commit | Safe |
| `[ 6]` | **Remove Git** | "Remove with more nicer": Unlocks ReadOnly/hidden attributes, cleans locks, deletes `.git` cleanly | ⚠️ Protected (requires typing `REMOVE`) |
| `[ 7]` | **Clone** | Clones external repo into target directory or designated subfolder | Standard |
| `[ 8]` | **Worktree** | Manages isolated worktree branches (`list`, `add`, `remove/prune`) | Safe |
| `[ 9]` | **Custom Shell** | Runs arbitrary git commands or executes drag & dropped scripts (`.ps1`, `.bat`, `.js`, `.py`) | Standard |
| `[ h]` | **Help** | Displays full guide and shortcut instructions | Read-Only |
| `[ t]` | **Target Dir** | Interactive switch for target directory (Root, `apps/*`, or drag & drop folder) | Safe |
| `[ q]` | **Quit** | Exits the Git Manager | Safe |

---

## 3. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-TargetDir` | string | No | Workspace Root | Working directory to execute git commands in |
| `-Action` | string | No | Interactive Menu | Direct action (`Recover`, `Commit`, `Push`, `Pull`, `Discard`, `Remove`, `Assign`, `Clone`, `Worktree`, `Status`) |

---

## 4. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/ps_git-manage.ps1`](..\../script/powershell/ps_git-manage.ps1)
* **Legacy Wrapper**: [`all-lads-tool/script/powershell/ps_recover.ps1`](..\../script/powershell/ps_recover.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md).
