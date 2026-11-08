---
name: what-todo-trying-to-modify-move-delete-on-going-prosseeeing-by-other-app
aliases: [file-locked-by-other-process, handle-busy-file-conflict, retry-backoff-locked-file, file-in-use-resolution-protocol]
category: FILE_RECOVERY_PROTOCOL
tags: [all-lads-tool, file-lock, sharing-violation, busy-file, process-lock, safety, retry-backoff, protocol]
description: Definitive diagnostic and resolution standard for handling file lock conflicts (sharing violations) when modifying, moving, or deleting files actively held by other running applications.
dependencies:
  - "[[01-number-one-rule-DONOT-REMOVE-ANYTHING-THAT-I-DIDNOT-ASKED]]"
  - "[[donot-code-yet]]"
  - "[[donot-commit-yet]]"
  - "[[zero-hardcoded-variables]]"
  - "[[zero-emoji-serious-mode]]"
related:
  - "[[donot-ngada-ngada-exact-lapangan-variables]]"
  - "[[delete-trashbin-project-root]]"
  - "[[delete-trashbin-system-not-permanent]]"
pros:
  - "Prevents catastrophic script aborts and unhandled sharing violation crashes"
  - "Safely identifies locking applications and PIDs using Windows Restart Manager APIs"
  - "Enforces non-destructive exponential backoff and shadow staging before resorting to process termination"
cons:
  - "Requires brief delay during exponential backoff retry cycles"
---

# File Locked by Other Application Resolution Protocol (`what-todo-trying-to-modify-move-delete-on-going-prosseeeing-by-other-app`)

> [!CAUTION]
> **ABSOLUTE INVARIANT**:
> When a script or user attempts to **MODIFY, MOVE, RENAME, or DELETE** a file and encounters a sharing violation (`ERROR_SHARING_VIOLATION 0x80070020` / `IOException`):
> 1. **DO NOT PANIC CRASH**: Never terminate execution abruptly without diagnosing the locking process.
> 2. **DO NOT KILL BLINDLY**: Never kill unknown processes without identifying the application and obtaining explicit confirmation.
> 3. **RULE #01 COMPLIANCE**: Never corrupt, truncate, or wipe out locked files.
> 4. **FOLLOW THE 5-STEP RESOLUTION PIPELINE**: Diagnose &rarr; Exponential Backoff &rarr; Shadow Stage &rarr; Actionable User Prompt &rarr; Safe Release.

---

## 1. Anatomy of the File Lock Conflict

File locks occur when an operating system process opens a file handle with exclusive write permissions (`FileShare.None` or `FileShare.Read`). Common culprits include:
- Integrated Development Environments (VS Code, Visual Studio, JetBrains) holding file handles during compilation or git sync.
- Node.js / Python / Java background servers running hot-reload watchers.
- Office suites (Excel, Word) creating hidden lock markers (`~$filename`).
- Windows Defender / Antivirus real-time file scanners holding temporary inspection locks.
- Command-line shells or child processes whose current working directory is anchored in the target folder.

---

## 2. The 5-Step Resolution Pipeline

```text
+-------------------------------------------------------------------------------+
|                    FILE LOCK RESOLUTION WORKFLOW PIPELINE                     |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ File Operation Triggered (Modify / Move / Delete) ]                        |
|                    |                                                          |
|                    v                                                          |
|  [ SHARING VIOLATION TRAPPED: System.IO.IOException ]                         |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 1: IDENTIFY LOCKING PROCESS (Windows Restart Manager) ]               |
|  - Resolve Application Name and Process ID (PID)                              |
|  - Is target process a critical Windows system process?                       |
|    If YES: ABORT DESTRUCTIVE ACTIONS IMMEDIATELY.                             |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 2: EXPONENTIAL BACKOFF RETRY ]                                        |
|  - Transient Lock Guard: Sleep 200ms -> 500ms -> 1000ms -> 2000ms (Max 4x)   |
|  - If file frees naturally: COMPLETE OPERATION CLEANLY.                       |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 3: NON-DESTRUCTIVE FALLBACK (If Modifying) ]                          |
|  - Write to Staged File: <filename>.pending-swap                              |
|  - Inform user that content is safely staged.                                 |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 4: INTERACTIVE DIAGNOSTIC PROMPT ]                                    |
|  - Present: Process Name, PID, File Path, Lock Mode                           |
|  - Options: [R] Retry  [W] Wait 5s  [S] Keep Staged  [C] Close App (Confirm)  |
|                    |                                                          |
|                    v                                                          |
|  [ STEP 5: SAFE PROCESS CLOSURE (Explicit User Approval Only) ]               |
|  - Send WM_CLOSE (Graceful) -> Wait 3s                                        |
|  - Complete file operation -> Verify disk integrity                           |
+-------------------------------------------------------------------------------+
```

