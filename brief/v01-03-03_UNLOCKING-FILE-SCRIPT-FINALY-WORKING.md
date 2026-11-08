---
title: Unlocking File & Directory Lock Inspector Engine Finally Working
version: v01-03-03
status: canonical
dependencies:
  - "[[brief/v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md|v01-03-02]]"
  - "[[docs/file/detector-file-lock-process.md|detector-file-lock-process]]"
  - "[[skill/what-todo-trying-to-modify-move-delete-on-going-prosseeeing-by-other-app.md|what-todo-trying-to-modify-move-delete]]"
  - "[[skill/privacy-default-masking-2-letter-exposure.md|privacy-default-masking-2-letter-exposure]]"
  - "[[skill/asci-tree-codeblock-standard-without-branch.md|asci-tree-codeblock-standard-without-branch]]"
  - "[[skill/brief-content-codeblock-diff-and-explaining-how-is-the-fix.md|brief-content-codeblock-diff-and-explaining-how-is-the-fix]]"
---

# Brief v01-03-03: Unlocking File & Directory Lock Inspector Engine (`detector-file-lock-process.ps1`)

## Status
- **Status**: Canonical / Verified Production Engine
- **Version**: v01-03-03
- **Context**: `file` / `all-lads-tool`
- **Target Executable**: `script/file/detector-file-lock-process.ps1`
- **Target Documentation**: `docs/file/detector-file-lock-process.md`

---

## 1. Why It Works This Time vs. Why It Failed Last Time

| Failure Point | Last Time (Broken Behavior) | This Time (Working Architecture) |
| :--- | :--- | :--- |
| **1. Directory Watcher Handles (`muninn-sidecar.exe`)** | Used Windows Restart Manager (`rstrtmgr.dll`), which **only sees open leaf files** and is completely blind to `ReadDirectoryChangesW` directory handles (`392+` directory handles held by `muninn-sidecar.exe` PID `10872`). | Uses `HandleScanOOP` (`NtQuerySystemInformation(64)`) to enumerate actual kernel `File` and `Directory` handles across all processes and closes them remotely with `DUPLICATE_CLOSE_SOURCE` (`0x00000001`). |
| **2. Crash `0xc000070a` & Pipe Deadlocks** | Naively duplicated every handle in the system table without checking `ObjectTypeIndex`, touching PowerShell's internal `NamedPipeServerStream` / `EventWaitHandle` and hanging on synchronous pipes. | Opens a calibration `FileStream` first, finds its own handle in the snapshot to get the exact `File` `ObjectTypeIndex`, skips all non-file kernel objects, skips synchronous pipe access masks, and runs `GetFinalPathNameByHandle` on a `150ms` timeout worker thread. |
| **3. Double-Snapshot Calibration Race** | Captured `Snapshot()` *before* opening the calibration temp file, so the temp file handle wasn't in the first snapshot (`fileTypeIndex = -1`), causing `Scan()` to return `0` matches. | Opens `using (var fs = new FileStream(tmp, ...))` **first**, then calls `Snapshot()` while `fs` is open, guaranteeing `fileTypeIndex` resolves on the first pass. |
| **4. PowerShell WPF Loop Closure Bug** | Inside `foreach ($lock in $script:currentAppLocks)`, `[Unlock]` and `[Re-test]` click handlers referenced loop variables (`$targetActualPath`, `$badge`, `$btnUnlock`), so clicking `[Unlock]` on Row 1 actually executed on the **last row** in the table. | Attaches a dedicated `$rowCtx` (`Path`, `Badge`, `TxtBadge`, `BtnUnlock`) to `$btnUnlock.Tag` and `$btnProbe.Tag` and reads `$ctx = $sender.Tag` inside the click handler. |
| **5. Discovery & Refresh Scope Blindness** | Only scanned `trash-bin` (capped at 30 folders) and overwrote the scope on Refresh, missing locked workspace folders (`E:\proj\remotion`, `E:\proj\web-app_sport-club`, etc.). | Scans both `trash-bin` and workspace directories (`E:\proj` + `CWD`) with single-pass batching (`HandleScanOOP::Scan`, `ProcessCwdReader::FindProcessesInPaths`, and `Win32_Process`). |

---

## 2. Diff Codeblocks (Line Minus First, Line Plus Second, Column-Aligned `# Line xxxx` Counts)

### 2.1. Diff 1: `HandleScanOOP` Single-Snapshot Calibration (`script/file/adapter/file-lock-inspector.psm1`)

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

### 2.2. Diff 2: Remote Handle Closing via `DUPLICATE_CLOSE_SOURCE` (`script/file/adapter/file-lock-inspector.psm1`)

