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
    Write-Host " Enter number [1-$($repos.Count)], enter custom path, or [q] to cancel:" -ForegroundColor White
    $sel = Read-Host " Target"
    $sel = if ($sel) { $sel.Trim().Trim('"').Trim("'") } else { "" }

    if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $repos.Count) {
        $newTarget = $repos[[int]$sel - 1].FullName
        Update-RunJsonTarget $newTarget
        Write-Host "[OK] Target switched to: $newTarget" -ForegroundColor Green
        return $newTarget
    } elseif ($sel -and (Test-Path $sel)) {
        $resolved = (Resolve-Path $sel).Path
        if (Test-IsGitRepo $resolved) {
            Update-RunJsonTarget $resolved
            Write-Host "[OK] Target switched to: $resolved" -ForegroundColor Green
            return $resolved
        } else {
            Write-Host "[WARNING] '$resolved' is not a git repository." -ForegroundColor Yellow
            return $resolved
        }
    } elseif ($sel -eq 'q') {
        return $current
    } else {
        Write-Host "No change made." -ForegroundColor DarkGray
        return $current
    }
}

# 3. If target is not a Git repo, prompt to select
if (-not (Test-IsGitRepo $currentTarget)) {
    Write-Host "[ALERT] '$currentTarget' is not a git repository." -ForegroundColor Yellow
    $currentTarget = Select-TargetRepo $currentTarget
    if (-not (Test-IsGitRepo $currentTarget)) {
        Write-Host "[ERROR] Operation aborted: A valid Git repository is required." -ForegroundColor Red
        exit 1
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
    Write-Host "  [ t ] Retarget Directory (Switch Git Repo)" -ForegroundColor Cyan
    Write-Host "  [ q ] Quit" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan

    $choice = Read-Host "Select option [1-3, t, q] [Default: 1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }
    $choice = $choice.Trim()

    switch ($choice) {
        "1" { continue }
        "2" {
            $newBr = Read-Host "TARGET BRANCH NAME (Nama branch baru)"
            if ($newBr) {
                Invoke-GitBranchRename -NewBranch $newBr.Trim() -RepoPath $currentTarget
            }
            Start-Sleep -Seconds 1
        }
        "3" {
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
        "t" {
            $currentTarget = Select-TargetRepo $currentTarget
            Start-Sleep -Seconds 1
        }
        "q" {
            Write-Host "Exiting Git Manager." -ForegroundColor DarkGray
            break
        }
        default {
            Write-Host "Opsi tidak valid: '$choice'." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
