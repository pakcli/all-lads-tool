---
name: codebase-compliance-audit
description: Authoritative protocol and automated checklist for auditing codebase compliance against Rule #000, Rule #001 (Zero Hardcoded Variables), Rule #002 (Mobile Zero Scroll), Rule #003 (Immutable Theme), Rule #004 (Strict Naming), and UI/UX Monospace ASCII standards.
category: AUDIT_AND_COMPLIANCE
tags: [all-lads-tool, audit, compliance, verification, quality-gate]
---

# 🛡️ Codebase Compliance Audit Skill (`codebase-compliance-audit`)

This skill defines the authoritative, automated verification protocol for auditing the codebase before any milestone release or version bump.

It ensures that all files strictly comply with repository architectural invariants, preventing path leaks, broken layouts, and formatting regressions.

---

## 1. The 6 Core Audit Invariants

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   CODEBASE COMPLIANCE AUDIT GATEWAY                    │
├────────────────────────────────────────────────────────────────────────┤
│ [1] Rule #001 : ZERO Hardcoded Paths & Machine Drives (D:\, C:\)       │
│ [2] Rule #004 : Strict Kebab-Case Naming Across Files & Directories    │
│ [3] Obsidian  : ZERO Quotes in YAML Frontmatter Properties             │
│ [4] UI/UX     : Monospace ASCII Alignment, <=80 Cols, Zero Wide Emojis │
│ [5] Rule #003 : Immutability of Master Theme CSS (0 Edits Allowed)     │
│ [6] Rule #002 : Mobile Viewport Zero Horizontal Scroll (Portrait)      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Invariant Specifications

### 2.1 Invariant 1: Rule #001 (Zero Hardcoded Paths)
* **Check**: No file may contain hardcoded drive letters (`D:\`, `C:\`, `d:/`, `c:/`) or user home directories.
* **Prohibited**:
  ```javascript
  const p = 'D:\\0pro\\fadhlisl-my-id\\apps'; // VIOLATION!
  ```
* **Required**: Dynamic resolution via relative path traversal:
  ```javascript
  const repoRoot = path.resolve(__dirname, '..', '..');
  const appsDir = path.join(repoRoot, 'apps');
  ```

---

### 2.2 Invariant 2: Rule #004 (Strict Kebab-Case Naming)
* **Check**: All files and directories must use lowercase kebab-case (`lower-case-with-hyphens`).
* **Exceptions**: Top-level project files (`README.md`, `BUILD_REPORT.md`, `.gitignore`).
* **Prohibited**: PascalCase (`BundleProcessor.ps1`), camelCase (`buildBundles.js`), or spaces.
* **Required**: `bundle-processor.ps1`, `build-bundles.js`.

---

### 2.3 Invariant 3: Obsidian Native YAML Frontmatter
* **Check**: YAML frontmatter keys must **NEVER** be wrapped in double quotes (`"..."`).
* **Prohibited**:
  ```yaml
  title: "My Application"
  description: "Some description"
  ```
* **Required**:
  ```yaml
  title: My Application
  description: Some description
  ```

---

### 2.4 Invariant 4: UI/UX Monospace ASCII Wireframe Standards
* **Check**: Monospace text codeblocks (````text` / ````ascii`):
  1. **Strict Monospace Boundary**: Every bordered line in a box must have identical character length.
  2. **Width Budget**: Desktop `<= 80` columns; Mobile portrait `<= 60` columns.
  3. **Zero Wide Emojis in Boxes**: Variable-width glyphs (e.g., 🔥, 💾, 📱) render inconsistently (1 vs 2 cols). Use standard ASCII glyphs (`[*]`, `[+]`, `[x]`, `>`).

---

### 2.5 Invariant 5: Rule #003 (Theme CSS Immutability)
* **Check**: `src/theme/theme.css` and `public/theme.css` must remain 100% untouched.
* **Enforcement**: Verify git diff on theme CSS files. If modified without explicit user authorization, revert immediately.

---

### 2.6 Invariant 6: Rule #002 (Mobile Zero Horizontal Scroll)
* **Check**: Mobile viewport (`320px – 768px`) must not produce horizontal overflow.
* **Enforcement**: Containers must declare `overflow-x: clip;` or `minmax(0, 1fr)`.

---

## 3. Automated Audit Engine (`audit-codebase.js`)

To perform a 100% automated audit, execute the companion audit script:

```bash
node all-lads-tool/script/javascript/audit-codebase.js
```

### Programmatic Scan Implementation:
```javascript
// Scan all files recursively
const files = getAllFiles(targetDir);

// 1. Audit absolute paths (Rule #001)
const driveRegex = /(?:^|[^\w\/:])([A-Za-z]:[\\\/](?!$))/;

// 2. Audit naming (Rule #004)
const namingRegex = /[A-Z\s]/;

// 3. Audit YAML quotes
const yamlQuoteRegex = /^[\w-]+:\s*["'][^"']+["']\s*$/;

// 4. Audit ASCII wireframes (Width > 80 cols or wide emojis inside boxes)
const emojiRegex = /[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF]/;
```

---

## 4. Verification & Audit Sign-Off Checklist

Before merging, committing, or deploying:
- [ ] Run `node all-lads-tool/script/javascript/audit-codebase.js` and verify **0 violations**.
- [ ] Run `node src/modules/build-bundle.js` and verify **100% clean build**.
- [ ] Record audit lineage in `.agent/.agent.json`.