```diff
- $devNames = @("node", "remotion", "ffmpeg", "esbuild", "rspack")                                      # Line 467 START (BROKEN: Only checked hardcoded dev process names)
- Get-Process -ErrorAction SilentlyContinue | Where-Object { $devNames -contains $_.ProcessName }       # Line 468 (Completely missed muninn-sidecar.exe PID 10872)
- & cmd.exe /c "attrib -r -s -h -a `"$resolved`" /s /d" 2>$null                                         # Line 476 (Slow recursive attrib across thousands of node_modules files)
- & cmd.exe /c "icacls `"$resolved`" /reset /t /c /q" 2>$null                                           # Line 481 (Slow recursive icacls across thousands of node_modules files)
- [void](Restart-WindowsExplorer)                                                                       # Line 485 END (Killed Explorer shell without releasing muninn-sidecar locks)
+ [void]([HandleScanOOP]::CloseHandlesForPath($resolved))                                               # Line 734 START (WORKING: Force-closes all remote handles via DUPLICATE_CLOSE_SOURCE 0x1)
+ $shell = New-Object -ComObject Shell.Application                                                      # Line 739 (Connect to Explorer shell windows via COM without killing desktop)
+ foreach ($w in $shell.Windows()) { if ($w.LocationURL -like "*$leafName*") { $w.Quit() } }            # Line 740 (Close only Explorer window viewing the target folder)
+ if (-not (Test-FileIsLocked -Path $resolved)) { return $true }                                        # Line 748 (Fast-path return if remote handle closure already unlocked folder)
+ $remainingHandles = [HandleScanOOP]::Scan(@($resolved))                                               # Line 754 (Re-scan remaining handles if folder is still held)
+ Stop-Process -Id $hPid -Force -ErrorAction SilentlyContinue                                           # Line 762 (Terminate non-critical lock holder while protecting IDE & OS)
+ [void]([HandleScanOOP]::CloseHandlesForPath($resolved))                                               # Line 766 END (Final remote handle sweep and verification)
```

### 2.3. Diff 3: Per-Row Button Context Isolation in WPF (`script/file/adapter/lock-panel-window.psm1`)

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

### 2.4. Diff 4: Single-Pass Batch Multi-Scope Discovery (`script/file/adapter/detector-file-lock-process.psm1`)

```diff
- $trashLocations = @((Join-Path (Get-Location).Path "trash-bin"), "E:\proj\trash-bin")                                               # Line 31 START (BROKEN: Scanned only trash-bin folders)
- $subDirs = Get-ChildItem -LiteralPath $scope -Directory | Select-Object -First 30                                                   # Line 58 (Truncated at 30 folders, missing locked workspace items)
- $dirLocks = Get-FileLockingProcesses -Path $dir.FullName                                                                            # Line 61 END (Ran separate unbatched process/CIM scans per folder)
+ $discoveryLocations = @("E:\proj\trash-bin", "E:\proj", (Join-Path $cwdPath "trash-bin"), $cwdPath)                                 # Line 37 START (WORKING: Scans both trash-bin and workspace directories)
+ $subDirs = Get-ChildItem -LiteralPath $scope -Directory -ErrorAction SilentlyContinue                                               # Line 78 (Scans all child directories without 30-item truncation)
+ $batchHandles = [HandleScanOOP]::Scan($lockedTargets.ToArray())                                                                     # Line 104 (Single-pass kernel handle scan across all locked targets)
+ $batchCwds = [ProcessCwdReader]::FindProcessesInPaths($lockedTargets.ToArray())                                                     # Line 109 (Single-pass PEB CWD scan across all locked targets)
+ $batchProcs = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)                                                        # Line 114 (Single-pass CIM process command-line snapshot)
+ $found = Get-FileLockingProcesses -Path $lt -PreScannedHandles $batchHandles -PreScannedCwds $batchCwds -PreScannedProcs $batchProcs # Line 120 END (Instant attribution from pre-scanned batch data)
```

---

## 3. Clean Indented Module Topology (Zero Branches & Zero Tabs)

```text
all-lads-tool                                                                                                 # Root repository directory
    brief                                                                                                     # Architectural briefs directory
        v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md # Strict 1:1 script-to-docs standard
        v01-03-03_UNLOCKING-FILE-SCRIPT-FINALY-WORKING                                                        # Canonical brief for File Lock & Unlock engine
        v01-03-03_UNLOCKING-FILE-SCRIPT-FINALY-WORKING.md                                                     # Markdown mirror of Brief v01-03-03
    docs                                                                                                      # Documentation root (1:1 parity with script/)
        file                                                                                                  # File context documentation
            detector-file-lock-process.md                                                                     # 1:1 documentation for detector-file-lock-process.ps1
    script                                                                                                    # Executable scripts root (zero markdown allowed)
        file                                                                                                  # File context executables
            detector-file-lock-process.ps1                                                                    # Main entry point for CLI and WPF Lock Inspector
            adapter                                                                                           # Modular PowerShell adapter engines
                detector-file-lock-process.psm1                                                               # Master snapshot aggregator and batch scanner
                file-lock-inspector.psm1                                                                      # HandleScanOOP, ProcessCwdReader, and Unlock-FileOrFolder engine
                drive-activity-scanner.psm1                                                                   # Dynamic system drive and directory tree scanner
                lock-console-dashboard.psm1                                                                   # Interactive terminal CLI dashboard renderer
                lock-panel-window.psm1                                                                        # Interactive WPF dark card window host
```

---

## 4. Verification Checklist

- [x] **All `-` Lines First, All `+` Lines Second**: Every diff block strictly groups removed (`-`) lines at the top with `# Line xxxx START` / `# Line xxxx END` and added (`+`) lines below with `# Line xxxx START` / `# Line xxxx END`.
- [x] **Zero Branches & Zero Tabs**: All codeblocks use pure spaces and vertically column-aligned `#` annotations.
- [x] **Zero Crash (`0xc000070a` Eliminated)**: `HandleScanOOP` calibrates `fileTypeIndex` inside the active `FileStream` scope and never touches non-file kernel handles.
- [x] **Per-Row `[Unlock]` Execution**: Each row's `[Unlock]` button is isolated via `$sender.Tag` context and immediately releases remote directory/file handles via `DUPLICATE_CLOSE_SOURCE`.
