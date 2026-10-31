---
name: env-string-statement-parser
description: Standard protocol and automated parser for resolving, replacing, and sanitizing runtime string statements and path boilerplate (__dirname, $PSScriptRoot, Path(__file__), and user machine PII) using main.env and main.json as the Single Source of Truth.
category: ARCHITECTURE_AND_STANDARDS
tags: [all-lads-tool, env, sanitizer, zero-pii, path-resolution]
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 🌐 Environment String Statement Parser Skill (`env-string-statement-parser`)

This skill defines the authoritative specification and transformation engine for resolving, sanitizing, and replacing machine-specific paths and boilerplate path-resolution statements across all repository scripts and documentation.

---

## 1. The Core Architecture: The Three-Tier System

To maintain **Zero-PII**, **Zero Hardcoded Variables (Rule #001)**, and **Clean Git History**, the repository separates execution into three distinct layers:

```text
+----------------------------------------------------------------------+
|                     THE THREE-TIER RUNTIME MODEL                     |
+----------------------------------------------------------------------+
| [1] main.json : Static Blueprint & Schema (Committed to Git)         |
|                 - Defines script catalogue, inputs, and defaults     |
|                                                                      |
| [2] main.env  : Living System Overrides & Machine State (Ignored)    |
|                 - Stores local ports, last-run history, user masks   |
|                 - Never commits to Git; prevents dirty status        |
|                                                                      |
| [3] main.ps1  : Universal Dispatcher & Engine                        |
|                 - Loads main.json blueprint                          |
|                 - Overlays main.env living configuration             |
|                 - Writes runtime session back to main.env            |
+----------------------------------------------------------------------+
```

---

## 2. Token Lexicon & Directory Aliases

Every script or rule referencing workspace locations must use standardized aliases defined in `main.env` and `main.json`:

| Token Alias | Target Directory | Description |
| :--- | :--- | :--- |
| `@root` | `.` | Root workspace directory |
| `@apps` | `apps` | Cartridges and standalone app sources |
| `@public` | `public` | Compiled distribution output |
| `@tools` | `all-lads-tool` | Optional developer cockpit and toolchain |
| `@rules` | `all-lads-tool/rule` | Architectural rules and invariants |
| `@skills` | `all-lads-tool/skill` | Agent skills and operational runbooks |
| `@scripts` | `all-lads-tool/script` | Executable automation scripts |
| `@docs` | `all-lads-tool/docs` | Technical documentation per script |

---

## 3. String Parsing & Replacement Rules

When an AI agent or developer authors, reviews, or refactors code, any statement matching the left column must be replaced by the compliant statement on the right:

### 3.1 Node.js Runtime Statements

```text
+----------------------------------------------------------------------+
| [DETECTED] Manual Depth Boilerplate:                                 |
|   const repoRoot = path.resolve(__dirname, '..', '..');              |
|                                                                      |
| [COMPLIANT] Dynamic Upward Discovery / Alias Resolution:             |
|   // Find repo root dynamically via anchor (main.json / main.env):   |
|   const repoRoot = findAnchorRoot(__dirname);                        |
+----------------------------------------------------------------------+
```

### 3.2 PowerShell Runtime Statements

```text
+----------------------------------------------------------------------+
| [DETECTED] Manual ScriptRoot Math:                                   |
|   $repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")         |
|                                                                      |
| [COMPLIANT] Dynamic Upward Discovery / Env Resolution:               |
|   # Resolves root dynamically from nearest main.env / main.json      |
|   $repoRoot = Get-WorkspaceRoot $PSScriptRoot                        |
+----------------------------------------------------------------------+
```

### 3.3 Python Runtime Statements

```text
+----------------------------------------------------------------------+
| [DETECTED] Manual Parent Traversal:                                  |
|   repo_root = Path(__file__).resolve().parent.parent                 |
|                                                                      |
| [COMPLIANT] Anchor-Based Root Lookup:                                |
|   repo_root = find_anchor_root(Path(__file__).resolve())             |
+----------------------------------------------------------------------+
```

### 3.4 PII & Machine Drive Masking

```text
+----------------------------------------------------------------------+
| [FORBIDDEN] Machine-Specific Hardcoded String:                       |
|   "D:\\projects\\sample-repo\\apps"                                   |
|   "C:\\Users\\<USER>\\AppData\\..."                                   |
|                                                                      |
| [COMPLIANT] Sanitized Alias or Env Variable:                         |
|   path.join(env.ALIAS_ROOT, env.ALIAS_APPS)                          |
|   Join-Path $env:ALIAS_ROOT $env:ALIAS_APPS                          |
+----------------------------------------------------------------------+
```

---

## 4. Upward Anchor Resolution ("Find-Up" Protocol)

To eliminate brittle `../../..` relative depth assumptions when scripts are relocated:

```text
+----------------------------------------------------------------------+
|                         FIND-UP ALGORITHM                            |
+----------------------------------------------------------------------+
| 1. Start at current script directory.                                |
| 2. Check if main.env or main.json exists in current directory.       |
| 3. If found: Return this path as @root.                              |
| 4. If not found: Move to parent directory.                           |
| 5. Repeat until filesystem root; fallback to relative depth if none. |
+----------------------------------------------------------------------+
```

---

## 5. Verification Checklist

Before completing any task modifying scripts or configuration:
* [ ] Verify `main.env` is listed in `.gitignore`.
* [ ] Ensure `main.ps1` writes session state to `main.env`, keeping `main.json` untouched.
* [ ] Run `node all-lads-tool/script/javascript/audit-codebase.js` to ensure zero hardcoded machine drives.
* [ ] Verify that Obsidian frontmatter contains **ZERO quotes** around properties.
