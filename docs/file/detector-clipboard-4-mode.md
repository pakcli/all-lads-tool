---
title: PolyClip 4-Mode Clipboard Suite & Path Protocol
tool: detector-clipboard-4-mode.ps1
adapter: script/file/adapter/detector-clipboard-4-mode.psm1
category: system-clipboard-protocol
runtime: PowerShell 5.1+ / 7+ (WPF STA)
aliases: [polyclip, clipboard-4-mode, detector-clipboard, drive-color-coding]
tags: [all-lads-tool, clipboard, wpf, path-visualizer, explorer, drive-color, selectable-textbox]
---

# `detector-clipboard-4-mode.ps1` — PolyClip 4-Mode Clipboard Architecture & Drive Color Protocol

> [!INFO]
> **Context**: `file` | **Orchestrator**: `script/file/detector-clipboard-4-mode.ps1`  
> **Adapter**: `script/file/adapter/detector-clipboard-4-mode.psm1`  
> **Skill**: `all-lads-tool/skill/detector-clipboard-4-mode.md`  
> **Options File**: `script/file/detector-clipboard-4-mode.json`

---

## 1. Filosofi & Visi Keseluruhan (The Whole Idea)

PolyClip dirancang sebagai pengelola clipboard desktop berkecepatan tinggi tanpa sniffer background yang rakus resource. Tool ini mentransformasikan setiap objek clipboard ke dalam **4 Mode Universal** secara instan (JIT), dengan antarmuka gelap (*Full-Dark*) yang ramah mata, layout akordeon ultra-ringkas (tepat 1 baris per item), dan fitur visualisasi path sistematis.

```
+-------------------------------------------------------------------------------------------------------------------+
|   i   | 1. PLAIN TEXT    | 2. FILE PATH (Selectable)   | 3. CONTENT (Preview) | 4. EXACT FILE (Reveal) | ACTIONS  |
+-------+------------------+-----------------------------+----------------------+------------------------+----------+
|  [i]  | my-script.ps1... | <workspace_root>\script\file [📋][.] | function Start { ... | my-script.ps1 [📋] 34KB | [Ed][Dp][X]
+-------------------------------------------------------------------------------------------------------------------+
```

---

## 2. Standar Pewarnaan Drive (Drive Color-Coding Protocol)

Untuk mempercepat identifikasi lokasi file secara visual tanpa harus membaca seluruh path secara perlahan, diterapkan aturan warna sistematis pada **Kolom 2 (FILE PATH)**:

| Drive / Partisi | Warna Visual | Kode Hex | Arti & Konteks |
| :--- | :--- | :--- | :--- |
| **`C:`** | **Merah (System / "Fistem")** | `#F87171` (Red-400) | Partisi Windows/OS, `System32`, `AppData`, `Program Files`, atau area sistem krusial yang memerlukan kehati-hatian tinggi. |
| **`D:`** | **Biru (Data Secondary)** | `#38BDF8` (Sky-400) | Partisi penyimpanan data sekunder, installer, media, atau arsip umum. |
| **`E:` atau lebih tinggi** (`E:`, `F:`, `G:`, `H:`, ...) | **Hijau (Projects / Workspace)** | `#34D399` (Emerald-400) | Workspace pengembangan proyek (`E:\workspace\...`), repositori aktif, flashdisk/eksternal, atau folder kerja utama. |
| **UNC / Network / Lainnya** (`\\server\...`) | **Indigo** | `#818CF8` (Indigo-400) | Network share, path relatif, atau virtual drive non-standar. |

### Contoh Representasi Nyata:
* `C:\Windows\System32\cmd.exe` &rarr; Teks ditampilkan dengan warna **Merah**.
* `D:\backup\archive-2026.zip` &rarr; Teks ditampilkan dengan warna **Biru**.
* `E:\workspace\project\script\file` &rarr; Teks ditampilkan dengan warna **Hijau**.

---

## 3. Fitur Selectable TextBox pada File Path

Sebelumnya, path hanya berupa tombol statis yang meng-copy keseluruhan path. Namun dalam alur kerja coding nyata, developer sering kali hanya membutuhkan **sebagian** (snippet) dari path (misalnya hanya subfolder `script\file` atau nama folder proyek tanpa drive letter).

### Spesifikasi Interaksi Kolom 2:
1. **Selectable Read-Only TextBox**:
   - Menggunakan WPF `TextBox` dengan `IsReadOnly = True`, `Background = Transparent`, dan `BorderThickness = 0`.
   - User dapat mengklik di sembarang titik path, men-drag kursor untuk memblok bagian teks tertentu, lalu menekan `Ctrl + C` untuk meng-copy bagian tersebut saja.
   - Font: `Consolas, Segoe UI` (Monospace untuk keterbacaan struktur direktori).
2. **Dedicated Clipboard Copy Button (`[📋]`)**:
   - Terletak tepat di samping teks path.
   - 1-Klik kiri langsung menyalin **keseluruhan path absolut** (Mode 2) ke clipboard Windows tanpa perlu blok manual.
