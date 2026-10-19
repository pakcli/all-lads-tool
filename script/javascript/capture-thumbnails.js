/**
 * ============================================================================
 * MODULAR PLAYWRIGHT THUMBNAIL CAPTURE ENGINE
 * File: all-script/scripts/capture-thumbnails.js
 * ============================================================================
 * Purpose:
 *   Captures desktop view snapshots of all standalone applications in public/apps/
 *   and outputs ultra-compact <standalonename>.webp files directly into public/
 *   (public/assets/thumbnails/<standalonename>.webp).
 *
 * Compliance:
 *   - RULE #3: Zero hardcoded machine/project variables. All paths dynamically resolved.
 *   - Desktop Viewport: 1280x800.
 *   - Output Format: WebP (quality: 85).
 *   - Source: Dynamic discovery via public/apps/_catalog.json or file scan.
 * ============================================================================
 */

const fs = require('fs');
const path = require('path');

// 1. DYNAMIC REPOSITORY & DIRECTORY RESOLUTION (Rule #3 Compliant)
const scriptDir = __dirname;
const repoRoot = path.resolve(scriptDir, '..', '..');
const publicDir = path.join(repoRoot, 'public');
const publicAppsDir = path.join(publicDir, 'apps');
const catalogPath = path.join(publicAppsDir, '_catalog.json');
const outThumbnailsDir = path.join(publicDir, 'assets', 'thumbnails');

// Ensure output directory exists inside public/
if (!fs.existsSync(outThumbnailsDir)) {
  fs.mkdirSync(outThumbnailsDir, { recursive: true });
}

async function run() {
  console.log('====================================================');
  console.log('  MODULAR PLAYWRIGHT DESKTOP THUMBNAIL CAPTURE');
  console.log('====================================================');
  console.log(`Repo Root   : ${repoRoot}`);
  console.log(`Public Dir  : ${publicDir}`);
  console.log(`Apps Dir    : ${publicAppsDir}`);
  console.log(`Thumbnails  : ${outThumbnailsDir}\n`);

  // 2. DISCOVER APPS FROM _catalog.json OR DIRECTORY SCAN
  let apps = [];
  if (fs.existsSync(catalogPath)) {
    try {
      const catalogData = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
      if (Array.isArray(catalogData)) {
        apps = catalogData.map(item => ({
          slug: item.slug || item.id,
          title: item.title || item.slug,
          htmlFile: `${item.slug || item.id}.html`
        }));
      }
    } catch (e) {
      console.warn('[Warning] Failed to parse _catalog.json, falling back to file scan:', e.message);
    }
  }

  // Fallback: Scan public/apps/ for standalone .html files
  if (apps.length === 0 && fs.existsSync(publicAppsDir)) {
    const files = fs.readdirSync(publicAppsDir);
    apps = files
      .filter(f => f.endsWith('.html') && !f.endsWith('_playground.html'))
      .map(f => {
        const slug = f.replace(/\.html$/, '');
        return { slug, title: slug, htmlFile: f };
      });
  }

  if (apps.length === 0) {
    console.error('[Error] No standalone applications found to capture.');
    process.exit(1);
  }

  console.log(`Found ${apps.length} standalone app(s) to capture:`);
  apps.forEach(a => console.log(`  - ${a.slug} (${a.htmlFile})`));
  console.log('');

  // 3. LAUNCH PLAYWRIGHT CHROMIUM
  let chromium;
  try {
    const pw = require('playwright');
    chromium = pw.chromium;
  } catch (err) {
    console.error('[Error] Playwright is not installed or accessible:', err.message);
    console.error('Please ensure Playwright is installed via: npm install -D playwright');
    process.exit(1);
  }

  let browser;
  try {
    browser = await chromium.launch({
      channel: 'chrome',
      headless: true,
      args: ['--disable-gpu', '--hide-scrollbars', '--no-sandbox']
    });
  } catch (e) {
    try {
      browser = await chromium.launch({
        channel: 'msedge',
        headless: true,
        args: ['--disable-gpu', '--hide-scrollbars', '--no-sandbox']
      });
    } catch (e2) {
      browser = await chromium.launch({
        headless: true,
        args: ['--disable-gpu', '--hide-scrollbars', '--no-sandbox']
      });
    }
  }

  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 },
    deviceScaleFactor: 1
  });

  const page = await context.newPage();
  let successCount = 0;

  for (const app of apps) {
    const targetHtmlPath = path.join(publicAppsDir, app.htmlFile);
    if (!fs.existsSync(targetHtmlPath)) {
      console.warn(`  [Skip] Target file not found: ${targetHtmlPath}`);
      continue;
    }

    const rootAppsWebpPath = path.join(repoRoot, 'apps', `${app.slug}.webp`);
    const publicAppsWebpPath = path.join(publicAppsDir, `${app.slug}.webp`);
    const outWebpPath = path.join(outThumbnailsDir, `${app.slug}.webp`);
    const fileUrl = `file:///${targetHtmlPath.replace(/\\/g, '/')}`;

    try {
      console.log(`  Capturing: ${app.slug} -> ${app.slug}.webp ...`);
      await page.goto(fileUrl, { waitUntil: 'load', timeout: 8000 });
      
      // Allow CSS transitions / canvas to settle
      await page.waitForTimeout(600);

      const buffer = await page.screenshot({
        type: 'webp',
        quality: 85,
        clip: { x: 0, y: 0, width: 1280, height: 800 }
      });

      // Write directly beside app cartridge in apps/ and public/apps/
      fs.writeFileSync(rootAppsWebpPath, buffer);
      fs.writeFileSync(publicAppsWebpPath, buffer);
      fs.writeFileSync(outWebpPath, buffer);

      const kb = (buffer.length / 1024).toFixed(1);
      console.log(`  ★ Saved: apps/${app.slug}.webp & public/apps/${app.slug}.webp (${kb} KB)`);
      successCount++;
    } catch (err) {
      console.error(`  [Failed] Could not capture ${app.slug}:`, err.message);
    }
  }

  await browser.close();

  console.log('\n====================================================');
  console.log(`  CAPTURE COMPLETE: ${successCount}/${apps.length} thumbnails generated in public/assets/thumbnails/`);
  console.log('====================================================');
}

run().catch(err => {
  console.error('[Fatal Error in capture-thumbnails]:', err);
  process.exit(1);
});
