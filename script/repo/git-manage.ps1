<#
.SYNOPSIS
    Universal Git Manager (Context: Repo)
.DESCRIPTION
    Lean orchestrator that detects Git runtime version and loads the matching adapter from adapter/.
    Features automatic Git repository validation, interactive retargeting (t),
    and synchronization with _run.json.
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [string]$TargetDir = ""
)

$ErrorActionPreference = 'Stop'
$scriptDir = $PSScriptRoot

# 1. Detect Git version
$gitVersionRaw = git --version 2>$null
if (-not $gitVersionRaw) {
    Write-Error "[ERROR] Git CLI tidak ditemukan pada sistem."
    exit 1
}

$versionNumber = [regex]::Match($gitVersionRaw, '\d+\.\d+').Value
$adapterFile = if ([version]$versionNumber -ge [version]"2.40") {
    "v02-40-00.psm1"
} else {
    "v02-30-00.psm1"
}

$adapterPath = Join-Path $scriptDir "adapter\$adapterFile"
Import-Module -Name $adapterPath -Force

# Helper to find _run.json
function Get-RunJsonPath {
    $candidates = @(
        (Join-Path $scriptDir "..\..\_run.json"),
        (Join-Path $scriptDir "..\..\..\_run.json")
    )
    foreach ($cand in $candidates) {
        if (Test-Path -LiteralPath $cand) {
            return (Resolve-Path $cand).Path
        }
    }
    return ""
}

# Helper to update targetDir in _run.json
function Update-RunJsonTarget ([string]$newTarget) {
    $jsonPath = Get-RunJsonPath
    if ($jsonPath -and (Test-Path -LiteralPath $jsonPath)) {
        try {
            $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
            $data = $raw | ConvertFrom-Json
            $data | Add-Member -MemberType NoteProperty -Name "targetDir" -Value $newTarget -Force
            $json = $data | ConvertTo-Json -Depth 5
            [System.IO.File]::WriteAllText($jsonPath, $json, [System.Text.Encoding]::UTF8)
        } catch { }
    }
}

# Helper to safely invoke native git commands without NativeCommandError on stderr
function Invoke-GitSafe {
    param(
        [Parameter(Mandatory)] [string]$RepoPath,
        [Parameter(Mandatory)] [string[]]$GitArgs
    )
    $prev = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        $result = & git -C $RepoPath @GitArgs 2>&1
        $code = $LASTEXITCODE
        $strLines = @($result | Where-Object { $_ -is [string] -or $_ -is [System.Management.Automation.ErrorRecord] } | ForEach-Object { "$_" })
        return [PSCustomObject]@{
            Success = ($code -eq 0)
            Output  = $strLines
            Raw     = $result
        }
    } catch {
        return [PSCustomObject]@{
            Success = $false
            Output  = @()
            Raw     = $_
        }
    } finally {
        $ErrorActionPreference = $prev
    }
}

# Helper to check if a directory is a Git repository safely
function Test-IsGitRepo ([string]$path) {
    if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Container)) { return $false }
    return (Test-Path -LiteralPath (Join-Path $path ".git"))
}

# 2. Resolve initial TargetDir
$jsonPath = Get-RunJsonPath
$savedTarget = ""
if ($jsonPath) {
    try {
        $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
        $parsed = $raw | ConvertFrom-Json
        if ($parsed.targetDir) { $savedTarget = $parsed.targetDir }
    } catch { }
}

$currentTarget = if ($TargetDir -and (Test-Path $TargetDir)) {
    (Resolve-Path $TargetDir).Path
} elseif ($savedTarget -and (Test-Path $savedTarget) -and (Test-IsGitRepo $savedTarget)) {
    $savedTarget
} else {
    (Get-Location).Path
}

# Helper to discover git repos in workspace
function Get-WorkspaceGitRepos ([string]$basePath) {
    $found = @()
    # Resolve the workspace parent directory (e.g. E:\proj)
    $searchRoot = $basePath
    if (Test-IsGitRepo $basePath) {
        $parent = Split-Path $basePath -Parent
        if ($parent -and (Test-Path -LiteralPath $parent)) {
            $searchRoot = $parent
        }
    }

    # 1. If searchRoot itself is a git repo, include it
    if (Test-IsGitRepo $searchRoot) {
        $found += (Get-Item -LiteralPath $searchRoot)
    }

    # 2. Inspect immediate child directories under searchRoot only
    $subDirs = Get-ChildItem -LiteralPath $searchRoot -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $subDirs) {
        if ($dir.Name -ne 'node_modules' -and $dir.Name -ne 'trash-bin' -and -not $dir.Name.StartsWith('.')) {
            if (Test-IsGitRepo $dir.FullName) {
                $found += $dir
            }
        }
    }

    return ($found | Sort-Object FullName -Unique)
}

