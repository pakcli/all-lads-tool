---
name: interactive-modular-for-selected-context
aliases: [interactive-modular-context-dispatch, modular-context-prompt, context-parameter-resolver]
category: SCRIPTING_PROTOCOL
tags: [all-lads-tool, interactive, powershell, context, prompt, parameters]
description: Protocol and reusable PowerShell design pattern for creating interactive modular scripts that prompt for TARGET DIR and context-specific parameters with smart defaults and non-interactive CLI overrides.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Interactive Modular for Selected Context Protocol (`interactive-modular-for-selected-context`)

> [!IMPORTANT]
> **THE DUAL-MODE INTERACTION INVARIANT**:
> Every automation script across all contexts (`file`, `repo`, `website`, `blender`, `unity`) must support **Dual-Mode Execution**:
> 1. **Interactive Mode**: If executed without parameters (e.g. double-clicked or called plain), it MUST prompt the user for `TARGET DIR` and its primary target parameters with smart defaults.
> 2. **Non-Interactive CLI Mode**: If arguments are passed via CLI flags (`-TargetDir`, `-Target...`), prompts are automatically bypassed for headless and automated pipelines.

---

## 1. Universal Parameter Architecture

Every modular script must declare standard parameters with fallback interactive prompts:

```powershell
[CmdletBinding()]
param(
    [string]$TargetDir = "",
    [string]$TargetItem = "",
    [switch]$NonInteractive
)
```

---

## 2. Standard 3-Phase Execution Pattern

```text
┌────────────────────────────────────────────────────────────────────────┐
│               INTERACTIVE MODULAR CONTEXT DISPATCH FLOW                │
├────────────────────────────────────────────────────────────────────────┤
│ 1. CONTEXT DISCOVERY : Detect current folder or closest parent repo    │
│ 2. TARGET PROMPT     : Prompt for TARGET DIR if blank (with [Default]) │
│ 3. CONTEXT PARAMETER : Prompt for target item/file/commit if blank     │
│ 4. SAFE SCOPE PUSH   : Push-Location to target dir (isolated context)  │
│ 5. DISPATCH ACTION   : Execute modular action or invoke adapter        │
│ 6. SCOPE POP         : Pop-Location in finally block (zero side-effect)│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. PowerShell Implementation Template

```powershell
# Phase 1 & 2: Interactive Target Directory Discovery
if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    $defaultCandidate = (Get-Location).Path
    $inputDir = Read-Host "TARGET DIR (Folder context target) [Default: $defaultCandidate]"
    $TargetDir = if ([string]::IsNullOrWhiteSpace($inputDir)) { $defaultCandidate } else { $inputDir.Trim('"').Trim() }
}

if (-not (Test-Path -LiteralPath $TargetDir)) {
    Write-Error "Target directory not found: '$TargetDir'"
    exit 1
}

# Phase 3: Interactive Context-Specific Parameter
if ([string]::IsNullOrWhiteSpace($TargetItem)) {
    $TargetItem = Read-Host "TARGET ITEM (File/Commit/Asset to process)"
    $TargetItem = $TargetItem.Trim('"').Trim()
}

# Phase 4 & 5: Isolated Context Execution
Push-Location -LiteralPath $TargetDir
try {
    Write-Host "[ACTIVE CONTEXT] Working inside: $((Get-Location).Path)" -ForegroundColor Green
    # Execute modular action or invoke adapter here...
}
finally {
    Pop-Location
}
```

---

## 4. Context-Specific Target Prompts Reference

| Context | Mandatory Prompt 1 | Mandatory Prompt 2 |
| :--- | :--- | :--- |
| **`repo`** | `TARGET DIR` (Git repository root) | `TARGET COMMIT` (Commit index or hash) / `TARGET BRANCH` |
| **`file`** | `TARGET DIR` (Output notes folder) | `TARGET CSV` / `TARGET FILE` (Data input path) |
| **`website`** | `TARGET DIR` (Web project root) | `TARGET BUNDLE` / `TARGET SCSS` |
| **`blender`** | `TARGET DIR` (3D Assets folder) | `TARGET BLEND` (Model `.blend` file) |
| **`unity`** | `TARGET DIR` (Unity project root) | `TARGET ASSET` (Model or prefab to import) |

---

## 5. Verification Checklist

- [ ] Can the script be called with zero parameters without crashing (`.\script.ps1`)?
- [ ] Does the script prompt for `TARGET DIR` with a smart default in square brackets `[Default: ...]`?
- [ ] Does passing CLI parameters (`-TargetDir "path"`) completely skip all interactive prompts?
- [ ] Is `Push-Location` used and safely paired with `Pop-Location` inside a `finally {}` block?
