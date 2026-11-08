# Active File Lock & Disk Activity Inspector (`detector-file-lock-process.ps1`)

> **Context**: `file` / `all-lads-tool`  
> **Script**: `script/file/detector-file-lock-process.ps1`  
> **Adapter Engine**: `script/file/adapter/detector-file-lock-process.psm1`  
> **Architecture Standard**: Conforms strictly to Brief `[[brief/v01-03-02_foldering-structure-updated-stricly-no-markdown-in-script-and-docs-file-name-per-script.md|v01-03-02]]` and Brief `[[brief/v01-03-03_UNLOCKING-FILE-SCRIPT-FINALY-WORKING.md|v01-03-03]]` (1:1 Script-to-Docs Parity, Zero Markdown in `script/`).

---

## 1. Overview & Purpose

When applications, IDE file-watcher sidecars (`muninn-sidecar.exe`), background build jobs (`node.exe`, `esbuild.exe`), language servers (`language_server.exe`), or terminals actively hold open file or directory handles, developers encounter sharing violations (`ERROR_SHARING_VIOLATION` `0x80070020`) or Windows Explorer **"Folder In Use"** dialogs (`ERROR_ACCESS_DENIED` `0x80070005`).

`detector-file-lock-process.ps1` provides an interactive, dual-mode diagnostics and unlocking suite:
1. **Mode A (`Group by Application`)**: Groups locked files and folders by the holding Application and Process ID (`PID`), presenting resource names, masked paths, open handle counts / lock modes, and instant row actions (`[Reveal]`, `[Re-test]`, `[Unlock]`).
2. **Mode B (`Group by Drive & Directory Tree`)**: Discovers all active drives (`C:`, `D:`, `E:`) dynamically and presents an interactive directory tree to select and inspect any target scope.

---

## 2. Command Line Arguments & Lapangan Parameters

Conforming to `[[skill/donot-ngada-ngada-exact-lapangan-variables.md|donot-ngada-ngada-exact-lapangan-variables]]`, the exact literal parameter signature in `script/file/detector-file-lock-process.ps1` is:

```powershell
param (
    [ValidateSet("CLI", "Panel", "App", "DriveTree", "Inspect")]
    [string]$Mode = "CLI",

    [string]$Path = "",

    [switch]$Panel,
    [switch]$Inspect,
    [switch]$Json
)
```

### Parameter Breakdown

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `-Mode` | String | `"CLI"` | Execution target: `"CLI"` (terminal dashboard), `"Panel"` (WPF Dark Card GUI), `"App"` (group by application), `"DriveTree"` (group by drive tree), or `"Inspect"` (single-run stdout). |
| `-Path` | String | `""` | Optional specific file or folder path to inspect for locks. If omitted, auto-discovers active locks across `trash-bin` and workspace directories. |
| `-Panel` | Switch | `$false` | Shortcut switch to immediately launch the interactive WPF Card Panel window. |
| `-Inspect`| Switch | `$false` | Shortcut switch for non-interactive diagnostics output. |
| `-Json` | Switch | `$false` | Emits raw structured JSON diagnostic output (used with `-Inspect`). |

---

## 3. Detection & Unlocking Engine Architecture (`v01-03-03`)

### 3.1. 4-Tier Lock Attribution (`file-lock-inspector.psm1`)
1. **Leaf File & Directory Move Prober (`Test-FileIsLocked`)**:
   - **Leaf Files**: Probes exclusive write access via `[System.IO.File]::Open(..., FileShare.None)`.
   - **Directories**: Probes atomic directory rename/move availability to catch Windows `"Folder In Use"` locks caused by open child handles or directory watchers.
2. **Kernel Handle Table Scanner (`HandleScanOOP`)**:
   - Opens a calibration `FileStream` and queries `NtQuerySystemInformation(64)` (`SystemExtendedHandleInformation`) in a single snapshot to resolve the exact `File` kernel `ObjectTypeIndex`.
   - Filters strictly to `ObjectTypeIndex == fileTypeIndex` (never touching NamedPipe WaitHandles, EventWaitHandles, or ALPC ports, preventing `0xc000070a` crashes).
   - Skips synchronous pipe access masks and resolves `GetFinalPathNameByHandle` on a background worker thread with a `150ms` timeout guard (`QueryWithTimeout`).
   - Excludes `explorer.exe` shell navigation from false-positive lock attribution.
3. **Remote Process PEB Working Directory Reader (`ProcessCwdReader`)**:
   - Reads process PEB memory via `NtQueryInformationProcess` + `ReadProcessMemory` (`FindProcessesInPaths`) to identify terminals or shells whose Current Working Directory (`CWD`) is inside the locked folder.
4. **Command-Line & Windows Restart Manager (`RestartManager.FileLockFinder`)**:
   - Uses `rstrtmgr.dll` for leaf files and `Win32_Process` command-line matching for background worker processes.

