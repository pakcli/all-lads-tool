---
title: Git Sync From Directory
tool: git-sync-from-dir.ps1
category: repo
runtime: PowerShell 5.1 / 7+
aliases: [git-sync-from-dir, repo-sync-dir]
tags: [all-lads-tool, repo, powershell, git, sync, robocopy]
---

# `git-sync-from-dir.ps1` - Git Sync From Directory

> [!INFO]
> **Runtime**: PowerShell 5.1 / 7+ | **Directory**: `script/repo/`  
> **Protection**: Never mutates `.git/` metadata or repository commit history.

Overwrites repository files in target repository A with contents from source directory B using Robocopy, while strictly preserving `.git` metadata, remote configs, and branch history.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive mode (prompts for Target Repo A and Source Dir B)
.\script\repo\git-sync-from-dir.ps1

# Direct execution with prompt confirmation
.\script\repo\git-sync-from-dir.ps1 -TargetRepo "E:\proj\repoA" -SourceDir "E:\backup\code"

# Unattended execution bypass
.\script\repo\git-sync-from-dir.ps1 -TargetRepo "E:\proj\repoA" -SourceDir "E:\backup\code" -Yes
```

---

## 2. Key Safeguards

1. **`.git` Absolute Quarantine**:
   - Robocopy excludes `.git` directories and files at every nested level (`/XD .git /XF .git`). Target repo A's commit lineage, branch pointers, and remote identity are 100% untouched.
2. **Pre-Flight Preview (`/L`)**:
   - Executes a simulated dry-run listing differences before asking for confirmation.
3. **No Phantom Deletions**:
   - Files existing solely in A are not removed unless explicitly purged.

---

## 3. Implementation Sources

* **Runner**: [`script/repo/git-sync-from-dir.ps1`](../../script/repo/git-sync-from-dir.ps1)
