<#
.SYNOPSIS
    Headless Git submodule business logic engine.
#>
[CmdletBinding()]
param()

Import-Module "$PSScriptRoot\git-core.psm1" -Force

function Get-SubmoduleList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    $output = Invoke-GitCommand -RepoPath $RepoPath -Arguments @("submodule", "status")
    $results = @()

    if ($output) {
        $idx = 1
        foreach ($line in ($output -split "`r?`n")) {
            $trimmed = $line.Trim()
            if ($trimmed -match '^([\s\+\-U]?[0-9a-fA-F]+)\s+([^\s]+)(.*)$') {
                $results += [PSCustomObject]@{
                    Index  = $idx
                    Hash   = $matches[1].Trim()
                    Path   = $matches[2].Trim()
                    Branch = $matches[3].Trim()
                }
                $idx++
            }
        }
    }
    return $results
}

function Add-SubmoduleItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    Invoke-GitCommand -RepoPath $RepoPath -Arguments @("submodule", "add", $Url, $Destination)
    if ($LASTEXITCODE -eq 0) {
        Invoke-GitCommand -RepoPath $RepoPath -Arguments @("submodule", "update", "--init", "--recursive", $Destination)
        return $true
    }
    return $false
}

function Remove-SubmoduleItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$SubPath
    )

    Invoke-GitCommand -RepoPath $RepoPath -Arguments @("submodule", "deinit", "-f", "--", $SubPath)
    Invoke-GitCommand -RepoPath $RepoPath -Arguments @("rm", "-f", $SubPath)

    $cacheDir = Join-Path $RepoPath ".git\modules\$SubPath"
    if (Test-Path -LiteralPath $cacheDir) {
        Remove-Item -LiteralPath $cacheDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    return $true
}

function Sync-SubmoduleItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $false)]
        [string]$SubPath = ""
    )

    if ($SubPath) {
        Invoke-GitCommand -RepoPath $RepoPath -Arguments @("submodule", "update", "--init", "--recursive", "--", $SubPath)
    } else {
        Invoke-GitCommand -RepoPath $RepoPath -Arguments @("submodule", "update", "--init", "--recursive")
    }
    return ($LASTEXITCODE -eq 0)
}

Export-ModuleMember -Function Get-SubmoduleList, Add-SubmoduleItem, Remove-SubmoduleItem, Sync-SubmoduleItem
