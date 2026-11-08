---
name: 01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED
aliases: [number-one-rule-no-unsolicited-deletion, preserve-unrequested-code, strict-anti-deletion-rule, zero-unsolicited-removals]
category: SAFETY_PROTOCOL
tags: [all-lads-tool, safety, preservation, anti-deletion, integrity, workflow, rule-01, protocol]
description: Supreme cardinal invariant prohibiting the removal, deletion, truncation, or refactoring away of any file, function, variable, comment, or line of code that the user did not explicitly ask to be removed.
dependencies:
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[delete-trashbin-project-root]]"
  - "[[delete-trashbin-system-not-permanent]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[donot-ngada-ngada-exact-lapangan-variables]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
  - "[[codebase-compliance-audit]]"
pros:
  - "Guarantees zero accidental data loss or silent loss of functional code"
  - "Prevents overzealous refactorings from gutting critical user features or comments"
  - "Enforces strict additive and surgical modification boundaries"
cons:
  - "Requires deliberate, surgical file edits and complete preservation of legacy or unrelated code"
---

# Number One Rule: Do Not Remove Anything That Was Not Asked (`01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED`)

> [!CAUTION]
> **CARDINAL RULE #01 — THE SUPREME SAFETY INVARIANT**:
> **NEVER REMOVE, DELETE, PURGE, TRUNCATE, OR STRIP OUT ANY COMPONENT THAT THE USER DID NOT EXPLICITLY ASK YOU TO REMOVE**.
> 
> 1. **Files & Directories**: Do not delete or prune any file or directory unless the user provides an exact, unambiguous command to remove it.
> 2. **Code & Functions**: When editing an existing file to add, fix, or adjust logic, **preserve all existing functions, methods, helper blocks, and variables** outside the direct scope of the requested change.
> 3. **Documentation & Comments**: Never silently delete docstrings, license headers, inline comments, or surrounding documentation blocks during code edits.
> 4. **No "Helpful" Cleanups**: Do not clean up, refactor away, or purge code you consider "unused", "dead", or "redundant" on your own initiative. If the user did not ask to delete it, **leave it untouched**.

---

## 1. The Anatomy of Unsolicited Removals

Unsolicited removal is one of the most destructive failure modes in automated and agentic coding. It manifests as:

1. **Silent Code Stripping**: Rewriting a 400-line script into an 80-line "simplified" script that removes essential features, error handling, or command switches.
2. **Comment Eradication**: Overwriting files and wiping out developer notes, warnings, TODOs, and architectural explanations.
3. **Collateral File Deletion**: Deleting older or sibling scripts during refactoring without explicit authorization.
4. **Parameter Purging**: Removing existing CLI switches or function arguments that are still in active use by other tools or downstream scripts.
5. **Over-Truncation**: Replacing large working structures with summaries, placeholders (`// ... existing code ...`), or incomplete stubs.

Under **Rule #01**, all such behaviors are classified as critical integrity violations.

---

## 2. The 4 Preservation Principles

```text
+-------------------------------------------------------------------------------+
|                    RULE #01 CODE PRESERVATION FRAMEWORK                      |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ User Instruction Received ]                                                |
|             |                                                                 |
|             v                                                                 |
|  [ AUDIT INSTRUCTION FOR EXPLICIT REMOVAL MANDATE ]                           |
|  - Did the user specifically ask to delete X?                                 |
|             |                                                                 |
|      +------+------+                                                          |
|      |             |                                                          |
|   [ NO ]        [ YES ]                                                       |
|      |             |                                                          |
|      v             v                                                          |
|  [ PRESERVE ]   [ QUARANTINE FIRST, NEVER HARD DELETE ]                       |
|  - Retain all   - Move target to trash-bin/ or OS Recycle Bin                 |
|    existing     - Strictly forbidden from using Remove-Item -Force            |
|    code/files   - Never delete unasked collateral files                       |
|      |                                                                        |
|      +---------------------+                                                  |
|                            v                                                  |
|                 [ SURGICAL EDIT PIPELINE ]                                    |
|                 - Add or patch only the targeted lines                        |
|                 - Retain all existing docstrings, types, and logic            |
|                 - Zero unrequested deletions verified before completion       |
+-------------------------------------------------------------------------------+
```

---

## 3. Mandatory Behavioral Matrix: Violations vs. Compliance

| Context | VIOLATION: Unsolicited Removal | COMPLIANCE: Cardinal Rule #01 |
| :--- | :--- | :--- |
| **Editing a Script** | Overwriting entire files and removing legacy functions or comments | Performing surgical edits (`edit_file`) targeting only the specific lines requested |
| **Refactoring Architecture** | Deleting older scripts because a newer version exists | Keeping existing scripts functional; moving only upon explicit user command |
| **Updating Documentation** | Wiping out previous sections, changelogs, or references | Appending or updating only the requested sections while keeping previous content intact |
| **Optimizing Functions** | Stripping out existing fallback paths or error handling branches | Preserving existing fallbacks and only augmenting or correcting the logic |
| **Stray Files Encountered** | Deleting unreferenced or temporary files autonomously | Reporting the finding to the user and asking for instructions before touching them |

---

## 4. Execution Protocol: When Removal IS Explicitly Requested

Even when the user explicitly instructs to remove an item (*"delete script X"*, *"hapus file Y"*):

1. **Zero Hard Delete**:
   - Never use `Remove-Item -Force`, `rm -rf`, or file shredding.
2. **Safe Quarantine Routing**:
   - If project-level quarantine is active, move the target item into `trash-bin/<relative-path>` per `[[delete-trashbin-project-root]]`.
   - If OS-level quarantine is requested, route the item to the native Operating System Recycle Bin per `[[delete-trashbin-system-not-permanent]]`.
3. **Strict Target Isolation**:
   - Move *only* the specific file or folder requested. Never sweep sibling files or parent directories.

---

## 5. Surgical Modification Checklist

Before applying any change to a codebase file:
- [ ] Have I identified the exact lines that need modification?
- [ ] Are all unrelated functions, methods, and classes preserved without alterations?
- [ ] Are all existing docstrings, inline comments, and type signatures intact?
- [ ] Did I verify that no parameters or configuration keys are being silently dropped?
- [ ] If a deletion was requested, is it routed safely to trash-bin rather than hard-deleted?
- [ ] Does the proposed change respect zero-emoji serious mode and ground-truth invariants?
