---
name: edit-commited-files-but-hidden-in-the-history-with-staged
aliases: [commit-file-overwrite, historical-git-amend-rebase, overwrite-committed-files-hidden-in-history]
category: REPO_WORKFLOW_STANDARD
tags: [all-lads-tool, skill, repo, git, amend, fixup, autosquash, staged, modified, custom-path, no-default-enter]
description: Interactive Git commit file overwrite standard that replaces files inside an existing commit (HEAD or historical SHA) using 5 options (Options 1..4 2x2 matrix + Option 5 Custom Path with folder/file detection and new-file sub-prompt) with strict No-Default-Enter prompts, original commit date preservation, and Pre-Flight Briefed Overview confirmation.
dependencies:
  - "[[docs-same-file-name-script]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[asci-tree-codeblock-standard-without-branch]]"
  - "[[brief-content-codeblock-diff-and-explaining-how-is-the-fix]]"
  - "[[donot-ngada-ngada-exact-lapangan-variables]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[git-clone-briefed-overview]]"
pros:
  - "Eliminates noisy 'fix typo / forgot file' commits by absorbing changes directly into the target commit"
  - "Provides orthogonal 2x2 file scope control (Opsi 1..4) plus Opsi 5 Custom Path (folder scope or exact file with new-file sub-prompt)"
  - "Enforces strict No-Default-Enter across repo, commit id, opsi, custom path, and confirmation prompts to prevent accidental history rewrites"
  - "Preserves original CommitDate and creates a deterministic refs/backup/commit-overwrite-* rollback ref"
cons:
  - "Rewriting commits that have already been pushed to a remote branch requires 'git push --force-with-lease'"
---

# Historical Commit File Overwrite Standard (`edit-commited-files-but-hidden-in-the-history-with-staged`)

> [!IMPORTANT]
> **THE 5 CARDINAL INVARIANTS OF HISTORICAL COMMIT FILE OVERWRITE**:
> 1. **Strict Zero-Default-Enter (`Read-RequiredInput`)**: Every interactive prompt (`repo`, `commit id`, `opsi 1..5`, custom path, new-file sub-prompt, and `yes` confirmation) rejects empty `Enter` keystrokes and loops until an explicit value is entered.
> 2. **2x2 Scope & State Matrix (`Opsi 1..4`)**: Supports precise selection between **Staged Files (`Index`)** vs. **All Files (`Index + Working Tree`)** crossed with **Modified Only (`M`)** vs. **All States (`M/A/D/R/??`)**.
> 3. **Custom Path Scope (`Opsi 5`)**: Accepts either a repo-relative path or a full drive-root path. Automatically detects **Folder Scope** (`path/subfolder`) vs. **Exact Single-File Scope** (`path/subfolder/file.md`), and if any new file (`??` or `A`) is detected inside the scope, prompts for **`1. all`**, **`2. modified only`**, or **`3. cancel`**.
> 4. **Zero Extra Commit Nodes in `git log`**: Uses index-isolated `git commit --amend --no-edit` when targeting `HEAD`, and `git commit --fixup=<sha>` + non-interactive `git -c sequence.editor=true rebase -i --autosquash --autostash` when targeting an older commit.
> 5. **Original Timestamp Preservation & Rollback Safety**: Preserves original `CommitDate` (`GIT_COMMITTER_DATE` / `--committer-date-is-author-date`) and saves a pre-flight backup ref at `refs/backup/commit-overwrite-<timestamp>`.

---

## 1. The 5 File Overwrite Options (`Opsi 1..5`)

