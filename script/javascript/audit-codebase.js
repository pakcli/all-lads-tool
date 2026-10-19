/**
 * All Lads Tool — Automated Codebase Compliance Auditor
 * File: audit-codebase.js
 *
 * Scans files recursively and audits against:
 *   [1] Rule #001: Zero Hardcoded Machine Paths (D:\, C:\)
 *   [2] Rule #004: Strict Lowercase Kebab-Case Naming
 *   [3] Obsidian Format: Zero Quotes in YAML Frontmatters
 *   [4] UI/UX Monospace ASCII: <=80 Columns, Zero Wide Emojis in Boxes
 */

const fs = require('fs');
const path = require('path');

const scriptDir = __dirname;
const allLadsToolDir = path.resolve(scriptDir, '..', '..');
const repoRoot = path.resolve(allLadsToolDir, '..');

const targetDir = process.argv[2] ? path.resolve(process.cwd(), process.argv[2]) : allLadsToolDir;

console.log('========================================================================');
console.log('   ALL LADS TOOL -- CODEBASE COMPLIANCE AUDIT GATEWAY');
console.log('========================================================================');
console.log(' Target Directory :', targetDir);
console.log(' Target Scope     :', path.relative(repoRoot, targetDir) || '.');
console.log('========================================================================\n');

const results = {
  hardcodedPaths: [],
  namingViolations: [],
  yamlQuoteViolations: [],
  asciiViolations: [],
  rootReadmeViolations: [],
  totalFiles: 0
};

function getAllFiles(dir, list = []) {
  if (!fs.existsSync(dir)) return list;
  const entries = fs.readdirSync(dir);
  for (const entry of entries) {
    if (entry === '.git' || entry === 'node_modules') continue;
    const fullPath = path.join(dir, entry);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      getAllFiles(fullPath, list);
    } else {
      list.push(fullPath);
    }
  }
  return list;
}

const allFiles = getAllFiles(targetDir);
results.totalFiles = allFiles.length;

allFiles.forEach(filePath => {
  const relPath = path.relative(targetDir, filePath);
  const fileName = path.basename(filePath);
  const ext = path.extname(filePath).toLowerCase();

  // 1. Audit Rule #004: File Naming (Kebab-Case)
  if (!fileName.startsWith('.')) {
    if (/[A-Z\s]/.test(fileName) && fileName !== 'README.md' && fileName !== 'BUILD_REPORT.md') {
      results.namingViolations.push({
        file: relPath,
        issue: 'Contains uppercase characters or spaces (must be lowercase kebab-case)'
      });
    }
  }

  // Skip binary/media files for content checks
  if (['.png', '.webp', '.jpg', '.jpeg', '.ico', '.svg', '.lock', '.woff', '.woff2'].includes(ext)) {
    return;
  }

  let content = '';
  try {
    content = fs.readFileSync(filePath, 'utf8');
  } catch (err) {
    return;
  }

  const lines = content.split('\n');

  // 2. Audit Rule #001: Hardcoded absolute drive letters
  if (['.js', '.ps1', '.py', '.bat', '.sh', '.cmd'].includes(ext)) {
    lines.forEach((line, idx) => {
      if (/(?:^|[^\w\/:])([A-Za-z]:[\\\/](?!$))/.test(line)) {
        if (!line.includes('Program Files') && !line.includes('Rule #001') && !line.includes('IsPathRooted') && !line.includes('Splitter')) {
          results.hardcodedPaths.push({
            file: relPath,
            line: idx + 1,
            snippet: line.trim()
          });
        }
      }
    });
  }

  // 3. Audit Obsidian Frontmatter Quotes
  if (ext === '.md') {
    lines.slice(0, 20).forEach((line, idx) => {
      if (/^[\w-]+:\s*["'][^"']+["']\s*$/.test(line.trim())) {
        results.yamlQuoteViolations.push({
          file: relPath,
          line: idx + 1,
          snippet: line.trim()
        });
      }
    });

    // 4. Audit UI/UX ASCII Monospace Codeblocks
    const codeBlockRegex = /```(?:text|ascii)\r?\n([\s\S]*?)```/g;
    let match;
    while ((match = codeBlockRegex.exec(content)) !== null) {
      const blockLines = match[1].split('\n').map(l => l.replace(/\r$/, ''));
      blockLines.forEach((bLine, lIdx) => {
        // Wide emojis inside boxes
        if (/[│║|]/.test(bLine) && /[\uD800-\uDBFF][\uDC00-\uDFFF]|[\u2600-\u27BF]/.test(bLine)) {
          results.asciiViolations.push({
            file: relPath,
            line: lIdx + 1,
            issue: 'Contains wide emoji inside bordered box',
            snippet: bLine
          });
        }
        // Exceeds 80 columns
        if (bLine.length > 80 && /[┌╔├╠└╚─═│║]/.test(bLine)) {
          results.asciiViolations.push({
            file: relPath,
            line: lIdx + 1,
            issue: `Bordered ASCII box exceeds 80 columns (${bLine.length} cols)`,
            snippet: bLine.substring(0, 80) + '...'
          });
        }
      });
    }
  }
});

