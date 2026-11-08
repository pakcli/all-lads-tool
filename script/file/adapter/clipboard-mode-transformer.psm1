<#
.SYNOPSIS
    PolyClip Clipboard Mode Transformer & Dispatcher Adapter
.DESCRIPTION
    Converts clipboard snapshot objects into 4 discrete OS clipboard modes:
    - Mode 1: Plain Text
    - Mode 2: File Path String
    - Mode 3: Text Content Stream
    - Mode 4: CF_HDROP File Drop List
    Enforces anti-feedback loop guardrail ($script:suppressLiveCaptureUntil).
#>

function Invoke-ApplyMode {
    param (
        [int]$TargetMode,
        [PSCustomObject]$Snapshot
    )

    if (-not $Snapshot) { return "No snapshot provided." }

    # Suppress live watcher to prevent capturing internal PolyClip copy actions
    $global:PolyClipSuppressUntil = [DateTime]::UtcNow.AddMilliseconds(3000)

    switch ($TargetMode) {
        1 {
            if ($Snapshot.IsGitRepo -and $Snapshot.GitHttpsUrl) {
                $val = [string]$Snapshot.GitHttpsUrl
                $global:PolyClipLastRawText = $val
                try { Set-Clipboard -Value $val } catch { [System.Windows.Forms.Clipboard]::SetText($val) }
                return "Applied Mode 1 (Git HTTPS Clone URL: $val)"
            }
            if ($Snapshot.Mode1_Text) {
                $val = Clean-PlainText [string]$Snapshot.Mode1_Text
                $global:PolyClipLastRawText = $val
                try { Set-Clipboard -Value $val } catch { [System.Windows.Forms.Clipboard]::SetText($val) }
                return "Applied Mode 1 (Plain Text)"
            }
        }
        2 {
            if ($Snapshot.IsGitRepo -and $Snapshot.GitSshUrl) {
                $val = [string]$Snapshot.GitSshUrl
                $global:PolyClipLastRawText = $val
                try { Set-Clipboard -Value $val } catch { [System.Windows.Forms.Clipboard]::SetText($val) }
                return "Applied Mode 2 (Git SSH Clone URL: $val)"
            }
            if ($Snapshot.Mode2_Path -and (Test-Path -LiteralPath $Snapshot.Mode2_Path)) {
                $val = [string]$Snapshot.Mode2_Path
                $global:PolyClipLastRawText = $val
                try { Set-Clipboard -Value $val } catch { [System.Windows.Forms.Clipboard]::SetText($val) }
                return "Applied Mode 2 (File Path)"
            }
            return "Mode 2 Blocked: File no longer exists on disk."
        }
        3 {
            if ($Snapshot.IsGitRepo -and $Snapshot.GitGhCli) {
                $val = [string]$Snapshot.GitGhCli
                $global:PolyClipLastRawText = $val
                try { Set-Clipboard -Value $val } catch { [System.Windows.Forms.Clipboard]::SetText($val) }
                return "Applied Mode 3 (GitHub CLI Clone Command: $val)"
            }
            if ($Snapshot.IsOpenable -and $Snapshot.Mode3_Content) {
                $val = if ($Snapshot.Mode3_Content -is [string]) { $Snapshot.Mode3_Content } elseif ($Snapshot.Mode3_Content.value) { [string]$Snapshot.Mode3_Content.value } else { [string]$Snapshot.Mode3_Content }
                $global:PolyClipLastRawText = $val
                try { Set-Clipboard -Value $val } catch { [System.Windows.Forms.Clipboard]::SetText($val) }
                return "Applied Mode 3 (File Content)"
            }
            return "Mode 3 Blocked (? Binary or Unreadable)"
        }
        4 {
            if ($Snapshot.IsGitRepo -and $Snapshot.GitCloneCmd) {
                $val = [string]$Snapshot.GitCloneCmd
                $global:PolyClipLastRawText = $val
                try { Set-Clipboard -Value $val } catch { [System.Windows.Forms.Clipboard]::SetText($val) }
                return "Applied Mode 4 (Git Clone CLI Command: $val)"
            }
            if ($Snapshot.Mode4_File -and (Test-Path -LiteralPath $Snapshot.Mode4_File)) {
                $sc = New-Object System.Collections.Specialized.StringCollection
                $sc.Add([string]$Snapshot.Mode4_File) | Out-Null
                $global:PolyClipLastPath = [string]$Snapshot.Mode4_File
                [System.Windows.Forms.Clipboard]::SetFileDropList($sc)
                return "Applied Mode 4 (CF_HDROP File Drop)"
            }
            return "Mode 4 Blocked: File no longer exists on disk."
        }
    }
    return "Mode $TargetMode could not be applied."
}

function Promote-ToFirst {
    param ($Item)
    if (-not $Item) { return $null }

    # Suppress live watcher to avoid double-capturing PolyClip's own clipboard write
    $global:PolyClipSuppressUntil = [DateTime]::UtcNow.AddMilliseconds(3000)

    $cleanMode1 = Clean-PlainText [string]$Item.Mode1_Text

    $dup = [PSCustomObject]@{
        Id            = [guid]::NewGuid().ToString().Substring(0, 6)
        Timestamp     = (Get-Date -Format "HH:mm:ss")
        RawType       = $Item.RawType
        DetectedPath  = $Item.DetectedPath
        FileName      = $Item.FileName
        FileSizeStr   = $Item.FileSizeStr
        IsOpenable    = $Item.IsOpenable
        OpenStatus    = $Item.OpenStatus
        Mode1_Text    = $cleanMode1
        Mode2_Path    = $Item.Mode2_Path
        Mode3_Content = $Item.Mode3_Content
        Mode4_File    = $Item.Mode4_File
    }
    $global:PolyClipHistory.Insert(0, $dup)
    if ($global:PolyClipHistory.Count -gt 50) {
        $global:PolyClipHistory.RemoveAt(50)
    }
    Save-PersistentHistory

    if ($dup.RawType -eq "CF_HDROP" -and $dup.Mode4_File -and (Test-Path -LiteralPath $dup.Mode4_File)) {
        try {
            $sc = New-Object System.Collections.Specialized.StringCollection
            $sc.Add([string]$dup.Mode4_File) | Out-Null
            $global:PolyClipLastPath = [string]$dup.Mode4_File
            [System.Windows.Forms.Clipboard]::SetFileDropList($sc)
        } catch {}
    } else {
        $clipVal = if ($dup.IsOpenable -and $dup.Mode3_Content) {
            if ($dup.Mode3_Content -is [string]) { $dup.Mode3_Content } elseif ($dup.Mode3_Content.value) { [string]$dup.Mode3_Content.value } else { [string]$dup.Mode3_Content }
        } elseif ($dup.Mode2_Path -and $dup.Mode2_Path -ne "-") {
            $dup.Mode2_Path
        } else {
            $cleanMode1
        }
        $isBogus = ($clipVal -like "*[string]@*" -or $clipVal -like "@{value=*" -or $clipVal -like "@{Id=*" -or $clipVal -like "*; Timestamp=*")
        if ($clipVal -and -not $isBogus) {
            $global:PolyClipLastRawText = [string]$clipVal
            try {
                Set-Clipboard -Value ([string]$clipVal)
            } catch {
                try { [System.Windows.Forms.Clipboard]::SetText([string]$clipVal) } catch {}
            }
        }
    }
    return $dup
}




