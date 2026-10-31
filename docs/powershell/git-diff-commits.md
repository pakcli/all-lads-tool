---
title: Commit Difference & Audit Inspector
tool: git-diff-commits_stand.ps1
category: git & versioning
runtime: PowerShell 7+
aliases: [git-diff-commits, git-diff-commits_stand, diff-analyzer]
tags: [all-lads-tool, powershell, git, diff, standalone]
---

# 🛠️ `git-diff-commits_stand.ps1` / `git-diff-commits.ps1` — Commit Difference & Sandbox Size Analyzer

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`
> **Two Editions Available**:
> - **Modular (`git-diff-commits.ps1`)**: Connected to `module/git-diffengine.psm1`, `module/git-core.psm1`, and `module/history.psm1`.
> - **Standalone (`git-diff-commits_stand.ps1`)**: Self-contained single-file analyzer with built-in minifier and sandbox extraction.

Inspects commit deltas, file modification lists, and compares source code and compiled build sizes across Git commits safely in isolated temp sandboxes.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive Selection Menu (defaults to comparing Live vs HEAD)
.\all-lads-tool\script\powershell\git-diff-commits_stand.ps1

# Modular invocation comparing Live (0) vs latest commit (1)
.\all-lads-tool\script\powershell\git-diff-commits.ps1 -Compare "0,1" -Mode "both"

# Range comparison (commits 1 to 5)
.\all-lads-tool\script\powershell\git-diff-commits_stand.ps1 -Compare "1-5" -Mode "src"

# Compare with 'vs' format
.\all-lads-tool\script\powershell\git-diff-commits_stand.ps1 -Compare "0vs1"
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
