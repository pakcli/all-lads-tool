---
name: brief-orang-awam-overview-dan-manfaat
aliases: [brief-orang-awam, panduan-bahasa-awam, non-technical-overview]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, brief, documentation, plain-language, non-technical]
description: Panduan penulisan brief arsitektur dan manfaat produk dalam bahasa yang ramah orang awam tanpa jargon teknis yang membingungkan.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Brief Untuk Orang Awam: Apa yang Sedang Kita Bangun & Manfaatnya (`v01-06`)

> [!NOTE]
> Dokumen ini menjelaskan secara sederhana (tanpa istilah koding) tentang apa yang sebenarnya sedang kita bangun, apa saja yang bisa dilakukan pengunjung di website, bagaimana fitur **Shareable Note / Tur Bacaan** bekerja, dan apa manfaat nyatanya.

---

## 1. Secara Sederhana: Apa yang Sedang Kita Bangun?

Bayangkan sebuah **website buku catatan digital** (seperti Wikipedia pribadi atau perpustakaan catatan Kimia) yang punya **"Pemandu Tur Suara Otomatis"** di dalamnya — gabungan antara **Audiobook**, **Lirik Karaoke Spotify**, dan **Asisten Presentasi**.

Secara garis besar, sistem yang kita bangun terdiri dari **3 bagian sederhana**:

1. **Halaman Catatan yang Saling Terhubung (Website)**:
   Tempat semua materi atau catatan berada. Satu halaman bisa punya tautan (*link*) ke halaman-halaman terkait lainnya.
2. **Pemutar & Penunjuk Visual di Layar (Companion Reader)**:
   Kotak pemutar di bagian bawah layar yang membacakan isi halaman dengan suara, menampilkan teks *subtitle* di bawah, **menggarisbawahi kalimat yang sedang dibaca**, dan **memberi kotak penunjuk pada kata yang sedang diucapkan** langsung di artikel web.
3. **Daftar Urutan Bacaan yang Bisa Dibagikan (Tabel CSV)**:
   Daftar jadwal sederhana yang berisi: *"Buka halaman apa, di detik ke berapa, kalimat mana yang ditunjuk di layar, dan kalimat apa yang diucapkan."*

---

## 2. Orang yang Buka Website Bisa Ngapain Aja?

Pengunjung yang datang ke website tidak perlu mengerti teknis sama sekali. Mereka langsung bisa:

* **Langsung Klik Play & Dengarkan Isi Halaman (Termasuk Panel Samping & Info Halaman)**:
  Begitu klik tombol Play, website langsung membacakan isi halaman dari atas ke bawah. Pengguna bahkan bisa memilih bagian layar mana saja yang mau ikut dibacakan dan ditunjuk:
  * **Article**: Isi tulisan utama di tengah halaman.
  * **Left Sidebar (Explorer)**: Daftar folder dan menu halaman di panel kiri.
  * **Right Sidebar (TOC + Backlinks)**: Daftar Isi (*Table of Contents*) dan Tautan Balik (*Backlinks*) di panel kanan.
  * **Page Properties**: Judul halaman, jejak lokasi (*breadcrumbs*), info tanggal/waktu baca, dan tabel properti catatan di bagian atas.
  Layar (termasuk panel samping) akan *scroll* (menggulir) sendiri mengikuti bagian yang sedang dibaca.
* **Melihat Penunjuk Kalimat & Kata Secara Langsung (Seperti Karaoke)**:
  * **Satu Garis Bawah (Single Underline)**: Menunjukkan satu baris/kalimat yang sedang dibahas.
  * **Kotak Kata Aktif (Stroke Only, Tanpa Garis Bawah Ganda)**: Melompat dari kata ke kata sesuai ucapan suara, baik di kotak *subtitle* bawah maupun langsung di teks artikel atau panel samping.
* **Geser Timeline (Scrubbing) dengan Mulus**:
  Pengunjung bisa menggeser garis waktu maju/mundur untuk langsung melompat ke bagian kalimat atau kata tertentu.
* **Pindah Halaman Otomatis & Tombol `<` / `>`**:
  * Kalau tur bacaan membahas beberapa halaman sekaligus, website **otomatis pindah halaman sendiri** tanpa menghentikan suara.
  * Tombol **`<`** di sebelah garis waktu: kalau halaman sedang berjalan, klik `<` akan mengulang halaman itu dari awal; kalau diklik saat baru mulai, dia mundur ke halaman sebelumnya. Saat kursor diarahkan (*hover*), muncul info nama halamannya.
  * Tombol **`>`**: langsung melompat ke halaman berikutnya (lengkap dengan info nama halaman saat di-*hover*).
