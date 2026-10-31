---
title: Sensitive Data Scanner & Git History Sanitizer
tool: scan-sensitive-data.sh
category: security & privacy
runtime: Bash 4+ (Git Bash / macOS / Linux)
aliases: [scan-sensitive-data, sensitive-scanner, git-sanitizer, lads-scanner]
tags: [all-lads-tool, bash, security, privacy, git, sanitizer]
---

# 🛡️ `scan-sensitive-data.sh` — Sensitive Data Scanner & Git History Sanitizer

> [!INFO]
> **Runtime**: Bash 4+ (Git Bash / POSIX) | **Directory**: `all-lads-tool/script/bash/`

Scans both the active working tree and full Git commit history (`git log --all -p`) in `/src`, `/brief`, `/docs`, or `all` using **4 adjustable search methods** (`Sensitive Word`, `Non-Sensitive Word`, `Sensitive Line`, `Non-Sensitive Line`), then executes **4 remediation actions** (`Replace Word`, `Replace Line`, `Delete Line`, `Remove Whole File`).

---

## 1. Quick Syntax & Usage

```bash
# Interactive Triage Menu (choose scope, 4 search methods, and detect & execute action)
bash all-lads-tool/script/bash/scan-sensitive-data.sh

# Method 2 (Non-Sensitive Word) in /docs -> Replace Word with auto 2-letter mask
bash all-lads-tool/script/bash/scan-sensitive-data.sh \
  --scope docs --method non-sensitive-word --find "pa****" \
  --action replace-word --replace-with auto-mask --history

# Method 3 (Sensitive Line) in /src -> Replace Line across working tree & commit history
bash all-lads-tool/script/bash/scan-sensitive-data.sh \
  --scope src --method sensitive-line --find "const API_KEY =" \
  --action replace-line --replace-with "const API_KEY = process.env.API_KEY;" --history

# Method 4 (Non-Sensitive Line) in /brief -> Delete Line
bash all-lads-tool/script/bash/scan-sensitive-data.sh \
  --scope brief --method non-sensitive-line --find "secret_token" \
  --action delete-line --history
```

---

## 2. The 4 Search / Detection Methods

| Key | Method Flag | Case Mode | Match Target | Description |
| :---: | :--- | :--- | :--- | :--- |
| `[ 1]` | `sensitive-word` | **Case-Sensitive** | **Word / Token** | Matches exact case of the target word (`Aa != aa`) |
| `[ 2]` | `non-sensitive-word` | **Case-Insensitive** | **Word / Token** | Matches target word ignoring case (`Aa == aa`) |
| `[ 3]` | `sensitive-line` | **Case-Sensitive** | **Whole Line** | Matches the entire line containing exact-case pattern |
| `[ 4]` | `non-sensitive-line` | **Case-Insensitive** | **Whole Line** | Matches the entire line containing pattern ignoring case |

---

## 3. Detect & Execute: The 4 Remediation Actions

| Key | Action Flag | Working Tree Behavior | Commit History Behavior (`--history`) | Safety Level |
| :---: | :--- | :--- | :--- | :--- |
| `[ 1]` | `replace-word` | Replaces **only the matched word** (`auto-mask` `dc******@gmail.com` / `pa****`, or custom word) | Rewrites matched word across all commits via `git filter-repo --replace-text` | Safe (Default) |
| `[ 2]` | `replace-line` | Replaces the **entire matched line** with a new line string | Rewrites matching full lines across historical commit blobs | Safe |
| `[ 3]` | `delete-line` | Deletes the entire matched line (`sed -i "${LINE}d"`) | Strips matching line from historical commit blobs | ⚠️ Warns on `/src` code files |
| `[ 4]` | `remove-file` | Moves file to `trash-bin/`, runs `git rm --cached`, adds to `.gitignore` | Purges file from all commits via `git filter-repo --invert-paths` | ⚠️ Protected (requires `REMOVE`) |
| `[ s]` | `skip` | Leaves current match untouched | No history change | Read-Only |
| `[ q]` | `quit` | Exits cleanly | Aborts queued history rewrites | Safe |

---

## 4. Folder Scopes & Parameters

| Parameter | Type | Allowed Values | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `--scope` | string | `src`, `brief`, `docs`, `all` | Interactive Menu | Target folder scope to scan |
| `--method` | string | `sensitive-word`, `non-sensitive-word`, `sensitive-line`, `non-sensitive-line` | Interactive Menu | Search sensitivity & granularity (1 of 4 methods) |
| `--find` | string | Any word or line pattern | Built-in Regexes | Search pattern to detect |
| `--action` | string | `replace-word`, `replace-line`, `delete-line`, `remove-file`, `prompt` | `prompt` | Detect & Execute remediation mode |
| `--replace-with` | string | `auto-mask` or custom text | `auto-mask` | New word (for `replace-word`) or new full line (for `replace-line`) |
| `--history` | switch | boolean flag | `false` | Scan and rewrite full `git log --all -p` commit history |
| `--dry-run` | switch | boolean flag | `false` | Preview detections without modifying files or commits |

---

## 5. Implementation Source
* **Master Brief**: [`all-lads-tool/docs/brief-sensitive-data-scanner.md`](../brief-sensitive-data-scanner.md)
* **Script Location**: [`all-lads-tool/script/bash/scan-sensitive-data.sh`](../../script/bash/scan-sensitive-data.sh)
* **Rule Compliance**: Complies with [Rule #001 (Zero Hardcoded Variables)](../../rule/001_skills-no-hardcoded-variables.md) and the [Privacy Default Masking Protocol](../../../.agents/rules/privacy-default-masking.md).
