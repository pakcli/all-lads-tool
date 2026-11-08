<#
.SYNOPSIS
    PolyClip Clipboard JIT Inspector (Zero-Sniffer Inspection Service Adapter)
.DESCRIPTION
    Inspects Windows OS clipboard on demand (JIT) for CF_HDROP and TEXT formats,
    detects physical file attributes, and parses text previews.
#>

function Test-IsFileOpenableText {
    param ([string]$FilePath)

    if (-not (Test-Path -LiteralPath $FilePath)) { return $false }
    try {
        $item = Get-Item -LiteralPath $FilePath -ErrorAction Stop
        if ($item -isnot [System.IO.FileInfo]) { return $false }
        if ($item.Length -gt 5MB) { return $false }

        $openableExts = @(
            ".txt", ".md", ".json", ".csv", ".ps1", ".psm1", ".bat", ".cmd",
            ".py", ".js", ".ts", ".html", ".css", ".scss", ".xml", ".yaml", ".yml",
            ".ini", ".cfg", ".log", ".env", ".cs", ".cpp", ".c", ".h", ".rs", ".go"
        )
        if ($openableExts -contains $item.Extension.ToLower()) {
            return $true
        }

        # Sample first 512 bytes for null byte inspection
        $bytes = [System.IO.File]::ReadAllBytes($item.FullName)
        $sampleLen = [math]::Min($bytes.Length, 512)
        for ($i = 0; $i -lt $sampleLen; $i++) {
            if ($bytes[$i] -eq 0) { return $false }
        }
        return $true
    } catch {
        return $false
    }
}

function Format-FileSize {
    param ([long]$Bytes)
    if ($Bytes -lt 1KB) { return "$Bytes B" }
    if ($Bytes -lt 1MB) { return "{0:N1} KB" -f ($Bytes / 1KB) }
    if ($Bytes -lt 1GB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    return "{0:N1} GB" -f ($Bytes / 1GB)
}

function Get-First15Chars {
    param ([string]$Content)
    if ([string]::IsNullOrWhiteSpace($Content)) { return "-" }
    
    $lines = $Content -split "\r?\n"
    $firstLine = ""
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
            $firstLine = $trimmed
            break
        }
    }
    if ([string]::IsNullOrWhiteSpace($firstLine)) { return "-" }

    if ($firstLine.Length -gt 15) {
        return $firstLine.Substring(0, 15) + "..."
    }
    return $firstLine
}

