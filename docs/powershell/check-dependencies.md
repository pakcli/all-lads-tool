---
title: Toolchain Dependency Preflight Checker
tool: ps_check-dependencies.ps1
category: runtime & dependencies
runtime: PowerShell 7+
aliases: [ps_check-dependencies, check-dependencies, preflight-checker]
tags: [all-lads-tool, powershell, dependencies, preflight, automation]
---

# 🛠️ `ps_check-dependencies.ps1` — Dependency Preflight Checker

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Verifies that required runtimes (Node.js, Python, Git, Playwright) are installed and meet version constraints before executing any optional toolchain scripts. Offers automated installation via `winget` or `npm`.

---

## 1. Quick Syntax & Usage

```powershell
# Check all system and toolchain dependencies
.\all-lads-tool\script\powershell\ps_check-dependencies.ps1

# Check specific runtime with interactive installation prompt if missing
.\all-lads-tool\script\powershell\ps_check-dependencies.ps1 -TargetRuntime node -Install
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-TargetRuntime` | string | No | `all` | Specific runtime to check (`node`, `python`, `git`, `playwright`, or `all`) |
| `-Install` | switch | No | `false` | Enables interactive prompts to download/install missing runtimes via `winget` |
| `-Quiet` | switch | No | `false` | Suppresses console report and returns object stream directly |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/ps_check-dependencies.ps1`](..\../script/powershell/ps_check-dependencies.ps1)
* **Skill Reference**: [`all-lads-tool/skill/dependency-preflight-checker.md`](..\../skill/dependency-preflight-checker.md)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](..\../rule/001-skills-no-hardcoded-variables.md) and [Rule #000](..\../rule/000_main-rule.md).
