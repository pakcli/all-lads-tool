---
name: sync-manifest-json-to-brief
aliases: [manifest-json-brief-sync, package-json-brief-alignment, sync-package-to-milestone, version-manifest-lockstep]
category: ARCHITECTURE_STANDARD
tags: [all-lads-tool, skill, manifest, json, package-json, brief, versioning, semver, lockstep]
description: Enforces strict synchronization between the project's architectural brief milestone version (brief/vXX-XX-XX_<name>.md) and the project manifest (package.json, manifest.json, or plugin manifest).
pros:
  - "Eliminates version drift between architectural contracts and package manifests"
  - "Ensures build and packaging scripts output correctly versioned installer artifacts"
cons:
  - "Requires multi-file audit whenever a brief milestone version increments"
---

# Sync Manifest JSON to Architectural Brief Protocol (`sync-manifest-json-to-brief`)

> [!IMPORTANT]
> **THE MANIFEST-BRIEF LOCKSTEP INVARIANT**:
> Whenever an architectural brief is authored, incremented, or refactored under `brief/vXX-XX-XX_<name>.md` (or `brief/vXX-XX_<name>.md`), the project's root manifests (`package.json`, `manifest.json`, plugin descriptor, and build script artifact targets) **MUST be updated in lockstep** before formulating any commit message or creating release artifacts.

---

## 1. Version Mapping Standard: Brief to SemVer

Architectural briefs in the `all-lads-tool` ecosystem follow milestone octets. Project package manifests (`package.json`) use Semantic Versioning (`MAJOR.MINOR.PATCH`).

The translation between Brief Milestone and Manifest SemVer is deterministic:

```text
+-----------------------------+-----------------------+---------------------------------------+
| Architectural Brief File    | Milestone String      | Manifest SemVer (`package.json`)     |
+-----------------------------+-----------------------+---------------------------------------+
| brief/v01-00_*.md           | v01-00-00             | "version": "1.0.0"                    |
| brief/v01-01_*.md           | v01-01-00             | "version": "1.1.0"                    |
| brief/v01-01-01_*.md        | v01-01-01             | "version": "1.1.1"                    |
| brief/v01-03-02_*.md        | v01-03-02             | "version": "1.3.2"                    |
+-----------------------------+-----------------------+---------------------------------------+
```

---

## 2. Mandatory Manifest Audit Checklist

When auditing a project for manifest synchronization:

1. **Root `package.json` / `manifest.json` `version` Field**:
   - Check `"version": "X.Y.Z"`. Must match the latest active brief milestone.
2. **Lockfile Synchronization (`package-lock.json`)**:
   - Update the root package `"version"` fields (both top-level and under `"packages": { "": { "version": ... } }`) so `package-lock.json` stays in exact sync with `package.json` without lockfile drift.
3. **Packaging Script Target Paths**:
   - In VS Code extensions or standalone tools:
     ```json
     "package": "npx -y @vscode/vsce package --no-dependencies -o ./out/multiple-treepane-1.1.1.vsix"
     ```
   - Ensure the output `.vsix`, bundle `.tar.gz`, or `.zip` filename reflects the synchronized SemVer.
4. **Documentation Cross-References (`README.md` & `GUIDE.md`)**:
   - Ensure installation command blocks (`code --install-extension ./out/<name>-1.1.1.vsix`) point to the exact same version string.

---

## 3. Operational Workflow for AI Agents

```powershell
# Step 1: Discover the latest brief in the brief/ directory
Get-ChildItem -Path "brief" -Filter "v*.md" | Sort-Object Name -Descending | Select-Object -First 1

# Step 2: Read the milestone version from the brief filename and frontmatter
# Example: brief/v01-01-01_multi-column-tree-explorer.md -> Version v01-01-01 -> SemVer 1.1.1

# Step 3: Synchronize package.json / manifest.json version and packaging script targets
# Step 4: Synchronize README.md and GUIDE.md installer file references
# Step 5: Verify lockstep before formulating canonical commit messages
```