# Helper to clean and normalize Git clone URLs (HTTPS, SSH, GitHub CLI, or owner/repo)
function ConvertTo-GitCloneUrl ([string]$rawInput) {
    if (-not $rawInput) { return "" }
    $clean = $rawInput.Trim().Trim('"').Trim("'")

    # Handle GitHub CLI: "gh repo clone owner/repo" or "gh repo clone https://..."
    if ($clean -match 'gh\s+repo\s+clone\s+(?<repo>\S+)') {
        $clean = $Matches['repo'].Trim()
    }

    # Handle short-form "owner/repo" (no protocol, contains single slash, no spaces)
    if ($clean -match '^([a-zA-Z0-9_\-\.]+)/([a-zA-Z0-9_\-\.]+)$') {
        return "https://github.com/$clean.git"
    }

    return $clean
}

# Helper to infer a clean repo folder name from a Git clone URL
function Get-GitRepoNameFromUrl ([string]$url) {
    if (-not $url) { return "cloned-repo" }
    $trimmed = $url.Trim().TrimEnd('/')
    $base = [System.IO.Path]::GetFileNameWithoutExtension($trimmed)
    if ($base -match '[:/](?<name>[^/:]+)$') {
        $base = $Matches['name']
    }
    $base = $base -replace '\.git$', ''
    return if ($base) { $base } else { "cloned-repo" }
}

