---
name: modular-versioned-dependency-checker
aliases: [versioned-dependency-checker, multi-runtime-preflight]
category: RUNTIME_AND_DEPENDENCIES
tags: [all-lads-tool, dependencies, versioning, modular, polyglot, preflight]
description: Modular dependency checking protocol supporting multiple runtimes and declarative formats (.json, .py, .ps1, .js, .sh) inside modules/dependencies-checker/<version>.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Modular Versioned Dependency Checker Protocol (`modular-versioned-dependency-checker`)

> [!IMPORTANT]
> **MULTI-RUNTIME & FORMAT-AGNOSTIC ADAPTERS**:
> Versioned dependency checkers inside `modules/dependencies-checker/` are **NOT restricted to PowerShell (`.ps1`)**. 
> They can be implemented using declarative formats (`.json`) or native target language scripts (`.py` for Blender, `.cs` for Unity, `.js` for Web, `.sh` for Unix, `.ps1` for Windows).

---

## 1. Supported Formats & Structure

Inside each tool's `modules/dependencies-checker/`, version profiles can exist in multiple formats:

```text
context
	modules
		check.py
		v3-adapter.py
		v4-adapter.py
```

---

## 2. Declarative Schema (`<version>.json`)

For zero-code, universal compatibility across all runners (Python, JS, PowerShell, C#), prefer declarative `.json`:

```json
{
  "version": "4.0.1",
  "target": "blender",
  "minRuntime": {
    "python": "3.10.0"
  },
  "requiredCommands": [
    {
      "command": "blender",
      "versionArg": "--version",
      "expectedMin": "4.0.0"
    }
  ],
  "requiredModules": ["bpy", "mathutils"],
  "breakingChanges": [
    "Principled BSDF node input changes",
    "Mesh auto-smooth API refactor"
  ]
}
```

---

## 3. Native Script Formats

When environment logic requires deep introspection:
* **Blender**: `<version>.py` directly imports `bpy` and validates internal API properties.
* **Unity**: `<version>.json` or C# editor validation scripts verifying `ProjectVersion.txt` and package manifests.
* **Website / Node**: `<version>.js` or `.json` evaluating semver ranges against `engines.node`.
* **PowerShell / System**: `<version>.ps1` verifying system PATH, registry, and CLI presence.

---

## 4. Resolution Order

When checking a target version (e.g. `4.0.1`):
1. **Direct Match**: Check for `4.0.1.json` (declarative universal) or native runner extension (`.py`, `.ps1`, `.js`).
2. **SemVer Fallback**: If exact patch `4.0.1` is missing, fallback to minor `4.0.0.*` or nearest lower profile.
3. **Execution**:
   * If `.json`: Any runner reads and validates the rules without executing arbitrary code.
   * If native script (`.py`, `.ps1`, `.js`): Executed in the target runtime.
