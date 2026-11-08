---
name: donot-code-yet-allow-markdown-creation-all
aliases: [allow-all-markdown-creation, code-quarantine-allow-all-md, docs-unrestricted-code-frozen]
category: WORKFLOW_PROTOCOL
tags: [all-lads-tool, workflow, safety, planning, documentation, markdown, pre-coding, protocol]
description: Strict pre-coding protocol freezing all executable source code (.ps1, .ts, .py, .json) while granting full authorization to create, refine, and structure any markdown files (.md) across docs/, brief/, skill/, combo/, and guidelines.
dependencies:
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[donot-code-yet-allow-markdown-creation-brief-only]]"
  - "[[docs-same-file-name-script]]"
  - "[[brief-revisions-to-perfection]]"
pros:
  - "Eliminates premature, unvetted script implementations and fragile runtime bugs"
  - "Empowers comprehensive documentation, architecture mapping, and skill building before code is touched"
  - "Allows seamless authoring of docs, briefs, skills, and combos without triggering code review gates"
cons:
  - "Requires explicit user prompt confirmation before any executable code files can be written"
---

# Do Not Code Yet: Allow Markdown Creation (All) (`donot-code-yet-allow-markdown-creation-all`)

> [!CAUTION]
> **ABSOLUTE INVARIANT**:
> **ALL EXECUTABLE CODE GENERATION IS FROZEN IN QUARANTINE**.
> 
> 1. **Code Execution Freeze**: NEVER create, edit, or mutate executable codebase files (`.ps1`, `.psm1`, `.ts`, `.js`, `.py`, `.json`, `.cs`, `.sh`) without explicit user instruction to code (*"code it"*, *"implement now"*, *"gas coding"*).
> 2. **Full Markdown Authorization**: The agent and developer ARE FULLY PERMITTED to create, expand, and refine any Markdown files (`.md`) across all documentation domains:
>    - `docs/**` (Technical specifications and tool manuals)
>    - `brief/**` (Architectural briefs and revision roadmaps)
>    - `skill/**` and `.agents/skills/**` (Reusable skills and workflow rules)
>    - `combo/**` (Multi-skill composite orchestrations)
>    - Root Markdown files (`README.md`, `GUIDE.md`, etc.)
> 3. **Preservation Invariant**: Existing documentation must not be deleted or gutted without explicit instruction (complies with Rule #01).

---

## 1. Context & Architectural Purpose

In large-scale agentic engineering, coding too early is the primary cause of architectural drift, code sprawl, and rework. However, freezing *everything*—including documentation—stifles collaborative design, requirement mapping, and skill formulation.

`donot-code-yet-allow-markdown-creation-all` splits the authoring boundary cleanly:
- **Executable Code (`.ps1`, `.ts`, etc.)**: Requires explicit approval to write.
- **Specification & Documentation (`.md`)**: Freely authorable for rapid iteration, comprehensive design planning, and knowledge capture.

---

## 2. Permitted vs. Quarantined File Operations

```text
+-------------------------------------------------------------------------------+
|                       FILE EXTENSION PERMISSION MATRIX                        |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ INCOMING USER PROMPT / TASK ]                                              |
|             |                                                                 |
|             v                                                                 |
|  [ FILE EXTENSION & TYPE AUDIT ]                                              |
|             |                                                                 |
|      +------+------+                                                          |
|      |             |                                                          |
|      v             v                                                          |
|  [ .md FILES ]   [ EXECUTABLE / CONFIG FILES ]                                |
|  - docs/*.md     - *.ps1, *.psm1, *.bat, *.cmd                                |
|  - brief/*.md    - *.ts, *.js, *.py, *.cs                                     |
|  - skill/*.md    - *.json, *.csv (unless catalog registration), *.yaml        |
|      |             |                                                          |
|      v             v                                                          |
|  [ ALLOWED ]     [ STRICT QUARANTINE: DO NOT CODE YET ]                       |
|  Author and      - Draft plan / brief first                                   |
|  refine freely   - Await explicit user command to code                        |
+-------------------------------------------------------------------------------+
```

---

## 3. Mandatory Behavioral Matrix

| Target File Type | Action Taken | Status |
| :--- | :--- | :--- |
| `docs/file/tool-name.md` | Author complete documentation & parameter tables | **PERMITTED** |
| `brief/v01-04_architecture.md` | Author architectural blueprint & phase plans | **PERMITTED** |
| `skill/new-protocol.md` | Formulate reusable agent skill & rules | **PERMITTED** |
| `combo/new-composite.md` | Define multi-skill workflow orchestration | **PERMITTED** |
| `script/file/tool-name.ps1` | Writing script code before confirmation | **FORBIDDEN (Quarantine)** |
| `src/components/Panel.ts` | Writing TypeScript components before confirmation | **FORBIDDEN (Quarantine)** |

---

## 4. Promotion Gate: Moving from Markdown to Code

When the specification in Markdown is complete:
1. Present the briefed overview and file placement plan to the user.
2. Await explicit confirmation to code (e.g. *"proceed"*, *"code it"*, *"implement"*).
3. Upon confirmation, the quarantine lifts, and executable code generation proceeds under `[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]` and `[[donot-commit-yet]]`.
