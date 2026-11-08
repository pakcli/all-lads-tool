---
name: zero-hardcoded-sensitive-variables
aliases: [bounded-relative-paths, zero-sensitive-leaks, workspace-root-containment, safe-relative-paths-standard]
category: SECURITY_AND_PORTABILITY_STANDARD
tags: [all-lads-tool, skill, security, containment, privacy, path-traversal, zero-hardcoded-variables]
description: Security and portability standard mandating zero hardcoded secrets and credentials, while allowing relative navigation to local project or sibling project directories within an authorized workspace root, strictly prohibiting traversal above the workspace root boundary.
dependencies:
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[sensitive-data-sanitizer]]"
  - "[[first-run-setup-wizard-zero-state]]"
pros:
  - "Permits modular multi-project and sibling repository orchestration via relative paths"
  - "Guarantees strict directory jail preventing traversal above the designated workspace root"
  - "Eliminates credentials, API tokens, and machine-specific absolute root paths from source code"
cons:
  - "Requires runtime boundary validation (path jail checking) when resolving relative paths"
---

# Zero Hardcoded Sensitive Variables & Root-Bounded Relative Paths (`zero-hardcoded-sensitive-variables`)

> [!IMPORTANT]
> **THE ROOT-BOUNDED CONTAINMENT & ZERO SECRETS INVARIANT**:
> 1. **Zero Hardcoded Secrets**: Under no circumstance may private API keys, bearer tokens, access passwords, connection strings, or raw secrets be hardcoded in scripts, markdown files, configuration templates, or source code.
> 2. **Allowed Relative Navigation**: Scripts and tooling are permitted to reference local directories (`./script/repo/`) and adjacent/sibling project directories (`../sibling-project/`) to support modular multi-repository workspaces.
> 3. **Strict Root Boundary Jail**: Path traversal is strictly forbidden from ascending above the defined workspace or repository root boundary (`<workspace_root>`). Any attempt to navigate outside the authorized root (e.g. `../../../../` escaping to system directories, user profiles, or OS partition roots) must be rejected and halted.

---

## 1. Permitted vs. Prohibited Matrix

| Target Entity | Permitted (Compliant) | Prohibited (Violation) |
| :--- | :--- | :--- |
| **Project Directories** | `./script/file/`, `docs/repo/` | Hardcoded machine root paths in source code |
| **Sibling Projects** | `../pakcli-plugin/`, `../web-app_sims/` (within workspace root) | Unbounded escape: `../../../../Windows` |
| **System Directories** | Generic system paths (`C:\Program Files\`, `%APPDATA%`) | Uncensored user machine account paths |
| **User Profile Paths** | Masked username paths (`C:\Users\us****\...`, `%USERPROFILE%`) | Raw personal user profile (`C:\Users\rawuser\...`) |
| **Credentials & Tokens** | Environment variables (`$env:API_KEY`, `process.env.TOKEN`) | Plaintext strings: `'ghp_abc123...'` |
| **Root Boundary** | Bounded within designated multi-project workspace root | Traversing up to disk root (`C:\`, `E:\`, `/`) |
| **Sensitive Data Display** | 2-Letter masked default state (`dc******@domain.com`) | Unmasked raw credentials in default CLI or UI |

---

## 2. Directory Containment Topology

```text
+-------------------------------------------------------------------------------+
|                      WORKSPACE ROOT CONTAINMENT BOUNDARY                      |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ TOP-LEVEL ROOT: <workspace_root>/ ]                                        |
|  |                                                                            |
|  +---> project-a/ (all-lads-tool)                                             |
|  |     +--- script/                                                           |
|  |     +--- docs/                                                             |
|  |     +--- skill/                                                            |
|  |                                                                            |
|  +---> project-b/ (pakcli-plugin)                                             |
|  |     +--- .agents/                                                          |
|  |     +--- src/                                                              |
|  |                                                                            |
|  [ ALLOWED ]: Relative navigation between project-a and project-b:            |
|    From project-a: Resolve-Path "../pakcli-plugin"  [ ALLOWED ]                |
|                                                                               |
|  [ FORBIDDEN ]: Traversing above <workspace_root>/:                           |
|    From project-a: Resolve-Path "../../.."          [ BLOCKED - ESCAPES ROOT ] |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 3. Runtime Path Boundary Validation Guards

Every script or tool accepting or calculating relative paths must enforce that the resolved absolute path remains within the authorized workspace root boundary.

### 3.1 PowerShell Implementation

