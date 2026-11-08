---
name: update-json-readme-and-guide-and-what-commit-message-donot-commit-yet
aliases: [sync-manifest-readme-guide-and-commit-donot-commit-yet, 4-way-release-invariant, brief-json-readme-guide-commit-pipeline]
category: META_SKILL_COMBO
tags: [all-lads-tool, combo, meta-skill, manifest, json, package-json, brief, documentation, git, workflow, pre-commit, readme, guide]
description: Master composite 4-way release standard enforcing JSON manifest / package.json synchronization with architectural brief milestones, systematic README.md and GUIDE.md documentation updates, and canonical commit message formulation (vxx-xx-xx context(ngapain): catatan) under strict pre-commit quarantine (donot-commit-yet).
dependencies:
  - "[[sync-manifest-json-to-brief]]"
  - "[[briefing-0x-0x-version]]"
  - "[[commit-convention]]"
  - "[[donot-commit-yet]]"
  - "[[asci-tree-codeblock-standard]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[zero-hardcoded-variables]]"
  - "[[modular-architecture-standard]]"
related:
  - "[[update-readme-and-guide-and-what-commit-message-donot-commit-yet]]"
  - "[[software-development-opensource]]"
  - "[[documentation-markdown-architecture]]"
pros:
  - "Guarantees zero version drift between brief milestones, package.json manifest, installer output scripts, and docs"
  - "Enforces the absolute 'DO NOT COMMIT YET' quarantine invariant, keeping the human developer in control"
  - "Produces standardized, structured commit messages adhering to vxx-xx-xx context(ngapain): catatan"
cons:
  - "Requires thorough 4-point verification across brief, package.json, README, GUIDE, and git tree"
  - "Prevents instant automated git commits, requiring explicit user review and greenlight"
---

# Master Manifest, Documentation & Staged Commit Protocol (`update-json-readme-and-guide-and-what-commit-message-donot-commit-yet`)

> [!IMPORTANT]
> **THE FOUR-WAY RELEASE INVARIANT**:
> No functional, architectural, or UI refactoring is considered complete until:
> 1. **Package / Manifest & Lockfile JSON** (`package.json`, `package-lock.json`, `manifest.json`, plugin descriptors): Version and build/packaging script artifact targets are strictly synchronized with the canonical architectural brief milestone (`brief/vXX-XX-XX_<name>.md`) per `[[sync-manifest-json-to-brief]]`.
> 2. **README.md** reflects current high-level capabilities, table of contents, artifact outputs (`.vsix` or `dist/`), and quickstart runbooks.
> 3. **GUIDE.md** provides precise operational CLI syntax, parameter tables, interaction modes, and edge-case troubleshooting.
> 4. **The Commit Message** is formulated according to canonical convention (`vxx-xx-xx context(ngapain): catatan`), strictly matching the brief milestone version, and quarantined in the working tree under the **DO NOT COMMIT YET** invariant for sovereign human approval.

---

## 1. Monospace Workflow Topology & Pipeline Diagram

```text
+-----------------------------------------------------------------------------------------------+
|         UPDATE JSON, README & GUIDE + WHAT COMMIT MESSAGE (DO NOT COMMIT YET)                 |
+-----------------------------------------------------------------------------------------------+
|                                                                                               |
|   [ INPUT: Codebase / Adapter / UI Changes + Architectural Brief Milestone ]                  |
|                                  |                                                            |
|                                  v                                                            |
|   +---------------------------------------------------------------------------------------+   |
|   | STAGE 0: MANIFEST JSON & PACKAGE.JSON SYNCHRONIZATION                                 |   |
|   | - Discover active brief under brief/vXX-XX-XX_*.md                                    |   |
|   | - Map milestone octets (v01-01-01) to SemVer (1.1.1) per [[sync-manifest-json-to-brief]] |
|   | - Align package.json "version" and packaging script targets (e.g. .vsix or .tgz)      |   |
|   +---------------------------------------------------------------------------------------+   |
|                                  |                                                            |
|                                  v                                                            |
|   +---------------------------------------------------------------------------------------+   |
|   | STAGE 1: SYSTEMATIC README.md SYNCHRONIZATION                                         |   |
|   | - Audit new capabilities, removed technical debt, and architectural shifts            |   |
|   | - Synchronize Table of Contents, 5-Context matrix, and quickstart runbooks            |   |
|   | - Ensure installer command references point to the synchronized artifact version      |   |
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
|   | - Header version strictly matches the brief milestone (v01-01-01)                     |   |
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
|   [ OUTPUT: Synchronized Manifest + Synchronized Docs + Staged State + Commit Proposal ]      |
|                                                                                               |
+-----------------------------------------------------------------------------------------------+
```

