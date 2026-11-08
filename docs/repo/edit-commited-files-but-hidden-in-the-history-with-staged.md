---
title: Committed File Overwrite (Hidden in History with Staged / Working Tree)
tool: edit-commited-files-but-hidden-in-the-history-with-staged.ps1
category: repo & git
runtime: PowerShell 5.1+ / 7+
aliases: [edit-commited-files-but-hidden-in-the-history-with-staged, commit-file-overwrite, historical-commit-amend]
tags: [all-lads-tool, repo, git, amend, fixup, autosquash, history, no-default-enter]
dependencies:
  - "[[skill/docs-same-file-name-script.md|docs-same-file-name-script]]"
  - "[[skill/confirmation-to-proceed-brief-overview-options.md|confirmation-to-proceed-brief-overview-options]]"
  - "[[skill/edit-commited-files-but-hidden-in-the-history-with-staged.md|edit-commited-files-but-hidden-in-the-history-with-staged]]"
  - "[[skill/donot-ngada-ngada-exact-lapangan-variables.md|donot-ngada-ngada-exact-lapangan-variables]]"
  - "[[skill/asci-tree-codeblock-standard-without-branch.md|asci-tree-codeblock-standard-without-branch]]"
---

# `edit-commited-files-but-hidden-in-the-history-with-staged.ps1` — Historical Commit File Overwrite

> [!IMPORTANT]
> **Context**: `repo` | **Executable**: `script/repo/edit-commited-files-but-hidden-in-the-history-with-staged.ps1`  
> **Adapter**: `script/repo/adapter/edit-commited-files-but-hidden-in-the-history-with-staged.psm1`  
> **Canonical Documentation**: `docs/repo/edit-commited-files-but-hidden-in-the-history-with-staged.md` (1:1 Script-to-Docs Parity)  
> **Brief**: `[[brief/v01-03-04_repo-edit-commited-files-but-hidden-in-the-history-with-staged.md|v01-03-04]]`

Replaces files inside an already-committed Git commit (`HEAD` or any historical commit `<commit-sha>`) with current staged, working-tree, or custom-scoped changes **without adding extra "fixup" or "oops" commits in `git log`**, while preserving the original commit timestamp (`CommitDate`) and enforcing a strict **No-Default-Enter** interactive contract.

---

## 1. Command Line Arguments & Lapangan Parameters

Conforming to `[[skill/donot-ngada-ngada-exact-lapangan-variables.md|donot-ngada-ngada-exact-lapangan-variables]]`, the exact parameter block in `script/repo/edit-commited-files-but-hidden-in-the-history-with-staged.ps1` is:

```powershell
param(
    [string]$Repo = "",
    [string]$CommitId = "",
    [int]$Option = 0,
    [string]$CustomPath = "",
    [int]$CustomNewFileAction = 0,
    [switch]$Yes
)
```

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-Repo` | `string` | `""` | Optional target Git repository path. When omitted, Step 1 prompts interactively (No Default Enter). |
| `-CommitId` | `string` | `""` | Optional target commit SHA, `HEAD`, or 1-based commit index. When omitted, Step 2 prompts interactively (No Default Enter). |
| `-Option` | `int` | `0` | Optional overwrite mode (`1`, `2`, `3`, `4`, or `5`). When `0` or omitted, Step 3 prompts interactively (No Default Enter). |
| `-CustomPath` | `string` | `""` | Optional custom path (relative to repo or full path from drive root) when `-Option 5` is used. |
| `-CustomNewFileAction` | `int` | `0` | Optional sub-choice (`1` = `all`, `2` = `modified only`, `3` = `cancel`) when new/untracked files are detected in `-Option 5`. |
| `-Yes` | `switch` | `$false` | Optional non-interactive confirmation bypass for scripted automation. When omitted, Step 4 requires typing `yes` explicitly. |

---

## 2. The 5 File Overwrite Options (`Opsi 1..5`)

When prompted for `opsi`, the operator must explicitly select `1`, `2`, `3`, `4`, or `5` (empty `Enter` is rejected):

| Opsi | Scope Source | File State Filter | Exact Git Resolution & Overwrite Behavior |
| :--- | :--- | :--- | :--- |
| **`1`** | **Staged Files Only** (`Index`) | **`modified` (`M` only)** | Queries `git diff --cached --name-status` and filters strictly to `M` (Modified existing files). Temporarily isolates any non-`M` staged files (`A`/`D`/`R`), overwrites only the staged `M` files into `<commit id>`, and re-stages the excluded files afterward. |
| **`2`** | **Staged Files Only** (`Index`) | **`all` (`M`, `A`, `D`, `R`, `C`)** | Queries `git diff --cached --name-status` across all staged states and overwrites the entire staged index into `<commit id>`, leaving unstaged working-tree edits untouched. |
| **`3`** | **All Files** (`Staged + Working Tree`) | **`modified` (`M` only)** | Queries both `git diff --cached --name-status` and `git diff --name-status` for tracked `M` (Modified) files, stages only those `M` files, and overwrites them into `<commit id>`. Untracked (`??`), added (`A`), and deleted (`D`) files remain untouched. |
| **`4`** | **All Files** (`Staged + Working Tree`) | **`all` (`M`, `A`, `D`, `R`, `??`)** | Stages all tracked and untracked files (`git add -A`) and absorbs the entire repository state into `<commit id>`. |
| **`5`** | **Custom Path** (`Relative` or `Drive Root`) | **Folder Scope (`path/subfolder`) or Exact File (`path/subfolder/file.md`)** | Accepts either a repo-relative path or full path from the drive root. If the path is a directory (`path/subfolder`), scopes to that folder; if the path is a file (`path/subfolder/file.md`), scopes strictly to that single file. If any new file (`??` or `A`) is detected inside the scope, prompts: **`1. all`**, **`2. modified only`**, or **`3. cancel`**. |

---

## 3. Interactive Flow (Strict No Default Enter)

```text
+--------------------------------------------------------------------------------+
|  STEP 1: SELECT TARGET GIT REPOSITORY (No Default Enter)                       |
|  - Discovers workspace Git repositories [1..N] or accepts custom path          |
|  - Rejects empty Enter keystrokes                                              |
+--------------------------------------------------------------------------------+
                                        |
                                        v
