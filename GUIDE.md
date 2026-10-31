---
title: All Lads Tool Operational & Installation Guide
aliases:
  - all-lads-tool-guide
  - lads-guide
  - installation-manual
category: OPERATIONAL_GUIDE
tags:
  - all-lads-tool
  - guide
  - installation
  - cli
  - operations
---

# 📖 All Lads Tool Operational Guide (`GUIDE.md`)

> Panduan komprehensif untuk instalasi, konfigurasi runtime, eksekusi CLI, dependensi multi-versi, dan troubleshooting di ekosistem **All Lads Tool**.

---

## 📑 Daftar Isi

1. [Prasyarat Sistem (Prerequisites)](#1-prasyarat-sistem-prerequisites)
2. [Instalasi & Setup Workspace](#2-instalasi--setup-workspace)
3. [Menjalankan Toolchain](#3-menjalankan-toolchain)
   - [Mode 1: Universal Launcher (`_run.ps1`)](#mode-1-universal-launcher-_runps1)
   - [Mode 2: Central Cockpit (`_mainmenu.ps1`)](#mode-2-central-cockpit-_mainmenups1)
   - [Mode 3: Direct Standalone CLI (`_stand`)](#mode-3-direct-standalone-cli-_stand)
4. [Panduan Operasional 5 Contexts](#4-panduan-operasional-5-contexts)
   - [Context: File (`script/file/`)](#context-file-scriptfile)
   - [Context: Repo (`script/repo/`)](#context-repo-scriptrepo)
   - [Context: Website (`script/website/`)](#context-website-scriptwebsite)
   - [Context: Blender (`script/blender/`)](#context-blender-scriptblender)
   - [Context: Unity (`script/unity/`)](#context-unity-scriptunity)
5. [Sistem Versioned Dependencies Checker](#5-sistem-versioned-dependencies-checker)
6. [Simulasi Dry-Run (Protokol Keselamatan)](#6-simulasi-dry-run-protokol-keselamatan)
7. [Troubleshooting & Solusi](#7-troubleshooting--solusi)

---

## 1. Prasyarat Sistem (Prerequisites)

All Lads Tool dirancang mandiri tanpa dependensi global yang mengotori sistem operasi. Namun, beberapa runtime dibutuhkan tergantung context yang dijalankan:

| Runtime / Engine | Minimum Versi | Context Terkait | Rekomendasi Instalasi (Windows) |
| :--- | :--- | :--- | :--- |
| **PowerShell** | 5.1 (Built-in) / 7.2+ LTS | `file/`, `repo/`, launcher | `winget install Microsoft.PowerShell` |
| **Git CLI** | v2.30+ | `repo/` | `winget install Git.Git` |
| **Node.js** | v18.0.0+ LTS | `website/` | `winget install OpenJS.NodeJS.LTS` |
| **Python** | v3.9+ | `blender/`, utilitas | `winget install Python.Python.3.11` |
| **Blender** | v3.6 LTS / v4.0+ | `blender/` | `winget install BlenderFoundation.Blender` |
| **Unity Editor** | 2021.3 LTS / 2022.3 LTS | `unity/` | Via Unity Hub |

---

## 2. Instalasi & Setup Workspace

### Clone Repositori
```bash
git clone https://github.com/pakcli/all-lads-tool.git
cd all-lads-tool
```

### Kebijakan Eksekusi PowerShell (Execution Policy)
Jika sistem Anda memblokir eksekusi skrip PowerShell, izinkan eksekusi untuk user saat ini:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

## 3. Menjalankan Toolchain

### Mode 1: Universal Launcher (`_run.ps1`)
`_run.ps1` adalah launcher portabel yang dapat diletakkan di direktori mana saja dalam drive Anda:
```powershell
.\_run.ps1
```
* **Auto-Discovery**: Memindai drive secara otomatis untuk menemukan `_mainmenu.ps1`.
* **Multi-Mainmenu Alert**: Jika ada lebih dari satu `_mainmenu.ps1` di drive, tabel ASCII akan muncul meminta Anda memilih instance target.
* **Smart Cache**: Pilihan Anda disimpan di `_run.json` sehingga proses scanning tidak akan diulang pada pemanggilan berikutnya.
* **History Stack**: Menyimpan parameter eksekusi terbaru (`0 = latest`, `1 = previous latest`, `2 = older`).

### Mode 2: Central Cockpit (`_mainmenu.ps1`)
Dijalankan langsung dari folder `all-lads-tool/`:
```powershell
.\_mainmenu.ps1
```
Menyediakan antarmuka interaktif bernomor A-Z untuk seluruh alat otomasi dengan pencarian instan dan quick re-run (`0`).

### Mode 3: Direct Standalone CLI (`_stand`)
Setiap skrip berakhiran `_stand.<ext>` dapat dijalankan secara langsung tanpa bergantung pada launcher induk:
```powershell
# Contoh menjalankan CSV to Frontmatter Converter
.\script\file\csv-to-frontmatter_stand.ps1 -TargetDir "vault/notes" -TargetCsv "data.csv"
```

---

## 4. Panduan Operasional 5 Contexts

### Context: File (`script/file/`)
Fokus pada konversi data, sanitasi format, dan manipulasi teks aman.
- **`csv-to-frontmatter_stand.ps1`**:
  Mengubah data tabular CSV menjadi dokumen Markdown dengan YAML frontmatter kompatibel Obsidian:
  ```powershell
  .\script\file\csv-to-frontmatter_stand.ps1 -TargetDir "output/notes" -TargetCsv "input.csv"
  ```
- **`dry-run-ps1.ps1`**:
  Runner simulasi untuk menguji skrip PowerShell sebelum melakukan perubahan permanen pada file.

### Context: Repo (`script/repo/`)
Fokus pada version control, keamanan riwayat git, dan otomasi branching.
- **`git-manage_stand.ps1`**:
  Manajer Git interaktif lengkap dengan penanganan stash, reflog recovery, dan branch switching.
- **`git-branch-rename_stand.ps1`**:
  Otomasi penggantian nama branch mengikuti standar penamaan datar `language-firstname-secondname`.

### Context: Website (`script/website/`)
Fokus pada client bundling, stylesheet compiler, dan inspeksi DOM.
- **`build-bundles_stand.js`**:
  Mengompilasi ES modules menjadi bundel produksi terisolasi tanpa framework berlebih.
- **`theme-compiler_stand.js`**:
  Kompilasi SCSS/CSS 1:1 dan mode sinkronisasi tema Obsidian.

### Context: Blender (`script/blender/`)
Fokus pada otomasi pemodelan 3D dan export pipeline.
- Menjalankan batch export mesh FBX/glTF dengan setting game-ready.
- Auto-clean UV map, unassigned materials, dan normal map sync.

### Context: Unity (`script/unity/`)
Fokus pada sinkronisasi aset ke dalam engine game.
- Importer otomatis dan sanitasi file metadata (`.meta`).
- Automasi build headless (`-batchmode -executeMethod`).

---

## 5. Sistem Versioned Dependencies Checker

Untuk mengatasi perbedaan versi antar proyek (misalnya Project A menggunakan Blender 3.6 LTS sementara Project B menggunakan Blender 4.2), setiap context memiliki folder:
`script/<context>/modules/dependencies-checker/`

Folder ini menampung profil kompatibilitas dalam format yang sesuai:
- **`.json`**: Definisi deklaratif universal (semver range, command requirements).
- **`.py`**: Pengecekan API internal Blender (`bpy`).
- **`.js`**: Pengecekan API bundler atau engine Node.js.
- **`.ps1`**: Pengecekan registry atau runtime Windows/PowerShell.

---

## 6. Simulasi Dry-Run (Protokol Keselamatan)

Berdasarkan aturan **`run-dry`**, dilarang mengeksekusi mutasi massal (rename file, modifikasi struktur folder, checkout paksa) tanpa preview simulasi.

Gunakan parameter `-DryRun` pada skrip yang didukung:
```powershell
.\script\file\dry-run-ps1.ps1 -ScriptPath ".\script\repo\git-branch-rename_stand.ps1"
```
Output simulasi akan menampilkan tabel ASCII berstatus `[DRY-RUN / NO CHANGE]` tanpa menyentuh disk fisik.

---

## 7. Troubleshooting & Solusi

### 1. `_run.ps1` Membuka Menu yang Salah
Hapus atau edit file cache `_run.json` di samping `_run.ps1`, atau jalankan dengan parameter `-Rescan`:
```powershell
.\_run.ps1 -Rescan
```

### 2. Error Pengecekan Eksekusi PowerShell (`PSScriptRoot` Kosong)
Pastikan Anda menjalankan skrip sebagai file, bukan menempelkan kode langsung ke konsol PowerShell. Gunakan:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\script\file\csv-to-frontmatter_stand.ps1
```

### 3. File Terkunci oleh Proses Lain (File Locker)
Gunakan utilitas pendeteksi locker di context `repo/` atau `file/` untuk melihat PID proses Windows yang menahan handle file sebelum mencoba menghapus paksa.
