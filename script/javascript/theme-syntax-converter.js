/**
 * ============================================================================
 * SCRIPT: theme-syntax-converter.js
 * Location: all-script/scripts/theme-syntax-converter.js
 * Purpose:
 *   Bidirectional conversion between Obsidian Theme CSS and AI-Friendly SCSS.
 * Modes:
 *   [0] Direct 1:1 Syntax (Verbatim raw conversion)
 *   [1] Obsidian Theme Class Conversion:
 *       - CSS -> SCSS: Compact, hierarchical, scoped under theme roots for easy AI reading
 *       - SCSS -> CSS: Full expanded Obsidian theme stylesheet with complete selector hierarchy
 * ============================================================================
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

/**
 * Splits CSS declarations safely respecting quotes and parentheses (e.g. data URI SVGs).
 */
function splitDeclarations(bodyText) {
  const decls = [];
  let current = '';
  let inDouble = false;
  let inSingle = false;
  let depth = 0;

  for (let i = 0; i < bodyText.length; i++) {
    const ch = bodyText[i];
    if (ch === '"' && !inSingle) inDouble = !inDouble;
    else if (ch === "'" && !inDouble) inSingle = !inSingle;
    else if (!inDouble && !inSingle) {
      if (ch === '(') depth++;
      else if (ch === ')') depth = Math.max(0, depth - 1);
      else if (ch === ';' && depth === 0) {
        const cleaned = cleanDecl(current);
        if (cleaned) decls.push(cleaned);
        current = '';
        continue;
      }
    }
    current += ch;
  }
  const cleaned = cleanDecl(current);
  if (cleaned) decls.push(cleaned);
  return decls;
}

function cleanDecl(declStr) {
  let s = declStr.trim();
  if (!s) return '';
  // Collapse whitespace while preserving strings
  return s.replace(/\r?\n\s*/g, ' ').replace(/\s{2,}/g, ' ');
}

/**
 * Format declarations compactly.
 * Short bodies (<= 2 properties, <= 90 chars) stay on 1 line: { prop: val; }
 */
function formatDeclsCompact(bodyText, indentLevel = 1) {
  const indent = '  '.repeat(indentLevel);
  const decls = splitDeclarations(bodyText);
  if (decls.length === 0) return '';
  if (decls.length <= 2) {
    const joined = decls.join('; ') + ';';
    if (joined.length <= 90 && !joined.includes('\n')) {
      return `${indent}${joined}`;
    }
  }
  return decls.map(d => `${indent}${d};`).join('\n');
}

/**
 * Fast, accurate CSS parser for rules, at-rules, comments.
 */
function parseCss(cssText) {
  const items = [];
  let i = 0;
  const len = cssText.length;

  while (i < len) {
    while (i < len && /\s/.test(cssText[i])) i++;
    if (i >= len) break;

    // Comment
    if (cssText[i] === '/' && cssText[i + 1] === '*') {
      const end = cssText.indexOf('*/', i + 2);
      if (end === -1) {
        items.push({ type: 'comment', text: cssText.substring(i).trim() });
        break;
      } else {
        items.push({ type: 'comment', text: cssText.substring(i, end + 2).trim() });
        i = end + 2;
        continue;
      }
    }

    // At-rule
    if (cssText[i] === '@') {
      const openBrace = cssText.indexOf('{', i);
      const semiColon = cssText.indexOf(';', i);

      if (semiColon !== -1 && (openBrace === -1 || semiColon < openBrace)) {
        items.push({
          type: 'at-simple',
          text: cssText.substring(i, semiColon + 1).trim()
        });
        i = semiColon + 1;
        continue;
      }

      if (openBrace === -1) break;
      const header = cssText.substring(i, openBrace).replace(/\s+/g, ' ').trim();

      let depth = 1;
      let j = openBrace + 1;
      while (j < len && depth > 0) {
        if (cssText[j] === '/' && cssText[j + 1] === '*') {
          const cEnd = cssText.indexOf('*/', j + 2);
          j = (cEnd === -1) ? len : cEnd + 2;
          continue;
        }
        if (cssText[j] === '{') depth++;
        else if (cssText[j] === '}') depth--;
        j++;
      }
      const body = cssText.substring(openBrace + 1, j - 1).trim();
      items.push({ type: 'at-block', header, body });
      i = j;
      continue;
    }

    // Rule: selector { body }
    const openBrace = cssText.indexOf('{', i);
    if (openBrace === -1) break;
    const selector = cssText.substring(i, openBrace).replace(/\s+/g, ' ').trim();

    let depth = 1;
    let j = openBrace + 1;
    while (j < len && depth > 0) {
      if (cssText[j] === '/' && cssText[j + 1] === '*') {
        const cEnd = cssText.indexOf('*/', j + 2);
        j = (cEnd === -1) ? len : cEnd + 2;
        continue;
      }
      if (cssText[j] === '{') depth++;
      else if (cssText[j] === '}') depth--;
      j++;
    }
    const body = cssText.substring(openBrace + 1, j - 1).trim();
    items.push({ type: 'rule', selector, body });
    i = j;
  }

  return items;
}

