---
name: brief-content-codeblock-diff-and-explaining-how-is-the-fix
aliases: [brief-diff-codeblock-standard, line-minus-first-line-plus-second, aligned-line-count-diff, why-it-works-this-time-brief]
category: DOCUMENTATION_STANDARD
tags: [all-lads-tool, skill, brief, diff, codeblock, line-count, alignment, root-cause, fix-explanation]
description: Canonical brief standard for explaining why a fix works now versus why it failed previously, featuring a comparative Root-Cause vs. Working-Architecture matrix and strict diff codeblocks where all minus (-) lines appear first, all plus (+) lines appear second, zero tabs or branches are used, and right-hand '# Line xxxx START/END' explanations are vertically aligned to the exact same column.
dependencies:
  - "[[asci-tree-codeblock-standard-without-branch]]"
  - "[[donot-ngada-ngada-exact-lapangan-variables]]"
  - "[[obsidian-wikilink-format-full-from-vault]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[brief-revisions-to-perfection]]"
  - "[[docs-same-file-name-script]]"
pros:
  - "Provides immediate side-by-side clarity on why the previous implementation failed and why the new implementation succeeds"
  - "Groups all removed (-) lines first and all added (+) lines second for clean visual scanning without interleaved noise"
  - "Vertically aligns all '# Line xxxx START/END' annotations to a single column (longest_line + 1 space)"
  - "Enforces explicit 'Line xxxx' numbering instead of ambiguous shorthand like 'Lxx'"
cons:
  - "Requires calculating exact visual line lengths across each diff block to align the '#' column"
---

# Brief Content Codeblock Diff & Fix Explanation Standard (`brief-content-codeblock-diff-and-explaining-how-is-the-fix`)

> [!IMPORTANT]
> **THE 5 CORE INVARIANTS OF A FIX-EXPLANATION BRIEF**:
> 1. **Comparative "Last Time vs. This Time" Matrix**: Every fix brief must explain **why it failed last time** versus **why it works this time** using exact codebase variables, APIs, and line numbers.
> 2. **All `-` Lines First, All `+` Lines Second**: Inside every `diff` codeblock, all removed (`- `) lines **MUST appear first** as a contiguous top block, and all added (`+ `) lines **MUST appear second** as a contiguous bottom block. Never interleave `-` and `+` lines.
> 3. **Zero Tabs & Zero Branch Symbols**: Do not use tabs (`\t`) or branch characters (`├──`, `└──`, `│`, `+--`) inside diff codeblocks. Each diff line begins at column 0 with `- ` or `+ `.
> 4. **Strict `Line xxxx` Prefix (Never `Lxx`)**: Line numbers inside `#` annotations must always be written as `Line xxxx` (e.g., `# Line 348 START`, `# Line 350 END`), **NEVER** abbreviated as `L348` or `Lxx`.
> 5. **Vertical `#` Column Alignment (`Longest + 1 Space`)**: Every `# Line xxxx` annotation within a codeblock must start at the exact same visual column (`longest_code_line_length + 1 space`).

---

## 1. Visual Structure of the Diff Codeblock

```text
- <removed line 1>                # Line xxxx START (<Why this initial line was broken>)
- <removed line 2>                # Line xxxx (<Why this intermediate line failed>)
- <removed line N>                # Line xxxx END (<Final failure outcome of old code>)
+ <added line 1>                  # Line xxxx START (<How the new replacement starts>)
+ <added line 2>                  # Line xxxx (<How the new mechanism processes data>)
+ <added line N>                  # Line xxxx END (<Verified working outcome of new code>)
```

### Column Alignment & Marker Rules

| Rule | Specification | Valid Example | Invalid Example |
| :--- | :--- | :--- | :--- |
| **Ordering** | All `- ` lines grouped at top; all `+ ` lines grouped at bottom | `- old1` then `- old2` then `+ new1` then `+ new2` | `- old1` then `+ new1` then `- old2` |
| **Line Number Format** | Must use full word `Line xxxx` | `# Line 348 START` | `# L348 START` or `# Lxx` |
| **Block Boundaries** | First & last `-` lines have `START` / `END`; first & last `+` lines have `START` / `END` | `# Line 348 START (...)` ... `# Line 350 END (...)` | Missing `START` or `END` markers |
| **Indentation / Branches** | Zero tabs, zero branch graphics (`├──`, `└──`, `│`) | `- var snap = Snapshot();` | `- \t├── var snap = Snapshot();` |
| **Vertical `#` Alignment** | Pad shorter lines with spaces so every `#` is at `max_len + 1` | Every `#` in the block forms a straight vertical line | Jagged `#` comments at different columns |

---

## 2. Section 1 Template: "Why It Works This Time vs. Why It Failed Last Time"

Before presenting the diff codeblocks, every fix brief must include a structured comparison table contrasting the previous broken behavior against the working architecture:

```markdown
## 1. Why It Works This Time vs. Why It Failed Last Time

| Failure Point | Last Time (Broken Behavior) | This Time (Working Architecture) |
| :--- | :--- | :--- |
| **1. <Subsystem / Component>** | <Exact technical reason the previous code failed, including API limitation or bug> | <Exact technical mechanism that resolves it in the current code> |
| **2. <Subsystem / Component>** | <Exact crash, deadlock, or false-negative cause> | <Exact guard, calibration, or isolation mechanism> |
```

---