### 3.2. Surgical Remote Handle Closing (`Unlock-FileOrFolder`)
Clicking `[Unlock]` executes an 8-step non-destructive release sequence:
1. **Remote Handle Closure (`DUPLICATE_CLOSE_SOURCE`)**: Calls `[HandleScanOOP]::CloseHandlesForPath($resolved)` using `DuplicateHandle(..., 0x00000001)` to directly close open file and directory watcher handles held inside the target path by processes like `muninn-sidecar.exe` without killing the IDE.
2. **Explorer Folder Release**: Closes any open Windows Explorer windows pointing to the target folder via `Shell.Application`.
3. **Immediate Fast-Path Verification**: Checks `Test-FileIsLocked`; returns `$true` immediately if the lock is already cleared.
4. **Remaining Non-System Process Termination**: If still locked, terminates remaining non-critical processes holding handles or CWD inside the path (strictly protecting system processes and IDE hosts: `explorer`, `lsass`, `services`, `csrss`, `system`, `svchost`, `wininit`, `winlogon`, `dwm`, `antigravity`, `code`).
5. **Attribute Normalization & Backoff Verification**: Clears read-only/system/hidden flags on the target root and verifies unlock status across `150ms`, `350ms`, and `700ms` backoff intervals.

---

## 4. Dual-Mode UI Specifications

### 4.1. WPF Dark Card Panel (`-Panel`)
```text
+----------------------------------------------------------------------------------------------------------+
| LOCK INSPECTOR - Active File Lock & Disk Activity [Drag to Move] [Hold to Reveal] [Mask: ON] [Refresh] X |
+----------------------------------------------------------------------------------------------------------+
| Target Scope: [ E:\proj\trash-bin                                ] [Paste Clipboard] [Browse...] [Inspect]|
+----------------------------------------------------------------------------------------------------------+
| [Mode A: Group by Application] [Mode B: Group by Drive & Directory Tree]          Filter: [            ] |
+----------------------------------------------------------------------------------------------------------+
| APPLICATION / PID            FILE / FOLDER NAME     LOCKED RESOURCE PATH          LOCK MODE      ACTIONS |
+----------------------------------------------------------------------------------------------------------+
| muninn-sidecar (PID: 10872)  my-video               E:\proj\trash-bin\my-video    79 Handle(s)   [Reveal] [Re-test] [Unlock] |
| node (PID: 31832)            remotion               E:\proj\remotion              304 Handle(s)  [Reveal] [Re-test] [Unlock] |
+----------------------------------------------------------------------------------------------------------+
```

- **Target Scope Toolbar**: Includes `[Paste Clipboard]`, `[Browse...]`, and `[Inspect Path]`, plus full window Drag & Drop support.
- **Row Actions** (isolated per row via `$sender.Tag` context):
  - `[Reveal]`: Selects the locked item in Windows File Explorer.
  - `[Re-test]`: Re-checks `Test-FileIsLocked` and updates the badge to `Clear (Unlocked)` if released.
  - `[Unlock]`: Runs `Unlock-FileOrFolder`, turning the status badge green (`Clear (Unlocked)`) and button to `Unlocked`.
- **Privacy Masking (`Format-PrivacyMaskString`)**: Masks emails and user profile paths (`C:\Users\fa***`) to 2 visible characters by default (`Mask: ON (2-Letter)`), with ephemeral `Hold to Reveal` and session-only toggle.

### 4.2. CLI Dashboard (`-Mode CLI`)
Interactive console view supporting `[TAB]` to toggle between `App` view and `DriveTree` view, `[R]` to refresh snapshot, `[P]` to open the WPF Panel, and `[Q]` to exit.

---

## 5. Architecture & Adapter Modules

```text
script/file/
├── detector-file-lock-process.ps1                 # Entry point CLI & WPF dispatcher
└── adapter/
    ├── detector-file-lock-process.psm1            # Master snapshot aggregator & batch scanner
    ├── file-lock-inspector.psm1                   # HandleScanOOP, ProcessCwdReader, RestartManager & Unlock engine
    ├── drive-activity-scanner.psm1                # System drive discovery & lazy tree enumerator
    ├── lock-console-dashboard.psm1                # Interactive ANSI CLI dashboard renderer
    └── lock-panel-window.psm1                     # Interactive WPF dark card window host
```

---

## 6. Verification & Invariants

- **Rule #001**: Zero hardcoded user secrets; drives are resolved dynamically via `[System.IO.DriveInfo]::GetDrives()`.
- **Rule #01**: Zero unsolicited file deletions.
- **Rule #4**: Privacy 2-letter exposure masking active by default on all UI views; reveal state is never written to disk.
- **Serious Mode**: Zero emojis across CLI banners, WPF controls, and logs.
