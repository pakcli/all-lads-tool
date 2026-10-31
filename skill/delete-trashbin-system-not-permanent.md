---
name: delete-trashbin-system-not-permanent
aliases: [delete-trashbin-sistem-not-permanent, system-recycle-bin, os-trash-safe-delete, native-recycle-bin]
category: FILE_CLEANUP_PROTOCOL
tags: [all-lads-tool, recycle-bin, system-trash, os-trash, safety, non-permanent, recovery]
description: Cross-platform non-permanent deletion protocol routing files to the native Operating System Recycle Bin or Trash keeping the workspace clean while guaranteeing desktop GUI restorability.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# System Recycle Bin Protocol (`delete-trashbin-system-not-permanent`)

> [!TIP]
> **SYSTEM-TRASH INVARIANT**:
> When a clean workspace is required without storing residual files in the project folder, **send files to the native OS Recycle Bin / Trash**.
> This guarantees the file is removed from the local workspace directory while remaining 100% restorable via the Operating System Desktop GUI.

---

## 1. Core Principles

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   SYSTEM RECYCLE BIN ARCHITECTURE                      │
├────────────────────────────────────────────────────────────────────────┤
│ 1. ZERO LOCAL CLUTTER  : File disappears entirely from workspace tree  │
│ 2. DESKTOP RESTORATION : User can restore from Windows / macOS GUI     │
│ 3. REVERSIBLE BY DESIGN: Safe alternative to permanent destruction     │
│ 4. CROSS-OS SUPPORT    : PowerShell .NET (Win), Finder (mac), gio (Lin)│
│ 5. FALLBACK QUARANTINE : Falls back to project trash-bin/ if OS lacks  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Platform-Specific Implementations

### Windows (PowerShell via .NET `FileSystem`)

Windows PowerShell uses `Microsoft.VisualBasic.FileIO.FileSystem` to send items directly to the native Windows Recycle Bin without requiring external executables or dialog popups:

```powershell
Add-Type -AssemblyName Microsoft.VisualBasic

function Move-ToSystemRecycleBin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Path
    )

    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path

    if (Test-Path -LiteralPath $resolved -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory(
            $resolved,
            [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
        )
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
            $resolved,
            [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
            [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
        )
    }

    Write-Host "[RECYCLE-BIN] Sent to OS Recycle Bin: $resolved" -ForegroundColor Green
}
```

### macOS (Bash / AppleScript / `trash`)

```bash
# macOS Finder Trash Command
if command -v trash >/dev/null 2>&1; then
    trash "$TARGET_PATH"
else
    osascript -e "tell application \"Finder\" to delete POSIX file \"$(realpath "$TARGET_PATH")\"" >/dev/null
fi
```

### Linux (FreeDesktop Trash Spec / `gio` / `trash-cli`)

```bash
# Linux GIO Trash or trash-cli
if command -v gio >/dev/null 2>&1; then
    gio trash "$TARGET_PATH"
elif command -v trash-put >/dev/null 2>&1; then
    trash-put "$TARGET_PATH"
else
    echo "Warning: System trash not found. Falling back to project trash-bin/"
    mkdir -p "./trash-bin"
    mv "$TARGET_PATH" "./trash-bin/"
fi
```

---

## 3. Decision Matrix: Which Deletion Protocol to Choose?

```text
┌──────────────────────────────────────────────────────────┐
│                   DELETION TRIAGE MATRIX                 │
└──────────────────────────────────────────────────────────┘
                        │
         Is this a temporary project artifact?
         (e.g., test screenshots, .tmp, build artifacts)
               ├── YES ──► delete-trash-bin-project-root
               │           (Keep local, inspectable in project)
               │
         Does the user want a clean workspace, but safely?
               ├── YES ──► delete-trashbin-system-not-permanent
               │           (Sent to OS Recycle Bin, restorable via GUI)
               │
         Is permanent unrecoverable deletion explicitly demanded?
               └── YES ──► delete-permanent
                           (Requires explicit confirmation, irreversible)
```

---

## 4. Safety Guard & Fallback

If an agent or script cannot reach the native OS Recycle Bin service (e.g., inside restricted container or headless remote server):
1. **DO NOT switch to permanent delete**.
2. **FALL BACK safely** to `delete-trash-bin-project-root` (`./trash-bin/`).
3. Notify user: `"[FALLBACK] OS Recycle Bin unavailable. Safely relocated to './trash-bin/'."`
