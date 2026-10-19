---
trigger: always_on
description: RULE #001 — Modular Skills and Scripts ZERO Hardcoded Variables
---

# RULE — Modular Skills & Scripts: ZERO Hardcoded Variables

## 1. Core Invariant (The Zero-Hardcoding Mandate)
Every skill document (`.md`), automation script (`.js`, `.ps1`, `.bat`, `.py`), rule, and test suite in this repository must be **100% MODULAR, PORTABLE, AND CONTEXT-AGNOSTIC**.

> [!CAUTION]
> **ABSOLUTE PROHIBITIONS ACROSS ALL FILES**:
> 1. **ZERO Absolute Machine Paths**: Never hardcode disk letters or machine-specific directories (e.g. `D:\0pro\fadhlisl-my-id`, `C:\Users\fsl\...`, `d:/...`).
> 2. **ZERO Hardcoded Usernames & Session Environments**: Never assume the current user, local AppData path, or operating system directory structure.
> 3. **ZERO Hardcoded Application Lists**: Never hardcode static arrays of cartridges or filenames (e.g. `['family-quiz', 'lotek-offline', ...]`). All apps must be dynamically discovered from `_catalog.json` or live directory scans.
> 4. **ZERO Hardcoded Ports or Hostnames**: Never hardcode fixed dev server ports or localhost URLs without parameterization.

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
const apps = ['family-quiz', 'islam-memes', 'lotek-offline']; // REJECTED!
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

## 3. Enforcement & Verification Checklist
Before submitting or completing any code change:
- [ ] Scan modified files for drive letters (`D:\`, `C:\`, `d:/`, `c:/`). None must exist.
- [ ] Scan for hardcoded user names or user home directories. None must exist.
- [ ] Scan for static lists of cartridges. Dynamic discovery must be used instead.
- [ ] Test that the script or module executes cleanly from any arbitrary working directory.
