---
title: Git Bash Universal Git Manager
tool: git-manage.sh
category: git & versioning
runtime: Git Bash / Unix Shell
aliases: [gitbash-manage-git, gitbash-git-manager]
tags: [all-lads-tool, gitbash, bash, git, submodule, reflog]
---

# 🛠️ `git-manage.sh` — Universal Git Manager (Git Bash Edition)

> [!INFO]
> **Runtime**: Git Bash / POSIX Bash | **Directory**: `all-lads-tool/script/gitbash/`  
> **Architecture**: Dual-Layer Edition (Standalone `git-manage_stand.sh` vs Modular `git-manage.sh`)  
> **Status Invariant**: Uncommitted quarantine strictly enforced under `donot-commit-yet`.

Interactive terminal cockpit for Git repository operations, reflog commit recovery, branch synchronization, and submodule management directly inside Git Bash or Linux/macOS environments.

---

## 1. Dual-Layer Editions

### A. Standalone Edition (`git-manage_stand.sh`)
* **File Location**: `script/gitbash/git-manage_stand.sh`
* **Features**: Self-contained, zero-dependency script with all modules inlined.
* **Usage**:
  ```bash
  bash all-lads-tool/script/gitbash/git-manage_stand.sh [target_directory]
  ```

### B. Modular Edition (`git-manage.sh`)
* **File Location**: `script/gitbash/git-manage.sh`
* **Features**: Dynamically sources headless libraries from `script/gitbash/module/`:
  - `git-core.sh`: Process execution wrapper
  - `git-status.sh`: Status queries and dirty count
  - `git-reflog.sh`: Surgical commit recovery
  - `git-submodule.sh`: Submodule automation engine
  - `history.sh`: JSON state tracker
* **Usage**:
  ```bash
  bash all-lads-tool/script/gitbash/git-manage.sh [target_directory]
  ```

---

## 2. Interactive Menu Options

| Key | Action | Description |
| :--- | :--- | :--- |
| `[-1]` | **Discard All Changes** | Safe rollback using `git restore .` and `git clean -fd` (requires typing `DISCARD`). |
| `[ 0 ]` | **Status Dashboard** | Live branch detection, remote URL, dirty files count, and recent commits. |
| `[ 1 ]` | **Reflog Recovery** | Browse recent reflogs and checkout detached commits for recovery. |
| `[ 2 ]` | **Commit** | Staging selection and interactive commit creation. |
| `[ 3 ]` | **Push** | Push active branch with upstream tracking (`--set-upstream origin`). |
| `[ 4 ]` | **Pull / Sync** | Smart linear synchronization using `git pull --rebase`. |
| `[ 11]` | **Submodule Hub** | Add, sync, or remove submodules. |
| `[ t ]` | **Target Directory** | Switch target repository without leaving the session. |
| `[ q ]` | **Quit** | Exit the Git Manager cleanly. |
