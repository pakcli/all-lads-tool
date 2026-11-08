---
title: Universal Git Manager & Recovery Engine
tool: git-manage.ps1
category: repo & git
runtime: PowerShell 5.1+ / 7+
aliases: [git-manage, repo-manager, universal-git-manager]
tags: [all-lads-tool, repo, git, adapter, clone, options, recover, worktree, submodule]
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[git-clone-briefed-overview]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
---

# `git-manage.ps1` - Universal Git Manager (Context: Repo)

> [!INFO]
> **Context**: `repo` | **Executable**: `script/repo/git-manage.ps1`
> **Adapters**: `script/repo/adapter/git-core.psm1`, `script/repo/adapter/git-status.psm1`, `script/repo/adapter/git-reflog.psm1`, `script/repo/adapter/git-submodule.psm1`, `script/repo/adapter/git-worktree.psm1`
> **Canonical Documentation**: `docs/repo/git-manage.md` (Matches script filename 1:1)

Universal Git operations toolkit and recovery engine backed by modular adapters in `script/repo/adapter/`. Supports managing workspace roots, individual project subfolders, or external repositories with live repository inspection, reflog surgical recovery, conventional commit authoring, safe git unlinking, branch worktrees, and interactive cloning with pre-flight Briefed Overview.

---

## 1. Quick Syntax & Usage

```powershell
# Interactive master cockpit in active repository / last saved target
.\all-lads-tool\script\repo\git-manage.ps1

# Target a specific repository or cartridge path
.\all-lads-tool\script\repo\git-manage.ps1 -TargetDir "e:\proj\web-app_sims-homebox"

# Direct headless action invocation
.\all-lads-tool\script\repo\git-manage.ps1 -Action "status"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "recover"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "commit"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "push"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "pull"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "discard"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "assign"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "remove"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "clone"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "worktree"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "shell"
.\all-lads-tool\script\repo\git-manage.ps1 -Action "submodule"
```

---

## 2. Command Matrix (-1 to 9, 11 & Footer)

| Key | Action | Description | Safety Level |
| :--- | :--- | :--- | :--- |
| `[-1]` | **Discard All** | Reverts uncommitted changes (`git restore .` + `git clean -fd`) | Protected (requires typing `DISCARD`) |
| `[ 0]` | **Status** | Live dashboard of branch, remotes, dirty file counts, and recent commits | Read-Only |
| `[ 1]` | **Recover** | Reflog browser with detached commit detection & surgical/full restore | Non-destructive preview |
| `[ 2]` | **Commit** | Status preview, staging options (All/Selective), & Conventional Commit prefix helper | Standard |
| `[ 3]` | **Push** | Pushes active branch to upstream remote with auto tracking setup | Standard |
| `[ 4]` | **Pull / Sync** | Smart pull (Rebase, Fast-Forward only, or Merge) | Standard |
| `[ 5]` | **Assign Git** | Initializes Git repo (`git init -b main/pakcli`), adds remote, creates `.gitignore`, initial commit | Safe |
| `[ 6]` | **Remove Git** | "Remove with more nicer": Unlocks ReadOnly/hidden attributes, cleans locks, deletes `.git` cleanly | Protected (requires typing `REMOVE`) |
| `[ 7]` | **Clone** | Clones external repo into target directory or designated subfolder with pre-flight card | Standard |
| `[ 8]` | **Worktree** | Manages isolated worktree branches (`list`, `add`, `remove`, `prune`) | Safe |
| `[ 9]` | **Custom Shell** | Runs arbitrary git commands or executes drag & dropped scripts (`.ps1`, `.bat`, `.js`, `.py`) | Standard |
| `[11]` | **Submodule** | Interactive Git Submodule Hub (list, add, remove, sync) | Standard |
| `[ h]` | **Help** | Displays full guide and shortcut instructions | Read-Only |
| `[ t]` | **Switch Target** | Switch target directory (workspace root, sibling repos, or drag & drop path) | Interactive |
| `[ q]` | **Quit** | Exits the interactive manager | Read-Only |

