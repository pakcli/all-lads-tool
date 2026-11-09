<#
.SYNOPSIS
    Universal _run.json State Bridge Adapter (Context: common)
.DESCRIPTION
    Conforms strictly to Brief v01-04-00 and Brief v01-04-01.
    Provides cross-tool state persistence and target directory inheritance.
#>

function Get-RunJsonPath {
    [CmdletBinding()]
    param (
        [string]$StartingDir = $PSScriptRoot
    )

    $current = $StartingDir
    while ($current -and (Test-Path -LiteralPath $current)) {
        $candidate = Join-Path $current "_run.json"
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
        $gitDir = Join-Path $current ".git"
        if (Test-Path -LiteralPath $gitDir) {
            return $candidate
        }
        $parent = Split-Path -Path $current -Parent
        if ($parent -eq $current) { break }
        $current = $parent
    }

    # Fallback to 2 levels up from adapter dir
    $fallbackRoot = Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -Parent) -Parent
    if (-not [string]::IsNullOrWhiteSpace($fallbackRoot)) {
        return (Join-Path $fallbackRoot "_run.json")
    }

    return (Join-Path (Get-Location).Path "_run.json")
}

function Get-RunJsonState {
    [CmdletBinding()]
    param (
        [string]$Path = (Get-RunJsonPath)
    )

    if (Test-Path -LiteralPath $Path) {
        try {
            $raw = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
            $obj = $raw | ConvertFrom-Json
            if ($obj) { return $obj }
        } catch {}
    }

    # Return default empty state
    return [PSCustomObject]@{
        targetDir         = (Get-Location).Path
        lastIngestionType = "default-workspace"
        lastWebUrl        = ""
        detectedContext   = "repo"
        lastUpdated       = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
}

function Set-RunJsonState {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$State,

        [string]$Path = (Get-RunJsonPath)
    )

    try {
        $dict = [ordered]@{}
        foreach ($prop in $State.PSObject.Properties) {
            $dict[$prop.Name] = $prop.Value
        }
        $dict["lastUpdated"] = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        $jsonStr = $dict | ConvertTo-Json -Depth 5
        $dir = Split-Path -Path $Path -Parent
        if (-not (Test-Path -LiteralPath $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
        [System.IO.File]::WriteAllText($Path, $jsonStr, [System.Text.Encoding]::UTF8)
        return $true
    } catch {
        return $false
    }
}

function Get-TargetDirectory {
    [CmdletBinding()]
    param (
        [string]$Fallback = (Get-Location).Path
    )

    $state = Get-RunJsonState
    if ($state -and -not [string]::IsNullOrWhiteSpace($state.targetDir)) {
        if (Test-Path -LiteralPath $state.targetDir) {
            return $state.targetDir
        }
    }
    return $Fallback
}

function Set-TargetDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetDir,

        [string]$IngestionType = "manual-cli",
        [string]$DetectedContext = "repo"
    )

    $state = Get-RunJsonState
    $state.targetDir = $TargetDir
    $state.lastIngestionType = $IngestionType
    $state.detectedContext = $DetectedContext
    return (Set-RunJsonState -State $state)
}

Export-ModuleMember -Function @(
    "Get-RunJsonPath",
    "Get-RunJsonState",
    "Set-RunJsonState",
    "Get-TargetDirectory",
    "Set-TargetDirectory"
)
