<#
.SYNOPSIS
    Universal Runtime & Version Resolver Adapter (Context: common)
.DESCRIPTION
    Conforms strictly to Brief v01-04-00.
    Detects runtime versions for Git, PowerShell, and Node.js.
    Provides prerequisite auditing across cross-context tools.
#>

function Get-GitVersion {
    [CmdletBinding()]
    param ()

    try {
        $out = & git --version 2>$null
        if ($out -match "git version (\d+\.\d+\.\d+)") {
            return [version]$Matches[1]
        }
    } catch {}
    return $null
}

function Get-PowerShellVersion {
    [CmdletBinding()]
    param ()

    return $PSVersionTable.PSVersion
}

function Get-NodeVersion {
    [CmdletBinding()]
    param ()

    try {
        $out = & node --version 2>$null
        if ($out -match "v?(\d+\.\d+\.\d+)") {
            return [version]$Matches[1]
        }
    } catch {}
    return $null
}

function Test-ToolPrerequisites {
    [CmdletBinding()]
    param (
        [string[]]$RequiredTools = @("git", "powershell")
    )

    $results = [ordered]@{}

    foreach ($tool in $RequiredTools) {
        switch ($tool.ToLowerInvariant()) {
            "git" {
                $ver = Get-GitVersion
                $results["git"] = [PSCustomObject]@{
                    Available = ($null -ne $ver)
                    Version   = if ($ver) { $ver.ToString() } else { "Not Found" }
                    Status    = if ($ver) { "OK" } else { "Missing" }
                }
            }
            "powershell" {
                $ver = Get-PowerShellVersion
                $results["powershell"] = [PSCustomObject]@{
                    Available = ($null -ne $ver)
                    Version   = if ($ver) { $ver.ToString() } else { "Unknown" }
                    Status    = if ($ver -and $ver.Major -ge 5) { "OK" } else { "Outdated" }
                }
            }
            "node" {
                $ver = Get-NodeVersion
                $results["node"] = [PSCustomObject]@{
                    Available = ($null -ne $ver)
                    Version   = if ($ver) { $ver.ToString() } else { "Not Found" }
                    Status    = if ($ver) { "OK" } else { "Missing" }
                }
            }
        }
    }

    return [PSCustomObject]$results
}

Export-ModuleMember -Function @(
    "Get-GitVersion",
    "Get-PowerShellVersion",
    "Get-NodeVersion",
    "Test-ToolPrerequisites"
)
