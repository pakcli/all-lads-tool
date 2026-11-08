<#
.SYNOPSIS
    Universal Git Manager & Recovery Engine (Context: Repo)
.DESCRIPTION
    Comprehensive interactive Git management tool backed by modular adapters in adapter/.
    Supports managing the workspace root, detected repositories, or custom target folders.
    Features:
      [-1] Discard All Changes (Rollback uncommitted changes safely)
      [ 0] Status (Dashboard: branch, remote, modified files, recent commits)
      [ 1] Recover (Git reflog browser: detached/lost commit, surgical or full restore)
      [ 2] Commit (Status preview, staging, & Conventional Commit builder)
      [ 3] Push (Push active branch to remote with upstream tracking)
      [ 4] Pull / Sync (Smart pull with rebase or fast-forward)
      [ 5] Assign Git (Init repo, set remote origin, auto .gitignore, initial commit)
      [ 6] Remove Git ("Remove with more nicer" - safe attribute unlock & clean unlinking)
      [ 7] Clone (Interactive Git Clone Wizard with pre-flight briefed overview)
      [ 8] Worktree (Manage isolated branch worktrees: list, add, remove, prune)
      [ 9] Custom Shell / Run Script (Execute git commands or drag & drop scripts)
      [ 11] Submodule Hub (Interactive Git Submodule management)
      [ h] Help & Shortcuts
      [ t] Switch Target Directory (Workspace root, detected repos, or drag & drop folder)
      [ q] Quit
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$Action = "",

    [Parameter()]
    [string]$DefaultBranch = "main/pakcli"
)

$scriptDir = $PSScriptRoot

# ------------------------------------------------------------------------------
# 1. LOAD MODULAR ADAPTERS
# ------------------------------------------------------------------------------
$adapterDir = Join-Path $scriptDir "adapter"
if (-not (Test-Path -LiteralPath $adapterDir)) {
    Write-Error "[ERROR] Adapter directory not found: $adapterDir"
    exit 1
}

# Import core headless adapters
Import-Module (Join-Path $adapterDir "git-core.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $adapterDir "git-status.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $adapterDir "git-reflog.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $adapterDir "git-submodule.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $adapterDir "git-worktree.psm1") -Force -DisableNameChecking

# ------------------------------------------------------------------------------
# 2. PATH & TARGET RESOLUTION HELPERS (Zero Hardcoded Variables)
# ------------------------------------------------------------------------------
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

function Normalize-InputPath ([string]$rawPath, [string]$baseDir) {
    if ([string]::IsNullOrWhiteSpace($rawPath)) { return "" }
    $clean = $rawPath.Trim().Trim('"').Trim("'")
    if ([System.IO.Path]::IsPathRooted($clean)) {
        if (Test-Path -LiteralPath $clean) {
            return (Resolve-Path -LiteralPath $clean).Path
        }
        return $clean
    } else {
        $resolved = Join-Path $baseDir $clean
        if (Test-Path -LiteralPath $resolved) {
            return (Resolve-Path -LiteralPath $resolved).Path
        }
        return $resolved
    }
}

function Read-PromptDefault {
    param(
        [string]$Prompt,
        [string]$Default = ""
    )
    $msg = if (-not [string]::IsNullOrWhiteSpace($Default)) { "$($Prompt) [Default: $Default]: " } else { "$($Prompt): " }
    $inputVal = Read-Host $msg
    if ([string]::IsNullOrWhiteSpace($inputVal)) {
        return $Default
    }
    return $inputVal.Trim().Trim('"').Trim("'")
}

function Write-ColorGitStatusLine ([string]$line) {
    if ([string]::IsNullOrWhiteSpace($line)) { return }
    $prefix = if ($line.Length -ge 2) { $line.Substring(0, 2) } else { "" }
    $color = "White"
    if ($prefix -match "R" -or $prefix -match "D" -or $line -match "->") {
        $color = "Red"
    } elseif ($prefix -match "M") {
        $color = "Yellow"
    } elseif ($prefix -match "A" -or $prefix -match "\?") {
        $color = "Green"
    }
    Write-Host "  $line" -ForegroundColor $color
}

