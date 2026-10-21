# 📌 Master Brief: Web Toolkit — Modular Playwright CLI (all-lads-tool)

> **Feature Status**: `0` (Draft / Pending Implementation)  
> **Target Module**: all-lads-tool (`script/web-toolkit/`)  
> **Platform**: Cross-platform (Windows / macOS / Linux), Node 18+  
> **Date**: 2026-10-20  

---

## 1. Objective & Problem Statement
- **Problem**: Screen/DOM capture, recording and GUI-extraction tasks are one-off scripts. The Obsidian Reviews panel (login required) can only be read manually.
- **Solution**: One entry point `web-toolkit.js` that asks what you want and dispatches to independent modules. Adding a module = dropping one file in `modules/`.

## 2. Interactive Menu
```
$ node script/web-toolkit/web-toolkit.js

[env] Windows 11 (win32) | Node v20 | Playwright 1.64.1 | Chromium OK

What do you want?
  1. extract         DOM/text -> CSV (e.g. Obsidian reviews)
  2. record          page video + screenshots
  3. overlay guide   on-page highlight / step guide
  4. update          git pull + npm update (optional)
  q. quit
>
```
- Also callable without menu: `web-toolkit.js extract --url ...`, `record`, `overlay`.
- Menu is built by scanning `modules/*.js`, so new modules appear automatically.
- Shared command: `login` (headed browser, saves persistent profile).

## 3. OS Detection (Windows / macOS / Linux)
`lib/platform.js` detects the OS at startup using `process.platform` and exposes it to every module via `ctx.platform`.

| `process.platform` | Name | Notes |
| :--- | :--- | :--- |
| `win32` | Windows | Default dev target; PowerShell + `.bat` helpers available |
| `darwin` | macOS | Use `open` to launch files/folders |
| `linux` | Linux | Use `xdg-open`; headless servers have no display |

