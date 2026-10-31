const path = require('path');
const { chromium } = require('playwright');

const repoRoot = path.resolve(__dirname, '..', '..');
const pageUrl = `file:///${path.join(repoRoot, 'public', 'page-apps.html').replace(/\\/g, '/')}`;

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const page = await browser.newPage({ viewport: { width: 1280, height: 800 } });
  await page.goto(pageUrl);
  
  const animName = await page.$eval('#terminalCursor', el => getComputedStyle(el).animationName);
  const animDuration = await page.$eval('#terminalCursor', el => getComputedStyle(el).animationDuration);
  const animTiming = await page.$eval('#terminalCursor', el => getComputedStyle(el).animationTimingFunction);
  console.log('Cursor Animation Info:', { animName, animDuration, animTiming });

  // Frame 1 (visible)
  await page.screenshot({ path: path.join(repoRoot, 'frame_visible.png'), clip: { x: 20, y: 150, width: 300, height: 60 } });
  
  // Wait 500ms for blink half-cycle
  await page.waitForTimeout(550);
  
  // Frame 2 (hidden/blinked)
  await page.screenshot({ path: path.join(repoRoot, 'frame_blinked.png'), clip: { x: 20, y: 150, width: 300, height: 60 } });
  
  await browser.close();
  console.log('Captured 2 frames successfully!');
})();
