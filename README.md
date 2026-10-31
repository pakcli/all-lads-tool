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

Seluruh aset eksekusi dalam `all-lads-tool/script/` dikelompokkan secara ketat ke dalam **5 Domain Contexts**:

```text
all-lads-tool
	brief
	skill
	docs
	script
		blender
			fbx-export.py
			modules
				check.py
		unity
			asset-importer.cs
			modules
				check.cs
		repo
			git-manage.ps1
			git-branch-rename.ps1
			modules
				check.psm1
		website
			build-bundles.js
			modules
				check.js
		file
			csv-to-frontmatter.ps1
			dry-run.ps1
			modules
				check.psm1
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
3. **`repo/` (Git & Repository Orchestration)**: Universal Git Manager, branch renamer, commit size inspector, submodule orchestrator, dan reflog recovery.
4. **`website/` (Web Architecture & Frontend)**: Bundling ES module, SCSS/CSS compiler, DOM accessibility validator, dan Playwright snapshot engine.
5. **`file/` (File & Data Transformation)**: Bidirectional CSV $\leftrightarrow$ YAML Frontmatter bridge, text formatters, dan PowerShell dry-run simulation engine.

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
   # Jalankan tool konversi CSV ke Frontmatter
   .\script\file\csv-to-frontmatter_stand.ps1 -TargetDir "vault/notes" -TargetCsv "data.csv"
   
   # Jalankan simulasi Dry-Run pada skrip apapun
   .\script\file\dry-run-ps1.ps1 -ScriptPath ".\script\repo\git-branch-rename_stand.ps1"
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
