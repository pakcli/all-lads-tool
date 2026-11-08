---
name: update-readme-and-guide-and-what-commit-message-donot-commit-yet
aliases: [readme-guide-update-and-commit-proposal, update-docs-and-propose-commit, release-documentation-and-quarantine-commit, staged-commit-protocol]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, meta-skill, documentation, git, workflow, pre-commit, readme, guide]
description: Master composite release standard combining systematic README.md and GUIDE.md documentation synchronization with canonical commit message formulation (vxx-xx-xx context(ngapain): catatan) under strict pre-commit quarantine (donot-commit-yet).
dependencies:
  - "[[commit-convention]]"
  - "[[donot-commit-yet]]"
  - "[[asci-tree-codeblock-standard]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[zero-hardcoded-variables]]"
  - "[[modular-architecture-standard]]"
  - "[[sync-manifest-json-to-brief]]"
related:
  - "[[software-development-opensource]]"
  - "[[documentation-markdown-architecture]]"
  - "[[briefing-0x-0x-version]]"
pros:
  - "Guarantees documentation is always in lockstep with codebase reality before committing"
  - "Enforces the absolute 'DO NOT COMMIT YET' quarantine invariant, keeping the human developer in control"
  - "Produces standardized, structured commit messages adhering to vxx-xx-xx context(ngapain): catatan"
cons:
  - "Requires thorough multi-file auditing across README, GUIDE, and git working tree"
  - "Prevents instant automated git commits, requiring explicit user review and greenlight"
---

# Master Documentation Update & Staged Commit Message Protocol (`update-readme-and-guide-and-what-commit-message-donot-commit-yet`)

> [!IMPORTANT]
> **THE THREE-WAY RELEASE INVARIANT (WITH MANIFEST AUDIT)**:
> No functional, architectural, or UI refactoring is considered complete until:
> 0. **Package / Manifest JSON** (`package.json`, `manifest.json`) version and packaging script targets are synchronized with the architectural brief milestone (`brief/vXX-XX-XX_<name>.md`) per `[[sync-manifest-json-to-brief]]`.
> 1. **README.md** reflects the current high-level capabilities, table of contents, and architectural topology.
> 2. **GUIDE.md** provides precise operational CLI syntax, parameter tables, interaction modes, and edge-case troubleshooting.
> 3. **The Commit Message** is formulated according to canonical convention (`vxx-xx-xx context(ngapain): catatan`) matching the brief milestone version, and quarantined in the working tree under the **DO NOT COMMIT YET** invariant for sovereign human approval.
>
> *(For projects with automated multi-tier manifest validation, see the full 4-tier combo: `[[update-json-readme-and-guide-and-what-commit-message-donot-commit-yet]]`).*

---

## 1. Monospace Workflow Topology & Pipeline Diagram

```text
+-----------------------------------------------------------------------------------------------+
|             UPDATE README & GUIDE + WHAT COMMIT MESSAGE (DO NOT COMMIT YET)                   |
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|   [ INPUT: Codebase / Adapter / UI Changes in Git Working Tree ]                              |
|                                  |                                                            |
|                                  v                                                            |
|   +---------------------------------------------------------------------------------------+   |
|   | STAGE 1: SYSTEMATIC README.md SYNCHRONIZATION                                         |   |
|   | - Audit new capabilities, removed technical debt, and architectural shifts            |   |
|   | - Synchronize Table of Contents, 5-Context matrix, and quickstart runbooks            |   |
|   | - Eliminate obsolete parameters and invalid path assumptions                          |   |
|   +---------------------------------------------------------------------------------------+   |
|                                  |                                                            |
|                                  v                                                            |
|   +---------------------------------------------------------------------------------------+   |
|   | STAGE 2: COMPREHENSIVE GUIDE.md OPERATIONAL ALIGNMENT                                 |   |
|   | - Document exact CLI parameters, switches, and interactive dashboard keybindings     |   |
|   | - Detail GUI layouts, column widths, interaction ergonomics, and modal behavior       |   |
|   | - Add root cause troubleshooting entries for runtime issues and feedback loops        |   |
|   +---------------------------------------------------------------------------------------+   |
|                                  |                                                            |
|                                  v                                                            |
|   +---------------------------------------------------------------------------------------+   |
|   | STAGE 3: FORMULATE "WHAT COMMIT MESSAGE"                                              |   |
|   | - Canonical Pattern: vxx-xx-xx context(ngapain): catatan                              |   |
|   | - Structured Multi-line Body: Summary, Motivation/Root Cause, File Manifest           |   |
|   | - Verification Proof: Unit test status, manual sanity checks, and invariant audits    |   |
|   +---------------------------------------------------------------------------------------+   |
|                                  |                                                            |
|                                  v                                                            |
|   +---------------------------------------------------------------------------------------+   |
|   | STAGE 4: STRICT PRE-COMMIT QUARANTINE (DO NOT COMMIT YET)                             |   |
|   | - ABSOLUTE PROHIBITION: Agent NEVER runs 'git commit' autonomously                    |   |
|   | - Present working tree status ('git status -s') and formatted commit proposal         |   |
|   | - Await sovereign user review, adjustment, and explicit greenlight                    |   |
|   +---------------------------------------------------------------------------------------+   |
|                                  |                                                            |
|                                  v                                                            |
|   [ OUTPUT: Synchronized Docs + Uncommitted Staged State + Commit Proposal Codeblock ]        |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+
```