/**
 * Group rules that share a base selector and fold pseudo-classes / modifiers using &.
 */
function foldRuleGroup(rules, baseIndent = 1) {
  const indent = '  '.repeat(baseIndent);
  const out = [];

  // Check if this rule group contains task items: div.HyperMD-task-line[data-task="..."], ul > li[data-task="..."]
  const taskRules = [];
  const normalRules = [];

  for (const r of rules) {
    if (r.selector.includes('[data-task=')) {
      taskRules.push(r);
    } else {
      normalRules.push(r);
    }
  }

  // 1. Process normal rules with pseudo folding
  const groups = new Map();
  const groupOrder = [];

  for (const r of normalRules) {
    const sel = r.selector.trim();
    if (sel === '&') {
      // Direct root properties
      const formatted = formatDeclsCompact(r.body, baseIndent);
      if (formatted) out.push(formatted);
      continue;
    }

    // Match pseudo-class or modifier suffix
    const pseudoMatch = sel.match(/^(.+?)(:(?:hover|active|focus|focus-visible|focus-within|disabled|checked|first-child|last-child)|::(?:before|after|placeholder|-webkit-scrollbar\S*|\S+)|(?:\.(?:is-active|is-selected|mod-active|mod-root|is-focused|is-collapsed)))$/);

    if (pseudoMatch && !sel.includes(',')) {
      const base = pseudoMatch[1].trim();
      const pseudo = pseudoMatch[2].trim();
      if (!groups.has(base)) {
        groups.set(base, { baseRules: [], pseudos: [] });
        groupOrder.push(base);
      }
      groups.get(base).pseudos.push({ pseudo: '&' + pseudo, body: r.body });
    } else {
      if (!groups.has(sel)) {
        groups.set(sel, { baseRules: [], pseudos: [] });
        groupOrder.push(sel);
      }
      groups.get(sel).baseRules.push(r.body);
    }
  }

  // Format folded normal groups
  for (const baseSel of groupOrder) {
    const data = groups.get(baseSel);
    const hasPseudos = data.pseudos.length > 0;
    const baseBody = data.baseRules.join('; ');

    if (!hasPseudos) {
      const declsFormatted = formatDeclsCompact(baseBody, baseIndent + 1);
      if (declsFormatted && declsFormatted.indexOf('\n') === -1 && declsFormatted.length < 90) {
        out.push(`${indent}${baseSel} { ${declsFormatted.trim()} }`);
      } else {
        out.push(`${indent}${baseSel} {`);
        if (declsFormatted) out.push(declsFormatted);
        out.push(`${indent}}`);
      }
    } else {
      out.push(`${indent}${baseSel} {`);
      if (baseBody.trim()) {
        const declsFormatted = formatDeclsCompact(baseBody, baseIndent + 1);
        if (declsFormatted) out.push(declsFormatted);
      }
      for (const p of data.pseudos) {
        const pDecls = formatDeclsCompact(p.body, baseIndent + 2);
        if (pDecls && pDecls.indexOf('\n') === -1 && pDecls.length < 75) {
          out.push(`${indent}  ${p.pseudo} { ${pDecls.trim()} }`);
        } else {
          out.push(`${indent}  ${p.pseudo} {`);
          if (pDecls) out.push(pDecls);
          out.push(`${indent}  }`);
        }
      }
      out.push(`${indent}}`);
    }
  }

  // 2. Process task rules (factored under common selector)
  if (taskRules.length > 0) {
    out.push(`${indent}div.HyperMD-task-line, ul > li {`);
    for (const tr of taskRules) {
      const taskMatch = tr.selector.match(/\[data-task=[^\]]+\]/);
      const subSel = taskMatch ? `&${taskMatch[0]}` : tr.selector;
      const decls = formatDeclsCompact(tr.body, baseIndent + 2);
      if (decls.indexOf('\n') === -1 && decls.length < 90) {
        out.push(`${indent}  ${subSel} { ${decls.trim()} }`);
      } else {
        out.push(`${indent}  ${subSel} {`);
        out.push(decls);
        out.push(`${indent}  }`);
      }
    }
    out.push(`${indent}}`);
  }

  return out.join('\n');
}

