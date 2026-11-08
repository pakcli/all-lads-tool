---
title: Git Bash Universal Git Manager
tool: git-manage.sh
category: repo
runtime: Git Bash / POSIX Bash
aliases: [gitbash-manage-git, gitbash-git-manager]
tags: [all-lads-tool, repo, gitbash, bash, git, submodule, reflog, modular]
---

# `git-manage.sh` - Universal Git Manager (Git Bash Edition)

> [!INFO]
> **Runtime**: Git Bash / POSIX Bash | **Directory**: `script/repo/`  
> **Architecture**: Modular Edition (Connected to `script/repo/adapter/*.sh`).  
> **Status Invariant**: Uncommitted quarantine strictly enforced under `donot-commit-yet`.

Interactive terminal cockpit for Git repository operations, reflog commit recovery, branch synchronization, and submodule management directly inside Git Bash or Linux/macOS environments.

---

## 1. Quick Syntax & Usage

```bash
# Launch interactive Git Bash cockpit in current repository
bash script/repo/git-manage.sh

# Launch targeting a specific repository path
bash script/repo/git-manage.sh /e/proj/my-repo
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

---

## 3. Implementation Sources

- **Runner**: [`script/repo/git-manage.sh`](../../script/repo/git-manage.sh)
- **Adapters**:
  - [`script/repo/adapter/git-core.sh`](../../script/repo/adapter/git-core.sh)
  - [`script/repo/adapter/git-status.sh`](../../script/repo/adapter/git-status.sh)
  - [`script/repo/adapter/git-reflog.sh`](../../script/repo/adapter/git-reflog.sh)
  - [`script/repo/adapter/git-submodule.sh`](../../script/repo/adapter/git-submodule.sh)
  - [`script/repo/adapter/history.sh`](../../script/repo/adapter/history.sh)
