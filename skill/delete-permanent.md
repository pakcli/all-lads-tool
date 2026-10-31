---
name: delete-permanent
aliases: [delte-permaentnt, hard-delete-protocol, permanent-destruction, force-delete-safeguard]
category: SECURITY_AND_SAFETY_PROTOCOL
tags: [all-lads-tool, delete, permanent, safety, security, data-loss-prevention, safeguard]
description: Strict authorization and verification protocol governing permanent, non-recoverable file destruction. Requires mandatory explicit user confirmation, dry-run impact preview, and absolute protection for system-critical paths.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Permanent Deletion Protocol (`delete-permanent`)

> [!CAUTION]
> **ABSOLUTE SAFETY INVARIANT**:
> **NEVER execute permanent, unrecoverable deletion (`Remove-Item -Force`, `rm -rf`) autonomously.**
> Permanent deletion destroys data beyond recovery. The agent MUST obtain explicit, unambiguous user confirmation and display an impact preview before running any permanent deletion command.

---

## 1. Core Principles

```text
┌────────────────────────────────────────────────────────────────────────┐
│                    PERMANENT DELETION SAFETY GATES                     │
├────────────────────────────────────────────────────────────────────────┤
│ GATE 1: STOP & VERIFY     - Explicit user approval required            │
│ GATE 2: PROTECTED ZONES   - Never touch .git, roots, or system folders │
│ GATE 3: IMPACT AUDIT      - Show file count and total size before execution │
│ GATE 4: VERIFY TARGET     - Verify path exists and is exact (no wildcards) │
│ GATE 5: UNRECOVERABLE LOG - Log the action clearly to terminal         │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Absolute Protected Zones (Forbidden Targets)

Under **NO CIRCUMSTANCES** may the following targets be permanently deleted:

1. **Git Database**: `.git/`, `.gitmodules`, git hooks.
2. **Drive / Filesystem Roots**: `C:\`, `D:\`, `/`, `/root`, `/etc`, `/usr`.
3. **Project Roots**: Deleting the entire workspace or repository folder.
4. **Environment & Secrets**: `.env`, `credentials.json`, `id_rsa`, `*.pem`, `*.key`.
5. **Parent Path Traversal**: Paths containing unverified `..` leading outside the project root.
6. **Broad Wildcards**: `Remove-Item * -Force`, `rm -rf *`, `rm -rf /*`.

---

## 3. Mandatory User Authorization Workflow

Before executing any hard delete command:

```text
1. Identify Candidate Items
2. Run Dry-Run Simulation (-WhatIf or List Targets)
3. Print Impact Summary (Total files, Total bytes, Exact paths)
4. Prompt User: "Do you explicitly authorize PERMANENT deletion of these specific items? (yes/no)"
5. IF user enters "yes" -> Execute
   ELSE -> Abort immediately or offer soft-delete to trash-bin/
```

---

## 4. Standard Execution Patterns

### PowerShell Pattern (Safe Hard Delete)

```powershell
function Invoke-PermanentDelete {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$LiteralPath,
        [switch]$Confirmed
    )

    # 1. Resolve and validate path
    if (-not (Test-Path -LiteralPath $LiteralPath)) {
        Write-Host "[ERROR] Target path does not exist: $LiteralPath" -ForegroundColor Red
        return
    }

    $resolved = (Resolve-Path -LiteralPath $LiteralPath).Path

    # 2. Check protected zones
    if ($resolved -match '^[A-Za-z]:\\?$' -or $resolved -match '[\\/]\.git([\\/]|$)') {
        Write-Host "[BLOCKED] Refusing to permanently delete protected target: $resolved" -ForegroundColor Red
        return
    }

    # 3. Dry-run impact count
    $items = Get-ChildItem -LiteralPath $resolved -Recurse -Force 2>$null
    $fileCount = if ($items) { ($items | Where-Object { -not $_.PSIsContainer }).Count } else { 1 }
    
    Write-Host "[WARNING] Permanent deletion requested for: $resolved" -ForegroundColor Yellow
    Write-Host "[WARNING] Affected files: $fileCount item(s). This cannot be undone." -ForegroundColor Yellow

    if (-not $Confirmed) {
        $ans = Read-Host "Type 'DELETE-PERMANENT' to confirm destruction"
        if ($ans -ne "DELETE-PERMANENT") {
            Write-Host "[ABORTED] Permanent deletion canceled by user." -ForegroundColor Green
            return
        }
    }

    # 4. Execute permanent deletion
    Remove-Item -LiteralPath $resolved -Recurse -Force
    Write-Host "[DELETED] Permanently removed: $resolved" -ForegroundColor DarkGray
}
```

---

## 5. Comparison: Permanent vs Trash Protocols

| Feature | `delete-permanent` | `delete-trash-bin-project-root` | `delete-trashbin-system-not-permanent` |
| :--- | :--- | :--- | :--- |
| **Recoverability** | ❌ Impossible (Zero) | ✅ 100% via Project `trash-bin/` | ✅ 100% via OS Recycle Bin |
| **Location** | Destroyed from disk | Kept in `<project-root>/trash-bin/` | Kept in System Recycle Bin |
| **User Confirmation** | Mandatory (Strict) | Automatic / Seamless | Seamless |
| **Workspace Cleanliness** | Completely cleaned | Stored in local trash folder | Completely cleaned |
