---
name: playwright-thumbnail-capture
description: >-
  Modular Playwright desktop view thumbnail capture skill. Automatically scans standalone app cartridges from public/apps/_catalog.json and renders crisp 1280x800 desktop screenshots saved directly inside public/assets/thumbnails/<standalonename>.webp with ultra-compact compression and zero hardcoded paths.
---

# 📸 Modular Playwright Desktop Thumbnail Capture Skill (`playwright-thumbnail-capture`)

This skill defines the automated, modular screenshot capture engine for generating high-fidelity, client-ready thumbnail previews of standalone web applications (`apps/*.html`) in modern WebP format.

---

## 1. Core Principles & Architectural Directives

1. **Rule #3 Compliance (Zero Hardcoded Variables)**:
   - The capture script strictly derives paths dynamically from repository root (`path.resolve(__dirname, '..', '..')`). Never hardcode absolute disk drives (`D:\...`, `C:\...`) or static user directories.
2. **Output Location Inside `public/`**:
   - All generated thumbnails are written directly into `public/assets/thumbnails/<standalonename>.webp`.
   - Never clutter root or source directories with compiled binary assets.
3. **Modern WebP Compression**:
   - Thumbnails are saved as `type: 'webp'` with `quality: 85`. This reduces 1280×800 screenshot size from ~180 KB (PNG) down to ~35 KB (WebP) with zero visible artifacting on retro CRT bezels.
4. **Single Source of Truth (`_catalog.json`)**:
   - Discovers applications dynamically by reading `public/apps/_catalog.json`.
   - File basename / slug maps directly to `<standalonename>.webp`.

---

## 2. Directory Topology & Naming Convention

```text
public/
├── apps/
│   ├── _catalog.json                  <-- Dynamic source of all cartridges
│   ├── family-quiz.html               <-- Standalone Cartridge 1
│   ├── radiansincostan.html           <-- Standalone Cartridge 2
│   └── ...
└── assets/
    └── thumbnails/                    <-- Target Destination
        ├── family-quiz.webp           <-- 1280x800 desktop snapshot
        ├── radiansincostan.webp
        ├── lotek-offline.webp
        ├── pdf-editor.webp
        ├── islam-memes.webp
        ├── vibe-arcade-deck.webp
        └── wa-parser.webp
```

---

## 3. Playwright Execution Specification

### 3.1 Script Invocation
Execute the modular capture runner from any working directory in the repository:
```bash
node all-script/scripts/capture-thumbnails.js
```

### 3.2 Viewport & Browser Context
- **Browser**: Playwright Chromium in headless mode (`--disable-gpu`, `--hide-scrollbars`, `--no-sandbox`).
- **Viewport**: `1280×800` (16:10 desktop aspect ratio).
- **Device Scale Factor**: `1`.
- **Navigation Timeout**: `8000ms` with `waitUntil: 'load'`.
- **Render Settle Delay**: `600ms` to let CSS transitions, SVG arcs, and canvas components complete their initial animation frames.

---

## 4. UI/UX Fallback Integration (`[preview not found]`)

In `src/modules/catalog-core.js`, catalog cards reference the generated WebP images:
```html
<div class="screen-preview-slot">
  <img 
    src="assets/thumbnails/${disk.id}.webp" 
    class="thumb-img" 
    alt="${disk.title}" 
    loading="lazy" 
    onerror="this.onerror=null;this.parentElement.innerHTML='<div class=\\'preview-not-found-box\\'><span class=\\'not-found-icon\\'>📺</span><span class=\\'not-found-text\\'>[preview not found]</span></div><div class=\\'launch-prompt\\'>▶</div>';" 
  />
  <div class="launch-prompt">▶</div>
</div>
```
- If the WebP thumbnail is present, it renders instantly with retro scanline overlays.
- If missing or deleted, it seamlessly falls back to the monospace retro `[preview not found]` box with zero layout shifting or console errors.

---

## 5. Agent Verification Checklist
- [ ] Has `node all-script/scripts/capture-thumbnails.js` been executed?
- [ ] Are all `.webp` files generated inside `public/assets/thumbnails/`?
- [ ] Is file size under 60 KB per `.webp` thumbnail?
- [ ] Does `src/modules/catalog-core.js` reference `<standalonename>.webp`?
- [ ] Has the file modification been audited in `.agent/.agent.json`?
