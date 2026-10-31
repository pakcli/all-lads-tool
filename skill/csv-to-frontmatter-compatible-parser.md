---
name: csv-to-frontmatter-compatible-parser
description: Skill for parsing CSV rows to clean Obsidian-compatible YAML Frontmatter and serializing Frontmatter back to CSV. Uses pipe '|' for list/coordinate separations, handles negative numbers cleanly, strictly avoids unnecessary outer quotes, and complies with zero-hardcoding rules.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# CSV to Frontmatter Data Parsing Skill

This skill defines the bidirectional transformation between CSV tabular data and Obsidian-compatible Markdown YAML Frontmatter, adhering to strict delimiter isolation, dynamic schema discovery, and zero-hardcoded environment constraints.

---

## 1. Core Delimiter & Syntax Standards

1. **Pipe Delimiter (`|`)**:
   - Used exclusively for separating coordinate parameters or multi-item list elements inside a single CSV cell.
   - Coordinate Example: `x:-1|y:0.5|rot:45.5|scale:2`
   - Tag/List Example: `tag-one|tag-two|tag-three`

2. **Negative Number Collision Immunity**:
   - By utilizing `|`, negative coordinate numbers (`x:-1`, `rot:-45.5`, `y:-0.5`) never collide with YAML list dashes (`-`).

3. **Strict Quote Policy (`"..."` vs Unquoted)**:
   - **In CSV**: Cells containing `|` or `,` are enclosed in standard single CSV double quotes (`"..."`). Triple quotes (`"""`) or unescaped nested quotes are strictly prohibited.
   - **In Frontmatter (YAML)**: Numbers, booleans, and clean file paths are output **unquoted**. Strings are only quoted if they contain reserved YAML sequence characters (`: `, `#`, `{`, `}`).

4. **Zero-Hardcoding Compliance**:
   - No hardcoded disk drive letters, operating system paths, usernames, or static schema keys.
   - Field names, coordinate types, and data columns are processed dynamically.

---

## 2. Bidirectional Mapping Specifications

### A. Coordinate Mapping (Dynamic Key-Value Transform)

#### CSV Cell:
```csv
foto_profile_active_coordinate
"x:-1|y:0.5|rot:45.5|scale:2"
```

#### Markdown YAML Frontmatter:
```yaml
foto_profile_active_coordinate:
  x: -1
  y: 0.5
  rot: 45.5
  scale: 2
```

---

### B. List / Tag Mapping

#### CSV Cell:
```csv
tags
"tag-one|tag-two|tag-three"
```

#### Markdown YAML Frontmatter:
```yaml
tags:
  - tag-one
  - tag-two
  - tag-three
```

---

### C. Wikilinks Mapping

#### CSV Cell:
```csv
related_items
"[[Item One]]|[[Item Two]]"
```

#### Markdown YAML Frontmatter:
```yaml
related_items:
  - "[[Item One]]"
  - "[[Item Two]]"
```

---

## 3. Dynamic Vanilla JavaScript Implementation

This module contains zero external dependencies and operates dynamically without hardcoded entity keys or machine paths.