`ctx.platform` returns:
```js
{ id: 'win32', name: 'Windows', isWin: true, isMac: false, isLinux: false,
  arch: process.arch, hasDisplay: true, openCmd: 'start', shell: 'powershell' }
```
Rules:
1. Each module may declare `platforms: ['win32','darwin','linux']` (default: all). Unsupported modules are shown greyed out in the menu with the reason, and refuse to run.
2. Core is pure Node (`path`, `os`, `fs`), so no path separators are hardcoded (Rule #001).
3. `hasDisplay` is false on Linux without `DISPLAY`/`WAYLAND_DISPLAY`, so `login` (headed) warns and `HEADLESS` is forced true.
4. Opening the output folder uses `openCmd` per OS (`start` / `open` / `xdg-open`); failure never crashes the run.
5. Browser install hint is printed per OS (`npx playwright install chromium`, plus `--with-deps` on Linux).
6. Windows-only helpers in the wider `all-lads-tool` (PowerShell, `.bat`) are marked `platforms: ['win32']`.

## 4. Preflight Check (runs before the menu)
1. Detect OS (section 3).
2. Check Node version is 18+.
3. Check `node_modules/playwright`; if missing, print `npm install` (never auto-run without approval).
4. Check the Chromium browser is installed; if missing, print the install command.
5. Show a one-line status; stop with a clear message if anything blocking is missing.

## 5. Module Contract
Each file in `modules/` exports:
```js
module.exports = {
  id: 'extract',                          // CLI name
  title: 'extract',                       // menu label
  description: 'DOM/text -> CSV',
  version: '1.0.0',
  minCore: '1.0.0',
  platforms: ['win32', 'darwin', 'linux'],
  async run(ctx, args) {}   // ctx = { page, browserContext, config, log, platform }
};
```
Core (`lib/`) provides: config loader (`.env`), platform detector, preflight, browser launcher (persistent profile, headless flag), logger, CSV writer. Modules never launch their own browser.

## 6. Modules (phase 1)
### 6.1 `extract` (the original review extractor)
- Step 0: check DevTools Network for a JSON endpoint; use it if present, DOM parser as fallback.
- Parser on `innerText`, line based: `Date:` starts a block (version, commit), ALL-CAPS section header, exact category line (Recommendation, Warning, plus Error, Info, Notice, Critical defensively) starts an item, other lines are details. Single-line `Name: text` splits at first `:` only if left part under ~60 chars.
- Scope: **every review block** (`LATEST_ONLY=false` default).
- Output (UTF-8 BOM, all fields quoted, `""` escaped), never silently overwritten:
  - `reviews_compact_<version>_<date>.csv`: section,name,category,lines
  - `reviews_lines_only_<version>_<date>.csv`: line
  - `reviews_detailed_<version>_<date>.csv`: review,version,commit,section,name,category,line_no,line
- Zero items or expired session: exit non-zero, no CSV; zero items saves screenshot + raw text to `debug/`.

### 6.2 `record`
- Page video via Playwright `recordVideo` and/or timed screenshots, saved to `OUTPUT_DIR/records/`.
- Options: url, viewport, duration, full-page screenshot, DOM snapshot (HTML + innerText).

### 6.3 `overlay guide` (assumption, confirm)
- Injects a visual overlay into the page: highlight selected elements and numbered step tooltips from a small `guide.json`.
- Can combine with `record`.

## 7. Auth & Config
- GitHub/Google login: **persistent profile** in `auth/profile/` (`launchPersistentContext`), created by `login`. `auth/`, `debug/` in `.gitignore`.
- Expired session: "Session expired, run login".
- `.env`: `PLUGIN_URL`, `OUTPUT_DIR` (relative default, Rule #001), `LATEST_ONLY`, `HEADLESS`.

## 8. Files
| File | Status | Description |
| :--- | :---: | :--- |
| `script/web-toolkit/package.json` | ⏳ | Only dep: playwright (^1.64), `bin` entry |
| `script/web-toolkit/web-toolkit.js` | ⏳ | Menu + dispatcher + `login` |
| `script/web-toolkit/lib/platform.js` | ⏳ | OS detection (win32/darwin/linux) |
| `script/web-toolkit/lib/preflight.js` | ⏳ | Env + dependency checks |
| `script/web-toolkit/lib/browser.js` | ⏳ | Persistent-profile launcher |
| `script/web-toolkit/lib/config.js` | ⏳ | `.env` loader |
| `script/web-toolkit/lib/csv-writer.js` | ⏳ | 3 CSV writers |
| `script/web-toolkit/modules/extract.js` | ⏳ | Review extractor |
| `script/web-toolkit/modules/record.js` | ⏳ | Video/screenshot recorder |
| `script/web-toolkit/modules/overlay.js` | ⏳ | Overlay guide |
| `script/web-toolkit/fixtures/review-sample.txt` | ⏳ | For `extract --selftest` |
| `docs/web-toolkit/web-toolkit.md` | ⏳ | Version 3 doc (one per module) |
| `rule/000_main-rule.md`, `README.md` | ⏳ | Note: packages with own deps live in `script/<package>/`; fix stale lists/links |

## 9. Phase 2
- Scheduling, Drive upload, multi-plugin URLs, failure notifications.
- Publish: install via `npm i github:<user>/all-lads-tool` first; later a scoped npm package (`files` field, `.npmignore`, `os` field, MIT license, name check). Needs user approval to publish.
- `update-all` script to propagate the tool to every project.

## 10. Acceptance Criteria
- [ ] Status 0 brief committed
- [ ] Menu lists extract / record / overlay guide; direct CLI also works
- [ ] Startup prints detected OS (Windows / macOS / Linux), Node and Playwright status
- [ ] `ctx.platform` available to modules; `platforms` filter greys out unsupported modules
- [ ] Linux without display: headed `login` warns and headless is forced
- [ ] No hardcoded path separators or drive letters
- [ ] New file in `modules/` shows up in the menu with no core edits
- [ ] `login` creates a working session once
- [ ] `extract` writes 3 CSVs headless; 10+ items spot-checked (pakcli-local v1.0.12)
- [ ] Expired session fails clearly with no files written
- [ ] `record` produces video/screenshot output
- [ ] `overlay` highlights elements from `guide.json`
- [ ] CSVs open correctly in Excel
- [ ] Docs and README updated; Status 1 committed

## 11. Open Questions
1. Does "overlay guide" mean the on-page highlight/steps in 6.3, or something else?
2. Should `record` capture only the browser page, or the whole desktop (which would need per-OS tools)?
3. Keep the `update` menu item, or manual updates only?
