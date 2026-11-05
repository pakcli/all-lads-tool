---
name: interactive-asking-cli
aliases: [numbered-choice-cli, cli-history-picker, reverse-chronological-prompt]
category: CLI_DESIGN_STANDARD
tags: [cli, powershell, interactive, history-picker, agent-safe, prompt]
description: Interactive command-line prompt standard featuring reverse-chronological index selection (0 = latest option [Default], 1 = latest - 1, 2 = latest - 2), default Enter execution, agentic headless overrides, and cross-drive path validation.
pros:
  - "Provides frictionless developer experience with single-keypress repeat executions"
  - "Eliminates repetitive manual path typing via persistent reverse-chronological history"
  - "Preserves automated agent execution via headless parameter overrides"
cons:
  - "Requires persistent local JSON state management"
  - "Demands pre-flight validation on historical paths that may have moved or unmounted"
---

# Interactive Asking CLI Protocol (`interactive-asking-cli`)

## 1. Core Principle: The Reverse-Chronological Selection Standard

When building interactive command-line interfaces for multi-path, multi-drive, or multi-option build systems, developers and automation agents frequently need to reuse their most recent choices.

To minimize cognitive load, eliminate typo risks, and ensure predictable agent interaction, all interactive terminal scripts must adhere to the **Reverse-Chronological History Index**:

```text
===================================================
 SELECT TARGET DATA SOURCE
===================================================
 [0] D:\0pro\vault_sport-data      [Latest - Default / Press Enter]
 [1] E:\shared\backup-data         [Latest - 1]
 [2] D:\staging\test-fixtures      [Latest - 2]
 --------------------------------------------------
 [C] Enter Custom Path (Relative or Cross-Drive)
 [Q] Cancel and Exit
===================================================
```

---

## 2. Selection Index Invariants

### 1. Zero is Always the Latest Option (`0 = Latest`)
- Index `[0]` is **always** reserved for the most recently used successful target or default configuration.
- Pressing `<Enter>` with empty input must resolve directly to `[0]`.

### 2. Decreasing Chronology (`1 = Latest - 1`, `2 = Latest - 2`)
- Subsequent numbers represent prior choices in reverse chronological order:
  - `[1]`: Choice used immediately before the latest.
  - `[2]`: Choice used two iterations prior.
- History size must be capped (recommended: 3 to 5 items) using a FIFO eviction ring buffer to avoid terminal visual clutter.

### 3. Agentic & Non-Interactive Fallback
- Every interactive prompt must support a non-interactive override (`-NonInteractive`, `-Choice 0`, or `-DataSource <path>`).
- If an automated agent or CI environment invokes the script without a terminal TTY, the script must:
  1. Use the explicitly provided CLI parameter if present.
  2. Fall back to `[0]` (Latest) or safe default if `-NonInteractive` is set.
  3. Abort cleanly with exit code 1 if no default exists, rather than hanging on `Read-Host`.

### 4. Cross-Drive Path Normalization & Pre-Flight
- Input may be:
  - A relative path (`..\vault_sport-data`).
  - An absolute path on the same drive (`E:\proj\data`).
  - A cross-drive path on an external volume (`D:\0pro\vault_sport-data`).
- The script must resolve the absolute path (`Resolve-Path`) and verify its physical existence with `Test-Path` before proceeding or updating history. If a historically saved external drive is currently unplugged, the script must flag it as `[OFFLINE / NOT FOUND]` rather than crashing.

---

## 3. Persistent State Architecture

### History Storage File
- History must be stored in a local JSON state file (e.g. `build.json` or `.cli_history.json`) located at the script or workspace root.
- **Mandatory Git Exclusion**: The state file must be declared in `.gitignore`. It contains machine-specific absolute paths that must never be committed to shared repositories.

### State Schema Structure
```json
{
  "lastUpdated": "2026-11-03T14:15:00Z",
  "activeChoice": "D:\\0pro\\vault_sport-data",
  "history": [
    "D:\\0pro\\vault_sport-data",
    "E:\\shared\\backup-data",
    "D:\\staging\\test-fixtures"
  ]
}
```

---

## 4. Reusable PowerShell Implementation Pattern

