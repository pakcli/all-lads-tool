<#
.SYNOPSIS
    PolyClip Drive Color-Coding Protocol Adapter
.DESCRIPTION
    Maps storage paths and drive letters to the standardized dark-theme visual color hierarchy:
    - C:      -> Red     (#F87171) [System / Fistem]
    - D:      -> Blue    (#38BDF8) [Data Secondary]
    - E: or + -> Green   (#34D399) [Projects / Workspace / External]
    - UNC / * -> Indigo  (#818CF8) [Network Share / Relative]
#>

function Get-DriveColorHex {
    param ([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "#A1A1AA" }
    $p = $Path.Trim().Trim('"').Trim("'")

    if ($p -match '^([a-zA-Z]):') {
        $letter = $matches[1].ToUpper()
        switch ($letter) {
            "C" { return "#F87171" } # Red-400 (System / Fistem)
            "D" { return "#38BDF8" } # Sky-400 (Secondary Data)
            default {
                # E or higher (E:, F:, G:, etc.) -> Green
                return "#34D399"     # Emerald-400 (Projects / Workspace)
            }
        }
    }
    
    if ($p -match '^\\\\') {
        return "#818CF8" # Indigo-400 (Network / UNC Path)
    }

    return "#34D399" # Default fallback
}




