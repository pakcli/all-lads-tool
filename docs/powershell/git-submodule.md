---
title: Git Submodule Manager
tool: git-submodule_stand.ps1
category: git & submodules
runtime: PowerShell 7+
aliases: [git-submodule, git-submodule_stand, submodule-manager]
tags: [all-lads-tool, powershell, git, submodules, standalone]
---

# 🛠️ `git-submodule_stand.ps1` / `git-submodule.ps1` — Git Submodule Manager

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`
> **Two Editions Available**:
> - **Modular (`git-submodule.ps1`)**: Connected to `module/git-submodule.psm1` and `module/history.psm1`.
> - **Standalone (`git-submodule_stand.ps1`)**: Self-contained zero-dependency script.

Zero-hardcoded-path Git Submodule utility supporting adding, updating, syncing, listing, and cleanly removing submodule repositories.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive Submodule Hub (Lists submodules, accepts numbers, -index, or URLs)
.\all-lads-tool\script\powershell\git-submodule_stand.ps1

# Modular invocation
.\all-lads-tool\script\powershell\git-submodule.ps1 -Action list

# CLI Direct Add with Auto Path Extraction
.\all-lads-tool\script\powershell\git-submodule_stand.ps1 -Action add -Url "https://github.com/org/repo.git"

# CLI Direct Remove (deinit + git rm + cache cleanup)
.\all-lads-tool\script\powershell\git-submodule_stand.ps1 -Action remove -Path "submodules/repo" -Force
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