function Clean-PlainText {
    param ([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return "" }
    $t = Unwrap-Mode1Text $Text
    $t = $t.Trim()
    # Strip wrapping quotes if user copied "something"
    if (($t.StartsWith('"') -and $t.EndsWith('"')) -or ($t.StartsWith("'") -and $t.EndsWith("'"))) {
        if ($t.Length -ge 2) {
            $t = $t.Substring(1, $t.Length - 2).Trim()
        }
    }
    return $t
}

function Convert-ToGitRepoInfo {
    param ([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }

    $val = Clean-PlainText $Raw

    # Strip command prefixes if present
    if ($val -match 'gh\s+repo\s+clone\s+(?<repo>\S+)') {
        $val = $Matches['repo'].Trim()
    } elseif ($val -match 'git\s+clone\s+(?<url>\S+)') {
        $val = $Matches['url'].Trim()
    }

    $owner = $null
    $repo = $null
    $host = "github.com"

    # HTTPS format: https://github.com/owner/repo(.git)? or http://
    if ($val -match '^https?:\/\/(?<host>[^\/]+)\/(?<owner>[^\/]+)\/(?<repo>[^\/\s\?#]+?)(\.git)?(\/)?$') {
        $host = $Matches['host']
        $owner = $Matches['owner']
        $repo = $Matches['repo']
    }
    # SSH format: git@github.com:owner/repo(.git)?
    elseif ($val -match '^git@(?<host>[^:]+):(?<owner>[^\/]+)\/(?<repo>[^\/\s\?#]+?)(\.git)?(\/)?$') {
        $host = $Matches['host']
        $owner = $Matches['owner']
        $repo = $Matches['repo']
    }
    # Short slug format: owner/repo (e.g. pakcli/absolute-home-inventory)
    elseif ($val -match '^(?<owner>[a-zA-Z0-9_\-\.]+)\/(?<repo>[a-zA-Z0-9_\-\.]+)$' -and $val -notmatch '^[a-zA-Z]:') {
        $owner = $Matches['owner']
        $repo = $Matches['repo']
    }

    if ($owner -and $repo) {
        $repoClean = $repo -replace '\.git$', ''
        $slug = "$owner/$repoClean"
        $httpsUrl = "https://$host/$slug.git"
        $sshUrl = "git@$host`:$slug.git"
        $ghCli = "gh repo clone $slug"
        $cloneCmd = "git clone $httpsUrl"

        return [PSCustomObject]@{
            IsGitRepo = $true
            Host      = $host
            Owner     = $owner
            Repo      = $repoClean
            Slug      = $slug
            HttpsUrl  = $httpsUrl
            SshUrl    = $sshUrl
            GhCli     = $ghCli
            CloneCmd  = $cloneCmd
        }
    }
    return $null
}

function Convert-ToNativePath {
    param ([string]$Raw)
    if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }

    $val = $Raw.Trim()

    # 1. Unquote if wrapped in quotes
    if (($val.StartsWith('"') -and $val.EndsWith('"')) -or ($val.StartsWith("'") -and $val.EndsWith("'"))) {
        if ($val.Length -ge 2) {
            $val = $val.Substring(1, $val.Length - 2).Trim()
        }
    }

    # 2. Advance Path format: (file;file:///e%3A/proj/...)
    if ($val -match '^\(file;file:\/\/\/?(?<inner>.+?)\)$') {
        $val = "file:///" + $Matches['inner']
    }

    # 3. URI format: file:///... or file://...
    if ($val -match '^file:\/\/\/?(?<uriPath>.+)$') {
        $uPath = $Matches['uriPath']
        $uPath = [System.Text.RegularExpressions.Regex]::Replace($uPath, '(?i)%3A', ':')
        try {
            $uPath = [System.Uri]::UnescapeDataString($uPath)
        } catch {}
        if ($uPath -match '^\/([a-zA-Z]:.*)$') {
            $uPath = $Matches[1]
        }
        $val = $uPath
    }

    # Normalize forward slashes to Windows backslashes
    $norm = $val.Replace('/', '\')

    # 4. Check absolute path
    if ($norm -match '^[a-zA-Z]:\\|^\\\\') {
        if (Test-Path -LiteralPath $norm) {
            return (Resolve-Path -LiteralPath $norm).Path
        }
    }

    # 5. Check relative path against current directory and workspace root
    $candidateBases = @(
        (Get-Location).Path,
        $PSScriptRoot,
        (Split-Path -Parent $PSScriptRoot),
        (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
        (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique

    foreach ($base in $candidateBases) {
        if ($base -and (Test-Path -LiteralPath $base)) {
            $combined = Join-Path $base $norm
            if (Test-Path -LiteralPath $combined) {
                return (Resolve-Path -LiteralPath $combined).Path
            }
        }
    }

    return $null
}

function Extract-PathsFromDataObject {
    param ($DataObject)
    $detected = @()
    if ($null -eq $DataObject) { return $detected }

    # 1. Standard FileDrop (CF_HDROP)
    try {
        if ($DataObject.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
            $files = $DataObject.GetData([System.Windows.Forms.DataFormats]::FileDrop)
            if ($files) {
                foreach ($f in $files) {
                    $p = Convert-ToNativePath ([string]$f)
                    if ($p -and $p -notin $detected) { $detected += $p }
                }
            }
        }
    } catch {}

    # 2. Windows Shell FileNameW / FileName
    if ($detected.Count -eq 0) {
        try {
            if ($DataObject.GetDataPresent("FileNameW")) {
                $fn = $DataObject.GetData("FileNameW")
                if ($fn) {
                    $p = Convert-ToNativePath ([string]$fn)
                    if ($p -and $p -notin $detected) { $detected += $p }
                }
            } elseif ($DataObject.GetDataPresent("FileName")) {
                $fn = $DataObject.GetData("FileName")
                if ($fn) {
                    $p = Convert-ToNativePath ([string]$fn)
                    if ($p -and $p -notin $detected) { $detected += $p }
                }
            }
        } catch {}
    }

    # 3. text/uri-list (Electron & VS Code standard)
    if ($detected.Count -eq 0) {
        try {
            if ($DataObject.GetDataPresent("text/uri-list")) {
                $uriData = $DataObject.GetData("text/uri-list")
                if ($uriData) {
                    $lines = [string]$uriData -split "`r?`n"
                    foreach ($l in $lines) {
                        if (-not [string]::IsNullOrWhiteSpace($l) -and -not $l.StartsWith("#")) {
                            $p = Convert-ToNativePath $l
                            if ($p -and $p -notin $detected) { $detected += $p }
                        }
                    }
                }
            }
        } catch {}
    }

    # 4. Custom VS Code internal buffer formats (code/resources, NativeClipboardService.FILE_FORMAT)
    if ($detected.Count -eq 0) {
        try {
            $formats = $DataObject.GetFormats()
            foreach ($fmt in $formats) {
                if ($fmt -like "*code*" -or $fmt -like "*resource*" -or $fmt -like "*file*" -or $fmt -like "*uri*") {
                    $rawFmt = $DataObject.GetData($fmt)
                    if ($rawFmt) {
                        $str = if ($rawFmt -is [string]) { $rawFmt }
                               elseif ($rawFmt -is [System.IO.MemoryStream]) {
                                   (New-Object System.IO.StreamReader($rawFmt)).ReadToEnd()
                               } elseif ($rawFmt -is [byte[]]) {
                                   [System.Text.Encoding]::UTF8.GetString($rawFmt)
                               } else { $null }
                        if ($str) {
                            $matches = [System.Text.RegularExpressions.Regex]::Matches($str, '(file:\/\/\/[^\s"\''\<\>\)]+|[a-zA-Z]:\\[^\s"\''\<\>\r\n]+|[a-zA-Z]:\/[^\s"\''\<\>\r\n]+)')
                            foreach ($m in $matches) {
                                $p = Convert-ToNativePath $m.Value
                                if ($p -and $p -notin $detected) { $detected += $p }
                            }
                        }
                    }
                }
            }
        } catch {}
    }

    return $detected
}

function Get-ClipboardSnapshot {
    $rawType = "UNKNOWN"
    $rawText = $null
    $fileDropList = $null
    $detectedPath = $null

    # Phase 1: Deep inspection of DataObject (CF_HDROP, FileNameW, text/uri-list, VS Code code/resources)
    try {
        $dataObj = [System.Windows.Forms.Clipboard]::GetDataObject()
        if ($dataObj) {
            $paths = Extract-PathsFromDataObject -DataObject $dataObj
            if ($paths -and $paths.Count -gt 0) {
                $rawType = "CF_HDROP"
                $detectedPath = $paths[0]
            }
        }
    } catch {}

    # Phase 2: Direct WinForms FileDropList fallback
    if (-not $detectedPath) {
        try {
            if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
                $fileDropList = [System.Windows.Forms.Clipboard]::GetFileDropList()
                if ($fileDropList -and $fileDropList.Count -gt 0) {
                    $rawType = "CF_HDROP"
                    $detectedPath = $fileDropList[0]
                }
            }
        } catch {}
    }

    # Phase 3: Text inspection (handles VS Code Copy Path, Copy Relative Path, Advance Path, quoted paths)
    try {
        if ([System.Windows.Forms.Clipboard]::ContainsText()) {
            $rawInput = [System.Windows.Forms.Clipboard]::GetText()
            if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
                $cleanedText = Clean-PlainText $rawInput
                if (-not [string]::IsNullOrWhiteSpace($cleanedText)) {
                    $rawText = $cleanedText
                    if ($rawType -eq "UNKNOWN") {
                        $rawType = "TEXT"
                    }
                    if (-not $detectedPath) {
                        # Check if text is a single path or multiline paths
                        $lines = $rawText -split "`r?`n" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
                        foreach ($line in $lines) {
                            $resolved = Convert-ToNativePath $line
                            if ($resolved) {
                                $detectedPath = $resolved
                                $rawType = "CF_HDROP"
                                break
                            }
                        }
                    }
                }
            }
        }
    } catch {}

    $fileName = "-"
    $fileSizeStr = "-"
    $isOpenable = $false
    $openStatus = "UNREADABLE"

    # Git Repository URL Detection (mirrors GitHub clone widget: HTTPS, SSH, GitHub CLI)
    $gitInfo = if ($rawText) { Convert-ToGitRepoInfo $rawText } else { $null }

    if ($gitInfo) {
        $rawType = "GIT_REPO"
        $fileName = "$($gitInfo.Slug) (GitHub)"
        $fileSizeStr = "<GIT>"
        $isOpenable = $true
        $openStatus = "GIT_REPO"
        $mode1 = $gitInfo.HttpsUrl
        $mode2 = $gitInfo.SshUrl
        $mode3 = $gitInfo.GhCli
        $mode4 = $gitInfo.CloneCmd
    } else {
        $mode1 = if ($rawText) { $rawText } elseif ($detectedPath) { (Split-Path $detectedPath -Leaf) } else { "" }
        $mode2 = if ($detectedPath) { $detectedPath } else { "" }
        $mode3 = ""
        $mode4 = if ($detectedPath) { $detectedPath } else { "" }
    }

    if ($detectedPath -and (Test-Path -LiteralPath $detectedPath)) {
        try {
            $item = Get-Item -LiteralPath $detectedPath -ErrorAction SilentlyContinue
            if ($item -is [System.IO.FileInfo]) {
                $fileName = $item.Name
                $fileSizeStr = Format-FileSize -Bytes $item.Length

                if (Test-IsFileOpenableText -FilePath $item.FullName) {
                    $isOpenable = $true
                    $openStatus = "OPENABLE"
                    try {
                        $mode3 = Get-Content -LiteralPath $item.FullName -Raw -Encoding UTF8 -ErrorAction Stop
                    } catch {
                        $mode3 = [System.IO.File]::ReadAllText($item.FullName)
                    }
                } else {
                    $openStatus = "BINARY"
                }
            } elseif ($item -is [System.IO.DirectoryInfo]) {
                $fileName = $item.Name
                $fileSizeStr = "<DIR>"
                $isOpenable = $true
                $openStatus = "DIRECTORY"
                $mode3 = "[Directory] " + $item.FullName
            }
        } catch {
            $openStatus = "ACCESS_ERROR"
        }
    }

    $snapshot = [PSCustomObject]@{
        Id            = [guid]::NewGuid().ToString().Substring(0, 6)
        Timestamp     = (Get-Date -Format "HH:mm:ss")
        RawType       = $rawType
        DetectedPath  = $detectedPath
        FileName      = $fileName
        FileSizeStr   = $fileSizeStr
        IsOpenable    = $isOpenable
        OpenStatus    = $openStatus
        Mode1_Text    = $mode1
        Mode2_Path    = $mode2
        Mode3_Content = $mode3
        Mode4_File    = $mode4
        IsGitRepo     = ($null -ne $gitInfo)
        GitOwner      = if ($gitInfo) { $gitInfo.Owner } else { "" }
        GitRepo       = if ($gitInfo) { $gitInfo.Repo } else { "" }
        GitSlug       = if ($gitInfo) { $gitInfo.Slug } else { "" }
        GitHttpsUrl   = if ($gitInfo) { $gitInfo.HttpsUrl } else { "" }
        GitSshUrl     = if ($gitInfo) { $gitInfo.SshUrl } else { "" }
        GitGhCli      = if ($gitInfo) { $gitInfo.GhCli } else { "" }
        GitCloneCmd   = if ($gitInfo) { $gitInfo.CloneCmd } else { "" }
    }

    # Tracking & Deduplication (Prevents runaway feedback loops)
    if ($null -eq $global:PolyClipLastRawText) { $global:PolyClipLastRawText = "" }
    if ($null -eq $global:PolyClipLastPath)    { $global:PolyClipLastPath    = "" }

    $isDuplicate = $false
    if ($rawType -eq "TEXT" -and $rawText -and $rawText -eq $global:PolyClipLastRawText) {
        $isDuplicate = $true
    } elseif ($detectedPath -and $detectedPath -eq $global:PolyClipLastPath) {
        $isDuplicate = $true
    } elseif ($global:PolyClipHistory.Count -gt 0) {
        $top = $global:PolyClipHistory[0]
        if ($snapshot.Mode2_Path -and $top.Mode2_Path -eq $snapshot.Mode2_Path) {
            $isDuplicate = $true
        } elseif ($snapshot.Mode1_Text -and $top.Mode1_Text -eq $snapshot.Mode1_Text) {
            $isDuplicate = $true
        }
    }

    if (-not $isDuplicate -and (-not [string]::IsNullOrWhiteSpace($snapshot.Mode1_Text) -or -not [string]::IsNullOrWhiteSpace($snapshot.Mode2_Path))) {
        # Strict filter: Never store stringified PowerShell hash dumps
        $isBogus = ($snapshot.Mode1_Text -like "*[string]@*" -or $snapshot.Mode1_Text -like "@{value=*" -or $snapshot.Mode1_Text -like "@{Id=*" -or $snapshot.Mode1_Text -like "*; Timestamp=*")
        if (-not $isBogus) {
            $global:PolyClipLastRawText = [string]$snapshot.Mode1_Text
            $global:PolyClipLastPath    = [string]$snapshot.Mode2_Path
            $global:PolyClipHistory.Insert(0, $snapshot)
            if ($global:PolyClipHistory.Count -gt 50) {
                $global:PolyClipHistory.RemoveAt(50)
            }
            Save-PersistentHistory
        }
    }

    return $snapshot
}



