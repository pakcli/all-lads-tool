---
name: ip-safe-vault-architecture
aliases: [trademark-safe-vault, ip-clean-knowledge-base, open-source-vault-sanitization, neutral-sports-taxonomy]
category: VAULT_DESIGN_PROTOCOL
tags: [all-lads-tool, protocol, intellectual-property, trademark-safety, licensing, open-source, vault-architecture]
trigger: on_demand
description: Architectural blueprint and sanitization protocol for designing digital knowledge vaults that are 100% IP-safe, trademark-neutral, and legally compliant for open-source and educational distribution.
---

# IP-Safe Knowledge Vault Architecture (`ip-safe-vault-architecture`)

## 1. Core Rule & Legal Invariant
1. **Separation of Science from Commerce**: Pure mechanical principles, anatomical science, and biomechanical movements are universal public domain concepts. Commercial league names (e.g., "UFC", "NBA", "FIFA"), trademarked competition enclosures (e.g., "The Octagon"), and athlete commercial likenesses carry proprietary intellectual property (IP) and trademark protections.
2. **Dual-Scope Knowledge Partitioning**:
   - **Tier A (`general-only` / Neutral)**: Contains only timeless sport science, neutral positional roles, and universal technique mechanics. 100% IP-safe for public GitHub repositories, MIT/CC-BY licensing, and educational school textbooks.
   - **Tier B (`licensed` / Commercial Roster)**: Contains specific active promotions, athlete contracts, trademarked branding, and commercial division rankings. Kept in isolated folders (`organisations/`, `athletes/`) that can be filtered out during public builds.

---

## 2. Proprietary vs. Neutral Lexicon Matrix

When authoring content intended for the **`general-only`** educational tier, all proprietary terms must be sanitized into their neutral, descriptive equivalents:

| Proprietary / Trademarked Term | Neutral Descriptive Replacement | Legal Domain |
| :--- | :--- | :--- |
| **"UFC"** | Professional mixed martial arts promotion / Combat organisation | Registered Trademark (Zuffa, LLC) |
| **"The Octagon"** | Eight-sided caged enclosure / Caged arena | Registered Shape & Word Mark |
| **"Super Bowl"** | Championship football final | Registered Trademark (NFL) |
| **"FIFA World Cup"** | International football championship | Registered Trademark (FIFA) |
| **"WWE"** | Professional sports entertainment promotion | Registered Trademark (WWE, Inc.) |
| **"Venum / Reebok Kits"** | Standardized fight wear / Combat uniform | Commercial Apparel Trademarks |
| **Named Fighter Likeness** | Generic archetype (e.g. *Elite Southpaw Striker*) | Right of Publicity / Personality Rights |

---

## 3. Directory Isolation Protocol

To guarantee that a single toggle can strip all commercial IP from a publication build, the directory structure **MUST** enforce physical file boundary isolation:

```text
vault/
├── sports/                     <-- [TIER A: 100% IP-SAFE] Universal roles & rules
├── moves/                      <-- [TIER A: 100% IP-SAFE] Biomechanical physics & mechanics
├── tactics/                    <-- [TIER A: 100% IP-SAFE] Generic strategy & gameplans
│
├── organisations/              <-- [TIER B: ISOLATED COMMERCIAL IP] Promoters & trademarked leagues
│   └── ufc/
│       ├── rules-mma.md
│       └── divisions-male.md
└── athletes/                   <-- [TIER B: ISOLATED COMMERCIAL IP] Real personae & likenesses
    ├── alex-pereira.md
    └── jon-jones.md
```

### 3.1 Link Sanitization Invariant
* In Tier A notes (`sports/`, `moves/`), **never hardcode direct wikilinks** to Tier B notes without an alias or conditional fallback.
* Use neutral descriptive phrases:
  * ❌ *Bad*: `Land devastating knockouts like [[athletes/alex-pereira|Alex Pereira]] in the [[organisations/ufc|UFC Octagon]].`
  * ✅ *Good*: `Land devastating knockouts utilizing heavy hip rotation inside an eight-sided caged enclosure.`
  * ✅ *Acceptable in Full Mode*: Provide conditional metadata tags so build scripts can strip Tier B links in public exports.

---

## 4. Build Configuration & Export Automation

In `vault.config.yaml` or Quartz build scripts, define an explicit exclusion profile:

```yaml
# vault.config.yaml
distribution_profiles:
  educational_open_source:
    mode: "general-only"
    exclude_directories:
      - "organisations/**"
      - "athletes/**"
    strip_tags:
      - "commercial-ip"
      - "trademarked"
    license: "CC-BY-4.0"

  pro_analytics_internal:
    mode: "full"
    exclude_directories: []
    license: "Proprietary / Fair Use Analytical"
```

---

## 5. Verification Checklist for Open-Source Publishing

Before pushing a knowledge vault to a public repository:
- [ ] **Zero Trademarked Enclosure Names**: "Octagon" replaced by "caged enclosure" in universal move notes.
- [ ] **No Commercial Brand Watermarks**: No proprietary league logos (e.g. UFC, FIFA crests) stored in public asset folders.
- [ ] **No Right of Publicity Violations**: Athlete profiles are excluded or strictly confined to factual biographical fair-use commentary.
- [ ] **Universal Science Focus**: All techniques in `moves/` describe human kinetic physics, angles, lever mechanics, and anatomy.
- [ ] **Single-Command Clean Export**: The build engine cleanly generates a standalone site containing only Tier A content when `--profile educational` is passed.
