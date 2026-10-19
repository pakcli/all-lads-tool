<#
.SYNOPSIS
    Universal Git Manager & Recovery Engine (ps_git-manage.ps1)
.DESCRIPTION
    Comprehensive interactive Git management tool with Target Directory awareness.
    Supports managing the workspace root or individual cartridge subfolders (apps/<app>).
    Features:
      [-1] Discard All Changes (Rollback uncommitted changes safely)
      [ 0] Status (Dashboard: branch, remote, modified files, recent commits)
      [ 1] Recover (Git reflog browser: detached/lost commit, surgical or full restore)
      [ 2] Commit (Status preview, staging, & Conventional Commit builder)
      [ 3] Push (Push active branch to remote with upstream tracking)
      [ 4] Pull / Sync (Smart pull with rebase or fast-forward)
      [ 5] Assign Git (Init repo, set remote origin, auto .gitignore, initial commit)
      [ 6] Remove Git ("Remove with more nicer" - safe attribute unlock & clean unlinking)
      [ 7] Clone (Clone remote repository into target directory or subfolder)
      [ 8] Worktree (Manage isolated branch worktrees: list, add, remove)
      [ 9] Custom Shell / Run Script (Execute git commands or drag & drop scripts)
      [ h] Help & Shortcuts
      [ t] Switch Target Directory (Workspace root, apps/<slug>, or drag & drop folder)
      [ q] Quit
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$TargetDir = "",

    [Parameter(Position = 1)]
    [string]$Action = ""
)

# ------------------------------------------------------------------------------
# 0. DYNAMIC ROOT & PATH RESOLUTION (Rule #001: Zero Hardcoded Variables)
# ------------------------------------------------------------------------------
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = (Resolve-Path (Join-Path $scriptDir "..\..\..")).Path

