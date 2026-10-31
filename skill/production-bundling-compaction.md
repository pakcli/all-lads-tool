---
name: production-bundling-compaction
aliases: [compile-architecture-bundle, bundled-js-compactor, modular-architecture-bundler, build-compaction-pipeline]
category: BUILD_PIPELINE
tags: [all-lads-tool, build, compaction, terser, bundling, architecture, pipeline, javascript]
trigger: on_demand
description: Standardized production build, minification, and compaction pipeline converting modular architecture into zero-dependency standalone distributions with declarative manifest discovery and before/after audit reporting.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# ⚡ Modular Architecture Bundling & Compaction Skill (`production-bundling-compaction`)

> [!INFO]
> **Domain**: Build & Compaction Pipeline | **Supersedes**: `compile-arctitecture-bundledjs_stand.ps1` (Retired to `trash-bin/`)  
> **Standard**: Zero-Hardcoding, Declarative Manifest Driven (`build.json`), In-Place Output, Zero Outer Dist Pollution  
> **Status Invariant**: All changes governed under the `donot-commit-yet` quarantine protocol.

This skill establishes the universal specification and automated patterns for transforming modular multi-file source trees (`src/`, `module/`, `apps/`) into compact, production-ready, airgap-capable distributions.

---

## 1. Architectural Principles

1. **100% Declarative Manifest Discovery**:
   - The build pipeline never hardcodes paths, filenames, or asset targets.
   - It auto-discovers configuration from the single source of truth in project root:
     $$\text{build.json} \longrightarrow \text{manifest.json} \longrightarrow \text{arcade.json}$$
   - Any flag provided via CLI (`-ConfigFile`, `-SourcePath`, `-OutputPath`, `-AppsSource`) overrides the manifest declarations dynamically.

2. **In-Place & Zero `dist/` Pollution**:
   - Compaction pipelines must output to designated target folders (`public/`, `build/`) or generate standalone `<name>_stand.<ext>` executables in-place without generating detached temporary build artifacts.

3. **Multi-Stage Modular Pipeline Execution**:
   - The pipeline executes 8 distinct, deterministic stages in strict dependency order:
     ```mermaid
     flowchart TD
       A["Initialize Directories"] --> B["Cartridge / Module Bundles"]
       B --> C["Slidev / Presentation Bundles"]
       C --> D["Script Bundles (JS / Terser)"]
       D --> E["Style Bundles (CSS Compactor)"]
       E --> F["HTML Minification"]
       F --> G["Media & Binary Pass-Through"]
       G --> H["App Screenshots Stage"]
       H --> I["Before/After Size Audit Report"]
     ```

---

## 2. Compaction Engines & Tooling Standards

### 2.1 Stage 1: JavaScript Variable Mangling & Dead-Code Elimination (Terser CLI)
* **Command Syntax**:
  ```bash
  npx --yes terser <input.js> -o <output.js> --module --mangle --compress passes=2
  ```
* **Engine Invariants**:
  * `--module`: Guarantees native ES Module (`import` / `export`) syntax remains 100% valid.
  * `--mangle`: Scrambles local variable names, function arguments, and internal iterators into single characters (`a`, `b`, `c`), obfuscating logic and saving bytes.
  * `--compress passes=2`:
    * Dead code elimination (removes uncalled helper functions and unreachable branches).
    * Compresses `if-else` branches into compact ternary operators.
    * Strips all single-line (`//`) and block (`/* ... */`) comments.
    * Removes all redundant whitespace and newline characters.

### 2.2 Stage 2: High-Performance CSS Regex Compaction
* **Transformation Patterns**:
  1. Strip all comment blocks: `/\*.*?\*/` $\rightarrow$ `""`
  2. Remove whitespace around structural operators: `\s*([{};:,>+~])\s*` $\rightarrow$ `$1`
  3. Strip redundant trailing semicolons: `;}` $\rightarrow$ `}`
  4. Collapse multiple consecutive spaces and empty lines into single streams.
* **Target Reduction**: 30% – 45% stylesheet size savings.

