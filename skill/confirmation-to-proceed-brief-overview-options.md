---
name: confirmation-to-proceed-brief-overview-options
aliases: [confirmation-to-proceed, brief-overview-options-confirmation, cli-briefed-overview-gating, preflight-confirmation-options]
category: CLI_INTERACTION_STANDARD
tags: [all-lads-tool, skill, cli, interactive, confirmation, briefed-overview, options, safety-gating, ux]
description: Standardized CLI pre-flight pattern requiring interactive scripts to render a high-contrast Briefed Overview card of all resolved parameters, target paths, and command previews, followed by mandatory explicit confirmation gating (yes to proceed) before execution.
dependencies:
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[interactive-asking-cli]]"
  - "[[protocol-dry-run]]"
  - "[[git-clone-briefed-overview]]"
pros:
  - "Prevents accidental file overwrites, unvetted destructive commands, and wrong directory operations"
  - "Provides complete transparency by previewing exact parameters and commands before execution"
  - "Standardizes confirmation syntax (y/yes) across all scripts and CLI runtimes"
cons:
  - "Requires non-interactive override flag (--yes / -y / --force) for automated headless CI/CD pipelines"
---

# Confirmation to Proceed with Briefed Overview Options (`confirmation-to-proceed-brief-overview-options`)

> [!IMPORTANT]
> **THE PRE-FLIGHT BRIEFED OVERVIEW INVARIANT**:
> No mutating, network-fetching, or filesystem-modifying CLI script may execute blindly. All interactive CLI tools must display a standardized **Briefed Overview Card** detailing all resolved arguments, target paths, modes, and command previews, followed by an explicit **Yes-to-Proceed Gating Prompt** (`[y/N]`). Defaulting on empty `Enter` must always abort safely.

---

## 1. Interaction Pipeline & Topology

```text
+-------------------------------------------------------------------------------+
|             CONFIRMATION TO PROCEED WITH BRIEFED OVERVIEW TOPOLOGY            |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ User Invocation: CLI Script / Subcommand / Retarget ]                      |
|                                |                                              |
|                                v                                              |
|  [ 1. PARAMETER RESOLUTION & SANITIZATION ]                                   |
|  - Parse input arguments, normalize paths, and resolve defaults               |
|  - Validate existence, permissions, and preconditions                         |
|                                |                                              |
|                                v                                              |
|  [ 2. ASSEMBLE BRIEFED OVERVIEW METADATA ]                                    |
|  - Identify: Target, Action, Mode, Flags, and Command Preview                 |
|                                |                                              |
|                                v                                              |
|  [ 3. RENDER MONOSPACE BRIEFED OVERVIEW CARD ]                                |
|  ==========================================================                   |
|     [ACTION NAME] PRE-FLIGHT BRIEFED OVERVIEW                                 |
|  ==========================================================                   |
|   Target Resource : <workspace_root>/target-folder                            |
|   Action Mode     : Overwrite / In-Place / Clean Allocation                   |
|   Active Flags    : --branch master --depth 1                                 |
|   Command Preview : git clone <url> "<workspace_root>/target-folder"          |
|  ==========================================================                   |
|                                |                                              |
|                                v                                              |
|  [ 4. YES-TO-PROCEED CONFIRMATION GATING ]                                    |
|  - Prompt: "Proceed with [Action]? [y/N] (Type 'y' or 'yes' to proceed):"    |
|  - Input === 'y' | 'yes' -> Advance to Step 5                                 |
|  - Input === ''  | 'n'   -> Immediate clean exit (Code 0, Zero Side-Effects)  |
|                                |                                              |
|                                v                                              |
|  [ 5. EXECUTE ENGINE & DISPATCH ACTION ]                                      |
|  - Stream stdout / stderr in real-time                                        |
|  - Verify post-action state and persist execution history                     |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 2. Standard Briefed Overview Card Specification

All tools adhering to this standard must print the card bounded by double horizontal rules (`=`):

```text
==========================================================
   [ACTION NAME] PRE-FLIGHT BRIEFED OVERVIEW