function Normalize-InputPath ([string]$rawPath) {
    if ([string]::IsNullOrWhiteSpace($rawPath)) { return "" }
    $clean = $rawPath.Trim().Trim('"').Trim("'")
    if ([System.IO.Path]::IsPathRooted($clean)) {
        if (Test-Path $clean) {
            return (Resolve-Path $clean).Path
        }
        return $clean
    } else {
        $resolved = Join-Path $repoRoot $clean
        if (Test-Path $resolved) {
            return (Resolve-Path $resolved).Path
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

# Resolve initial target directory
if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    $currentTarget = $repoRoot
} else {
    $currentTarget = Normalize-InputPath $TargetDir
    if (-not (Test-Path $currentTarget)) {
        Write-Host "Warning: Target directory '$currentTarget' does not exist. Falling back to workspace root." -ForegroundColor Yellow
        $currentTarget = $repoRoot
    }
}

# ------------------------------------------------------------------------------
# 1. GIT INSPECTION HELPERS (Target Directory Scoped)
# ------------------------------------------------------------------------------
function Test-IsGitRepo ([string]$dir) {
    $gitPath = Join-Path $dir ".git"
    return (Test-Path $gitPath)
}

function Invoke-GitCommand ([string]$dir, [string]$gitArgs) {
    Push-Location $dir
    try {
        $output = Invoke-Expression "git $gitArgs" 2>&1
        return $output
    } finally {
        Pop-Location
    }
}

function Write-ColorGitStatusLine ([string]$line) {
    if ([string]::IsNullOrWhiteSpace($line)) { return }
    $prefix = if ($line.Length -ge 2) { $line.Substring(0, 2) } else { "" }
    $color = "White"
    # R (Renamed) or D (Deleted): Red
    if ($prefix -match "R" -or $prefix -match "D" -or $line -match "->") {
        $color = "Red"
    }
    # M (Modified): Kuning (Yellow)
    elseif ($prefix -match "M") {
        $color = "Yellow"
    }
    # Added / Untracked: Green
    elseif ($prefix -match "A" -or $prefix -match "\?") {
        $color = "Green"
    }
    Write-Host "  $line" -ForegroundColor $color
}

function Get-GitStatusSummary ([string]$dir) {
    if (-not (Test-IsGitRepo $dir)) {
        return [PSCustomObject]@{
            IsRepo        = $false
            Branch        = "N/A"
            Remote        = "None"
            DirtyCount    = 0
            TotalDirtyKb  = 0
            RecentLog     = @()
            Uncommitted   = @()
        }
    }

    Push-Location $dir
    try {
        $branch = (git branch --show-current 2>$null)
        if ([string]::IsNullOrWhiteSpace($branch)) {
            $branch = (git rev-parse --short HEAD 2>$null)
            if ([string]::IsNullOrWhiteSpace($branch)) { $branch = "empty" } else { $branch = "(detached: $branch)" }
        }

        $remotes = (git remote -v 2>$null) | Select-Object -First 1
        $remoteName = if ($remotes) { ($remotes -split "\s+")[0] } else { "None" }

        $statusLines = @(git status -s 2>$null)
        $dirtyCount = if ($statusLines) { $statusLines.Count } else { 0 }

        $totalDirtyBytes = 0
        if ($statusLines) {
            foreach ($line in $statusLines) {
                if ($line.Length -gt 3) {
                    $rawPath = $line.Substring(3).Trim()
                    if ($rawPath -match '->\s*(.+)$') {
                        $rawPath = $matches[1].Trim()
                    }
                    $rawPath = $rawPath.Trim('"')
                    $fullPath = Join-Path $dir $rawPath
                    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
                        try {
                            $totalDirtyBytes += (Get-Item -LiteralPath $fullPath -Force).Length
                        } catch {}
                    }
                }
            }
        }
        $totalDirtyKb = [math]::Round($totalDirtyBytes / 1KB, 2)

        $recentLog = (git log -n 5 --format="%h | %cr | %s" 2>$null)

        return [PSCustomObject]@{
            IsRepo        = $true
            Branch        = $branch
            Remote        = $remoteName
            DirtyCount    = $dirtyCount
            TotalDirtyKb  = $totalDirtyKb
            RecentLog     = $recentLog
            Uncommitted   = $statusLines
        }
    } finally {
        Pop-Location
    }
}

# ------------------------------------------------------------------------------
# 2. FEATURE ACTIONS (-1 to 9)
# ------------------------------------------------------------------------------

# Action [-1]: Discard All Changes
function Invoke-DiscardAll ([string]$dir) {
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

# Action [0]: Custom Shell / Run Script (supports drag & drop)
function Invoke-CustomShell ([string]$dir) {
    Write-Host "`n=== [0] CUSTOM SHELL / SCRIPT RUNNER ===" -ForegroundColor Cyan
    Write-Host "Target Directory: $dir" -ForegroundColor Gray
    Write-Host "Hint: Type any git/bash command, OR drag & drop any script (.ps1, .bat, .js, .py) here." -ForegroundColor DarkGray
    Write-Host "Type 'q' or press Enter on empty prompt to return to menu.`n" -ForegroundColor DarkGray

    while ($true) {
        $inputCmd = Read-Host "Shell ($dir) > "
        if ([string]::IsNullOrWhiteSpace($inputCmd) -or $inputCmd.Trim() -eq "q") { break }

        $cleanPath = $inputCmd.Trim().Trim('"').Trim("'")

        # Check if user dragged & dropped a runnable script file
        if (Test-Path $cleanPath -PathType Leaf) {
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
            # Execute arbitrary command in target directory
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

# Action [1]: Recover (Reflog browser & surgical restore)
function Invoke-Recover ([string]$dir) {
    Write-Host "`n=== [1] RECOVER (REFLOG RESTORATION) ===" -ForegroundColor Cyan
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    Push-Location $dir
    try {
        $rawReflog = git reflog -n 40 --format="%h|%cr|%s" 2>$null
        if (-not $rawReflog) {
            Write-Host "No reflog entries found or repository is empty." -ForegroundColor Yellow
            return
        }

        $seen = [System.Collections.Generic.HashSet[string]]::new()
        $commitList = [System.Collections.Generic.List[PSCustomObject]]::new()

        foreach ($line in $rawReflog) {
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            $parts = $line.Split('|', 3)
            if ($parts.Length -lt 3) { continue }
            
            $hash = $parts[0].Trim()
            $time = $parts[1].Trim()
            $msg  = $parts[2].Trim()

            if ($seen.Add($hash)) {
                $inBranch = git branch --all --contains $hash 2>$null
                $isLost = [string]::IsNullOrWhiteSpace($inBranch)

                $commitList.Add([PSCustomObject]@{
                    Hash   = $hash
                    Time   = $time
                    Msg    = $msg
                    IsLost = $isLost
                })
            }
        }

        if ($commitList.Count -eq 0) {
            Write-Host "No commits found in reflog." -ForegroundColor Yellow
            return
        }

        Write-Host "Recent commit history (0 = latest):" -ForegroundColor Green
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
                foreach ($filePath in $fileList) {
                    git checkout $target.Hash -- $filePath 2>$null
                    Write-Host "  -> Restored: $filePath" -ForegroundColor Green
                }
                Write-Host "`nDone! All files restored successfully." -ForegroundColor Cyan
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
function Invoke-Commit ([string]$dir) {
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

        # Check if anything is staged
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
            $scope = Read-PromptDefault -Prompt "Enter scope (optional, e.g. arcade, nav, theme)" -Default ""
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
        Write-Host "[OK] Commit created successfully!" -ForegroundColor Green
    } finally {
        Pop-Location
    }
}

# Action [3]: Push
function Invoke-Push ([string]$dir) {
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

        # Check upstream
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
function Invoke-Pull ([string]$dir) {
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

# Action [5]: Assign Git (Init repo, remote, .gitignore, initial commit)
function Invoke-AssignGit ([string]$dir) {
    Write-Host "`n=== [5] ASSIGN GIT (INITIALIZE REPOSITORY) ===" -ForegroundColor Cyan
    if (Test-IsGitRepo $dir) {
        Write-Host "Directory '$dir' is ALREADY a Git repository." -ForegroundColor Yellow
        $reinit = Read-PromptDefault -Prompt "Do you want to re-initialize or add remote? (y/N)" -Default "n"
        if ($reinit.ToLower() -ne "y") { return }
    } else {
        Write-Host "Initializing new Git repository with main branch in: $dir" -ForegroundColor Green
        Push-Location $dir
        try {
            git init -b main 2>$null
            if ($LASTEXITCODE -ne 0) {
                git init
                git checkout -b main 2>$null
            }
            Write-Host "[OK] Git repository initialized." -ForegroundColor Green
        } finally {
            Pop-Location
        }
    }

    Push-Location $dir
    try {
        # Auto-create .gitignore if none exists
        $gitignorePath = Join-Path $dir ".gitignore"
        if (-not (Test-Path $gitignorePath)) {
            $defaultIgnore = @"
# Dependencies
node_modules/
vendor/

# Logs & Temp
*.log
.DS_Store
Thumbs.db
.bak

# Builds & Outputs
dist/
build/
*.tmp
"@
            Set-Content -Path $gitignorePath -Value $defaultIgnore -Encoding UTF8
            Write-Host "[OK] Created standard .gitignore" -ForegroundColor Green
        }

        # Remote setup
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

        # Initial commit prompt
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
function Invoke-RemoveGit ([string]$dir) {
    Write-Host "`n=== [6] REMOVE GIT (SAFE UNLINK) ===" -ForegroundColor Red
    $gitDir = Join-Path $dir ".git"
    if (-not (Test-Path $gitDir)) {
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
        if (Test-Path $lf) {
            Remove-Item -Path $lf -Force -ErrorAction SilentlyContinue
        }
    }

    # Step 3: Remove .git directory with robust fallback
    Write-Host "  -> Removing .git directory structure..." -ForegroundColor Gray
    $removed = $false
    try {
        Remove-Item -Path $gitDir -Recurse -Force -ErrorAction Stop
        $removed = $true
    } catch {
        # Fallback to .NET Directory Delete
        try {
            [System.IO.Directory]::Delete($gitDir, $true)
            $removed = $true
        } catch {
            Write-Host "Warning: Standard removal encountered locked files. Attempting cmd /c rmdir..." -ForegroundColor Yellow
            cmd.exe /c "rmdir /s /q `"$gitDir`"" 2>$null
            $removed = (-not (Test-Path $gitDir))
        }
    }

    if ($removed -or (-not (Test-Path $gitDir))) {
        Write-Host "`n[SUCCESS] Git tracking completely removed!" -ForegroundColor Green
        Write-Host "Folder '$dir' is now a clean, unversioned directory." -ForegroundColor Cyan
    } else {
        Write-Host "`n[ERROR] Failed to completely remove .git folder. Some files may be locked by an active process." -ForegroundColor Red
    }
}

# Action [7]: Clone
function Invoke-Clone ([string]$dir) {
    Write-Host "`n=== [7] CLONE REPOSITORY ===" -ForegroundColor Cyan
    $repoUrl = Read-PromptDefault -Prompt "Enter Git Repository URL to clone" -Default ""
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        Write-Host "Clone cancelled. URL cannot be empty." -ForegroundColor Yellow
        return
    }

    # Deduce folder name from URL
    $repoName = [System.IO.Path]::GetFileNameWithoutExtension($repoUrl.TrimEnd('/'))

    Write-Host "Clone Destination Options:" -ForegroundColor Cyan
    Write-Host "  [1] Inside current target dir as '$repoName' (e.g. $dir\$repoName)"
    Write-Host "  [2] Directly into current target dir (target dir must be empty)"
    Write-Host "  [3] Custom subfolder name"
    Write-Host "  [4] Cancel"

    $cloneOpt = Read-PromptDefault -Prompt "Select option" -Default "1"
    Push-Location $dir
    try {
        switch ($cloneOpt) {
            "1" {
                git clone $repoUrl $repoName
            }
            "2" {
                git clone $repoUrl .
            }
            "3" {
                $subName = Read-PromptDefault -Prompt "Enter folder name" -Default $repoName
                git clone $repoUrl $subName
            }
            default {
                Write-Host "Clone cancelled." -ForegroundColor DarkGray
                return
            }
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] Repository cloned successfully!" -ForegroundColor Green
        } else {
            Write-Host "Clone failed with exit code $LASTEXITCODE." -ForegroundColor Red
        }
    } finally {
        Pop-Location
    }
}

# Action [8]: Worktree Management
function Invoke-Worktree ([string]$dir) {
    Write-Host "`n=== [8] WORKTREE MANAGEMENT ===" -ForegroundColor Cyan
    if (-not (Test-IsGitRepo $dir)) {
        Write-Host "Target directory is not a Git repository." -ForegroundColor Yellow
        return
    }

    Push-Location $dir
    try {
        Write-Host "Current Worktrees:" -ForegroundColor Green
        git worktree list
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
                
                # Check if branch exists
                $exists = (git branch --list $branchName 2>$null)
                if ($exists) {
                    git worktree add $wtPath $branchName
                } else {
                    git worktree add -b $branchName $wtPath
                }
                Write-Host "[OK] Worktree added at: $wtPath" -ForegroundColor Green
            }
            "2" {
                $remPath = Read-PromptDefault -Prompt "Enter worktree path to remove" -Default ""
                if (-not [string]::IsNullOrWhiteSpace($remPath)) {
                    git worktree remove $remPath
                    Write-Host "[OK] Worktree removed." -ForegroundColor Green
                }
            }
            "3" {
                git worktree prune -v
                Write-Host "[OK] Worktrees pruned." -ForegroundColor Green
            }
            default {}
        }
    } finally {
        Pop-Location
    }
}

# Action [0]: Status Dashboard
function Invoke-StatusDashboard ([string]$dir) {
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
        Write-Host "`nRecent 5 Commits:" -ForegroundColor Green
        $summary.RecentLog | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    }
}

# Footer [t]: Switch Target Directory (supports drag & drop folder)
function Switch-TargetDirectory ([string]$current) {
    Write-Host "`n=== [t] SWITCH TARGET DIRECTORY ===" -ForegroundColor Cyan
    Write-Host "Current Target: $current`n" -ForegroundColor Gray

    # Scan cartridges in apps/
    $appsDir = Join-Path $repoRoot "apps"
    $cartridges = @()
    if (Test-Path $appsDir) {
        $cartridges = Get-ChildItem -Path $appsDir -Directory | Where-Object { $_.Name -notlike "_*" }
    }

    Write-Host "Quick Presets:" -ForegroundColor Cyan
    Write-Host "  [0] Workspace Root ($repoRoot)"
    
    $idx = 1
    foreach ($cart in $cartridges) {
        Write-Host "  [$idx] apps/$($cart.Name)"
        $idx++
    }
    Write-Host "  [c] Custom Path (or drag & drop any folder here)"
    Write-Host "  [x] Cancel"

    $sel = Read-PromptDefault -Prompt "`nSelect destination preset or drag & drop folder" -Default "0"

    if ($sel -eq "0") {
        return $repoRoot
    } elseif ($sel -match '^\d+$' -and [int]$sel -le $cartridges.Count) {
        $pick = $cartridges[[int]$sel - 1]
        return $pick.FullName
    } elseif ($sel -eq "x") {
        return $current
    } else {
        $candidate = Normalize-InputPath $sel
        if (Test-Path $candidate -PathType Container) {
            Write-Host "Switched to: $candidate" -ForegroundColor Green
            return $candidate
        } elseif (Test-Path $candidate -PathType Leaf) {
            $parent = Split-Path -Parent $candidate
            Write-Host "Switched to file parent folder: $parent" -ForegroundColor Green
            return $parent
        } else {
            Write-Host "Invalid folder path. Keeping current target." -ForegroundColor Yellow
            return $current
        }
    }
}

# Footer [h]: Help
function Show-HelpGuide {
    Write-Host "`n=== [h] GIT MANAGER HELP & SHORTCUTS ===" -ForegroundColor Cyan
    Write-Host @"
Universal Git Manager (ps_git-manage.ps1)
Designed for both the main workspace repository and standalone cartridge folders.

NUMERIC MENU (-1 to 9):
  [-1] Discard All Changes : Rollback all uncommitted changes and clean untracked files.
                             Protected with typed 'DISCARD' confirmation.
  [ 0] Status              : Live dashboard showing active branch, remotes, dirty files,
                             and recent commit log.
  [ 1] Recover             : Restores detached or lost commits from git reflog. Offers surgical
                             per-file overwrite or full commit restoration.
  [ 2] Commit              : Interactive status preview, staging options (All / Selective),
                             and a Conventional Commit prefix builder (feat, fix, docs, etc.).
  [ 3] Push                : Pushes current branch to remote with upstream tracking.
  [ 4] Pull / Sync         : Smart pull with linear rebase, fast-forward, or standard merge.
  [ 5] Assign Git          : Initializes Git repository, sets remote origin, generates
                             default .gitignore, and creates initial commit.
  [ 6] Remove Git          : 'Remove with more nicer' - unlocks ReadOnly and hidden attributes,
                             cleans locks, requires typed 'REMOVE' confirmation, and cleanly
                             deletes the .git folder leaving all project files intact.
  [ 7] Clone               : Clones a remote repository into target directory or subfolder.
  [ 8] Worktree            : Manages git worktrees for isolated parallel branch workflows.
  [ 9] Custom Shell / Script: Interactive shell inside target directory. Supports running
                             git/bash commands OR dragging & dropping any script (.ps1, .bat, etc.)

FOOTER CONTROLS:
  [ h] Help                : Display this guide.
  [ t] Switch Target       : Change working target directory (Root, apps/<app>, or drag & drop).
  [ q] Quit                : Exit tool.
"@ -ForegroundColor Gray
    Write-Host ""
}

# ------------------------------------------------------------------------------
# 3. DIRECT ACTION EXECUTION (If invoked via -Action parameter)
# ------------------------------------------------------------------------------
if (-not [string]::IsNullOrWhiteSpace($Action)) {
    switch ($Action.ToLower()) {
        "0"       { Invoke-StatusDashboard $currentTarget; exit }
        "status"  { Invoke-StatusDashboard $currentTarget; exit }
        "1"       { Invoke-Recover $currentTarget; exit }
        "recover" { Invoke-Recover $currentTarget; exit }
        "2"       { Invoke-Commit $currentTarget; exit }
        "commit"  { Invoke-Commit $currentTarget; exit }
        "3"       { Invoke-Push $currentTarget; exit }
        "push"    { Invoke-Push $currentTarget; exit }
        "4"       { Invoke-Pull $currentTarget; exit }
        "pull"    { Invoke-Pull $currentTarget; exit }
        "-1"      { Invoke-DiscardAll $currentTarget; exit }
        "discard" { Invoke-DiscardAll $currentTarget; exit }
        "5"       { Invoke-AssignGit $currentTarget; exit }
        "assign"  { Invoke-AssignGit $currentTarget; exit }
        "6"       { Invoke-RemoveGit $currentTarget; exit }
        "remove"  { Invoke-RemoveGit $currentTarget; exit }
        "7"       { Invoke-Clone $currentTarget; exit }
        "clone"   { Invoke-Clone $currentTarget; exit }
        "8"       { Invoke-Worktree $currentTarget; exit }
        "worktree"{ Invoke-Worktree $currentTarget; exit }
        "9"       { Invoke-CustomShell $currentTarget; exit }
        "shell"   { Invoke-CustomShell $currentTarget; exit }
        default {
            Write-Host "Unknown action: $Action" -ForegroundColor Red
        }
    }
}

# ------------------------------------------------------------------------------
# 4. MASTER INTERACTIVE MENU LOOP
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
    Write-Host ""
    Write-Host " ----------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ h ]  Help          : Panduan lengkap dan shortcut" -ForegroundColor Gray
    Write-Host "  [ t ]  Target Dir    : Ganti target (Root, apps/<cartridge>, Custom)" -ForegroundColor Gray
    Write-Host "  [ q ]  Quit          : Keluar" -ForegroundColor Gray
    Write-Host "========================================================================" -ForegroundColor Cyan

    $choice = Read-Host "Select option [-1 to 9, h, t, q] [Default: 0]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "0" }
    $choice = $choice.Trim()

    switch ($choice) {
        "-1" { Invoke-DiscardAll $currentTarget }
        "0"  { Invoke-StatusDashboard $currentTarget }
        "1"  { Invoke-Recover $currentTarget }
        "2"  { Invoke-Commit $currentTarget }
        "3"  { Invoke-Push $currentTarget }
        "4"  { Invoke-Pull $currentTarget }
        "5"  { Invoke-AssignGit $currentTarget }
        "6"  { Invoke-RemoveGit $currentTarget }
        "7"  { Invoke-Clone $currentTarget }
        "8"  { Invoke-Worktree $currentTarget }
        "9"  { Invoke-CustomShell $currentTarget }
        "h"  { Show-HelpGuide }
        "t"  { $currentTarget = Switch-TargetDirectory $currentTarget }
        "q"  {
            Write-Host "Exiting Git Manager. Happy coding lads!" -ForegroundColor Cyan
            break
        }
        default {
            # Check if user dragged & dropped a path directly onto the main menu prompt
            $cleanDropped = Normalize-InputPath $choice
            if (Test-Path $cleanDropped) {
                if (Test-Path $cleanDropped -PathType Container) {
                    $currentTarget = $cleanDropped
                    Write-Host "Target directory updated to: $currentTarget" -ForegroundColor Green
                } else {
                    $parent = Split-Path -Parent $cleanDropped
                    $currentTarget = $parent
                    Write-Host "Target directory updated to: $currentTarget" -ForegroundColor Green
                }
            } else {
                Write-Host "Invalid option '$choice'. Type 'h' for help." -ForegroundColor Yellow
            }
        }
    }
}
