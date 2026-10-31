---
title: Git Commit Renamer
tool: git-rename-commit.ps1
category: git & versioning
runtime: PowerShell 7+ / 5.1
aliases: [git-rename-commit, git-commit-renamer, commit-renamer]
tags: [all-lads-tool, powershell, git, commit, reword, github, gitlab]
---

# `git-rename-commit.ps1` — Git Commit Renamer

> [!INFO]
> **Runtime**: PowerShell 7+ / Windows PowerShell 5.1 | **Directory**: `all-lads-tool/script/powershell/`  
> **Architecture**: Dual-Layer Edition (Standalone `git-rename-commit_stand.ps1` vs Modular `git-rename-commit.ps1`)  
> **Remote Providers**: Detects GitHub, GitLab, and custom git remotes; synchronizes via `--force-with-lease`.

Safely renames commit messages locally (HEAD or historical commits) using native Git plumbing, and synchronizes the rewritten lineage with remote providers (GitHub, GitLab).

---

## 1. Quick Syntax & Usage

```powershell
# 1. Interactive Mode: Select from recent commit list and rename
.\all-lads-tool\script\powershell\git-rename-commit_stand.ps1

# 2. Rename specific commit non-interactively
.\all-lads-tool\script\powershell\git-rename-commit.ps1 -CommitHash "a1b2c3d" -NewMessage "feat: new clean message"

# 3. Rename and push directly to GitHub / GitLab
.\all-lads-tool\script\powershell\git-rename-commit.ps1 -CommitHash "HEAD" -NewMessage "fix: update syntax" -PushRemote
```

---

## 2. Key Capabilities

1. **Plumbing-Level Rewriting**:
   Uses native `git commit-tree` and `git update-ref` operations instead of fragile interactive rebasing, preventing editor popup hangs and MSYS2 subshell errors on Windows.

2. **Historical & HEAD Support**:
   Renames HEAD instantly via `commit --amend`, or replays child commits automatically when renaming an earlier commit in branch history.

3. **Remote Provider Detection**:
   Inspects `git remote -v` and identifies whether the upstream repository is hosted on **GitHub**, **GitLab**, or a self-hosted Git server.

4. **Safe Force Push with Lease**:
   Synchronizes remote branches using `git push --force-with-lease <remote> <branch>`, ensuring you do not overwrite unseen upstream commits made by collaborators.

---

## 3. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-TargetDir` | string | No | Current Directory | Target Git repository folder. |
| `-CommitHash` | string | No | Prompt | Commit hash or index to rename. |
| `-NewMessage` | string | No | Prompt | New commit message text. |
| `-PushRemote` | switch | No | `false` | Pushes rewritten commit history to remote using `--force-with-lease`. |

---

## 4. Dual-Layer Implementation

* **Standalone Runner**: [`script/powershell/git-rename-commit_stand.ps1`](../../script/powershell/git-rename-commit_stand.ps1) (Zero-dependency inlined executable)
* **Modular Runner**: [`script/powershell/git-rename-commit.ps1`](../../script/powershell/git-rename-commit.ps1) (Connected to `module/git-commitrenamer.psm1`)
* **Underlying Engine**: [`script/powershell/module/git-commitrenamer.psm1`](../../script/powershell/module/git-commitrenamer.psm1)
