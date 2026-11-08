---
title: Git Checkpoint Rollback & Safe Reset
tool: git-checkpoint-rollback.ps1
category: repo & git
runtime: PowerShell 5.1+ / 7+
aliases: [checkpoint-rollback, git-rollback, safe-rollback]
tags: [all-lads-tool, repo, git, rollback, soft-reset, checkpoint, options]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
---

# `git-checkpoint-rollback.ps1` - Git Checkpoint Rollback & Safe Reset (Keep Local Work)

> [!INFO]
> **Context**: `repo` | **Executable**: `script/repo/git-checkpoint-rollback.ps1`  
> **Adapter**: `script/repo/adapter/git-rollback.psm1`, `script/repo/adapter/git-status.psm1`  
> **Canonical Documentation**: `docs/repo/git-checkpoint-rollback.md` (Matches script filename 1:1)

Interactive Git history rewind and checkpoint recovery engine. Rolls back local commit history to a chosen previous commit using `git reset --soft`, guaranteeing that **100% of your working code is kept safe in the Git Staging Area (index)** rather than deleted. Offers optional remote synchronization with `--force-with-lease`.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive mode (prompts for target repo and commit checkpoint)
.\all-lads-tool\script\repo\git-checkpoint-rollback.ps1

# Specify target repository directly
.\all-lads-tool\script\repo\git-checkpoint-rollback.ps1 -TargetDir "e:\proj\my-project"

# Headless non-interactive rewind to commit #2 with remote sync
.\all-lads-tool\script\repo\git-checkpoint-rollback.ps1 -TargetDir "e:\proj\my-project" -TargetCommit "2" -ForcePush
```

---

## 2. Interactive Workflow & Features

1. **Target Repository Resolution**:
   - Reads `-TargetDir` parameter, saved target in `_run.json`, or queries the active workspace.
2. **Timeline Inspector**:
   - Pretty-prints recent 10 commits with index numbers `[1..10]`.
   - Distinctively highlights `[ 1 ] (HEAD Saat Ini)` and previous commit checkpoints with author and relative time.
3. **Target Checkpoint Selector**:
   - Accepts list number (`1..10`) or direct commit hash (short or full).
   - Validates commit existence and computes diff count (`git rev-list --count <target>..HEAD`).
4. **Pre-flight Briefed Overview Card**:
   - Displays target directory, active branch, target commit hash & subject, count of stripped commits, and local code safety assurance.
5. **Safe Soft Rollback**:
   - Runs `git reset --soft <target-hash>`.
   - Your local changes from unwound commits remain staged in the Git index, ready for inspection via `git status` or re-committing.
6. **Remote Synchronization (Optional)**:
   - Prompts whether to align the upstream tracking remote using `git push --force-with-lease origin <branch>`.

---

## 3. Pre-Flight Briefed Overview Example

```text
==========================================================
   GIT CHECKPOINT ROLLBACK PRE-FLIGHT OVERVIEW
==========================================================
 Target Repo      : E:\proj\web-app_catalog-style-retro_GITHUB
 Branch Aktif     : main
 Mundur ke Commit : a3b4c5d ("feat: initial scaffolding")
 Commit Dicopot   : 2 commit terbaru dari history
 Kodingan Lokal   : 100% AMAN (masuk ke Staging Area via reset --soft)
 Perintah Git     : git reset --soft a3b4c5d
==========================================================

Lanjutkan proses mundur ini? (y/N):
```

---

## 4. Implementation Sources

- **Runner**: [`script/repo/git-checkpoint-rollback.ps1`](../../script/repo/git-checkpoint-rollback.ps1)
- **Adapter**: [`script/repo/adapter/git-rollback.psm1`](../../script/repo/adapter/git-rollback.psm1)
- **Git Bash Companion**: [`script/repo/git-checkpoint-rollback.sh`](../../script/repo/git-checkpoint-rollback.sh)
