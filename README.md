---
title: All Lads Tool Master Hub & Architecture Guide
aliases:
  - all-lads-tool
  - tool-hub
  - lads-readme
category: MASTER_HUB
tags:
  - all-lads-tool
  - architecture
  - manual
  - guide
  - documentation
---

# 🛠️ All Lads Tool (`all-lads-tool`)

> Cross-Runtime Developer Toolchain, Automation Engine, & Agent Skill Hub. Standardized, zero-hardcoded, modular automation for modern web, 3D, and interactive development.

---

## 📑 Daftar Isi (7 Core Sections)

1. [Overview](#1-overview)
2. [Tujuan & Manfaat](#2-tujuan--manfaat)
3. [Untuk Siapa](#3-untuk-siapa)
4. [Visi & Misi](#4-visi--misi)
5. [The 5 Contexts Architecture](#5-the-5-contexts-architecture)
6. [How to Install & Quickstart](#6-how-to-install--quickstart)
7. [Lisensi (MIT)](#7-lisensi-mit)

---

## 1. Overview

**All Lads Tool** (`all-lads-tool/`) adalah ekosistem modular yang menyatukan seluruh skrip otomasi, aturan arsitektur (*invariant rules*), spesifikasi keahlian kecerdasan buatan (*AI agent skills*), dan dokumentasi teknis dalam satu hub mandiri.

Dibangun dengan prinsip arsitektur modular berbasis **Domain Contexts**, proyek ini menghilangkan ketergantungan manual, menstandarisasi alur kompilasi aset (SCSS, bundling JS, visual capture), konversi format teks (CSV $\leftrightarrow$ YAML Frontmatter), integrasi 3D (Blender) & Game Engine (Unity), serta menyediakan antarmuka terpadu untuk manajemen repositori Git yang aman.

Untuk panduan instalasi mendalam dan detail CLI, baca **[GUIDE.md](GUIDE.md)**.

---

## 2. Tujuan & Manfaat

### 🎯 Tujuan Utama
- **Eliminasi Hardcoded Path**: Menjamin setiap otomasi dapat berpindah mesin dan direktori tanpa error path absolut melalui penegakan [Rule #001](rule/001_skills-no-hardcoded-variables.md).
- **Single Source of Truth**: Menghubungkan tema visual, build bundle, dan dokumentasi secara sinkron tanpa redundansi.
- **AI-Human Pair Programming**: Menyediakan ground-truth skills dan protokol audit lineage yang dapat dipahami dan dieksekusi baik oleh pengembang manusia maupun agen AI.
- **Polyglot Versioned Preflight**: Menjamin kompatibilitas dependency runtime multi-versi (`modules/dependencies-checker/`).

### 🌟 Manfaat Konkret
- **Zero Horizontal Scroll**: Seluruh UI, output CLI, dan dokumentasi diformat rapi tanpa overflow horizontal.
- **Multi-Runtime Flexibility**: Mendukung ekosistem PowerShell, Node.js/JavaScript, Python, C#, dan Bash.
- **Safe Git & Dry-Run Operations**: Perlindungan bawaan terhadap data loss saat manipulasi branch, reflog recovery, hingga simulasi dry-run non-destruktif (`run-dry`).
- **Obsidian Markdown Native**: Seluruh dokumentasi kompatibel 100% dengan Obsidian Markdown tanpa escape quote yang mengotori frontmatter.

---

## 3. Untuk Siapa

All Lads Tool dirancang secara spesifik untuk:
- 👨‍💻 **Solo Developers & Web Crafters**: Yang mengelola multi-project cartridge, tema CSS kompleks, atau web app tanpa framework raksasa yang memperlambat alur kerja.
- 🎮 **Game Developers & 3D Creators**: Pengembang Unity dan seniman 3D Blender yang membutuhkan otomasi asset pipeline (FBX batch export, material sync, meta cleaner).
- 🤖 **AI Agents & LLM Pair-Programmers**: Agen AI (seperti Antigravity/Gemini) yang membutuhkan SOP terstruktur, spesifikasi skill yang jelas, dan aturan deterministik untuk membaca serta memodifikasi repositori.
- 📦 **Modular Tool Enthusiasts**: Pengembang yang menyukai sistem modular tanpa instalasi dependency global yang mengotori sistem operasi.
- 🎨 **Theme & Obsidian Vault Architects**: Kreator yang menyinkronkan tema SCSS/CSS antara aplikasi web mandiri dan vault catatan Obsidian.

---

## 4. Visi & Misi

### 🔭 Visi
Menjadi fondasi standar alat bantu pengembang (*developer toolchain*) yang mandiri, tahan masa depan (*future-proof*), dan menjadi jembatan harmonis antara logika mesin (AI Agent) dan kemudahan interaksi manusia di berbagai platform.

### 🚀 Misi
- **Standarisasi**: Menerapkan kategorisasi folder yang deterministik berbasis konteks fungsional (`blender`, `unity`, `repo`, `website`, `file`).
- **Keamanan Data**: Mencegah kehilangan histori atau file berharga melalui double-confirmation, dry-run simulator, dan recovery engine.
- **Kecepatan Iterasi**: Menyediakan launcher satu pintu (`_run.ps1` / `_mainmenu.ps1`) untuk menjalankan kompilasi, pengujian, dan versioning dalam hitungan detik dari mana saja di dalam disk.
- **Dokumentasi Hidup**: Menjaga setiap skrip memiliki 1 dokumen panduan teknis yang selalu terbarui dan dapat diakses cepat.

---

## 5. The 5 Contexts Architecture

Seluruh aset eksekusi dalam `all-lads-tool/script/` dikelompokkan secara ketat ke dalam **5 Domain Contexts** dengan topologi 1:1 antara script dan dokumentasi (mengikuti `brief/v01-03-02`):

```text
all-lads-tool
	brief
		v01-00_main-idea.md
		v01-01_foldering-structure.md
		v01-02_foldering-structure.md
		v01-03_foldering-structure.md
		v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md
		v01-03-03_UNLOCKING-FILE-SCRIPT-FINALY-WORKING.md
		v01-03-04_repo-edit-commited-files-but-hidden-in-the-history-with-staged.md
		v01-03-05_repo-edit-commited-files-all-commit-state.md
	docs
		repo
			edit-commited-files-but-hidden-in-the-history-with-staged.md <--- 1:1 match for script/repo/edit-commited-files-but-hidden-in-the-history-with-staged.ps1
			git-all-state-renamer-prefix-v.md                            <--- 1:1 match for script/repo/git-all-state-renamer-prefix-v.ps1
			git-branch-rename.md                                         <--- 1:1 match for script/repo/git-branch-rename.ps1
			git-diff-commits.md                                          <--- 1:1 match for script/repo/git-diff-commits.ps1
			git-manage.md                                                <--- 1:1 match for script/repo/git-manage.ps1
			git-manage.sh.md                                             <--- 1:1 match for script/repo/git-manage.sh
			git-reconfig-identity.md                                     <--- 1:1 match for script/repo/git-reconfig-identity.ps1
			git-recover.md                                               <--- 1:1 match for script/repo/git-recover.ps1
			git-rename-commit.md                                         <--- 1:1 match for script/repo/git-rename-commit.ps1
			git-submodule.md                                             <--- 1:1 match for script/repo/git-submodule.ps1
			git-sync-from-dir.md                                         <--- 1:1 match for script/repo/git-sync-from-dir.ps1
		file
			batch-target-dir-rename.md
			csv-to-frontmatter.md
			detector-clipboard-4-mode.md <--- 1:1 match for script/file/detector-clipboard-4-mode.ps1
			detector-file-lock-process.md <--- 1:1 match for script/file/detector-file-lock-process.ps1
			dry-run.md
			file-merge-into-one.md
			file-one-to-multiple-files.md
		blender
			fbx-export.md
		unity
			asset-importer.md
		website
			build-bundles.md
	script
		repo
			edit-commited-files-but-hidden-in-the-history-with-staged.ps1 <--- Historical Commit File Overwrite
			git-all-state-renamer-prefix-v.ps1                            <--- Batch Prefix Renamer
			git-branch-rename.ps1                                         <--- Branch Renamer
			git-diff-commits.ps1                                          <--- Commit Diff & Size Analyzer
			git-manage.ps1                                                <--- Universal Git Manager (PowerShell)
			git-manage.sh                                                 <--- Universal Git Manager (Git Bash)
			git-reconfig-identity.ps1                                     <--- Repo Local Identity Aligner
			git-recover.ps1                                               <--- Reflog Discovery & Recovery
			git-rename-commit.ps1                                         <--- Commit Message Renamer
			git-submodule.ps1                                             <--- Submodule Manager
			git-sync-from-dir.ps1                                         <--- Non-destructive Robocopy Sync
			adapter
				edit-commited-files-but-hidden-in-the-history-with-staged.json <--- Persisted Options & History
				edit-commited-files-but-hidden-in-the-history-with-staged.psm1 <--- Rewrite & State Adapter
				git-commitrenamer.psm1                                        <--- Commit Rewriter Plumbing Engine
				git-core.psm1                                                 <--- Process Execution Wrapper
				git-core.sh                                                   <--- POSIX Git CLI Wrapper
				git-diffengine.psm1                                           <--- Sandbox Compile & Diff Engine
				git-identity.psm1                                             <--- Remote Owner & Identity Engine
				git-reflog.psm1                                               <--- Reflog Parser & Restore Engine
				git-reflog.sh                                                 <--- POSIX Reflog Recovery Engine
				git-status.psm1                                               <--- Status Summary Engine
				git-status.sh                                                 <--- POSIX Git Status Inspector
				git-submodule.psm1                                            <--- Submodule Plumbing Engine
				git-submodule.sh                                              <--- POSIX Submodule Engine
				history.psm1                                                  <--- JSON History Tracker
				history.sh                                                    <--- POSIX State Logger
				v02-30-00.psm1                                                <--- LTS Version Adapter
				v02-40-00.psm1                                                <--- Modern Version Adapter
		file
			csv-to-frontmatter.ps1
			detector-clipboard-4-mode.ps1  <--- Executable (4-Mode Clipboard & Git Protocol Suite)
			detector-clipboard-4-mode.json <--- Atomic persistence store
			detector-file-lock-process.ps1 <--- Executable (File Lock Inspector & Unlocker)
			dry-run.ps1
			batch-target-dir-rename.ps1
			file-merge-into-one.ps1
			file-one-to-multiple-files.ps1
			adapter/
		blender
			fbx-export.py
			adapter/
		unity
			asset-importer.cs
			adapter/
		website
			build-bundles.js
			adapter/
	skill/
	combo/
	_run.ps1
	_run.env
	_run.env.example
	_run.json
	_mainmenu.ps1
	_mainmenu.html
	README.md
	GUIDE.md
```

### 🏛️ Ringkasan 5 Domain Contexts:
1. **`blender/` (3D & Modeling Pipeline)**: Otomasi mesh cleaning, FBX/glTF batch export, dan material baking via Blender Python API.
2. **`unity/` (Game Engine & Editor Tools)**: C# Editor utilities, asset post-processors, meta-file cleaners, dan build triggers.
3. **`repo/` (Git & Repository Orchestration)**: Universal Git Manager (`git-manage.ps1` PowerShell & `git-manage.sh` Git Bash) dilengkapi Git Clone Wizard interaktif (HTTPS, SSH, GitHub CLI, owner/repo slug) dengan pre-flight briefed overview card dan konfirmasi eksplisit `[y/N]`; Historical Commit File Overwrite Engine (`edit-commited-files-but-hidden-in-the-history-with-staged.ps1`) dengan 3-Step No-Default-Enter architecture (Step 1 repo `1..20` + `more`, Step 2 `commit id / more / L / all` [All Commit State], Step 3 5 Opsi `1..5` dengan folder/file custom scope & new-file gate); Branch Renamer (`git-branch-rename.ps1`); Batch Prefix Renamer (`git-all-state-renamer-prefix-v.ps1`); Commit Diff & Sandbox Size Analyzer (`git-diff-commits.ps1`); Remote Owner Identity Reconfig (`git-reconfig-identity.ps1`); Reflog Commit Recovery (`git-recover.ps1`); Historical Commit Message Renamer (`git-rename-commit.ps1`); Submodule Hub (`git-submodule.ps1`); dan Non-destructive Robocopy Sync (`git-sync-from-dir.ps1`).
4. **`website/` (Web Architecture & Frontend)**: Bundling ES module, SCSS/CSS compiler, DOM accessibility validator, dan Playwright snapshot engine.
5. **`file/` (File & Data Transformation)**: Universal 4-Mode Clipboard Suite (`PolyClip` / `detector-clipboard-4-mode.ps1`) dengan Unified 5-Column Architecture, Git Multi-Protocol Widget (`[ HTTPS | SSH | GitHub CLI ]`), integrasi native clipboard VS Code Explorer (`text/uri-list`, `FileNameW`), File Lock Inspector & Unlocker (`detector-file-lock-process.ps1`) dengan split action `[Only Instance]` vs `[Unlock All]`, Bidirectional CSV $\leftrightarrow$ YAML Frontmatter bridge, pemecah/penggabung file (`file-merge` / `file-split`), dan PowerShell dry-run simulation engine.

---

## 6. How to Install & Quickstart

### 📦 Prerequisites
- **PowerShell**: Versi 5.1 atau PowerShell 7+ (Sangat direkomendasikan).
- **Node.js**: v18.0+ (Untuk bundling JS dan web tools).
- **Python**: v3.9+ (Untuk tooling Python dan Blender pipeline).
- **Git**: v2.30+ (Wajib untuk Git Manager dan reflog recovery).

### 🚀 Cara Menjalankan
1. **Universal Portable Launcher (Direkomendasikan)**:
   ```powershell
   .\_run.ps1
   ```
   *Dapat diletakkan di folder mana saja pada drive. Otomatis mencari `_mainmenu.ps1`, menyimpan cache ke `_run.json`, dan mencatat riwayat eksekusi (`0`, `1`, `2`).*

2. **Jalankan Standalone Script Langsung**:
   ```powershell
   # Buka PolyClip 4-Mode Clipboard Panel (Unified 5-Column WPF UI)
   .\script\file\detector-clipboard-4-mode.ps1 -Panel

   # Jalankan PolyClip Terminal CLI Dashboard
   .\script\file\detector-clipboard-4-mode.ps1 -Mode CLI

   # Jalankan Win+V Background Override Daemon (0% CPU Event-Driven)
   .\script\file\adapter\daemon-override-win-v.ps1

   # Jalankan File Lock Inspector & Unlocker (Cari proses & lepaskan lock)
   .\script\file\detector-file-lock-process.ps1

   # Jalankan Historical Commit File Overwrite Engine (No Default Enter)
   .\script\repo\edit-commited-files-but-hidden-in-the-history-with-staged.ps1

   # Jalankan tool konversi CSV ke Frontmatter
   .\script\file\csv-to-frontmatter.ps1 -TargetDir "vault/notes" -TargetCsv "data.csv"
   
   # Jalankan Git Manager interaktif (dengan Git Clone Wizard & clipboard auto-detect)
   .\script\repo\git-manage.ps1

   # Jalankan simulasi Dry-Run pada skrip apapun
   .\script\file\dry-run.ps1 -ScriptPath ".\script\repo\git-branch-rename.ps1"
   ```

*Untuk panduan lengkap setiap perintah dan parameter, silakan baca **[GUIDE.md](GUIDE.md)**.*

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