---

## 2. Pillar 0: Manifest JSON / `package.json` Synchronization

Adhering to [`sync-manifest-json-to-brief`](file:///e:/proj/all-lads-tool/skill/sync-manifest-json-to-brief.md):
1. **Discover Brief Milestone**: Check `brief/` for the active specification (e.g. `brief/v01-01-01_multi-column-tree-explorer.md`).
2. **Convert Milestone to SemVer**:
   - `v01-00-00` $\rightarrow$ `1.0.0`
   - `v01-01-01` $\rightarrow$ `1.1.1`
   - `v01-03-02` $\rightarrow$ `1.3.2`
3. **Audit Manifest Fields**:
   - Update `"version"` in `package.json` or `manifest.json`.
   - Update `"package"` script output target (e.g. `./out/multiple-treepane-1.1.1.vsix`).

---

## 3. Pillar 1: Systematic README.md Synchronization

The root [`README.md`](file:///E:/proj/all-lads-tool/README.md) reflects high-level capabilities:
1. **Table of Contents**: Strictly reflects all numbered sections.
2. **Feature Index & Topology**: Accurately describes newly introduced architectural elements.
3. **Artifact Consistency**: Installation codeblocks (`code --install-extension ./out/...`) must match the exact SemVer in `package.json`.

---

## 4. Pillar 2: Comprehensive GUIDE.md Operational Alignment

[`GUIDE.md`](file:///E:/proj/all-lads-tool/GUIDE.md) is the complete technical manual:
1. **Operational Guide**: Detail command IDs, CLI switches, UI/UX interaction columns, and keybindings.
2. **Troubleshooting Matrix**: Record newly solved runtime failure modes (flex height stretching, lazy loading, CSP nonces) with root causes and prevention measures.

---

## 5. Pillar 3: Formulating "What Commit Message" (Canonical Protocol)

Commit messages must conform strictly to [`commit-convention`](file:///E:/proj/all-lads-tool/skill/commit-convention.md):

### 5.1 Canonical Header Pattern
```text
vxx-xx-xx context(ngapain): catatan
```
- **`vxx-xx-xx`**: 3-octet version matching the brief milestone (e.g., `v01-01-01`).
- **`context`**: Primary domain context (`file`, `repo`, `website`, `vscode`, `plugin`, `skill`, `combo`, `brief`).
- **`(ngapain)`**: Concise action phrase in parenthesis (e.g., `(multiple-treepane)`, `(polyclip-vscode-tree)`).
- **`: catatan`**: Short descriptive summary of the change.

### 5.2 Standard Multi-Line Commit Template
```text
vxx-xx-xx context(ngapain): catatan

### Summary of Changes
- Concise bullet points describing functional, UI, manifest, and doc changes.

### Root Cause / Motivation
- Technical explanation of what milestone was fulfilled per the architectural brief.

### File Manifest
- Modified: [path/to/file]
- Added:    [path/to/file]
- Cleaned:  [path/to/store]

### Verification & Safety
- Test results, packaging verification, and pre-commit status.
```

---

## 6. Pillar 4: The "DO NOT COMMIT YET" Quarantine Invariant

Following [`donot-commit-yet`](file:///E:/proj/all-lads-tool/skill/donot-commit-yet.md):

> [!CAUTION]
> **ABSOLUTE RULE FOR AGENTS**:
> Under NO circumstance may the agent run `git commit`, `git commit -m`, or append `&& git commit` to commands.
> All modifications must sit safely uncommitted in the working tree.
> The agent presents the proposed commit message inside a clean markdown codeblock, reports `git status -s`, and tells the user:
> *"Semua perubahan tersimpan di working tree (uncommitted). Do not commit yet — siap untuk Anda periksa dan approve."*

---

## 7. Execution Runbook (Step-by-Step for Agents)

When triggered:
```powershell
# Step 1: Discover active brief milestone
Get-ChildItem -Path "brief" -Filter "v*.md" | Sort-Object Name -Descending | Select-Object -First 1

# Step 2: Synchronize package.json / manifest.json version & script targets
# Step 3: Synchronize README.md and GUIDE.md
# Step 4: Verify working tree state without committing
git status -s

# Step 5: Present the proposed commit message to the user in a copyable codeblock
```
