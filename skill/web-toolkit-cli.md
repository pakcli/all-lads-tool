---
name: web-toolkit-cli
description: Modular cross-platform developer toolchain and Playwright automation engine for web extraction, headless inspection, video/screenshot recording, and interactive overlay guides.
category: AUTOMATION_AND_TESTING
tags: [all-lads-tool, playwright, web-toolkit, extraction, recording, automation]
---

# 🌐 Modular Playwright Web Toolkit CLI Skill (`web-toolkit-cli`)

This skill defines the authoritative architecture, runtime invariants, and execution protocols for **Web Toolkit** (`all-lads-tool/script/javascript/web-toolkit/`), a modular cross-platform automation engine powered by Playwright and Node.js.

It consolidates headless DOM extraction, session-authenticated review harvesting, viewport recording, and on-page step guides into a unified, extensible CLI.

---

## 1. Architectural Invariants & Compliance Rules

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   WEB TOOLKIT CORE INVARIANT SUITE                     │
├────────────────────────────────────────────────────────────────────────┤
│ [1] Rule #000 : 4 Pillars isolation; zero hard dependency on web app   │
│ [2] Rule #001 : ZERO hardcoded drives (D:\, C:\), users, or ports      │
│ [3] Rule #004 : Strict lowercase kebab-case naming for all modules     │
│ [4] Platform  : Cross-platform (Windows, macOS, Linux) with preflight  │
│ [5] Session   : Persistent profile auth; tokens never committed in git │
│ [6] Fail-Safe : Zero empty CSVs; fail loudly with descriptive errors   │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Rule #000 (Decoupled Toolchain)**:
   - The toolkit lives inside `script/javascript/web-toolkit/` or `script/web-toolkit/`.
   - Core application logic (`src/`, `apps/`, `public/`) must never depend on or import this toolkit.