```text
+--------+---------------------------+------------------------+---------------------------------------------------------------+
| OPSI   | TARGET FILE SCOPE         | FILE STATE FILTER      | GIT RESOLUTION & ISOLATION MECHANISM                          |
+--------+---------------------------+------------------------+---------------------------------------------------------------+
| [ 1 ]  | Overwrite staged files    | type state: modified   | git diff --cached --name-status (M only; preserves A/D/R)     |
| [ 2 ]  | Overwrite staged files    | type state: all        | git diff --cached --name-status (All staged M/A/D/R/C)        |
| [ 3 ]  | Overwrite all files       | type state: modified   | Staged + Unstaged tracked M only (ignores untracked ?? & A/D) |
| [ 4 ]  | Overwrite all files       | type state: all        | git status --porcelain=v1 -uall -> git add -A (All states)    |
| [ 5 ]  | Custom path               | Folder or Exact File   | Relative or drive-root path; asks 1.all/2.modified/3.cancel   |
+--------+---------------------------+------------------------+---------------------------------------------------------------+
```

---

## 2. Interactive Prompt Sequence (No Default Enter)

1. **`repo`**:
   - Lists discovered workspace Git repositories `[1..N]` or accepts a full directory path.
   - Rejects empty `Enter`.
2. **`commit id`**:
   - Lists the last `15` commits (`[1..15] <ShortHash> | <Date> | <Subject>`) and marks `(HEAD)`.
   - Accepts either a list index (`1..15`) or any valid commit SHA / ref.
   - Rejects empty `Enter`.
3. **`opsi` (`1`, `2`, `3`, `4`, `5`)**:
   - Displays Options `1..4` with live matching file counts, plus Option `5` (`Custom path`).
   - If Option `5` is chosen:
     - Prompts for custom path (relative or drive root):
       - If `path/subfolder` -> **Folder Scope**
       - If `path/subfolder/file.md` -> **Exact Single-File Scope**
     - If new/untracked file(s) (`??` or `A`) are detected inside that scope, prompts:
       - `1. all`
       - `2. modified only`
       - `3. cancel`
4. **Pre-Flight Briefed Overview (`yes` to proceed)**:
   - Renders the full summary card (`Repository Path`, `Active Branch`, `Target Commit ID`, `Selected Opsi`, `Rewrite Strategy`, `Commit Timestamp`, `Remote Status`, and `Files To Overwrite`) and requires typing `yes` explicitly.

---

## 3. Canonical Implementation Reference

- **Executable Script**: `[[script/repo/edit-commited-files-but-hidden-in-the-history-with-staged.ps1|edit-commited-files-but-hidden-in-the-history-with-staged.ps1]]`
- **Adapter Module**: `[[script/repo/adapter/edit-commited-files-but-hidden-in-the-history-with-staged.psm1|edit-commited-files-but-hidden-in-the-history-with-staged.psm1]]`
- **Documentation**: `[[docs/repo/edit-commited-files-but-hidden-in-the-history-with-staged.md|edit-commited-files-but-hidden-in-the-history-with-staged.md]]`
- **Architectural Brief**: `[[brief/v01-03-04_repo-edit-commited-files-but-hidden-in-the-history-with-staged.md|v01-03-04]]`

---

## 4. Verification Checklist

- [x] **No Default Enter**: Pressing `Enter` on an empty line at `repo`, `commit id`, `opsi`, custom path, or confirmation re-prompts without executing.
- [x] **Option 1 (`Staged + Modified`)**: Overwrites only staged `M` files into `<commit id>` while preserving staged `A`/`D` and unstaged files.
- [x] **Option 2 (`Staged + All`)**: Overwrites all staged files (`M/A/D/R`) into `<commit id>` while preserving unstaged files.
- [x] **Option 3 (`All + Modified`)**: Overwrites all tracked `M` files (staged + unstaged) into `<commit id>` while ignoring untracked (`??`) files.
- [x] **Option 4 (`All + All`)**: Stages and overwrites all repository changes (`M/A/D/R/??`) into `<commit id>`.
- [x] **Option 5 (`Custom Path`)**: Resolves relative or drive-root path into Folder Scope (`path/subfolder`) or Exact File Scope (`path/subfolder/file.md`), and asks `1. all` / `2. modified only` / `3. cancel` when new files are detected.
- [x] **1:1 Script-to-Docs Parity**: Zero markdown in `script/repo/`, exact matching doc at `docs/repo/edit-commited-files-but-hidden-in-the-history-with-staged.md`.
