---
title: Git Lost & Detached Commit Recovery Wrapper
tool: ps_recover.ps1
category: git & versioning
runtime: PowerShell 7+
aliases: [ps_recover, git-recover, reflog-recovery]
tags: [all-lads-tool, powershell, git, recovery, reflog]
---

# 🛠️ `ps_recover.ps1` — Git Lost & Detached Commit Recovery Wrapper

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Dedicated, streamlined wrapper for instant Git reflog recovery, orphaned commit hunting, and surgical working-tree file restoration (powered by `ps_git-manage.ps1` engine).

---

## 1. Quick Syntax & Usage

```powershell
# Recover orphaned or lost commits in repository root
.\all-lads-tool\script\powershell\ps_recover.ps1

# Target a specific cartridge or subfolder
.\all-lads-tool\script\powershell\ps_recover.ps1 -TargetDir "apps/radiansincostan"
```

---

## 2. Recovery Workflow

1. Scans `git reflog` for recent commit SHAs including unreachable/detached commits.
2. Presents an interactive list with zero-indexed numbers (`0` = latest, `1` = prior to latest).
3. Allows inspection of modified files before restoring.
4. Performs surgical or full restoration to the active working tree without data loss.

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/ps_recover.ps1`](../../script/powershell/ps_recover.ps1)
* **Engine Dependency**: [`all-lads-tool/script/powershell/ps_git-manage.ps1`](../../script/powershell/ps_git-manage.ps1)
