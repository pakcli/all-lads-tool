---
trigger: always_on
description: RULE #009 — Commit Message Convention with 2-Octet Version Prefix
---

# RULE #9 — Standardized Commit Message Convention

All git commit messages in this repository must strictly adhere to the structured conventional commit standard, prefixed by the active **2-octet project version** (`v0x-0x`).

---

## 1. Canonical Commit Message Structure

```text
v<MAJOR>-<MINOR>: <type>(<scope>): <short imperative description>

[optional body explaining motivation, context, and changes]

[optional footer referencing issues, lineage records, or breaking changes]
```

### Key Elements:
1. **Version Prefix (`v0x-0x:`)**:
   - Must match the current active project version declared at the root level of `.agent.json` (e.g., `v01-03:`).
   - Strictly 2 octets (`0x-0x`). Never use 3 octets (e.g. prohibited: `v01-03.1`).
2. **Type**:
   - Must be one of the 6 standard lowercase types: `feat`, `fix`, `refactor`, `docs`, `chore`, `build`.
3. **Scope (Optional but Strongly Recommended)**:
   - Identifies the module, component, or subsystem modified, enclosed in parentheses.
   - Examples: `(catalog)`, `(playground)`, `(nav)`, `(theme)`, `(skills)`, `(thumbnails)`, `(rules)`.
4. **Subject**:
   - Concise, imperative summary (e.g., "add", "update", "remove", "prevent" — NOT "added" or "adding").
   - Maximum 72 characters, lowercase start, no trailing period.

---

## 2. The 6 Standard Commit Types

| Type | Purpose & Scope | Example |
| :--- | :--- | :--- |
| **`feat`** | Introduces a new feature, component, user capability, or page | `v01-03: feat(thumbnails): add modular playwright webp capture pipeline` |
| **`fix`** | Patches a bug, styling glitch, contrast failure, or runtime error | `v01-03: fix(mobile): enforce zero horizontal scroll on portrait grid` |
| **`refactor`** | Restructures code without changing behavior or adding new features | `v01-03: refactor(skills): make path resolution dynamic across verification scripts` |
| **`docs`** | Updates documentation, architectural briefs, rules, or skill guides | `v01-03: docs(brief): synchronize v01-03 bento layout brief with webp thumbnails` |
| **`chore`** | Maintenance, lineage audits, permissions, tool configs, housekeeping | `v01-03: chore(lineage): record skill execution audit in .agent.json` |
| **`build`** | Build system, compilers, minifiers, bundlers, dependency runners | `v01-03: build(bundle): update build-bundle.js compiler passes and catalog generation` |

---

## 3. Concrete Commit Examples by Type

### `feat`
```text
v01-03: feat(catalog): implement dynamic sector meta filtering from _catalog.json
```

### `fix`
```text
v01-03: fix(playground): resolve iframe pointer interception during split resize
```

### `refactor`
```text
v01-03: refactor(catalog-core): extract detectCategoryCounts helper into pure function
```

### `docs`
```text
v01-03: docs(rules): author rule 009 commit convention specification
```

### `chore`
```text
v01-03: chore(permission): establish .agent-execution-permission.json security policy
```

### `build`
```text
v01-03: build(terser): configure module mangling passes for production distribution
```

---

## 4. Multi-Line Commit Format (Body & Lineage References)

For complex atomic commits requiring explanatory context:

```text
v01-03: feat(thumbnails): integrate automated playwright webp capture

- Render 1280x800 desktop snapshots saved to public/assets/thumbnails/<slug>.webp
- Support host chrome/msedge channel fallback with zero binary download requirement
- Wire up retro [preview not found] fallback badge in catalog-core.js
- Audit applied skill playwright-thumbnail-capture in .agent/.agent.json
```

---

## 5. Non-Negotiable Invariants

> [!CAUTION]
> **REJECTED COMMIT FORMATS**:
> - ❌ `git commit -m "fix stuff"` (Missing version, type, and scope)
> - ❌ `git commit -m "v01.03.2: update files"` (Three octets are prohibited; use `v01-03:`)
> - ❌ `git commit -m "v01-03: FEAT: new thing"` (Type must be lowercase: `feat`)
> - ❌ `git commit -m "v01-03: feat: added thumbnail"` (Use imperative mood: `add`, not `added`)
> - ❌ Any commit referencing hardcoded local machine paths (`D:\...`, `C:\...`).