```powershell
function Invoke-InteractiveAskingCli {
    [CmdletBinding()]
    param (
        [string]$PromptTitle = "SELECT TARGET SOURCE",
        [string]$StateFilePath = "$PSScriptRoot\build.json",
        [string]$ManualOverride = "",
        [switch]$NonInteractive = $false,
        [int]$MaxHistory = 5
    )

    # 1. Non-interactive CLI override takes precedence
    if (-not [string]::IsNullOrWhiteSpace($ManualOverride)) {
        if (-not (Test-Path -LiteralPath $ManualOverride)) {
            throw "Specified path does not exist: $ManualOverride"
        }
        return (Resolve-Path -LiteralPath $ManualOverride).Path
    }

    # 2. Read history from state file
    $history = @()
    if (Test-Path -LiteralPath $StateFilePath) {
        try {
            $state = Get-Content -LiteralPath $StateFilePath -Raw | ConvertFrom-Json
            if ($state.history) {
                $history = @($state.history)
            }
        } catch {
            $history = @()
        }
    }

    # 3. Handle non-interactive fallback
    if ($NonInteractive) {
        if ($history.Count -gt 0 -and (Test-Path -LiteralPath $history[0])) {
            return $history[0]
        }
        throw "Cannot execute non-interactively: no valid history available in $StateFilePath"
    }

    # 4. Display interactive prompt
    Write-Host "==================================================="
    Write-Host " $PromptTitle"
    Write-Host "==================================================="

    if ($history.Count -gt 0) {
        for ($i = 0; $i -lt $history.Count; $i++) {
            $pathItem = $history[$i]
            $exists = Test-Path -LiteralPath $pathItem
            $tag = if ($i -eq 0) { "[Latest - Default / Press Enter]" } else { "[Latest - $i]" }
            $status = if ($exists) { "" } else { " (PATH NOT FOUND / OFFLINE)" }
            Write-Host " [$i] $pathItem $tag$status"
        }
    } else {
        Write-Host " [No previous history found]"
    }

    Write-Host " --------------------------------------------------"
    Write-Host " [C] Enter Custom Path (Relative or Cross-Drive)"
    Write-Host " [Q] Cancel and Exit"
    Write-Host "==================================================="

    $selectedPath = ""
    while ([string]::IsNullOrWhiteSpace($selectedPath)) {
        $rawInput = Read-Host "Select option (Default: 0)"

        if ([string]::IsNullOrWhiteSpace($rawInput) -or $rawInput -eq "0") {
            if ($history.Count -gt 0) {
                if (Test-Path -LiteralPath $history[0]) {
                    $selectedPath = $history[0]
                } else {
                    Write-Warning "Target path is offline or does not exist: $($history[0])"
                }
            } else {
                $customInput = Read-Host "No history available. Enter path"
                if (Test-Path -LiteralPath $customInput) {
                    $selectedPath = (Resolve-Path -LiteralPath $customInput).Path
                } else {
                    Write-Warning "Path not found: $customInput"
                }
            }
        } elseif ($rawInput -match '^\d+$' -and [int]$rawInput -lt $history.Count) {
            $candidate = $history[[int]$rawInput]
            if (Test-Path -LiteralPath $candidate) {
                $selectedPath = $candidate
            } else {
                Write-Warning "Selected path is offline or does not exist: $candidate"
            }
        } elseif ($rawInput -eq "C" -or $rawInput -eq "c") {
            $customInput = Read-Host "Enter absolute or relative path"
            if (-not [string]::IsNullOrWhiteSpace($customInput) -and (Test-Path -LiteralPath $customInput)) {
                $selectedPath = (Resolve-Path -LiteralPath $customInput).Path
            } else {
                Write-Warning "Path not found or invalid: $customInput"
            }
        } elseif ($rawInput -eq "Q" -or $rawInput -eq "q") {
            Write-Host "Operation cancelled."
            exit 0
        } else {
            Write-Warning "Invalid selection. Please choose an available index."
        }
    }

    # 5. Update history ring buffer (push latest to index 0)
    $updatedHistory = @($selectedPath) + ($history | Where-Object { $_ -ne $selectedPath })
    if ($updatedHistory.Count -gt $MaxHistory) {
        $updatedHistory = $updatedHistory[0..($MaxHistory - 1)]
    }

    $statePayload = @{
        lastUpdated  = (Get-Date).ToString("o")
        activeChoice = $selectedPath
        history      = $updatedHistory
    }
    $statePayload | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $StateFilePath -Force

    return $selectedPath
}
```

---

## 5. Verification Checklist

1. **Default Enter Test**: When the prompt is presented with existing history, does pressing `<Enter>` without entering any text resolve to index `[0]` immediately?
2. **History Ordering**: When a new custom path `[C]` is selected, is it persisted at index `0`, pushing prior items to `1`, `2`, etc.?
3. **Cross-Drive Verification**: Can the prompt accept a path on a secondary drive letter (e.g. `D:\...` when running from `E:\...`) and resolve it cleanly?
4. **Offline Path Handling**: If a secondary drive is unplugged, does the script clearly indicate the path is offline rather than terminating abruptly?
5. **Headless Execution**: Does `-NonInteractive` complete without blocking when valid input or history is present?
