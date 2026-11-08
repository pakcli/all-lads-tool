---
title: Git Bash Checkpoint Rollback & Safe Reset
tool: git-checkpoint-rollback.sh
category: repo
runtime: Git Bash / POSIX Bash
aliases: [gitbash-checkpoint-rollback, gitbash-git-rollback]
tags: [all-lads-tool, repo, gitbash, bash, git, rollback, soft-reset, checkpoint]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
---

# `git-checkpoint-rollback.sh` - Git Checkpoint Rollback (Git Bash Edition)

> [!INFO]
> **Runtime**: Git Bash / POSIX Bash | **Directory**: `script/repo/`  
> **Adapter**: `script/repo/adapter/git-rollback.sh`  
> **Canonical Documentation**: `docs/repo/git-checkpoint-rollback.sh.md` (Matches script filename 1:1)

Interactive Git Bash cockpit to roll back commit history to a specified checkpoint using `git reset --soft`, keeping all local changes safely in the staging area.

---

## 1. Quick Syntax & Usage

```bash
# Launch interactive rollback in active repo
bash script/repo/git-checkpoint-rollback.sh

# Launch targeting a specific directory
bash script/repo/git-checkpoint-rollback.sh /e/proj/my-project
```

---

## 2. Implementation Sources

- **Runner**: [`script/repo/git-checkpoint-rollback.sh`](../../script/repo/git-checkpoint-rollback.sh)
- **Adapter**: [`script/repo/adapter/git-rollback.sh`](../../script/repo/adapter/git-rollback.sh)
- **PowerShell Companion**: [`script/repo/git-checkpoint-rollback.ps1`](../../script/repo/git-checkpoint-rollback.ps1)
