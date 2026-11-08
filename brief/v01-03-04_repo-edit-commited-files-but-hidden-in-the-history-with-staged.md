---
title: "repo(): Historical Commit File Overwrite with Staged, Working Tree & Custom Path Matrix"
version: v01-03-04
status: canonical
dependencies:
  - "[[brief/v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md|v01-03-02]]"
  - "[[docs/repo/edit-commited-files-but-hidden-in-the-history-with-staged.md|edit-commited-files-but-hidden-in-the-history-with-staged]]"
  - "[[skill/edit-commited-files-but-hidden-in-the-history-with-staged.md|edit-commited-files-but-hidden-in-the-history-with-staged]]"
  - "[[skill/confirmation-to-proceed-brief-overview-options.md|confirmation-to-proceed-brief-overview-options]]"
  - "[[skill/save-option-as-exact-executor-name-json.md|save-option-as-exact-executor-name-json]]"
  - "[[skill/asci-tree-codeblock-standard-without-branch.md|asci-tree-codeblock-standard-without-branch]]"
---

# Brief v01-03-04: `repo()` Historical Commit File Overwrite (`edit-commited-files-but-hidden-in-the-history-with-staged.ps1`)

## Status
- **Status**: Canonical / Production Feature Specification
- **Version**: v01-03-04
- **Context**: `repo` / `all-lads-tool`
- **Target Executable**: `script/repo/edit-commited-files-but-hidden-in-the-history-with-staged.ps1`
- **Target Adapter**: `script/repo/adapter/edit-commited-files-but-hidden-in-the-history-with-staged.psm1`
- **Target Documentation**: `docs/repo/edit-commited-files-but-hidden-in-the-history-with-staged.md`
- **Target Skill**: `skill/edit-commited-files-but-hidden-in-the-history-with-staged.md`

---

## 1. Architectural Purpose (`repo()`)

Provides a dedicated `repo` tool that replaces files inside an existing commit (`HEAD` or any historical commit `<commit-sha>`) with current staged, working-tree, or custom-scoped changes **without adding extra "fixup" commits to `git log`**, governed by a strict **No-Default-Enter** interactive contract.

---

## 2. Interactive Prompt Specification (Strict No Default Enter)

Every interactive prompt uses `Read-RequiredInput` to reject empty `Enter` keystrokes:

1. **Prompt 1 — `repo`**:
   - Scans workspace directories for valid Git repositories (`[1..N]`) or accepts a custom path.
   - Empty `Enter` is rejected (`No Default Enter`).
2. **Prompt 2 — `commit id`**:
   - Displays the latest `15` commits (`[1..15] <ShortHash> | <Date> | <Subject>`) and marks `(HEAD)`.
   - Accepts either a list index (`1..15`) or a commit SHA / `HEAD`.
   - Empty `Enter` is rejected (`No Default Enter`).
3. **Prompt 3 — `opsi` (`1`, `2`, `3`, `4`, `5`)**:
   - Presents the 5 file overwrite options (`Options 1..4` `2x2` matrix with live file match counts + `Option 5` Custom Path):

| Opsi | Scope | File Type State | Resolution & Overwrite Behavior |
| :--- | :--- | :--- | :--- |
| **`1`** | **Overwrite staged files** | **`modified` (`M` only)** | Filters `git diff --cached --name-status` strictly to `M` (Modified existing files) and overwrites only those files into `<commit id>`, preserving any staged `A`/`D`/`R` and unstaged files. |
| **`2`** | **Overwrite staged files** | **`all` (`M`, `A`, `D`, `R`, `C`)** | Absorbs the entire staged index (`git diff --cached --name-status`) into `<commit id>`, leaving unstaged working-tree edits untouched. |
| **`3`** | **Overwrite all files** | **`modified` (`M` only)** | Collects all tracked `M` (Modified) files across both staged index and working tree, stages only those `M` files, and overwrites them into `<commit id>` while ignoring untracked (`??`), added (`A`), or deleted (`D`) files. |
| **`4`** | **Overwrite all files** | **`all` (`M`, `A`, `D`, `R`, `??`)** | Stages all tracked and untracked files (`git add -A`) and absorbs the complete working tree state into `<commit id>`. |
| **`5`** | **Custom path** | **Folder (`path/subfolder`) or Exact File (`path/subfolder/file.md`)** | Accepts either a repo-relative path or a full drive-root path. Automatically resolves **Folder Scope** (`path/subfolder`) vs. **Exact Single-File Scope** (`path/subfolder/file.md`). |

