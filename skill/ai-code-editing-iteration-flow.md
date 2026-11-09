---
name: ai-code-editing-iteration-flow
aliases: [ai-code-editing-itteration-flow, direct-src-modification-no-scratch-flow, in-repo-iteration-standard, zero-unconnected-scratch-rule]
category: AGENTIC_DEVELOPMENT_LIFECYCLE
tags: [all-lads-tool, iteration, lifecycle, direct-src, anti-scratch, verification, code-editing, safety, protocol]
description: Standard operating procedure and lifecycle for AI-assisted code editing requiring direct in-repo source modification (src/), atomic build toolchain execution, real rendered DOM verification, and strict prohibition of disconnected scratch files or mock sandboxes.
dependencies:
  - "[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]"
  - "[[zero-hardcoded-sensitive-variables]]"
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
related:
  - "[[read-architecture-markdown-preserve-exact-ui-outcome]]"
  - "[[codebase-compliance-audit]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
pros:
  - "Guarantees all edits directly impact the actual project codebase rather than detached sandboxes"
  - "Eliminates false-positive test results caused by testing disconnected scratch files"
  - "Enforces atomic build-and-verify loops against the true rendered DOM"
cons:
  - "Requires strict discipline to modify production source directly with surgical precision"
  - "Demands immediate rollback capability if in-place verification fails"
---

# AI Code Editing Iteration Flow (`ai-code-editing-iteration-flow`)

> [!IMPORTANT]
> **THE DIRECT SOURCE & ZERO UNCONNECTED SCRATCH INVARIANT**:
> When a project features a real source directory (`src/`), an active build pipeline (`build-bundle.js`, compilers), or a public rendered DOM (`public/`, web app):
> 1. **HARUS WAJIB LANGSUNG DI `src/`**: All modifications must be applied directly to the real codebase files.
> 2. **STRICTLY PROHIBIT SCRATCH SCRIPTS (`brain/.../scratch/` & `scratch/`)**: Never create one-off scripts, inspectors, or scratch files (e.g. `brain > <id> > scratch > inspect-table.js`, `scratch/test.js`). Throwaway scratch scripts clutter directories, produce false confidence, and delay real progress.
> 3. **VERIFY ON THE REAL RENDERED DOM**: Every test, visual inspection, or Playwright capture must target the **actual live build or generated DOM** of the real project repository. Use inline terminal one-liners (`node -e "..."`) if quick data inspection is needed, without saving temporary files to disk.

---

## 1. Core Principles