2. **Rule #001 (Zero Hardcoded Variables)**:
   - All paths are resolved dynamically using `path.resolve(__dirname, ...)` and relative traversal.
   - Disk drive letters (`D:\`, `C:\`, `d:/`, `c:/`) and personal usernames are strictly prohibited.
   - Output paths default to relative `./output/` and are overridable via `.env`.

3. **Rule #004 (Strict Kebab-Case)**:
   - All modules inside `modules/` must be named strictly in lowercase kebab-case (e.g. `extract.js`, `record.js`, `overlay.js`).
   - Module IDs must be lowercase kebab-case strings matching the filename.

4. **Security & Session Hygiene**:
   - Authentication states (`auth/profile/`, `auth/state.json`) and run artifacts (`debug/`, `output/`) are excluded via `.gitignore`.
   - Sensitive user tokens or email addresses must follow the Privacy Default Masking Protocol (2-letter rule: `dc******@gmail.com`).

---

## 2. Directory Topology

```text
all-lads-tool/
├── skill/
│   └── web-toolkit-cli.md       <-- Agent skill & runbook
├── docs/
│   └── javascript/
│       └── web-toolkit.md       <-- Technical reference docs
└── script/
    └── javascript/
        └── web-toolkit/
            ├── package.json     <-- Manifest (playwright ^1.64)
            ├── web-toolkit.js   <-- CLI entry & interactive menu
            ├── lib/
            │   ├── platform.js  <-- OS detection (win/mac/linux)
            │   ├── preflight.js <-- Environment readiness
            │   ├── browser.js   <-- Persistent context launcher
            │   ├── config.js    <-- Env variable loader
            │   └── csv-writer.js<-- RFC-4180 BOM-safe CSV
            ├── modules/
            │   ├── extract.js   <-- Reviews & DOM extractor
            │   ├── record.js    <-- Video & screenshot capture
            │   └── overlay.js   <-- Interactive step guide
            └── fixtures/
                └── review-sample.txt
```

---

## 3. Cross-Platform OS Detection Protocol (`lib/platform.js`)

The toolkit inspects the host platform dynamically at startup using `process.platform`:

```javascript
// Dynamic platform normalization
const os = require('os');
const platformId = process.platform; // 'win32' | 'darwin' | 'linux'

const platform = {
  id: platformId,
  name: platformId === 'win32' ? 'Windows' : platformId === 'darwin' ? 'macOS' : 'Linux',
  isWin: platformId === 'win32',
  isMac: platformId === 'darwin',
  isLinux: platformId === 'linux',
  arch: process.arch,
  hasDisplay: platformId !== 'linux' || Boolean(process.env.DISPLAY || process.env.WAYLAND_DISPLAY),
  openCmd: platformId === 'win32' ? 'start' : platformId === 'darwin' ? 'open' : 'xdg-open',
  shell: platformId === 'win32' ? 'powershell' : 'bash'
};
```

### Headless & Display Fallback Invariants
- On Linux headless servers without display servers (`hasDisplay === false`):
  - Headed `login` command displays an explicit warning and guidance.
  - CLI operations force `HEADLESS=true`.
  - Folder opening commands gracefully no-op without uncaught process errors.

---

## 4. Preflight Verification Engine (`lib/preflight.js`)

Before displaying the interactive menu or executing commands, `preflight.js` verifies:
1. **Node.js Runtime**: Must be `>= v18.0.0`.
2. **Playwright Module**: Checks presence in local `node_modules/playwright`. If absent, guides user to install without executing unauthorized commands.
3. **Browser Binary**: Validates Chromium executable availability via Playwright registry.
4. **Environment Banner**: Prints concise single-line system readiness:
   ```text
   [env] Windows 11 (win32) | Node v20.12.0 | Playwright 1.64.1 | Chromium OK
   ```

---

## 5. Modular Plug-and-Play Contract

Every module dropped into `modules/<name>.js` automatically registers into the interactive dispatcher without altering core logic:

```javascript
module.exports = {
  id: 'extract',
  title: 'extract',
  description: 'DOM/text -> CSV (Obsidian reviews & table data)',
  version: '01-01',
  minCore: '01-00',
  platforms: ['win32', 'darwin', 'linux'], // Supported environments

  /**
   * Execution lifecycle
   * @param {Object} ctx - Shared context
   * @param {import('playwright').Page} ctx.page
   * @param {import('playwright').BrowserContext} ctx.browserContext
   * @param {Object} ctx.config - Resolved .env variables
   * @param {Object} ctx.platform - Host OS metadata
   * @param {Object} ctx.log - Colorized logger
   * @param {Array<string>} args - Additional CLI flags
   */
  async run(ctx, args) {
    // Modular execution logic
  }
};
```

---

## 6. Module Specifications

### 6.1 Module: `extract` (Review & DOM Extractor)
1. **Network Probe First**: Inspects HTTP responses for native JSON reviews endpoints before DOM scraping.
2. **Resilient Text Stream Parser**:
   - Targets the review container using `innerText`.
   - Splits into trimmed non-empty lines starting from header token `Reviews`.
   - `Date:` marks review block boundary; extracts `version` and `commit`.
   - All-caps lines `^[A-Z][A-Z &/-]{2,}$` define section headers (`RELEASES`, `BEHAVIOR`).
   - Exact category tokens (`Recommendation`, `Warning`, `Error`, `Info`, `Notice`, `Critical`) initialize new items.
   - Detail lines are accumulated until the next category, section, or meta line.
   - Single-line entries formatted as `Title: description` split at the first colon only if title length `<= 60` characters.
3. **Triple CSV Output Standard**:
   - `reviews_compact_<ver>_<date>.csv`: `section,name,category,lines` (lines comma-joined inside quoted cell).
   - `reviews_lines_only_<ver>_<date>.csv`: Single column `line`.
   - `reviews_detailed_<ver>_<date>.csv`: `review,version,commit,section,name,category,line_no,line`.
   - Format: UTF-8 with BOM (`\uFEFF`), every cell double-quoted (`"..."`), internal quotes escaped as `""`.

### 6.2 Module: `record` (Visual & DOM Recorder)
- Records browser actions using Playwright `recordVideo`.
- Captures timed viewport snapshots and full-page WebP/PNG screenshots.
- Serializes DOM state and logs network requests for audit trails.

### 6.3 Module: `overlay` (Interactive GUI Guidance)
- Injects non-destructive highlight frames and numerical tooltips over target selectors based on a `guide.json` sequence.
- Emits presentation-ready visual walk-throughs or synchronizes with `record`.

---

## 7. Command Reference

```bash
# Interactive menu (scans modules/ dynamically)
node all-lads-tool/script/javascript/web-toolkit/web-toolkit.js

# Initial one-time headed authentication (Google / GitHub login)
node all-lads-tool/script/javascript/web-toolkit/web-toolkit.js login

# Direct headless execution of a specific module
node all-lads-tool/script/javascript/web-toolkit/web-toolkit.js extract --url https://community.obsidian.md/account/plugins/pakcli-local

# Offline self-test verification against recorded test fixture
node all-lads-tool/script/javascript/web-toolkit/web-toolkit.js extract --selftest
```

---

## 8. Verification & Quality Gate Checklist

Before committing or releasing updates to `web-toolkit`:
- [ ] Ensure Rule #001 compliance: no hardcoded absolute drive letters (`D:\`, `C:\`).
- [ ] Confirm Rule #004 compliance: all module filenames in `modules/` are strictly kebab-case.
- [ ] Verify cross-platform OS handling: path separators use `path.join()` or forward slashes for web URLs.
- [ ] Run `--selftest` and verify 100% extraction parity against `fixtures/review-sample.txt`.
- [ ] Confirm CSV outputs contain valid UTF-8 BOM and render correctly in spreadsheet tools.
- [ ] Ensure credentials directory `auth/` and debug logs `debug/` are excluded from version control.