4. **Prompt 3B — Custom Path & Conditional New-File Sub-Prompt (When `Opsi 5` Selected)**:
   - User enters the custom path (relative or full path from drive root, e.g. `script/repo` or `E:\proj\all-lads-tool\docs\repo\git-manage.md`).
   - **If new/untracked file(s) (`??` or `A`) are detected inside that custom scope**, the script prompts (with **No Default Enter**):
     - **`1. all`**: Include both new (`??`/`A`) and modified (`M`) files inside the custom scope.
     - **`2. modified only`**: Include strictly tracked modified (`M`) files inside the custom scope, excluding new files.
     - **`3. cancel`**: Abort the operation cleanly without modifying commit history.
5. **Prompt 4 — Pre-Flight Briefed Overview (`yes` to proceed)**:
   - Displays the resolved `Repository Path`, `Active Branch`, `Target Commit ID`, `Selected Opsi`, `Rewrite Strategy`, `Commit Timestamp`, `Remote Status`, and the exact list of matched files, requiring an explicit `yes` to execute.

---

## 3. Execution Engine Mechanics (`edit-commited-files-but-hidden-in-the-history-with-staged.psm1`)

- **Pre-Flight Safety Backup Ref**: Records `refs/backup/commit-overwrite-<yyyyMMdd-HHmmss>` pointing to `HEAD` before mutating history.
- **Index Isolation for Scoped Options (`Opsi 1`, `3`, `5`)**: Temporarily unstages any staged files outside the selected target file set, stages the selected target files, performs the commit overwrite, and re-stages the excluded files afterward.
- **Target `HEAD` (`$TargetCommit.IsHead == $true`)**:
  - Preserves original commit timestamp via `$env:GIT_COMMITTER_DATE = $TargetCommit.CommitDateIso` and executes `git commit --amend --no-edit`.
- **Target Historical Commit (`$TargetCommit.IsHead == $false`)**:
  - Creates a temporary `git commit --fixup=<FullHash>` and executes a non-interactive autosquash rebase (`git -c sequence.editor=true rebase -i --autosquash --autostash --committer-date-is-author-date <FullHash>~1`), automatically aborting and restoring state if any downstream conflict occurs.

---

## 4. Clean Indented Module Topology (Zero Branches & Zero Tabs)

```text
all-lads-tool                                                                               # Root repository directory
    brief                                                                                   # Architectural briefs directory
        v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md # 1:1 script-to-docs topology standard
        v01-03-03_UNLOCKING-FILE-SCRIPT-FINALY-WORKING.md                                   # File lock & unlock engine brief
        v01-03-04_repo-edit-commited-files-but-hidden-in-the-history-with-staged.md         # Historical commit file overwrite brief
    docs                                                                                    # Documentation root (1:1 parity with script/)
        repo                                                                                # Repo context documentation
            git-branch-rename.md                                                            # 1:1 doc for git-branch-rename.ps1
            git-manage.md                                                                   # 1:1 doc for git-manage.ps1
            edit-commited-files-but-hidden-in-the-history-with-staged.md                    # 1:1 doc for edit-commited-files-but-hidden-in-the-history-with-staged.ps1
    script                                                                                  # Executable scripts root (zero markdown allowed)
        repo                                                                                # Repo context executables
            git-branch-rename.ps1                                                           # Branch naming & isolation manager
            git-manage.ps1                                                                  # Universal Git manager
            edit-commited-files-but-hidden-in-the-history-with-staged.ps1                   # Historical commit file overwrite CLI (No Default Enter)
            adapter                                                                         # Modular PowerShell adapter engines & state JSON
                v02-30-00.psm1                                                              # Git 2.30+ runtime adapter
                v02-40-00.psm1                                                              # Git 2.40+ runtime adapter
                edit-commited-files-but-hidden-in-the-history-with-staged.psm1              # 5-option file resolver, HEAD amend & autosquash rebase engine
                edit-commited-files-but-hidden-in-the-history-with-staged.json              # 1:1 persisted executor options & history JSON in adapter/
    skill                                                                                   # Reusable architectural & workflow skills
        edit-commited-files-but-hidden-in-the-history-with-staged.md                        # Skill specification for historical commit file overwrite
```

---

## 5. Verification Checklist

- [x] **Strict No-Default-Enter**: All interactive prompts (`repo`, `commit id`, `opsi 1..5`, custom path, new-file sub-prompt, `yes` confirmation) reject empty `Enter` inputs.
- [x] **5 File Overwrite Options**: Supports `Staged | modified` (`1`), `Staged | all` (`2`), `All | modified` (`3`), `All | all` (`4`), and `Custom path` (`5`) with folder (`path/subfolder`) vs. exact file (`path/subfolder/file.md`) detection and `1. all` / `2. modified only` / `3. cancel` new-file gate.
- [x] **Zero Branches & Zero Tabs**: Topology codeblock uses pure space alignment with `#` aligned to `longest_line + 1 space`.
- [x] **1:1 Script-to-Docs Parity**: Zero `.md` files inside `script/repo/`; exact matching documentation at `docs/repo/edit-commited-files-but-hidden-in-the-history-with-staged.md`.
