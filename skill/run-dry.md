---
name: run-dry
aliases: [powershell-dry-run, ps1-dry-run, simulation-mode]
category: SCRIPTING_PROTOCOL
tags: [all-lads-tool, powershell, dry-run, simulation, safety]
description: Standard operating protocol for adding and running non-destructive dry-run (-DryRun / -WhatIf) simulations in PowerShell scripts before applying state changes.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# PowerShell Dry-Run Protocol (`run-dry`)

> [!IMPORTANT]
> **SIMULATION BEFORE MUTATION**:
> Every PowerShell automation script that moves, writes, renames, or executes external commands must support a non-destructive `-DryRun` (or standard `[switch]$DryRun`) execution mode.

---

## 1. Standard Switch Definition in PowerShell

Every script that performs state mutations must include the parameter:

```powershell
param(
    [string]$TargetDir = "",
    [switch]$DryRun
)
```

Or enable advanced PowerShell `SupportsShouldProcess` for native `-WhatIf` / `-Confirm` compatibility:

```powershell
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TargetDir = ""
)
```

---

## 2. Implementation Rules

1. **Zero Mutations When `$DryRun` is Active**:
   - Prohibit invoking `Set-Content`, `Out-File`, `Move-Item`, `Remove-Item`, `New-Item`, or destructive API calls.
   - All state computations remain strictly in-memory.

2. **Visual Dry-Run Preview Table**:
   - Always display an impact table showing:
     - `Source`: Existing path / state
     - `Target`: Intended destination / state
     - `Action`: Operation to be performed (`CREATE`, `MOVE`, `UPDATE`, `EXECUTE`)
     - `Status`: `[DRY-RUN / NO CHANGE]`

3. **PowerShell Wrapper Pattern**:
   ```powershell
   function Invoke-SafeAction {
       param(
           [string]$ActionName,
           [string]$Target,
           [scriptblock]$ExecuteBlock
       )
       if ($DryRun) {
           Write-Host "[DRY-RUN] Would $ActionName -> $Target" -ForegroundColor Cyan
       } else {
           & $ExecuteBlock
       }
   }
   ```

4. **CLI Dry-Run Execution**:
   - When calling tools from terminal:
     ```powershell
     .\script.ps1 -DryRun
     # or
     powershell -NoProfile -ExecutionPolicy Bypass -File .\script.ps1 -DryRun
     ```
