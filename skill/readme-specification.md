---
name: readme-specification
aliases: [readme-standard, readme-structure, readme-authoring-standard, readme-protocol]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, skill, documentation, readme, front-door, standard, guide-link]
description: Standardized authoring protocol for high-impact project READMEs enforcing 4 core pillars: (1) Overview (audience, value proposition, use cases), (2) Features, (3) How It Works with a direct link to guide.md, and (4) License.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 📄 Standardized README Specification (`readme-specification`)

> [!INFO]
> **Core Mandate**: The Front Door Standard.  
> A project `README.md` must be informative, inviting, and concise. It acts as the product pitch and overview, while delegating heavy installation and terminal commands to the dedicated `GUIDE.md` (all-caps at repository root).

This skill defines the mandatory 4-pillar anatomy for all repository `README.md` documents across the ecosystem.

---

## 1. The 4 Compulsory README Pillars

Every `README.md` authored or refactored must strictly contain the following 4 sections in sequential order:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                      THE 4-PILLAR README ANATOMY                       │
├────────────────────────────────────────────────────────────────────────┤
│ 1. OVERVIEW            : Target audience, value proposition, examples  │
│ 2. FEATURES            : Core capabilities & feature highlights       │
│ 3. HOW IT WORKS        : High-level workflow + prominent GUIDE.md link │
│ 4. LICENSE & CREDITS   : Open-source license & attribution             │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Detailed Anatomy & Structure Checklist

### Pillar 1: Overview (`## 1. Overview`)
Must answer 3 fundamental questions immediately:
1. **Untuk Siapa (Target Audience)**: Who is this repository or tool built for? (e.g., student researchers, chemists, PKM developers, personal wiki curators).
2. **Bagus Kenapa (Value Proposition)**: Why should anyone care? What pain points does it solve that alternatives don't? (e.g., zero dependencies, 100% decoupling from personal notes, lightning fast builds).
3. **Case Contoh (Real-World Use Cases)**: Provide 2–3 concrete examples or scenarios showing the product in action.

### Pillar 2: Features (`## 2. Features`)
* A clear, formatted list of the top 3–6 standout capabilities.
* Highlight innovative features (e.g., Dual Graph View, Bohr atomic orbitals, automatic 404 fallbacks, dynamic theming).

### Pillar 3: How It Works & Guide Link (`## 3. How It Works`)
* **Keep It High-Level**: Explain the data flow or system concept in 1 brief ASCII diagram or 3–4 bullet points.
* **ZERO Command Bloat**: Prohibit 50 lines of shell commands here.
* **Prominent Guide Handoff**: Include a bold, clickable markdown link pointing directly to the root `GUIDE.md`:
  ```markdown
  👉 **[📖 Buka Panduan Lengkap Instalasi & Penggunaan (GUIDE.md)](./GUIDE.md)**
  ```

### Pillar 4: License (`## 4. License / Lisensi`)
* State the license clearly (e.g., MIT License, Apache 2.0).
* Include copyright notice and optional open-source community credits.

---

## 3. Bilingual Invariant: English Primary + Indonesian Secondary

All public repository READMEs must strictly implement the **Bilingual Architecture**:
1. **English as Default (Primary)**: The first half of the document must be in English under `## 🇬🇧 English`.
2. **Indonesian as Secondary**: The second half must provide the complete Indonesian version under `## 🇮🇩 Bahasa Indonesia`.
3. **Quick Navigation Header**: Place anchor jump links immediately below the project title and pitch:
   ```markdown
   [English](#-english) | [Bahasa Indonesia](#-bahasa-indonesia)
   ```

---

## 4. Standard Template for a Compliant `README.md`

```markdown
# 🚀 [Project Name / Logo]

> [Short 1-line elevator pitch]

---

## 1. Overview

### 🎯 Untuk Siapa (Target Audience)
* ...

### 💡 Bagus Kenapa (Value Proposition)
* ...

### 🧪 Case Contoh (Example Use Cases)
* **Kasus 1**: ...
* **Kasus 2**: ...

---

## 2. Features

* ✨ **Fitur 1**: Deskripsi singkat.
* ⚡ **Fitur 2**: Deskripsi singkat.
* 🎨 **Fitur 3**: Deskripsi singkat.

---

## 3. How It Works

[Diagram ASCII Alur Kerja Singkat]

> 📖 **Panduan Lengkap Instalasi & Penggunaan**:  
> Untuk langkah instalasi step-by-step, konfigurasi environment variable, dan command terminal lengkap:  
> 👉 **[Buka Panduan Lengkap (GUIDE.md)](./GUIDE.md)**

---

## 4. License (Lisensi)

Distributed under the **MIT License**. See `LICENSE` for details.
```

---

## 4. Pre-Commit Verification Checklist

- [ ] **Overview complete**: Covers target audience ("untuk siapa"), value proposition ("bagus kenapa"), and concrete examples ("case contoh").
- [ ] **Features clearly listed**: Standout capabilities highlighted with bullet points.
- [ ] **Concise How It Works**: High-level explanation without terminal bloat.
- [ ] **Prominent Guide Link**: Clickable link to root `GUIDE.md` (all-caps) present and verified.
- [ ] **License declared**: Open-source license clearly specified at the bottom.
