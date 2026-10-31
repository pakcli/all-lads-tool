---
title: Git All-State Prefix Renamer
tool: git-all-state-renamer-prefix-v.ps1
category: git & versioning
runtime: PowerShell 7+
aliases: [git-all-state-renamer-prefix-v, git-renamer-prefix, batch-prefix-renamer]
tags: [all-lads-tool, powershell, git, renamer, modular]
---

# 🛠️ `git-all-state-renamer-prefix-v.ps1` — Git All-State Prefix Renamer

> [!INFO]
> **Runtime**: PowerShell 7+ | **Directory**: `all-lads-tool/script/powershell/`  
> **Architecture**: Modular Edition (decoupled from `git-manage`, strictly independent per Rule #000).  
> **Compliance**: Conforms to **Rule #001** (Zero Hardcoded Paths) and **Rule #004** (Strict 2-Octet Versioning `v0x-0x_`).

A specialized, interactive batch renamer for Git repositories that safely renames files (e.g., converting legacy `brief-<name>.md` into standardized 2-octet versioned files `v01-01_<name>.md`) using `git mv` so commit histories are preserved via `git log --follow` without requiring history rewriting.

---

## 1. Quick Syntax & Usage

```powershell
# 1. Interactive Mode (prompts for target directory, prefix pattern, and strip count)
pwsh -File ./all-lads-tool/script/powershell/git-all-state-renamer-prefix-v.ps1

# 2. Targeted Directory with Dry-Run Preview
pwsh -File ./all-lads-tool/script/powershell/git-all-state-renamer-prefix-v.ps1 `
  -TargetDir "local/docs" `
  -Filter "brief-*.md" `
  -StripPrefix "brief-" `
  -VersionPrefix "v01" `
  -DryRun

# 3. Direct Execution (removes custom character count and injects 2-octet counter)
pwsh -File ./all-lads-tool/script/powershell/git-all-state-renamer-prefix-v.ps1 `
  -TargetDir "local/docs" `
  -Filter "*.md" `
  -StripLength 6 `
  -VersionPrefix "v01" `
  -StartIndex 1
```

---

## 2. Parameter Specifications

| Parameter | Type | Required? | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `-TargetDir` | `string` | No | Auto (`$PSScriptRoot/../../local/docs` or current dir) | Target directory containing files to rename. Evaluated dynamically. |
| `-Filter` | `string` | No | `brief-*.md` | Search pattern filter for candidate files. |
| `-StripPrefix` | `string` | No | `brief-` | Exact string prefix to strip from file basenames. |
| `-StripLength` | `int` | No | `0` | Alternative: exact number of leading characters to remove from file basenames. |
| `-VersionPrefix` | `string` | No | `v01` | Semantic version prefix matching Rule #004 (e.g. `v01`, `v02`). |
| `-StartIndex` | `int` | No | `1` | Starting counter for sequential numbering (`01`, `02`, ...). |
| `-DryRun` | `switch` | No | `$false` | Preview renames without executing `git mv` or touching files. |
| `-Interactive` | `switch` | No | Auto | Forces full interactive confirmation before executing operations. |

---

## 3. Transformation Example

Converting legacy briefs into Rule #004 standardized filenames:

| Original Filename | Transformation Rule | New Filename (Rule #004 Compliant) |
| :--- | :--- | :--- |
| `brief-apps-dashboard.md` | Strip `brief-` + Prefix `v01-01_` | `v01-01_apps-dashboard.md` |
| `brief-github-remote.md` | Strip `brief-` + Prefix `v01-02_` | `v01-02_github-remote.md` |
| `brief-privacy-masking.md` | Strip `brief-` + Prefix `v01-03_` | `v01-03_privacy-masking.md` |

---

## 4. Key Architectural Safeguards

1. **Zero Hardcoded Paths (Rule #001)**:
   - Dynamic path resolution via `$PSScriptRoot`. No machine drive letters (`D:\`, `C:\`) or hardcoded usernames.
2. **Git Tracking Invariant**:
   - Uses `git mv` for tracked files so Git recognizes renames as 100% similarity moves, preserving all historical diffs via `git log --follow`.
   - Untracked files fallback safely to `Move-Item`.
3. **Collision Protection**:
   - Pre-checks target paths before executing; halts if a destination file already exists.
4. **Working Tree Quarantine (`donot-commit-yet`)**:
   - Leaves renamed files safely staged or modified in the working tree; never executes automatic `git commit`.
