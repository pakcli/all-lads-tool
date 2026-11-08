---
title: Git Submodule Manager
tool: git-submodule.ps1
category: repo
runtime: PowerShell 5.1 / 7+
aliases: [git-submodule, submodule-manager]
tags: [all-lads-tool, repo, powershell, git, submodules, modular]
---

# `git-submodule.ps1` - Git Submodule Manager

> [!INFO]
> **Runtime**: PowerShell 5.1 / 7+ | **Directory**: `script/repo/`  
> **Architecture**: Modular Edition (Connected to `adapter/git-submodule.psm1`, `adapter/git-core.psm1`, and `adapter/history.psm1`).

Zero-hardcoded-path Git Submodule utility supporting adding, updating, syncing, listing, and cleanly removing submodule repositories.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive Submodule Hub (Lists submodules, accepts numbers, -index, or URLs)
.\script\repo\git-submodule.ps1

# Modular invocation
.\script\repo\git-submodule.ps1 -Action list

# CLI Direct Add with Auto Path Extraction
.\script\repo\git-submodule.ps1 -Action add -Url "https://github.com/org/repo.git"

# CLI Direct Remove (deinit + git rm + cache cleanup)
.\script\repo\git-submodule.ps1 -Action remove -Path "submodules/repo" -Force
```

---

## 2. Interactive Hub Features

| Input Pattern | Action | Behavior |
| :--- | :--- | :--- |
| `https://...` or `git@...` | **Add Submodule** | Auto-extracts target directory from repository name |
| `-1`, `-2`, `-[n]` | **Remove Submodule** | Surgical deinitialization, index removal, and `.git/modules` cache wipe |
| `1`, `2`, `[n]` | **Update Submodule** | Updates the specific submodule at index `[n]` |
| `all` | **Sync All** | Updates all registered submodules recursively |
| `[1]` to `[5]` | **Menu Directives** | Interactive wizard for Add, Update, Status, Sync, Remove |

---

## 3. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Action` | string | No | `""` | Operation: add, update, sync, status, list, remove, interactive |
| `-Url` | string | Cond | `""` | Git repository URL when adding submodules |
| `-Path` | string | Cond | `""` | Destination directory relative to repo root |
| `-Branch` | string | No | `main` | Target branch to track for updates |
| `-Force` | switch | No | `$false` | Force operation without confirmation |

---

## 4. Implementation Sources

* **Runner**: [`script/repo/git-submodule.ps1`](../../script/repo/git-submodule.ps1)
* **Adapters**:
  - [`script/repo/adapter/git-submodule.psm1`](../../script/repo/adapter/git-submodule.psm1)
  - [`script/repo/adapter/git-core.psm1`](../../script/repo/adapter/git-core.psm1)
  - [`script/repo/adapter/history.psm1`](../../script/repo/adapter/history.psm1)
