---
title: "Universal Toolchain Compiler & Bundler"
tool: "compiler.ps1"
context: "common"
runtime: "PowerShell 5.1+ / 7+"
aliases: ["tool-compiler", "script-bundler", "standalone-compiler"]
tags: ["all-lads-tool", "common", "compiler", "bundler", "standalone", "distribution"]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
copy_to_terminal_snippet: |
  & .\script\common\compiler.ps1 -ToolScript "script/repo/git-checkpoint-rollback.ps1"
---

# `compiler.ps1` - Universal Toolchain Compiler & Bundler (Context: Common)

> [!INFO]
> **Context**: `common` | **Executable**: `script/common/compiler.ps1`
> **Adapters**: `script/common/adapter/compiler-engine.psm1`, `script/common/adapter/path-normalizer.psm1`, `script/common/adapter/run-json-bridge.psm1`
> **Canonical Documentation**: `docs/common/compiler.md` (Matches script filename 1:1)

Compiles modular automation tools and their associated `adapter/*.psm1` sub-modules into self-contained single-file production executables with standardized standalone boundary markers (`# [STANDALONE-MODULE: ...]`).

---

## 1. Quick Syntax & Usage

```powershell
# Interactive mode (prompts for tool script path or drag-and-drop input)
.\script\common\compiler.ps1

# Specify target script directly
.\script\common\compiler.ps1 -ToolScript "script/repo/git-checkpoint-rollback.ps1"

# Dry-run preview without writing to disk
.\script\common\compiler.ps1 -ToolScript "script/repo/git-checkpoint-rollback.ps1" -DryRun
```

---

## 2. Command Line Parameters Matrix

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-ToolScript` | `[string]` | No | Interactive Prompt | Path to the modular runner script to compile. Supports drag-and-drop input. |
| `-OutputDir` | `[string]` | No | `dist/<context>/` | Destination directory for the compiled standalone executable. |
| `-DryRun` | `[switch]` | No | `$false` | Previews inlining and outputs diagnostics without writing files. |
| `-Yes` | `[switch]` | No | `$false` | Bypasses interactive confirmation gating for CI/CD pipelines. |

---

## 3. Pre-Flight Briefed Overview Card

Before compiling, the tool renders a safety confirmation card:

```text
==========================================================
   COMPILER PRE-FLIGHT BRIEFED OVERVIEW
==========================================================
 Source Script : <workspace_root>/script/repo/git-checkpoint-rollback.ps1
 Output Dir    : dist/repo/ (Auto-resolved)
 Execution Mode: Compile to Standalone
 Safety Status : Source files remain strictly untouched (read-only)
==========================================================

Proceed with compilation? (Type 'yes' to proceed, Enter to cancel):
```

---

## 4. Troubleshooting Matrix

| Issue | Root Cause | Solution |
| :--- | :--- | :--- |
| Adapter modules not found | Script directory does not have `adapter/` subfolder | Ensure tool adheres to Brief `v01-03` modular foldering standard. |
| Path contains trailing quotes | Terminal drag-and-drop escaped trailing backslash | `path-normalizer.psm1` automatically strips quotes and sanitizes paths. |
