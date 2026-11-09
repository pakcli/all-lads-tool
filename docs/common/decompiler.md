---
title: "Universal Standalone Decompiler & Slicer"
tool: "decompiler.ps1"
context: "common"
runtime: "PowerShell 5.1+ / 7+"
aliases: ["tool-decompiler", "script-unbundler", "standalone-decompiler"]
tags: ["all-lads-tool", "common", "decompiler", "unbundler", "modularizer", "distribution"]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
copy_to_terminal_snippet: |
  & .\script\common\decompiler.ps1 -StandaloneScript "dist/repo/git-checkpoint-rollback.ps1"
---

# `decompiler.ps1` - Universal Standalone Decompiler & Slicer (Context: Common)

> [!INFO]
> **Context**: `common` | **Executable**: `script/common/decompiler.ps1`
> **Adapters**: `script/common/adapter/decompiler-engine.psm1`, `script/common/adapter/path-normalizer.psm1`, `script/common/adapter/run-json-bridge.psm1`
> **Canonical Documentation**: `docs/common/decompiler.md` (Matches script filename 1:1)

Losslessly reconstructs modular source trees from single-file compiled executables. Scans `# [STANDALONE-MODULE: ...]` boundary markers, extracts sub-module code into `adapter/*.psm1` files, and restores the modular runner script.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive mode (prompts for standalone script path or drag-and-drop input)
.\script\common\decompiler.ps1

# Specify standalone script directly
.\script\common\decompiler.ps1 -StandaloneScript "dist/repo/git-checkpoint-rollback.ps1"

# Dry-run extraction preview without writing to disk
.\script\common\decompiler.ps1 -StandaloneScript "dist/repo/git-checkpoint-rollback.ps1" -DryRun
```

---

## 2. Command Line Parameters Matrix

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-StandaloneScript` | `[string]` | No | Interactive Prompt | Path to the compiled single-file script. Supports drag-and-drop input. |
| `-TargetDir` | `[string]` | No | Source Directory | Destination folder to reconstruct modular script and `adapter/` directory. |
| `-DryRun` | `[switch]` | No | `$false` | Previews extraction and outputs diagnostics without writing files. |
| `-Yes` | `[switch]` | No | `$false` | Bypasses interactive confirmation gating for CI/CD pipelines. |

---

## 3. Pre-Flight Briefed Overview Card

Before extracting, the tool renders a safety confirmation card:

```text
==========================================================
   DECOMPILER PRE-FLIGHT BRIEFED OVERVIEW
==========================================================
 Standalone Script : <workspace_root>/dist/repo/git-checkpoint-rollback.ps1
 Target Directory  : <workspace_root>/script/repo/ (Auto-resolved)
 Execution Mode    : Extract to Modular Structure
 Safety Status     : Reconstructs adapter/*.psm1 modules safely
==========================================================

Proceed with decompilation? (Type 'yes' to proceed, Enter to cancel):
```

---

## 4. Troubleshooting Matrix

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| No modules extracted | Target script was not compiled using Brief `v01-04-00` boundary markers | Ensure script contains `# [STANDALONE-MODULE: ...]` headers. |
| Path contains trailing quotes | Terminal drag-and-drop escaped trailing backslash | `path-normalizer.psm1` automatically strips quotes and sanitizes paths. |
