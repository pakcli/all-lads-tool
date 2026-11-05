---
name: trash-bin-inroot-same-structure
aliases: [safe-trash-structure, trash-bin-root-hierarchy, mirror-trash-retention]
category: AGENT_BEHAVIOR_PROTOCOL
tags: [all-lads-tool, protocol, file-safety, trash-bin, directory-structure, zero-loss]
trigger: always_on
description: Safe file deletion protocol enforcing that any deleted or deprecated files are moved to trash-bin/ at the workspace root, preserving their exact relative directory hierarchy.
---

# Trash Bin Root Mirror Structure Protocol (`trash-bin-inroot-same-structure`)

## 1. Core Rule (Zero Permanent Deletion)
1. **Never Permanently Delete**: Never use destructive deletion commands (`Remove-Item -Recurse -Force`, `rm -rf`, `git rm -rf`) directly on workspace files or folders unless explicitly commanded.
2. **Move to Root `trash-bin/`**: Any file or directory marked for removal, replacement, or deprecation must be safely moved into `trash-bin/` located at the repository/workspace root.

## 2. Directory Hierarchy Invariant (1:1 Mirror)
When moving files or folders to `trash-bin/`, you **MUST preserve the identical relative path structure** from the repository root:

```text
<REPO_ROOT>/
├── src/
│   └── components/
│       └── old-widget.js          # File to remove
└── trash-bin/
    └── src/
        └── components/
            └── old-widget.js      # Moved here (Exact relative path mirrored)
```

## 3. Operational Standards

### 3.1 Path Resolution & Creation
- Determine repository/workspace root dynamically (Rule #001: zero hardcoded paths).
- Calculate the relative path of the target item from the root.
- Create parent target directories inside `trash-bin/<relative-path>` before moving if they do not already exist.

### 3.2 In PowerShell
```powershell
# Dynamic root resolution
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path # Adjust relative depth dynamically
$targetFile = Resolve-Path "path\to\target-file.ext"
$relPath = [System.IO.Path]::GetRelativePath($repoRoot, $targetFile.Path)
$trashDestination = Join-Path $repoRoot (Join-Path "trash-bin" $relPath)

# Ensure parent directory exists in trash-bin
$trashParent = Split-Path $trashDestination -Parent
if (-not (Test-Path $trashParent)) {
    New-Item -ItemType Directory -Path $trashParent -Force | Out-Null
}

# Move item preserving structure
Move-Item -Path $targetFile.Path -Destination $trashDestination -Force
```

## 4. Conflict Handling (Collision Safety)
If a file with the identical relative path already exists in `trash-bin/`:
- Do not overwrite silently.
- Append a timestamp or collision counter: `<filename>_archived_<yyyyMMdd_HHmmss>.<ext>`.

## 5. Related Protocols
- **Revive & Restore**: Use [[all-lads-tool/skill/trash-bin-inroot-same-structure-revive.md|trash-bin-inroot-same-structure-revive]] to restore items back to their exact original workspace location.
- **Wikilink Formatting**: Use [[all-lads-tool/skill/obsidian-wikilink-format-full-from-vault.md|obsidian-wikilink-format-full-from-vault]] for full vault-relative linking standards across markdown files.
