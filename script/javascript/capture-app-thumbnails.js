const fs = require('fs');
const path = require('path');
const playwrightPath = fs.existsSync(path.resolve(__dirname, '../../node_modules/playwright'))
  ? path.resolve(__dirname, '../../node_modules/playwright')
  : 'playwright';
const { chromium } = require(playwrightPath);

const repoRoot = path.resolve(__dirname, '../..');
const appsDir = path.join(repoRoot, 'apps');
const pubAppsDir = path.join(repoRoot, 'public', 'apps');
const srcThumbsDir = path.join(repoRoot, 'src', 'assets', 'thumbnails');
const pubThumbsDir = path.join(repoRoot, 'public', 'assets', 'thumbnails');

[appsDir, pubAppsDir, srcThumbsDir, pubThumbsDir].forEach(d => {
  if (!fs.existsSync(d)) fs.mkdirSync(d, { recursive: true });
});

async function captureAppThumbnails() {
  console.log('[Thumbnail Capture] Scanning apps directory for standalone HTML apps...');
  const files = fs.readdirSync(appsDir).filter(f => f.endsWith('.html') && !f.includes('_playground'));

  if (files.length === 0) {
    console.log('[Thumbnail Capture] No .html apps found in apps/.');
    return;
  }

  console.log(`[Thumbnail Capture] Found ${files.length} app(s): ${files.join(', ')}`);

  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 800 },
    deviceScaleFactor: 1
  });

  for (const file of files) {
    const appName = file.replace(/\.html$/, '');
    const htmlPath = path.join(appsDir, file);
    const fileUrl = 'file:///' + htmlPath.replace(/\\/g, '/');

    console.log(`\n--- Capturing App: [${appName}] ---`);
    const page = await context.newPage();

    try {
      await page.goto(fileUrl, { waitUntil: 'networkidle' });
      await page.waitForTimeout(1000);

      // 1. CAPTURE DARK MODE
      console.log(`  -> Switching to Dark Theme...`);
      await page.emulateMedia({ colorScheme: 'dark' });
      await page.evaluate(() => {
        const root = document.documentElement;
        root.setAttribute('data-theme', 'dark');
        root.classList.remove('theme-light');
        root.classList.add('theme-dark');
        if (document.body) {
          document.body.setAttribute('data-theme', 'dark');
          document.body.classList.remove('theme-light');
          document.body.classList.add('theme-dark');
        }
        // If app has theme toggle button, try to ensure dark
        const toggle = document.querySelector('#themeToggle, [data-action="toggle-theme"], .theme-toggle');
        if (toggle && root.getAttribute('data-theme') !== 'dark') {
          toggle.click();
        }
      });
      await page.waitForTimeout(800);

      const darkBuf = await page.screenshot({ type: 'webp', quality: 90 });
      const darkName = `${appName}_img-darkmode.webp`;

      fs.writeFileSync(path.join(appsDir, darkName), darkBuf);
      fs.writeFileSync(path.join(pubAppsDir, darkName), darkBuf);
      fs.writeFileSync(path.join(srcThumbsDir, darkName), darkBuf);
      fs.writeFileSync(path.join(pubThumbsDir, darkName), darkBuf);
      // Also update baseline .webp for backward compatibility
      fs.writeFileSync(path.join(appsDir, `${appName}.webp`), darkBuf);
      fs.writeFileSync(path.join(pubAppsDir, `${appName}.webp`), darkBuf);
      fs.writeFileSync(path.join(srcThumbsDir, `${appName}.webp`), darkBuf);
      fs.writeFileSync(path.join(pubThumbsDir, `${appName}.webp`), darkBuf);
      console.log(`  [OK] Saved: ${darkName} (${(darkBuf.length / 1024).toFixed(1)} KB)`);

      // 2. CAPTURE LIGHT MODE
      console.log(`  -> Switching to Light Theme...`);
      await page.emulateMedia({ colorScheme: 'light' });
      await page.evaluate(() => {
        const root = document.documentElement;
        root.setAttribute('data-theme', 'light');
        root.classList.remove('theme-dark');
        root.classList.add('theme-light');
        if (document.body) {
          document.body.setAttribute('data-theme', 'light');
          document.body.classList.remove('theme-dark');
          document.body.classList.add('theme-light');
        }
      });
      await page.waitForTimeout(800);

      const lightBuf = await page.screenshot({ type: 'webp', quality: 90 });
      const lightName = `${appName}_img-lightmode.webp`;

      fs.writeFileSync(path.join(appsDir, lightName), lightBuf);
      fs.writeFileSync(path.join(pubAppsDir, lightName), lightBuf);
      fs.writeFileSync(path.join(srcThumbsDir, lightName), lightBuf);
      fs.writeFileSync(path.join(pubThumbsDir, lightName), lightBuf);
      console.log(`  [OK] Saved: ${lightName} (${(lightBuf.length / 1024).toFixed(1)} KB)`);

    } catch (err) {
      console.error(`  [ERROR] Failed to capture ${appName}:`, err.message);
    } finally {
      await page.close();
    }
  }

  await browser.close();
  console.log('\n[Thumbnail Capture Completed Successfully]');
}

if (require.main === module) {
  captureAppThumbnails().catch(err => {
    console.error('Fatal thumbnail capture error:', err);
    process.exit(1);
  });
}

module.exports = { captureAppThumbnails };
