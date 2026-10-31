# Technical Specification: Git Branch Renamer (`git-branch-rename.ps1`)

## 📑 Table of Contents
- [1. Overview](#1-overview)
- [2. File Location & Dependencies](#2-file-location--dependencies)
- [3. Parameters](#3-parameters)
- [4. Execution Flow](#4-execution-flow)
- [5. Usage Examples](#5-usage-examples)
- [6. Error Handling & Invariants](#6-error-handling--invariants)

---

## 1. Overview
`git-branch-rename.ps1` provides an interactive, direct mechanism to rename an active local branch and publish the newly named branch directly to the configured remote repository (`origin`).

## 2. File Location & Dependencies
- **Script Path**: `all-lads-tool/script/powershell/git-branch-rename.ps1`
- **Dependencies**:
  - `all-lads-tool/script/powershell/module/git-core.psm1`
  - `all-lads-tool/script/powershell/module/git-status.psm1`

## 3. Parameters
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `TargetDir` | `[string]` | Repository root | Target Git repository directory. |
| `NewBranch` | `[string]` | Prompted | Desired target branch name. |
| `Remote` | `[string]` | `"origin"` | Target remote name. |

## 4. Execution Flow
1. **Target Inspection**: Validates whether the target path contains a valid `.git` repository and confirms the active branch name.
2. **Name Resolution**: Prompts for the new branch name if omitted as an argument.
3. **Dry-Run Confirmation**: Displays planned commands (`git branch -m` followed by `git push -u origin <new_branch>`) and requests user confirmation via `(Y/n)`.
4. **Local Execution**: Executes `git branch -m <old_branch> <new_branch>`.
5. **Remote Push**: Executes `git push -u <remote> <new_branch>`.

## 5. Usage Examples

```powershell
# Interactive run targeting the repository root
.\all-lads-tool\script\powershell\git-branch-rename.ps1

# Direct execution targeting specific submodule
.\all-lads-tool\script\powershell\git-branch-rename.ps1 -TargetDir "all-lads-tool" -NewBranch "main/pakcli"
```

## 6. Error Handling & Invariants
- **Detached HEAD Guard**: Stops immediately if HEAD is detached.
- **Rule #001 Compliance**: Resolves paths dynamically from `$PSScriptRoot` without hardcoded system drive paths.
- **Dirty Tree Invariant**: Renaming does not mutate or discard uncommitted changes in the working tree.