```powershell
function Test-PathWithinRoot {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [string]$RootBoundary = $PSScriptRoot
    )

    if ([string]::IsNullOrWhiteSpace($TargetPath)) { return $false }

    try {
        # Normalize and resolve full paths
        $resolvedRoot = [System.IO.Path]::GetFullPath($RootBoundary)
        $combinedTarget = [System.IO.Path]::Combine($resolvedRoot, $TargetPath)
        $resolvedTarget = [System.IO.Path]::GetFullPath($combinedTarget)

        # Ensure root ends with separator for strict prefix matching
        $sep = [System.IO.Path]::DirectorySeparatorChar
        if (-not $resolvedRoot.EndsWith($sep)) {
            $resolvedRoot += $sep
        }

        # Check if target resides within root or matches root exactly
        $isSubdir = $resolvedTarget.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)
        $isExactRoot = ($resolvedTarget.TrimEnd($sep) -eq $resolvedRoot.TrimEnd($sep))

        return ($isSubdir -or $isExactRoot)
    } catch {
        return $false
    }
}
```

### 3.2 Node.js Implementation

```javascript
const path = require('path');

function isPathWithinRoot(targetPath, rootBoundary = process.cwd()) {
  if (!targetPath || typeof targetPath !== 'string') return false;

  const resolvedRoot = path.resolve(rootBoundary);
  const resolvedTarget = path.resolve(resolvedRoot, targetPath);
  const relative = path.relative(resolvedRoot, resolvedTarget);

  // If relative path starts with '..' or is absolute, it escapes root
  return !relative.startsWith('..') && !path.isAbsolute(relative);
}
```

### 3.3 Python Implementation

```python
from pathlib import Path

def is_path_within_root(target_path: str, root_boundary: Path = Path.cwd()) -> bool:
    if not target_path:
        return False
    try:
        resolved_root = Path(root_boundary).resolve()
        resolved_target = (resolved_root / target_path).resolve()
        return resolved_root in resolved_target.parents or resolved_target == resolved_root
    except Exception:
        return False
```

---

## 4. Sensitive Variable Isolation & Privacy Masking Protocol

### 4.1 Environment Variable Loading
Sensitive configurations must always be read from environment variables or git-ignored local configuration files (`_run.json`, `.env.local`):

```powershell
# CORRECT: Reading from environment variable with fallback
$apiKey = if ($env:TOOL_API_KEY) { $env:TOOL_API_KEY } else { "" }

# FORBIDDEN: Hardcoding credentials directly in script
$apiKey = "sk-live-1234567890abcdef" # VIOLATION: REJECTED
```

### 4.2 Two-Letter Default Exposure Rule
On default state, sensitive values (emails, account names, tokens) must never be displayed unmasked in CLI outputs or GUI panels:

```powershell
function Mask-SensitiveString {
    param ([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return "" }
    if ($Raw.Length -le 2) { return "**" }
    
    # Reveal first 2 characters, mask the remainder
    $exposed = $Raw.Substring(0, 2)
    $maskedLength = [math]::Max(4, $Raw.Length - 2)
    return $exposed + ("*" * $maskedLength)
}
```

### 4.3 System Directory References and User Path Masking Protocol
When system-level architectural explanations, environment audits, or diagnostic runbooks need to reference host operating system paths:

1. **System-Level Paths Allowed**:
   Generic system directories (e.g., `C:\Program Files\`, `/etc/`, `%APPDATA%`, `C:\Windows\`) may be explicitly referenced for technical context, provided they contain no personal user identifiers.

2. **User Profile Directory Masking (Mandatory Censoring)**:
   Whenever referencing user-specific host paths (such as `C:\Users\<user>\...` or `/home/<user>/...`), the username segment MUST be censored:
   - Permitted: `C:\Users\us****\AppData\...` (2-letter exposure rule) or generic placeholders `C:\Users\<user>\...`.
   - Prohibited: Unmasked raw personal user directory names (e.g., `C:\Users\realname\...`).

---

## 5. Verification Checklist

Before committing or releasing any automation script, tool, or skill:

- [ ] Ensure **zero credentials, tokens, or private secrets** are hardcoded.
- [ ] Ensure any relative path resolution (`../`) is bounded by an authorized workspace root.
- [ ] Verify that path jail guards (`Test-PathWithinRoot` or `isPathWithinRoot`) reject inputs attempting to traverse above the workspace root (`../../..`).
- [ ] Verify that source code relies on relative project paths rather than machine-specific absolute roots.
- [ ] Verify that system paths reference generic directories or have personal usernames strictly masked (`C:\Users\us****\`).
- [ ] Verify that sensitive values in default state follow the 2-letter masking protocol.
