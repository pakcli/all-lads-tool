<#
.SYNOPSIS
    Engine: Windows File & Directory Lock Prober
.DESCRIPTION
    Detects which files or directories cannot be modified, moved, renamed, or deleted:
    1. Leaf File Prober: Tests exclusive write access ([System.IO.File]::Open).
    2. Directory Handle Prober: Tests directory move/rename sharing lock (catches "Folder In Use" dialogs).
    3. Windows Restart Manager: Discovers specific PID / ProcessName when available.
#>

if (-not ([System.Management.Automation.PSTypeName]'RestartManager.FileLockFinder').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace RestartManager {
    public class FileLockFinder {
        [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
        public static extern int RmStartSession(out uint pSessionHandle, int dwSessionFlags, [Out] char[] strSessionKey);

        [DllImport("rstrtmgr.dll")]
        public static extern int RmEndSession(uint pSessionHandle);

        [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
        public static extern int RmRegisterResources(uint pSessionHandle, uint nFiles, string[] rgsFilenames,
            uint nApplications, uint[] rgApplications, uint nServices, string[] rgsServiceNames);

        [DllImport("rstrtmgr.dll", CharSet = CharSet.Unicode)]
        public static extern int RmGetList(uint pSessionHandle, out uint pnProcInfoNeeded,
            ref uint pnProcInfo, [In, Out] RM_PROCESS_INFO[] rgAffectedApps, ref uint lpdwRebootReasons);

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
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

        public static List<int> FindLockingProcessIds(string path) {
            List<int> pids = new List<int>();
            uint handle;
            char[] sessionKey = new char[33];
            int res = RmStartSession(out handle, 0, sessionKey);
            if (res != 0) return pids;

            try {
                string[] resources = new string[] { path };
                res = RmRegisterResources(handle, (uint)resources.Length, resources, 0, null, 0, null);
                if (res != 0) return pids;

                uint procInfoNeeded = 0;
                uint numProcs = 0;
                uint rebootReasons = 0;
                res = RmGetList(handle, out procInfoNeeded, ref numProcs, null, ref rebootReasons);
                if (res == 234) {
                    RM_PROCESS_INFO[] infos = new RM_PROCESS_INFO[procInfoNeeded];
                    numProcs = procInfoNeeded;
                    res = RmGetList(handle, out procInfoNeeded, ref numProcs, infos, ref rebootReasons);
                    if (res == 0) {
                        for (int i = 0; i < numProcs; i++) {
                            if (!pids.Contains(infos[i].Process.dwProcessId)) {
                                pids.Add(infos[i].Process.dwProcessId);
                            }
                        }
                    }
                } else if (res == 0 && numProcs > 0) {
                    RM_PROCESS_INFO[] infos = new RM_PROCESS_INFO[numProcs];
                    res = RmGetList(handle, out procInfoNeeded, ref numProcs, infos, ref rebootReasons);
                    if (res == 0) {
                        for (int i = 0; i < numProcs; i++) {
                            if (!pids.Contains(infos[i].Process.dwProcessId)) {
                                pids.Add(infos[i].Process.dwProcessId);
                            }
                        }
                    }
                }
            } finally {
                RmEndSession(handle);
            }
            return pids;
        }
    }
}
'@
}

if (-not ([System.Management.Automation.PSTypeName]'ProcessCwdReader').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;

public class ProcessCwdReader {
    private const int ProcessBasicInformation = 0;

    [DllImport("ntdll.dll")]
    private static extern int NtQueryInformationProcess(IntPtr hProcess, int processInformationClass, ref PROCESS_BASIC_INFORMATION processInformation, int processInformationLength, out int returnLength);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, int processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, [Out] byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);

    [DllImport("kernel32.dll")]
    private static extern bool CloseHandle(IntPtr hObject);

    private const uint PROCESS_QUERY_LIMITED_INFORMATION = 0x1000;
    private const uint PROCESS_VM_READ = 0x0010;

    [StructLayout(LayoutKind.Sequential)]
    private struct PROCESS_BASIC_INFORMATION {
        public IntPtr ExitStatus;
        public IntPtr PebBaseAddress;
        public IntPtr AffinityMask;
        public IntPtr BasePriority;
        public IntPtr UniqueProcessId;
        public IntPtr InheritedFromUniqueProcessId;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct UNICODE_STRING {
        public ushort Length;
        public ushort MaximumLength;
        public IntPtr Buffer;
    }

    public static string GetProcessCwd(int pid) {
        IntPtr hProc = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION | PROCESS_VM_READ, false, pid);
        if (hProc == IntPtr.Zero) return null;

        try {
            PROCESS_BASIC_INFORMATION pbi = new PROCESS_BASIC_INFORMATION();
            int retLen;
            int status = NtQueryInformationProcess(hProc, ProcessBasicInformation, ref pbi, Marshal.SizeOf(pbi), out retLen);
            if (status != 0 || pbi.PebBaseAddress == IntPtr.Zero) return null;

            int procParamsOffset = IntPtr.Size == 8 ? 0x20 : 0x10;
            byte[] ptrBuf = new byte[IntPtr.Size];
            IntPtr bytesRead;
            if (!ReadProcessMemory(hProc, new IntPtr(pbi.PebBaseAddress.ToInt64() + procParamsOffset), ptrBuf, ptrBuf.Length, out bytesRead))
                return null;

            IntPtr procParams = IntPtr.Size == 8 ? (IntPtr)BitConverter.ToInt64(ptrBuf, 0) : (IntPtr)BitConverter.ToInt32(ptrBuf, 0);
            if (procParams == IntPtr.Zero) return null;

            int cwdOffset = IntPtr.Size == 8 ? 0x38 : 0x24;
            byte[] uStrBuf = new byte[Marshal.SizeOf(typeof(UNICODE_STRING))];
            if (!ReadProcessMemory(hProc, new IntPtr(procParams.ToInt64() + cwdOffset), uStrBuf, uStrBuf.Length, out bytesRead))
                return null;

            ushort len = BitConverter.ToUInt16(uStrBuf, 0);
            IntPtr bufPtr = IntPtr.Size == 8 ? (IntPtr)BitConverter.ToInt64(uStrBuf, 8) : (IntPtr)BitConverter.ToInt32(uStrBuf, 4);
            if (bufPtr == IntPtr.Zero || len == 0 || len > 2048) return null;

            byte[] strBuf = new byte[len];
            if (!ReadProcessMemory(hProc, bufPtr, strBuf, strBuf.Length, out bytesRead))
                return null;

            return Encoding.Unicode.GetString(strBuf);
        } catch {
            return null;
        } finally {
            CloseHandle(hProc);
        }
    }

    public class ProcessHoldingInfo {
        public int ProcessId;
        public string ProcessName;
        public string Cwd;
    }

    public static List<ProcessHoldingInfo> FindProcessesInPath(string targetPath) {
        if (string.IsNullOrWhiteSpace(targetPath)) return new List<ProcessHoldingInfo>();
        return FindProcessesInPaths(new string[] { targetPath });
    }

    public static List<ProcessHoldingInfo> FindProcessesInPaths(string[] targetPaths) {
        var list = new List<ProcessHoldingInfo>();
        if (targetPaths == null || targetPaths.Length == 0) return list;
        var prefixes = new List<string>();
        foreach (var tp in targetPaths) {
            if (!string.IsNullOrWhiteSpace(tp)) prefixes.Add(tp.TrimEnd('\\', '/').ToLowerInvariant());
        }
        if (prefixes.Count == 0) return list;

        int me = Process.GetCurrentProcess().Id;
        foreach (var proc in Process.GetProcesses()) {
            try {
                if (proc.Id <= 4 || proc.Id == me) continue;
                string cwd = GetProcessCwd(proc.Id);
                if (!string.IsNullOrEmpty(cwd)) {
                    string lowerCwd = cwd.TrimEnd('\\', '/').ToLowerInvariant();
                    foreach (var clean in prefixes) {
                        if (lowerCwd == clean || lowerCwd.StartsWith(clean + "\\")) {
                            list.Add(new ProcessHoldingInfo {
                                ProcessId = proc.Id,
                                ProcessName = proc.ProcessName,
                                Cwd = cwd
                            });
                            break;
                        }
                    }
                }
            } catch {}
        }
        return list;
    }
}
'@
}

if (-not ([System.Management.Automation.PSTypeName]'HandleScanOOP').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;

public static class HandleScanOOP {
    [DllImport("ntdll.dll")]
    static extern uint NtQuerySystemInformation(int cls, IntPtr buf, int len, out int retLen);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern IntPtr OpenProcess(uint access, bool inherit, int pid);
    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool DuplicateHandle(IntPtr srcProc, IntPtr srcHandle, IntPtr dstProc, out IntPtr dstHandle, uint access, bool inherit, uint options);
    [DllImport("kernel32.dll")]
    static extern bool CloseHandle(IntPtr h);
    [DllImport("kernel32.dll")]
    static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")]
    static extern uint GetFileType(IntPtr h);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    static extern uint GetFinalPathNameByHandle(IntPtr h, StringBuilder sb, uint cch, uint flags);

    [StructLayout(LayoutKind.Sequential)]
    struct ENTRY {
        public IntPtr Object;
        public IntPtr UniqueProcessId;
        public IntPtr HandleValue;
        public uint GrantedAccess;
        public ushort CreatorBackTraceIndex;
        public ushort ObjectTypeIndex;
        public uint HandleAttributes;
        public uint Reserved;
    }

    static List<ENTRY> Snapshot() {
        var list = new List<ENTRY>();
        int len = 0x100000;
        IntPtr buf = Marshal.AllocHGlobal(len);
        try {
            int ret;
            while (NtQuerySystemInformation(64, buf, len, out ret) == 0xC0000004) {
                Marshal.FreeHGlobal(buf);
                len = ret + 0x100000;
                buf = Marshal.AllocHGlobal(len);
            }
            long count = Marshal.ReadInt64(buf);
            int size = Marshal.SizeOf(typeof(ENTRY));
            IntPtr cur = new IntPtr(buf.ToInt64() + 16);
            for (long i = 0; i < count; i++) {
                list.Add((ENTRY)Marshal.PtrToStructure(cur, typeof(ENTRY)));
                cur = new IntPtr(cur.ToInt64() + size);
            }
        } finally { Marshal.FreeHGlobal(buf); }
        return list;
    }

    static System.Threading.Thread worker;
    static System.Threading.AutoResetEvent jobReady;
    static System.Threading.AutoResetEvent jobDone;
    static IntPtr jobHandle;
    static string jobResult;

    static void StartWorker() {
        jobReady = new System.Threading.AutoResetEvent(false);
        jobDone = new System.Threading.AutoResetEvent(false);
        var ready = jobReady; var done = jobDone;
        worker = new System.Threading.Thread(() => {
            while (true) {
                ready.WaitOne();
                string r = null;
                try {
                    if (GetFileType(jobHandle) == 1) {
                        var sb = new StringBuilder(2048);
                        if (GetFinalPathNameByHandle(jobHandle, sb, 2048, 0) != 0) r = sb.ToString();
                    }
                } catch { }
                jobResult = r;
                done.Set();
            }
        });
        worker.IsBackground = true;
        worker.Start();
    }

    static bool lastTimedOut;

    static string QueryWithTimeout(IntPtr h, int ms) {
        if (worker == null) StartWorker();
        jobHandle = h;
        jobResult = null;
        lastTimedOut = false;
        jobReady.Set();
        if (jobDone.WaitOne(ms)) return jobResult;
        lastTimedOut = true;
        StartWorker();
        return null;
    }

    static int ResolveFileTypeIndex(List<ENTRY> snap, int me) {
        string tmp = Path.GetTempFileName();
        using (var fs = new FileStream(tmp, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 1, FileOptions.DeleteOnClose)) {
            long myHandle = fs.SafeFileHandle.DangerousGetHandle().ToInt64();
            foreach (var e in snap) {
                if (e.UniqueProcessId.ToInt64() == me && e.HandleValue.ToInt64() == myHandle) {
                    return e.ObjectTypeIndex;
                }
            }
            var snap2 = Snapshot();
            foreach (var e in snap2) {
                if (e.UniqueProcessId.ToInt64() == me && e.HandleValue.ToInt64() == myHandle) {
                    return e.ObjectTypeIndex;
                }
            }
        }
        return -1;
    }

    // Returns lines: PID|ProcessName|HandleHex|Path
    public static List<string> Scan(string[] targets) {
        var output = new List<string>();
        if (targets == null || targets.Length == 0) return output;
        var prefixes = new List<string>();
        foreach (var t in targets) {
            if (!string.IsNullOrWhiteSpace(t)) prefixes.Add(t.TrimEnd('\\').ToLowerInvariant());
        }
        if (prefixes.Count == 0) return output;

        int me = Process.GetCurrentProcess().Id;
        string tmp = Path.GetTempFileName();
        int fileTypeIndex = -1;
        using (var fs = new FileStream(tmp, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 1, FileOptions.DeleteOnClose)) {
            long myHandle = fs.SafeFileHandle.DangerousGetHandle().ToInt64();
            var snap = Snapshot();
            foreach (var e in snap) {
                if (e.UniqueProcessId.ToInt64() == me && e.HandleValue.ToInt64() == myHandle) {
                    fileTypeIndex = e.ObjectTypeIndex;
                    break;
                }
            }
            if (fileTypeIndex < 0) return output;

            var names = new Dictionary<int, string>();
            var procHandles = new Dictionary<int, IntPtr>();
            IntPtr self = GetCurrentProcess();
            try {
                foreach (var e in snap) {
                    if (e.ObjectTypeIndex != fileTypeIndex) continue;
                    int pid = (int)e.UniqueProcessId.ToInt64();
                    if (pid <= 4 || pid == me) continue;
                    IntPtr hp;
                    if (!procHandles.TryGetValue(pid, out hp)) {
                        hp = OpenProcess(0x0040, false, pid);
                        procHandles[pid] = hp;
                    }
                    if (hp == IntPtr.Zero) continue;
                    uint ga = e.GrantedAccess;
                    if (ga == 0x0012019f || ga == 0x001a019f || ga == 0x00120189 || ga == 0x00100000 || ga == 0x0016019f) continue;
                    IntPtr dup;
                    if (!DuplicateHandle(hp, e.HandleValue, self, out dup, 0, false, 2)) continue;
                    bool timedOut = false;
                    try {
                        string p = QueryWithTimeout(dup, 150);
                        if (p == null) { timedOut = lastTimedOut; continue; }
                        if (p.StartsWith(@"\\?\")) p = p.Substring(4);
                        string low = p.TrimEnd('\\').ToLowerInvariant();
                        foreach (var pre in prefixes) {
                            if (low == pre || low.StartsWith(pre + "\\")) {
                                string n;
                                if (!names.TryGetValue(pid, out n)) {
                                    try { n = Process.GetProcessById(pid).ProcessName; } catch { n = "?"; }
                                    names[pid] = n;
                                }
                                output.Add(pid + "|" + n + "|0x" + e.HandleValue.ToInt64().ToString("X") + "|" + p);
                                break;
                            }
                        }
                    } finally { if (!timedOut) CloseHandle(dup); }
                }
            } finally {
                foreach (var hp in procHandles.Values) if (hp != IntPtr.Zero) CloseHandle(hp);
            }
        }
        return output;
    }

    // Force-closes all remote file and directory handles matching targetPath or inside targetPath
    public static int CloseHandlesForPath(string targetPath) {
        if (string.IsNullOrWhiteSpace(targetPath)) return 0;
        string pre = targetPath.TrimEnd('\\').ToLowerInvariant();
        int closedCount = 0;

        int me = Process.GetCurrentProcess().Id;
        string tmp = Path.GetTempFileName();
        int fileTypeIndex = -1;
        using (var fs = new FileStream(tmp, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 1, FileOptions.DeleteOnClose)) {
            long myHandle = fs.SafeFileHandle.DangerousGetHandle().ToInt64();
            var snap = Snapshot();
            foreach (var e in snap) {
                if (e.UniqueProcessId.ToInt64() == me && e.HandleValue.ToInt64() == myHandle) {
                    fileTypeIndex = e.ObjectTypeIndex;
                    break;
                }
            }
            if (fileTypeIndex < 0) return 0;

            var procHandles = new Dictionary<int, IntPtr>();
            IntPtr self = GetCurrentProcess();
            try {
                foreach (var e in snap) {
                    if (e.ObjectTypeIndex != fileTypeIndex) continue;
                    int pid = (int)e.UniqueProcessId.ToInt64();
                    if (pid <= 4 || pid == me) continue;
                    IntPtr hp;
                    if (!procHandles.TryGetValue(pid, out hp)) {
                        hp = OpenProcess(0x0040, false, pid);
                        procHandles[pid] = hp;
                    }
                    if (hp == IntPtr.Zero) continue;
                    uint ga = e.GrantedAccess;
                    if (ga == 0x0012019f || ga == 0x001a019f || ga == 0x00120189 || ga == 0x00100000 || ga == 0x0016019f) continue;
                    IntPtr dup;
                    if (!DuplicateHandle(hp, e.HandleValue, self, out dup, 0, false, 2)) continue;
                    bool timedOut = false;
                    bool matched = false;
                    try {
                        string p = QueryWithTimeout(dup, 150);
                        if (p == null) { timedOut = lastTimedOut; continue; }
                        if (p.StartsWith(@"\\?\")) p = p.Substring(4);
                        string low = p.TrimEnd('\\').ToLowerInvariant();
                        if (low == pre || low.StartsWith(pre + "\\")) {
                            matched = true;
                        }
                    } finally {
                        if (!timedOut) CloseHandle(dup);
                    }

                    if (matched) {
                        IntPtr dummy;
                        if (DuplicateHandle(hp, e.HandleValue, IntPtr.Zero, out dummy, 0, false, 0x00000001)) {
                            closedCount++;
                        }
                    }
                }
            } finally {
                foreach (var hp in procHandles.Values) if (hp != IntPtr.Zero) CloseHandle(hp);
            }
        }
        return closedCount;
    }
}
'@
}

function Test-FileIsLocked {
    [CmdletBinding()]
    param(
        [string]$Path = ""
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path))) {
        return $false
    }

    # 1. Leaf File test
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        try {
            $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
            if ($stream) {
                $stream.Close()
                $stream.Dispose()
            }
            return $false
        } catch [System.IO.IOException] {
            return $true
        } catch [System.UnauthorizedAccessException] {
            return $true
        } catch {
            return $false
        }
    }

    # 2. Directory Handle test (Catches "Folder In Use" dialogs)
    if (Test-Path -LiteralPath $Path -PathType Container) {
        try {
            $parent = [System.IO.Path]::GetDirectoryName($Path)
            $dirName = [System.IO.Path]::GetFileName($Path)
            $testName = Join-Path $parent ($dirName + "_locktest_temp")
            [System.IO.Directory]::Move($Path, $testName)
            [System.IO.Directory]::Move($testName, $Path)
            return $false
        } catch {
            # Move failed -> Folder is in use by another program
            return $true
        }
    }

    return $false
}

function Get-FileLockingProcesses {
    [CmdletBinding()]
    param(
        [string]$Path = "",
        [array]$PreScannedHandles = $null,
        [array]$PreScannedCwds = $null,
        [array]$PreScannedProcs = $null
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path))) {
        return @()
    }

    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue).Path
    if (-not $resolved) { $resolved = $Path }

    $isLocked = Test-FileIsLocked -Path $resolved
    if (-not $isLocked) { return @() }

    # Query Restart Manager for locking PIDs (only for leaf files; directories use HandleScanOOP directly for speed)
    $pids = [System.Collections.Generic.List[int]]::new()
    $isContainer = Test-Path -LiteralPath $resolved -PathType Container
    if (-not $isContainer) {
        try {
            $rmPids = [RestartManager.FileLockFinder]::FindLockingProcessIds($resolved)
            foreach ($p in $rmPids) {
                if (-not $pids.Contains($p)) { $pids.Add($p) }
            }
        } catch {}
    }

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $leafName = [System.IO.Path]::GetFileName($resolved)
    if (-not $leafName) { $leafName = $resolved }

    # If Restart Manager found specific PIDs, return each process
    if ($pids.Count -gt 0) {
        $systemNames = @("explorer", "lsass", "services", "csrss")
        foreach ($pidNum in $pids) {
            $proc = Get-Process -Id $pidNum -ErrorAction SilentlyContinue
            $procName = if ($proc) { $proc.ProcessName } else { "Process" }
            $isSys = if ($proc -and ($systemNames -contains $proc.ProcessName)) { $true } else { $false }
            $results.Add([PSCustomObject]@{
                ProcessId   = $pidNum
                ProcessName = $procName
                FilePath    = $resolved
                FileName    = $leafName
                IsSystem    = $isSys
                LockMode    = if ($isContainer) { "Folder In-Use (Subfile open by $procName)" } else { "File In-Use" }
            })
        }
    } else {
        # 1. Scan open File & Directory Handles via NtQuerySystemInformation (HandleScanOOP)
        try {
            $handleLines = if ($null -ne $PreScannedHandles) {
                $PreScannedHandles
            } else {
                [HandleScanOOP]::Scan(@($resolved))
            }
            $prefixLow = $resolved.TrimEnd('\').ToLowerInvariant()
            $byName = @{}
            foreach ($line in $handleLines) {
                $parts = $line -split '\|', 4
                if ($parts.Count -ge 4) {
                    $hPathLow = $parts[3].TrimEnd('\').ToLowerInvariant()
                    if ($hPathLow -eq $prefixLow -or $hPathLow.StartsWith($prefixLow + "\")) {
                        $hPid = [int]$parts[0]
                        $hName = $parts[1]
                        # Exclude File Explorer shell navigation from being blamed unless nothing else exists
                        if ($hName -notmatch '^(explorer)$') {
                            $key = $hName.ToLowerInvariant()
                            if (-not $byName.ContainsKey($key)) {
                                $byName[$key] = [PSCustomObject]@{
                                    ProcessId   = $hPid
                                    ProcessName = $hName
                                    Count       = 0
                                }
                            }
                            $byName[$key].Count++
                        }
                    }
                }
            }
            foreach ($entry in $byName.Values) {
                $isSys = if ($entry.ProcessName -match '^(lsass|services|csrss|system|svchost)$') { $true } else { $false }
                $results.Add([PSCustomObject]@{
                    ProcessId   = $entry.ProcessId
                    ProcessName = $entry.ProcessName
                    FilePath    = $resolved
                    FileName    = $leafName
                    IsSystem    = $isSys
                    LockMode    = "Folder In Use ($($entry.Count) Open Handle(s))"
                })
            }
        } catch {}

        # 2. Check processes whose Current Working Directory is inside this folder
        try {
            $cwdProcs = if ($null -ne $PreScannedCwds) {
                $prefixLowCwd = $resolved.TrimEnd('\', '/').ToLowerInvariant()
                $PreScannedCwds | Where-Object {
                    $cLow = $_.Cwd.TrimEnd('\', '/').ToLowerInvariant()
                    $cLow -eq $prefixLowCwd -or $cLow.StartsWith($prefixLowCwd + "\")
                }
            } else {
                [ProcessCwdReader]::FindProcessesInPath($resolved)
            }
            foreach ($cp in $cwdProcs) {
                if ($cp.ProcessName -match '^explorer$') { continue }
                $isSys = if ($cp.ProcessName -match '^(lsass|services|csrss|system|svchost)$') { $true } else { $false }
                $exists = $results | Where-Object { $_.ProcessId -eq $cp.ProcessId -or $_.ProcessName.ToLowerInvariant() -eq $cp.ProcessName.ToLowerInvariant() }
                if (-not $exists) {
                    $results.Add([PSCustomObject]@{
                        ProcessId   = $cp.ProcessId
                        ProcessName = $cp.ProcessName
                        FilePath    = $resolved
                        FileName    = $leafName
                        IsSystem    = $isSys
                        LockMode    = "Folder In Use (Working Directory of $($cp.ProcessName))"
                    })
                }
            }
        } catch {}

        # 3. Check running processes whose CommandLine contains this folder or path
        try {
            $procPool = if ($null -ne $PreScannedProcs) {
                $PreScannedProcs
            } else {
                Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
                    $_.ProcessId -ne $PID -and $_.Name -notmatch '^(explorer|svchost|csrss|lsass)\.exe$'
                }
            }
            $matchingProcs = $procPool | Where-Object {
                ($_.CommandLine -like "*\$leafName*" -or $_.CommandLine -like "*/$leafName*" -or $_.CommandLine -like "*`"$leafName`"*") -or
                ($_.CommandLine -like "*$resolved*")
            }
            foreach ($mp in $matchingProcs) {
                $cleanProcName = $mp.Name -replace '\.exe$', ''
                $exists = $results | Where-Object { $_.ProcessId -eq $mp.ProcessId -or $_.ProcessName -eq $cleanProcName }
                if (-not $exists) {
                    $results.Add([PSCustomObject]@{
                        ProcessId   = $mp.ProcessId
                        ProcessName = $cleanProcName
                        FilePath    = $resolved
                        FileName    = $leafName
                        IsSystem    = $false
                        LockMode    = "Folder In Use ($cleanProcName PID: $($mp.ProcessId))"
                    })
                }
            }
        } catch {}

        if ($results.Count -eq 0) {
            # Check running dev/terminal processes whose title matches this folder
            $candidateProc = $null
            try {
                $devProcs = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^(node|remotion|ffmpeg|code|powershell|pwsh|cmd|wt|git)$' }
                foreach ($dp in $devProcs) {
                    if ($dp.MainWindowTitle -and ($dp.MainWindowTitle -like "*$($leafName)*")) {
                        $candidateProc = $dp
                        break
                    }
                }
            } catch {}

            if ($candidateProc) {
                $results.Add([PSCustomObject]@{
                    ProcessId   = $candidateProc.Id
                    ProcessName = "$($candidateProc.ProcessName)"
                    FilePath    = $resolved
                    FileName    = $leafName
                    IsSystem    = $false
                    LockMode    = "Folder In Use (Dev Process)"
                })
            } else {
                # File Explorer is treated as shell exception; identify as exclusive directory lock
                $results.Add([PSCustomObject]@{
                    ProcessId   = "-"
                    ProcessName = "Exclusive Directory Lock"
                    FilePath    = $resolved
                    FileName    = $leafName
                    IsSystem    = $false
                    LockMode    = "Folder In Use (Exclusive Handle)"
                })
            }
        }
    }

    return ,$results.ToArray()
}

function Restart-WindowsExplorer {
    [CmdletBinding()]
    param()
    try {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 1000
        $alive = Get-Process -Name explorer -ErrorAction SilentlyContinue
        if (-not $alive) {
            Start-Process explorer.exe
            Start-Sleep -Milliseconds 600
        }
        return $true
    } catch {
        return $false
    }
}

function Unlock-FileOrFolder {
    [CmdletBinding()]
    param(
        [string]$Path = ""
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or (-not (Test-Path -LiteralPath $Path))) {
        return $false
    }

    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue).Path
    if (-not $resolved) { $resolved = $Path }
    $leafName = Split-Path -Leaf $resolved

    # 1. Force-close all remote file and directory handles inside targetPath (DUPLICATE_CLOSE_SOURCE)
    try {
        [void]([HandleScanOOP]::CloseHandlesForPath($resolved))
    } catch {}

    # 2. Close any Explorer windows currently viewing the locked path or its parent
    try {
        $shell = New-Object -ComObject Shell.Application
        foreach ($w in $shell.Windows()) {
            if ($w.LocationURL -like "*$leafName*") {
                $w.Quit()
            }
        }
    } catch {}

    # 3. Check immediately if closing remote handles already unlocked the path!
    if (-not (Test-FileIsLocked -Path $resolved)) {
        return $true
    }

    # 4. If still locked, identify any remaining processes holding handles on the path and terminate non-critical ones
    try {
        $remainingHandles = [HandleScanOOP]::Scan(@($resolved))
        $protectedNames = @("explorer", "lsass", "services", "csrss", "system", "svchost", "wininit", "winlogon", "dwm", "antigravity", "code")
        foreach ($line in $remainingHandles) {
            $parts = $line -split '\|', 4
            if ($parts.Count -ge 2) {
                $hPid = [int]$parts[0]
                $hName = $parts[1].ToLowerInvariant()
                if ($hPid -gt 4 -and $hPid -ne $PID -and ($protectedNames -notcontains $hName)) {
                    Stop-Process -Id $hPid -Force -ErrorAction SilentlyContinue
                }
            }
        }
        [void]([HandleScanOOP]::CloseHandlesForPath($resolved))
    } catch {}

    # 5. Terminate any processes whose Current Working Directory is inside this folder
    try {
        $cwdProcs = [ProcessCwdReader]::FindProcessesInPath($resolved)
        foreach ($cp in $cwdProcs) {
            $sysNames = @("explorer", "lsass", "services", "csrss", "system", "svchost")
            if ($sysNames -notcontains $cp.ProcessName.ToLower() -and $cp.ProcessId -ne $PID) {
                Stop-Process -Id $cp.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
    } catch {}

    # 6. Terminate background processes whose commandline or executable path matches this specific folder
    try {
        $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
            ($_.CommandLine -like "*$leafName*" -or $_.CommandLine -like "*$resolved*" -or $_.ExecutablePath -like "*$resolved*") -and
            $_.ProcessId -ne $PID -and $_.Name -notmatch '^(explorer|svchost|csrss|lsass)\.exe$'
        }
        foreach ($p in $procs) {
            Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
        }
    } catch {}

    # 7. Strip any Read-Only / Hidden / System flags on the root target itself
    try {
        & cmd.exe /c "attrib -r -s -h `"$resolved`"" 2>$null
    } catch {}

    # 8. Exponential backoff verification (150ms, 350ms, 700ms)
    $retries = @(150, 350, 700)
    foreach ($waitMs in $retries) {
        if (-not (Test-FileIsLocked -Path $resolved)) { return $true }
        [void]([HandleScanOOP]::CloseHandlesForPath($resolved))
        Start-Sleep -Milliseconds $waitMs
    }

    return (-not (Test-FileIsLocked -Path $resolved))
}

Export-ModuleMember -Function Test-FileIsLocked, Get-FileLockingProcesses, Restart-WindowsExplorer, Unlock-FileOrFolder