---

## 3. Detailed Feature Breakdown

### Action [-1]: Discard All Changes
- Displays uncommitted and untracked files with color status.
- Protected by mandatory prompt typing `DISCARD`.
- Executes `git restore .`, `git checkout -- .`, and `git clean -fd`.

### Action [0]: Status Dashboard
- Scans working tree using `adapter/git-status.psm1`.
- Displays active branch, remotes, dirty file counts, and total dirty file size in KB.
- Pretty-prints recent 5 commits with hashes and timestamps.

### Action [1]: Reflog Commit Recovery
- Evaluates recent reflogs via `adapter/git-reflog.psm1`.
- Identifies detached/lost commits versus reachable branched commits.
- Inspects changed files within selected commit and offers:
  1. *Simple overwrite all*: Restores all commit files into working tree.
  2. *Per-file overwrite*: Interactive prompt per modified file (`1` = overwrite, `0` = skip).

### Action [2]: Commit Assistant
- Live uncommitted change preview.
- Staging mode selection: Stage all (`git add -A`) or selective per-file staging.
- Conventional Commit prefix builder (`feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `style:`, or custom raw message) with optional scope prompting.

### Action [3]: Push
- Verifies branch is not detached.
- Inspects upstream tracking status and pushes with `--set-upstream` automatically when required.

### Action [4]: Pull / Sync
- Offers 3 synchronization strategies:
  1. Rebase (`git pull --rebase` for clean linear history).
  2. Fast-forward only (`git pull --ff-only`).
  3. Standard merge (`git pull`).

### Action [5]: Assign Git (Initialize Repository)
- Creates fresh Git repository using default branch `main/pakcli`.
- Automatically provisions standard `.gitignore` template if absent (`node_modules/`, `dist/`, `build/`, `*.log`, `*.tmp`, `*.bak`).
- Optionally configures remote `origin` and creates initial commit.

### Action [6]: Remove Git (Safe Unlink - "Remove with more nicer")
- Cleanly strips `.git` directory without harming working project files.
- Strips Read-Only, System, and Hidden attributes across `.git` using `attrib -r -s -h`.
- Purges lingering `index.lock` and `HEAD.lock` files.
- Gated by mandatory uppercase confirmation `REMOVE`.

### Action [7]: Git Clone Wizard
- Ingests HTTPS, SSH, GitHub CLI (`gh repo clone`), or short slugs (`owner/repo`).
- Auto-detects repository URLs copied to the system clipboard.
- Pre-flight Briefed Overview card displays resolved URL, destination path, branch, and shallow depth.
- Explicit `y`/`yes` confirmation gating before running `git clone`.

### Action [8]: Worktree Management
- Powered by `adapter/git-worktree.psm1`.
- Lists active worktrees with branches and commit heads.
- Allows provisioning isolated worktree branches into dedicated subfolders (`../wt-<branch>`).
- Safely removes and prunes stale worktrees.

### Action [9]: Custom Shell / Script Runner
- Interactive command prompt scoped to target directory.
- Runs arbitrary git/cmd commands or executes dragged-and-dropped script files (`.ps1`, `.bat`, `.cmd`, `.js`, `.py`).

### Action [11]: Submodule Hub
- Connects to `script/repo/git-submodule.ps1` and `adapter/git-submodule.psm1`.
- Headless and interactive listing, addition, unlinking, and recursive updating of submodules.

---

## 4. Retargeting Protocol & `_run.json` Synchronization

- `[ t ] Switch Target`: Discovers sibling Git repositories in workspace root.
- Allows switching active focus without restarting the process.
- Persists chosen repository target into `_run.json` (`targetDir`) so all sibling scripts inherit the updated target.
- Fully supports drag-and-drop paths directly onto prompt inputs.
