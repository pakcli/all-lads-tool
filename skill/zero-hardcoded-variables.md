---
description: RULE #001 — Modular Skills and Scripts ZERO Hardcoded Variables
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# RULE — Modular Skills & Scripts: ZERO Hardcoded Variables

## 1. Core Invariant (The Zero-Hardcoding Mandate)
Every skill document (`.md`), automation script (`.js`, `.ps1`, `.bat`, `.py`), rule, and test suite in this repository must be **100% MODULAR, PORTABLE, AND CONTEXT-AGNOSTIC**.

> [!CAUTION]
> **ABSOLUTE PROHIBITIONS ACROSS ALL FILES**:
> 1. **ZERO Absolute Machine Paths**: Never hardcode disk letters or machine-specific directories (e.g. `<DRIVE>:\<dir>\<project>`, `<DRIVE>:\Users\<user>\...`, `<drive>:/...`).
> 2. **ZERO Hardcoded Usernames & Session Environments**: Never assume the current user, local AppData path, or operating system directory structure.
> 3. **ZERO Hardcoded Application Lists**: Never hardcode static arrays of cartridges or filenames (e.g. `['<app-a>', '<app-b>', ...]`). All apps must be dynamically discovered from `_catalog.json` or live directory scans.
> 4. **ZERO Hardcoded Ports or Hostnames**: Never hardcode fixed dev server ports or localhost URLs without parameterization.
> 5. **ZERO Direct Edits to `node_modules` or External Libraries**: Never edit files inside `node_modules/`, third-party packages, vendor libraries, or external upstream core modules directly. All modifications must be implemented via configurations, official plugin hooks, local wrapper modules, or project-level styling.

---

## 2. Mandatory Implementation Standards

### 2.1 Dynamic Repository Root Resolution
In Node.js scripts:
```javascript
// ALWAYS resolve repository root dynamically from __dirname:
const path = require('path');
const scriptDir = __dirname;
const repoRoot = path.resolve(scriptDir, '..', '..'); // or appropriate relative depth
const appsDir = path.join(repoRoot, 'apps');
const publicDir = path.join(repoRoot, 'public');
```

In PowerShell scripts:
```powershell
# ALWAYS resolve repository root dynamically from $PSScriptRoot:
$scriptDir = $PSScriptRoot
$repoRoot = Resolve-Path (Join-Path $scriptDir "..\..")
$appsDir = Join-Path $repoRoot "apps"
$publicDir = Join-Path $repoRoot "public"
```

In Python scripts:
```python
# ALWAYS resolve repository root dynamically from __file__:
from pathlib import Path
script_dir = Path(__file__).resolve().parent
repo_root = script_dir.parent.parent
apps_dir = repo_root / "apps"
public_dir = repo_root / "public"
```

---

### 2.2 Dynamic Resource Discovery (No Static App Arrays)
All scripts, test suites, and catalog engines must discover cartridges dynamically:

```javascript
// CORRECT: Dynamic discovery from SSOT (_catalog.json) or directory scan
const catalogPath = path.join(publicDir, 'apps', '_catalog.json');
let apps = [];

if (fs.existsSync(catalogPath)) {
  apps = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
} else {
  apps = fs.readdirSync(appsDir)
    .filter(f => f.endsWith('.md'))
    .map(f => ({ slug: f.replace(/\.md$/, '') }));
}
```

```javascript
// FORBIDDEN (VIOLATION OF THIS RULE):
const apps = ['<app-a>', '<app-b>', '<app-c>']; // REJECTED!
```

---

### 2.3 URL & File Path Normalization
When constructing browser `file:///` URLs or web paths, never use platform-specific backslashes:
```javascript
// CORRECT: Safe forward-slash conversion for browser URLs:
const fileUrl = `file:///${filePath.replace(/\\/g, '/')}`;
```

---

### 2.4 Skill & Rule Documentation Standards
When authoring or updating skill files (`all-lads-tool/skill/*.md` or `.agent/skills/*.md`):
- Use repository-relative paths: `apps/`, `src/modules/`, `public/apps/_catalog.json`.
- Never include machine-specific drive letters or user home directories in code snippets, shell examples, or architecture diagrams.
- All code samples provided to the AI programmer agent must illustrate dynamic path resolution.

---

### 2.5 Prohibition Against Mutating `node_modules` or External Libraries
Files located within `node_modules/` or third-party vendor directories are strictly ephemeral and ignored by version control. Any direct edits to installed packages will:
- Be permanently wiped on `npm install` or `npm ci`.
- Cause irreproducible, silent build discrepancies between local development and cloud CI/CD runners (such as GitHub Actions).
- Violate codebase portability and upstream upgradability.
Always extend external packages through public configuration files, plugin extensions, or local wrapper modules.

---

## 3. Enforcement & Verification Checklist
Before submitting or completing any code change:
- [ ] Scan modified files for drive-letter paths (regex `\b[A-Za-z]:[\\/]`, any letter, either slash). None must exist.
- [ ] Scan for hardcoded user names or user home directories. None must exist.
- [ ] Scan for static lists of cartridges. Dynamic discovery must be used instead.
- [ ] Test that the script or module executes cleanly from any arbitrary working directory.
- [ ] Ensure zero files inside node_modules/ or external libraries were touched or edited.
