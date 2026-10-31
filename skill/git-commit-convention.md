---
description: RULE #008 — Git Commit Message Convention with 3-Octet Version Prefix and Context Scope
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE #008 — Git Commit Message Convention (`vxx-xx-xx context(ngapain): catatan`)

> [!IMPORTANT]
> **CANONICAL COMMIT MESSAGE FORMAT**:
> Every commit message in this repository must strictly follow the format:
> `vxx-xx-xx context(ngapain): catatan`

---

## 1. Syntax Breakdown

$$\text{vxx-xx-xx context(ngapain): catatan}$$

```text
v01-03-00 file(csv-parse): fix negative number coordinate parsing
│         │    │          │
│         │    │          └── Catatan / ringkasan perubahan spesifik
│         │    └── Action / apa yang sedang dilakukan (ngapain)
│         └── Domain context (file, repo, website, blender, unity, brief, rule, skill)
└── Version prefix (3-octet: v<MAJOR>-<MINOR>-<PATCH>)
```

### Components:
1. **Version Prefix (`vxx-xx-xx`)**:
   - 3-octet format matching active project/milestone version (e.g. `v01-00-00`, `v01-03-00`, `v01-03-01`).
2. **Context**:
   - The primary domain or architectural context being touched:
     - `file`
     - `repo`
     - `website`
     - `blender`
     - `unity`
     - `brief`
     - `rule`
     - `skill`
3. **Action / Scope (`(ngapain)`)**:
   - Enclosed in parentheses immediately following context. Explains the operational action (e.g. `(add-adapter)`, `(fix-path)`, `(update-gui)`, `(refactor)`).
4. **Notes / Description (`: catatan`)**:
   - Clear, concise explanation of the change in lowercase.

---

## 2. Examples by Context

| Context | Example Commit Message |
| :--- | :--- |
| **file** | `v01-03-00 file(csv-to-frontmatter): add pipe delimiter coordinate parser` |
| **repo** | `v01-03-00 repo(git-branch-rename): support flat branch naming convention` |
| **blender** | `v01-03-00 blender(adapter): add v04-02-00 self-contained api checker and exporter` |
| **unity** | `v01-03-00 unity(importer): automate meta file cleanup for models` |
| **website** | `v01-03-00 website(bundler): compile es modules without framework bloat` |
| **rule** | `v01-03-00 rule(commit-convention): enforce vxx-xx-xx context(ngapain) pattern` |
| **brief** | `v01-03-00 brief(foldering): document v01-03 adapter-based architecture` |

---

## 3. Prohibited Formats

❌ `git commit -m "update code"` *(Missing version, context, and action)*  
❌ `git commit -m "feat(file): fix stuff"` *(Missing vxx-xx-xx version prefix)*  
❌ `git commit -m "v01-03: file(fix): notes"` *(Must use 3-octet vxx-xx-xx)*  
❌ `git commit -m "v01-03-00: fix file notes"` *(Missing context(ngapain) structure)*  

---

## 4. Verification Checklist

- [ ] Does the commit message start with `vxx-xx-xx`?
- [ ] Is there a valid context (`file`, `repo`, `website`, `blender`, `unity`, `rule`, `brief`, `skill`)?
- [ ] Is the action enclosed in parentheses `(ngapain)`?
- [ ] Is the description clear after the colon `: `?