+--------------------------------------------------------------------------------+
|  STEP 2: SELECT TARGET COMMIT ID (No Default Enter)                            |
|  - Displays recent 15 commits [1..15] with ShortHash, Date, and Subject        |
|  - Accepts 1-based list number or raw commit SHA / HEAD                        |
|  - Rejects empty Enter keystrokes                                              |
+--------------------------------------------------------------------------------+
                                        |
                                        v
+--------------------------------------------------------------------------------+
|  STEP 3: SELECT OPSI [1 / 2 / 3 / 4 / 5] (No Default Enter)                    |
|  [ 1 ] Overwrite staged files | type state: modified   (N matching file(s))    |
|  [ 2 ] Overwrite staged files | type state: all        (N matching file(s))    |
|  [ 3 ] Overwrite all files    | type state: modified   (N matching file(s))    |
|  [ 4 ] Overwrite all files    | type state: all        (N matching file(s))    |
|  [ 5 ] Custom path            | relative or drive root (folder or exact file)  |
+--------------------------------------------------------------------------------+
                                        |
                                        v  (If Opsi 5 Selected)
+--------------------------------------------------------------------------------+
|  STEP 3B: CUSTOM PATH & NEW-FILE DETECTION GATE (No Default Enter)             |
|  - Input: 'path/subfolder' (Folder Scope) or 'path/subfolder/file.md' (Exact)  |
|  - If new file(s) (?? / A) detected in scope, asks:                            |
|      [ 1 ] all           (include new + modified files in scope)               |
|      [ 2 ] modified only (M only, exclude new files)                           |
|      [ 3 ] cancel        (abort operation)                                     |
+--------------------------------------------------------------------------------+
                                        |
                                        v
+--------------------------------------------------------------------------------+
|  STEP 4: PRE-FLIGHT BRIEFED OVERVIEW & CONFIRMATION ('yes' Required)           |
|  - Displays Repository, Branch, Target Commit, Opsi, Strategy, Remote Status,  |
|    Commit Timestamp, and full list of matched files                            |
|  - Requires explicit 'yes' to execute                                          |
+--------------------------------------------------------------------------------+
```

---

## 4. Internal History Rewrite Mechanics (`edit-commited-files-but-hidden-in-the-history-with-staged.psm1`)

1. **Deterministic Safety Backup Ref**:
   - Before touching history, records `refs/backup/commit-overwrite-<yyyyMMdd-HHmmss>` pointing to current `HEAD`.
2. **Case A — Target Commit is `HEAD` (`$TargetCommit.IsHead == $true`)**:
   - Reads the target commit's original committer timestamp (`%cI`) and sets `$env:GIT_COMMITTER_DATE = $TargetCommit.CommitDateIso`.
   - Executes `git commit --amend --no-edit` after isolating the index to the exact target files, updating `HEAD` in place without changing its commit message or committer timestamp.
3. **Case B — Target Commit is Historical (`$TargetCommit.IsHead == $false`)**:
   - Creates a temporary `fixup!` commit targeting `$TargetCommit.FullHash` (`git commit --fixup=<FullHash>`).
   - Executes non-interactive autosquash rebase:
     `git -c sequence.editor=true rebase -i --autosquash --autostash --committer-date-is-author-date <FullHash>~1` (or `--root` if targeting the repository's initial root commit).
   - If a downstream commit conflicts during rebase, automatically aborts (`git rebase --abort`) and resets softly (`git reset --soft $origHead`) so zero changes are lost.

---

## 5. Module Topology (Zero Branches & Zero Tabs)

```text
all-lads-tool                                                                     # Repository root
    brief                                                                         # Architectural briefs
        v01-03-04_repo-edit-commited-files-but-hidden-in-the-history-with-staged.md # Brief v01-03-04 specification
    docs                                                                          # Documentation root (1:1 parity with script/)
        repo                                                                      # Repo context documentation
            edit-commited-files-but-hidden-in-the-history-with-staged.md          # 1:1 documentation for commit file overwrite
    script                                                                        # Executable scripts root (zero markdown allowed)
        repo                                                                      # Repo context executables
            edit-commited-files-but-hidden-in-the-history-with-staged.ps1         # Main CLI entry point (No Default Enter)
            adapter                                                               # Modular PowerShell adapter engines
                edit-commited-files-but-hidden-in-the-history-with-staged.psm1    # 5-option file resolver & commit overwrite engine
    skill                                                                         # Reusable architectural & workflow skills
        edit-commited-files-but-hidden-in-the-history-with-staged.md              # Canonical skill specification
```
