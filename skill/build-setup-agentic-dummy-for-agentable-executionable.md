---
name: build-setup-agentic-dummy-for-agentable-executionable
aliases: [agentic-dummy-build, agent-safe-build-pipeline, dual-build-architecture]
category: BUILD_ARCHITECTURE
tags: [build, pipeline, agentic, dummy-data, junction, security, powershell]
description: Protocol for bifurcated build pipelines separating zero-credential, agent-executable dummy builds from human-restricted production builds, enforcing zero hardcoded variables, cross-drive NTFS junctions, and git-ignored build state.
pros:
  - "Guarantees safe automated execution by AI agents and CI without data leak risks"
  - "Protects production credentials and proprietary data behind human confirmation gates"
  - "Eliminates duplicate storage using high-performance cross-drive NTFS junctions"
cons:
  - "Requires maintaining synchronized dummy fixtures alongside production schemas"
  - "Demands strict adherence to safe junction detachment protocols"
---

# Build Setup Protocol: Agentic Dummy Execution vs Human-Guarded Production (`build-setup-agentic-dummy-for-agentable-executionable`)

## 1. Architectural Mandate: The Bifurcated Build Paradigm

In modern development workflows involving autonomous AI agents, CI/CD pipelines, and multi-drive storage, monolithic build scripts introduce critical security and operational failures:
1. An autonomous agent instructed to run a build may inadvertently expose proprietary athlete data, customer PII, or internal credentials.
2. A build script with blocking interactive prompts will hang indefinitely in headless agentic or CI environments.
3. Storing multi-gigabyte production media or vaults directly inside the web repository leads to bloated git histories and redundant disk consumption.

To solve these failure modes, all application workspaces must bifurcate their build infrastructure into two distinct scripts:

```
[Application Workspace Root]
  |
  +-- build-with-dummy.ps1   --> AGENT-RUNNABLE (Zero credentials, safe defaults, non-blocking)
  |
  +-- build.ps1              --> HUMAN-GUARDED  (Interactive history, cross-drive junction, production-ready)
  |
  +-- build.json             --> GIT-IGNORED    (Local runtime state and active mount metadata)
```

---

## 2. Invariant Specifications

### Invariant 1: Agent-Executable Dummy Build (`build-with-dummy.ps1`)
- **Default-Enter Execution**: If executed without parameters, pressing `<Enter>` immediately selects the standard dummy dataset (`data-dummy/`) and proceeds.
- **Agentic / Non-Interactive Mode**: Supports flags (`-NonInteractive`, `-Yes`, `-DummySet <name>`) that bypass all terminal prompts, allowing autonomous agents to build, bundle, and verify without human intervention.
- **Air-Gapped & IP-Safe**: Uses strictly sanitized mock data committed directly to the repository. Contains zero real athlete names, zero trademarks, zero secrets, and zero production database URLs.
- **Build Output Attribution**: Compiles artifacts with an embedded metadata banner indicating `mode: "dummy"` to prevent mock builds from ever being deployed to live production servers.

