---
title: Commit Difference & Sandbox Size Analyzer
tool: git-diff-commits.ps1
category: repo
runtime: PowerShell 5.1 / 7+
aliases: [git-diff-commits, diff-analyzer]
tags: [all-lads-tool, repo, powershell, git, diff, modular]
---

# `git-diff-commits.ps1` - Commit Difference & Sandbox Size Analyzer

> [!INFO]
> **Runtime**: PowerShell 5.1 / 7+ | **Directory**: `script/repo/`  
> **Architecture**: Modular Edition (Connected to `adapter/git-diffengine.psm1`, `adapter/git-core.psm1`, and `adapter/history.psm1`).

Inspects commit deltas, file modification lists, and compares source code and compiled build sizes across Git commits safely in isolated temp sandboxes.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive Selection Menu (defaults to comparing Live vs HEAD)
.\script\repo\git-diff-commits.ps1

# Modular invocation comparing Live (0) vs latest commit (1)
.\script\repo\git-diff-commits.ps1 -Compare "0,1" -Mode "both"

# Range comparison (commits 1 to 5)
.\script\repo\git-diff-commits.ps1 -Compare "1-5" -Mode "src"

# Compare with 'vs' format
.\script\repo\git-diff-commits.ps1 -Compare "0vs1"
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Compare` | string | No | `""` | Commit indices or range (`0,1`, `0vs1`, `1-5`, `current,latest`) |
| `-Mode` | string | No | `both` | Analysis mode: `src`, `public`, or `both` |
| `-SrcFolder` | string | No | Auto | Source folder to measure (auto-detected `src`, `client`, etc.) |
| `-DistFolder` | string | No | Auto | Dist/output folder (auto-detected `public`, `dist`, etc.) |
| `-NoCache` | switch | No | `$false` | Bypass cached sandbox compile results |

---

## 3. Implementation Sources

- **Runner**: [`script/repo/git-diff-commits.ps1`](../../script/repo/git-diff-commits.ps1)
- **Adapters**:
  - [`script/repo/adapter/git-diffengine.psm1`](../../script/repo/adapter/git-diffengine.psm1)
  - [`script/repo/adapter/git-core.psm1`](../../script/repo/adapter/git-core.psm1)
  - [`script/repo/adapter/history.psm1`](../../script/repo/adapter/history.psm1)