### 2.3 Stage 3: HTML Markup Minification
* **Transformations**:
  1. Strip standard HTML comments: `<!--.*?-->` $\rightarrow$ `""`
  2. Collapse whitespace between tags: `>\s+<` $\rightarrow$ `><`
  3. Preserve preformatted text without altering `<pre>`, `<code>`, or `<textarea>` blocks.

### 2.4 Stage 4: Binary Asset Pass-Through
* Binary assets (`.png`, `.jpg`, `.webp`, `.svg`, `.ico`) in source asset directories are copied directly using raw binary file streams (`[System.IO.File]::ReadAllBytes` / `fs.copyFileSync`), guaranteeing zero image compression artifacts or metadata corruption.

---

## 3. Automated Manifest Format (`build.json`)

Projects adhering to this skill maintain a standard declarative manifest in root:

```json
{
  "project": "my-modular-app",
  "version": "1.0.0",
  "paths": {
    "source": "src",
    "output": "public",
    "apps": "apps"
  },
  "bundles": {
    "scripts": [
      { "entry": "src/index.js", "output": "public/bundle.min.js", "minify": true }
    ],
    "styles": [
      { "entry": "src/styles/main.css", "output": "public/style.min.css" }
    ],
    "html": [
      { "entry": "src/index.html", "output": "public/index.html" }
    ]
  }
}
```

---

## 4. Standalone One-Liner Execution Patterns

When compiling or bundling without relying on retired scripts:

```powershell
# Quick Run: Execute Node-based bundle processor directly
node -e "
const fs = require('fs');
const cfg = JSON.parse(fs.readFileSync('build.json', 'utf8'));
console.log('Building ' + cfg.project + ' v' + cfg.version);
"

# Terser Inlining on Single Script
npx --yes terser src/index.js -o public/bundle.js --module --mangle --compress passes=2

# Full Node Modular Compiler
node script/javascript/standalone-compiler_stand.js
```

---

## 5. File-System Watcher Protocol (Watch Mode)

For real-time development iteration, the build watcher listens for changes across the resolved source tree using native event hooks:

```powershell
# PowerShell Native FileSystemWatcher Snippet
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = (Resolve-Path "src").Path
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.Filter = "*.*"

$action = {
    param($source, $eventArgs)
    Write-Host "[Change Detected] $($eventArgs.Name) -> Re-running compaction..." -ForegroundColor Magenta
}

Register-ObjectEvent $watcher 'Changed' -Action $action | Out-Null
Register-ObjectEvent $watcher 'Created' -Action $action | Out-Null
```

---

## 6. Before/After Size Audit Reporting

Every build execution must measure byte reduction and print a structured audit summary table:

```text
==========================================================================
  [*] PRODUCTION BUILD & COMPACTION AUDIT REPORT
==========================================================================
  File Name          | Original    | Compacted   | Reduction
  -------------------+-------------+-------------+------------
  script.js          | 45.50 KB    | 24.20 KB    | -46.8%  [*]
  navigation-url.js  |  8.20 KB    |  4.80 KB    | -41.5%  [*]
  winget.js          |  6.10 KB    |  3.70 KB    | -39.3%  [*]
  style.css          | 32.40 KB    | 19.80 KB    | -38.9%  [*]
  winget.css         |  5.30 KB    |  3.40 KB    | -35.8%  [*]
  apps.html          | 52.40 KB    | 36.10 KB    | -31.1%  [*]
  playground.html    | 35.20 KB    | 24.60 KB    | -30.1%  [*]
  -------------------+-------------+-------------+------------
  TOTAL PAYLOAD      | 185.10 KB   | 116.60 KB   | -37.0%  (SAVED 68.5 KB)
==========================================================================
```

---

## 7. Migration & Retirement History

* **Retired Script**: `all-lads-tool/script/powershell/compile-arctitecture-bundledjs_stand.ps1`
* **Target Destination**: Moved safely to `trash-bin/compile-arctitecture-bundledjs_stand.ps1` per repository zero-hard-delete rules.
* **Replacement Engine**: Centralized under `all-lads-tool/skill/production-bundling-compaction.md` and executed via native `standalone-compiler_stand.*` engines.