### Invariant 2: Human-Guarded Production Build (`build.ps1`)
- **Agent-Execution Barrier**: Cannot be run blindly by autonomous agents without human presence. It requires explicit interactive selection or a dedicated environment confirmation token.
- **Indexed History Selection**: Implements the `interactive-asking-cli` protocol (`0 = latest option`, `1 = latest - 1`, `2 = latest - 2`, `[C] Custom Path`).
- **Cross-Drive NTFS Directory Junctions**: Connects to live external datasets and vaults residing on different drive letters (e.g. `D:\`, `E:\`, `F:\`) via NTFS directory junctions (`New-Item -ItemType Junction`), avoiding file duplication.
- **Clean Build State**: Never commits production data into the web app repository.

### Invariant 3: Zero Hardcoded Variables (Rule #001 Compliance)
- **Zero Drive Letters in Source**: Never embed `C:\`, `D:\`, or `E:\` inside JavaScript, HTML, CSS, or script defaults.
- **Dynamic Path Resolution**: Paths must be discovered through interactive selection, CLI parameter flags (`-DataSource <path>`), or external configuration files (`config.yaml`).

### Invariant 4: Mandatory `.gitignore` Exclusion
- The local build metadata file `build.json` stores machine-specific state (last selected drive path, junction target, timestamp).
- `build.json` MUST be declared in `.gitignore` to prevent machine-specific paths or internal folder structures from leaking into version control.

---

## 3. Cross-Drive NTFS Directory Junction Architecture

### The Cross-Drive Capability
Unlike hard links, NTFS Directory Junctions (reparse points) natively support linking across different local drive volumes on Windows:

```
Drive E: [web-app_sport-club\src\data\active]  ===(Junction)===>  Drive D: [0pro\vault_sport-data]
```

Junctions require no administrative or elevated rights, enabling frictionless local development.

### Safe Junction Lifecycle Management
> [!CAUTION]
> **PREVENTING RECURSIVE SOURCE DELETION**:
> Standard PowerShell commands like `Remove-Item -Recurse $JunctionPath` can traverse the junction and permanently delete the original files on the source drive.
> Scripts must strictly inspect `LinkType` and delete the reparse point directly without recursion:

```powershell
function Remove-SafeJunction {
    param([Parameter(Mandatory=$true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.LinkType -eq "Junction" -or $item.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint)) {
            Write-Verbose "Safely removing junction reparse point: $Path"
            $item.Delete()
        } else {
            # Regular directory: safely move to trash or clean contents
            Write-Verbose "Directory is not a junction. Standard handling applies."
        }
    }
}
```

---

## 4. Standard Implementation Blueprints

### Pattern A: `build-with-dummy.ps1` (Agentic & Headless)

```powershell
[CmdletBinding()]
param (
    [string]$DummyDataset = "default",
    [switch]$NonInteractive = $false,
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$DataTarget = Join-Path $ProjectRoot "src\data\active"
$DummySource = Join-Path $ProjectRoot "data-dummy\$DummyDataset"

Write-Host "================================================="
Write-Host " AGENTIC DUMMY BUILD (AGENT-SAFE & HEADLESS)"
Write-Host "================================================="

if ($Clean) {
    Remove-SafeJunction -Path $DataTarget
    Write-Host "Build data unmounted. Exiting."
    exit 0
}

# Prompt only if interactive, with default Enter = 0 / Default
if (-not $NonInteractive) {
    Write-Host "Available Dummy Datasets:"
    Write-Host " [0] default (Standard IP-Safe Mock Athletes) [Default - Press Enter]"
    Write-Host " [1] minimal (Barebones Smoke Test Dataset)"
    
    $choice = Read-Host "Select dataset [0-1] (Default: 0)"
    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq "0") {
        $DummyDataset = "default"
    } elseif ($choice -eq "1") {
        $DummyDataset = "minimal"
    }
    $DummySource = Join-Path $ProjectRoot "data-dummy\$DummyDataset"
}

if (-not (Test-Path -LiteralPath $DummySource)) {
    throw "Dummy dataset directory not found: $DummySource"
}

# Mount dummy dataset
Remove-SafeJunction -Path $DataTarget
New-Item -ItemType Junction -Path $DataTarget -Target $DummySource | Out-Null
Write-Host "Mounted dummy data from: $DummySource"

# Execute pre-build validation and packaging
Write-Host "Running syntax validation and frontend build..."
# Invoke validator and bundler here
Write-Host "Dummy build completed successfully."
```

### Pattern B: `build.ps1` (Human-Guarded Production)

```powershell
[CmdletBinding()]
param (
    [string]$DataSource = "",
    [switch]$NonInteractive = $false
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot
$BuildStateFile = Join-Path $ProjectRoot "build.json"
$DataTarget = Join-Path $ProjectRoot "src\data\active"

Write-Host "================================================="
Write-Host " PRODUCTION BUILD (HUMAN-GUARDED & CROSS-DRIVE)"
Write-Host "================================================="

# Guard against blind agent execution
if ($NonInteractive -and [string]::IsNullOrWhiteSpace($DataSource)) {
    Write-Error "Production build cannot be executed headlessly without an explicit -DataSource parameter."
    exit 1
}

# Load selection history from git-ignored build.json
$history = @()
if (Test-Path -LiteralPath $BuildStateFile) {
    try {
        $state = Get-Content -LiteralPath $BuildStateFile -Raw | ConvertFrom-Json
        $history = $state.history
    } catch {
        $history = @()
    }
}

if ([string]::IsNullOrWhiteSpace($DataSource)) {
    Write-Host "Select Data Source:"
    if ($history.Count -gt 0) {
        Write-Host " [0] $($history[0]) [Latest - Press Enter]"
        for ($i = 1; $i -lt $history.Count; $i++) {
            Write-Host " [$i] $($history[$i]) [Latest - $i]"
        }
    }
    Write-Host " [C] Enter Custom Cross-Drive Path"
    Write-Host " [Q] Abort"

    $inputChoice = Read-Host "Select option (Default: 0)"
    if ([string]::IsNullOrWhiteSpace($inputChoice) -or $inputChoice -eq "0") {
        if ($history.Count -eq 0) {
            $DataSource = Read-Host "No history found. Enter source path"
        } else {
            $DataSource = $history[0]
        }
    } elseif ($inputChoice -match '^\d+$' -and [int]$inputChoice -lt $history.Count) {
        $DataSource = $history[[int]$inputChoice]
    } elseif ($inputChoice -eq "C" -or $inputChoice -eq "c") {
        $DataSource = Read-Host "Enter absolute or relative source path"
    } else {
        Write-Host "Build cancelled."
        exit 0
    }
}

# Resolve and validate target path
$ResolvedSource = (Resolve-Path -LiteralPath $DataSource).Path
if (-not (Test-Path -LiteralPath $ResolvedSource)) {
    throw "Target data path does not exist: $ResolvedSource"
}

# Update history in build.json
$newHistory = @($ResolvedSource) + ($history | Where-Object { $_ -ne $ResolvedSource })
if ($newHistory.Count -gt 5) { $newHistory = $newHistory[0..4] }

$stateObj = @{
    lastBuildMode = "production"
    lastUpdated   = (Get-Date).ToString("o")
    activeSource  = $ResolvedSource
    history       = $newHistory
}
$stateObj | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $BuildStateFile -Force

# Mount cross-drive junction
Remove-SafeJunction -Path $DataTarget
New-Item -ItemType Junction -Path $DataTarget -Target $ResolvedSource | Out-Null
Write-Host "Mounted production junction: $DataTarget -> $ResolvedSource"

# Run production build and audit
Write-Host "Compiling production bundle..."
# Execute production packaging here
Write-Host "Production build verified and complete."
```

---

## 5. Verification Checklist

1. **Agent Test**: Can an automated agent run `.\build-with-dummy.ps1 -NonInteractive` without human interaction or script failure?
2. **Safety Test**: Does `Remove-SafeJunction` safely unmount directory junctions across drive letters without modifying files on the target drive?
3. **Leak Prevention**: Is `build.json` present in `.gitignore`?
4. **Zero-Hardcoding Check**: Are all drive letters (`D:`, `E:`) passed via arguments, resolved via history, or prompted dynamically?