```javascript
/**
 * Dynamic CSV <-> YAML Frontmatter Bridge (Zero Dependencies)
 */
export const CsvFrontmatterBridge = {
  /**
   * Parse a single coordinate string (e.g. "x:-1|y:0.5|rot:45.5|scale:2") into an Object
   * @param {string} coordStr
   * @returns {Record<string, number|string>}
   */
  parseCoordinates(coordStr) {
    if (!coordStr) return {};
    const clean = coordStr.replace(/^"+|"+$/g, '').trim();
    const result = {};
    clean.split('|').forEach(part => {
      const idx = part.indexOf(':');
      if (idx !== -1) {
        const key = part.slice(0, idx).trim();
        const val = part.slice(idx + 1).trim();
        result[key] = isNaN(Number(val)) ? val : Number(val);
      }
    });
    return result;
  },

  /**
   * Serialize a coordinate Object back to a pipe-separated string
   * @param {Record<string, number|string>} coordObj
   * @returns {string}
   */
  serializeCoordinates(coordObj) {
    if (!coordObj || typeof coordObj !== 'object') return '';
    return Object.entries(coordObj)
      .map(([k, v]) => `${k}:${v}`)
      .join('|');
  },

  /**
   * Convert a dynamic CSV row Object into Markdown with YAML Frontmatter
   * @param {Record<string, any>} row
   * @param {string} [body='']
   * @returns {string}
   */
  csvRowToMarkdown(row, body = '') {
    let yaml = '---\n';

    for (const [key, rawValue] of Object.entries(row)) {
      if (rawValue === undefined || rawValue === null || rawValue === '') continue;

      const val = typeof rawValue === 'string' ? rawValue.replace(/^"+|"+$/g, '').trim() : rawValue;

      // Dynamic Detection 1: Value contains coordinate syntax (`key:value` pairs separated by '|')
      if (typeof val === 'string' && val.includes(':') && val.includes('|')) {
        const coords = this.parseCoordinates(val);
        yaml += `${key}:\n`;
        for (const [cKey, cVal] of Object.entries(coords)) {
          yaml += `  ${cKey}: ${cVal}\n`;
        }
      }
      // Dynamic Detection 2: Key represents list / tags / wikilinks (contains pipe '|')
      else if (typeof val === 'string' && val.includes('|')) {
        const items = val.split('|').map(item => item.trim()).filter(Boolean);
        yaml += `${key}:\n`;
        items.forEach(item => {
          if (item.startsWith('[[') && item.endsWith(']]')) {
            yaml += `  - "${item}"\n`;
          } else {
            yaml += `  - ${item}\n`;
          }
        });
      }
      // Dynamic Detection 3: Numbers
      else if (!isNaN(Number(val)) && typeof val !== 'boolean') {
        yaml += `${key}: ${Number(val)}\n`;
      }
      // Dynamic Detection 4: Booleans
      else if (val === 'true' || val === 'false' || typeof val === 'boolean') {
        yaml += `${key}: ${val}\n`;
      }
      // Dynamic Detection 5: Standard string
      else {
        // Enforce safe path forward-slashes and quote only when reserved YAML characters exist
        const normalized = typeof val === 'string' ? val.replace(/\\/g, '/') : val;
        const needsQuotes = typeof normalized === 'string' && /(: |#|[{}])/.test(normalized);
        yaml += needsQuotes ? `${key}: "${normalized}"\n` : `${key}: ${normalized}\n`;
      }
    }

    yaml += '---\n\n';
    return yaml + body;
  },

  /**
   * Parse Markdown content with Frontmatter back to a flat CSV row Object
   * @param {string} mdContent
   * @returns {{ row: Record<string, string>, body: string }}
   */
  markdownToCsvRow(mdContent) {
    const match = mdContent.match(/^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/);
    if (!match) return { row: {}, body: mdContent };

    const rawYaml = match[1];
    const body = match[2].trim();
    const row = {};

    const lines = rawYaml.split(/\r?\n/);
    let currentKey = null;
    let listBuffer = [];
    let coordBuffer = {};
    let isCoordBlock = false;

    const flushBuffers = () => {
      if (!currentKey) return;
      if (isCoordBlock) {
        row[currentKey] = this.serializeCoordinates(coordBuffer);
        coordBuffer = {};
        isCoordBlock = false;
      } else if (listBuffer.length > 0) {
        row[currentKey] = listBuffer.join('|');
        listBuffer = [];
      }
      currentKey = null;
    };

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) continue;

      // Sub-item list (starts with '- ')
      if (line.startsWith('  - ')) {
        const itemVal = line.replace('  - ', '').replace(/^["']|["']$/g, '').trim();
        listBuffer.push(itemVal);
        continue;
      }

      // Sub-item coordinate property (e.g. '  x: -1')
      if (line.startsWith('  ') && line.includes(':')) {
        isCoordBlock = true;
        const idx = line.indexOf(':');
        const k = line.slice(0, idx).trim();
        const v = line.slice(idx + 1).trim();
        coordBuffer[k] = v;
        continue;
      }

      // Top level key encountered: flush any previous nested block
      flushBuffers();

      const colonIdx = line.indexOf(':');
      if (colonIdx !== -1) {
        const key = line.slice(0, colonIdx).trim();
        const valuePart = line.slice(colonIdx + 1).trim();

        if (valuePart) {
          row[key] = valuePart.replace(/^["']|["']$/g, '');
        } else {
          currentKey = key; // Multi-line block (list or coordinate object) begins
        }
      }
    }

    // Flush trailing block
    flushBuffers();

    return { row, body };
  }
};
```

---

## 4. Verification & Testing Checklist

- [x] **Zero Hardcoded Paths**: No disk drive letters or machine-specific directories exist.
- [x] **Path Normalization**: All file paths use normalized forward-slashes (`/`).
- [x] **Negative Coordinate Safety**: `x:-1`, `y:-0.5`, `rot:-45.5` parse with zero token collision.
- [x] **Rule #001 Compliance** (`all-lads-tool/rule/001_skills-no-hardcoded-variables.md`): no usernames, ports, hostnames, static app/entity lists, domain-specific sample data, or `node_modules/` edits; all examples are generic and repository-relative.
- [x] **Any Working Directory**: The module performs only pure string transforms, with no file-system, path, or environment access, so it runs identically from any directory.
- [x] **Zero External Libraries**: Pure Vanilla JavaScript ESM executable directly in modern browsers or Node.js.
- [x] **Quote Cleanliness**: No triple quotes (`"""`) or extraneous outer quotes generated.
