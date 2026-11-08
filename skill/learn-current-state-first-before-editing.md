---
name: learn-current-state-first-before-editing
aliases: [learn-current-state-first, scan-lapangan-before-suggesting, no-hallucinated-architecture, adapt-existing-structure]
category: WORKFLOW_PROTOCOL
tags: [all-lads-tool, workflow, inspection, ground-truth, architecture, lapangan, discovery]
description: Mandatory protocol to inspect and learn the live filesystem, existing folders, exported modules, and existing configuration before proposing any architecture, structural changes, or new directories.
dependencies:
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[donot-ngada-ngada-exact-lapangan-variables]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[asci-tree-codeblock-standard-without-branch]]"
  - "[[modular-architecture-standard]]"
  - "[[confirmation-to-proceed-brief-overview-options]]"
pros:
  - "Stops the agent from inventing non-existent folders (e.g. shared, common) that do not exist in the codebase"
  - "Ensures new features adapt to the existing directory layout instead of forcing unnecessary restructures"
  - "Forces direct file system discovery (Get-ChildItem) before formulating technical proposals"
cons:
  - "Requires an upfront command call to scan directories before giving architecture advice"
---

# Learn Current State First Before Editing (`learn-current-state-first`)

> [!CAUTION]
> **ABSOLUTE INVARIANT**:
> **PELAJARI DULU KONDISI LAPANGAN (CURRENT STATE) SEBELUM MEMBERIKAN USULAN ATAU MENGUBAH KODE**.
> 1. **Dilarang Berasumsi Struktur Folder**: Jangan pernah menyarankan folder baru (misalnya `src/shared/`, `src/common/`, `src/utils/`) sebelum memverifikasi apakah folder itu ada atau apakah sudah ada folder sejenis yang sedang dipakai.
> 2. **Inspeksi Langsung**: Lakukan `Get-ChildItem` atau pembacaan file konfigurasi untuk memetakan struktur nyata saat ini.
> 3. **Adaptasi Pola Lapangan**: Jika proyek sudah memiliki `src/components/`, `src/lib/`, dan `src/data/`, gunakan tempat yang sudah ada. Jangan memecah arsitektur hanya karena kebiasaan template luar.
> 4. **Hanya Buat Jika Benar-Benar Perlu**: Penambahan folder baru harus didiskusikan secara eksplisit dan disetujui, bukan diasumsikan sudah ada.

---

## 1. Masalah yang Diselesaikan

Sering kali AI mengusulkan solusi dengan asumsi bawaan (contoh: *"taruh saja di `src/shared/`"*), padahal di proyek nyata folder tersebut tidak ada. Hal ini membingungkan pengembang dan merusak struktur yang sudah berjalan.

Protokol ini mewajibkan:
1. Scan lapangan terlebih dahulu.
2. Jelaskan keadaan saat ini apa adanya.
3. Baru usulkan solusi yang menempel secara natural pada arsitektur yang sudah ada.

---

## 2. Alur Kerja 3 Tahap

```text
+-------------------------------------------------------------------------------+
|                 LEARN CURRENT STATE PIPELINE                                  |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ Pertanyaan / Tugas Terkait Struktur atau Arsitektur ]                     |
|                           |                                                   |
|                           v                                                   |
|  [ TAHAP 1: INSPEKSI FISIK LAPANGAN ]                                         |
|  - Jalankan inspeksi direktori nyata (Get-ChildItem)                           |
|  - Petakan folder dan file yang benar-benar ada di disk                       |
|                           |                                                   |
|                           v                                                   |
|  [ TAHAP 2: PEMETAAN & ADAPTASI ]                                             |
|  - Identifikasi tempat yang sudah ada untuk meletakkan fungsi baru            |
|  - Cocokkan konvensi proyek (Next.js, Remotion, Obsidian plugin, dll.)        |
|                           |                                                   |
|                           v                                                   |
|  [ TAHAP 3: USULAN BERDASARKAN KENYATAAN ]                                    |
|  - Paparkan struktur nyata menggunakan ASCII tree standard tanpa branch       |
|  - Tunjukkan letak file baru berdasarkan struktur eksisting                   |
+-------------------------------------------------------------------------------+
```

---

## 3. Matriks Perilaku: Asumsi vs. Berdasarkan Lapangan

| Kasus | DILARANG: Asumsi / Mengarang | WAJIB: Pelajari Lapangan Dulu |
| :--- | :--- | :--- |
| **Menyimpan Fungsi Bersama** | "Pindahkan ke `src/shared/`" tanpa memeriksa isi `src/` | Memeriksa `src/`, melihat adanya `src/lib/utils.ts` atau `src/components/`, lalu menempatkannya di sana |
| **Menambah Multi-Video Remotion** | "Bikin subproject baru via CLI" yang membuat nested repo | Memeriksa `src/remotion/Root.tsx`, melihat multi `<Composition>` sudah didukung native di satu project |
| **Lokasi Aset Gambar/Media** | Mengasumsikan path relatif acak | Memeriksa `public/` atau direktori aset yang terkonfigurasi di bundler |

---

## 4. Checklist Lapangan Sebelum Menjawab

- [ ] Apakah saya sudah mengecek struktur folder nyata dengan command inspeksi?
- [ ] Apakah nama folder yang saya sebutkan benar-benar ada di disk saat ini?
- [ ] Jika mengusulkan file baru, apakah letaknya sudah selaras dengan folder yang sudah ada?
- [ ] Apakah format pohon direktori menggunakan format ASCII standard tanpa simbol branch bercabang?
- [ ] Apakah aturan `donot-code-yet` tetap dihormati?