# Interactive Git Clone Wizard with Briefed Overview & explicit confirmation gating
function Start-GitCloneWizard {
    param(
        [string]$SuggestedDestination = "",
        [string]$PrefilledUrl = ""
    )
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   GIT CLONE WIZARD (CONTEXT: REPO)                       " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Supported URL formats: HTTPS, SSH, GitHub CLI, or owner/repo" -ForegroundColor DarkGray
    Write-Host ""

    # 1. Prompt for URL if not provided (with automatic clipboard pre-fill detection)
    $rawUrl = $PrefilledUrl
    if (-not $rawUrl) {
        $detectedClip = $null
        try {
            Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
            if ([System.Windows.Forms.Clipboard]::ContainsText()) {
                $clipRaw = [System.Windows.Forms.Clipboard]::GetText()
                if ($clipRaw) {
                    $cand = ConvertTo-GitCloneUrl $clipRaw
                    if ($cand -and ($cand -match '^https?:\/\/' -or $cand -match '^git@' -or $cand -match 'gh\s+repo\s+clone')) {
                        $detectedClip = $cand
                    }
                }
            }
        } catch {}

        if ($detectedClip) {
            Write-Host " [DETECTED CLIPBOARD REPO] Found: $detectedClip" -ForegroundColor Green
            $promptMsg = "Remote Repository URL / GitHub CLI command [Default: $detectedClip]"
            $userInput = Read-Host $promptMsg
            if ([string]::IsNullOrWhiteSpace($userInput)) {
                $rawUrl = $detectedClip
            } else {
                $rawUrl = $userInput
            }
        } else {
            $rawUrl = Read-Host "Remote Repository URL / GitHub CLI command"
        }
    }
    $url = ConvertTo-GitCloneUrl $rawUrl
    if (-not $url) {
        Write-Host "[CANCELLED] URL is empty. Aborting clone." -ForegroundColor Yellow
        return $null
    }

    $repoName = Get-GitRepoNameFromUrl $url

    # 2. Destination Strategy
    Write-Host "`nTarget Destination Options:" -ForegroundColor White
    $destOptions = @()
    if ($SuggestedDestination -and (Test-Path -LiteralPath $SuggestedDestination)) {
        $isEmpty = @(Get-ChildItem -LiteralPath $SuggestedDestination -Force -ErrorAction SilentlyContinue).Count -eq 0
        if ($isEmpty) {
            Write-Host "  [ 1 ] Clone directly into selected directory: $SuggestedDestination" -ForegroundColor Green
            $destOptions += @{ Key = "1"; Path = $SuggestedDestination; Mode = "In-Place (Clean Target Directory)" }
        } else {
            Write-Host "  [ 1 ] Selected directory is NOT empty: $SuggestedDestination" -ForegroundColor DarkGray
        }
        $subPath = Join-Path $SuggestedDestination $repoName
        Write-Host "  [ 2 ] Clone into new subfolder: $subPath" -ForegroundColor White
        $destOptions += @{ Key = "2"; Path = $subPath; Mode = "New Subdirectory" }
    } else {
        $defaultRoot = if ($currentTarget -and (Test-Path -LiteralPath $currentTarget)) {
            if (Test-IsGitRepo $currentTarget) { Split-Path $currentTarget -Parent } else { $currentTarget }
        } else {
            (Get-Location).Path
        }
        $defaultTarget = Join-Path $defaultRoot $repoName
        Write-Host "  [ 1 ] Clone to workspace subfolder: $defaultTarget" -ForegroundColor White
        $destOptions += @{ Key = "1"; Path = $defaultTarget; Mode = "Workspace Subdirectory" }
    }
    Write-Host "  [ c ] Enter custom destination path" -ForegroundColor Cyan
    Write-Host "  [ q ] Cancel clone" -ForegroundColor DarkGray

    $destChoice = Read-Host "Select destination [Default: 1]"
    if ([string]::IsNullOrWhiteSpace($destChoice)) { $destChoice = "1" }
    $destChoice = $destChoice.Trim()

    if ($destChoice -eq 'q') {
        Write-Host "[CANCELLED] Clone cancelled by user." -ForegroundColor DarkGray
        return $null
    }

    $finalDest = ""
    $finalMode = "Custom Subdirectory"
    $opt = $destOptions | Where-Object { $_.Key -eq $destChoice }
    if ($opt) {
        $finalDest = $opt.Path
        $finalMode = $opt.Mode
    } elseif ($destChoice -eq 'c') {
        $cust = Read-Host "Enter custom full directory path"
        if (-not $cust) {
            Write-Host "[CANCELLED] Path is empty." -ForegroundColor Yellow
            return $null
        }
        $finalDest = $cust.Trim().Trim('"').Trim("'")
        $finalMode = "Custom Path"
    } else {
        Write-Host "[CANCELLED] Invalid destination selection." -ForegroundColor Yellow
        return $null
    }

    # 3. Optional Branch
    Write-Host ""
    $branchInput = Read-Host "Specific Branch (optional - press Enter for default branch)"
    $branch = if ($branchInput) { $branchInput.Trim() } else { "" }

    # 4. Optional Depth
    $depth = 0
    $shallowPrompt = Read-Host "Shallow clone (--depth 1 for fast download)? [y/N] [Default: N]"
    if ($shallowPrompt -match '^(y|yes)$') {
        $depth = 1
    }

    # 5. Pre-flight Briefed Overview Card (options.md standard)
    $cmdPreview = "git clone"
    if ($branch) { $cmdPreview += " --branch $branch" }
    if ($depth -gt 0) { $cmdPreview += " --depth $depth" }
    $cmdPreview += " $url `"$finalDest`""

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   GIT CLONE PRE-FLIGHT BRIEFED OVERVIEW                  " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Remote URL    : $url" -ForegroundColor White
    Write-Host " Target Path   : $finalDest" -ForegroundColor White
    Write-Host " Clone Mode    : $finalMode" -ForegroundColor DarkGray
    Write-Host " Branch        : $(if ($branch) { $branch } else { '(Remote Default HEAD)' })" -ForegroundColor DarkGray
    Write-Host " History Depth : $(if ($depth -gt 0) { 'Shallow (1)' } else { 'Full History' })" -ForegroundColor DarkGray
    Write-Host " Command       : $cmdPreview" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""

    # 6. Explicit Yes-To-Proceed Confirmation Gating
    $confirm = Read-Host "Proceed with git clone? [y/N] (Type 'y' or 'yes' to proceed)"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Host "[CANCELLED] Git clone aborted by user confirmation check." -ForegroundColor Yellow
        return $null
    }

    # 7. Execute Clone via Adapter
    Write-Host "`n[START] Cloning repository..." -ForegroundColor Green
    $cloneOk = Invoke-GitClone -Url $url -DestinationPath $finalDest -Branch $branch -Depth $depth

    if ($cloneOk -and (Test-IsGitRepo $finalDest)) {
        Write-Host "`n[SUCCESS] Repository cloned successfully to: $finalDest" -ForegroundColor Green
        Update-RunJsonTarget $finalDest
        return $finalDest
    } else {
        Write-Host "`n[ERROR] Git clone failed or target directory is not a valid git repository." -ForegroundColor Red
        return $null
    }
}