* **Atur Kecepatan Suara, Nada (Pitch), dan Jeda Antar-Kalimat (Pace)**:
  * **Speed (`-2` sampai `5x`)**: Bisa diperlambat (`0.25x` – `0.75x`) atau dipercepat hingga `5x` lipat secara *real-time*.
  * **Pitch (`ON / OFF`)**: Mengatur apakah nada suara ikut berubah mengikuti kecepatan atau tetap normal.
  * **Pace / Sentence Delay (`Fast`, `Medium`, `Slow`, atau Angka Custom)**: Mengatur jeda napas antar-kalimat (dan otomatis mengatur jeda per kata sebesar **1/4 dari jeda kalimat**).

---

## 3. Fitur "Shareable Note" dari Website: Bisa Apa Saja?

Salah satu kekuatan utama yang kita bangun adalah **kemudahan mengambil isi catatan dari website, mengolahnya dengan AI, dan membagikan "Tur Bacaan" ke orang lain**:

1. **Pilih Cakupan Catatan (Scope) yang Mau Dibagikan**:
   Di panel pengaturan (`⚙️`), pengguna bisa memilih seberapa luas catatan yang ingin diambil:
   * **Active Only**: Hanya halaman yang sedang dibuka saat ini.
   * **+ Wikilinks**: Halaman ini ditambah semua halaman lain yang ditautkan di dalamnya.
   * **All Relations**: Seluruh jaringan catatan yang masih berhubungan dengan topik ini.
   * **All Pages**: Semua halaman di dalam website.
2. **Pilih Gaya Pembacaan (`Per-Word by Line` atau `Line per Line`) & Bahasa**:
   Bisa memilih apakah ingin dibacakan **per potongan 5–7 kata** atau **satu kalimat utuh per baris**, serta memilih bahasa narasi (Indonesia, Inggris, Jepang, Mandarin, Arab, dll.).
3. **Sekali Klik `[Copy Prompt]` (Bersih Tanpa Emoji)**:
   Satu klik langsung menyalin instruksi siap pakai beserta seluruh isi catatan (yang sudah dibersihkan otomatis dari emoji) untuk ditempelkan ke ChatGPT, Claude, atau Gemini. AI akan langsung menghasilkan jadwal tur bacaan (CSV).
4. **Simpan, Buka Halaman dari Daftar, & Bagikan (`[Export CSV]` / `[CSV Clipboard]`)**:
   * Setiap tur yang dimasukkan otomatis tersimpan di daftar **Recent Files** di browser.
   * Di setiap baris data yang tersimpan, ada **Dropdown Halaman (`Pages`)**: pengguna bisa melihat halaman apa saja yang ada di dalam tur tersebut, dan **begitu diklik, website langsung membuka halaman itu** di menit/detik yang tepat.
   * Ada tombol **`[Export CSV]`** (unduh jadi file `.csv`) dan **`[CSV Clipboard]`** (salin isi CSV) supaya alur bacaan tersebut bisa langsung dikirim ke teman, murid, atau kolega.

---

## 4. Manfaat Nyatanya Apa? (Kenapa Ini Bagus?)

1. **Membaca Materi Berat Jadi Jauh Lebih Mudah & Fokus**:
   Cocok untuk pelajar, peneliti, atau pembaca umum. Karena telinga mendengar suara dan mata dituntun oleh garis bawah serta kotak per kata, pembaca tidak mudah terdistraksi atau kehilangan baris.
2. **Mengubah Website Catatan Biasa Menjadi "Kursus / Tur Terpandu"**:
   Biasanya orang bingung harus mulai baca dari halaman mana saat membuka website dokumentasi atau *digital garden*. Dengan alat ini, pemilik web atau pembaca bisa membuat **"Playlist Tur"** yang menuntun pembaca dari Halaman A -> Halaman B -> Halaman C secara berurutan.
3. **Hemat Waktu dengan Bantuan AI & Gampang Dibagikan**:
   Tidak perlu membuat jadwal *subtitle* atau rekaman manual berjam-jam. Cukup klik `[Copy Prompt]`, minta AI buatkan naskah turnya, tempel kembali, dan bagikan lewat `[Export CSV]` atau `[CSV Clipboard]` ke siapa saja.
