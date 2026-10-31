---
title: Main Idea
version: v01-00
status: active
dependencies:
  - "[[modular-architecture-standard]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
  - "[[donot-overengineer-instructions]]"
---

# Brief v01-00: Main Idea

## Status
- **Status**: Milestone Reference (Archived Baseline)
- **Version**: v01-00
- **Scope**: Original Core Concept & Vision

---

## 1. Overview
All Lads Tool (`all-lads-tool/`) lahir sebagai perkakas otomasi developer cross-runtime mandiri untuk ekosistem Windows, Web, dan Vintage Computing Arcade. Didesain untuk menyatukan skrip otomasi yang tercecer, membasmi hardcoded path, dan menyediakan antarmuka terpusat bagi developer dan agen AI.

## 2. Core Pillars Awal
1. **Zero Hardcoded Variables (Rule #001)**:
   - Dilarang keras hardcode drive letter (`C:`, `D:`) atau username lokal.
   - Menggunakan resolusi dinamis berbasis `$PSScriptRoot`, `__dirname`, dan relative depth.
2. **Multi-Runtime Tooling**:
   - Skrip dikelompokkan berdasarkan runtime bahasa pemrograman (`powershell`, `javascript`, `python`, `bash`, `bat`).
3. **Master Central Launcher**:
   - Pintu masuk tunggal menggunakan interactive cockpit (`_mainmenu.ps1`) untuk memicu eksekusi cepat.