3. **Accordion Expand Button (`[...]`)**:
   - Mengubah baris 26px menjadi kotak teks scrollable 90px jika direktori sangat panjang / dalam, dan dapat diciutkan kembali dengan tombol `[^]`.

---

## 4. Arsitektur 5 Kolom Terpadu (Unified 5-Column Architecture)

Berdasarkan evaluasi standard `wdyt`, redundansi antara Plain Text dan File Content disatukan menjadi 1 kolom **CONTENT** polimorfik cerdas:

| Kolom | Judul | Lebar | Keterangan & Perilaku Interaksi |
| :---: | :--- | :---: | :--- |
| **0** | `i` | `34px` | Tombol inspeksi & edit metadata serialisasi PowerShell (`Open-EditModal`) |
| **1** | `CONTENT` | `1.6*` | **Unified Content**: Teks clipboard (`[TXT]`) atau preview isi kode file (`[FILE]`) |
| **2** | `FILE PATH` | `1.2*` | Path absolut dengan pewarnaan drive (`C:` Merah, `D:` Biru, `E:+` Hijau) & Selectable TextBox |
| **3** | `EXACT FILE (NAME \| SIZE)` | `1.2*` | Nama file fisik `CF_HDROP` (klik untuk buka Explorer) + tombol `📋` + badge ukuran |
| **4** | `ACTIONS` | `90px` | Tombol aksi: **`Copy`** (promosikan ke #1 latest & copy) dan **`Del`** (hapus) |

### Kolom 0 — INFO & INSPECT (`[ i ]`)
* **Hanya Berisi Tombol `[ i ]`**: Tombol inspeksi interaktif ultra-kompak (lebar 34px) berwarna biru langit (`#38BDF8`).
* **Klik Tombol `[ i ]`**: Membuka modal overlay **Edit Item Content** untuk meninjau detail metadata lengkap dalam format representasi objek serialisasi:
  ```powershell
  [string]@{Id=...; Timestamp=...; RawType=...; DetectedPath=...; FileName=...; FileSizeStr=...; IsOpenable=...; OpenStatus=...; Mode1_Text=...; Mode2_Path=...; Mode3_Content=...; Mode4_File=...}.Mode1_Text
  ```
* **Dapat Diedit & Disimpan**: Perubahan pada format objek maupun teks bebas dapat langsung disimpan melalui tombol **Save Only** atau **Save & Set at First**.
* **Tooltip Waktu**: Menyorot kursor ke tombol `[ i ]` menampilkan timestamp waktu klip dibuat (misal `[20:19:57]`).

### Kolom 1 — CONTENT (Unified Text & File Content)
* **Polimorfik & Adaptif**:
  - **Teks Murni**: Menampilkan teks string mentah dengan badge **`[TXT]`** biru (`#38BDF8`). Auto-unwrap otomatis membersihkan dump stringifikasi.
  - **File Kode/Teks**: Menampilkan preview 15 karakter baris pertama kode dengan badge **`[FILE]`** hijau emerald (`#34D399`).
  - **File Binary**: Menampilkan label aman `[FileName] (binary asset)` tanpa memicu error I/O.
* **Akordeon Scrollable (`[...]`)**: Mengklik `...` membuka textbox scrollable untuk meninjau keseluruhan teks atau kode script sebelum di-copy, dan dapat diciutkan kembali via `[^]`.
* **1-Klik Copy**: Mengklik area sel langsung menyalin teks atau konten file ke clipboard Windows.

### Kolom 2 — FILE PATH
* Menampilkan path absolut file/folder dengan pewarnaan drive (`Red` / `Blue` / `Green`).
* Berbasis **Selectable TextBox** untuk seleksi teks granular + tombol `📋` untuk copy instan full path.
* **Indikator File Hilang (`[ ✕ ]`)**: Jika file pada path tersebut sudah tidak ada lagi di direktori (terhapus atau dipindahkan), sel otomatis menampilkan badge merah **`[ ✕ ]`** dengan teks path bergaris coret (*strikethrough*), dan tooltip status memberi peringatan bahwa file telah hilang.

### Kolom 3 — EXACT FILE (`CF_HDROP`)
* **Klik Teks Nama File**: Membuka Windows File Explorer dan langsung **menyorot/memilih** file fisik tersebut menggunakan perintah native:
  ```powershell
  explorer.exe /select,"$filePath"
  ```
* **Tombol Clipboard (`[📋]`)**: Menyuntikkan stream `CF_HDROP` ke clipboard sehingga file dapat langsung di-paste (`Ctrl+V`) di Explorer mana saja.
* **Badge Ukuran**: Menampilkan badge ukuran file (misal `138 KB`) dengan highlight pink `#F472B6`.
* **Indikator File Hilang (`[ ✕ ]`)**: Jika file fisik sudah tidak ada lagi di direktori tujuan, sel otomatis menampilkan badge merah **`[ ✕ ]`** dengan nama file bergaris coret (*strikethrough*). Aksi pembukaan Explorer dan copy diblokir dengan aman.

### Kolom 4 — ACTIONS (`Copy` & `Del`)
* **Tombol `[Copy]`** (sebelumnya `Dup`): Menyalin item ke clipboard Windows dan mempromosikannya ke urutan **#1 Latest** (item asli tetap tersimpan dalam riwayat).
* **Tombol `[Del]`**: Menghapus item dari riwayat clipboard secara aman.

---

## 5. Mekanisme Anti-Feedback Loop (Duplikasi Presisi)

Saat tombol **`[Copy]`** ditekan:
1. `Promote-ToFirst` menyisipkan item baru di urutan **#1 Latest** dan menyalin nilainya ke clipboard Windows.
2. Variabel `$script:suppressLiveCaptureUntil` aktif selama 2 detik untuk **membungkam timer background (`liveTimer`)**.
3. Timer background tidak akan salah mengira bahwa clipboard write internal tersebut adalah aksi copy dari luar.
4. **Hasil**: Item terduplikasi tepat **1 kali saja** (tanpa memunculkan phantom row teks kedua).

---

## 6. Persistensi Sesuai Standar Skill

Mengikuti skill [`save-option-as-exact-executor-name-json`](file:///<workspace_root>/skill/save-option-as-exact-executor-name-json.md):
* Data riwayat disimpan secara atomik pada file JSON yang persis dengan nama executor:
  `script/file/detector-clipboard-4-mode.json`
* State toggle **`Show All`** (berada di samping tombol `Refresh`) persisten selama sesi panel aktif.

---

## 7. Dekonstruksi Modular Flat (Anti-Generic Core-Engine Protocol)

Sesuai dengan standar arsitektur dan skill [`anti-generic-core-engine-naming`](file:///<workspace_root>/skill/anti-generic-core-engine-naming.md), adapter `detector-clipboard-4-mode.psm1` didekonstruksi menjadi **7 submodul `.psm1` flat** langsung di dalam direktori `script/file/adapter/` tanpa subfolder bersarang:

```
script/file/
├── detector-clipboard-4-mode.ps1            # Main CLI & Panel Dispatcher (Orchestrator)
├── detector-clipboard-4-mode.json           # Atomic Persistence Store
└── adapter/
    ├── detector-clipboard-4-mode.psm1       # Master Facade (imports flat submodules)
    ├── clipboard-history-store.psm1         # Persistence Service & JSON Sanitizer
    ├── clipboard-jit-inspector.psm1         # JIT Inspection & Attribute Probing
    ├── clipboard-mode-transformer.psm1     # 4-Mode Dispatcher & Feedback Suppression
    ├── drive-color-protocol.psm1           # Drive Hierarchy Palette Engine
    ├── ui-card-renderer.psm1               # WPF Row Cards, Accordions, Buttons & Badges
    ├── panel-window-host.psm1              # Full-Dark WPF Window Host & Live DispatcherTimer
    └── cli-console-dashboard.psm1          # Terminal Interactive ANSI Dashboard
```

Arsitektur flat `.psm1` ini memastikan setiap berkas merupakan modul PowerShell resmi (*first-class module*) yang dapat diimpor secara modular, mudah diuji secara independen, dan konsisten dengan foldering structure adapter tools lainnya.

---

## 8. Git Multi-Protocol Widget (HTTPS, SSH, GitHub CLI)

Ketika clipboard mendeteksi URL atau perintah kloning Git (misalnya `https://github.com/owner/repo`, `git@github.com:...`, `gh repo clone ...`, atau `owner/repo`), antarmuka secara otomatis beralih ke widget Git Multi-Protocol:

```text
+-------------------------------------------------------------------------------------------------------------------+
|   i   | GIT PROTOCOL WIDGET (Tabs + Selectable Box) | REPO SLUG (Col 2)          | ACTION                          |
+-------+---------------------------------------------+----------------------------+---------------------------------+
|  [i]  | [HTTPS] [SSH] [GitHub CLI] [url...   ] [📋] | github.com/owner/repo      | [Copy] [Del]                    |
+-------------------------------------------------------------------------------------------------------------------+
```

- **Pill Tabs**: Tombol `[HTTPS]`, `[SSH]`, dan `[GitHub CLI]` memungkinkan pengalihan instan antar format URL kloning.
- **Selectable URL Box**: Memungkinkan seleksi sebagian teks atau melihat URL lengkap.
- **Dedicated Copy Button (`[📋]`)**: Menyalin format yang sedang aktif ke clipboard Windows.
- **Interoperabilitas dengan `git-manage.ps1`**: URL kloning yang tersalin di clipboard secara otomatis dideteksi dan dijadikan default input saat menjalankan wizard kloning pada `script/repo/git-manage.ps1`.

