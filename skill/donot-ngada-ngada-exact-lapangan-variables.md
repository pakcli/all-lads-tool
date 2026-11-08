---
name: donot-ngada-ngada-exact-lapangan-variables
aliases: [donot-ngada-ngada, exact-ground-truth-variables, no-hallucination-lapangan-protocol, strict-lapangan-parity]
category: WORKFLOW_PROTOCOL
tags: [all-lads-tool, workflow, safety, verification, ground-truth, lapangan, variables, protocol]
description: Strict anti-hallucination protocol mandating that all technical explanations, variable names, parameters, and environment references must match the exact live ground truth (lapangan) inspected directly from the actual codebase.
dependencies:
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[docs-same-file-name-script]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[brief-revisions-to-perfection]]"
pros:
  - "Eliminates phantom variables, hallucinated configuration flags, and imaginary CLI arguments"
  - "Guarantees 100% parity between script documentation, explanations, and actual running code"
  - "Forces direct code inspection of param blocks, environment variables, and runtime states before answering"
cons:
  - "Requires upfront codebase inspection calls before formulating technical explanations"
---

# Do Not Ngada-Ngada: Exact Lapangan Variables Protocol (`donot-ngada-ngada`)

> [!CAUTION]
> **ABSOLUTE INVARIANT**:
> **DILARANG KERAS NGADA-NGADA (ZERO HALLUCINATION)**.
> When explaining, documenting, or referencing scripts, functions, configuration keys, or environment settings:
> 1. **Inspect First**: NEVER assume, invent, or speculate variable names, parameter flags, default values, or file structures.
> 2. **Ground Truth (`Lapangan`)**: Inspect the actual script source code or live runtime environment before writing a single line of explanation.
> 3. **Exact Parity**: All reported variables must match the exact literal casing, signature, scope, and behavior verified on disk.
> 4. **No Guessing**: If a variable or parameter does not exist in the source file, state explicitly that it does not exist instead of improvising.

---

## 1. What Does "Ngada-Ngada" Mean in Engineering?

In agentic coding and technical architecture, *"ngada-ngada"* refers to:
- Fabricating parameter names (e.g., documenting `-ForcePush` when the actual script only accepts `-Force`).
- Quoting hypothetical configuration options that have never been implemented.
- Explaining variable scopes without checking `param()`, local scriptblocks, or module exports.
- Assuming external directory structures instead of resolving actual root-bounded paths.
- Claiming an environment variable exists without checking the script's actual `$env:` lookups.

Under this protocol, every single token representing a variable or configuration key must be verifiable against the live codebase (*lapangan*).

---

## 2. The 4 Golden Pillars of Lapangan Verification

```text
+-------------------------------------------------------------------------------+
|                       LAPANGAN VERIFICATION PIPELINE                         |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ Inquiry or Requirement Regarding Script / Component ]                      |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 1: READ SCRIPT SOURCE DIRECTLY ]                                      |
|  - Read param(...) block for exact names, types, and defaults                 |
|  - Read internal variables, calculated paths, and regex anchors               |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 2: CLASSIFY LAPANGAN VARIABLES ACCURATELY ]                           |
|  - A. Script Parameters (CLI / function inputs)                               |
|  - B. Runtime Calculated Variables (PSScriptRoot, dynamic state)             |
|  - C. Environment / Host Variables ($env:USERPROFILE, etc.)                  |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 3: EXPLAIN ACCORDING TO LIVE VALUES & SOURCE ]                        |
|  - Quote exact literal variable syntax ($TargetRepoUrl, $CloneMode)           |
|  - State exact line ranges or source locations                                |
|  - Explain what the variable ACTUALLY does in logic, not what it could do     |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 4: VERIFY BOUNDARIES & SECRETS ]                                      |
|  - Verify zero hardcoded machine drives (E:\, C:\)                            |
|  - Ensure sensitive values follow the 2-letter exposure mask rule             |
+-------------------------------------------------------------------------------+
```

---

## 3. Mandatory Behavioral Matrix: Hallucinated vs. Lapangan

| Context | FORBIDDEN: "Ngada-Ngada" (Hallucination) | MANDATORY: Exact Lapangan Ground Truth |
| :--- | :--- | :--- |
| **Explaining Script Parameters** | Generating names from memory (e.g. `$repoPath`, `$verboseMode`) | Reading the exact `param()` block and quoting exact names (e.g. `$RepoDirectory`, `$DebugOutput`) |
| **Explaining Config Keys** | Assuming standard keys like `timeout: 3000` | Reading `config.json` or `config.csv` to verify actual keys and types |
| **Explaining Path Variables** | Guessing root paths or hardcoding drive letters (`E:\proj\...`) | Verifying dynamic anchors like `$PSScriptRoot`, `(Get-Location).Path`, or bounded relative paths |
| **Explaining Return Values** | Assuming standard objects (`{ status: true }`) | Inspecting script pipeline output, `[PSCustomObject]`, or return statements |
| **Missing Information** | Inventing a plausible answer to sound helpful | Explicitly reporting: *"Variable not present in script, requires definition or prompt confirmation"* |

---

## 4. Lapangan Variable Classification Standard

When delivering a variable explanation or breakdown, organize variables into three strictly delineated categories:

### Category A: Explicit Script Parameters (`param`)
Variables passed into the script or function via CLI arguments or pipeline binding.
- **Verification Rule**: Must cite the exact `param(...)` definition, parameter attributes (e.g., `[Parameter(Mandatory=$true)]`), and type constraints.
- **Example**:
  ```powershell
  # Actual Lapangan Inspection:
  param(
      [string]$TargetRepoUrl = "",
      [ValidateSet("HTTPS", "SSH", "GitHubCLI", "GitClone")]
      [string]$ProtocolMode = "HTTPS"
  )
  ```

### Category B: Runtime Internal Variables
Variables computed dynamically within script execution.
- **Verification Rule**: Must state where and how the variable is calculated (e.g. parsed from regex, clipboard text, or directory lookup).
- **Example**:
  ```powershell
  # Actual Lapangan Inspection:
  $repoName = if ($TargetRepoUrl -match '/([^/]+?)(?:\.git)?$') { $matches[1] } else { "workspace" }
  ```

### Category C: Environment & System Boundaries
Variables sourced from the operating system or host session.
- **Verification Rule**: Must inspect whether fallback defaults exist and verify that no private credentials or raw usernames leak.
- **Example**:
  ```powershell
  # Actual Lapangan Inspection:
  $homeDir = if ($env:USERPROFILE) { $env:USERPROFILE } else { $HOME }
  ```

---

## 5. Verification Checklist Before Answering

Before delivering any explanation of a script's variables to the user:
- [ ] Have I read the target script using file inspection tools?
- [ ] Are all referenced variable names spelled and cased exactly as in the source file?
- [ ] Have I avoided adding non-existent helper parameters?
- [ ] Did I verify the default value assigned in the code rather than assuming one?
- [ ] Are directory paths described in root-bounded relative terms without machine drive letters?
- [ ] Is the tone casual yet formal with zero emojis?
