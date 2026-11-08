---
title: Git Identity Reconfig
tool: git-reconfig-identity.ps1
category: repo
runtime: PowerShell 5.1 / 7+
aliases: [git-reconfig-identity, git-identity-reconfig]
tags: [all-lads-tool, repo, powershell, git, identity, github, gitlab, modular]
---

# `git-reconfig-identity.ps1` - Git Identity Reconfig

> [!INFO]
> **Runtime**: PowerShell 5.1 / 7+ | **Directory**: `script/repo/`  
> **Architecture**: Modular Edition (Connected to `adapter/git-identity.psm1`).  
> **Scope**: Repo-local `user.name` / `user.email` only. Zero commits, zero history rewrites.

Reads the remote URL (GitHub or GitLab), extracts the owner account, and sets the repo-local identity to match it. Use it after cloning or forking a repo that still carries another author's identity.

---

## 1. Usage

```powershell
# Dry-run inspection
.\script\repo\git-reconfig-identity.ps1 -TargetDir "path/to/repo" -DryRun

# Apply repo-local identity configuration
.\script\repo\git-reconfig-identity.ps1 -TargetDir "path/to/repo"
```

---

## 2. Resolution Rules

| Field | Default | Override |
| :--- | :--- | :--- |
| `user.name` | Remote owner login | `-Name` |
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

* **Runner**: [`script/repo/git-reconfig-identity.ps1`](../../script/repo/git-reconfig-identity.ps1)
* **Adapter Engine**: [`script/repo/adapter/git-identity.psm1`](../../script/repo/adapter/git-identity.psm1) (exports `Get-RemoteOwner`, `Get-GitIdentity`, `Resolve-TargetIdentity`, `Set-LocalGitIdentity`)
