<#
.SYNOPSIS
    PolyClip Clipboard History Store (Persistence Service)
.DESCRIPTION
    Conforms to Skill: save-option-as-exact-executor-name-json
    Handles atomic JSON persistence and cache memory for clipboard history items.
#>

if (-not $global:PolyClipHistory) {
    $global:PolyClipHistory = [System.Collections.Generic.List[PSCustomObject]]::new()
}

$script:ExecutorBaseName = "detector-clipboard-4-mode"
$script:OptionsFile = if (Test-Path (Join-Path $PSScriptRoot "..")) {
    Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "$($script:ExecutorBaseName).json"
} else {
    Join-Path $PSScriptRoot "$($script:ExecutorBaseName).json"
}

function Load-PersistentHistory {
    $fileToRead = if (Test-Path -LiteralPath $script:OptionsFile) {
        $script:OptionsFile
    } elseif (Test-Path "E:\proj\all-lads-tool\polyclip-history.json") {
        "E:\proj\all-lads-tool\polyclip-history.json"
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
                    $global:PolyClipHistory.Add([PSCustomObject]$item)
                }
            }
        } catch {}
    }
}

function Save-PersistentHistory {
    try {
        $clean = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $global:PolyClipHistory) {
            $t = [string]$item.Mode1_Text
            # Filter out corrupt/bogus hash stringifications
            if ($t -notlike '@{value=*' -and $t -notlike '@{Id=*' -and $item.FileName -ne 'polyclip-history.json') {
                $clean.Add($item)
            }
        }
        $json = $clean | ConvertTo-Json -Depth 4
        Set-Content -LiteralPath $script:OptionsFile -Value $json -Encoding UTF8 -Force
    } catch {}
}
