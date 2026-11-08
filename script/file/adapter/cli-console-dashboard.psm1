<#
.SYNOPSIS
    PolyClip Terminal CLI Interactive Dashboard Adapter
.DESCRIPTION
    Renders high-fidelity ANSI terminal interface for quick CLI mode selection,
    status inspection, and clipboard history browsing.
#>

$script:esc = [char]27

function Render-CLI {
    param ($Snap, $Msg)

    $esc = $script:esc
    Write-Host -NoNewline "$esc[H"

    $pDisp = if ($Snap.DetectedPath) { [string]$Snap.DetectedPath } else { "(Pure Text Content)" }
    $pDisp = [string]$pDisp
    if ($pDisp.Length -gt 50) { $pDisp = "..." + $pDisp.Substring($pDisp.Length - 47) }

    $size = if ($Snap.FileSizeStr -ne "-") { [string]$Snap.FileSizeStr } else { "$([string]$Snap.Mode1_Text.Length) chars" }

    $openBadge = if ($Snap.IsOpenable) {
        "$esc[32m[OK] OPENABLE (.md/code/text)$esc[0m"
    } else {
        "$esc[31m[?] UNREADABLE / BINARY$esc[0m"
    }

    $histLines = @()
    $limit = [math]::Min(3, $global:PolyClipHistory.Count)
    for ($i = 0; $i -lt $limit; $i++) {
        $h = $global:PolyClipHistory[$i]
        $tag = if ($h.IsOpenable) { "$esc[32m[OK]$esc[0m" } else { "$esc[31m[?]$esc[0m" }
        $label = if ($h.FileName -ne "-") { [string]$h.FileName } else { [string]$h.Mode1_Text }
        $label = [string]$label
        if ($label.Length -gt 34) { $label = $label.Substring(0, 31) + "..." }
        $histLines += "|  $($h.Timestamp.PadRight(10)) $tag $($h.RawType.PadRight(15)) : $($label.PadRight(35))|"
    }
    while ($histLines.Count -lt 3) {
        $histLines += "|  (empty)                                                           |"
    }

    $modesBlock = if ($Snap.IsGitRepo) {
@"
| GIT PROTOCOL DETECTED: $($Snap.GitSlug.PadRight(42))|
|  [1] HTTPS      : $($Snap.GitHttpsUrl.PadRight(47))|
|  [2] SSH        : $($Snap.GitSshUrl.PadRight(47))|
|  [3] GitHub CLI : $($Snap.GitGhCli.PadRight(47))|
|  [4] Git Clone  : $($Snap.GitCloneCmd.PadRight(47))|
"@
    } else {
@"
| MODES AVAILABLE TO APPLY:                                          |
|  [1] PLAIN TEXT (raw string to clipboard)                         |
|  [2] FILE PATH  (resolved disk path string)                       |
|  [3] CONTENT    (first 15 chars preview -> full script buffer)    |
|  [4] EXACT FILE (CF_HDROP explorer pasteable file drop)            |
"@
    }

    $out = @"
$esc[2J$esc[H+--------------------------------------------------------------------+
|                POLYCLIP CLI - 4-MODE CLIPBOARD SUITE               |
+--------------------------------------------------------------------+
| Time: $($Snap.Timestamp.PadRight(10)) Type: $($Snap.RawType.PadRight(15)) Size: $($size.PadRight(15))   |
| Status: $($openBadge.PadRight(50))     |
| Target: $($pDisp.PadRight(55))|
+--------------------------------------------------------------------+
$modesBlock
+--------------------------------------------------------------------+
| RECENT HISTORY:                                                    |
$($histLines[0])
$($histLines[1])
$($histLines[2])
+--------------------------------------------------------------------+
| COMMANDS: [1-4] Apply Mode | [P] Open Panel | [SPACE] Refresh | [Q] |
+--------------------------------------------------------------------+
Status: $Msg
"@
    Write-Host $out
}




