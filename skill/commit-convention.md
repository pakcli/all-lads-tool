---
name: commit-convention
aliases: [git-commit-convention, commit-format-standard]
category: VERSION_CONTROL
tags: [all-lads-tool, git, commit, convention, versioning]
description: SOP and specification for creating git commit messages following the vxx-xx-xx context(ngapain): catatan standard.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Git Commit Convention Skill (`commit-convention`)

When creating, formatting, or amending Git commits in `all-lads-tool`:

## 1. Canonical Pattern

```text
vxx-xx-xx context(ngapain): catatan
```

## 2. Context Options
- `file` : CSV, frontmatter, text manipulation, dry-run
- `repo` : Git manager, branch rename, submodules
- `website` : Bundlers, stylesheets, DOM, thumbnails
- `blender` : 3D models, batch exports, python adapters
- `unity` : C# editor scripts, meta files, asset importer
- `rule` : Architectural invariants (`rule/`)
- `skill` : Agent procedures and protocols (`skill/`)
- `brief` : Concepts, topology, and milestones (`brief/`)

## 3. Concrete Command Example
```powershell
git commit -m "v01-03-00 file(csv-parse): fix negative number coordinate parsing"
```
