---
name: donot-code-yet
aliases: [do-not-code-yet, plan-first-code-later, pre-code-quarantine, no-premature-coding-protocol]
category: WORKFLOW_PROTOCOL
tags: [all-lads-tool, workflow, safety, planning, architecture, pre-coding, protocol]
description: Strict pre-coding quarantine protocol requiring all architectural proposals, file placement plans, API designs, and briefs to be reviewed and explicitly approved by the user before writing or modifying any codebase files.
dependencies:
  - "[[donot-commit-yet]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[zero-hardcoded-variables]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[brief-revisions-to-perfection]]"
  - "[[first-run-setup-wizard-zero-state]]"
pros:
  - "Eliminates premature, unvetted, or hallucinated file modifications and script rewrites"
  - "Guarantees architectural alignment on folder topology, dependencies, and APIs before implementation"
  - "Prevents wasted developer effort, unwanted file sprawl, and destructive refactoring"
cons:
  - "Introduces an upfront planning and review gate before code execution begins"
---

# Do Not Code Yet Protocol (`donot-code-yet`)

> [!CAUTION]
> **ABSOLUTE INVARIANT**:
> **NEVER write, edit, generate, or mutate codebase files** upon receiving a complex, ambiguous, or multi-file architectural prompt until:
> 1. The problem analysis, folder topology, API contract, and proposed approach have been formulated as a clear plan or architectural brief.
> 2. The plan has been presented to the user with a concise briefed overview.
> 3. The user provides an explicit confirmation to proceed (e.g., *"proceed"*, *"yes"*, *"code it now"*, *"lanjut"*).
>
> Prior to explicit confirmation, all code generation remains in quarantine (**DO NOT CODE YET**).

---

## 1. Core Mandate: The Pre-Coding Quarantine

Whenever an agent or developer initiates architectural tasks, major refactorings, or cross-context implementations:

1. **Zero Premature File Mutations**: Do not call file-writing or file-editing tools (`write_file`, `edit_file`, or script scaffolding) during exploratory or planning phases.
2. **Sovereign User Architectural Approval**: The user retains sole authority over design direction, naming conventions, directory structure, and scope boundaries before files are written.
3. **No Unilateral Assumptions**: When design ambiguities, multiple naming variants, or branching architectural choices exist, pause and present the options rather than guessing and generating premature code.
4. **Lifecycle Alignment**: Complements the release lifecycle:
   - **`donot-code-yet`**: Pre-implementation gating (Design/Plan Review &rarr; Approval).
   - **`confirmation-to-proceed-brief-overview-options`**: Pre-flight CLI execution gating (Briefed Overview Card &rarr; `[y/N]` prompt).
   - **`donot-commit-yet`**: Pre-commit working-tree quarantine (Working Tree &rarr; Human Review &rarr; Commit).

---

## 2. Forbidden vs. Mandatory Behavioral Patterns

| Context | FORBIDDEN (Premature Auto-Coding) | MANDATORY (Quarantine / Plan First) |
| :--- | :--- | :--- |
| **Architectural Refactor** | Editing files immediately upon user inquiry | Formulate brief/plan, present layout, await explicit confirmation |
| **New Script / Feature** | Creating files in `script/` before confirming topology | Propose exact file paths and 1:1 doc mapping; ask before writing |
| **Ambiguous Requirements** | Guessing intent and generating trial code | Ask targeted clarifying question; hold code in quarantine |
| **Tool / Package Installation** | Running installs before confirming dependency necessity | Present required package list and rationale; await greenlight |
| **Folder Hierarchy Shift** | Moving or creating directories unannounced | Preview target tree structure; obtain agreement before moving files |

---

## 3. Operational Protocol for AI Agents & Developers

```text
+-------------------------------------------------------------------------------+
|                       DO NOT CODE YET WORKFLOW PIPELINE                       |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ User Prompt / Requirement Received ]                                       |
|                    |                                                          |
|                    v                                                          |
|  [ STAGE 1: READ-ONLY INSPECTION & PROBLEM MAPPING ]                          |
|  - Inspect codebase, existing scripts, rules, and briefs                      |
|  - Zero writes to disk; read tools only                                       |
|                    |                                                          |
|                    v                                                          |
|  [ STAGE 2: ASSEMBLE ARCHITECTURAL PROPOSAL ]                                 |
|  - Define: Target file paths (1:1 docs/script parity)                         |
|  - Define: Dependencies, adapters, and interface contracts                    |
|  - Define: Step-by-step implementation roadmap                                |
|                    |                                                          |
|                    v                                                          |
|  [ STAGE 3: PRESENT BRIEFED OVERVIEW & ENFORCE QUARANTINE ]                   |
|  - Present concise plan and proposed file manifest                            |
|  - Explicitly state: "Do not code yet - awaiting confirmation to proceed."   |
|                    |                                                          |
|                    v                                                          |
|  [ STAGE 4: USER CONFIRMATION GATING ]                                        |
|  - Did user say "proceed", "yes", "code it"?                                  |
|      NO  --> Revise plan / clarify questions (ZERO code written)              |
|      YES --> Lift quarantine and proceed to implementation                     |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 4. The 4 Stages of Implementation

### Stage 1: Read-Only Inspection
Gather context, examine existing adapters, and check active briefs using read-only operations (`read_file`, `git status`). No files are created, modified, or deleted.

### Stage 2: Formulate Architectural Proposal
Document the proposed approach clearly:
- Target script path: `<workspace_root>/script/<context>/<tool-slug>.<ext>`
- Matching documentation path: `<workspace_root>/docs/<context>/<tool-slug>.md`
- Adapter requirements: `<workspace_root>/script/<context>/adapter/<adapter>.psm1`
- High-level logic flow and API contracts.

### Stage 3: Present Plan Under Quarantine
Present the proposal to the user and keep all file modifications quarantined:
> *"Rencana arsitektur dan penempatan file telah disiapkan di atas. Mengikuti protokol 'donot-code-yet', belum ada file yang dimodifikasi. Silakan periksa dan konfirmasi jika siap untuk diimplementasikan."*

### Stage 4: Execution Post-Approval
Only upon receiving explicit confirmation (`yes`, `proceed`, `lanjut`), invoke write tools to implement the agreed-upon design.

---

## 5. Why This Invariant is Critical

1. **Prevents Stray & Misplaced Files**: Avoids creating rogue documentation or duplicate files in unauthorized directories (e.g. creating `options.md` in `script/`).
2. **Saves Time & Tokens**: Prevents generating hundreds of lines of code that must subsequently be discarded or rewritten due to misaligned assumptions.
3. **Guarantees Canonical Compliance**: Ensures every new file strictly follows naming conventions, 1:1 documentation matching, and Rule #001 zero-hardcoding standards from the very first draft.
4. **Architectural Clarity**: Enforces clear thinking and clean design upfront, separating the planning phase from the execution phase.
