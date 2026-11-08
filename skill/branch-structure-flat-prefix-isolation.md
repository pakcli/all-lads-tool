---
name: branch-structure-flat-prefix-isolation
aliases: [branch-structure-standard, git-branch-isolation, flat-branch-convention, fn-bn-branching-protocol]
category: VERSION_CONTROL_STANDARD
tags: [all-lads-tool, git, branching, flat-naming, frontend-isolation, backend-isolation, developer-sandbox]
description: Standardized flat Git branching convention enforcing role isolation (fn- for frontend, bn- for backend), a zero-slash flat hierarchy, personal developer sandboxes (main-<user>), and upstream backend containment (bn-homebox).
pros:
  - "Guarantees frontend developers are never blocked by broken backend builds or Docker setups"
  - "Enforces flat, terminal-friendly branch names with zero slash folder collisions"
  - "Provides safe personal developer sandboxes without risking main branch stability"
cons:
  - "Requires upfront discipline to periodically sync personal branches with main to prevent drift"
  - "Requires upfront agreement on canonical JSON contracts between fn- and bn-"
---

# 🌿 Git Branch Structure & Flat Role Isolation Protocol (`branch-structure-flat-prefix-isolation`)

> [!IMPORTANT]
> **THE FLAT ISOLATION MANDATE**:
> 1. **Zero Slash Folders**: Do NOT use slash-nested branches (`fn/...`, `bn/...`). Keep all branch names strictly flat using hyphenated prefixes (`fn-<feat>`, `bn-<feat>`).
> 2. **Frontend-Backend Decoupling**: Frontend work (`fn-`) must run 100% locally with mock JSON and never be blocked by backend Docker, Go, or database migration failures.
> 3. **Personal Sandbox Invariant**: Every developer has their own shadow branch (`main-<user>`) for rapid, messy iterations before merging polished work to `main`.

---

## 1. Branch Topology Overview

```text
main                               (Utama: Clean, stable integration trunk)
│
├── main-<user>                    (Personal Sandbox: e.g. main-<developer>)
│
├── fn-<feature>                   (Frontend: fn-3d-editor, fn-inventory-drawer)
│
├── bn-homebox                     (Upstream Backend Clone: Docker, Go, DB schemas)
└── bn-<feature>                   (Backend Services: bn-solver, bn-api-sync)
```

---

## 2. The 5 Core Branch Roles

### 1. `main` (Trunk Utama)
* **Status**: Production-ready, stable, and tested.
* **Invariant**: Must always build and run cleanly (`npm run build`, `npm run dev`).
* **Rule**: Direct unvetted commits to `main` are prohibited. All code enters via merged feature branches or personal sandboxes.

### 2. `main-<user>` (Personal Developer Sandbox)
* **Naming**: `main-<username>` (e.g. `main-dev`, `main-lead`).
* **Purpose**: Safe haven for rapid prototyping, messy save-points, and experimental code.
* **Sync Rule**: Must regularly pull/merge from `main` (every 2–3 days) to avoid long-term divergence:
  ```powershell
  git checkout main-<user>
  git merge main
  ```

### 3. `fn-<feature>` (Frontend Features)
* **Naming**: `fn-<domain>-<name>` (e.g. `fn-3d-editor`, `fn-inventory-table`, `fn-fitting-ui`).
* **Isolation Rule**: Runs strictly with client-side Vite/React and local mock JSON (`blueprint.json`).
* **Safety**: Frontend devs can code at 60 FPS without installing Docker, Go, or Postgres.

### 4. `bn-homebox` (Backend Reference & Upstream Clone)
* **Purpose**: Dedicated container for the raw or forked backend services (Go, `ent` ORM, Dockerfiles, SQLite/Postgres migrations).
* **Isolation Rule**: Heavy backend dependencies remain quarantined here. If a Docker build or database migration breaks, it **never** affects `main` or `fn-` branches.

### 5. `bn-<feature>` (Backend & Core Math Solvers)
* **Naming**: `bn-<domain>-<name>` (e.g. `bn-solver-obb`, `bn-api-sync`, `bn-csv-export`).
* **Purpose**: Focused development of computational geometry, math solvers, and external REST API sync adapters.

---

## 3. Strict Rules & Prohibitions

| Pattern | ❌ Prohibited | ✅ Standard | Rationale |
| :--- | :--- | :--- | :--- |
| **Folder Slashes** | `fn/3d-editor`, `bn/solver` | `fn-3d-editor`, `bn-solver` | Flat names prevent git worktree collisions and terminal autocompletion friction. |
| **Suffix Naming** | `3d-editor-frontend` | `fn-3d-editor` | Prefixing groups all frontend branches together in CLI and IDE dropdowns. |
| **Anonymous Dev** | `bn-dev-1`, `bn-dev-2` | `bn-dev-solver`, `bn-dev-schema` | Descriptive names eliminate confusion 2 weeks later. |
| **Dormant Sandbox** | Letting `main-<user>` drift 1 month | Merging `main` into `main-<user>` weekly | Prevents painful merge conflicts upon final PR. |

---

## 4. Typical Feature Lifecycle Workflow

```text
1. START NEW UI FEATURE:
   git checkout main
   git checkout -b fn-3d-catalog-bar

2. DEVELOP & TEST LOCALLY:
   (Code in React using local mock JSON — zero backend needed)
   npm test && npm run build

3. MERGE TO PERSONAL SANDBOX (FOR STAGING):
   git checkout main-<user>
   git merge fn-3d-catalog-bar

4. FINAL INTEGRATION TO UTAMA:
   git checkout main
   git merge main-<user>  # Or open Pull Request
   git branch -d fn-3d-catalog-bar
```

---

## 5. Checklist for Release & Branch Health

- [ ] All UI features use flat `fn-` prefix.
- [ ] All backend/service features use flat `bn-` prefix.
- [ ] No slash `/` nesting in branch names.
- [ ] Frontend builds and passes tests completely decoupled from backend containers.
- [ ] Personal branch `main-<user>` is rebased or merged with `main` at least once per week.
