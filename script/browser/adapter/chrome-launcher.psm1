<#
.SYNOPSIS
    Browser Remote Debugger Launcher Adapter (Context: browser)
.DESCRIPTION
    Launches Chromium-based browsers (Chrome, Edge, Brave, or Custom)
    with dedicated isolated user-data-dir and remote debugging port (default: 9222)
    for Antigravity and AI agent automation.
#>

function Find-BrowserExecutable {
    [CmdletBinding()]
    param (
        [string]$BrowserType = "Chrome",
        [string]$CustomPath
    )

    if (-not [string]::IsNullOrWhiteSpace($CustomPath) -and (Test-Path -LiteralPath $CustomPath)) {
        return (Resolve-Path -LiteralPath $CustomPath).Path
    }

    $type = $BrowserType.Trim().ToLowerInvariant()
    $candidates = @()

    switch ($type) {
        "edge" {
            $candidates = @(
                "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
                "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
                "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
            )
        }
        "brave" {
            $candidates = @(
                "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
                "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe",
                "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe"
            )
        }
        default {
            # Chrome default
            $candidates = @(
                "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
                "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
                "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
            )
        }
    }

    foreach ($path in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)) {
            return $path
        }
    }

    # Search PATH as fallback
    $exeName = switch ($type) { "edge" { "msedge.exe" } "brave" { "brave.exe" } default { "chrome.exe" } }
    try {
        $cmd = Get-Command $exeName -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source) { return $cmd.Source }
    } catch {}

    return $null
}

function Find-ChromeExecutable {
    [CmdletBinding()]
    param ()
    return (Find-BrowserExecutable -BrowserType "Chrome")
}

function Get-ProfileDataDir {
    [CmdletBinding()]
    param (
        [string]$ProfileName = "ai-agent",
        [string]$BrowserType = "Chrome"
    )

    $cleanProfile = $ProfileName -replace '[^a-zA-Z0-9_\-]', '_'
    $type = $BrowserType.Trim().ToLowerInvariant()

    $baseDir = switch ($type) {
        "edge"  { Join-Path $env:LOCALAPPDATA "Microsoft\Edge" }
        "brave" { Join-Path $env:LOCALAPPDATA "BraveSoftware\Brave-Browser" }
        default { Join-Path $env:LOCALAPPDATA "Google\Chrome" }
    }

    return (Join-Path $baseDir "User Data - $cleanProfile")
}

function Test-ProfileExists {
    [CmdletBinding()]
    param (
        [string]$ProfileName = "ai-agent",
        [string]$BrowserType = "Chrome"
    )

    $dir = Get-ProfileDataDir -ProfileName $ProfileName -BrowserType $BrowserType
    return (Test-Path -LiteralPath $dir)
}

function Test-DebuggingPort {
    [CmdletBinding()]
    param (
        [int]$Port = 9222
    )

    try {
        $conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        return ($null -ne $conn)
    } catch {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $tcp.BeginConnect("127.0.0.1", $Port, $null, $null)
            $wait = $asyncResult.AsyncWaitHandle.WaitOne(300, $false)
            if ($wait -and $tcp.Connected) {
                $tcp.EndConnect($asyncResult)
                $tcp.Close()
                return $true
            }
            $tcp.Close()
        } catch {}
    }
    return $false
}

function Stop-PortProcess {
    [CmdletBinding()]
    param (
        [int]$Port = 9222
    )

    try {
        $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            if ($conn.OwningProcess -gt 0) {
                Stop-Process -Id $conn.OwningProcess -Force -ErrorAction SilentlyContinue
            }
        }
        return $true
    } catch {
        return $false
    }
}

function Start-BrowserRemoteDebugger {
    [CmdletBinding()]
    param (
        [string]$BrowserPath,
        [string]$BrowserType = "Chrome",
        [string]$ProfileName = "ai-agent",
        [int]$Port = 9222,
        [string]$Url = "about:blank",
        [switch]$Headless,
        [switch]$ForceRestart
    )

    if (-not $BrowserPath -or -not (Test-Path -LiteralPath $BrowserPath)) {
        throw "Browser executable not found: $BrowserPath"
    }

    $userDataDir = Get-ProfileDataDir -ProfileName $ProfileName -BrowserType $BrowserType

    # Check if port is already active
    $isListening = Test-DebuggingPort -Port $Port
    if ($isListening) {
        if ($ForceRestart) {
            Stop-PortProcess -Port $Port
            Start-Sleep -Milliseconds 500
        } else {
            return [PSCustomObject]@{
                Status      = "AlreadyRunning"
                Port        = $Port
                BrowserType = $BrowserType
                ProfileName = $ProfileName
                UserDataDir = $userDataDir
                BrowserPath = $BrowserPath
            }
        }
    }

    # Ensure user data dir exists
    if (-not (Test-Path -LiteralPath $userDataDir)) {
        New-Item -Path $userDataDir -ItemType Directory -Force | Out-Null
    }

    # Build arguments array
    $argList = @(
        "--remote-debugging-port=$Port",
        "--user-data-dir=`"$userDataDir`"",
        "--profile-directory=`"$ProfileName`"",
        "--no-first-run",
        "--no-default-browser-check"
    )

    if ($Headless) {
        $argList += "--headless=new"
    }

    if (-not [string]::IsNullOrWhiteSpace($Url) -and $Url -ne "about:blank") {
        $argList += "`"$Url`""
    }

    $argString = $argList -join " "

    # Launch detached process
    $proc = Start-Process -FilePath $BrowserPath -ArgumentList $argString -PassThru

    # Wait up to 5 seconds for port activation
    $ready = $false
    for ($i = 0; $i -lt 10; $i++) {
        Start-Sleep -Milliseconds 500
        if (Test-DebuggingPort -Port $Port) {
            $ready = $true
            break
        }
    }

    return [PSCustomObject]@{
        Status      = if ($ready) { "Running" } else { "LaunchedUnverified" }
        ProcessId   = $proc.Id
        Port        = $Port
        BrowserType = $BrowserType
        ProfileName = $ProfileName
        UserDataDir = $userDataDir
        BrowserPath = $BrowserPath
    }
}

function Start-ChromeRemoteDebugger {
    [CmdletBinding()]
    param (
        [string]$ChromePath,
        [string]$ProfileName = "ai-agent",
        [int]$Port = 9222,
        [string]$Url = "about:blank",
        [switch]$Headless,
        [switch]$ForceRestart
    )

    return (Start-BrowserRemoteDebugger `
        -BrowserPath $ChromePath `
        -BrowserType "Chrome" `
        -ProfileName $ProfileName `
        -Port $Port `
        -Url $Url `
        -Headless:$Headless `
        -ForceRestart:$ForceRestart)
}

Export-ModuleMember -Function @(
    "Find-BrowserExecutable",
    "Find-ChromeExecutable",
    "Get-ProfileDataDir",
    "Test-ProfileExists",
    "Test-DebuggingPort",
    "Stop-PortProcess",
    "Start-BrowserRemoteDebugger",
    "Start-ChromeRemoteDebugger"
)
