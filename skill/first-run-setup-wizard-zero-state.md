---
name: first-run-setup-wizard-zero-state
aliases: [first-run-wizard, cold-start-provisioning, zero-state-onboarding, oobe-shell-protocol]
category: ARCHITECTURE_AND_UIUX
tags: [all-lads-tool, uiux, architecture, cold-start, onboarding, wizard, pure-shell, zero-state]
description: Protocol and architectural standard for pure shell web applications operating on a clean-slate state (0 0 0 0 0), establishing a zero-crash public holding state and an interactive first-run setup wizard for initial admin provisioning.
pros:
  - "Eliminates intellectual property and private data leakage risks in source repositories"
  - "Provides seamless Day-0 onboarding experience for non-technical administrators"
  - "Guarantees zero-crash resilience on fresh unpopulated database deployments"
cons:
  - "Requires strict state-checking logic across all client-side view renderers"
  - "Demands defensive empty-state handling for all data-driven UI components"
---

# First-Run Setup Wizard & Zero-State Protocol (`first-run-setup-wizard-zero-state`)

## 1. Architectural Mandate: The Pure Shell Invariant

In reusable whitelabel and self-hosted application frameworks, repositories must ship as **Pure Shells**. When deployed or cloned, the system exists in a **Clean-Slate State (0 0 0 0 0)**:

```
Clean-Slate Inventory (Day-0 State):
[0] Entities/Roster : player.csv   -> 0 data rows (schema headers only)
[0] Events/Matches  : matches.csv  -> 0 data rows (schema headers only)
[0] Posts/News      : news.csv     -> 0 data rows (schema headers only)
[0] Media/Gallery   : gallery.csv  -> 0 data rows (schema headers only)
[0] Partners/Mitra  : mitra.csv    -> 0 data rows (schema headers only)
----------------------------------------------------------------------
[1] Authentication  : Single root administrator credential
```

