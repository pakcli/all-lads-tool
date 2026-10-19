---
name: lifecycle-development
description: >-
  Enforce granular commit lifecycle management and version bumping (v01_00 baseline -> v01_01 minor commit bump -> v02_00 major milestone bump) for the Vintage Computing Arcade. Use whenever staging changes, creating commits, tagging milestones, or updating architectural briefs.
---

# 🔄 Lifecycle Development & Granular Version Bumping

This skill guides the agent and developer in maintaining a disciplined, granular, atomic commit lifecycle for `fadhlisl-my-id`. Every small change is recorded with an incremental micro-version tag, ensuring transparent progression, zero-ambiguity rollbacks, and synchronized documentation.

---

## 1. Versioning Hierarchy & Rules

The project adopts a two-tier semantic numbering convention formatted as **`v{MAJOR}_{MINOR}`**:

```text
v01_00  ──(Initial Master Architecture Baseline)
  │
  ├── v01_01  (Small atomic commit: e.g. Sticky navbar auto-hide)
  ├── v01_02  (Small atomic commit: e.g. 2-layer beveled corner pin)
  ├── v01_03  (Small atomic commit: e.g. Mobile 2-row navbar layout)
  ├── v01_04  (Small atomic commit: e.g. Floating 2x2 Quick Nav Pod)
  └── v01_05  (Small atomic commit: e.g. Dynamic standalone.md parser)
  │
v02_00  ──(Major Milestone Release / Subsystem Completion)
  │
  ├── v02_01  (First small commit of Milestone 2)
  └── ...
```

### A. Baseline Version: `v01_00`
- The baseline starting point is **`v01_00`**, corresponding to the master architecture brief `brief/v01_00_architecture.md`.

### B. Micro Commit Bumps (`v01_01`, `v01_02`, ...)
- **Trigger**: Every small, atomic development task (single feature addition, styling fix, component extraction, router adjustment).
- **Rule**: Minor counter increments by 1 with two-digit zero padding (`_01`, `_02`, ..., `_10`, `_11`).
- **Git Commit Message Format**:
  ```text
  v01_XX: <type>(<scope>): <concise description>
  ```
- **Standard Types**:
  - `feat`: New feature or component logic.
  - `fix`: Bug fix or styling glitch patch.
  - `style`: Visual adjustment, theme token update, layout polish.
  - `refactor`: Code reorganization without changing external behavior.
  - `docs`: Brief or technical documentation update.

### C. Major Milestone Bumps (`v02_00`, `v03_00`, ...)
- **Trigger**: Completion of a major architectural phase, milestone release, or fundamental restructuring.
- **Rule**: Major counter increments by 1, minor counter resets to `_00`.
- **Brief Rule**: When a major version bumps, synchronize or create the corresponding brief file (e.g. `brief/v02_00_architecture.md`).
- **Git Commit Message Format**:
  ```text
  v02_00: feat(release): <major milestone summary>
  ```

---

## 2. State Storage in `main.json`

The current version state is tracked in `main.json` under the `"versioning"` object:

```json
{
  "versioning": {
    "current": "v01_00",
    "major": 1,
    "minor": 0,
    "lastCommit": "v01_00: baseline master architecture",
    "updatedAt": "2026-10-16T22:37:00+07:00"
  }
}
```

Whenever a commit is prepared, the helper script or agent reads `main.json`, increments the target segment, writes back the updated version, and uses that tag in the commit message.

---

## 3. Automation Tooling (`bump-version.ps1`)

The companion PowerShell script `all-script/powershell/bump-version.ps1` automates this lifecycle:

```powershell
# Bump minor version (v01_00 -> v01_01) and commit:
.\all-script\powershell\bump-version.ps1 -Type minor -Message "feat(nav): add auto-hide scroll listener"

# Bump major version (v01_XX -> v02_00) and commit:
.\all-script\powershell\bump-version.ps1 -Type major -Message "feat(release): complete public bundle distribution"

# Or through the universal dispatcher:
.\main.ps1 -Run bump
```

---

## 4. Agent Execution Guidelines

When working on coding tasks in this repository, the agent MUST:
1. Always prefix git commits with the current bumped version tag (`v01_XX:` or `v02_00:`).
2. Keep commits atomic and small (1 commit per logical step, bumping minor sequentially).
3. Ensure brief files match the active version scope (e.g., `brief/v01_00_architecture.md` for the v01 era).
4. Update `main.json` to keep the versioning state synchronized.
