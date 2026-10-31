---
name: dedicated-guide-specification
aliases: [guide-standard, guide-vs-brief-separation, operational-guide-spec, install-and-use-guide]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, skill, documentation, guide, brief, runbook, install-and-use]
description: Standardized protocol enforcing the separation of concerns between Architectural Briefs (system contracts, topologies, invariants) and Dedicated Operational Guides (guide.md for prerequisites, installation, CLI commands, and troubleshooting).
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# 📖 Dedicated Guide vs. Brief Separation Standard (`dedicated-guide-specification`)

> [!INFO]
> **Core Principle**: Separation of Concerns — Architect / RFC (`brief/`) vs Operator / Practitioner (`GUIDE.md`).  
> **Rule of Thumb**: System invariants and topological designs belong in `brief/vXX-XX_*.md`. Actionable step-by-step install commands, prerequisites, terminal walkthroughs, and error troubleshooting belong in a dedicated all-caps `GUIDE.md` at repository root beside `README.md`.

This skill establishes the universal specification for separating high-level architectural contracts from day-to-day operational execution manuals.

---

## 1. The Core Problem: Architectural Bloat

When installation instructions, shell commands, and debugging recipes are crammed into an architectural brief:
1. **Architectural Clutter**: System designers and AI agents looking for boundaries, data schemas, and invariants get lost in terminal walkthroughs.
2. **Version Bump Overhead**: A minor CLI flag change or Node.js patch forces an unnecessary revision/bump to the immutable architectural brief (`brief/v01-01_*`).
3. **Operator Frustration**: End-users who just want to install and preview the project must read through pages of architectural RFCs, data flow charts, and invariants.

```text
┌────────────────────────────────────────────────────────────────────────┐
│               SEPARATION OF CONCERNS: BRIEF vs. GUIDE                 │
├────────────────────────────────────────────────────────────────────────┤
│ ┌──────────────────────────────────┐ ┌───────────────────────────────┐ │
│ │   ARCHITECTURAL BRIEF (brief/)   │ │    OPERATIONAL GUIDE (guide)  │ │
│ ├──────────────────────────────────┤ ├───────────────────────────────┤ │
│ │ • System definition & ecosystem  │ │ • Prerequisites & Node setup  │ │
│ │ • Directory topology & boundary  │ │ • One-time installation steps │ │
│ │ • Architectural invariants       │ │ • Copy-paste CLI commands     │ │
│ │ • Data schema & fallback logic   │ │ • Terminal output previews    │ │
│ │ • Milestone version contracts    │ │ • Error troubleshooting & FAQ │ │
│ └─────────────────┬────────────────┘ └───────────────▲───────────────┘ │
│                   │                                  │                 │
│                   └───► Links to Guide for Runbooks ─┘                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Definitive Typology: What Goes Where?

| Dimension | Architectural Brief (`brief/vXX-XX_*.md`) | Dedicated Guide (`guide.md`) |
| :--- | :--- | :--- |
| **Placement Location** | Quarantined inside `brief/` (`brief/vXX-XX_*.md`) | **Repository ROOT directly beside `README.md`** (`./GUIDE.md`, all-caps) |
| **Primary Audience** | AI Planner, System Architect, Codebase Reviewer | End-User, DevOps Operator, Daily Contributor |
| **Document Purpose** | Single Source of Truth (SSOT) for system contracts & design | Practical runbook for installing, running, and using |
| **Frequency of Change** | Low (only on milestone/architecture evolution) | Medium to High (tooling updates, flags, FAQs) |
| **Installation Section** | **Optional / High-Level Matrix**: Summarizes execution modes and links out to `guide.md`. | **Mandatory / Granular**: Concrete copy-paste shell commands with flags. |
| **Invariants & Rules** | Mandatory (Security rules, naming standard, isolation) | Omitted (assumes framework compliance is pre-baked) |
| **Troubleshooting & FAQ** | High-level failure handling theory & fallback design | Actionable error messages and fix commands |

---

## 3. The Brief-to-Guide Handoff Pattern

In an architectural brief, the operational section must be concise and link directly to the dedicated guide:

```markdown
## 3. Execution & Compilation Modes Overview

The decoupled architecture supports three distinct operational pipelines.

| Mode | Pipeline Flow | Primary Use Case |
| :-: | :--- | :--- |
| **Mode 1** | Local Notes ➔ Local Engine | 100% Offline preview with hot-reload (`<HOST>:<PORT>`) |
| **Mode 2** | Local Notes ➔ GitHub Server Engine | Remote staging build dispatched via `gh` CLI |
| **Mode 3** | Repo Markdown ➔ GitHub Pages | Automated GitHub-to-GitHub native CI/CD deployment |

> 📖 **Full Operational Runbook**:  
> For step-by-step installation instructions, environment variables, and terminal execution commands for each mode, see the **[[GUIDE.md|Dedicated Operational Guide (GUIDE.md)]]**.
```

---

## 4. Anatomy of a Compliant `GUIDE.md`

Every dedicated guide must feature the following standardized structure:

1. **Title & Purpose Block**: What the project does and who the guide is for.
2. **Prerequisites**: Minimum software versions (Node.js, Git, GitHub CLI).
3. **Quick Start (60 Seconds)**: The fastest path to getting a working local preview.
4. **Step-by-Step Mode Walkthroughs**:
   - Mode 1: Local $\longrightarrow$ Local
   - Mode 2: Local $\longrightarrow$ Remote Cloud
   - Mode 3: Repo Markdown $\longrightarrow$ Automated CI/CD
5. **Configuration & Customization**: Environment variables (`QUARTZ_THEME`), layout settings.
6. **Troubleshooting & FAQ**: Common errors (port conflicts, missing dependencies, permissions) and exact fixes.

---

## 5. Verification Checklist

- [ ] Architectural brief remains clean and focused on contracts, boundaries, and fallbacks.
- [ ] Operational commands (`npm install`, `npx quartz build`, `gh workflow run`) reside in `GUIDE.md`.
- [ ] Brief contains a direct markdown link pointing to `GUIDE.md`.
- [ ] `GUIDE.md` is in all-caps at repository root and contains zero-ambiguity, copy-pasteable commands with clear expected outputs.
