---
title: Foldering Structure The Current Adapter Way
version: v01-03
status: canonical
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[asci-tree-codeblock-standard]]"
  - "[[cross-os-zero-localhost]]"
  - "[[git-commit-convention]]"
  - "[[obsidian-wikilink-frontmatter-standard]]"
  - "[[markdown-obsidian-format-compatibility]]"
  - "[[program-standalone]]"
  - "[[program-with-adapter]]"
  - "[[program-standalone-compile]]"
  - "[[program-tostandalone-decombine]]"
  - "[[modular-versioned-dependency-checker]]"
  - "[[run-dry]]"
---

# Brief v01-03: Foldering Structure (The Current Adapter Way)

## Status
- **Status**: Canonical / Active Standard (Current)
- **Version**: v01-03
- **Scope**: Clean 2-Level Context Architecture with Self-Contained Version Adapters

---

## 1. Canonical Directory Topology

Struktur modern, bersih, dan pragmatis. Executable di root context tanpa `_stand`, dan seluruh penanganan multi-versi software dibungkus utuh di dalam folder `adapter/`:

```text
all-lads-tool
	brief
		v01-00_main-idea.md
		v01-01_foldering-structure.md
		v01-02_foldering-structure.md
		v01-03_foldering-structure.md
	skill
		modular-architecture-standard.md
		zero-hardcoded-variables.md
		naming-convention-standard.md
		asci-tree-codeblock-standard.md
		cross-os-zero-localhost.md
		git-commit-convention.md
		obsidian-wikilink-frontmatter-standard.md
		markdown-obsidian-format-compatibility.md
		modular-versioned-dependency-checker.md
		run-dry.md
		csv-to-frontmatter-compatible-parser.md
	docs
		file
		repo
		website
		blender
		unity
	script
		blender
			fbx-export.py
			adapter
				v03-06-00.py
				v04-02-00.py
		unity
			asset-importer.cs
			adapter
				v20-21-03.cs
				v20-22-03.cs
		repo
			git-manage.ps1
			git-branch-rename.ps1
			adapter
				v02-30-00.psm1
				v02-40-00.psm1
		website
			build-bundles.js
			adapter
				v18-00-00.js
				v20-00-00.js
		file
			csv-to-frontmatter.ps1
			dry-run.ps1
			batch-target-dir-rename.ps1
			batch-target-dir-rename-based-on-frontmatter-markdown-title.ps1
			batch-target-dir-rename-based-on-frontmatter-markdown-title-kebab-case.ps1
			batch-target-dir-rename-frontmatter-markdown-kebab-case-and-rename-file.ps1
			adapter
				csv-to-frontmatter.psm1
				dry-run-simulator.psm1
				kebab-case-converter.psm1
				frontmatter-title-parser.psm1
				batch-file-renamer.psm1
	_run.ps1
	_run.env
	_run.env.example
	_run.json
	_mainmenu.ps1
	_mainmenu.html
	README.md
	GUIDE.md
```

---

## 2. Invariants & Prinsip Inti v01-03

1. **Hapus Suffix `_stand`**:
   - File di root folder context (`fbx-export.py`, `git-manage.ps1`) otomatis bertindak sebagai executable utama.
2. **Self-Contained Unit di `adapter/vxx-xx-xx.<ext>`**:
   - Satu file adapter memuat 2 tanggung jawab sekaligus:
     1. `check_environment()`: Memvalidasi ketersediaan dan kesesuaian runtime versi target.
     2. `run()`: Mengeksekusi logika, sintaks, dan API khusus untuk versi tersebut.
3. **Zero Nested Chaos**:
   - Tidak ada lagi folder beranak di dalam `modules/`. Struktur rata 2 tingkat: executable utama + folder `adapter/`.
4. **Isolasi Total**:
   - Penambahan versi baru cukup menambah satu file baru di `adapter/` tanpa menyentuh atau membahayakan stabilitas kode versi lama.

---

## 3. Sistem Tracking `_run.json` & Struktur Run Multi-Versi

Untuk setiap eksekusi script atau adapter versi, **`_run.json`** bertindak sebagai *Single State of Truth* perantara eksekusi:

### 3.1 Struktur Skema `_run.json`
```json
{
  "mainMenuPath": "D:\\0pro\\pakcli-plugin\\all-lads-tool\\_mainmenu.ps1",
  "activeSlug": "all-lads-tool",
  "githubUsername": "mygithubusername",
  "githubEmailPublic": "myemail@users.noreply.github.com",
  "allowedDomains": [
    "domain.com"
  ],
  "history": [
    {
      "timestamp": "2026-10-31 20:00:00",
      "slug": "all-lads-tool",
      "targetDir": "",
      "action": "blender/fbx-export",
      "activeAdapter": "v04-02-00"
    }
  ]
}
```

### 3.2 Siklus Eksekusi Multi-Versi Berbasis `_run`
1. **Entry Portal (`_run.ps1`)**:
   - Menemukan path fisik `_mainmenu.ps1` di seluruh drive.
   - Membaca konfigurasi `_run.env` (username, email, domains).
   - Menuliskan cache path dan parameter ke `_run.json`.
2. **Dispatcher Cockpit (`_mainmenu.ps1`)**:
   - Membaca `_run.json` tanpa localhost.
   - Me-mount parameter `activeSlug` dan riwayat `history` stack (`0 = latest`, `1 = previous`, `2 = older`).
   - Memicu script context yang dipilih (`script/<context>/<tool>.<ext>`).
3. **Adapter Resolver di Tiap Context**:
   - Script context mendeteksi versi software di sistem user (misal Blender 4.2).
   - Script memilih `adapter/v04-02-00.py`.
   - Nama adapter aktif (`v04-02-00`) dicatat kembali ke dalam stack history `_run.json`, sehingga status versi yang dijalankan selalu terekam transparan dan dapat di-audit ulang via `0` (re-run latest).
