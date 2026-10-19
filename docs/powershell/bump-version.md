---
title: Granular Version Tag Bumper
tool: bump-version.ps1
category: lifecycle & versioning
runtime: PowerShell 7+
aliases: [bump-version, bump-version-tool]
tags: [all-lads-tool, powershell, lifecycle]
---

# 🛠️ `bump-version.ps1` — Granular Version Tag Bumper

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`

Increments micro version tags (v01_00 -> v01_01) for atomic commits or major version milestones (v02_00) and synchronizes main.json.

---

## 1. Quick Syntax & Usage

```powershell
.\all-lads-tool\script\powershell\bump-version.ps1 -Type minor -Message "feat(nav): add auto-hide"
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-Type` | string | No | `minor` | Version bump level: minor (0x-0x) or major |
| `-Message` | string | No | `""` | Commit message annotation for git tagging |
| `-GitCommit` | switch | No | `false` | Automatically commits with formatted version prefix |
| `-DryRun` | switch | No | `false` | Previews next version calculation without modifying files |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/powershell/bump-version.ps1`](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/script/powershell/bump-version.ps1)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](file:///d:/0pro/fadhlisl-my-id/all-lads-tool/rule/001-skills-no-hardcoded-variables.md).
