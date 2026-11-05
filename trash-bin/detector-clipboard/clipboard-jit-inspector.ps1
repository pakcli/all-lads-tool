<#
.SYNOPSIS
    PolyClip Clipboard JIT Inspector (Zero-Sniffer Inspection Service)
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

function Get-ClipboardSnapshot {
    $rawType = "UNKNOWN"
    $rawText = $null
    $fileDropList = $null
    $detectedPath = $null

    try {
        if ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
            $fileDropList = [System.Windows.Forms.Clipboard]::GetFileDropList()
            if ($fileDropList -and $fileDropList.Count -gt 0) {
                $rawType = "CF_HDROP"
                $detectedPath = $fileDropList[0]
            }
        }
    } catch {}

    if (-not $detectedPath) {
        try {
            if ([System.Windows.Forms.Clipboard]::ContainsText()) {
                $rawText = [System.Windows.Forms.Clipboard]::GetText()
                if (-not [string]::IsNullOrWhiteSpace($rawText)) {
                    $rawType = "TEXT"
                }
            }
        } catch {}
    }

    if ($rawType -eq "TEXT" -and $rawText) {
        $cleaned = $rawText.Trim().Trim('"').Trim("'")
        if ($cleaned -match '^[a-zA-Z]:\\|^\\\\') {
            if (Test-Path -LiteralPath $cleaned) {
                $detectedPath = (Resolve-Path -LiteralPath $cleaned).Path
            }
        }
    }

    $fileName = "-"
    $fileSizeStr = "-"
    $isOpenable = $false
    $openStatus = "UNREADABLE"
    $mode1 = if ($rawText) { $rawText } elseif ($detectedPath) { $detectedPath } else { "" }
    $mode2 = if ($detectedPath) { $detectedPath } else { "" }
    $mode3 = ""
    $mode4 = if ($detectedPath) { $detectedPath } else { "" }

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
            } else {
                $fileName = $item.Name
                $openStatus = "DIRECTORY"
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
    }

    # Smart duplicate detection: checks if top history item already matches by path or text
    $isDuplicate = $false
    if ($global:PolyClipHistory.Count -gt 0) {
        $top = $global:PolyClipHistory[0]
        if ($snapshot.Mode2_Path -and $top.Mode2_Path -eq $snapshot.Mode2_Path) {
            $isDuplicate = $true
        } elseif ($snapshot.Mode1_Text -and $top.Mode1_Text -eq $snapshot.Mode1_Text) {
            $isDuplicate = $true
        }
    }

    if (-not $isDuplicate -and (-not [string]::IsNullOrWhiteSpace($snapshot.Mode1_Text) -or -not [string]::IsNullOrWhiteSpace($snapshot.Mode2_Path))) {
        # Filter out bogus PowerShell hash stringifications
        if (-not ($snapshot.Mode1_Text -like "@{value=*" -or $snapshot.Mode1_Text -like "@{Id=*")) {
            $global:PolyClipHistory.Insert(0, $snapshot)
            if ($global:PolyClipHistory.Count -gt 50) {
                $global:PolyClipHistory.RemoveAt(50)
            }
            Save-PersistentHistory
        }
    }

    return $snapshot
}
