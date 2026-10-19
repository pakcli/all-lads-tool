<#
.SYNOPSIS
    Vintage Computing Arcade - Git Submodule Manager
.DESCRIPTION
    Zero-hardcoded-path utility for managing Git submodules inside the repository.
    Supports Adding, Updating, Syncing, Listing, and Removing submodules.
    Can be run interactively or via CLI parameters.
.PARAMETER Action
    Action to perform: 'add', 'update', 'sync', 'status', 'list', 'remove'
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

function Show-InteractiveMenu {
    while ($true) {
        Write-Host ""
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "   VINTAGE COMPUTING ARCADE - GIT SUBMODULE HUB           " -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host " [1] Add New Submodule (include repo inside this project) " -ForegroundColor White
        Write-Host " [2] Update / Pull All Submodules                         " -ForegroundColor White
        Write-Host " [3] View Submodules Status & List                        " -ForegroundColor White
        Write-Host " [4] Sync Submodule URLs                                  " -ForegroundColor White
        Write-Host " [5] Remove a Submodule                                   " -ForegroundColor White
        Write-Host " [Q] Quit / Back                                          " -ForegroundColor DarkGray
        Write-Host "==========================================================" -ForegroundColor Cyan
        $choice = (Read-Host "Select option [1-5, Q]").Trim().ToUpper()

        switch ($choice) {
            "1" { Add-Submodule -forceAdd:$Force }
            "2" { Update-Submodules }
            "3" { Show-SubmoduleStatus }
            "4" { Sync-Submodules }
            "5" { Remove-Submodule -forceRemove:$Force }
            "Q" { return }
            default { Write-Host "Invalid option. Please choose 1, 2, 3, 4, 5, or Q." -ForegroundColor Red }
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
    default {
        if ($Url) {
            Add-Submodule -subUrl $Url -subPath $Path -subBranch $Branch -forceAdd:$Force
        } else {
            Show-InteractiveMenu
        }
    }
}
