---
title: Foldering Structure The Semi Old Way
version: v01-02
status: archived
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[modular-versioned-dependency-checker]]"
  - "[[naming-convention-standard]]"
---

# Brief v01-02: Foldering Structure (The Semi-Old Way)

## Status
- **Status**: Milestone Reference (Transitional & Over-Engineered)
- **Version**: v01-02
- **Scope**: Context-Based Migration with Deep Nested Checker Subfolders

---

## 1. Directory Topology (The Nested Checker Way)

Pada era transisi ini, struktur mulai beralih ke Domain Contexts, namun jatuh ke dalam jebakan *deep nesting* (folder di dalam folder) untuk pengecekan versi:

```text
all-lads-tool
	brief
	rule
	skill
	docs
		file
		repo
		website
		blender
		unity
	script
		blender
			fbx-export_stand.py
			modules
				dependencies-checker
					3.6.0.json
					4.0.0.py
					4.2.0.py
				function
					mesh-utils.py
		unity
			asset-importer_stand.cs
			modules
				dependencies-checker
					2021.3.json
					2022.3.json
		repo
			git-manage_stand.ps1
			modules
				dependencies-checker
					2.30.0.json
		file
			csv-to-frontmatter_stand.ps1
			modules
				dependencies-checker
					universal.json
	_run.ps1
	_run.json
	_mainmenu.ps1
	_mainmenu.html
	README.md
	GUIDE.md
```

## 2. Karakteristik & Kekurangan
1. **Over-Engineered Hierarchy**:
   - `modules/dependencies-checker/<version>` membuat struktur terlalu dalam (*deeply nested*).
2. **Keterpisahan Antara Checker & Logika**:
   - Pengecekan ada di file JSON terpisah, tapi kode fungsi yang mengeksekusi sintaks versi tersebut terpisah lagi di file lain.
3. **Sisa Suffix `_stand`**:
   - Masih menyertakan `_stand` di nama file executable utama.
