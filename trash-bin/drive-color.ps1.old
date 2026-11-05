<#
.SYNOPSIS
    PolyClip Drive Color-Coding Protocol Standard
.DESCRIPTION
    Maps filesystem paths and drive letters to visual color codes:
    - C: -> Red (#F87171) for System / "fistem"
    - D: -> Blue (#38BDF8) for Secondary Data Drive
    - E: or higher -> Green (#34D399) for Projects, Workspace, and Removables
    - UNC / Network / Other -> Indigo (#818CF8)
#>

function Get-DriveColorHex {
    param ([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "#A1A1AA" }
    
    if ($Path -match '^([a-zA-Z]):') {
        $letter = $matches[1].ToUpper()
        switch ($letter) {
            'C' { return "#F87171" } # Red for System (fistem)
            'D' { return "#38BDF8" } # Blue for D
            default {
                if ($letter -ge 'E') {
                    return "#34D399" # Green for E or more (E, F, G, ...)
                } else {
                    return "#FBBF24" # Amber for A / B
                }
            }
        }
    }
    return "#818CF8" # Indigo for UNC or relative
}