1. **Direct In-Repo Ownership**: If a feature or fix is requested, edit the real source files (`src/`, `script/`, `docs/`) directly. Do not invent proxy files or disconnected experiments.
2. **Absolute Ban on Scratch Scripts**: Never create one-off scripts in `<appDataDir>\brain\<conversation-id>\scratch\` or workspace `scratch/` (such as `inspect-table.js`, `test-logic.js`).
3. **Rule of Least Surprise**: Never introduce unsolicited architectural rewrites, stylistic overhauls, or dependency additions beyond the explicit prompt.
4. **Read Before Touch**: Never edit a file without first reading the exact target lines, existing imports, docstrings, and local conventions.
5. **Preserve Documentation & Code Anchors**: Follow `01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED`. Retain all docstrings, comments, and unrelated helper blocks.
6. **Zero Hardcoded Sensitive Variables**: Never introduce drive letters or absolute machine paths. Follow `zero-hardcoded-sensitive-variables` using root-bounded placeholders (`<workspace_root>`, `<project_root>`).
7. **Non-Destructive Cleanup**: Never permanently delete (`rm -rf` / `Remove-Item -Force`). Move deprecated artifacts or temporary screenshots to `trash-bin/`.

---

## 2. The Absolute Prohibition on Scratch Scripts (`brain/.../scratch/` & `scratch/`)

```text
+-------------------------------------------------------------------------------+
|     BANNED PATTERN: BRAIN / WORKSPACE SCRATCH SCRIPT CREATION                 |
+-------------------------------------------------------------------------------+
|  VIOLATION:                                                                   |
|  brain > ac63f28d-06b3-4976-9e41-55245c49826f > scratch > inspect-table.js    |
|                                                                               |
|  WHY THIS IS STRICTLY PROHIBITED:                                             |
|  1. Orphaned Garbage: Creates detached, unversioned files outside the repo.  |
|  2. False Feedback: Testing a throwaway script tells you nothing about the    |
|     actual project build pipeline or the real browser DOM.                    |
|  3. Token & Time Waste: Burns user turns authoring, debugging, and running   |
|     scratch scripts instead of surgically modifying the real codebase.        |
+-------------------------------------------------------------------------------+
```

### Approved Alternatives to Scratch Scripts:

1. **Inline Terminal One-Liners (Zero Disk Footprint)**:
   If you need to inspect JSON data, parse a string, or check a regex, run an inline one-liner directly via `run_command` without writing any script to disk:
   ```powershell
   node -e "const data = JSON.parse(require('fs').readFileSync('public/apps/_catalog.json')); console.log(data.length);"
   ```
2. **Repository-Native Test Suites**:
   If a persistent automated check is needed, place it inside the repository's official test directory (`test/`, `script/`) per project conventions, never in a phantom scratch folder.
3. **Real DOM & Direct Headless Testing**:
   Inspect the real rendered DOM using built-in commands or existing test runners without creating temporary intermediate test files.

---

## 3. The 5-Phase Iteration Loop

```text
+-------------------------------------------------------------------------------+
|                    AI DIRECT-SOURCE ITERATION WORKFLOW                        |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ PHASE 1: DISCOVERY & REAL BASELINE INSPECTION ]                            |
|  - Inspect live working tree state via git status -s                          |
|  - Locate exact target files inside real source tree (src/, script/, docs/)   |
|  - Identify active build pipelines and rendered DOM targets                   |
|                                       |                                       |
|                                       v                                       |
|  [ PHASE 2: HYPOTHESIS & SURGICAL IN-PLACE PLANNING ]                         |
|  - Formulate minimal contiguous diffs (edit_file)                             |
|  - Identify responsive constraints (60 cols mobile, 72 cols desktop)          |
|  - Plan changes directly on real source files; ZERO scratch mocks planned     |
|                                       |                                       |
|                                       v                                       |
|  [ PHASE 3: SURGICAL DIRECT MODIFICATION & ATOMIC BUILD ]                     |
|  - Apply edits directly to target source files in src/ or script/             |
|  - Maintain existing indentation, casing, and coding styles                   |
|  - Trigger real repository build pipeline immediately:                       |
|    e.g. node src/modules/build-bundle.js or npm run build                     |
|                                       |                                       |
|                                       v                                       |
|  [ PHASE 4: REAL RENDERED DOM & AUTOMATED VERIFICATION ]                      |
|  - Verify compiler/bundler exits with code 0                                  |
|  - Inspect the ACTUAL generated output in public/ or dist/                    |
|  - Run visual checks (Playwright/CDP) against the true rendered DOM           |
|  - If verification fails -> Revert surgical edit in src/ and re-plan          |
|                                       |                                       |
|                                       v                                       |
|  [ PHASE 5: CLEANUP TO TRASH-BIN & SOVEREIGN REPORT ]                         |
|  - Move verification screenshots to trash-bin/                                |
|  - Confirm zero stray scratch files exist in the repo                         |
|  - Deliver concise summary with clickable file links and uncommitted state    |
|                                                                               |
+-------------------------------------------------------------------------------+
```

---

## 4. Phase Details & Invariants

### Phase 1: Discovery & Real Baseline Inspection
- Check `git status -s` to understand existing unstaged modifications.
- Locate the authoritative source files rather than generated output bundles.
- Never make assumptions based on stale briefs; inspect the newest brief in `brief/`.

### Phase 2: Hypothesis & Surgical In-Place Planning
- Isolate the smallest contiguous block of code that fulfills the requirement.
- Verify boundaries: do not touch upstream vendor themes or shared libraries unless explicitly requested.
- Confirm that testing will occur against the true project DOM, not a proxy sandbox.

### Phase 3: Surgical Direct Modification (`src/`) & Atomic Build
- Apply edits using surgical tools (`edit_file`) targeting specific line ranges.
- Do not rewrite whole files when a 5-line patch is sufficient.
- Run the actual project build toolchain immediately so the distribution bundles reflect the source modification.

### Phase 4: Real Rendered DOM & Automated Verification
- Verify the build logs for zero errors, zero warnings, and correct asset bundling.
- Launch verification against the real web app entry point (e.g. `public/index.html` or local dev server).
- Confirm layout aspect ratios (`3:4` card containers, `16:9` media slots) and responsive breakpoints.
- If a regression occurs, diagnose and fix the source file directly; do not patch the bundle or create sidecar hacks.

### Phase 5: Cleanup to `trash-bin/` & Sovereign Report
- Route any verification captures directly to `trash-bin/`.
- Verify that `git status -s` shows only intended changes in `src/`, `docs/`, or `public/` -- strictly zero scratch files.
- Report the results clearly, leaving all changes uncommitted in the working tree for sovereign human approval.

---

## 5. Anti-Patterns vs. Compliant Practices

| Anti-Pattern (STRICTLY PROHIBITED) | Compliant Practice (MANDATORY) |
| :--- | :--- |
| Creating `brain/.../scratch/*.js` (e.g. `inspect-table.js`) | Run inline shell one-liners (`node -e "..."`) with zero disk footprint |
| Creating `scratch/test.html` or isolated dummy scripts to test UI | Edit directly in `src/`, build via project toolchain, verify in real `public/` DOM |
| Testing a mock sandbox that does not affect the repository | Run verification strictly against the true repository build output |
| Overwriting entire 500-line files for a 3-line update | Perform surgical, contiguous block edits (`edit_file`) |
| Silently removing comments or helper functions during refactor | Strictly preserve all non-targeted code per Rule #01 |
| Hardcoding absolute machine paths in test scripts | Use root-bounded placeholders (`<workspace_root>`) per security standard |
| Permanently deleting files with `Remove-Item -Force` | Safely route all deletions to `trash-bin/` |
| Autonomously running `git commit` after editing | Present the diff and proposed message; leave working tree uncommitted |

---

## 6. Verification Checklist

Before reporting completion of an editing iteration:

- [ ] **Zero Brain Scratch Scripts**: Verified 0 files created in `brain/.../scratch/` or workspace `scratch/` folders.
- [ ] **Direct Source Verified**: Were edits made directly in `src/` or official source files?
- [ ] **Zero Scratch Debris**: Are there zero disconnected scratch files or mock sandboxes left in the repo?
- [ ] **Real DOM Verified**: Was testing executed against the actual built project output (`public/`, real DOM)?
- [ ] **Rule #01 Honored**: Are all existing comments, docstrings, and unrelated functions preserved?
- [ ] **Zero Hardcoded Paths**: Are all paths root-bounded with zero machine-specific drive letters?
- [ ] **Safe Disposal**: Were any temporary captures or obsolete files moved to `trash-bin/` rather than hard deleted?
- [ ] **Do Not Commit Yet**: Are all modifications sitting uncommitted in the working tree?
