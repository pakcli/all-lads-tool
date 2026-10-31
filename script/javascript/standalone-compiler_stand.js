#!/usr/bin/env node
/**
 * JS_STANDALONE-COMPILER.JS
 * Inlines modular JS dependencies from module/ into a standalone, zero-dependency .js script.
 */

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
if (args.length === 0) {
    console.log("Usage: node js_standalone-compiler.js <source_file.js> [output_file.js]");
    process.exit(1);
}

const sourceFile = path.resolve(args[0]);
const outputFile = args[1] 
    ? path.resolve(args[1]) 
    : path.join(path.dirname(sourceFile), path.basename(sourceFile, '.js').replace(/_stand$/, '') + '_stand.js');

if (!fs.existsSync(sourceFile)) {
    console.error(`[ERROR] Source file not found: ${sourceFile}`);
    process.exit(1);
}

console.log(`[*] Compiling JS: ${path.basename(sourceFile)} -> ${outputFile} ...`);

const sourceContent = fs.readFileSync(sourceFile, 'utf8');
const lines = sourceContent.split(/\r?\n/);
const inlinedLines = [
    "// ==========================================================================",
    "// COMPILED STANDALONE JAVASCRIPT - ALL-LADS-TOOL",
    `// Source: ${path.basename(sourceFile)} | Built: ${new Date().toISOString()}`,
    "// ==========================================================================\n"
];

for (const line of lines) {
    const requireMatch = line.match(/const\s+(\w+)\s*=\s*require\(['"]\.\/module\/([^'"]+)['"]\);?/);
    if (requireMatch) {
        const varName = requireMatch[1];
        const modFileName = requireMatch[2].endsWith('.js') ? requireMatch[2] : `${requireMatch[2]}.js`;
        const modPath = path.join(path.dirname(sourceFile), 'module', modFileName);

        if (fs.existsSync(modPath)) {
            console.log(`  [+] Inlining module: ${modFileName} as ${varName}`);
            const modContent = fs.readFileSync(modPath, 'utf8');
            inlinedLines.push(`// --- [INLINED MODULE: ${modFileName}] ---`);
            inlinedLines.push(`const ${varName} = (() => {`);
            inlinedLines.push("  const module = { exports: {} };");
            inlinedLines.push("  const exports = module.exports;");
            inlinedLines.push(modContent);
            inlinedLines.push("  return module.exports;");
            inlinedLines.push(`})();`);
            inlinedLines.push(`// --- [END INLINED MODULE: ${modFileName}] ---\n`);
        } else {
            inlinedLines.push(line);
        }
    } else {
        inlinedLines.push(line);
    }
}

const outDir = path.dirname(outputFile);
if (!fs.existsSync(outDir)) {
    fs.mkdirSync(outDir, { recursive: true });
}

fs.writeFileSync(outputFile, inlinedLines.join('\n'), 'utf8');
console.log(`[OK] Standalone script generated: ${outputFile}`);