## 3. Canonical Example: Production Diff Codeblocks (`v01-03-03`)

### 3.1. Example A: Single-Snapshot Handle Calibration (`script/file/adapter/file-lock-inspector.psm1`)

```diff
- var snap = Snapshot();                                                                                                                     # Line 348 START (BROKEN: Snapshot taken before FileStream open)
- int fileTypeIndex = ResolveFileTypeIndex(snap, me);                                                                                        # Line 349 (Temp file handle missing in snap -> returns -1)
- if (fileTypeIndex < 0) return output;                                                                                                      # Line 350 END (Aborts scan with 0 handles detected)
+ string tmp = Path.GetTempFileName();                                                                                                       # Line 348 START (WORKING: Create calibration temp file first)
+ int fileTypeIndex = -1;                                                                                                                    # Line 349 (Initialize File ObjectTypeIndex)
+ using (var fs = new FileStream(tmp, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 1, FileOptions.DeleteOnClose)) { # Line 350 (Open FileStream before snapshot)
+ long myHandle = fs.SafeFileHandle.DangerousGetHandle().ToInt64();                                                                          # Line 351 (Capture live kernel handle value)
+ var snap = Snapshot();                                                                                                                     # Line 352 (Take NtQuerySystemInformation(64) snapshot while fs is live)
+ foreach (var e in snap) {                                                                                                                  # Line 353 (Locate our calibration handle in snapshot)
+ if (e.UniqueProcessId.ToInt64() == me && e.HandleValue.ToInt64() == myHandle) { fileTypeIndex = e.ObjectTypeIndex; break; }                # Line 354 (Exact File ObjectTypeIndex resolved on first pass)
+ }                                                                                                                                          # Line 358 (End calibration loop)
+ if (fileTypeIndex < 0) return output;                                                                                                      # Line 359 END (Proceeds to scan only e.ObjectTypeIndex == fileTypeIndex)
```

### 3.2. Example B: Per-Row Button Context Isolation (`script/file/adapter/lock-panel-window.psm1`)

```diff
- $targetActualPath = $rawPath                                                                                # Line 541 START (BROKEN: Shared parent-scope variable overwritten every loop)
- $btnProbe.Add_Click({ $isStill = Test-FileIsLocked -Path $targetActualPath })                               # Line 567 (Always re-tested the LAST row in the table)
- $btnUnlock.Add_Click({ $isUnlocked = Unlock-FileOrFolder -Path $targetActualPath })                         # Line 592 (Clicking Unlock on Row 1 actually ran on the LAST row)
- $txtBadge.Text = "Clear (Unlocked)"                                                                         # Line 604 (Updated badge of the LAST row instead of clicked row)
- $btnUnlock.Content = "Unlocked"                                                                             # Line 606 END (Disabled button of the LAST row instead of clicked row)
+ $rowCtx = [PSCustomObject]@{ Path = $rawPath; Badge = $badge; TxtBadge = $txtBadge; BtnUnlock = $btnUnlock } # Line 582 START (WORKING: Create isolated per-row context object)
+ $btnProbe.Tag = $rowCtx                                                                                     # Line 588 (Bind row context to Re-test button Tag)
+ $btnUnlock.Tag = $rowCtx                                                                                    # Line 589 (Bind row context to Unlock button Tag)
+ $btnUnlock.Add_Click({ param($sender, $e) $ctx = $sender.Tag                                                # Line 612 (Read exact clicked row context from $sender.Tag)
+ $isUnlocked = Unlock-FileOrFolder -Path $ctx.Path                                                           # Line 622 (Unlock the exact clicked row path)
+ $ctx.TxtBadge.Text = "Clear (Unlocked)"                                                                     # Line 626 (Update badge on the exact clicked row)
+ $ctx.BtnUnlock.Content = "Unlocked" })                                                                      # Line 628 END (Mark Unlock button on the exact clicked row as Unlocked)
```

---

## 4. Automated Formatter Helper (PowerShell)

Use this snippet when generating or verifying aligned diff codeblocks to guarantee that every `# Line xxxx` comment aligns to `max_length + 1 space`:

```powershell
function Format-AlignedDiffBlock {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entries # Array of @{ Code = "- ..."; Comment = "# Line 348 START (...)" }
    )
    $maxLen = ($Entries | ForEach-Object { $_.Code.Length } | Measure-Object -Maximum).Maximum
    foreach ($entry in $Entries) {
        $pad = " " * (($maxLen - $entry.Code.Length) + 1)
        Write-Output "$($entry.Code)$pad$($entry.Comment)"
    }
}
```

---

## 5. Verification Checklist

- [x] **Comparative Table Included**: Brief explains why it failed last time vs. why it works this time.
- [x] **All `-` First, All `+` Second**: Every `diff` codeblock places all removed (`-`) lines at the top and all added (`+`) lines at the bottom.
- [x] **Explicit `Line xxxx` Format**: Every line annotation uses `# Line xxxx` (never `# Lxxxx` or `# Lxx`).
- [x] **`START` and `END` Boundaries**: Both the `-` section and the `+` section explicitly mark their first line with `START` and their last line with `END`.
- [x] **Zero Tabs & Zero Branches**: No `\t` characters or ASCII tree branches (`├──`, `└──`, `│`).
- [x] **Strict Vertical Column Alignment**: Every `#` in a codeblock aligns to `longest_line + 1 space`.
