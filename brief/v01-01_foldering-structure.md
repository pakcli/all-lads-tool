---
title: Foldering Structure The Old Way
version: v01-01
status: archived
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[naming-convention-standard]]"
---

# Brief v01-01: Foldering Structure (The Old Way)

## Status
- **Status**: Milestone Reference (The Old Way)
- **Version**: v01-01
- **Scope**: Initial Language-Based Directory Topology

---

## 1. Directory Topology (Language-Driven)

Pada era ini, file dikelompokkan secara kaku berdasarkan bahasa pemrograman (*runtime*), dengan penamaan berakhiran `_stand`:

```text
all-lads-tool
	brief
	rule
	skill
	docs
		powershell
		javascript
		python
		bash
		bat
	script
		powershell
			git-manage_stand.ps1
			bump-version_stand.ps1
			modules
		javascript
			audit-codebase_stand.js
			build-bundles_stand.js
		python
			screenshot_stand.py
		bash
			check-battery_stand.sh
		bat
			start-chrome-cwp_stand.bat
	_mainmenu.ps1
	README.md
```

## 2. Karakteristik & Kekurangan
1. **Context Terpecah**:
   - Jika membuat pipeline aset 3D (Blender Python + Unity C# + trigger PS1), kodenya tersebar di 3 folder berbeda.
2. **Redundansi `_stand`**:
   - Semua executable dipaksa memakai suffix `_stand` padahal tidak ada versi non-stand.
3. **No Dedicated Multi-version Handling**:
   - Belum ada mekanisme modular untuk menangani perbedaan versi software eksternal (Blender 3 vs 4, Unity 2021 vs 2022).
