---
name: dependency-preflight-checker
description: Protocol and automated PowerShell preflight engine that verifies runtime dependencies (Node.js, Python, Git, Playwright) and offers automated download/installation before executing any optional toolchain script.
category: RUNTIME_AND_DEPENDENCIES
tags: [all-lads-tool, dependencies, preflight, powershell, automation]
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 🔌 Dependency Preflight Checker Skill (`dependency-preflight-checker`)

This skill defines the authoritative protocol for verifying and automatically installing prerequisite runtimes before executing any optional developer tool or script in `all-lads-tool/`.

---

## 1. The Preflight Verification Principle

No developer script or automation routine should fail with an obscure error due to missing runtimes.

Before executing any script in the developer cockpit (`main.ps1` or standalone `.ps1` files), the system executes a **Dependency Preflight Check**:

```text
+----------------------------------------------------------------------+
|                    DEPENDENCY PREFLIGHT GATEWAY                      |
+----------------------------------------------------------------------+
| 1. Detect target runtime requirement (.js -> Node, .py -> Python).   |
| 2. Verify command existence and minimum required version.            |
| 3. If installed: Proceed to script execution seamlessly.             |
| 4. If missing: Prompt user with automated download/install action.   |
| 5. If confirmed: Execute winget/npm install, refresh PATH, & run.    |
+----------------------------------------------------------------------+
```

---

## 2. Supported Runtimes & Installation Handlers

| Runtime | Verification Command | Min Version | Automated Install Command (Winget/NPM) |
| :--- | :--- | :--- | :--- |
| **Node.js** | `node -v` | v18.0.0 | `winget install -e --id OpenJS.NodeJS.LTS` |
| **Python** | `python --version` | 3.8.0 | `winget install -e --id Python.Python.3.11` |
| **Git** | `git --version` | 2.30.0 | `winget install -e --id Git.Git` |
| **Playwright** | `Test-Path node_modules/playwright` | Latest | `npm install -D playwright; npx playwright install` |

---

## 3. PowerShell Implementation Pattern

Every optional script launcher must invoke the preflight gate:

```powershell
# Example: Testing Node.js availability before running JS
function Test-PreflightDependency {
    param ([string]$Runtime)

    switch ($Runtime.ToLower()) {
        "node" {
            $cmd = Get-Command node -ErrorAction SilentlyContinue
            if (-not $cmd) {
                Write-Host "[!] Node.js is required but not installed." -ForegroundColor Yellow
                $ans = Read-Host "Download and install Node.js via winget? [Y/n]"
                if ($ans -match "^(y|yes|)$") {
                    winget install -e --id OpenJS.NodeJS.LTS
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                } else {
                    return $false
                }
            }
            return $true
        }
        "python" {
            $cmd = Get-Command python -ErrorAction SilentlyContinue
            if (-not $cmd) {
                Write-Host "[!] Python 3 is required but not installed." -ForegroundColor Yellow
                $ans = Read-Host "Download and install Python via winget? [Y/n]"
                if ($ans -match "^(y|yes|)$") {
                    winget install -e --id Python.Python.3.11
                    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
                } else {
                    return $false
                }
            }
            return $true
        }
    }
    return $true
}
```

---

## 4. Verification Checklist

Before completing any task integrating optional scripts:
- [ ] Verify that `main.ps1` runs dependency checks before launching scripts.
- [ ] Ensure that users are prompted for confirmation before triggering any automated installation.
- [ ] Ensure environment variables (`$env:Path`) are refreshed dynamically if a tool is installed.
- [ ] Confirm compliance with Rule #000 (core build remains independent of this skill).
