---
name: trash-bin-inroot-same-structure-revive
aliases: [restore-from-trash-mirror, revive-trash-structure, undo-trash-bin]
category: AGENT_BEHAVIOR_PROTOCOL
tags: [all-lads-tool, protocol, file-safety, restore, trash-bin, revive, zero-loss]
trigger: always_on
description: Safe file restoration protocol for reviving files and directories from trash-bin/ back to their exact original locations in the workspace hierarchy.
---

# Trash Bin Restore & Revive Protocol (`trash-bin-inroot-same-structure-revive`)

## 1. Core Rule (Exact Location Restoration)
1. **Mirror Reverse**: Any file or directory currently located in `trash-bin/` can be revived back to its original location in the workspace by inverting the relative path.
2. **Force Directory Recreation (Create Whatever Needed)**:
   - Jika folder tujuan asli sudah tidak ada, terhapus, atau terpindah: **WAJIB langsung buat foldernya secara otomatis tanpa ragu (`New-Item -ItemType Directory -Force`)**.
   - Tidak perlu konfirmasi atau tanya ke user hanya untuk membuat parent folder tujuan. Buat semua level subfolder yang diperlukan agar file bisa langsung mendarat di posisi semula.

## 2. Restoration Invariant
```text
<REPO_ROOT>/
├── trash-bin/
│   └── src/
│       └── components/
│           └── old-widget.js          # File to revive
└── src/
    └── components/
        └── old-widget.js              # Restored to exact original path
```

## 3. Operational Standards

### 3.1 PowerShell Implementation
```powershell
# Dynamic root resolution
$repoRoot = (Resolve-Path "$PSScriptRoot\..\..").Path
$trashTarget = Resolve-Path "trash-bin\path\to\file.ext"

# Compute relative path inside trash-bin
$relPath = [System.IO.Path]::GetRelativePath((Join-Path $repoRoot "trash-bin"), $trashTarget.Path)
$originalDestination = Join-Path $repoRoot $relPath

# Ensure original parent directory exists (Auto-create whatever is missing)
$origParent = Split-Path $originalDestination -Parent
if (-not (Test-Path $origParent)) {
    Write-Host "Recreating missing directory hierarchy: $origParent" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $origParent -Force | Out-Null
}

# Restore file
Move-Item -Path $trashTarget.Path -Destination $originalDestination -Force

# Optional: Clean up empty trash-bin parent folders
```

## 4. Conflict Handling During Revive
If an active file already exists at the target location:
1. **Never Overwrite Silently**: Prompt the user or compare file hashes/timestamps.
2. **Backup Precaution**: If replacement is intended, move the existing active file to `trash-bin/` under an archived timestamp before completing the restore.

## 5. Related Protocols
- **Trash Bin Mirror Retention**: See [[all-lads-tool/skill/trash-bin-inroot-same-structure.md|trash-bin-inroot-same-structure]].
- **Wikilink Formatting**: Refer to [[all-lads-tool/skill/obsidian-wikilink-format-full-from-vault.md|obsidian-wikilink-format-full-from-vault]] for vault-relative linking standards.
