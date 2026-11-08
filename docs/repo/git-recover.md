---
title: Git Lost & Detached Commit Recovery
tool: git-recover.ps1
category: repo
runtime: PowerShell 5.1 / 7+
aliases: [git-recover, reflog-recovery]
tags: [all-lads-tool, repo, powershell, git, recovery, reflog]
---

# `git-recover.ps1` - Git Lost & Detached Commit Recovery

> [!INFO]
> **Runtime**: PowerShell 5.1 / 7+ | **Directory**: `script/repo/`  
> **Architecture**: Modular Edition (Connected to `adapter/git-reflog.psm1`).

Dedicated tool for Git reflog timeline inspection, orphaned and detached commit discovery, and surgical working-tree file restoration.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive recovery in current repository
.\script\repo\git-recover.ps1

# Target a specific repository path
.\script\repo\git-recover.ps1 -TargetDir "path/to/repo"

# Inspect and recover a specific commit SHA directly
.\script\repo\git-recover.ps1 -CommitHash "a1b2c3d"
```

---

## 2. Recovery Workflow

1. Scans `git reflog` for recent commit SHAs including unreachable/detached commits.
2. Presents an interactive list with zero-indexed numbers (`0` = latest, `1` = prior to latest).
3. Allows inspection of modified files before restoring.
4. Performs surgical file restoration, detached checkout, or creates a new recovery branch without data loss.

---

## 3. Implementation Sources
* **Runner**: [`script/repo/git-recover.ps1`](../../script/repo/git-recover.ps1)
* **Adapter Engine**: [`script/repo/adapter/git-reflog.psm1`](../../script/repo/adapter/git-reflog.psm1)
