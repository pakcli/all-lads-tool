---
title: Commit Difference & Audit Inspector
tool: ps_diff-commits.ps1
category: git & versioning
runtime: PowerShell 7+
aliases: [ps_diff-commits, ps_diff-commits-tool]
tags: [all-lads-tool, powershell, git]
---

# 🛠️ `ps_diff-commits.ps1` — Commit Difference & Audit Inspector

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Inspects commit deltas, file modification lists, and milestone changes between git references.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\ps_diff-commits.ps1 -From "HEAD~1" -To "HEAD"
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-From` | string | No | `HEAD~1` | Starting commit hash or branch ref |
| `-To` | string | No | `HEAD` | Ending commit hash or branch ref |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/ps_diff-commits.ps1`](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/script/powershell/ps_diff-commits.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/rule/001-skills-no-hardcoded-variables.md).
