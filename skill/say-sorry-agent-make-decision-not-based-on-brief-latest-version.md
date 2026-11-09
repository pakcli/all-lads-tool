---
name: say-sorry-agent-make-decision-not-based-on-brief-latest-version
aliases: [say-sorry-agent-make-decision-not-based-on-brief-latest-version, apologize-stale-brief-decision, latest-brief-alignment-protocol]
category: AGENT_BEHAVIOR_PROTOCOL
tags: [all-lads-tool, protocol, apology, brief, versioning, alignment, discipline, governance]
description: Sincere apology and realignment protocol triggered when an agent makes architectural decisions, assumptions, or code changes based on an outdated brief rather than the latest versioned brief in brief/.
pros:
  - "Guarantees agent decisions always anchor to the highest canonical brief version"
  - "Eliminates architectural regression caused by memory latency or stale conventions"
  - "Enforces immediate admission, zero defensiveness, and rapid realignment"
cons:
  - "Requires active directory inspection of brief/ before answering architectural queries"
  - "Strictly invalidates any decision made from obsolete brief milestones"
---

# Say Sorry Because Agent Make Decision Not Based on Brief Latest Version

> [!IMPORTANT]
> **THE BRIEF SSOT (SINGLE SOURCE OF TRUTH) INVARIANT**:
> Architectural decisions, component layouts, naming standards, and data flows are governed strictly by the **latest versioned brief** inside `brief/` (e.g. `v01-04-03` > `v01-04-02` > `v01-04-00` > `v01-03`).
> If the agent makes a decision based on an older brief, memory bias, or generic assumptions: **Admit the error immediately, apologize directly without excuses, inspect the latest brief, and realign the output.**

---

## 1. Core Rule

1. **Admit Mistake Promptly**:
   When caught relying on stale specs or when user points out brief desynchronization, immediately state:
   > `"say sorry because agent make decision not based on brief latest version"`
2. **Zero Defensiveness**:
   - No deflection: Never blame context truncation, prompt length, or file naming.
   - No justification: Never argue that the older brief was "close enough" or "partially valid".
   - Full ownership: Acknowledge that the highest brief version was not verified first.

---

## 2. The 4-Step Realignment Workflow

```text
+-------------------------------------------------------------------------------+
|           LATEST BRIEF REALIGNMENT & APOLOGY WORKFLOW                         |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ STEP 1: PROMPT ADMISSION ]                                                 |
|  - Say exact apology: "say sorry because agent make decision not based on    |
|    brief latest version"                                                      |
|                                       |                                       |
|                                       v                                       |
|  [ STEP 2: DISCOVER LATEST BRIEF MILESTONE ]                                  |
|  - Run: Get-ChildItem brief/ (or scan repository brief/ directory)            |
|  - Identify highest semantic milestone: vXX-XX-XX                             |
|  - Example: brief/v01-04-03_*.md supersedes v01-04-02, v01-04-00, v01-03      |
|                                       |                                       |
|                                       v                                       |
|  [ STEP 3: GAP AUDIT (WHAT WAS STALE VS WHAT IS LATEST) ]                     |
|  - State plainly in 1-2 lines what stale assumption was mistakenly used.     |
|  - Quote the exact rule or invariant from the latest brief that governs it.  |
|                                       |                                       |
|                                       v                                       |
|  [ STEP 4: IMMEDIATE CORRECTIVE ALIGNMENT ]                                   |
|  - Present the updated solution, code, or explanation strictly complying     |
|    with the latest brief version.                                             |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 3. Mandatory Inspection Protocol Before Decision-Making

To prevent this error before it occurs:

1. **Always Inspect `brief/` Directory First**:
   Before proposing architecture, modifying core structure, or answering design questions, verify the newest file in `brief/`:
   ```powershell
   Get-ChildItem -Path "brief" -Filter "v*.md" | Sort-Object Name -Descending | Select-Object -First 3
   ```
2. **Check Status Frontmatter**:
   Ensure the chosen brief has `status: canonical` or represents the active milestone.
3. **Verify Superseded Directives**:
   If a newer brief modifies an earlier rule (for example, replacing hardcoded `Trigger` columns with dynamic `Tags`), the newer brief **always wins**.

---

## 4. Good vs. Bad Examples

### Bad (Defensive & Evasive):
> *"Actually, v01-03 still had valid points about modularity, and v01-04-02 was just created recently so I assumed the older structure applied..."*
*(Deflects responsibility, rationalizes stale information).*

### Bad (Performative Groveling):
> *"I am so terribly ashamed and embarrassed! Please forgive my catastrophic incompetence for looking at the wrong version!"*
*(Performative drama, wastes developer time).*

### Good (The Standard):
> *"say sorry because agent make decision not based on brief latest version.*
>
> *I mistakenly based the proposal on `v01-03` which had hardcoded trigger columns, instead of inspecting the latest `brief/v01-04-02_uiux-catalog-arcade-4-subsystems-3-display-modes.md` which replaced triggers with dynamic project-assigned tags.*
>
> *Here is the realigned implementation matching `v01-04-02`: ..."*
*(Prompt apology, specific gap identification, zero excuses, immediate fix).*
