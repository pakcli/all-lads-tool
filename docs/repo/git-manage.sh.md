---
title: Git Bash Universal Git Manager
tool: git-manage.sh
category: repo
runtime: Git Bash / POSIX Bash
aliases: [gitbash-manage-git, gitbash-git-manager]
tags: [all-lads-tool, repo, gitbash, bash, git, submodule, reflog, worktree, clone, modular]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
---

# `git-manage.sh` - Universal Git Manager (Git Bash Edition)

> [!INFO]
> **Runtime**: Git Bash / POSIX Bash | **Directory**: `script/repo/`  
> **Architecture**: Modular Edition (Connected to `script/repo/adapter/*.sh`).  
> **Status Invariant**: Uncommitted quarantine strictly enforced under `donot-commit-yet`.

Interactive terminal cockpit for Git repository operations, reflog commit recovery, branch synchronization, worktree workflows, and submodule management directly inside Git Bash or POSIX terminal environments.

---

## 1. Quick Syntax & Usage

```bash
# Launch interactive Git Bash cockpit in current repository
bash script/repo/git-manage.sh

# Launch targeting a specific repository path
bash script/repo/git-manage.sh /e/proj/my-repo
```

---

## 2. Command Matrix (-1 to 9, 11 & Footer)

| Key | Action | Description | Safety Level |
| :--- | :--- | :--- | :--- |
| `[-1]` | **Discard All Changes** | Safe rollback using `git restore .` and `git clean -fd` (requires typing `DISCARD`). | Protected |
| `[ 0 ]` | **Status Dashboard** | Live branch detection, remote URL, dirty files count, and recent commits. | Read-Only |
| `[ 1 ]` | **Reflog Recovery** | Browse recent reflogs and checkout detached commits for recovery. | Non-destructive |
| `[ 2 ]` | **Commit** | Staging selection and interactive commit creation. | Standard |
| `[ 3 ]` | **Push** | Push active branch with upstream tracking (`--set-upstream origin`). | Standard |
| `[ 4 ]` | **Pull / Sync** | Smart linear synchronization using `git pull --rebase`. | Standard |
| `[ 5 ]` | **Assign Git** | Initializes Git repo, sets remote origin, provisions `.gitignore`, initial commit. | Safe |
| `[ 6 ]` | **Remove Git** | Clean unlinking of `.git` folder with permissions unlock and confirmation. | Protected |
| `[ 7 ]` | **Clone** | Clones external repo into designated target directory with shallow depth option. | Standard |
| `[ 8 ]` | **Worktree** | Manages isolated worktree branches (`list`, `add`, `remove`, `prune`). | Safe |
| `[ 9 ]` | **Custom Shell** | Runs arbitrary commands inside target repository directory. | Standard |
| `[ 11]` | **Submodule Hub** | Add, sync, or remove submodules using modular adapter. | Standard |
| `[ h ]` | **Help** | Displays complete operational instructions and shortcuts. | Read-Only |
| `[ t ]` | **Target Directory** | Switch target repository without leaving the session. | Interactive |
| `[ q ]` | **Quit** | Exit the Git Manager cleanly. | Read-Only |

---

## 3. Implementation Sources

- **Runner**: [`script/repo/git-manage.sh`](../../script/repo/git-manage.sh)
- **Adapters**:
  - [`script/repo/adapter/git-core.sh`](../../script/repo/adapter/git-core.sh)
  - [`script/repo/adapter/git-status.sh`](../../script/repo/adapter/git-status.sh)
  - [`script/repo/adapter/git-reflog.sh`](../../script/repo/adapter/git-reflog.sh)
  - [`script/repo/adapter/git-submodule.sh`](../../script/repo/adapter/git-submodule.sh)
  - [`script/repo/adapter/history.sh`](../../script/repo/adapter/history.sh)
