# DryRunModule.psm1 - Modular Helper for PowerShell Dry-Run simulations
# Conforms to: all-lads-tool/skill/run-dry.md & Rule #001 (Zero-Hardcoding)

function Test-IsDryRun {
    param([switch]$DryRun)
    return [bool]$DryRun
}

function Show-DryRunBanner {
    param([string]$OperationName = "OPERATION")
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host " [SIMULATION / DRY-RUN MODE ACTIVE] : $OperationName" -ForegroundColor Yellow
    Write-Host " Zero mutations will be executed on the filesystem." -ForegroundColor DarkYellow
    Write-Host "==========================================================" -ForegroundColor Yellow
}

function Show-DryRunTable {
    param(
        [Parameter(Mandatory = $true)]
        [array]$PlanMatrix
    )
    if ($PlanMatrix.Count -eq 0) {
        Write-Host "No items to process in dry-run plan." -ForegroundColor Cyan
        return
    }
    
    $formatted = $PlanMatrix | ForEach-Object {
        [PSCustomObject]@{
            Index     = $_.Index
            Action    = $_.Action
            Source    = $_.Source
            Target    = $_.Target
            Status    = "[DRY-RUN / NO CHANGE]"
        }
    }
    
    $formatted | Format-Table -AutoSize | Out-String | Write-Host -ForegroundColor Cyan
}

function Invoke-DryRunAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)][string]$Target,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock,
        [switch]$DryRun
    )
    if ($DryRun) {
        Write-Host "[DRY-RUN WOULD $Action] -> $Target" -ForegroundColor DarkCyan
    } else {
        Write-Host "[EXECUTING $Action] -> $Target" -ForegroundColor Green
        & $ScriptBlock
    }
}

Export-ModuleMember -Function Test-IsDryRun, Show-DryRunBanner, Show-DryRunTable, Invoke-DryRunAction
