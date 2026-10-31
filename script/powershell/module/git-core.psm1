<#
.SYNOPSIS
    Low-level Git CLI process execution wrapper.
#>
[CmdletBinding()]
param()

function Invoke-GitCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "git"
    $allArgs = @("-C", "`"$RepoPath`"") + $Arguments
    $psi.Arguments = $allArgs -join " "
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    $global:LASTEXITCODE = $proc.ExitCode
    if ($proc.ExitCode -ne 0 -and [string]::IsNullOrWhiteSpace($stdout)) {
        return $stderr.Trim()
    }
    return $stdout.Trim()
}

Export-ModuleMember -Function Invoke-GitCommand