---

## 3. Mandatory Behavioral Matrix: Violations vs. Standard

| Action | FORBIDDEN (Destructive / Fragile) | MANDATORY (Protocol Standard) |
| :--- | :--- | :--- |
| **Encountering Sharing Violation** | Letting script crash with unhandled stack trace | Catching `IOException` and invoking diagnostic prober |
| **Handling Locked Process** | Running `Stop-Process -Force` autonomously | Identifying process name/PID and presenting options to user |
| **System Process Locked** | Attempting to kill system process (`explorer`, `lsass`) | Flagging as protected; preventing destructive termination |
| **Modifying Locked Document** | Overwriting with empty content or failing silently | Staging update to `.pending-swap` and alerting user |
| **Deleting Locked File** | Forcing recursive deletion attempts in tight loop | Running 4-stage exponential backoff; prompting if lock persists |

---

## 4. Ground-Truth PowerShell Lock Detection Implementation

The canonical detection engine is implemented in [script/file/adapter/file-lock-inspector.psm1](file:///e:/proj/all-lads-tool/script/file/adapter/file-lock-inspector.psm1) using Windows Restart Manager:

```powershell
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

public class FileLockFinder {
    [DllImport("rstrtmgr.dll", CharSet = CharSet.Auto)]
    public static extern int RmStartSession(out uint pSessionHandle, int dwSessionFlags, string strSessionKey);

    [DllImport("rstrtmgr.dll")]
    public static extern int RmEndSession(uint pSessionHandle);

    [DllImport("rstrtmgr.dll", CharSet = CharSet.Auto)]
    public static extern int RmRegisterResources(uint pSessionHandle, uint nFiles, string[] rgsFilenames,
        uint nApplications, uint[] rgApplications, uint nServices, string[] rgsServiceNames);

    [DllImport("rstrtmgr.dll")]
    public static extern int RmGetList(uint pSessionHandle, out uint pnProcInfoNeeded,
        ref uint pnProcInfo, [In, Out] RM_PROCESS_INFO[] rgAffectedApps, ref uint lpdwRebootReasons);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct RM_PROCESS_INFO {
        public RM_UNIQUE_PROCESS Process;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string strAppName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
        public string strServiceShortName;
        public int ApplicationType;
        public uint AppStatus;
        public uint TSSessionId;
        [MarshalAs(UnmanagedType.Bool)]
        public bool bRestartable;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct RM_UNIQUE_PROCESS {
        public int dwProcessId;
        public System.Runtime.InteropServices.ComTypes.FILETIME ProcessStartTime;
    }
}
'@
```

---

## 5. Associated Tools & Scripts

- **Primary Diagnostic Inspector**: [script/file/detector-file-lock-process.ps1](file:///e:/proj/all-lads-tool/script/file/detector-file-lock-process.ps1)
- **1:1 Documentation**: [docs/file/detector-file-lock-process.md](file:///e:/proj/all-lads-tool/docs/file/detector-file-lock-process.md)
- **Adapter Engine**: [script/file/adapter/detector-file-lock-process.psm1](file:///e:/proj/all-lads-tool/script/file/adapter/detector-file-lock-process.psm1)
