<#
.SYNOPSIS
    Git local identity reconfiguration module.
.DESCRIPTION
    Detects the account that owns a GitHub/GitLab remote and aligns the repo-local
    user.name / user.email with it. Local config only, no history rewrite.
#>
[CmdletBinding()]
param()

function Get-RemoteOwner {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [string]$Remote = "origin"
    )

    $url = (git -C $RepoPath remote get-url $Remote 2>$null)
    if ([string]::IsNullOrWhiteSpace($url)) { return $null }
    $url = $url.Trim()

    $provider = "Custom"
    if ($url -match 'github\.com') { $provider = "GitHub" }
    elseif ($url -match 'gitlab\.com') { $provider = "GitLab" }

    # https://host/owner/repo(.git) or git@host:owner/repo(.git)
    if ($url -match '[:/]([^/:]+)/([^/]+?)(?:\.git)?/?$') {
        return [PSCustomObject]@{
            Remote   = $Remote
            Url      = $url
            Provider = $provider
            Owner    = $matches[1]
            Repo     = $matches[2]
        }
    }
    return $null
}

function Get-GitIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [ValidateSet("local", "global", "effective")][string]$Scope = "effective"
    )

    $flag = switch ($Scope) {
        "local"  { "--local" }
        "global" { "--global" }
        default  { $null }
    }

    $nameArgs  = @("-C", $RepoPath, "config") + @($flag | Where-Object { $_ }) + @("user.name")
    $emailArgs = @("-C", $RepoPath, "config") + @($flag | Where-Object { $_ }) + @("user.email")

    $name  = (& git @nameArgs 2>$null)
    $email = (& git @emailArgs 2>$null)

    return [PSCustomObject]@{
        Name  = if ($name)  { $name.Trim() }  else { "" }
        Email = if ($email) { $email.Trim() } else { "" }
    }
}

function Resolve-TargetIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string]$Owner,
        [string]$Name = "",
        [string]$Email = ""
    )

    $global = Get-GitIdentity -RepoPath $RepoPath -Scope global

    # Reuse the global identity when it already belongs to the remote owner
    $globalMatchesOwner = ($global.Email -match [regex]::Escape($Owner)) -or ($global.Name -eq $Owner)

    $finalName = if ($Name) { $Name } else { $Owner }

    $finalEmail = if ($Email) { $Email }
                  elseif ($globalMatchesOwner -and $global.Email) { $global.Email }
                  else { "$Owner@users.noreply.github.com" }

    return [PSCustomObject]@{ Name = $finalName; Email = $finalEmail }
}

function Set-LocalGitIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RepoPath,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Email
    )

    git -C $RepoPath config --local user.name $Name
    if ($LASTEXITCODE -ne 0) { throw "Failed to set local user.name." }
    git -C $RepoPath config --local user.email $Email
    if ($LASTEXITCODE -ne 0) { throw "Failed to set local user.email." }
    return $true
}

Export-ModuleMember -Function Get-RemoteOwner, Get-GitIdentity, Resolve-TargetIdentity, Set-LocalGitIdentity
