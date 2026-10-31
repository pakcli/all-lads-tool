<#
.SYNOPSIS
    Infinite counter JSON history engine.
#>
[CmdletBinding()]
param()

function Get-ToolHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonPath
    )

    if (Test-Path -LiteralPath $JsonPath) {
        try {
            return Get-Content -LiteralPath $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

function Add-ToolHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonPath,

        [Parameter(Mandatory = $true)]
        [string]$ToolName,

        [Parameter(Mandatory = $true)]
        [string]$TargetDir,

        [Parameter(Mandatory = $true)]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [hashtable]$Details = @{}
    )

    $store = Get-ToolHistory -JsonPath $JsonPath
    if (-not $store) {
        $store = [PSCustomObject]@{
            tool         = $ToolName
            last_counter = 0
            last_target  = $TargetDir
            history      = @()
        }
    }

    $nextId = [int]$store.last_counter + 1
    $store.last_counter = $nextId
    $store.last_target  = $TargetDir

    $entry = [PSCustomObject]@{
        id        = $nextId
        timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        target    = $TargetDir
        action    = $Action
        details   = $Details
    }

    $entries = @($store.history)
    $entries += $entry
    $store.history = $entries

    $store | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $JsonPath -Encoding UTF8
    return $entry
}

Export-ModuleMember -Function Get-ToolHistory, Add-ToolHistory