# Function to interactively select or switch target repo
function Select-TargetRepo ([string]$current) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   SELECT / RETARGET GIT REPOSITORY                       " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Current Directory : $current" -ForegroundColor White
    
    $repos = Get-WorkspaceGitRepos $current
    if ($repos.Count -gt 0) {
        Write-Host "`n Available Git Repositories Detected:" -ForegroundColor DarkCyan
        for ($i = 0; $i -lt $repos.Count; $i++) {
            $isCur = if ($repos[$i].FullName -eq $current) { " (ACTIVE)" } else { "" }
            Write-Host "  [$($i + 1)] $($repos[$i].Name)$isCur" -ForegroundColor White
            Write-Host "      Path: $($repos[$i].FullName)" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host " Enter number [1-$($repos.Count)], enter custom path, [c] to clone, or [q] to cancel:" -ForegroundColor White
    $sel = Read-Host " Target"
    $sel = if ($sel) { $sel.Trim().Trim('"').Trim("'") } else { "" }

    if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $repos.Count) {
        $newTarget = $repos[[int]$sel - 1].FullName
        Update-RunJsonTarget $newTarget
        Write-Host "[OK] Target switched to: $newTarget" -ForegroundColor Green
        return $newTarget
    } elseif ($sel -eq 'c') {
        $cloned = Start-GitCloneWizard -SuggestedDestination $current
        if ($cloned -and (Test-IsGitRepo $cloned)) {
            return $cloned
        }
        return $current
    } elseif ($sel -and (Test-Path $sel)) {
        $resolved = (Resolve-Path $sel).Path
        if (Test-IsGitRepo $resolved) {
            Update-RunJsonTarget $resolved
            Write-Host "[OK] Target switched to: $resolved" -ForegroundColor Green
            return $resolved
        } else {
            Write-Host "[ALERT] '$resolved' is not a git repository." -ForegroundColor Yellow
            $askClone = Read-Host "Assign as clone destination and clone a repository here? [y/N] [Default: Y]"
            if ([string]::IsNullOrWhiteSpace($askClone) -or $askClone -match '^(y|yes)$') {
                $cloned = Start-GitCloneWizard -SuggestedDestination $resolved
                if ($cloned -and (Test-IsGitRepo $cloned)) {
                    return $cloned
                }
            }
            return $resolved
        }
    } elseif ($sel -eq 'q') {
        return $current
    } else {
        Write-Host "No change made." -ForegroundColor DarkGray
        return $current
    }
}

# 3. If target is not a Git repo, offer clone, select, or init
while (-not (Test-IsGitRepo $currentTarget)) {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   TARGET IS NOT A GIT REPOSITORY                         " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Current Directory : $currentTarget" -ForegroundColor White
    Write-Host ""
    Write-Host " Available Actions:" -ForegroundColor White
    Write-Host "  [ 1 ] Clone a remote repository here (Git Clone Wizard)" -ForegroundColor Green
    Write-Host "  [ 2 ] Select another Git repository from workspace" -ForegroundColor White
    Write-Host "  [ 3 ] Initialize a fresh Git repository here (git init)" -ForegroundColor Cyan
    Write-Host "  [ q ] Quit" -ForegroundColor DarkGray
    Write-Host "==========================================================" -ForegroundColor Cyan

    $nonGitChoice = Read-Host "Select option [1-3, q] [Default: 1]"
    if ([string]::IsNullOrWhiteSpace($nonGitChoice)) { $nonGitChoice = "1" }
    $nonGitChoice = $nonGitChoice.Trim()

    switch ($nonGitChoice) {
        "1" {
            $cloned = Start-GitCloneWizard -SuggestedDestination $currentTarget
            if ($cloned -and (Test-IsGitRepo $cloned)) {
                $currentTarget = $cloned
            }
        }
        "2" {
            $currentTarget = Select-TargetRepo $currentTarget
        }
        "3" {
            $initConfirm = Read-Host "Initialize new Git repository at '$currentTarget'? [y/N]"
            if ($initConfirm -match '^(y|yes)$') {
                $initRes = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('init')
                if ($initRes.Success) {
                    Write-Host "[OK] Git repository initialized at $currentTarget" -ForegroundColor Green
                    Update-RunJsonTarget $currentTarget
                } else {
                    Write-Host "[ERROR] Failed to init git repo: $($initRes.Output -join ' ')" -ForegroundColor Red
                }
            }
        }
        "q" {
            Write-Host "Operation aborted: A valid Git repository is required." -ForegroundColor DarkGray
            exit 0
        }
        default {
            Write-Host "Invalid option." -ForegroundColor Yellow
        }
    }
}

