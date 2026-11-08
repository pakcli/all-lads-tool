<#
.SYNOPSIS
    PolyClip 4-Mode Clipboard Adapter (Flat Facade)
.DESCRIPTION
    Conforms strictly to Brief v01-03: Foldering Structure & Anti-Generic Core-Engine Protocol.
    All adapter sub-components are flattened directly inside adapter/ as .psm1 modules:
      - clipboard-history-store.psm1     : Persistence Service & Cache Store
      - clipboard-jit-inspector.psm1     : On-demand Inspection & Text Parsing
      - clipboard-mode-transformer.psm1 : 4-Mode Clipboard Dispatcher & Loop Prevention
      - drive-color-protocol.psm1       : Drive Hierarchy Color System (C: Red, D: Blue, E:+ Green)
      - ui-card-renderer.psm1           : WPF Row Cards, Accordions & Action Buttons
      - panel-window-host.psm1          : WPF Window Host, XAML & Live Timer
      - cli-console-dashboard.psm1      : Terminal CLI Dashboard
#>

# Load Required .NET GUI & Clipboard Assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Windows.Forms, System.Drawing -ErrorAction SilentlyContinue

# Dot-source all flattened adapter sub-modules into this module session scope
$subModules = @(
    "clipboard-history-store.psm1",
    "clipboard-jit-inspector.psm1",
    "clipboard-mode-transformer.psm1",
    "drive-color-protocol.psm1",
    "ui-card-renderer.psm1",
    "panel-window-host.psm1",
    "cli-console-dashboard.psm1"
)

foreach ($mod in $subModules) {
    $modPath = Join-Path $PSScriptRoot $mod
    if (Test-Path -LiteralPath $modPath) {
        $raw = [System.IO.File]::ReadAllText($modPath, [System.Text.Encoding]::UTF8)
        $sb = [scriptblock]::Create($raw)
        . $sb
    }
}

# Export all public adapter functions
Export-ModuleMember -Function @(
    "Get-ClipboardSnapshot",
    "Convert-ToNativePath",
    "Convert-ToGitRepoInfo",
    "Extract-PathsFromDataObject",
    "Invoke-ApplyMode",
    "Promote-ToFirst",
    "Load-PersistentHistory",
    "Save-PersistentHistory",
    "Unwrap-Mode1Text",
    "Clean-PlainText",
    "Show-LightweightPanel",
    "Render-CLI",
    "Set-PanelStatus",
    "Open-InFileExplorer",
    "Open-EditModal",
    "Close-EditModal",
    "Get-DriveColorHex",
    "New-BlueOutPlaceholder",
    "New-MissingFileCell",
    "New-ExpandableCell",
    "New-GitProtocolCell",
    "Update-ToggleVisual",
    "Add-RowCard",
    "New-PolyClipRowCard",
    "Render-AllRows"
)