==========================================================
 Remote / Source : [URL, source file, or upstream repository]
 Target Path     : [Absolute normalized destination path]
 Operation Mode  : [In-Place / Subdirectory / Dry-Run / Replace]
 Key Parameters  : [Branch, depth, format, or profile]
 Command Preview : [Exact executable command string to be run]
==========================================================

Proceed with [Action]? [y/N] (Type 'y' or 'yes' to proceed): 
```

### Confirmation Evaluation Rules:
1. **Case-Insensitive Match**: Only `y`, `yes`, `Y`, `YES` count as affirmative.
2. **Safe Default**: Hitting `Enter` with empty input evaluates to `No` (Cancellation).
3. **Explicit Abort Feedback**: On cancellation, print `[CANCELLED] Operation aborted by user confirmation check.` and exit without modifying disk state.
4. **Automation Bypass Flag**: Scripts must support `--yes`, `-y`, or `--force` for non-interactive automated workflows.

---

## 3. Reusable Implementations Across Runtimes

### PowerShell Implementation (`Test-BriefedOverviewConfirmation`)

```powershell
function Confirm-BriefedOverview {
    param(
        [Parameter(Mandatory)] [string]$ActionTitle,
        [Parameter(Mandatory)] [hashtable]$OverviewItems,
        [string]$CommandPreview = "",
        [switch]$Force
    )

    if ($Force) { return $true }

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   $ActionTitle PRE-FLIGHT BRIEFED OVERVIEW" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan

    foreach ($key in $OverviewItems.Keys) {
        $padKey = $key.PadRight(16)
        Write-Host " $padKey: $($OverviewItems[$key])" -ForegroundColor White
    }

    if ($CommandPreview) {
        Write-Host " Command Preview : $CommandPreview" -ForegroundColor Cyan
    }
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""

    $response = Read-Host "Proceed with operation? [y/N] (Type 'y' or 'yes' to proceed)"
    if ($response -match '^(y|yes)$') {
        return $true
    }

    Write-Host "[CANCELLED] Operation aborted by user confirmation check." -ForegroundColor Yellow
    return $false
}
```

### Node.js Implementation (`confirmBriefedOverview`)

```javascript
const readline = require('readline');

async function confirmBriefedOverview({ actionTitle, overviewItems, commandPreview, force = false }) {
  if (force) return true;

  console.log('\n==========================================================');
  console.log(`   ${actionTitle.toUpperCase()} PRE-FLIGHT BRIEFED OVERVIEW`);
  console.log('==========================================================');

  for (const [key, value] of Object.entries(overviewItems)) {
    console.log(` ${key.padEnd(16)}: ${value}`);
  }

  if (commandPreview) {
    console.log(` Command Preview : ${commandPreview}`);
  }
  console.log('==========================================================\n');

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  return new Promise((resolve) => {
    rl.question('Proceed with operation? [y/N] (Type \'y\' or \'yes\' to proceed): ', (answer) => {
      rl.close();
      const confirmed = /^(y|yes)$/i.test(answer.trim());
      if (!confirmed) {
        console.log('[CANCELLED] Operation aborted by user confirmation check.');
      }
      resolve(confirmed);
    });
  });
}
```

---

## 4. Pairing with Canonical Tool Documentation (`docs/<context>/<tool-slug>.md`)

Per [[docs-same-file-name-script]], options and parameter definitions must never be placed in a stray `options.md` file or inside `script/`. Instead, every CLI subsystem implementing this standard consolidates its options specification directly inside its 1:1 documentation file (e.g., `docs/repo/git-manage.md`) defining:
1. The available interactive menu choices and shortcuts.
2. The exact field definitions displayed inside the Briefed Overview card.
3. The validation criteria for user input.
4. The error recovery pathways when prerequisites are unmet.
