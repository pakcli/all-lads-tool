<#
.SYNOPSIS
    PolyClip Clipboard History Store (Persistence Service Adapter)
.DESCRIPTION
    Conforms to Skill: save-option-as-exact-executor-name-json
    Handles atomic JSON persistence and cache memory for clipboard history items.
#>

if (-not $global:PolyClipHistory) {
    $global:PolyClipHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
}

$script:ExecutorBaseName = "detector-clipboard-4-mode"
$baseDir = if ($PSScriptRoot) { $PSScriptRoot } else { "E:\proj\all-lads-tool\script\file\adapter" }
$parentDir = Split-Path $baseDir -Parent
$script:OptionsFile = if (Test-Path (Join-Path $parentDir "$($script:ExecutorBaseName).json")) {
    Join-Path $parentDir "$($script:ExecutorBaseName).json"
} elseif (Test-Path (Join-Path $baseDir "$($script:ExecutorBaseName).json")) {
    Join-Path $baseDir "$($script:ExecutorBaseName).json"
} else {
    Join-Path $parentDir "$($script:ExecutorBaseName).json"
}

function Unwrap-Mode1Text {
    param ([string]$InputText)
    if ([string]::IsNullOrWhiteSpace($InputText)) { return $InputText }
    if ($InputText -match '(?s)Mode1_Text=(.*?)(?:;\s*[a-zA-Z0-9_]+=\s*|\}\s*(?:\.Mode1_Text)?\s*$)') {
        $extracted = $matches[1].Trim()
        if (-not [string]::IsNullOrWhiteSpace($extracted)) {
            return $extracted
        }
    }
    return $InputText
}

function Load-PersistentHistory {
    $fileToRead = if (Test-Path -LiteralPath $script:OptionsFile) {
        $script:OptionsFile
    } elseif (Test-Path "E:\proj\all-lads-tool\script\file\detector-clipboard-4-mode.json") {
        "E:\proj\all-lads-tool\script\file\detector-clipboard-4-mode.json"
    } else {
        $null
    }

    if ($fileToRead) {
        try {
            $raw = Get-Content -LiteralPath $fileToRead -Raw -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                $list = $raw | ConvertFrom-Json
                $global:PolyClipHistory.Clear()
                foreach ($item in $list) {
                    $obj = [PSCustomObject]$item
                    if ($obj.Mode1_Text) {
                        $obj.Mode1_Text = Unwrap-Mode1Text -InputText [string]$obj.Mode1_Text
                    }
                    $global:PolyClipHistory.Add($obj)
                }
            }
        } catch {}
    }
}

function Save-PersistentHistory {
    try {
        $clean = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $global:PolyClipHistory) {
            $t = Unwrap-Mode1Text -InputText [string]$item.Mode1_Text
            $item.Mode1_Text = $t
            # Filter out corrupt/bogus hash stringifications if unwrap was not possible
            if ($t -notlike '@{value=*' -and $t -notlike '@{Id=*' -and $item.FileName -ne 'polyclip-history.json') {
                $clean.Add($item)
            }
        }
        $json = $clean | ConvertTo-Json -Depth 4
        Set-Content -LiteralPath $script:OptionsFile -Value $json -Encoding UTF8 -Force
    } catch {}
}




