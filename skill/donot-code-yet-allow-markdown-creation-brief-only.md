---
name: donot-code-yet-allow-markdown-creation-brief-only
aliases: [allow-markdown-creation-brief-only, code-quarantine-brief-only, docs-brief-only-pre-code]
category: WORKFLOW_PROTOCOL
tags: [all-lads-tool, workflow, safety, planning, brief, architecture, pre-coding, protocol]
description: Restrictive pre-coding quarantine freezing all executable code and non-brief files, strictly limiting new markdown creation exclusively to architectural briefs inside brief/ (v0x-xx_*.md) until design sign-off.
dependencies:
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[donot-code-yet-allow-markdown-creation-all]]"
  - "[[brief-revisions-to-perfection]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
pros:
  - "Focuses developer and agent attention exclusively on high-level architectural briefs"
  - "Prevents premature documentation sprawl across docs/, skill/, or script/ before the core brief is stabilized"
  - "Enforces systematic versioning of system design concepts (v01-01, v01-02, v01-03)"
cons:
  - "Disallows creating skills or user docs until the brief is reviewed and accepted"
---

# Do Not Code Yet: Allow Markdown Creation (Brief Only) (`donot-code-yet-allow-markdown-creation-brief-only`)

> [!CAUTION]
> **ABSOLUTE INVARIANT**:
> **CODE IS FROZEN AND NEW DOCUMENTATION IS STRICTLY ISOLATED TO `brief/`**.
> 
> 1. **Code Execution Freeze**: NEVER create or edit executable source code files (`.ps1`, `.ts`, `.py`, `.json`, etc.) without explicit instruction.
> 2. **Brief-Only Markdown Permission**: Authoring new Markdown files is **STRICTLY RESTRICTED TO THE `brief/` DIRECTORY**:
>    - Permitted: `brief/v0x-xx_<concept-name>.md`
>    - Quarantined: `docs/**`, `skill/**`, `combo/**`, `script/**`
> 3. **Design Blueprint First**: All architectural debates, requirements, data schemas, and folder topology plans must be consolidated exclusively inside the target versioned brief.
> 4. **No Premature Sprawl**: Do not author user guides, manual pages, or skills until the brief receives explicit human approval.

---

## 1. When to Use the Brief-Only Variant

Use `donot-code-yet-allow-markdown-creation-brief-only` when:
- Designing a major new subsystem or architectural paradigm that is still in flux.
- Naming conventions, module boundaries, or data flow are actively being debated.
- You want to prevent polluting `docs/` or `skill/` with draft ideas that may be discarded during review.

---

## 2. Directory Isolation Matrix

```text
+-------------------------------------------------------------------------------+
|                      BRIEF-ONLY DIRECTORY ISOLATION                           |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ INCOMING ARCHITECTURAL PROPOSAL ]                                          |
|             |                                                                 |
|             v                                                                 |
|  [ TARGET DIRECTORY AUDIT ]                                                   |
|             |                                                                 |
|      +------+------+                                                          |
|      |             |                                                          |
|      v             v                                                          |
|  [ brief/*.md ]  [ ANY OTHER DIRECTORY ]                                      |
|  - Permitted     - docs/*.md    -> QUARANTINED (Too early for user docs)      |
|  - v0x-xx_*.md   - skill/*.md   -> QUARANTINED (Too early for agent skills)   |
|  - Architectural - script/*.*   -> QUARANTINED (Do not code yet)              |
|    blueprints    - combo/*.md   -> QUARANTINED (Too early for combos)         |
|      |                                                                        |
|      v                                                                        |
|  [ AUTHOR BRIEF & AWAIT HUMAN APPROVAL ]                                      |
+-------------------------------------------------------------------------------+
```

---

## 3. Mandatory Behavioral Matrix

| Location / Action | Permitted? | Rationale |
| :--- | :---: | :--- |
| `brief/v01-04_file-watcher-topology.md` | **YES** | Legitimate architectural brief authoring. |
| `docs/file/file-watcher-topology.md` | **NO** | Premature; tool design has not yet been approved. |
| `skill/file-watcher.md` | **NO** | Premature; workflow rules should wait for brief sign-off. |
| `script/file/file-watcher.ps1` | **NO** | Executable code strictly prohibited under quarantine. |

---

## 4. Promotion Lifecycle: From Brief to Implementation

```text
  [ Phase 1: brief-only ]   -->   [ Phase 2: allow-all ]   -->   [ Phase 3: Code Allowed ]
  Author brief/v0x-xx.md          Author docs/*.md               Write script/*.ps1
  Review architecture             Register skills & combos       Full test & verification
```
