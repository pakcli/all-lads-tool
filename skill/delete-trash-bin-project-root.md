---
name: delete-trash-bin-project-root
aliases: [delete--trash-bin-project-root, project-root-trash, local-trash-quarantine, trash-bin-root]
category: FILE_CLEANUP_PROTOCOL
tags: [all-lads-tool, trash-bin, cleanup, quarantine, safety, local-trash, non-permanent]
description: Project-root soft deletion protocol routing deleted files, test artifacts, and temporary scripts into the repository's local trash-bin/ directory instead of hard deleting or sending to system trash.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Project-Root Trash-Bin Protocol (`delete-trash-bin-project-root`)

> [!IMPORTANT]
> **LOCAL QUARANTINE INVARIANT**:
> When cleaning up project artifacts, temporary test files, or decommissioned scripts within a project workspace, **NEVER permanently delete** (`Remove-Item -Force`).
> Instead, move items safely into the project-root `trash-bin/` directory (`<project-root>/trash-bin/`).

---

## 1. Core Principles

```text
┌────────────────────────────────────────────────────────────────────────┐
│               PROJECT-ROOT TRASH-BIN ARCHITECTURE                      │
├────────────────────────────────────────────────────────────────────────┤
│ 1. WORKSPACE ISOLATION : Trashed items stay inside project context    │
│ 2. GIT EXCLUSION       : trash-bin/ MUST be listed in .gitignore      │
│ 3. TIMESTAMP SAFEGUARD : Name collision avoidance with timestamps     │
│ 4. ZERO HARD DELETE    : Reversible by simple Move-Item restore        │
│ 5. REPRODUCIBLE AUDIT  : Developers inspect deleted files locally     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory & Git Configuration

1. **Location**:
   - The directory MUST reside at the workspace root: `<project-root>/trash-bin/`.
   - Created automatically upon first deletion if it does not exist.

2. **Git Ignore Requirement**:
   - Every project root using this protocol must enforce `trash-bin/` in its `.gitignore`:
     ```gitignore
     # Local trash bin quarantine
     trash-bin/
     ```

---

## 3. Standard Execution Patterns

### PowerShell Pattern (Primary)

```powershell
function Move-ToProjectTrash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path,
        [string]$ProjectRoot = (Get-Location).Path
    )

    $targetItem = Get-Item -LiteralPath $Path -ErrorAction Stop
    $trashDir = Join-Path $ProjectRoot "trash-bin"
    if (-not (Test-Path -LiteralPath $trashDir)) {
        New-Item -ItemType Directory -Path $trashDir -Force | Out-Null
    }

    $destPath = Join-Path $trashDir $targetItem.Name
    if (Test-Path -LiteralPath $destPath) {
        $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
        $newName = "{0}_{1}{2}" -f $targetItem.BaseName, $timestamp, $targetItem.Extension
        $destPath = Join-Path $trashDir $newName
    }

    Move-Item -LiteralPath $targetItem.FullName -Destination $destPath
    Write-Host "[TRASH-BIN] Moved '$($targetItem.Name)' -> 'trash-bin/'" -ForegroundColor Yellow
}
```

### Git-Aware Pattern (Unstage & Trash)

When trashing a file currently tracked or staged in Git:
```powershell
# 1. Unstage from Git index
git rm --cached -f -- "$targetFile" 2>$null

# 2. Relocate to project-root trash-bin
Move-Item -LiteralPath "$targetFile" -Destination "$projectRoot\trash-bin\"
```

---

## 4. Forbidden vs Mandatory Practices

| Context | ❌ FORBIDDEN | ✅ MANDATORY |
| :--- | :--- | :--- |
| **Old Scripts / Test Output** | `Remove-Item -Force $path` | `Move-Item $path $projectRoot\trash-bin\` |
| **Temporary Files** (`*.tmp`, `*.bak`) | `rm -rf *.tmp` | Relocate to `trash-bin/` |
| **Directory Scope** | Trashing files outside the project | Scope strictly within `<project-root>/` |
| **Git Tracking** | Staging or committing `trash-bin/` files | Ensure `trash-bin/` is git-ignored |

---

## 5. Recovery Procedure

To restore an item from `trash-bin/`:
```powershell
# Inspect available trashed items
Get-ChildItem -Path "$projectRoot\trash-bin"

# Move back to original workspace location
Move-Item -LiteralPath "$projectRoot\trash-bin\<item-name>" -Destination "$projectRoot\<target-folder>\"
```
