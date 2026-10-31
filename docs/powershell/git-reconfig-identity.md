---
title: Git Identity Reconfig
tool: git-reconfig-identity.ps1
category: git & versioning
runtime: PowerShell 7+ / 5.1
aliases: [git-reconfig-identity, git-identity-reconfig]
tags: [all-lads-tool, powershell, git, identity, github, gitlab, modular]
---

# `git-reconfig-identity.ps1` - Git Identity Reconfig

> [!INFO]
> **Runtime**: PowerShell 7+ / Windows PowerShell 5.1 | **Directory**: `all-lads-tool/script/powershell/`
> **Architecture**: Modular (connected to `module/git-identity.psm1`)
> **Scope**: Repo-local `user.name` / `user.email` only. No commit, no history rewrite.

Reads the remote URL (GitHub or GitLab), extracts the owner account, and sets the repo-local identity to match it. Use it after cloning or forking a repo that still carries another author's identity (for example `saberzero1`).

---

## 1. Usage

```powershell
.\all-lads-tool\script\powershell\git-reconfig-identity.ps1 -TargetDir "D:\path\to\repo" -DryRun
```

```powershell
.\all-lads-tool\script\powershell\git-reconfig-identity.ps1 -TargetDir "D:\path\to\repo"
```

---

## 2. Resolution Rules

| Field | Default | Override |
| :--- | :--- | :--- |
| `user.name` | Remote owner login (e.g. `pakcli`) | `-Name` |
| `user.email` | Global email if it contains the owner login, else `<owner>@users.noreply.github.com` | `-Email` |
| Remote read | `origin` | `-Remote` |

---

## 3. Parameters

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-TargetDir` | string | Current directory | Target repository. |
| `-Remote` | string | `origin` | Remote whose owner is used. |
| `-Name` | string | Owner login | Override `user.name`. |
| `-Email` | string | See rules above | Override `user.email`. |
| `-DryRun` | switch | `false` | Show before/after without writing. |

---

## 4. Implementation

* **Runner**: [`script/powershell/git-reconfig-identity.ps1`](../../script/powershell/git-reconfig-identity.ps1)
* **Engine**: [`script/powershell/module/git-identity.psm1`](../../script/powershell/module/git-identity.psm1) (exports `Get-RemoteOwner`, `Get-GitIdentity`, `Resolve-TargetIdentity`, `Set-LocalGitIdentity`)