// Audit Rule #005: Root README.md Invariant
const rootReadmePath = path.join(repoRoot, 'README.md');
if (!fs.existsSync(rootReadmePath)) {
  results.rootReadmeViolations.push('Missing master README.md at repository root.');
}

// Summary Display
console.log('------------------------------------------------------------------------');
console.log(' AUDIT METRICS:');
console.log(' Total Files Scanned        :', results.totalFiles);
console.log(' Rule #001 (Hardcoded Path) :', results.hardcodedPaths.length === 0 ? '[PASS] 0 violations' : `[FAIL] ${results.hardcodedPaths.length} violations`);
console.log(' Rule #004 (Strict Naming)  :', results.namingViolations.length === 0 ? '[PASS] 0 violations' : `[FAIL] ${results.namingViolations.length} violations`);
console.log(' Rule #005 (Root README.md) :', results.rootReadmeViolations.length === 0 ? '[PASS] Root README.md present' : `[FAIL] Missing root README.md`);
console.log(' Obsidian (YAML Quotes)     :', results.yamlQuoteViolations.length === 0 ? '[PASS] 0 violations' : `[FAIL] ${results.yamlQuoteViolations.length} violations`);
console.log(' UI/UX (ASCII Codeblocks)   :', results.asciiViolations.length === 0 ? '[PASS] 0 violations' : `[FAIL] ${results.asciiViolations.length} violations`);
console.log('------------------------------------------------------------------------\n');

const totalViolations = results.hardcodedPaths.length + results.namingViolations.length + results.yamlQuoteViolations.length + results.asciiViolations.length + results.rootReadmeViolations.length;

if (totalViolations > 0) {
  console.log('[!] VIOLATIONS DETECTED:');
  if (results.hardcodedPaths.length) {
    console.log('\n--- Rule #001 Violations:');
    results.hardcodedPaths.forEach(v => console.log(`  ${v.file}:${v.line} -> ${v.snippet}`));
  }
  if (results.namingViolations.length) {
    console.log('\n--- Rule #004 Violations:');
    results.namingViolations.forEach(v => console.log(`  ${v.file} -> ${v.issue}`));
  }
  if (results.yamlQuoteViolations.length) {
    console.log('\n--- Obsidian YAML Quote Violations:');
    results.yamlQuoteViolations.forEach(v => console.log(`  ${v.file}:${v.line} -> ${v.snippet}`));
  }
  if (results.rootReadmeViolations.length) {
    console.log('\n--- Rule #005 Violations:');
    results.rootReadmeViolations.forEach(v => console.log(`  [MISSING] ${v}`));
  }
  if (results.asciiViolations.length) {
    console.log('\n--- UI/UX ASCII Violations:');
    results.asciiViolations.forEach(v => console.log(`  ${v.file} (block line ${v.line}) -> ${v.issue}`));
  }
  process.exit(1);
} else {
  console.log('[OK] ALL AUDIT CHECKS PASSED WITH 100% COMPLIANCE!');
  process.exit(0);
}
