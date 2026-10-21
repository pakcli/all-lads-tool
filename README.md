---
title: All Lads Tool Master Hub & Architecture Guide
aliases: [all-lads-tool, tool-hub, lads-readme]
category: MASTER_HUB
tags: [all-lads-tool, architecture, manual, guide, documentation]
---

# 🛠️ All Lads Tool (`all-lads-tool`)
> **Cross-Runtime Developer Toolchain, Automation Engine, & Agent Skill Hub**  
> *Standardized, zero-hardcoded, modular automation for modern web and arcade development.*

---

## 📑 Daftar Isi (7 Core Sections)
1. [Overview](#1-overview)
2. [Tujuan & Manfaat](#2-tujuan--manfaat)
3. [Untuk Siapa](#3-untuk-siapa)
4. [Visi & Misi](#4-visi--misi)
5. [The 4 Pillars Architecture (4 Folders)](#5-the-4-pillars-architecture)
6. [How to Install & Quickstart](#6-how-to-install--quickstart)
7. [Lisensi (MIT)](#7-lisensi-mit)

---

## 1. Overview
**All Lads Tool** (`all-lads-tool/`) adalah ekosistem modular yang menyatukan seluruh skrip otomasi, aturan arsitektur (*invariant rules*), spesifikasi keahlian kecerdasan buatan (*AI agent skills*), dan dokumentasi teknis dalam satu hub mandiri. 

Dibangun dengan prinsip **The 4 Pillars**, proyek ini menghilangkan ketergantungan manual, menstandarisasi alur kompilasi aset (SCSS, bundling JS, visual capture), serta menyediakan antarmuka terpadu untuk manajemen repositori Git dan cartridge aplikasi di ekosistem **Vintage Computing Arcade**.

---

## 2. Tujuan & Manfaat

### 🎯 Tujuan Utama
* **Eliminasi Hardcoded Path**: Menjamin setiap otomasi dapat berpindah mesin dan direktori tanpa error path absolut melalui penegakan [Rule #001](rule/001-skills-no-hardcoded-variables.md).
* **Single Source of Truth**: Menghubungkan tema visual, build bundle, dan dokumentasi secara sinkron tanpa redundansi.
* **AI-Human Pair Programming**: Menyediakan *ground-truth skills* dan protokol audit lineage (`.agent.json`) yang dapat dipahami dan dieksekusi baik oleh pengembang manusia maupun agen AI.

### 🌟 Manfaat Konkret
* **Zero Horizontal Scroll**: Seluruh UI, output CLI, dan dokumentasi diformat rapi tanpa overflow horizontal.
* **Multi-Runtime Flexibility**: Mendukung ekosistem PowerShell, Node.js/JavaScript, Python, dan Windows Batch.
* **Safe Git Operations**: Perlindungan bawaan terhadap data loss saat manipulasi branch, reflog recovery, hingga penghapusan tracking `.git` yang aman (*Remove with more nicer*).
* **Obsidian Markdown Native**: Seluruh dokumentasi kompatibel 100% dengan Obsidian Markdown tanpa escape quote yang mengotori frontmatter.

---

## 3. Untuk Siapa

All Lads Tool dirancang secara spesifik untuk:

* 👨‍💻 **Solo Developers & Web Crafters**: Yang mengelola multi-project cartridge, tema CSS kompleks, atau web app tanpa framework raksasa yang memperlambat alur kerja.
* 🤖 **AI Agents & LLM Pair-Programmers**: Agen AI (seperti Antigravity/Gemini) yang membutuhkan SOP terstruktur, spesifikasi skill yang jelas, dan aturan deterministik untuk membaca serta memodifikasi repositori.
* 📦 **Modular Tool Enthusiasts**: Pengembang yang menyukai sistem modular tanpa instalasi dependency global yang mengotori sistem operasi.
* 🎨 **Theme & Obsidian Vault Architects**: Kreator yang menyinkronkan tema SCSS/CSS antara aplikasi web mandiri dan vault catatan Obsidian.

---

## 4. Visi & Misi

### 🔭 Visi
Menjadi fondasi standar alat bantu pengembang (*developer toolchain*) yang mandiri, tahan masa depan (*future-proof*), dan menjadi jembatan harmonis antara logika mesin (AI Agent) dan kemudahan interaksi manusia.

### 🚀 Misi
1. **Standarisasi**: Menerapkan kategorisasi folder yang deterministik berbasis ekstensi runtime dan 4 pilar.
2. **Keamanan Data**: Mencegah kehilangan histori atau file berharga melalui double-confirmation dan recovery engine.
3. **Kecepatan Iterasi**: Menyediakan dispatcher satu pintu (`main.ps1`) untuk menjalankan kompilasi, pengujian, dan versioning dalam hitungan detik.
4. **Dokumentasi Hidup**: Menjaga setiap skrip memiliki 1 dokumen pendamping Versi 3 yang selalu terbarui dan dapat diakses cepat.

---

## 5. The 4 Pillars Architecture

Seluruh aset dalam `all-lads-tool` dikelompokkan secara ketat ke dalam **4 Pilar**:

```text
all-lads-tool/
├── 1. skill/     --> Agent skills & SOP kerja mandiri
├── 2. rule/      --> Aturan arsitektur & invariant tidak terbantahkan
├── 3. script/    --> Skrip eksekusi dikelompokkan berdasarkan runtime
└── 4. docs/      --> Dokumentasi Versi 3 (1 file per skrip)
```

---

### 🏛️ Pilar 1: `skill/` (AI Skills & Reusable Manuals)
Kumpulan spesifikasi keahlian yang dapat dimuat (*on-demand*) oleh agen kecerdasan buatan:
* [`web-toolkit-cli.md`](skill/web-toolkit-cli.md): Modular Playwright automation engine, DOM/reviews extraction, screen recording & on-page step guide.
* [`codebase-compliance-audit.md`](skill/codebase-compliance-audit.md): Protokol dan checklist audit kepatuhan otomatis Rule #000 - #005 & UI/UX ASCII.
* [`markdown-obsidian-format-compatibility.md`](skill/markdown-obsidian-format-compatibility.md): Standar Markdown tanpa tanda kutip di frontmatter, wikilinks, dan quick switcher.
* [`briefing-0x-0x-version.md`](skill/briefing-0x-0x-version.md): SOP penulisan brief arsitektur versi bertingkat (`0x-0x`).
* [`production-bundling-compaction.md`](skill/production-bundling-compaction.md): Panduan kompilasi dan reduksi bundle produksi.
* [`bento-layout-playground-skill.md`](skill/bento-layout-playground-skill.md): Arsitektur playground bento split 60/40.
* [`playwright-thumbnail-capture.md`](skill/playwright-thumbnail-capture.md): Prosedur tangkapan layar otomatis cartridge web ke format WebP.
* [`dependency-preflight-checker.md`](skill/dependency-preflight-checker.md): Pre-flight validator dependensi runtime (Node, PowerShell, Python).
* [`env-string-statement-parser.md`](skill/env-string-statement-parser.md): Engine ekstraksi dan normalisasi variable environment dinamis.
* [`lifecycle-development.md`](skill/lifecycle-development.md): Manajemen atomic commit lifecycle dan sinkronisasi versioning mikro.
* [`markdown-build-reporter.md`](skill/markdown-build-reporter.md): Generator laporan build markdown flat dan tabel ringkas.
* [`uiux-wireframe-via-text-ascii-codeblock.md`](skill/uiux-wireframe-via-text-ascii-codeblock.md): Standar visualisasi wireframe ASCII monospace <= 80 kolom.
* [`verify-visibility-ui.md`](skill/verify-visibility-ui.md): Validasi DOM element, kontras warna, dan inspeksi layout headless.

---

### 🏛️ Pilar 2: `rule/` (Architecture Invariants)
Hukum tata kelola proyek yang tidak boleh dilanggar:
* [`000_main-rule.md`](rule/000_main-rule.md): **Rule #000** — Modular decoupled toolchain invariant & 4 pilar arsitektur.
* [`001-skills-no-hardcoded-variables.md`](rule/001-skills-no-hardcoded-variables.md): **Rule #001** — Larangan keras hardcoded path (`D:\`, `C:\`, usernames); wajib resolusi dinamis.
* [`002-mobile-portrait-zero-horizontal-scroll.md`](rule/002-mobile-portrait-zero-horizontal-scroll.md): **Rule #002** — Jaminan zero horizontal scroll pada viewport mobile portrait (360px+).
* [`003-immutable-theme-css.md`](rule/003-immutable-theme-css.md): **Rule #003** — Immutabilitas file CSS tema produksi (0 edit manual).
* [`004_naming.md`](rule/004_naming.md): **Rule #004** — Standar penamaan file lowercase kebab-case dan 2-octet versioning (`0x-0x`).
* [`005_readme-on-root.md`](rule/005_readme-on-root.md): **Rule #005** — Kewajiban master `README.md` pada root repositori proyek.
* [`009_commit-convention.md`](rule/009_commit-convention.md): **Rule #009** — Standar konvensi commit semantik atomik dan pelacakan lineage.

---

### 🏛️ Pilar 3: `script/` (Executable Toolchain)
Engine otomasi yang dikelompokkan ke dalam 4 folder bahasa/runtime:

#### A. PowerShell (`script/powershell/`) — 13 Scripts
* [`ps_git-manage.ps1`](script/powershell/ps_git-manage.ps1): Universal Git Manager (-1 to 9, target directory aware, drag & drop shell).
* [`ps_recover.ps1`](script/powershell/ps_recover.ps1): Git reflog detached & lost commit recovery wrapper.
* [`bump-version.ps1`](script/powershell/bump-version.ps1): Semantic version tag bumper (v01_01 -> v01_02).
* [`compile-arctitecture-bundledjs.ps1`](script/powershell/compile-arctitecture-bundledjs.ps1): JS module packager & client bundler.
* [`compile-single-scss-to-css.ps1`](script/powershell/compile-single-scss-to-css.ps1): SCSS to CSS theme compiler (1:1 & Obsidian modes).
* [`compile-single-css-to-scss.ps1`](script/powershell/compile-single-css-to-scss.ps1): CSS to SCSS syntax reverse-converter.
* [`theme-compiler.ps1`](script/powershell/theme-compiler.ps1): Master SCSS theme & winget compiler.
* [`manage-submodule.ps1`](script/powershell/manage-submodule.ps1): Git submodule orchestrator (add, sync, update, remove).
* [`ps_diff-commits.ps1`](script/powershell/ps_diff-commits.ps1): Commit size delta & history inspector.
* [`find-folder-lockers.ps1`](script/powershell/find-folder-lockers.ps1): Windows Restart Manager process locker detector.
* [`ps_open-cwp.ps1`](script/powershell/ps_open-cwp.ps1): Clean Web Project isolated workspace opener.
* [`ps_sync-cwp.ps1`](script/powershell/ps_sync-cwp.ps1): Workspace integrity & asset synchronizer.
* [`start.ps1`](script/powershell/start.ps1): Multi-threaded local HTTP server with Wi-Fi IP display.

#### B. JavaScript (`script/javascript/`) — 7 Scripts
* [`audit-codebase.js`](script/javascript/audit-codebase.js): Automated codebase compliance auditor for Rule #001, Rule #004, YAML quotes & ASCII wireframes.
* [`build-bundles.js`](script/javascript/build-bundles.js): ES module client bundler.
* [`capture-app-thumbnails.js`](script/javascript/capture-app-thumbnails.js): Playwright automated viewport snapshot engine.
* [`capture-thumbnails.js`](script/javascript/capture-thumbnails.js): Headless screenshot utility.
* [`theme-syntax-converter.js`](script/javascript/theme-syntax-converter.js): Obsidian CSS/SCSS syntax translator.
* [`verify-all-elements.js`](script/javascript/verify-all-elements.js): DOM accessibility, contrast, and element validator.
* [`test-blink.js`](script/javascript/test-blink.js): Terminal blinking cursor tester.

#### C. Python (`script/python/`) — 4 Scripts
* [`server.py`](script/python/server.py): Multi-threaded local development web server.
* [`screenshot.py`](script/python/screenshot.py): Python viewport screenshot utility.
* [`screenshot_projects.py`](script/python/screenshot_projects.py): Batch screenshot capture runner.
* [`test_blink.py`](script/python/test_blink.py): Python terminal font & blink tester.

#### D. Windows Batch (`script/bat/`) — 1 Script
* [`start-chrome-cwp.bat`](script/bat/start-chrome-cwp.bat): Isolated Chrome sandbox profile launcher.

---

### 🏛️ Pilar 4: `docs/` (Versi 3 Technical Documentation)
Setiap skrip memiliki satu file panduan teknis individual dengan parameter lengkap:
* `docs/powershell/` : [`ps_git-manage.md`](docs/powershell/ps_git-manage.md), [`bump-version.md`](docs/powershell/bump-version.md), [`theme-compiler.md`](docs/powershell/theme-compiler.md), dll.
* `docs/javascript/` : [`audit-codebase.md`](docs/javascript/audit-codebase.md), [`build-bundles.md`](docs/javascript/build-bundles.md), [`capture-app-thumbnails.md`](docs/javascript/capture-app-thumbnails.md), dll.
* `docs/python/`     : [`server.md`](docs/python/server.md), [`screenshot.md`](docs/python/screenshot.md), dll.
* `docs/bat/`        : [`start-chrome-cwp.md`](docs/bat/start-chrome-cwp.md).

---

## 6. How to Install & Quickstart

### 📦 Prerequisites
Pastikan runtime berikut terpasang di sistem operasi Anda:
* **PowerShell**: Versi 5.1 atau PowerShell 7+ (Sangat direkomendasikan).
* **Node.js**: v18.0+ (Untuk script bundling dan Playwright).
* **Python**: v3.9+ (Opsional, untuk `server.py` dan capture utility).
* **Git**: v2.30+ (Wajib untuk Git Manager dan reflog recovery).

---

### 🚀 Cara Menjalankan

#### 1. Melalui Master Interactive Dispatcher (Direkomendasikan)
Cukup panggil launcher utama dari root repositori:
```powershell
.\main.ps1
```
Dispatcher akan otomatis mendeteksi seluruh skrip di `all-lads-tool/script/` dan menyediakan menu bernomor dengan pencarian instan.

#### 2. Menjalankan Universal Git Manager Langsung
```powershell
# Buka menu interaktif Git Manager (Target: Workspace Root)
.\all-lads-tool\script\powershell\ps_git-manage.ps1

# Targetkan cartridge tertentu secara spesifik
.\all-lads-tool\script\powershell\ps_git-manage.ps1 -TargetDir "apps/radiansincostan"

# Eksekusi aksi langsung tanpa menu
.\all-lads-tool\script\powershell\ps_git-manage.ps1 -Action status
.\all-lads-tool\script\powershell\ps_git-manage.ps1 -Action recover
```

#### 3. Menjalankan Server Web Lokal
```powershell
.\all-lads-tool\script\powershell\start.ps1
```

---

## 7. Lisensi (MIT)

Proyek ini didistribusikan di bawah lisensi terbuka **MIT License**.

```text
MIT License

Copyright (c) 2026 Vintage Computing Arcade / All Lads Tool Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
