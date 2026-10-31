<#
.SYNOPSIS
    Vintage Computing Arcade - Git Submodule Manager
.DESCRIPTION
    Zero-hardcoded-path utility for managing Git submodules inside the repository.
    Supports Adding, Updating, Syncing, Listing, and Removing submodules.
    Can be run interactively or via CLI parameters.
.PARAMETER Action
    Action to perform: 'add', 'update', 'sync', 'status', 'list', 'remove', 'interactive'
.PARAMETER Url
    Remote repository URL to clone as submodule (e.g. https://github.com/org/repo.git)
.PARAMETER Path
    Target path relative to repo root (e.g. submodules/my-tool, vendor/theme)
.PARAMETER Branch
    Optional branch to track (e.g. main, master)
.PARAMETER Force
    Force operation if destination exists or when removing
#>

[CmdletBinding()]
param (
    [ValidateSet("add", "update", "sync", "status", "list", "remove", "interactive", "")]
    [string]$Action = "",

    [string]$Url = "",
    [string]$Path = "",
    [string]$Branch = "",
    [switch]$Force,
    [switch]$Help
)

# Dynamically resolve repository root (Rule #3: ZERO Hardcoded Variables)
$scriptDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path
if ($Path -and (Test-Path -LiteralPath $Path) -and (Test-Path -LiteralPath "$Path\.git")) {
    $repoRoot = (Resolve-Path -LiteralPath $Path).Path
}

function Write-Header {
    param ([string]$title)
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Test-GitInstalled {
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-Host "[ERROR] 'git' command not found in PATH." -ForegroundColor Red
        return $false
    }
    return $true
}

function Show-SubmoduleStatus {
    Write-Header "GIT SUBMODULE STATUS"
    Push-Location $repoRoot
    try {
        $gitmodulesFile = Join-Path $repoRoot ".gitmodules"
        if (-not (Test-Path $gitmodulesFile)) {
            Write-Host "[INFO] No .gitmodules file found in repository root." -ForegroundColor DarkGray
            Write-Host "       (There are currently no registered submodules)" -ForegroundColor DarkGray
            return
        }

        Write-Host "[FILE] .gitmodules Configuration:" -ForegroundColor Green
        Get-Content $gitmodulesFile | ForEach-Object { Write-Host "   $_" -ForegroundColor Gray }
        Write-Host ""
        Write-Host "[STATUS] Submodule Working Tree Status:" -ForegroundColor Green
        & git submodule status --recursive
    }
    catch {
        Write-Host "[ERROR] Could not check status: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function Add-Submodule {
    param (
        [string]$subUrl,
        [string]$subPath,
        [string]$subBranch,
        [switch]$forceAdd
    )

    if (-not $subUrl) {
        $subUrl = Read-Host "Enter Git Repository URL (e.g. https://github.com/user/repo.git)"
    }

    if (-not $subUrl) {
        Write-Host "[ERROR] Repository URL cannot be empty." -ForegroundColor Red
        return
    }

    if (-not $subPath) {
        $derivedName = ($subUrl.TrimEnd('/') -split '/')[-1] -replace '\.git$', ''
        $defaultPath = "submodules/$derivedName"
        $inputPath = Read-Host "Enter target path relative to repo root [default: $defaultPath]"
        $subPath = if ([string]::IsNullOrWhiteSpace($inputPath)) { $defaultPath } else { $inputPath }
    }

    $cleanRelPath = ($subPath.TrimStart('\/').Replace('\', '/'))

    if (-not $subBranch) {
        $inputBranch = Read-Host "Enter branch to track (press Enter for default remote HEAD)"
        if (-not [string]::IsNullOrWhiteSpace($inputBranch)) {
            $subBranch = $inputBranch.Trim()
        }
    }

    Write-Header "ADDING SUBMODULE: $cleanRelPath"
    Write-Host "Target Path : $cleanRelPath" -ForegroundColor Cyan
    Write-Host "Remote URL  : $subUrl" -ForegroundColor Cyan
    if ($subBranch) {
        Write-Host "Branch      : $subBranch" -ForegroundColor Cyan
    }

    Push-Location $repoRoot
    try {
        $gitArgs = @("submodule", "add")
        if ($forceAdd) {
            $gitArgs += "--force"
        }
        if ($subBranch) {
            $gitArgs += @("-b", $subBranch)
        }
        $gitArgs += @($subUrl, $cleanRelPath)

        Write-Host "`n> git $($gitArgs -join ' ')" -ForegroundColor Yellow
        & git @gitArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Initializing and updating submodule contents..." -ForegroundColor Green
            & git submodule update --init --recursive $cleanRelPath
            Write-Host "[OK] Submodule '$cleanRelPath' successfully added and initialized!" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Failed to add submodule (Exit Code: $LASTEXITCODE)." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[ERROR] Exception occurred: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function Update-Submodules {
    param ([string]$targetPath)
    Write-Header "UPDATING SUBMODULES"
    Push-Location $repoRoot
    try {
        $updateArgs = @("submodule", "update", "--init", "--recursive", "--remote")
        if ($targetPath) {
            $cleanRelPath = ($targetPath.TrimStart('\/').Replace('\', '/'))
            $updateArgs += $cleanRelPath
            Write-Host "[INFO] Updating specific submodule: $cleanRelPath..." -ForegroundColor Cyan
        } else {
            Write-Host "[INFO] Updating all submodules recursively to latest remote commits..." -ForegroundColor Cyan
        }

        Write-Host "> git $($updateArgs -join ' ')" -ForegroundColor Yellow
        & git @updateArgs

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Submodule(s) updated successfully!" -ForegroundColor Green
        } else {
            Write-Host "[ERROR] Submodule update encountered errors (Exit Code: $LASTEXITCODE)." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "[ERROR] Exception occurred: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function Sync-Submodules {
    Write-Header "SYNCING SUBMODULE URLS"
    Push-Location $repoRoot
    try {
        Write-Host "[INFO] Running git submodule sync --recursive..." -ForegroundColor Cyan
        & git submodule sync --recursive
        & git submodule update --init --recursive
        Write-Host "[OK] Submodule sync completed." -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Exception occurred: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function Remove-Submodule {
    param (
        [string]$subPath,
        [switch]$forceRemove
    )

    if (-not $subPath) {
        $subPath = Read-Host "Enter relative path of submodule to remove (e.g. submodules/my-tool)"
    }

    if (-not $subPath) {
        Write-Host "[ERROR] Submodule path cannot be empty." -ForegroundColor Red
        return
    }

    $cleanRelPath = ($subPath.TrimStart('\/').Replace('\', '/'))
    Write-Header "REMOVING SUBMODULE: $cleanRelPath"

    $confirm = $forceRemove
    if (-not $confirm) {
        $response = Read-Host "[WARN] Are you sure you want to deinitialize and remove '$cleanRelPath'? (y/N)"
        if ($response -notmatch '^[Yy]$') {
            Write-Host "Aborted by user." -ForegroundColor Yellow
            return
        }
    }

    Push-Location $repoRoot
    try {
        Write-Host "[1/3] Deinitializing submodule '$cleanRelPath'..." -ForegroundColor Cyan
        & git submodule deinit -f -- $cleanRelPath

        Write-Host "[2/3] Removing submodule directory from git index..." -ForegroundColor Cyan
        & git rm -f $cleanRelPath

        # Cleanup internal git modules cache folder if present
        $gitModulesDir = Join-Path $repoRoot ".git/modules/$cleanRelPath"
        if (Test-Path $gitModulesDir) {
            Write-Host "[3/3] Cleaning internal git modules cache..." -ForegroundColor DarkGray
            Remove-Item -Path $gitModulesDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "[OK] Submodule '$cleanRelPath' successfully removed!" -ForegroundColor Green
        Write-Host "[HINT] Remember to commit the removal: git commit -m 'chore: remove submodule $cleanRelPath'" -ForegroundColor Gray
    }
    catch {
        Write-Host "[ERROR] Exception during submodule removal: $_" -ForegroundColor Red
    }
    finally {
        Pop-Location
    }
}

function Get-SubmoduleItemsList {
    Push-Location $repoRoot
    try {
        $statusOut = & git submodule status 2>$null
        $list = @()
        if ($statusOut) {
            $idx = 1
            foreach ($line in ($statusOut -split "`r?`n")) {
                $trimmed = $line.Trim()
                if ($trimmed -match '^([\s\+\-U]?[0-9a-fA-F]+)\s+([^\s]+)(.*)$') {
                    $list += [PSCustomObject]@{
                        Index  = $idx
                        Hash   = $matches[1].Trim()
                        Path   = $matches[2].Trim()
                        Branch = $matches[3].Trim()
                    }
                    $idx++
                }
            }
        }
        return $list
    }
    finally {
        Pop-Location
    }
}

function Show-InteractiveMenu {
    while ($true) {
        $subs = Get-SubmoduleItemsList
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "   GIT SUBMODULE HUB  ::  all-lads-tool                   " -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host " Target Repository : $repoRoot" -ForegroundColor Yellow
        Write-Host " Registered Count  : $($subs.Count)" -ForegroundColor Gray
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        if ($subs.Count -gt 0) {
            Write-Host " Detected Submodules:" -ForegroundColor Green
            foreach ($s in $subs) {
                Write-Host ("   [{0}] {1}  ({2})" -f $s.Index, $s.Path, $s.Hash) -ForegroundColor White
            }
        } else {
            Write-Host "   (No submodules currently registered)" -ForegroundColor DarkGray
        }
        Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " Actions:" -ForegroundColor White
        Write-Host "  [<Git URL>]        : Paste Git URL to add submodule (auto folder extraction)" -ForegroundColor Green
        Write-Host "  [-<index>]         : Negative index to remove (e.g. -1, -2)" -ForegroundColor Red
        Write-Host "  [<index>]          : Positive index to sync/update (e.g. 1, 2)" -ForegroundColor Cyan
        Write-Host "  [all]              : Sync / update all submodules" -ForegroundColor Cyan
        Write-Host "  [1] Add Submodule  : Add submodule interactively" -ForegroundColor White
        Write-Host "  [2] Update All     : Update all submodules" -ForegroundColor White
        Write-Host "  [3] Status & List  : Show verbose git submodule status" -ForegroundColor White
        Write-Host "  [4] Sync URLs      : Sync submodule URLs" -ForegroundColor White
        Write-Host "  [5] Remove Submod  : Remove a submodule by path" -ForegroundColor White
        Write-Host "  [Q] Quit / Back    : Return to previous menu" -ForegroundColor DarkGray
        Write-Host "==========================================================" -ForegroundColor Cyan

        $choice = (Read-Host "Select [1-5, URL, -index, Q]").Trim()
        if ([string]::IsNullOrWhiteSpace($choice)) { return }

        if ($choice -match '^-(?<delIdx>\d+)$') {
            $num = [int]$Matches['delIdx']
            $targetSub = $subs | Where-Object { $_.Index -eq $num }
            if ($targetSub) {
                Remove-Submodule -subPath $targetSub.Path -forceRemove:$Force
            } else {
                Write-Host "[ERROR] Submodule index -$num not found in list." -ForegroundColor Red
            }
            continue
        }

        if ($choice -match '^(https?://|git@)') {
            Add-Submodule -subUrl $choice -forceAdd:$Force
            continue
        }

        if ($choice -match '^(?<syncIdx>\d+)$') {
            $num = [int]$Matches['syncIdx']
            if ($num -ge 1 -and $num -le 5 -and ($subs.Count -eq 0 -or -not ($subs | Where-Object { $_.Index -eq $num }))) {
                # Fall through to menu switch if no submodule at that index
            } elseif ($subs | Where-Object { $_.Index -eq $num }) {
                $targetSub = $subs | Where-Object { $_.Index -eq $num }
                Update-Submodules -targetPath $targetSub.Path
                continue
            }
        }

        switch ($choice.ToUpper()) {
            "1" { Add-Submodule -forceAdd:$Force }
            "2" { Update-Submodules }
            "ALL" { Update-Submodules }
            "3" { Show-SubmoduleStatus; Pause }
            "4" { Sync-Submodules; Pause }
            "5" { Remove-Submodule -forceRemove:$Force }
            "Q" { return }
            default { Write-Host "Invalid option. Type 1-5, URL, -index, or Q." -ForegroundColor Yellow }
        }
    }
}

# --- Execution Router ---
if (-not (Test-GitInstalled)) {
    exit 1
}

if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit 0
}

switch ($Action.ToLower()) {
    "add" {
        Add-Submodule -subUrl $Url -subPath $Path -subBranch $Branch -forceAdd:$Force
    }
    "update" {
        Update-Submodules -targetPath $Path
    }
    "status" {
        Show-SubmoduleStatus
    }
    "list" {
        Show-SubmoduleStatus
    }
    "sync" {
        Sync-Submodules
    }
    "remove" {
        Remove-Submodule -subPath $Path -forceRemove:$Force
    }
    "interactive" {
        Show-InteractiveMenu
    }
    default {
        if ($Url) {
            Add-Submodule -subUrl $Url -subPath $Path -subBranch $Branch -forceAdd:$Force
        } else {
            Show-InteractiveMenu
        }
    }
}
