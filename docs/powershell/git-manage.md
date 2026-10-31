---
title: Universal Git Manager & Recovery Engine
tool: git-manage_stand.ps1
category: git & versioning
runtime: PowerShell 7+
aliases: [git-manage, git-manage_stand, git-manager]
tags: [all-lads-tool, powershell, git, cartridges, standalone]
---

# 🛠️ `git-manage_stand.ps1` / `git-manage.ps1` — Universal Git Manager & Recovery Engine

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`
> **Two Editions Available**:
> - **Modular (`git-manage.ps1`)**: Connected to `module/` headless libraries (`git-status.psm1`, `git-reflog.psm1`, `git-submodule.psm1`, `git-core.psm1`).
> - **Standalone (`git-manage_stand.ps1`)**: Self-contained, zero-dependency single executable compiled for drag-and-drop or isolated portability.

Interactive, target-directory-aware Git operations toolkit. Supports managing either the workspace root or individual cartridge subfolders (`apps/<slug>/`).

---

## 1. Quick Syntax & Usage

```powershell
# Run Standalone Edition (Self-contained)
.\all-lads-tool\script\powershell\git-manage_stand.ps1

# Run Modular Edition (Wired to module/*)
.\all-lads-tool\script\powershell\git-manage.ps1

# Target a specific cartridge subfolder
.\all-lads-tool\script\powershell\git-manage_stand.ps1 -TargetDir "apps/radiansincostan"

# Direct Action invocation
.\all-lads-tool\script\powershell\git-manage_stand.ps1 -Action "Recover"
.\all-lads-tool\script\powershell\git-manage_stand.ps1 -Action "Status"
```

---

## 2. Command Matrix (-1 to 9, 11 & Footer)

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
| `[11]` | **Submodule** | Interactive Git Submodule Hub (numbered list, negative index to delete, URL to add) | Standard |
| `[ h]` | **Help** | Displays full guide and shortcut instructions | Read-Only |
| `[ t]` | **Switch Target** | Switch target directory (workspace root, apps cartridge, or drag & drop path) | Interactive |
| `[ q]` | **Quit** | Exits the interactive manager | Read-Only |