# 4. Interactive Git Cockpit
while ($true) {
    # Resolve branch safely without throwing on fresh uncommitted repos
    $branchExec = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('branch', '--show-current')
    $branch = if ($branchExec.Success -and $branchExec.Output) { ($branchExec.Output -join '').Trim() } else { "" }
    if (-not $branch) {
        $symbExec = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('symbolic-ref', '--short', 'HEAD')
        $branch = if ($symbExec.Success -and $symbExec.Output) { ($symbExec.Output -join '').Trim() } else { "" }
    }
    if (-not $branch) {
        $headExec = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('rev-parse', '--short', 'HEAD')
        $branch = if ($headExec.Success -and $headExec.Output) { "HEAD ($($headExec.Output -join ''))" } else { "master (uncommitted)" }
    }

    # Verify if commits exist before calling git log
    $commitCheck = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('rev-parse', '--verify', 'HEAD')
    $lastCommit = if ($commitCheck.Success) {
        $logExec = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('log', '-1', '--oneline')
        if ($logExec.Success -and $logExec.Output) { ($logExec.Output -join ' ').Trim() } else { "" }
    } else {
        "(No commits yet - fresh repository)"
    }

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   GIT MANAGER (CONTEXT: REPO)                            " -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " Target Repo : $currentTarget" -ForegroundColor White
    Write-Host " Branch      : $branch" -ForegroundColor Green
    if ($lastCommit) {
        Write-Host " Last Commit : $lastCommit" -ForegroundColor DarkGray
    }
    Write-Host " Adapter     : $adapterFile" -ForegroundColor DarkGray
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Working Tree Status:" -ForegroundColor Yellow
    Invoke-GitStatus -RepoPath $currentTarget
    Write-Host ""
    Write-Host " ----------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ 1 ] Refresh Status" -ForegroundColor White
    Write-Host "  [ 2 ] Branch Rename (Invoke-GitBranchRename)" -ForegroundColor White
    Write-Host "  [ 3 ] Recent Commits (git log -5)" -ForegroundColor White
    Write-Host "  [ 4 ] Git Clone Remote Repository (Invoke-GitClone)" -ForegroundColor Green
    Write-Host "  [ t ] Retarget Directory (Switch Git Repo)" -ForegroundColor Cyan
    Write-Host "  [ q ] Quit" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan

    $choice = Read-Host "Select option [1-4, t, q] [Default: 1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    $choice = $choice.Trim()

    switch -Regex ($choice) {
        "^1$" { continue }
        "^2$" {
            $newBr = Read-Host "TARGET BRANCH NAME (Nama branch baru)"
            if ($newBr) {
                Invoke-GitBranchRename -NewBranch $newBr.Trim() -RepoPath $currentTarget
            }
            Start-Sleep -Seconds 1
        }
        "^3$" {
            Write-Host "`nRecent 5 Commits:" -ForegroundColor Green
            $commitCheck = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('rev-parse', '--verify', 'HEAD')
            if ($commitCheck.Success) {
                $logExec = Invoke-GitSafe -RepoPath $currentTarget -GitArgs @('log', '-5', '--graph', "--pretty=format:%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset", '--abbrev-commit')
                if ($logExec.Output) {
                    $logExec.Output | ForEach-Object { Write-Host $_ }
                }
            } else {
                Write-Host " [NOTICE] This repository has no commits yet." -ForegroundColor DarkGray
            }
            Write-Host ""
            Read-Host "Press Enter to return to menu"
        }
        "^(4|c|clone)$" {
            $parentRoot = if (Test-IsGitRepo $currentTarget) { Split-Path $currentTarget -Parent } else { $currentTarget }
            $cloned = Start-GitCloneWizard -SuggestedDestination $parentRoot
            if ($cloned -and (Test-IsGitRepo $cloned)) {
                $currentTarget = $cloned
            }
            Start-Sleep -Seconds 1
        }
        "^t$" {
            $currentTarget = Select-TargetRepo $currentTarget
            Start-Sleep -Seconds 1
        }
        "^q$" {
            Write-Host "Exiting Git Manager." -ForegroundColor DarkGray
            break
        }
        default {
            Write-Host "Opsi tidak valid: '$choice'." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
