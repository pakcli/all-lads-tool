---
name: obsidian-wikilink-format-full-from-vault
aliases: [obsidian-full-wikilink, wikilink-format-full-from-vault, vault-full-path-wikilink, obsidian-absolute-links]
category: AGENT_BEHAVIOR_PROTOCOL
tags: [all-lads-tool, protocol, obsidian, wikilink, full-path, vault-relative, linking, markdown]
trigger: always_on
description: Standardized Obsidian wikilink formatting protocol enforcing full path from vault root (e.g. [[folder/subfolder/file.md|alias]]), preventing broken shortest-path or brittle relative links.
---

# Obsidian Wikilink Format Full From Vault Protocol (`obsidian-wikilink-format-full-from-vault`)

## 1. Core Rule (Full Vault-Relative Path Invariant)
1. **Full Path From Vault Root**: Every wikilink generated, updated, or cross-referenced across markdown files **MUST** use the complete path starting from the vault/workspace root:
   ```markdown
   [[path/to/folder/filename.md|display-title]]
   ```
2. **Prohibit Shortest-Path Links**: Do **NOT** use floating shortest-name links (e.g. `[[filename]]`). Shortest-path links are brittle, ambiguous, and break when files are organized into nested directories or when duplicate names exist across multiple domains.
3. **Prohibit Brittle Relative Backtracking**: Do **NOT** use directory-traversal links (e.g. `[[../../folder/filename]]`). Moving either the source or destination note breaks relative links immediately.
4. **Zero Absolute OS Path Leaks**: Never leak OS drive letters (`C:`, `D:`) or user paths (`/Users/...`, `/home/...`). Links must start directly from the first directory inside the vault root.
5. **Strict POSIX Slashes (`/`)**: Always format paths using forward slashes (`/`), even on Windows OS environments. Backslashes (`\`) are strictly forbidden inside wikilinks.

---

## 2. Formatting Standards & Syntax Matrix

| Link Type | Recommended Standard Syntax | Example |
| :--- | :--- | :--- |
| **Standard Note Link** | `[[<vault-path>/<file>.md\|<display-title>]]` | `[[all-lads-tool/skill/trash-bin-inroot-same-structure.md\|trash-bin-inroot-same-structure]]` |
| **Note Without Extension** | `[[<vault-path>/<file>\|<display-title>]]` | `[[docs/file/batch-target-dir-rename\|Batch Target Dir Rename]]` |
| **Header / Section Anchor** | `[[<vault-path>/<file>.md#<Heading>\|<title>]]` | `[[all-lads-tool/skill/trash-bin-inroot-same-structure.md#3-operational-standards\|Operational Standards]]` |
| **Block Reference Link** | `[[<vault-path>/<file>.md#^<block-id>\|<title>]]` | `[[notes/architecture.md#^ref-summary\|Key Takeaway]]` |
| **Embed Note (Transclusion)** | `![[<vault-path>/<file>.md#<Heading>]]` | `![[all-lads-tool/skill/trash-bin-inroot-same-structure.md#1-core-rule]]` |
| **Media / Attachment Embed** | `![[<vault-path>/<asset-file>]]` | `![[assets/images/workflow-diagram.png]]` |
| **PDF Page Anchor Embed** | `![[<vault-path>/<doc>.pdf#page=<n>]]` | `![[references/technical-spec.pdf#page=12]]` |

---

## 3. Vault Root Discovery & Resolution Protocol

When resolving paths dynamically:
1. **Locate Vault Root**:
   - Check upwards for `.obsidian/` folder.
   - If not found, check upwards for `.git/` or repository root.
   - Fallback to current workspace root.
2. **Compute Relative Vault Path**:
   - Calculate relative path from Vault Root to the target file.
   - Replace any backslashes `\` with `/`.
   - Strip leading `/` or `./` so the path starts cleanly with the top-level vault folder.
3. **Display Text / Alias Policy**:
   - Always provide an explicit pipe alias `|<display-title>` to keep reading text clean and human-friendly in Obsidian Live Preview and Reading View.
   - Default display text: The target note's frontmatter `title`, or human-readable file basename without extension.

---

## 4. Automation & PowerShell Implementation

### 4.1 Wikilink Builder Function
```powershell
function New-ObsidianFullVaultWikilink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VaultRoot,

        [Parameter(Mandatory = $true)]
        [string]$TargetFilePath,

        [string]$DisplayText = "",
        [string]$Anchor = "",
        [switch]$IncludeExtension = $true,
        [switch]$Embed = $false
    )

    $resolvedRoot = (Resolve-Path -LiteralPath $VaultRoot).Path
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetFilePath).Path

    # Calculate relative path from vault root
    $relPath = [System.IO.Path]::GetRelativePath($resolvedRoot, $resolvedTarget)
    $normalizedPath = $relPath.Replace('\', '/')

    # Strip extension if requested (for markdown files only)
    if (-not $IncludeExtension -and $normalizedPath.EndsWith('.md', [System.StringComparison]::OrdinalIgnoreCase)) {
        $normalizedPath = $normalizedPath.Substring(0, $normalizedPath.Length - 3)
    }

    # Append anchor (#heading or #^block)
    $anchorStr = if ($Anchor) {
        if (-not $Anchor.StartsWith('#')) { "#$Anchor" } else { $Anchor }
    } else { "" }

    # Display alias
    $aliasStr = if ($DisplayText) { "|$DisplayText" } else { "" }
    $prefix = if ($Embed) { "!" } else { "" }

    return "${prefix}[[${normalizedPath}${anchorStr}${aliasStr}]]"
}
```

### 4.2 Batch Vault Link Converter (Shortest -> Full Path from Vault)
Use this script pattern to scan an entire Obsidian vault and upgrade all short `[[note]]` links to full vault-relative links `[[full/path/to/note.md|note]]`:

```powershell
param(
    [string]$VaultRoot = (Get-Location).Path,
    [switch]$DryRun = $true
)

$resolvedRoot = (Resolve-Path -LiteralPath $VaultRoot).Path

# 1. Build an index of all files in the vault: Basename -> Full Vault Relative Path
$fileIndex = @{}
Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File | ForEach-Object {
    $rel = [System.IO.Path]::GetRelativePath($resolvedRoot, $_.FullName).Replace('\', '/')
    $baseName = $_.BaseName
    if (-not $fileIndex.ContainsKey($baseName)) {
        $fileIndex[$baseName] = @($rel)
    } else {
        $fileIndex[$baseName] += $rel
    }
}

# 2. Process all markdown notes
Get-ChildItem -LiteralPath $resolvedRoot -Recurse -Filter "*.md" | ForEach-Object {
    $file = $_
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    if (-not $content) { return }

    # Regex matches [[target]] or [[target|label]] or [[target#anchor|label]]
    $newContent = [regex]::Replace($content, '(!?\[\[)([^\]\|#]+)(#?[^\]\|]*)(\|?[^\]]*)(\]\])', {
        param($m)
        $prefix   = $m.Groups[1].Value # "![[" or "[["
        $target   = $m.Groups[2].Value.Trim()
        $anchor   = $m.Groups[3].Value.Trim()
        $rawAlias = $m.Groups[4].Value.Trim()
        $suffix   = $m.Groups[5].Value # "]]"

        # If already a full path containing '/', do not touch
        if ($target -match '/') { return $m.Value }

        # Check index
        $targetClean = $target -replace '\.md$', ''
        if ($fileIndex.ContainsKey($targetClean)) {
            $candidates = $fileIndex[$targetClean]
            $chosenPath = $candidates[0] # First match or resolved
            $alias = if ($rawAlias) { $rawAlias } else { "|$targetClean" }
            return "${prefix}${chosenPath}${anchor}${alias}${suffix}"
        }
        return $m.Value
    })

    if ($newContent -ne $content) {
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would update links in: $($file.Name)" -ForegroundColor Yellow
        } else {
            Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding UTF8 -NoNewline
            Write-Host "[UPDATED] Links converted to full vault path in: $($file.Name)" -ForegroundColor Green
        }
    }
}
```

---

## 5. Conflict & Collision Resolution Rules
1. **Duplicate Filenames in Vault**:
   - If two or more notes share identical filenames in different folders (e.g. `docs/intro.md` and `brief/intro.md`), the full path **instantly resolves the ambiguity**:
     - `[[docs/intro.md|Introduction (Docs)]]`
     - `[[brief/intro.md|Introduction (Brief)]]`
2. **Renaming / Refactoring Notes**:
   - When a note is moved or renamed, update all referencing full-path wikilinks across the vault.
3. **External Vault Portability**:
   - By starting links at the vault root and avoiding drive letters or relative `../`, the entire vault remains 100% portable across Windows, macOS, Linux, iOS, and Android.

---

## 6. Integration With Other Protocols
- **Trash Bin Mirror Protocol**: Use with [[all-lads-tool/skill/trash-bin-inroot-same-structure.md|trash-bin-inroot-same-structure]] to guarantee that all cross-references inside skill documents maintain full-path integrity without broken links.
- **Revive Protocol**: Refer to [[all-lads-tool/skill/trash-bin-inroot-same-structure-revive.md|trash-bin-inroot-same-structure-revive]] when restoring notes and validating their links.
