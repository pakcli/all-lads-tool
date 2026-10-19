/**
 * ============================================================================
 * ALL LADS TOOL -- ENV STRING STATEMENT PARSER (env-string-parser.js)
 * ============================================================================
 * Resolves, replaces, and sanitizes runtime strings and machine PII based on
 * main.env and main.json configuration (Rule #001 & env-string-statement-parser).
 * ============================================================================
 */

const fs = require('fs');
const path = require('path');

// 1. Dynamic Anchor-Based Upward Discovery (Find-Up)
function findAnchorRoot(startDir) {
  let current = path.resolve(startDir);
  while (current) {
    if (fs.existsSync(path.join(current, 'main.env')) || fs.existsSync(path.join(current, 'main.json'))) {
      return current;
    }
    const parent = path.dirname(current);
    if (parent === current) break;
    current = parent;
  }
  return path.resolve(startDir, '..', '..');
}

const repoRoot = findAnchorRoot(__dirname);
const envPath = path.join(repoRoot, 'main.env');
const mainJsonPath = path.join(repoRoot, 'main.json');

// 2. Load Environment & Blueprint
function loadEnvConfig() {
  const envMap = {};
  if (fs.existsSync(envPath)) {
    try {
      const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed && !trimmed.startsWith('#') && trimmed.includes('=')) {
          const idx = trimmed.indexOf('=');
          const k = trimmed.substring(0, idx).trim();
          const v = trimmed.substring(idx + 1).trim();
          envMap[k] = v;
        }
      }
    } catch (e) {
      console.warn('Warning: Failed to read main.env:', e.message);
    }
  }

  let mainConfig = {};
  if (fs.existsSync(mainJsonPath)) {
    try {
      mainConfig = JSON.parse(fs.readFileSync(mainJsonPath, 'utf8'));
    } catch (e) {
      console.warn('Warning: Failed to parse main.json:', e.message);
    }
  }

  return { env: envMap, config: mainConfig };
}

// 3. String Sanitizer & Replacer Engine
function sanitizeString(content, customEnv) {
  const { env } = customEnv || loadEnvConfig();
  let result = content;

  // Mask machine paths from main.env
  if (env.MASK_LOCAL_WORKSPACE) {
    const wsEscaped = env.MASK_LOCAL_WORKSPACE.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    result = result.replace(new RegExp(wsEscaped, 'gi'), '@root');
  }
  if (env.MASK_USER_PROFILE) {
    const userEscaped = env.MASK_USER_PROFILE.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    result = result.replace(new RegExp(userEscaped, 'gi'), '{{USER_PROFILE}}');
  }

  // Catch general Windows drive path patterns
  result = result.replace(/(["'`])[A-Za-z]:\\[^"'`\r\n]+\1/g, (match) => {
    return match.replace(/[A-Za-z]:\\[^\\]+\\/i, '@root/');
  });

  return result;
}

// 4. CLI Execution Gateway
if (require.main === module) {
  const args = process.argv.slice(2);
  const target = args[0];

  console.log('========================================================================');
  console.log('   ALL LADS TOOL -- ENV STRING STATEMENT PARSER');
  console.log('========================================================================');
  console.log(` Target Root : ${repoRoot}`);

  if (!target) {
    console.log('\nUsage: node env-string-parser.js <filePath | string>');
    console.log('Example: node env-string-parser.js "<target-path-or-string>"');
    process.exit(0);
  }

  if (fs.existsSync(target) && fs.statSync(target).isFile()) {
    const original = fs.readFileSync(target, 'utf8');
    const sanitized = sanitizeString(original);
    if (original !== sanitized) {
      fs.writeFileSync(target, sanitized, 'utf8');
      console.log(`[OK] Sanitized and updated file: ${target}`);
    } else {
      console.log(`[OK] File is already 100% clean: ${target}`);
    }
  } else {
    const sanitized = sanitizeString(target);
    console.log('\nSanitized Output:');
    console.log(sanitized);
  }
}

module.exports = {
  findAnchorRoot,
  loadEnvConfig,
  sanitizeString
};