/**
 * Checks if every sub-selector of a rule belongs to a scope prefix.
 */
function ruleMatchesScope(ruleSelector, prefix) {
  const parts = ruleSelector.split(',').map(s => s.trim()).filter(Boolean);
  if (parts.length === 0) return false;
  return parts.every(part => {
    return part === prefix ||
      part.startsWith(prefix + ' ') ||
      part.startsWith(prefix + '.') ||
      part.startsWith(prefix + ':') ||
      part.startsWith(prefix + '[') ||
      part.startsWith(prefix + '>');
  });
}

/**
 * Decompile flat CSS into compact, scoped, AI-readable SCSS.
 */
function decompileToAiScss(cssText, srcLeaf, nowIso) {
  const items = parseCss(cssText);
  const rules = items.filter(it => it.type === 'rule');
  const atBlocks = items.filter(it => it.type === 'at-block');
  const atSimples = items.filter(it => it.type === 'at-simple');

  const out = [];
  out.push('// ============================================================================');
  out.push('// OBSIDIAN THEME SCSS (AI COMPACT MODE - SOURCE OF TRUTH)');
  out.push(`// Converted From: ${srcLeaf} at ${nowIso}`);
  out.push('// Mode 1: Natural SCSS Nesting, Factored Selectors, Declarative Tokens');
  out.push('// ============================================================================\n');

  if (atSimples.length > 0) {
    atSimples.forEach(s => out.push(s.text));
    out.push('');
  }

  // Major structural scopes
  const scopes = [
    { key: 'root', label: 'ROOT TOKENS & PALETTE VARIABLES', match: s => s === ':root' },
    { key: 'body', label: 'BODY BASE & COMPUTED ACCENTS', match: s => s === 'body' },
    { key: 'theme-both', label: 'SHARED THEME COMPONENTS (:is(.theme-light, .theme-dark))', prefix: ':is(.theme-light, .theme-dark)' },
    { key: 'theme-dark', label: 'DARK THEME SPECIFICATION (.theme-dark)', prefix: '.theme-dark' },
    { key: 'theme-light', label: 'LIGHT THEME SPECIFICATION (.theme-light)', prefix: '.theme-light' },
    { key: 'checkboxes', label: 'ALTERNATIVE CHECKBOXES (.enable-alternative-checkboxes)', prefix: '.enable-alternative-checkboxes' },
    { key: 'drawer', label: 'WORKSPACE DRAWER SYSTEM (.workspace-drawer)', prefix: '.workspace-drawer' },
    { key: 'calendar', label: 'CALENDAR WIDGET (#calendar-container)', prefix: '#calendar-container' },
    { key: 'nav', label: 'NAVIGATION FILE TREE (.nav-files-container)', prefix: '.nav-files-container' },
    { key: 'mobile', label: 'MOBILE & RESPONSIVE LAYOUTS (.is-mobile, .is-phone)', match: s => s.includes('.is-mobile') || s.includes('.is-phone') || s.includes('.is-tablet') }
  ];

  const assigned = new Set();

  scopes.forEach(sc => {
    const matched = [];
    rules.forEach((r, idx) => {
      if (assigned.has(idx)) return;
      let isMatch = false;
      if (sc.prefix) {
        isMatch = ruleMatchesScope(r.selector, sc.prefix);
      } else if (sc.match) {
        isMatch = sc.match(r.selector);
      }
      if (isMatch) {
        assigned.add(idx);
        matched.push(r);
      }
    });

    if (matched.length === 0) return;

    out.push(`// --------------------------------------------------------------------------`);
    out.push(`// ${sc.label} (${matched.length} rules)`);
    out.push(`// --------------------------------------------------------------------------`);

    if (sc.prefix) {
      out.push(`${sc.prefix} {`);
      const strippedRules = matched.map(r => {
        const strippedSel = r.selector.split(',').map(part => {
          let s = part.trim();
          if (s === sc.prefix) {
            return '&';
          }
          if (s.startsWith(sc.prefix + ' ')) {
            return s.substring(sc.prefix.length).trim();
          }
          if (s.startsWith(sc.prefix)) {
            return '&' + s.substring(sc.prefix.length);
          }
          return s;
        }).filter(Boolean).join(', ');
        return { selector: strippedSel, body: r.body };
      });

      out.push(foldRuleGroup(strippedRules, 1));
      out.push(`}\n`);
    } else {
      out.push(foldRuleGroup(matched, 0) + '\n');
    }
  });

  // Remaining rules
  const remaining = [];
  rules.forEach((r, idx) => {
    if (!assigned.has(idx)) remaining.push(r);
  });

  if (remaining.length > 0) {
    out.push(`// --------------------------------------------------------------------------`);
    out.push(`// WORKSPACE, EXTENSIONS & GENERAL SELECTORS (${remaining.length} rules)`);
    out.push(`// --------------------------------------------------------------------------`);
    out.push(foldRuleGroup(remaining, 0) + '\n');
  }

  // At-blocks
  if (atBlocks.length > 0) {
    out.push(`// --------------------------------------------------------------------------`);
    out.push(`// AT-RULES & KEYFRAMES`);
    out.push(`// --------------------------------------------------------------------------`);
    atBlocks.forEach(ab => {
      out.push(`${ab.header} {`);
      out.push(`  ${ab.body.trim()}`);
      out.push(`}\n`);
    });
  }

  return out.join('\n');
}

