---
name: detector-clipboard-4-mode
aliases: [polyclip, clipboard-4-mode, detector-clipboard, clipboard-transformer, win-v-override]
category: SYSTEM_CLIPBOARD_PROTOCOL
tags: [all-lads-tool, clipboard, electron, vscode, obsidian, explorer, windows, zero-sniffer, wpf-panel, win-v-override, full-dark, inline-editor]
trigger: on_demand
description: Dual-layout 4-mode clipboard transformer with zero-sniffer JIT architecture, native Win+V override, full dark styling (zero white glare), right-click promotion, and inline Edit/Duplicate/Delete controls.
---

# Detector Clipboard 4-Mode Protocol (`detector-clipboard-4-mode`)

## 1. Panel Layout & Interaction Standards

| Kolom | Label | Fungsi & Perilaku |
| :--- | :--- | :--- |
| **0** | **TIME** | Menampilkan jam copy. Klik kiri/kanan mempromosikan item ke urutan teratas (#1 Latest) & meng-copy ke Windows clipboard. |
| **1** | **1. PLAIN TEXT** | Meng-copy teks murni / nama file. |
| **2** | **2. FILE PATH** | Meng-copy path absolut bersih tanpa URI junk. |
| **3** | **3. FILE CONTENT** | **🟢 Background Hijau** untuk `.md` / code (meng-copy isi teks file). **🔴 Background Merah `?`** untuk file binary / unreadable. |
| **4** | **4. EXACT FILE** | Menginjeksi `CF_HDROP` untuk paste file fisik ke Windows Explorer. |
| **5** | **ACTIONS** | Tombol cepat: `[Edit]` (Buka Text Editor), `[Dup]` (Duplikasi ke #1), `[Del]` (Hapus dari history). |

---

## 2. Fitur Baru

1. **Full Dark Styling (Zero White Glare)**:
   Tombol disabled (`-`) kini menggunakan custom WPF ControlTemplate dengan warna gelap (`#161618` dengan border `#202024` dan teks redup `#4B4B54`). Tidak ada lagi kotak putih yang menyilaukan mata.
2. **Assigned Textbox Dihapus**:
   Area bawah kini 100% bersih, memberikan ruang maksimal untuk melihat baris riwayat.
3. **Right-Click Promotion**:
   Klik kanan pada baris atau kartu mana saja akan langsung:
   - Mempromosikan item tersebut menjadi **#1 Latest** di paling atas.
   - Meng-copy nilainya ke clipboard Windows aktif.
4. **Modal Text Editor**:
   Klik tombol `[Edit]` pada kolom aksi untuk memunculkan panel editor teks multiline dengan 3 tombol:
   - `[Cancel]`: Tutup tanpa menyimpan.
   - `[Save Only]`: Simpan teks yang diedit ke database.
   - `[Save & Set as #1]`: Simpan, jadikan item teratas (#1), dan masukkan ke clipboard Windows.
5. **Drive Color-Coding Protocol (Kolom 2 - File Path)**:
   - **`C:`** (Sistem/OS): **Merah** (`#F87171`)
   - **`D:`** (Data Sekunder): **Biru** (`#38BDF8`)
   - **`E:` atau lebih tinggi** (Proyek/Workspace/Flashdisk): **Hijau** (`#34D399`)
   - Format: Selectable read-only `TextBox` (teks bisa diblok/highlight cursor secara granular) + tombol `[📋]` untuk copy full path instan.
6. **File Reveal & CF_HDROP Stream (Kolom 4 - Exact File)**:
   - Klik teks nama file &rarr; Otomatis membuka dan menyorot file di Windows File Explorer (`explorer.exe /select,"<filepath>"`).
   - Tombol `[📋]` di samping nama &rarr; Menyalin stream `CF_HDROP` untuk paste file fisik ke Windows Explorer.
   - Badge ukuran file (misal `138 KB`) ditampilkan jelas di sebelah kanan.

---

## 3. Dokumentasi Arsitektur Lengkap
Detail spesifikasi teknis dan implementasi kode terdokumentasi di:
* [`docs/file/detector-clipboard-4-mode.md`](file:///E:/proj/all-lads-tool/docs/file/detector-clipboard-4-mode.md)

---

## 4. Cara Menjalankan

* **Buka Panel Langsung**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File "E:\proj\all-lads-tool\detector-clipboard-4-mode.ps1" -Panel
  ```
* **Atau gunakan Shortcut Win+V**:
  Jalankan daemon satu kali:
  ```powershell
  powershell -ExecutionPolicy Bypass -File "E:\proj\all-lads-tool\daemon-override-win-v.ps1"
  ```
  Lalu cukup tekan **`Win + V`** di mana saja.