function Get-WorkspaceGitRepos ([string]$basePath) {
    $found = @()
    $searchRoot = $basePath
    if (Test-IsGitRepo $basePath) {
        $parent = Split-Path $basePath -Parent
        if ($parent -and (Test-Path -LiteralPath $parent)) {
            $searchRoot = $parent
        }
    }

    if (Test-IsGitRepo $searchRoot) {
        $found += (Get-Item -LiteralPath $searchRoot)
    }

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

# Resolve initial target directory
$initialDir = ""
if (-not [string]::IsNullOrWhiteSpace($TargetDir)) {
    $initialDir = Normalize-InputPath $TargetDir (Get-Location).Path
} else {
    $savedPath = ""
    $jsonPath = Get-RunJsonPath
    if ($jsonPath) {
        try {
            $raw = [System.IO.File]::ReadAllText($jsonPath, [System.Text.Encoding]::UTF8)
            $parsed = $raw | ConvertFrom-Json
            if ($parsed.targetDir) { $savedPath = $parsed.targetDir }
        } catch { }
    }
    if ($savedPath -and (Test-Path -LiteralPath $savedPath)) {
        $initialDir = $savedPath
    } else {
        $initialDir = (Get-Location).Path
    }
}
$currentTarget = $initialDir

# ------------------------------------------------------------------------------
# 3. FEATURE ACTIONS (-1 to 9, 11)
# ------------------------------------------------------------------------------

# Action [-1]: Discard All Changes
function Invoke-DiscardAllAction ([string]$dir) {
    Write-Host "`n=== [-1] DISCARD ALL CHANGES ===" -ForegroundColor Red
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    $summary = Get-GitStatusSummary $dir
    if ($summary.DirtyCount -eq 0) {
        Write-Host "Working tree is clean. Nothing to discard." -ForegroundColor Green
        return
    }

    Write-Host "`nUncommitted changes to be discarded:" -ForegroundColor Yellow
    $summary.Uncommitted | ForEach-Object { Write-ColorGitStatusLine $_ }

    Write-Host "`nWARNING: This will permanently undo all uncommitted changes and delete untracked files!" -ForegroundColor Red
    Write-Host "Type 'DISCARD' to confirm: " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host

    if ($confirm -eq "DISCARD") {
        Push-Location $dir
        try {
            git restore . 2>$null
            git checkout -- . 2>$null
            git clean -fd 2>$null
            Write-Host "[OK] All changes discarded. Working tree is clean." -ForegroundColor Green
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "Discard cancelled." -ForegroundColor DarkGray
    }
}

# Action [0]: Status Dashboard
function Invoke-StatusDashboardAction ([string]$dir) {
    Write-Host "`n=== [0] GIT STATUS DASHBOARD ===" -ForegroundColor Cyan
    $summary = Get-GitStatusSummary $dir

    Write-Host "Target Directory : $dir" -ForegroundColor White
    Write-Host "Git Initialized  : $(if ($summary.IsRepo) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($summary.IsRepo) { "Green" } else { "Red" })

    if (-not $summary.IsRepo) {
        Write-Host "`nThis folder is NOT currently tracked by Git." -ForegroundColor Yellow
        Write-Host "Tip: Use [5] Assign Git to initialize, or [7] Clone to fetch a repo." -ForegroundColor Gray
        return
    }

    Write-Host "Active Branch    : $($summary.Branch)" -ForegroundColor Cyan
    Write-Host "Primary Remote   : $($summary.Remote)" -ForegroundColor Gray
    Write-Host "Dirty Files      : $($summary.DirtyCount)" -ForegroundColor $(if ($summary.DirtyCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host "Total Size       : $($summary.TotalDirtyKb) KB" -ForegroundColor $(if ($summary.TotalDirtyKb -gt 0) { "Yellow" } else { "Green" })

    if ($summary.DirtyCount -gt 0) {
        Write-Host "`nModified / Untracked / Renamed Files:" -ForegroundColor Cyan
        $summary.Uncommitted | ForEach-Object { Write-ColorGitStatusLine $_ }
    } else {
        Write-Host "`nWorking tree is completely clean." -ForegroundColor Green
    }

    if ($summary.RecentLog) {
        Write-Host "`nRecent Commits:" -ForegroundColor Green
        foreach ($c in $summary.RecentLog) {
            Write-Host "  $($c.Hash) | $($c.Time) | $($c.Msg)" -ForegroundColor Gray
        }
    }
}

# Action [1]: Recover (Reflog browser & surgical restore)
function Invoke-RecoverAction ([string]$dir) {
    Write-Host "`n=== [1] RECOVER (REFLOG RESTORATION) ===" -ForegroundColor Cyan
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    $commitList = Get-ReflogCommits -dir $dir -maxCount 30
    if (-not $commitList -or $commitList.Count -eq 0) {
        Write-Host "No commits found in reflog or repository is empty." -ForegroundColor Yellow
        return
    }

    Write-Host "Recent reflog history (0 = latest):" -ForegroundColor Green
    Write-Host ("-" * 80) -ForegroundColor DarkGray
    for ($i = 0; $i -lt [Math]::Min(15, $commitList.Count); $i++) {
        $c = $commitList[$i]
        $tag = if ($c.IsLost) { "[DETACHED/LOST]" } else { "[BRANCHED]     " }
        $color = if ($c.IsLost) { "Yellow" } else { "DarkGray" }
        $idxStr = "[$i]".PadRight(5)
        $hashStr = $c.Hash.PadRight(8)
        $timeStr = $c.Time.PadRight(15)

        Write-Host "$idxStr $hashStr $timeStr " -NoNewline -ForegroundColor White
        Write-Host "$tag " -NoNewline -ForegroundColor $color
        Write-Host $c.Msg -ForegroundColor Gray
    }
    Write-Host ("-" * 80) -ForegroundColor DarkGray

    $selectedIdx = Read-PromptDefault -Prompt "Select commit index to inspect (0 = latest)" -Default "0"
    if (-not ($selectedIdx -match '^\d+$') -or [int]$selectedIdx -ge $commitList.Count) {
        Write-Host "Invalid index selected." -ForegroundColor Red
        return
    }

    $target = $commitList[[int]$selectedIdx]
    Write-Host "`nSelected commit: $($target.Hash) ($($target.Msg))" -ForegroundColor Cyan

    Push-Location $dir
    try {
        $changedFiles = git diff-tree --no-commit-id --name-status -r $target.Hash 2>$null
        if (-not $changedFiles) {
            Write-Host "No file changes in this commit (root or empty commit)." -ForegroundColor Yellow
            return
        }

        Write-Host "`nFiles modified in this commit:" -ForegroundColor Green
        $fileList = @()
        foreach ($f in $changedFiles) {
            $fParts = $f -split "`t", 2
            $status = $fParts[0].Trim()
            $filePath = $fParts[1].Trim()
            $fileList += $filePath
            Write-Host "  [$status] $filePath" -ForegroundColor Yellow
        }

        Write-Host "`nApplication Options:" -ForegroundColor Cyan
        Write-Host "  1. Simple overwrite all (restore all files from commit into working directory)"
        Write-Host "  2. Per-file overwrite (prompt for each file individually)"
        Write-Host "  3. Cancel"

        $opt = Read-PromptDefault -Prompt "Select option [1/2/3]" -Default "3"
        switch ($opt) {
            "1" {
                Write-Host "`nRestoring all files from commit $($target.Hash)..." -ForegroundColor Green
                $ok = Restore-ReflogCommitFiles -dir $dir -commitHash $target.Hash -files $fileList
                if ($ok) {
                    Write-Host "[OK] All files restored successfully." -ForegroundColor Cyan
                }
            }
            "2" {
                Write-Host "`nPer-File Overwrite Mode (0 = Skip [Default], 1 = Overwrite):`n" -ForegroundColor Magenta
                $appliedCount = 0
                foreach ($filePath in $fileList) {
                    $ans = Read-PromptDefault -Prompt "Overwrite '$filePath'? (0 = skip, 1 = overwrite)" -Default "0"
                    if ($ans -eq "1") {
                        git checkout $target.Hash -- $filePath 2>$null
                        Write-Host "  -> [OK] Restored '$filePath'" -ForegroundColor Green
                        $appliedCount++
                    } else {
                        Write-Host "  -> [SKIP] Skipped '$filePath'" -ForegroundColor DarkGray
                    }
                }
                Write-Host "`nDone! $appliedCount file(s) restored." -ForegroundColor Cyan
            }
            default {
                Write-Host "Cancelled. No files were modified." -ForegroundColor DarkGray
            }
        }
    } finally {
        Pop-Location
    }
}

# Action [2]: Commit
function Invoke-CommitAction ([string]$dir) {
    Write-Host "`n=== [2] COMMIT ===" -ForegroundColor Cyan
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    Push-Location $dir
    try {
        $status = git status -s 2>$null
        if (-not $status) {
            Write-Host "Working tree is clean. Nothing to commit." -ForegroundColor Green
            return
        }

        Write-Host "Current Status:" -ForegroundColor Yellow
        $status | ForEach-Object { Write-ColorGitStatusLine $_ }

        Write-Host "`nStaging Options:" -ForegroundColor Cyan
        Write-Host "  [1] Stage all changes (git add -A) [Default]"
        Write-Host "  [2] Select specific files to stage"
        Write-Host "  [3] Cancel"

        $stageOpt = Read-PromptDefault -Prompt "Select staging option" -Default "1"
        if ($stageOpt -eq "1") {
            git add -A
            Write-Host "[OK] All changes staged." -ForegroundColor Green
        } elseif ($stageOpt -eq "2") {
            Write-Host "Interactive staging:" -ForegroundColor Cyan
            $files = (git status -s) | ForEach-Object { ($_ -split "\s+", 2)[1].Trim() }
            foreach ($f in $files) {
                $ans = Read-PromptDefault -Prompt "Stage '$f'? (y/N)" -Default "n"
                if ($ans.ToLower() -eq "y") {
                    git add -- $f
                    Write-Host "  -> Staged: $f" -ForegroundColor Green
                }
            }
        } else {
            Write-Host "Commit cancelled." -ForegroundColor DarkGray
            return
        }

        $staged = git diff --cached --name-only 2>$null
        if (-not $staged) {
            Write-Host "No files staged. Commit aborted." -ForegroundColor Yellow
            return
        }

        Write-Host "`nConventional Commit Prefix Helper:" -ForegroundColor Cyan
        Write-Host "  [1] feat:     (A new feature)"
        Write-Host "  [2] fix:      (A bug fix)"
        Write-Host "  [3] docs:     (Documentation changes)"
        Write-Host "  [4] chore:    (Maintenance or build changes)"
        Write-Host "  [5] refactor: (Code refactoring without feature change)"
        Write-Host "  [6] style:    (Formatting, CSS, visual updates)"
        Write-Host "  [7] Custom / Raw message"

        $prefixOpt = Read-PromptDefault -Prompt "Select prefix [1-7]" -Default "1"
        $prefix = switch ($prefixOpt) {
            "1" { "feat" }
            "2" { "fix" }
            "3" { "docs" }
            "4" { "chore" }
            "5" { "refactor" }
            "6" { "style" }
            default { "" }
        }

        if (-not [string]::IsNullOrWhiteSpace($prefix)) {
            $scope = Read-PromptDefault -Prompt "Enter scope (optional, e.g. repo, auth, ui)" -Default ""
            $msgText = Read-PromptDefault -Prompt "Enter commit message description" -Default ""
            if ([string]::IsNullOrWhiteSpace($msgText)) {
                Write-Host "Commit message cannot be empty. Aborted." -ForegroundColor Red
                return
            }
            $finalMsg = if (-not [string]::IsNullOrWhiteSpace($scope)) { "$($prefix)($scope): $msgText" } else { "$($prefix): $msgText" }
        } else {
            $finalMsg = Read-PromptDefault -Prompt "Enter full commit message" -Default ""
            if ([string]::IsNullOrWhiteSpace($finalMsg)) {
                Write-Host "Commit message cannot be empty. Aborted." -ForegroundColor Red
                return
            }
        }

        Write-Host "`nCommitting: `"$finalMsg`"" -ForegroundColor Cyan
        git commit -m $finalMsg
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Commit created successfully!" -ForegroundColor Green
        } else {
            Write-Host "Commit exited with code $LASTEXITCODE." -ForegroundColor Yellow
        }
    } finally {
        Pop-Location
    }
}

# Action [3]: Push
function Invoke-PushAction ([string]$dir) {
    Write-Host "`n=== [3] PUSH ===" -ForegroundColor Cyan
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    Push-Location $dir
    try {
        $branch = (git branch --show-current 2>$null)
        if ([string]::IsNullOrWhiteSpace($branch)) {
            Write-Host "Cannot push in detached HEAD state." -ForegroundColor Red
            return
        }

        $remotes = (git remote 2>$null)
        if (-not $remotes) {
            Write-Host "No git remotes configured for this repository." -ForegroundColor Yellow
            return
        }

        $remoteTarget = Read-PromptDefault -Prompt "Target remote" -Default "origin"
        Write-Host "Pushing branch '$branch' to '$remoteTarget'..." -ForegroundColor Cyan

        $upstream = (git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>$null)
        if (-not $upstream) {
            Write-Host "No upstream set. Pushing with --set-upstream..." -ForegroundColor Yellow
            git push --set-upstream $remoteTarget $branch
        } else {
            git push $remoteTarget $branch
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Push successful!" -ForegroundColor Green
        } else {
            Write-Host "Push failed with exit code $LASTEXITCODE." -ForegroundColor Red
        }
    } finally {
        Pop-Location
    }
}

# Action [4]: Pull / Sync
function Invoke-PullAction ([string]$dir) {
    Write-Host "`n=== [4] PULL / SYNC ===" -ForegroundColor Cyan
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    Push-Location $dir
    try {
        $branch = (git branch --show-current 2>$null)
        Write-Host "Pulling updates for branch '$branch'..." -ForegroundColor Cyan
        Write-Host "  [1] Rebase (git pull --rebase) [Default: Clean linear history]"
        Write-Host "  [2] Fast-forward only (git pull --ff-only)"
        Write-Host "  [3] Standard merge pull (git pull)"
        Write-Host "  [4] Cancel"

        $pullOpt = Read-PromptDefault -Prompt "Select pull strategy" -Default "1"
        switch ($pullOpt) {
            "1" { git pull --rebase }
            "2" { git pull --ff-only }
            "3" { git pull }
            default { Write-Host "Pull cancelled." -ForegroundColor DarkGray; return }
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Sync complete!" -ForegroundColor Green
        } else {
            Write-Host "Pull failed or encountered conflicts." -ForegroundColor Red
        }
    } finally {
        Pop-Location
    }
}

# Action [5]: Assign Git (Initialize Repository)
function Invoke-AssignGitAction ([string]$dir) {
    Write-Host "`n=== [5] ASSIGN GIT (INITIALIZE REPOSITORY) ===" -ForegroundColor Cyan
    if (Test-IsGitRepo $dir) {
        Write-Host "Directory '$dir' is ALREADY a Git repository." -ForegroundColor Yellow
        $reinit = Read-PromptDefault -Prompt "Do you want to re-initialize or configure remote? (y/N)" -Default "n"
        if ($reinit.ToLower() -ne "y") { return }
    } else {
        Write-Host "Initializing new Git repository with branch '$DefaultBranch' in: $dir" -ForegroundColor Green
        Push-Location $dir
        try {
            git init -b $DefaultBranch 2>$null
            if ($LASTEXITCODE -ne 0) {
                git init
                git checkout -b $DefaultBranch 2>$null
            }
            Write-Host "[OK] Git repository initialized." -ForegroundColor Green
            Update-RunJsonTarget $dir
        } finally {
            Pop-Location
        }
    }

    Push-Location $dir
    try {
        $gitignorePath = Join-Path $dir ".gitignore"
        if (-not (Test-Path -LiteralPath $gitignorePath)) {
            $defaultIgnore = @"
# Dependencies
node_modules/
vendor/

# Logs & Temp
*.log
.DS_Store
Thumbs.db
*.bak
*.tmp

# Builds & Outputs
dist/
build/
"@
            [System.IO.File]::WriteAllText($gitignorePath, $defaultIgnore, [System.Text.Encoding]::UTF8)
            Write-Host "[OK] Created standard .gitignore" -ForegroundColor Green
        }

        $existingRemote = (git remote -v 2>$null)
        if (-not $existingRemote) {
            $remoteUrl = Read-PromptDefault -Prompt "Enter Remote Git URL (or press Enter to skip)" -Default ""
            if (-not [string]::IsNullOrWhiteSpace($remoteUrl)) {
                git remote add origin $remoteUrl
                Write-Host "[OK] Remote 'origin' set to: $remoteUrl" -ForegroundColor Green
            }
        } else {
            Write-Host "Existing remote: $existingRemote" -ForegroundColor Gray
        }

        $doCommit = Read-PromptDefault -Prompt "Create initial commit? (Y/n)" -Default "y"
        if ($doCommit.ToLower() -eq "y") {
            git add -A
            git commit -m "chore: initial repository setup" 2>$null
            Write-Host "[OK] Initial commit created!" -ForegroundColor Green
        }
    } finally {
        Pop-Location
    }
}

# Action [6]: Remove Git ("Remove with more nicer")
function Invoke-RemoveGitAction ([string]$dir) {
    Write-Host "`n=== [6] REMOVE GIT (SAFE UNLINK) ===" -ForegroundColor Red
    $gitDir = Join-Path $dir ".git"
    if (-not (Test-Path -LiteralPath $gitDir)) {
        Write-Host "No '.git' folder found in '$dir'. Nothing to remove." -ForegroundColor Yellow
        return
    }

    Write-Host "`nTarget Directory : $dir" -ForegroundColor Yellow
    Write-Host "Git Folder       : $gitDir" -ForegroundColor Red
    Write-Host "`n[SAFETY WARNING]:" -ForegroundColor Red
    Write-Host "This operation will completely and permanently remove all Git tracking, history, commits, and branches from this directory." -ForegroundColor Red
    Write-Host "Your actual project files will NOT be deleted or touched." -ForegroundColor White
    Write-Host "`nType 'REMOVE' to confirm: " -NoNewline -ForegroundColor Yellow

    $confirm = Read-Host
    if ($confirm -ne "REMOVE") {
        Write-Host "Removal cancelled. Git repository remains untouched." -ForegroundColor DarkGray
        return
    }

    Write-Host "`nExecuting 'Remove with more nicer'..." -ForegroundColor Cyan

    # Step 1: Strip read-only, hidden, and system attributes across .git
    Write-Host "  -> Stripping Read-Only, System, and Hidden attributes..." -ForegroundColor Gray
    try {
        cmd.exe /c "attrib -r -s -h `"$gitDir\*.*`" /s /d" 2>$null
    } catch {}

    # Step 2: Remove lock files if lingering
    $lockFiles = @(Join-Path $gitDir "index.lock"), (Join-Path $gitDir "HEAD.lock")
    foreach ($lf in $lockFiles) {
        if (Test-Path -LiteralPath $lf) {
            Remove-Item -LiteralPath $lf -Force -ErrorAction SilentlyContinue
        }
    }

    # Step 3: Remove .git directory with robust fallback
    Write-Host "  -> Removing .git directory structure..." -ForegroundColor Gray
    $removed = $false
    try {
        Remove-Item -LiteralPath $gitDir -Recurse -Force -ErrorAction Stop
        $removed = $true
    } catch {
        try {
            [System.IO.Directory]::Delete($gitDir, $true)
            $removed = $true
        } catch {
            Write-Host "Warning: Standard removal encountered locked files. Attempting cmd /c rmdir..." -ForegroundColor Yellow
            cmd.exe /c "rmdir /s /q `"$gitDir`"" 2>$null
            $removed = (-not (Test-Path -LiteralPath $gitDir))
        }
    }

    if ($removed -or (-not (Test-Path -LiteralPath $gitDir))) {
        Write-Host "`n[SUCCESS] Git tracking completely removed!" -ForegroundColor Green
        Write-Host "Folder '$dir' is now a clean, unversioned directory." -ForegroundColor Cyan
    } else {
        Write-Host "`n[ERROR] Failed to completely remove .git folder. Some files may be locked by an active process." -ForegroundColor Red
    }
}

# Action [7]: Clone Wizard Helper
function ConvertTo-GitCloneUrl ([string]$rawInput) {
    if (-not $rawInput) { return "" }
    $clean = $rawInput.Trim().Trim('"').Trim("'")
    if ($clean -match 'gh\s+repo\s+clone\s+(?<repo>\S+)') {
        $clean = $Matches['repo'].Trim()
    }
    if ($clean -match '^([a-zA-Z0-9_\-\.]+)/([a-zA-Z0-9_\-\.]+)$') {
        return "https://github.com/$clean.git"
    }
    return $clean
}

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
            $userInput = Read-Host "Remote Repository URL / GitHub CLI command [Default: $detectedClip]"
            $rawUrl = if ([string]::IsNullOrWhiteSpace($userInput)) { $detectedClip } else { $userInput }
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

    $branchInput = Read-Host "Specific Branch (optional - press Enter for default branch)"
    $branch = if ($branchInput) { $branchInput.Trim() } else { "" }

    $depth = 0
    $shallowPrompt = Read-Host "Shallow clone (--depth 1 for fast download)? [y/N] [Default: N]"
    if ($shallowPrompt -match '^(y|yes)$') {
        $depth = 1
    }

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

    $confirm = Read-Host "Proceed with git clone? [y/N] (Type 'y' or 'yes' to proceed)"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Host "[CANCELLED] Git clone aborted by user confirmation check." -ForegroundColor Yellow
        return $null
    }

    Write-Host "`n[START] Cloning repository..." -ForegroundColor Green
    $cloneArgs = @("clone")
    if ($branch) { $cloneArgs += @("--branch", $branch) }
    if ($depth -gt 0) { $cloneArgs += @("--depth", "$depth") }
    $cloneArgs += @($url, $finalDest)

    & git @cloneArgs
    if ($LASTEXITCODE -eq 0 -and (Test-IsGitRepo $finalDest)) {
        Write-Host "`n[SUCCESS] Repository cloned successfully to: $finalDest" -ForegroundColor Green
        Update-RunJsonTarget $finalDest
        return $finalDest
    } else {
        Write-Host "`n[ERROR] Git clone failed with exit code $LASTEXITCODE." -ForegroundColor Red
        return $null
    }
}

# Action [8]: Worktree Management
function Invoke-WorktreeAction ([string]$dir) {
    Write-Host "`n=== [8] WORKTREE MANAGEMENT ===" -ForegroundColor Cyan
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    $wtList = Get-GitWorktrees -dir $dir
    Write-Host "Current Worktrees:" -ForegroundColor Green
    if ($wtList -and $wtList.Count -gt 0) {
        foreach ($wt in $wtList) {
            Write-Host "  Path: $($wt.Path) | Head: $($wt.Head) | Branch: $($wt.Branch)" -ForegroundColor White
        }
    } else {
        Write-Host "  (None found or root only)" -ForegroundColor DarkGray
    }
    Write-Host ""

    Write-Host "Worktree Options:" -ForegroundColor Cyan
    Write-Host "  [1] Add new worktree (checkout branch in isolated folder)"
    Write-Host "  [2] Remove an existing worktree"
    Write-Host "  [3] Prune stale worktree references"
    Write-Host "  [4] Return to menu"

    $wtOpt = Read-PromptDefault -Prompt "Select option" -Default "4"
    switch ($wtOpt) {
        "1" {
            $branchName = Read-PromptDefault -Prompt "Enter branch name (existing or new)" -Default ""
            if ([string]::IsNullOrWhiteSpace($branchName)) { return }
            $wtPath = Read-PromptDefault -Prompt "Enter destination folder relative to current target" -Default "../wt-$branchName"
            $ok = Add-GitWorktree -dir $dir -branch $branchName -targetPath $wtPath
            if ($ok) {
                Write-Host "[OK] Worktree added at: $wtPath" -ForegroundColor Green
            } else {
                Write-Host "[ERROR] Failed to add worktree." -ForegroundColor Red
            }
        }
        "2" {
            $remPath = Read-PromptDefault -Prompt "Enter worktree path to remove" -Default ""
            if (-not [string]::IsNullOrWhiteSpace($remPath)) {
                $ok = Remove-GitWorktree -dir $dir -worktreePath $remPath
                if ($ok) {
                    Write-Host "[OK] Worktree removed." -ForegroundColor Green
                } else {
                    Write-Host "[ERROR] Failed to remove worktree." -ForegroundColor Red
                }
            }
        }
        "3" {
            Prune-GitWorktrees -dir $dir
            Write-Host "[OK] Worktrees pruned." -ForegroundColor Green
        }
        default {}
    }
}

# Action [9]: Custom Shell / Run Script
function Invoke-CustomShellAction ([string]$dir) {
    Write-Host "`n=== [9] CUSTOM SHELL / SCRIPT RUNNER ===" -ForegroundColor Cyan
    Write-Host "Target Directory: $dir" -ForegroundColor Gray
    Write-Host "Hint: Type any git/cmd command, OR drag & drop any script (.ps1, .bat, .js, .py) here." -ForegroundColor DarkGray
    Write-Host "Type 'q' or press Enter on empty prompt to return to menu.`n" -ForegroundColor DarkGray

    while ($true) {
        $inputCmd = Read-Host "Shell ($dir) > "
        if ([string]::IsNullOrWhiteSpace($inputCmd) -or $inputCmd.Trim() -eq "q") { break }

        $cleanPath = $inputCmd.Trim().Trim('"').Trim("'")

        if (Test-Path -LiteralPath $cleanPath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($cleanPath).ToLower()
            Write-Host "Executing script: $cleanPath" -ForegroundColor Cyan
            Push-Location $dir
            try {
                switch ($ext) {
                    ".ps1" { & $cleanPath }
                    ".bat" { cmd.exe /c "`"$cleanPath`"" }
                    ".cmd" { cmd.exe /c "`"$cleanPath`"" }
                    ".js"  { node $cleanPath }
                    ".py"  { python $cleanPath }
                    default { & $cleanPath }
                }
            } catch {
                Write-Host "Error executing script: $_" -ForegroundColor Red
            } finally {
                Pop-Location
            }
        } else {
            Push-Location $dir
            try {
                Invoke-Expression $inputCmd
            } catch {
                Write-Host "Command error: $_" -ForegroundColor Red
            } finally {
                Pop-Location
            }
        }
        Write-Host ""
    }
}

# Action [11]: Submodule Hub
function Invoke-SubmoduleAction ([string]$dir) {
    Write-Host "`n=== [11] SUBMODULE HUB ===" -ForegroundColor Cyan
    $subScript = Join-Path $PSScriptRoot "git-submodule.ps1"
    if (Test-Path -LiteralPath $subScript) {
        & $subScript -Action "interactive" -Path $dir
    } else {
        $subs = Get-SubmoduleList -RepoPath $dir
        if (-not $subs -or $subs.Count -eq 0) {
            Write-Host "No submodules registered in '$dir'." -ForegroundColor Yellow
        } else {
            Write-Host "Registered Submodules:" -ForegroundColor Green
            foreach ($s in $subs) {
                Write-Host "  [$($s.Index)] $($s.Path) ($($s.Hash)) $($s.Branch)" -ForegroundColor White
            }
        }
    }
}

# Footer [t]: Switch Target Directory
function Switch-TargetDirectoryAction ([string]$current) {
    Write-Host "`n=== [t] SWITCH TARGET DIRECTORY ===" -ForegroundColor Cyan
    Write-Host "Current Target: $current`n" -ForegroundColor Gray

    $repos = Get-WorkspaceGitRepos $current
    Write-Host "Detected Workspace Repositories:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $repos.Count; $i++) {
        $isCur = if ($repos[$i].FullName -eq $current) { " (ACTIVE)" } else { "" }
        Write-Host "  [$($i + 1)] $($repos[$i].Name)$isCur" -ForegroundColor White
        Write-Host "      $($repos[$i].FullName)" -ForegroundColor DarkGray
    }
    Write-Host "  [c] Custom Path (or drag & drop any folder here)"
    Write-Host "  [x] Cancel"

    $sel = Read-PromptDefault -Prompt "`nSelect repository [1-$($repos.Count)], [c], or drag folder" -Default "x"

    if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $repos.Count) {
        $picked = $repos[[int]$sel - 1].FullName
        Update-RunJsonTarget $picked
        Write-Host "Target switched to: $picked" -ForegroundColor Green
        return $picked
    } elseif ($sel -eq "x") {
        return $current
    } else {
        $candidate = Normalize-InputPath $sel (Get-Location).Path
        if (Test-Path -LiteralPath $candidate -PathType Container) {
            Update-RunJsonTarget $candidate
            Write-Host "Switched to: $candidate" -ForegroundColor Green
            return $candidate
        } elseif (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $parent = Split-Path -Parent $candidate
            Update-RunJsonTarget $parent
            Write-Host "Switched to file parent folder: $parent" -ForegroundColor Green
            return $parent
        } else {
            Write-Host "Invalid folder path. Keeping current target." -ForegroundColor Yellow
            return $current
        }
    }
}

# Footer [h]: Help
function Show-HelpGuideAction {
    Write-Host "`n=== [h] GIT MANAGER HELP & SHORTCUTS ===" -ForegroundColor Cyan
    Write-Host @"
Universal Git Manager (git-manage.ps1, Context: Repo)
Supports workspace roots, subprojects, and independent repositories.

COMMAND MATRIX (-1 to 9, 11):
  [-1] Discard All Changes : Rollback all uncommitted changes and clean untracked files.
                             Protected with typed 'DISCARD' confirmation.
  [ 0] Status              : Live dashboard showing active branch, remotes, dirty files,
                             and recent commit log.
  [ 1] Recover             : Restores detached or lost commits from git reflog. Offers surgical
                             per-file overwrite or full commit restoration.
  [ 2] Commit              : Interactive status preview, staging options (All / Selective),
                             and Conventional Commit prefix helper (feat, fix, docs, etc.).
  [ 3] Push                : Pushes current branch to remote with upstream tracking.
  [ 4] Pull / Sync         : Smart pull with linear rebase, fast-forward, or standard merge.
  [ 5] Assign Git          : Initializes Git repository, sets remote origin, generates
                             default .gitignore, and creates initial commit.
  [ 6] Remove Git          : 'Remove with more nicer' - unlocks ReadOnly and hidden attributes,
                             cleans locks, requires typed 'REMOVE' confirmation, and cleanly
                             deletes the .git folder leaving all project files intact.
  [ 7] Clone               : Launches the Git Clone Wizard with pre-flight briefed overview.
  [ 8] Worktree            : Manages git worktrees for isolated parallel branch workflows.
  [ 9] Custom Shell / Script: Interactive shell inside target directory. Supports running
                             git/cmd commands OR dragging & dropping any script (.ps1, .bat, etc.)
  [ 11] Submodule Hub      : Interactive Git Submodule Hub (numbered list, add, remove, sync).

FOOTER CONTROLS:
  [ h] Help                : Display this guide.
  [ t] Switch Target       : Change working target directory (Detected repos, or drag & drop).
  [ q] Quit                : Exit tool.
"@ -ForegroundColor Gray
    Write-Host ""
}

# ------------------------------------------------------------------------------
# 4. DIRECT ACTION EXECUTION (If invoked via -Action parameter)
# ------------------------------------------------------------------------------
if (-not [string]::IsNullOrWhiteSpace($Action)) {
    switch ($Action.ToLower()) {
        "0"        { Invoke-StatusDashboardAction $currentTarget; exit }
        "status"   { Invoke-StatusDashboardAction $currentTarget; exit }
        "1"        { Invoke-RecoverAction $currentTarget; exit }
        "recover"  { Invoke-RecoverAction $currentTarget; exit }
        "2"        { Invoke-CommitAction $currentTarget; exit }
        "commit"   { Invoke-CommitAction $currentTarget; exit }
        "3"        { Invoke-PushAction $currentTarget; exit }
        "push"     { Invoke-PushAction $currentTarget; exit }
        "4"        { Invoke-PullAction $currentTarget; exit }
        "pull"     { Invoke-PullAction $currentTarget; exit }
        "-1"       { Invoke-DiscardAllAction $currentTarget; exit }
        "discard"  { Invoke-DiscardAllAction $currentTarget; exit }
        "5"        { Invoke-AssignGitAction $currentTarget; exit }
        "assign"   { Invoke-AssignGitAction $currentTarget; exit }
        "6"        { Invoke-RemoveGitAction $currentTarget; exit }
        "remove"   { Invoke-RemoveGitAction $currentTarget; exit }
        "7"        { Start-GitCloneWizard -SuggestedDestination $currentTarget; exit }
        "clone"    { Start-GitCloneWizard -SuggestedDestination $currentTarget; exit }
        "8"        { Invoke-WorktreeAction $currentTarget; exit }
        "worktree" { Invoke-WorktreeAction $currentTarget; exit }
        "9"        { Invoke-CustomShellAction $currentTarget; exit }
        "shell"    { Invoke-CustomShellAction $currentTarget; exit }
        "11"       { Invoke-SubmoduleAction $currentTarget; exit }
        "submodule"{ Invoke-SubmoduleAction $currentTarget; exit }
        default {
            Write-Host "Unknown action: $Action" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------------------------
# 5. NON-GIT TARGET DISPATCHER
# ------------------------------------------------------------------------------
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
    Write-Host "  [ 3 ] Initialize a fresh Git repository here (Assign Git)" -ForegroundColor Cyan
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
            $currentTarget = Switch-TargetDirectoryAction $currentTarget
        }
        "3" {
            Invoke-AssignGitAction $currentTarget
        }
        "q" {
            Write-Host "Exiting Git Manager." -ForegroundColor DarkGray
            exit 0
        }
        default {
            Write-Host "Invalid option." -ForegroundColor Yellow
        }
    }
}

# ------------------------------------------------------------------------------
# 6. MASTER INTERACTIVE MENU LOOP
# ------------------------------------------------------------------------------
$Host.UI.RawUI.WindowTitle = "Universal Git Manager :: all-lads-tool"

while ($true) {
    $summary = Get-GitStatusSummary $currentTarget
    $statusText = if ($summary.IsRepo) {
        "INITIALIZED (Branch: $($summary.Branch)) | Remotes: $($summary.Remote) | Dirty Files: $($summary.DirtyCount)"
    } else {
        "NOT A GIT REPO (Use [5] Assign Git or [7] Clone)"
    }

    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host "   UNIVERSAL GIT MANAGER & RECOVERY TOOL  ::  all-lads-tool" -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " Target Directory : $currentTarget" -ForegroundColor White
    Write-Host " Git Status       : $statusText" -ForegroundColor $(if ($summary.IsRepo) { "Green" } else { "Yellow" })
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [-1 ]  Discard All   : Rollback uncommitted changes (restore + clean)" -ForegroundColor Red
    Write-Host "  [ 0 ]  Status        : Dashboard (branch, remotes, status, recent log)" -ForegroundColor White
    Write-Host "  [ 1 ]  Recover       : Reflog browser (restore detached/lost commits)" -ForegroundColor Yellow
    Write-Host "  [ 2 ]  Commit        : Git status staging & Conventional Commit helper" -ForegroundColor Green
    Write-Host "  [ 3 ]  Push          : Push branch to remote with upstream tracking" -ForegroundColor Green
    Write-Host "  [ 4 ]  Pull / Sync   : Smart pull (Rebase / Fast-Forward)" -ForegroundColor Cyan
    Write-Host "  [ 5 ]  Assign Git    : Initialize repo (git init, remote, .gitignore)" -ForegroundColor Magenta
    Write-Host "  [ 6 ]  Remove Git    : 'Remove with more nicer' (safe .git unlink)" -ForegroundColor Yellow
    Write-Host "  [ 7 ]  Clone         : Clone repo from remote URL into target folder" -ForegroundColor Cyan
    Write-Host "  [ 8 ]  Worktree      : Manage isolated branch worktrees (list/add/rm)" -ForegroundColor Magenta
    Write-Host "  [ 9 ]  Custom Shell  : Custom command or drag & drop script (.ps1/.bat)" -ForegroundColor Cyan
    Write-Host "  [ 11]  Submodule     : Manage git submodules (list, add, remove)" -ForegroundColor Green
    Write-Host ""
    Write-Host " ----------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ h ]  Help          : Panduan lengkap dan shortcut" -ForegroundColor Gray
    Write-Host "  [ t ]  Target Dir    : Ganti target (Root, sibling repos, Custom)" -ForegroundColor Gray
    Write-Host "  [ q ]  Quit          : Keluar" -ForegroundColor Gray
    Write-Host "========================================================================" -ForegroundColor Cyan

    $choice = Read-Host "Select option [-1 to 9, 11, h, t, q] [Default: 0]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "0" }
    $choice = $choice.Trim()

    switch ($choice) {
        "-1" { Invoke-DiscardAllAction $currentTarget }
        "0"  { Invoke-StatusDashboardAction $currentTarget }
        "1"  { Invoke-RecoverAction $currentTarget }
        "2"  { Invoke-CommitAction $currentTarget }
        "3"  { Invoke-PushAction $currentTarget }
        "4"  { Invoke-PullAction $currentTarget }
        "5"  { Invoke-AssignGitAction $currentTarget }
        "6"  { Invoke-RemoveGitAction $currentTarget }
        "7"  {
            $cloned = Start-GitCloneWizard -SuggestedDestination (Split-Path $currentTarget -Parent)
            if ($cloned -and (Test-IsGitRepo $cloned)) {
                $currentTarget = $cloned
            }
        }
        "8"  { Invoke-WorktreeAction $currentTarget }
        "9"  { Invoke-CustomShellAction $currentTarget }
        "11" { Invoke-SubmoduleAction $currentTarget }
        "h"  { Show-HelpGuideAction }
        "t"  { $currentTarget = Switch-TargetDirectoryAction $currentTarget }
        "q"  {
            Write-Host "Exiting Git Manager. Happy coding lads!" -ForegroundColor Cyan
            break
        }
        default {
            $cleanDropped = Normalize-InputPath $choice (Get-Location).Path
            if (Test-Path -LiteralPath $cleanDropped) {
                if (Test-Path -LiteralPath $cleanDropped -PathType Container) {
                    $currentTarget = $cleanDropped
                    Update-RunJsonTarget $currentTarget
                    Write-Host "Target directory updated to: $currentTarget" -ForegroundColor Green
                } else {
                    $parent = Split-Path -Parent $cleanDropped
                    $currentTarget = $parent
                    Update-RunJsonTarget $currentTarget
                    Write-Host "Target directory updated to: $currentTarget" -ForegroundColor Green
                }
            } else {
                Write-Host "Invalid option '$choice'. Type 'h' for help." -ForegroundColor Yellow
            }
        }
    }
}
