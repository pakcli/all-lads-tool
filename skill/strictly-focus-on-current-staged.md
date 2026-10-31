---
name: strictly-focus-on-current-staged
aliases: [strictly-focus-on-current-staged, focus-on-current-staged, staged-diff-ground-truth, no-hallucinated-milestones]
category: AGENT_BEHAVIOR_PROTOCOL
tags: [all-lads-tool, git, staging, discipline, truth, audit, commit]
description: Protocol requiring the agent to ground all commit messages, summaries, and version determinations strictly on what is currently staged in the Git index, prohibiting hallucinated future milestones or unstaged architecture.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Strictly Focus on Current Staged Protocol (`strictly-focus-on-current-staged`)

> [!IMPORTANT]
> **THE STAGED GROUND-TRUTH INVARIANT**:
> The agent MUST NEVER assume, guess, or invent features for commit messages, briefs, or status reports. 
> All versions, contexts, scopes, and descriptions **MUST BE DERIVED 100% EXCLUSIVELY FROM THE CURRENT STAGED INDEX** (`git diff --cached` / `git status --short`).

---

## 1. Core Principles

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   STAGED GROUND-TRUTH DISCIPLINE                       │
├────────────────────────────────────────────────────────────────────────┤
│ 1. INDEX IS TRUTH      : Only staged files exist for the commit        │
│ 2. SEQUENTIAL VERSION  : Increment strictly from git log -1 (no jumps) │
│ 3. ZERO FUTURE LEAKAGE : Prohibit mentioning unlaunched milestones     │
│ 4. LITERAL FILE AUDIT  : List actual files with commas, zero guessing  │
│ 5. REJECT HALLUCINATIONS: Reject concepts not in the physical diff    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. The 4 Non-Negotiable Rules

### Rule 1: Linear Version Progression (No Skipping Ahead)
- Always inspect the most recent commit in history first:
  ```powershell
  git log -1 --oneline
  ```
- If HEAD is at `v01-01`, the next commit is strictly **`v01-02`**.
- It is strictly forbidden to jump ahead to `v01-03` or later milestones before `v01-02` is committed and established in Git history.

### Rule 2: Physical Staging Inspection
- Never formulate a commit message from memory, conversational context, or planned roadmap items.
- Always run and read the physical staged file list:
  ```powershell
  git diff --cached --name-only
  ```
- If a file is not in the staged list, it **must not** appear in the commit message or summary.

### Rule 3: Zero Unlaunched / Future Milestone Leakage
- Prohibit referencing features, topologies, or concepts designed for upcoming milestones (e.g., claiming "adapters" or "5 domain contexts" when only runtime folders and baseline skills are currently staged).
- A commit message must only reflect what is physically changing in that specific atomic changeset.

### Rule 4: Comma-Separated Exact Filenames
- When listing files in multi-line commit bodies or scope details, use exact comma-separated filenames matching the staged index:
  ```text
  v01-02 add(git): _commit.ps1, _run.ps1, _mainmenu.ps1, git-manage.ps1
  
  add(skills): delete-permanent.md, delete-trash-bin-project-root.md
  ```

---

## 3. Mandatory 5-Step Grounding Workflow

```text
Step 1: Check Last Commit
        └── git log -1 --oneline -> Determines current milestone (e.g. v01-01)

Step 2: Compute Immediate Next Linear Version
        └── v01-01 -> Target Version: v01-02

Step 3: Extract Exact Staged File List
        └── git diff --cached --name-only

Step 4: Categorize Only Files Present in Output
        ├── Git / Tooling files -> add(git): <file1>, <file2>, ...
        └── Skill / Markdown files -> add(skills): <skill1>, <skill2>, ...

Step 5: Verify Zero Unstaged Architecture Leaks
        └── Ensure no roadmap/future terms leak into the message
```

---

## 4. Forbidden vs Mandatory Behaviors

| Context | ❌ FORBIDDEN (Hallucination & Leaks) | ✅ MANDATORY (Staged Ground Truth) |
| :--- | :--- | :--- |
| **Milestone Version** | Jumping from `v01-01` directly to `v01-03` | Sequential progression to `v01-02` |
| **Commit Scope** | Claiming "5 domain contexts" when only runtime scripts exist | Accurately describing only the staged runtime scripts |
| **Feature References** | Mentioning "adapter protocols" planned for next milestone | Describing only the deletion & catalog skills in the index |
| **File Listing** | Vague generic summaries ("updated various files") | Literal comma-separated filenames matching `git diff --cached` |
