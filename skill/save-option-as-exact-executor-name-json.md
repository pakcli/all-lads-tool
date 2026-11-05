---
name: save-option-as-exact-executor-name-json
aliases: [executor-state-persistence, exact-script-json-standard, single-script-single-json]
category: PERSISTENCE_STANDARD
tags: [all-lads-tool, persistence, options, json, executor, architecture, standard]
description: Strict architectural standard mandating that every automation script or tool must save its options, user defaults, cache, and history into a JSON file named identically to its exact executor file name (<executor>.json).
pros:
  - "Eliminates mismatched, ambiguous, or orphaned configuration files"
  - "Guarantees 1:1 parity between executable and its state file"
  - "Context-agnostic and 100% modular across different directories"
cons:
  - "Requires dynamic resolution of script path instead of hardcoded strings"
---

# Save Option as Exact Executor Name JSON (`save-option-as-exact-executor-name-json`)

> [!IMPORTANT]
> **1:1 EXECUTOR-TO-JSON PARITY INVARIANT**:
> Whenever any automation tool, script, or adapter persists user options, default inputs, session state, or history, the configuration file **MUST BE NAMED IDENTICALLY** to the executor script's base filename with `.json` extension:
> `Join-Path $scriptDir "$($executorBaseName).json"`
>
> Hardcoding arbitrary, detached, or generic state filenames (such as `options.json`, `config.json`, `settings.json`, `history.json`, or disparate custom names) is **STRICTLY PROHIBITED**.

---

## 1. Motivation & Problems Solved

1. **Zero Mismatches**: When a script is named `file-merge-into-one.ps1`, users and agents should immediately find its state at `file-merge-into-one.json` right next to it, not inside an arbitrary file like `merge-config.json` or `my-output-state.json`.
2. **Predictable Cleanup & Auditing**: Finding all state and options files belonging to any tool is deterministic (`Get-ChildItem -Filter "$toolName.*"`).
3. **Multi-Instance Isolation**: If two different scripts exist in the same directory (`file-merge-into-one.ps1` and `file-one-to-multiple-files.ps1`), they will never collide on a generic `options.json`.

---

## 2. Directory Topology Example

```text
script/
  file/
    detector-clipboard-4-mode.ps1
    detector-clipboard-4-mode.json       <-- EXACT 1:1 state & history file
    file-merge-into-one.ps1
    file-merge-into-one.json             <-- EXACT 1:1 options & defaults file
    file-one-to-multiple-files.ps1
    file-one-to-multiple-files.json      <-- EXACT 1:1 options & defaults file
    csv-to-frontmatter.ps1
    csv-to-frontmatter.json              <-- EXACT 1:1 options & defaults file
    adapter/
      detector-clipboard-4-mode.psm1
```

---

## 3. Dynamic Resolution Implementation

### 3.1 PowerShell Implementation

Always resolve the base name dynamically from `$PSCommandPath` or `$MyInvocation.MyCommand.Path`:

```powershell
# Dynamic resolver for <executor-name>.json
$scriptBaseName = if ($PSCommandPath) {
    [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
} elseif ($MyInvocation.MyCommand.Path) {
    [System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Path)
} else {
    "default-tool"
}

# Resolve location: either adjacent to script or canonical workspace root
$optionsFile = Join-Path $PSScriptRoot "$scriptBaseName.json"

function Load-ExecutorOptions {
    if (Test-Path -LiteralPath $optionsFile) {
        try {
            $raw = Get-Content -LiteralPath $optionsFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                return ($raw | ConvertFrom-Json)
            }
        } catch {}
    }
    return @{}
}

function Save-ExecutorOptions {
    param ([object]$Options)
    try {
        $json = $Options | ConvertTo-Json -Depth 5
        Set-Content -LiteralPath $optionsFile -Value $json -Force -Encoding UTF8
    } catch {}
}
```

### 3.2 Canonical JSON Options Schema

The persisted JSON file should follow this standard schema:

```json
{
  "executor": "detector-clipboard-4-mode.ps1",
  "updatedAt": "2026-11-05T18:30:00Z",
  "options": {
    "lastSourceDir": "E:\\proj\\docs",
    "lastOutputFile": "E:\\proj\\merged.md",
    "showAll": false
  },
  "history": [
    {
      "timestamp": "18:25:00",
      "action": "...",
      "payload": "..."
    }
  ]
}
```

---

## 4. Legacy Migration Protocol

When migrating existing tools that previously used arbitrary state filenames (e.g. `polyclip-history.json`):
1. **Check for Target File First**: If `<executor>.json` exists, load it directly.
2. **Fallback to Legacy File**: If `<executor>.json` does not exist but `<legacy-name>.json` exists:
   - Read data from `<legacy-name>.json`.
   - Write data into the new `<executor>.json`.
   - Safely move `<legacy-name>.json` to `trash-bin/`.
3. **Future Writes**: All subsequent saves write exclusively to `<executor>.json`.
