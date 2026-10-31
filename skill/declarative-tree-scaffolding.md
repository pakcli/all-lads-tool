---
name: declarative-tree-scaffolding
aliases: [vault-scaffolding, declarative-file-tree, tree-to-workspace, inline-frontmatter-scaffolder]
category: WORKSPACE_ARCHITECTURE
tags: [all-lads-tool, scaffolding, tree, obsidian, automation, frontmatter, declarative]
description: Design, scaffold, and interconnect Obsidian vault files and code architectures using declarative panel-tree codeblocks with inline f? frontmatter directives. Eliminates JSON boilerplate, enabling instant file creation with pre-wired dependencies, tags, and YAML properties.
pros:
  - "Standardized execution and reproducible workflow"
  - "Enforces decoupling and system stability"
cons:
  - "Requires upfront discipline and strict specification"
  - "Restricts ad-hoc unvetted modifications"
---

# Declarative Tree Scaffolding Protocol (`declarative-tree-scaffolding`)

> [!IMPORTANT]
> **THE DECLARATIVE SCAFFOLDING INVARIANT**:
> When scaffolding or restructuring files in any active project:
> 1. Use **pure tab/4-space indented ASCII tree codeblocks** (per [[asci-tree-codeblock-standard]]).
> 2. Use **inline `f?` query syntax** to pre-wire YAML properties directly on the file line.
> 3. Eliminate JSON boilerplate and manual file-by-file creation.

---

## 1. Syntax Specification: The `f?` Directive

In declarative design codeblocks, append `f?<key>=<value>&<key>=<value>` after any leaf node filename:

```text
panel-tree
project-root
	brief
		v01-00_main-idea.md f?title=Main Idea&status=active
		v01-01_file-structure.md f?title=File Structure&dependencies=[[zero-hardcoded-variables]]
	docs
		guide.md f?category=GUIDE&tags=manual,quickstart
	script
		engine.ps1
```

### Supported Inline Property Types:
- **Plain Strings**: `f?title=My Document Title`
- **Lists / Arrays**: `f?tags=alpha,beta,gamma`
- **Obsidian Wikilinks**: `f?dependencies=[[skill-a]],[[skill-b]]`
- **Metadata Enums**: `f?status=canonical&version=v01-03`

---

## 2. Automation Lifecycle

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   DECLARATIVE TREE SCAFFOLDING PIPELINE                │
├────────────────────────────────────────────────────────────────────────┤
│ 1. DECLARATIVE BLUEPRINT : Author the indented tree with f? parameters │
│ 2. PARSER DISCOVERY      : Parser extracts node depth and properties   │
│ 3. COLLISION AUDIT       : Validates that target files do not overwrite │
│ 4. DIRECTORY CREATION    : Creates nested directories dynamically       │
│ 5. ATOMIC FILE WRITE     : Writes .md files with pre-populated YAML     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Scaffolding Automation Script (PowerShell Example)

```powershell
function Invoke-TreeScaffolding {
    param(
        [Parameter(Mandatory = $true)][string]$TreeBlueprint,
        [string]$TargetRoot = "."
    )

    $lines = $TreeBlueprint -split "`r?`n"
    $pathStack = @()

    foreach ($rawLine in $lines) {
        if ([string]::IsNullOrWhiteSpace($rawLine)) { continue }

        # Calculate indentation depth (tabs or 4-spaces)
        $indent = 0
        while ($rawLine.StartsWith("`t" * ($indent + 1))) { $indent++ }
        if ($indent -eq 0) {
            while ($rawLine.StartsWith("    " * ($indent + 1))) { $indent++ }
        }

        $trimmed = $rawLine.Trim()
        $pathStack = $pathStack[0..($indent - 1)]

        if ($trimmed -match '^([^?\s]+)(\s+f\?(.*))?$') {
            $nodeName = $matches[1]
            $queryParams = $matches[3]

            if ($nodeName.Contains('.')) {
                # File Node
                $dirPath = Join-Path $TargetRoot ($pathStack -join "/")
                if (-not (Test-Path $dirPath)) { New-Item -ItemType Directory -Path $dirPath -Force | Out-Null }
                
                $filePath = Join-Path $dirPath $nodeName
                $frontmatter = ""
                if ($queryParams) {
                    $frontmatter = "---\n"
                    foreach ($pair in ($queryParams -split '&')) {
                        $kv = $pair -split '='
                        $k = $kv[0]
                        $v = $kv[1]
                        if ($v.Contains(',')) {
                            $frontmatter += "${k}:\n"
                            foreach ($item in ($v -split ',')) {
                                if ($item.StartsWith('[[') -and $item.EndsWith(']]')) {
                                    $frontmatter += "  - `"$item`"\n"
                                } else {
                                    $frontmatter += "  - $item\n"
                                }
                            }
                        } else {
                            $frontmatter += "${k}: $v\n"
                        }
                    }
                    $frontmatter += "---\n\n# $nodeName\n"
                }

                if (-not (Test-Path $filePath)) {
                    [IO.File]::WriteAllText($filePath, $frontmatter, [Text.Encoding]::UTF8)
                    Write-Host "[CREATED] $filePath" -ForegroundColor Green
                }
            } else {
                # Folder Node
                $pathStack += $nodeName
            }
        }
    }
}
```

---

## 4. Verification Checklist

- [ ] Does the scaffolding tree respect [[asci-tree-codeblock-standard]] (tabs/spaces, no `├──`)?
- [ ] Are YAML properties generated with valid syntax and no syntax errors?
- [ ] Are array wikilinks in frontmatter properly wrapped with `"[[]]"`?
- [ ] Are existing files protected from accidental overwrites?
