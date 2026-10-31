---
name: protocol-dry-run
aliases: [dry-run-protocol, dryrun-protocol, dry-run-simulation, non-destructive-dryrun]
category: EXECUTION_SAFETY
tags: [all-lads-tool, skill, safety, dry-run, simulation, verification, non-destructive]
description: Authoritative protocol for non-destructive dry-run simulation, pre-execution impact tables, collision detection, and user confirmation before executing mutating operations.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 🛡️ Dry-Run & Non-Destructive Simulation Protocol (`protocol-dry-run`)

> [!IMPORTANT]
> **THE DRY-RUN INVARIANT**:
> **NEVER execute destructive or mutating batch actions** (bulk renames, mass file moves, tree restructuring, cleanup, or config rewrites) **without first computing, inspecting, and presenting a non-destructive Dry-Run preview.**

---

## 1. Core Mandate: Simulation Before Mutation

Every automation tool, migration script, and refactoring agent must implement a **2-Phase Simulation Architecture**:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        DRY-RUN SIMULATION PIPELINE                     │
├────────────────────────────────────────────────────────────────────────┤
│ 1. READ-ONLY SCAN   : Discovers candidate files/records (0 writes)     │
│ 2. IN-MEMORY PLAN   : Calculates target paths, new names, diff deltas │
│ 3. RISK DETECTION   : Validates collisions, overwrites & safety hazards│
│ 4. VISUAL TABLE     : Renders structured ASCII preview table to user   │
│ 5. USER GATEWAY     : Halts execution unless confirmed or run with -DryRun│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. The 4 Phases of Dry-Run Execution

### Phase 1: Read-Only Discovery
* Collect all candidate targets dynamically using context-agnostic scanning (per Rule #001).
* Prohibit invoking `Set-Content`, `Move-Item`, `Remove-Item`, `git mv`, `fs.renameSync`, or destructive CLI commands during this phase.

### Phase 2: In-Memory Plan Matrix
* Build a plan list containing objects with:
  * `Index`: Sequential counter (`1..N`).
  * `Source`: Current file/state path.
  * `Target`: Planned destination/mutation state.
  * `Operation`: Action to take (`Rename`, `Move`, `Rewrite`, `Delete`).

### Phase 3: Collision & Overwrite Pre-Check
Before prompting or executing:
* Check if `Target` already exists on disk.
* Flag collisions immediately as `COLLISION / ABORT`.
* If any collision exists, the tool must **ABORT BY DEFAULT** and block execution until resolved.

### Phase 4: Tabular Visual Output
Render a structured, monospaced ASCII table with fixed-width columns:

```text
No    | Original File                               | Proposed New Name                           | Safety Status
-------------------------------------------------------------------------------------------------------------------
1     | brief-apps-dashboard.md                     | v01-01_apps-dashboard.md                    | Ready
2     | brief-github-remote.md                      | v01-02_github-remote.md                     | Ready
3     | brief-privacy-masking.md                    | v01-03_privacy-masking.md                   | Ready
4     | brief-ytd-embed.md                          | v01-04_ytd-embed.md                         | COLLISION (File Exists)
```

---

## 3. Implementation Patterns Across Runtimes

### 3.1 PowerShell Standard Pattern (`.ps1`)

```powershell
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$NonInteractive
)

# 1. Build Plan List in Memory
$plan = [System.Collections.Generic.List[PSCustomObject]]::new()
$counter = 1

foreach ($file in $candidates) {
    $targetPath = Join-Path $file.DirectoryName "new-$($file.Name)"
    $isCollision = (Test-Path $targetPath) -and ($targetPath -ne $file.FullName)

    $plan.Add([PSCustomObject]@{
        Index       = $counter++
        Source      = $file.Name
        Target      = [System.IO.Path]::GetFileName($targetPath)
        Collision   = $isCollision
    })
}

# 2. Render Structured Table
Write-Host ("{0,-5} | {1,-40} | {2,-40} | {3}" -f "No", "Source", "Target", "Status")
Write-Host ("-" * 100)
foreach ($item in $plan) {
    $status = if ($item.Collision) { "[COLLISION / ABORT]" } else { "[READY]" }
    Write-Host ("{0,-5} | {1,-40} | {2,-40} | {3}" -f $item.Index, $item.Source, $item.Target, $status)
}

# 3. Halt on Collision
if (($plan | Where-Object { $_.Collision }).Count -gt 0) {
    Write-Host "Aborted: Collision detected." -ForegroundColor Red
    exit 1
}

# 4. Respect DryRun Switch
if ($DryRun) {
    Write-Host "Dry-Run active. Zero files modified." -ForegroundColor Yellow
    exit 0
}

# 5. User Confirmation Gate
if (-not $NonInteractive) {
    $confirm = Read-Host "Proceed with $($plan.Count) operations? (y/N)"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "Cancelled by user."
        exit 0
    }
}
```

---

### 3.2 JavaScript / Node.js Standard Pattern (`.js`)

```javascript
function executeWithDryRun(candidates, options = { dryRun: false }) {
  const plan = candidates.map((item, index) => {
    const target = calculateTarget(item);
    const collision = fs.existsSync(target);
    return { index: index + 1, source: item, target, status: collision ? 'COLLISION' : 'READY' };
  });

  console.table(plan, ['index', 'source', 'target', 'status']);

  if (plan.some(p => p.status === 'COLLISION')) {
    throw new Error('Collision detected! Aborting operation.');
  }

  if (options.dryRun) {
    console.log('ℹ️ Dry-run active. Zero filesystem mutations performed.');
    return;
  }

  // Proceed with actual mutation
  for (const item of plan) {
    fs.renameSync(item.source, item.target);
  }
}
```

---

## 4. Rule Synergy & Operational Invariants

1. **Synergy with `donot-commit-yet`**:
   - Even after a dry-run passes and live execution finishes successfully, all modified or staged files **MUST REMAIN IN THE UNCOMMITTED WORKING TREE**.
   - A successful dry run and live run never grants permission to automatically commit.
2. **Synergy with Rule #001 (Zero Hardcoded Variables)**:
   - Dynamic directory resolution must be preserved throughout dry run path calculations.
3. **Synergy with Rule #004 (Strict Naming)**:
   - Proposed target names calculated during dry-run simulation must be validated against 2-octet lower kebab-case standards before rendering the preview table.