> [!IMPORTANT]
> **ZERO-HARDCODING INVARIANT (RULE #001)**:
> Never hardcode organization, club, brand names, or pre-bundled entity data into frontend source templates.
> The framework shell is strictly tenant-agnostic. The tenant's identity is acquired dynamically via the **First-Run Setup Wizard**.

---

## 2. Dual-State View Behaviors

The system evaluates the initialization state via `manifest.json` on every page load:

```
[Application Startup]
          |
          v
[Inspect data/manifest.json]
          |
    +-----+-----+
    |           |
[Uninitialized] [Initialized]
    |           |
    v           v
State A     State B
```

### State A: Public Zero-State Holding Pattern
When an unauthenticated visitor accesses the root URL (`/`) and data is uninitialized:
1. **Zero-Crash Guarantee**: Components must never throw `TypeError: Cannot read properties of undefined` or render broken `NaN` metrics.
2. **Holding Notice**: Replaces empty tables with an official holding card stating that the season/roster is undergoing official management preparation.
3. **Hidden Multi-Entity Pickers**: Category, sport, or league switchers are completely suppressed from the DOM when entity counts are $\le 1$.
4. **Administrative Gateway**: Provides a subtle, unobtrusive entrypoint link (e.g. `[ Login Pengurus ]`) in the footer routing to `/admin`.

### State B: Admin First-Run Setup Wizard (Day-0 Provisioning)
When the root administrator logs in and data state is `0 0 0 0 0`:
1. **Navigation Interception**: The system blocks regular CRUD tables and routes directly to the **Setup Wizard**.
2. **Identity Prompt ("Ask What Name")**: First asks for the Organization/Club Name and optional Tagline.
3. **Canonical Slug Locking**: Generates an immutable, URL-safe slug (`slugify(name)`) and saves it to `manifest.json`.
4. **Seed Selection**: Offers three immediate provisioning pathways:
   - **Path 1 (1-Click Dummy Seed)**: Restores a clean mock dataset from `data-dummy/standar/`.
   - **Path 2 (Manual Entry Wizard)**: Guides manual creation of entity #1.
   - **Path 3 (CSV Archive Upload)**: Accepts an imported tabular backup.

---

## 3. UI/UX ASCII Wireframe Standards (Mobile <= 58 cols)

### Wireframe 1: Public Zero-State Holding Screen
```text
┌────────────────────────────────────────────────────────┐
│ INISIALISASI PORTAL KLUB                 [Setup Awal]  │
├────────────────────────────────────────────────────────┤
│                                                        │
│             SELAMAT DATANG DI WHITEMARK SHELL          │
│                                                        │
│ Sistem terpasang bersih (0 data). Masuk ke portal      │
│ untuk menetapkan nama klub dan melengkapi profil tim.  │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │ STATUS: MENUNGGU PENETAPAN NAMA KLUB               │ │
│ ├────────────────────────────────────────────────────┤ │
│ │ Nama Klub      : [ BELUM DITETAPKAN ]              │ │
│ │ Cabang Olahraga: Bola Voli                         │ │
│ │ Data Atlet     : 0 Pemain                          │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
├────────────────────────────────────────────────────────┤
│ Platform Cangkang Voli Murni         [ Login Pengurus ]│
└────────────────────────────────────────────────────────┘
```

### Wireframe 2: Admin First-Run Setup Wizard
```text
┌────────────────────────────────────────────────────────┐
│ PENGATURAN AWAL NAMA KLUB             [Sesi: Admin]    │
├────────────────────────────────────────────────────────┤
│ Database kosong terdeteksi (0 0 0 0 0).                │
│ Langkah 1: Tentukan identitas klub voli Anda:          │
│                                                        │
│ Nama Lengkap Klub:                                     │
│ [ Masukkan Nama Klub Voli Anda...                    ] │
│                                                        │
│ Nama Singkatan / Tagline:                              │
│ [ Masukkan Semboyan / Singkatan Tim...               ] │
│                                                        │
│ [ Batalkan ]                  [ Simpan & Lanjut Data ] │
└────────────────────────────────────────────────────────┘
```

---

## 4. Technical Implementation Pattern (Vanilla JS Guard)

```javascript
/**
 * Evaluates whether the application has undergone Day-0 initialization
 * @param {Object} manifest
 * @returns {boolean}
 */
export function isAppInitialized(manifest) {
  if (!manifest) return false;
  return Boolean(manifest.club && manifest.club.trim() !== '' && manifest.status !== 'uninitialized');
}

/**
 * Slug generator utility enforcing lowercase kebab-case
 * @param {string} title
 * @returns {string}
 */
export function generateSlug(title) {
  if (!title) return '';
  return title
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/[\s_-]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

/**
 * Renders the defensive public holding screen when uninitialized
 * @param {HTMLElement} rootContainer
 */
export function renderPublicHoldingState(rootContainer) {
  rootContainer.innerHTML = `
    <header class="header-shell">
      <div class="brand-badge">[Platform Shell]</div>
    </header>
    <main class="main-holding">
      <div class="holding-card">
        <h2>Persiapan Musim Kompetisi</h2>
        <p>Sistem web siap beroperasi. Roster atlet dan jadwal pertandingan sedang dalam tahap finalisasi manajemen tim.</p>
      </div>
    </main>
    <footer class="footer-shell">
      <a href="/admin" class="admin-link">Login Pengurus</a>
    </footer>
  `;
}
```

---

## 5. Summary Verification Checklist

- [x] **Zero Bundled PII**: Repositories contain zero real athlete names, phone numbers, or private media files.
- [x] **Safe Public Holding**: Root view renders a clean holding screen without console errors when `0 0 0 0 0`.
- [x] **Setup Prompt on First Launch**: Admin login detects uninitialized status and forces the club name setup wizard.
- [x] **Immutable Slug Generation**: Slug is generated automatically from name and locked from accidental edits in the UI.
- [x] **1-Click Seed Availability**: Admin wizard provides a direct option to populate mock data from `data-dummy/`.