---

## 2. Pillar 1: Systematic README.md Synchronization

The root [`README.md`](file:///E:/proj/all-lads-tool/README.md) is the Master Hub and entry door for all developers and AI agents. When synchronizing:

1. **Table of Contents (Daftar Isi)**:
   - Must strictly reflect all numbered sections.
   - Any newly introduced context feature must be reflected in the 5 Contexts section.
2. **Context Feature Index**:
   - Update descriptions of modified scripts in `script/file/`, `script/repo/`, `script/website/`, etc.
   - Ensure component cards, status badges, and output formats accurately portray current software behavior.
3. **No Phantom Dependencies**:
   - Ensure prerequisite tables only declare true requirements.

---

## 3. Pillar 2: Comprehensive GUIDE.md Operational Alignment

[`GUIDE.md`](file:///E:/proj/all-lads-tool/GUIDE.md) is the complete technical and operational manual. When updating:

1. **Operational Section per Tool**:
   - Detail script entry point (e.g. `script/file/detector-clipboard-4-mode.ps1`).
   - Describe all parameter switches (`-Mode`, `-Panel`, `-Inspect`, `-Json`).
   - Detail the UI/UX layout (columns, widths, button behaviors, and keybindings).
2. **Troubleshooting Matrix**:
   - Record newly solved runtime failure modes (e.g., feedback loops in clipboard polling, UI scope isolation in dot-sourcing, stringification leaks).
   - Document prevention measures and recovery steps.

---

## 4. Pillar 3: Formulating "What Commit Message" (Canonical Protocol)

Commit messages must conform strictly to [`commit-convention`](file:///E:/proj/all-lads-tool/skill/commit-convention.md):

### 4.1 Canonical Header Pattern
```text
vxx-xx-xx context(ngapain): catatan
```

- **`vxx-xx-xx`**: 3-octet version matching current release or milestone (e.g., `v01-03-01`).
- **`context`**: Primary domain context (`file`, `repo`, `website`, `blender`, `unity`, `rule`, `skill`, `combo`, `brief`).
- **`(ngapain)`**: Concise action phrase in parenthesis (e.g., `(polyclip-5col)`, `(clean-plaintext)`, `(prevent-loop)`).
- **`: catatan`**: Short descriptive summary of the change.

### 4.2 Standard Multi-Line Commit Template
```text
vxx-xx-xx context(ngapain): catatan

### Summary of Changes
- Concise bullet points describing functional and UI changes.

### Root Cause / Motivation
- Technical explanation of what bug or friction point was solved.

### File Manifest
- Modified: [path/to/file]
- Added:    [path/to/file]
- Cleaned:  [path/to/store]

### Verification & Safety
- Test script results, WPF GUI verification, and pre-commit status.
```

---

## 5. Pillar 4: The "DO NOT COMMIT YET" Quarantine Invariant

Following [`donot-commit-yet`](file:///E:/proj/all-lads-tool/skill/donot-commit-yet.md):

> [!CAUTION]
> **ABSOLUTE RULE FOR AGENTS**:
> Under NO circumstance may the agent run `git commit`, `git commit -m`, or append `&& git commit` to commands.
> All modifications must sit safely uncommitted in the working tree.
> The agent presents the proposed commit message inside a clean markdown codeblock, reports `git status -s`, and tells the user:
> *"Semua perubahan tersimpan di working tree (uncommitted). Do not commit yet — siap untuk Anda periksa dan approve."*

---

## 6. Execution Runbook (Step-by-Step for Agents)

When the user triggers this combo:

```powershell
# Step 1: Inspect working tree status
git status -s

# Step 2: Update README.md with high-level feature notes
# Step 3: Update GUIDE.md with detailed operational syntax & troubleshooting
# Step 4: Verify working tree state without committing
git status -s

# Step 5: Present the proposed commit message to the user in a copyable codeblock
```
