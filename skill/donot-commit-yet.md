---
name: donot-commit-yet
aliases: [donot-commit-yet, do-not-commit-yet, uncommitted-quarantine, no-commit-protocol]
category: WORKFLOW_PROTOCOL
tags: [all-lads-tool, git, workflow, safety, quarantine, pre-commit]
description: Strict pre-commit quarantine protocol requiring all file changes, submodule integrations, configuration updates, and dependency imports to remain uncommitted in the working tree until explicitly approved by the user.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Do Not Commit Yet Protocol (`donot-commit-yet`)

> [!CAUTION]
> **ABSOLUTE INVARIANT**:
> **NEVER execute `git commit` or chain `&& git commit` into commands** unless the user explicitly commands: *"commit this now"*, providing or confirming the exact commit message.
> Every change, file addition, submodule integration, module import, or refactoring **MUST REMAIN IN THE WORKING TREE / STAGING AREA**.

---

## 1. Core Mandate: The Working-Tree Quarantine

Whenever an agent or developer performs work across the codebase:
1. **Zero Premature Commits**: All edits, new files, deleted files, and submodule additions must sit safely in the uncommitted state (`Working Tree` or `Staged`).
2. **User Sovereign Greenlight**: The user has sole authority to inspect the diff, verify desktop/terminal behavior, test the outputs, and decide *when* and *what* to commit.
3. **No Hidden Commits**: Submodule commands, installation scripts, and helper functions must **NEVER** run commit commands in the background or automatically append commit flags (`-a`, `--amend`, `commit -m`).

---

## 2. Forbidden vs Mandatory Command Patterns

| Context | ❌ FORBIDDEN (Premature Auto-Commit) | ✅ MANDATORY (Quarantine / Uncommitted) |
| :--- | :--- | :--- |
| **Submodule Addition** | `git submodule add <url> <path> && git commit -m ...` | `git submodule add <url> <path> && git submodule update --init --recursive` |
| **Submodule Update** | `git submodule update --remote && git commit -am ...` | `git submodule update --remote --merge <submodule>` |
| **File Editing / Refactor** | Running `git commit -m "feat: ..."` right after editing | Leave files modified in working tree; verify with `git status` |
| **Documentation / Runbook** | Instructing readers to commit immediately | Instruct readers to inspect changes first; leave commit optional |
| **Batch Clean / Deinit** | `git rm <path> && git commit -m ...` | `git submodule deinit -f -- <path> && git rm -f <path>` |

---

## 3. Operational Protocol for AI Agents & Developers

### Step 1: Execute Changes in Working Tree
Make all required code changes, file creations, module inlinings, or configuration edits freely.

### Step 2: Stage or Leave Unstaged
Files can be staged (`git add`) for clarity or kept unstaged, but the commit boundary must **NEVER** be crossed.

### Step 3: Run Non-Destructive Verification
Verify that the workspace is in the expected state using read-only inspection:
```powershell
# Check modified & untracked files
git status -s

# Review exact diffs
git diff

# Verify syntax without modifying history
powershell -Command "[scriptblock]::Create((Get-Content '<script>' -Raw)) | Out-Null; Write-Host 'Syntax OK'"
```

### Step 4: Present Review to User
Report the work completed, point out which files were modified/created, and state clearly:
> *"Semua perubahan tersimpan di working tree / staging. Siap untuk Anda periksa dan review sebelum dicommit."*

---

## 4. Why This Invariant is Critical

1. **Prevents Polluted History**: Avoids micro-commits, typo-fix commits, or broken half-baked states in git history.
2. **Zero Detached HEAD Hazards**: Prevents accidental commits made in detached HEAD states inside submodules.
3. **Facilitates Clean Reverts**: If a direction is canceled, `git restore` or `git checkout` can revert changes instantly with zero reflog surgery.
4. **Human-in-the-Loop Verification**: Guarantees that the human architect always reviews visual layouts, test outputs, and diffs before anything enters project lineage.