/**
 * CSS -> SCSS Conversion Entry Point
 */
function convertCssToScss(cssText, mode = 1, srcFile = 'theme.css') {
  const nowIso = new Date().toISOString();
  const srcLeaf = path.basename(srcFile);

  if (parseInt(mode, 10) === 0) {
    const banner = [
      '/* ==========================================================================',
      `   SCSS SOURCE OF TRUTH (Direct 1:1 Convert from ${srcLeaf})`,
      `   Generated At: ${nowIso}`,
      '   Converter Mode: [0] Direct Syntax Verbatim',
      '   ========================================================================== */\n'
    ].join('\n');
    return banner + '\n' + cssText.trim() + '\n';
  }

  // Mode 1: Obsidian Theme Class Conversion (Compact AI SCSS)
  return decompileToAiScss(cssText, srcLeaf, nowIso);
}

/**
 * SCSS -> CSS Compilation Entry Point
 */
function compileScssToCss(srcPath, dstPath, mode = 1, isMin = false) {
  const styleFlag = isMin ? '--style=compressed' : '--style=expanded';
  const sassCmd = `npx --yes sass "${srcPath}" "${dstPath}" ${styleFlag} --no-source-map`;

  execSync(sassCmd, { stdio: 'inherit' });

  if (parseInt(mode, 10) === 1 && !isMin && fs.existsSync(dstPath)) {
    const rawCss = fs.readFileSync(dstPath, 'utf8');
    const nowIso = new Date().toISOString();
    const banner = [
      '/* ==========================================================================',
      '   THEME: Vintage Computer (Obsidian Theme Specification)',
      '   Compiler: compile-single-scss-to-css.ps1 (Mode 1: Obsidian Theme CSS)',
      `   Compiled At: ${nowIso}`,
      '   Architecture: Expanded Obsidian Theme Classes from Scoped SCSS Source',
      '   ========================================================================== */\n'
    ].join('\n');

    fs.writeFileSync(dstPath, banner + '\n' + rawCss.trim() + '\n', 'utf8');
  }
}

// CLI Dispatcher
if (require.main === module) {
  const args = process.argv.slice(2);
  const command = args[0]; // 'css-to-scss' | 'scss-to-css'

  if (command === 'css-to-scss') {
    const src = args[1];
    const dst = args[2];
    const mode = args[3] || '1';

    const inputCss = fs.readFileSync(src, 'utf8');
    const resultScss = convertCssToScss(inputCss, mode, src);
    fs.writeFileSync(dst, resultScss, 'utf8');
    console.log(`[OK] Converted CSS -> SCSS in Mode [${mode}]: ${dst}`);
  } else if (command === 'scss-to-css') {
    const src = args[1];
    const dst = args[2];
    const mode = args[3] || '1';
    const isMin = args[4] === 'true' || args[4] === '1';

    compileScssToCss(src, dst, mode, isMin);
    console.log(`[OK] Compiled SCSS -> CSS in Mode [${mode}]: ${dst}`);
  } else {
    console.log('Usage:');
    console.log('  node theme-syntax-converter.js css-to-scss <src> <dst> <mode>');
    console.log('  node theme-syntax-converter.js scss-to-css <src> <dst> <mode> [isMin]');
  }
}

module.exports = {
  convertCssToScss,
  compileScssToCss
};
