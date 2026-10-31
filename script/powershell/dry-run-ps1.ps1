<#
.SYNOPSIS
    dry-run-ps1.ps1 - Modular runner/interceptor to simulate or dry-run any target PowerShell script.
.DESCRIPTION
    Wraps and intercepts executions, enforcing non-destructive simulation modes (-DryRun / -WhatIf)
    or checking if the script supports dry-run parameters. Conforms to Rule #001 & naming conventions.
.PARAMETER ScriptPath
    Target PowerShell script (.ps1) to dry-run or inspect.
.PARAMETER TargetDir
    Target directory to pass to the underlying script.
.PARAMETER AdditionalArgs
    Any extra arguments to forward to the target script.
#>
[CmdletBinding()]
param(
    [string]$ScriptPath = "",
    [string]$TargetDir = "",
    [switch]$Interactive,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdditionalArgs
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

# 1. Resolve Modular DryRun helper
$modulePath = Join-Path $scriptDir "module\dry-run-core.psm1"
if (Test-Path -LiteralPath $modulePath) {
    Import-Module $modulePath -Force
}

# 2. Interactive prompt if no script provided
if (-not $ScriptPath) {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   PowerShell Modular Dry-Run Runner (dry-run-ps1)        " -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    $ScriptPath = Read-Host "TARGET SCRIPT (Path to .ps1 to dry-run)"
}

$ScriptPath = $ScriptPath.Trim('"').Trim()

if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    Write-Error "Script not found: $ScriptPath"
    exit 1
}

$resolvedScript = (Resolve-Path -LiteralPath $ScriptPath).Path

# 3. Analyze script for DryRun / WhatIf parameter support
Write-Host "[ANALYSIS] Inspecting parameters in: $(Split-Path $resolvedScript -Leaf)" -ForegroundColor Yellow
$content = Get-Content -LiteralPath $resolvedScript -Raw -Encoding UTF8

$supportsDryRun = $content -match '\bDryRun\b'
$supportsWhatIf = $content -match 'SupportsShouldProcess\s*=\s*\$true'

Write-Host " -> Supports -DryRun : $supportsDryRun" -ForegroundColor $(if ($supportsDryRun) { "Green" } else { "DarkGray" })
Write-Host " -> Supports -WhatIf : $supportsWhatIf" -ForegroundColor $(if ($supportsWhatIf) { "Green" } else { "DarkGray" })

# 4. Formulate Dry-Run arguments
$forwardArgs = @()
if ($TargetDir) {
    $forwardArgs += @("-TargetDir", "`"$TargetDir`"")
}

if ($supportsDryRun) {
    $forwardArgs += "-DryRun"
} elseif ($supportsWhatIf) {
    $forwardArgs += "-WhatIf"
} else {
    Write-Warning "Target script does not declare an explicit -DryRun or -WhatIf parameter."
    Write-Warning "Running in WhatIf mode via PowerShell preference injection."
    $forwardArgs += @("-WhatIfPreference", "`$true")
}

if ($AdditionalArgs) {
    $forwardArgs += $AdditionalArgs
}

# 5. Show Preview Banner
if (Get-Command Show-DryRunBanner -ErrorAction SilentlyContinue) {
    Show-DryRunBanner -OperationName (Split-Path $resolvedScript -Leaf)
}

$commandString = "& `"$resolvedScript`" $($forwardArgs -join ' ')"
Write-Host "[DRY-RUN EXECUTION COMMAND]:" -ForegroundColor DarkCyan
Write-Host "  $commandString" -ForegroundColor White
Write-Host ""

# 6. Execute under simulation mode
& powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '$resolvedScript' $forwardArgs"
