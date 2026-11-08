# Active File Lock & Disk Activity Inspector (`detector-file-lock-process.ps1`)

> **Context**: `file` / `all-lads-tool`  
> **Script**: `script/file/detector-file-lock-process.ps1`  
> **Adapter Engine**: `script/file/adapter/detector-file-lock-process.psm1`  
> **Architecture Standard**: Conforms strictly to Brief `v01-03-02` (Foldering Structure, 1:1 Script-to-Docs Parity, Zero Markdown in `script/`).

---

## 1. Overview & Purpose

When applications, background build jobs, language servers, or system indexing tools actively hold open handles to files, developers encounter sharing violations (`ERROR_SHARING_VIOLATION` `0x80070020` / `IOException`: *"The process cannot access the file because it is being used by another process"*).

`detector-file-lock-process.ps1` provides an interactive, dual-mode diagnostics and resolution console:
1. **Mode A (`App View`)**: Groups locked files by the holding Application and Process ID (PID), presenting file names, paths, lock modes, and safe non-destructive resolution actions (`Retry`, `Wait`, `Stage`, `Inspect`).
2. **Mode B (`Drive & Directory Tree View`)**: Discovers all active drives (`C:`, `D:`, `E:`) and presents an interactive, collapsible directory tree highlighting files currently locked or under active processing.

---

## 2. Command Line Arguments & Lapangan Parameters

Conforming to `[[donot-ngada-ngada-exact-lapangan-variables]]`, the exact literal parameter signature is:

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
| `-Mode` | String | `"CLI"` | Execution target: `"CLI"` (dashboard), `"Panel"` (WPF GUI), `"App"` (group by application), `"DriveTree"` (group by drive tree), or `"Inspect"` (single-run stdout). |
| `-Path` | String | `""` | Optional specific file or folder path to inspect for locks. If omitted, scans current workspace or drives. |
| `-Panel` | Switch | `$false` | Shortcut switch to immediately launch the interactive WPF Card Panel window. |
| `-Inspect`| Switch | `$false` | Shortcut switch for non-interactive diagnostics output. |
| `-Json` | Switch | `$false` | Emits raw structured JSON diagnostic output (used in pipelines and automation). |

---

## 3. Dual-Mode UI Specifications

### Mode A: Group by Application (`App View`)

Presents a clear inventory of all running applications holding open file handles within the target scope:

```text
+----------------------------------------------------------------------------------------------------+
| [FILE LOCK INSPECTOR] - MODE A: GROUP BY APPLICATION                              [Filter: code   ] |
+----------------------------------------------------------------------------------------------------+
| > Code.exe (PID: 14820) | Handles: 2 | Status: Shared Read / Write                                 |
|   |-- package.json             | <workspace>/package.json                     | [Inspect] [Release]|
|   |-- git-manage.ps1           | <workspace>/script/repo/git-manage.ps1       | [Inspect] [Release]|
|                                                                                                    |
| > node.exe (PID: 22104) | Handles: 1 | Status: Exclusive Write Lock (Conflict)                      |
|   |-- build-output.log         | <workspace>/build-output.log                 | [Retry] [Stage] [X]|
+----------------------------------------------------------------------------------------------------+
| [R] Refresh  [TAB] Switch to Drive Tree  [P] Launch WPF Panel  [F] Filter  [Q] Exit                |
+----------------------------------------------------------------------------------------------------+
```

### Mode B: Group by Drive & Directory Tree (`Drive Tree View`)

Discovers system drives dynamically and renders an interactive, collapsible directory tree highlighting active locks:

```text
+----------------------------------------------------------------------------------------------------+
| [FILE LOCK INSPECTOR] - MODE B: GROUP BY DRIVE & DIRECTORY TREE                   [Filter: .log   ] |
+----------------------------------------------------------------------------------------------------+
| [-] C:\ [OS System] (Free: 142 GB / 500 GB)                                                        |
|     +-- Program Files/                                                                             |
|     +-- Users/                                                                                     |
| [-] D:\ [Workspace Alpha] (Free: 410 GB / 1 TB)                                                    |
|     [-] 0pro/                                                                                      |
|         [-] pakcli-plugin/                                                                         |
|             * package.json            [LOCKED by Code.exe (PID: 14820)]                            |
| [-] E:\ [Workspace Beta] (Free: 620 GB / 2 TB)                                                     |
|     [-] proj/                                                                                      |
|         [-] all-lads-tool/                                                                         |
|             * build-output.log        [EXCLUSIVE LOCK by node.exe (PID: 22104)]                    |
+----------------------------------------------------------------------------------------------------+
| [ENTER] Expand/Collapse  [TAB] Switch to App View  [P] Launch WPF Panel  [R] Refresh  [Q] Exit      |
+----------------------------------------------------------------------------------------------------+
```

---

## 4. Conflict Resolution Strategy (Rule #01 Preservation Compliant)

When a locked file is detected during a pending modify/move/delete operation:
1. **Never Kill Blindly**: The tool never kills processes autonomously.
2. **Exponential Retry & Backoff**: Retries the file handle access up to 4 times (200ms, 500ms, 1000ms, 2000ms) to allow transient locks (e.g. search indexing, Antivirus scans) to clear.
3. **Shadow Staging (`.pending-swap`)**: For modifications, provides an option to stage changes into a temporary file without corrupting the original.
4. **Safe Process Termination**: If termination is explicitly requested by the user, validates that the target PID is not a critical system process (`explorer.exe`, `lsass.exe`, `services.exe`, `csrss.exe`) before asking for confirmation.

### 4.1. WPF Panel Features & Windows "Folder In Use" Detection

The WPF card panel (`-Panel`) provides interactive diagnostics for both leaf files and Windows directory locks:
1. **Target Scope Toolbar**: Allows specifying any folder/file path with `[Inspect Path]`, `[Browse...]`, and `[Paste Clipboard]`.
2. **Drag & Drop Support**: Dragging any folder or file from Windows File Explorer directly onto the Lock Inspector window automatically populates the target path and immediately runs lock inspection.
3. **Dual-Engine Detection (Leaf Files + Directory Handles)**: Uses Windows Restart Manager for file-level handles and transient move/rename probe to catch Windows "Folder In Use" dialogs where directory handles are held by Windows Explorer or background indexers.
4. **Action Controls**:
   - `[Reveal]`: Reveals and selects the resource in Windows Explorer.
   - `[Re-test]`: Instantly re-probes the resource lock status.
   - `[Unlock]`: Unlocks the resource by terminating the holding application process or restarting the Windows Explorer shell to release exclusive directory handles, immediately updating the status badge to green (`Clear (Unlocked)`).

---

## 5. Architecture & Adapter Modules

```text
script/file/
├── detector-file-lock-process.ps1                 # Entry point CLI & WPF dispatcher
└── adapter/
    ├── detector-file-lock-process.psm1            # Master aggregator module
    ├── file-lock-inspector.psm1                   # Windows Restart Manager P/Invoke prober
    ├── drive-activity-scanner.psm1                # System drive discovery & lazy tree enumerator
    ├── lock-console-dashboard.psm1                # Interactive ANSI CLI dashboard renderer
    └── lock-panel-window.psm1                     # Interactive WPF dark card window host
```

---

## 6. Verification & Invariants

- **Rule #001**: Zero hardcoded drive letters; drives are resolved dynamically via `[System.IO.DriveInfo]::GetDrives()` and relative paths.
- **Rule #01**: Zero unsolicited file or process removals.
- **Serious Mode**: Zero emojis across CLI banners, table columns, and status logs.
