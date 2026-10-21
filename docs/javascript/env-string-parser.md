---
title: Environment String Statement Parser
tool: env-string-parser.js
category: architecture & standards
runtime: Node.js 18+
aliases: [env-string-parser, path-sanitizer, string-replacer]
tags: [all-lads-tool, javascript, env, sanitizer, zero-pii]
---

# 🛠️ `env-string-parser.js` — Environment String Statement Parser

> [!INFO]
> **Runtime**: Node.js 18+ | **Directory**: `all-lads-tool/script/javascript/`

Resolves, replaces, and sanitizes runtime strings and machine PII based on `main.env` and `main.json` configuration, enforcing Rule #001 (Zero Hardcoded Variables).

---

## 1. Quick Syntax & Usage

```bash
# Test sanitizing an input string from CLI
node all-lads-tool/script/javascript/env-string-parser.js "<local-machine-path>/apps"

# Sanitize a specific file directly
node all-lads-tool/script/javascript/env-string-parser.js path/to/file.js
```

---

## 2. Capabilities & Architecture

| Feature | Description |
| :--- | :--- |
| **Find-Up Anchor** | Searches upward from script location to locate `main.env` or `main.json`. |
| **Mask Machine Drives** | Replaces workspace drive letters (`D:\...`, `C:\Users\...`) with `@root` or `{{USER_PROFILE}}`. |
| **Zero-PII Compliance** | Ensures machine-specific paths never commit to Git repositories. |

---

## 3. Implementation Source
* **Script Location**: [`all-lads-tool/script/javascript/env-string-parser.js`](..\../script/javascript/env-string-parser.js)
* **Skill Reference**: [`all-lads-tool/skill/env-string-statement-parser.md`](..\../skill/env-string-statement-parser.md)
