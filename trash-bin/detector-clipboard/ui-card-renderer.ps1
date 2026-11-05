<#
.SYNOPSIS
    PolyClip WPF UI Component & Card Renderer
.DESCRIPTION
    Builds WPF UI elements, accordion expandable cells, drive-color selectable path textboxes,
    file explorer reveal buttons, and history row cards.
#>

function Set-PanelStatus {
    param ([string]$Message)
    if ($script:txtStatus) {
        try {
            $script:txtStatus.Text = $Message
        } catch {}
    }
}

function Open-InFileExplorer {
    param ([string]$FilePath)
    if ([string]::IsNullOrWhiteSpace($FilePath)) { return }
    try {
        if (Test-Path -LiteralPath $FilePath) {
            $full = (Resolve-Path -LiteralPath $FilePath).Path
            if (Test-Path -LiteralPath $full -PathType Container) {
                [System.Diagnostics.Process]::Start("explorer.exe", "`"$full`"") | Out-Null
            } else {
                [System.Diagnostics.Process]::Start("explorer.exe", "/select,`"$full`"") | Out-Null
            }
            Set-PanelStatus "Revealed in File Explorer: $(Split-Path -Leaf $full)"
        } else {
            Set-PanelStatus "File does not exist on disk: $FilePath"
        }
    } catch {
        Set-PanelStatus "Failed to open File Explorer: $_"
    }
}

function Open-EditModal {
    param ($Item)
    if (-not $Item) { return }
    $script:activeEditItem = $Item
    if ($script:editItemInfo) {
        $script:editItemInfo.Text = "[$($Item.Timestamp)] - $($Item.FileName)"
    }
    $val = if ($Item.IsOpenable -and $Item.Mode3_Content) {
        $Item.Mode3_Content
    } elseif ($Item.Mode2_Path) {
        $Item.Mode2_Path
    } else {
        [string]$Item.Mode1_Text
    }
    if ($script:editTextBox) {
        $script:editTextBox.Text = [string]$val
        try { $script:editTextBox.Focus() | Out-Null } catch {}
    }
    if ($script:editOverlay) {
        $script:editOverlay.Visibility = [System.Windows.Visibility]::Visible
    }
}

function Close-EditModal {
    if ($script:editOverlay) {
        $script:editOverlay.Visibility = [System.Windows.Visibility]::Collapsed
    }
}

function New-BlueOutPlaceholder {
    param (
        [string]$Message = "-",
        [string]$ToolTipText = "Copy is not available for this mode"
    )
    $bdr = [System.Windows.Controls.Border]::new()
    $bdr.Height = 26
    $bdr.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#091424")
    $bdr.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#182C48")
    $bdr.BorderThickness = [System.Windows.Thickness]::new(1)
    $bdr.CornerRadius = [System.Windows.CornerRadius]::new(3)
    $bdr.Margin = [System.Windows.Thickness]::new(2)
    $bdr.Opacity = 0.55
    $bdr.ToolTip = $ToolTipText

    $tb = [System.Windows.Controls.TextBlock]::new()
    $tb.Text = $Message
    $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    $tb.FontSize = 10
    $tb.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
    $tb.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    $tb.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
    $bdr.Child = $tb

    $bdr.Add_MouseLeftButtonUp({
        param($s, $e)
        Set-PanelStatus "Copy unavailable: This item/mode is not accessible."
    }.GetNewClosure())

    return $bdr
}

function New-ExpandableCell {
    param (
        [string]$FullText,
        [string]$DisplayText,
        [int]$TargetMode,
        [PSCustomObject]$SnapshotItem,
        [string]$BgHex = "#1E1E22",
        [string]$FgHex = "#E4E4E7",
        [string]$BorderHex = "#2D2D33",
        [switch]$IsSelectableTextBox
    )

    $cellBorder = [System.Windows.Controls.Border]::new()
    $cellBorder.Margin = [System.Windows.Thickness]::new(2)
    $cellBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString($BgHex)
    $cellBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($BorderHex)
    $cellBorder.BorderThickness = [System.Windows.Thickness]::new(1)
    $cellBorder.CornerRadius = [System.Windows.CornerRadius]::new(3)

    $mainGrid = [System.Windows.Controls.Grid]::new()
    $cellBorder.Child = $mainGrid

    # 1. Collapsed View (Fixed 26px single line with ellipsis / selectable textbox)
    $collapsedGrid = [System.Windows.Controls.Grid]::new()
    $collapsedGrid.Height = 26

    $rawOne = if ($DisplayText) { $DisplayText } else { $FullText }
    $cleanOneLine = ($rawOne -replace "[\r\n\t]+", " ").Trim()

    if ($IsSelectableTextBox) {
        $cColText = [System.Windows.Controls.ColumnDefinition]::new()
        $cColText.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $cColClip = [System.Windows.Controls.ColumnDefinition]::new()
        $cColClip.Width = [System.Windows.GridLength]::Auto
        $cColBtn = [System.Windows.Controls.ColumnDefinition]::new()
        $cColBtn.Width = [System.Windows.GridLength]::Auto
        $collapsedGrid.ColumnDefinitions.Add($cColText)
        $collapsedGrid.ColumnDefinitions.Add($cColClip)
        $collapsedGrid.ColumnDefinitions.Add($cColBtn)

        # Selectable TextBox: user can click, drag to highlight, and copy snippets
        $tbSelectable = [System.Windows.Controls.TextBox]::new()
        $tbSelectable.Text = $cleanOneLine
        $tbSelectable.IsReadOnly = $true
        $tbSelectable.Background = [System.Windows.Media.Brushes]::Transparent
        $tbSelectable.BorderThickness = [System.Windows.Thickness]::new(0)
        $tbSelectable.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($FgHex)
        $tbSelectable.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Segoe UI")
        $tbSelectable.FontSize = 11
        $tbSelectable.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $tbSelectable.VerticalContentAlignment = [System.Windows.VerticalAlignment]::Center
        $tbSelectable.Padding = [System.Windows.Thickness]::new(6, 1, 4, 1)
        $tbSelectable.ToolTip = "Selectable Path (Drag cursor to highlight, Ctrl+C to copy snippet)"
        [System.Windows.Controls.Grid]::SetColumn($tbSelectable, 0)
        $collapsedGrid.Children.Add($tbSelectable) | Out-Null

        # Clipboard Copy Button
        $btnInlineClip = [System.Windows.Controls.Button]::new()
        $btnInlineClip.Content = [System.Char]::ConvertFromUtf32(0x1F4CB)
        $btnInlineClip.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI Emoji, Segoe UI Symbol")
        $btnInlineClip.FontSize = 10
        $btnInlineClip.Width = 24
        $btnInlineClip.Height = 22
        $btnInlineClip.Margin = [System.Windows.Thickness]::new(1, 1, 1, 1)
        $btnInlineClip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#182030")
        $btnInlineClip.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $btnInlineClip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#203650")
        $btnInlineClip.ToolTip = "Left-click: Copy full path to Clipboard (Mode $TargetMode)"
        $btnInlineClip.Tag = @{ TargetMode = $TargetMode; SnapshotItem = $SnapshotItem }
        $btnInlineClip.Add_Click({
            param($s, $e)
            $senderObj = if ($s) { $s } else { $this }
            $mode = $senderObj.Tag.TargetMode
            $snap = $senderObj.Tag.SnapshotItem
            Invoke-ApplyMode -TargetMode $mode -Snapshot $snap | Out-Null
            Set-PanelStatus "Applied Mode $mode to Clipboard."
        }.GetNewClosure())
        [System.Windows.Controls.Grid]::SetColumn($btnInlineClip, 1)
        $collapsedGrid.Children.Add($btnInlineClip) | Out-Null

        # Accordion Expand Button
        $btnExpand = [System.Windows.Controls.Button]::new()
        $btnExpand.Content = "..."
        $btnExpand.Width = 22
        $btnExpand.Height = 22
        $btnExpand.Margin = [System.Windows.Thickness]::new(1, 1, 2, 1)
        $btnExpand.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
        $btnExpand.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#818CF8")
        $btnExpand.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A2A34")
        $btnExpand.FontWeight = [System.Windows.FontWeights]::Bold
        $btnExpand.ToolTip = "Click to expand into scrollable textbox"
        [System.Windows.Controls.Grid]::SetColumn($btnExpand, 2)
        $collapsedGrid.Children.Add($btnExpand) | Out-Null
    } else {
        $cColText = [System.Windows.Controls.ColumnDefinition]::new()
        $cColText.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $cColBtn = [System.Windows.Controls.ColumnDefinition]::new()
        $cColBtn.Width = [System.Windows.GridLength]::Auto
        $collapsedGrid.ColumnDefinitions.Add($cColText)
        $collapsedGrid.ColumnDefinitions.Add($cColBtn)

        $btnCopy = [System.Windows.Controls.Button]::new()
        $btnCopy.Background = [System.Windows.Media.Brushes]::Transparent
        $btnCopy.BorderThickness = [System.Windows.Thickness]::new(0)
        $btnCopy.Padding = [System.Windows.Thickness]::new(6, 4, 2, 4)
        $btnCopy.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
        $btnCopy.ToolTip = "Left-click: Copy Mode $TargetMode to Clipboard"

        $tbText = [System.Windows.Controls.TextBlock]::new()
        $tbText.Text = $cleanOneLine
        $tbText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($FgHex)
        $tbText.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
        $tbText.TextWrapping = [System.Windows.TextWrapping]::NoWrap
        $tbText.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $btnCopy.Content = $tbText

        $btnCopy.Tag = @{ TargetMode = $TargetMode; SnapshotItem = $SnapshotItem }
        $btnCopy.Add_Click({
            param($s, $e)
            $senderObj = if ($s) { $s } else { $this }
            $mode = $senderObj.Tag.TargetMode
            $snap = $senderObj.Tag.SnapshotItem
            Invoke-ApplyMode -TargetMode $mode -Snapshot $snap | Out-Null
            Set-PanelStatus "Applied Mode $mode to Clipboard."
        }.GetNewClosure())
        [System.Windows.Controls.Grid]::SetColumn($btnCopy, 0)
        $collapsedGrid.Children.Add($btnCopy) | Out-Null

        $btnExpand = [System.Windows.Controls.Button]::new()
        $btnExpand.Content = "..."
        $btnExpand.Width = 24
        $btnExpand.Height = 22
        $btnExpand.Margin = [System.Windows.Thickness]::new(1, 1, 2, 1)
        $btnExpand.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
        $btnExpand.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#818CF8")
        $btnExpand.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A2A34")
        $btnExpand.FontWeight = [System.Windows.FontWeights]::Bold
        $btnExpand.ToolTip = "Click to expand into scrollable textbox"
        [System.Windows.Controls.Grid]::SetColumn($btnExpand, 1)
        $collapsedGrid.Children.Add($btnExpand) | Out-Null
    }

    $mainGrid.Children.Add($collapsedGrid) | Out-Null

    # 2. Expanded Accordion View (Scrollable multiline TextBox)
    $expandedGrid = [System.Windows.Controls.Grid]::new()
    $expandedGrid.Visibility = [System.Windows.Visibility]::Collapsed
    
    $rHeader = [System.Windows.Controls.RowDefinition]::new()
    $rHeader.Height = [System.Windows.GridLength]::Auto
    $rBody = [System.Windows.Controls.RowDefinition]::new()
    $rBody.Height = [System.Windows.GridLength]::Auto
    $expandedGrid.RowDefinitions.Add($rHeader)
    $expandedGrid.RowDefinitions.Add($rBody)

    $headDock = [System.Windows.Controls.DockPanel]::new()
    $headDock.Margin = [System.Windows.Thickness]::new(4, 2, 4, 2)

    $lblTitle = [System.Windows.Controls.TextBlock]::new()
    $charCount = if ($FullText) { [string]$FullText.Length } else { "0" }
    $lblTitle.Text = "MODE $TargetMode ($charCount chars)"
    $lblTitle.FontSize = 9
    $lblTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#71717A")
    $lblTitle.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
    [System.Windows.Controls.DockPanel]::SetDock($lblTitle, [System.Windows.Controls.Dock]::Left)
    $headDock.Children.Add($lblTitle) | Out-Null

    $btnCollapse = [System.Windows.Controls.Button]::new()
    $btnCollapse.Content = "^"
    $btnCollapse.Width = 22
    $btnCollapse.Height = 18
    $btnCollapse.FontSize = 10
    $btnCollapse.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#202026")
    $btnCollapse.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
    $btnCollapse.ToolTip = "Click to collapse back"
    [System.Windows.Controls.DockPanel]::SetDock($btnCollapse, [System.Windows.Controls.Dock]::Right)
    $headDock.Children.Add($btnCollapse) | Out-Null

    $btnInlineCopy = [System.Windows.Controls.Button]::new()
    $btnInlineCopy.Content = "Copy"
    $btnInlineCopy.Padding = [System.Windows.Thickness]::new(4, 0, 4, 0)
    $btnInlineCopy.Height = 18
    $btnInlineCopy.FontSize = 9
    $btnInlineCopy.Margin = [System.Windows.Thickness]::new(0, 0, 4, 0)
    $btnInlineCopy.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0284C7")
    $btnInlineCopy.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
    [System.Windows.Controls.DockPanel]::SetDock($btnInlineCopy, [System.Windows.Controls.Dock]::Right)
    $btnInlineCopy.Tag = @{ TargetMode = $TargetMode; SnapshotItem = $SnapshotItem }
    $btnInlineCopy.Add_Click({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $mode = $senderObj.Tag.TargetMode
        $snap = $senderObj.Tag.SnapshotItem
        Invoke-ApplyMode -TargetMode $mode -Snapshot $snap | Out-Null
        Set-PanelStatus "Applied Mode $mode to Clipboard."
    }.GetNewClosure())
    $headDock.Children.Add($btnInlineCopy) | Out-Null

    [System.Windows.Controls.Grid]::SetRow($headDock, 0)
    $expandedGrid.Children.Add($headDock) | Out-Null

    $txtBox = [System.Windows.Controls.TextBox]::new()
    $txtBox.Text = [string]$FullText
    $txtBox.IsReadOnly = $true
    $txtBox.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $txtBox.AcceptsReturn = $true
    $txtBox.VerticalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Auto
    $txtBox.HorizontalScrollBarVisibility = [System.Windows.Controls.ScrollBarVisibility]::Disabled
    $txtBox.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0D0D10")
    $txtBox.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($FgHex)
    $txtBox.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#232328")
    $txtBox.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas, Segoe UI")
    $txtBox.FontSize = 11
    $txtBox.Height = 90
    $txtBox.Padding = [System.Windows.Thickness]::new(4)
    [System.Windows.Controls.Grid]::SetRow($txtBox, 1)
    $expandedGrid.Children.Add($txtBox) | Out-Null

    $mainGrid.Children.Add($expandedGrid) | Out-Null

    $btnExpand.Tag = @{
        Collapsed = $collapsedGrid
        Expanded  = $expandedGrid
        Box       = $txtBox
    }
    $btnExpand.Add_Click({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $senderObj.Tag.Collapsed.Visibility = [System.Windows.Visibility]::Collapsed
        $senderObj.Tag.Expanded.Visibility  = [System.Windows.Visibility]::Visible
        try { $senderObj.Tag.Box.Focus() | Out-Null } catch {}
    }.GetNewClosure())

    $btnCollapse.Tag = @{
        Collapsed = $collapsedGrid
        Expanded  = $expandedGrid
    }
    $btnCollapse.Add_Click({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $senderObj.Tag.Expanded.Visibility  = [System.Windows.Visibility]::Collapsed
        $senderObj.Tag.Collapsed.Visibility = [System.Windows.Visibility]::Visible
    }.GetNewClosure())

    return $cellBorder
}

function Update-ToggleVisual {
    $conv = [System.Windows.Media.BrushConverter]::new()
    if ($script:showAll) {
        $script:btnToggleAll.Content    = "Show All: ON"
        $script:btnToggleAll.Background = $conv.ConvertFromString("#065F46")
        $script:btnToggleAll.BorderBrush = $conv.ConvertFromString("#059669")
        $script:btnToggleAll.Foreground = $conv.ConvertFromString("#34D399")
        $script:btnToggleAll.ToolTip    = "ON: showing all $($global:PolyClipHistory.Count) history items (click to limit to 5)"
    } else {
        $script:btnToggleAll.Content    = "Show All: OFF"
        $script:btnToggleAll.Background = $conv.ConvertFromString("#1E1E22")
        $script:btnToggleAll.BorderBrush = $conv.ConvertFromString("#2D2D33")
        $script:btnToggleAll.Foreground = $conv.ConvertFromString("#A1A1AA")
        $script:btnToggleAll.ToolTip    = "OFF: showing latest 5 items (click to show all $($global:PolyClipHistory.Count))"
    }
}

function Add-RowCard {
    param ($item, [int]$rowIdx)

    $rowBorder = [System.Windows.Controls.Border]::new()
    $rowBorder.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#151518")
    $rowBorder.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#232328")
    $rowBorder.BorderThickness = [System.Windows.Thickness]::new(1)
    $rowBorder.CornerRadius = [System.Windows.CornerRadius]::new(4)
    $rowBorder.Margin = [System.Windows.Thickness]::new(0, 0, 0, 5)
    $rowBorder.Padding = [System.Windows.Thickness]::new(3)

    $rowBorder.Tag = $item
    $rowBorder.Add_MouseRightButtonUp({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $it = if ($senderObj.Tag) { $senderObj.Tag } else { $item }
        $null = Promote-ToFirst $it
        Render-AllRows
        Set-PanelStatus "Duplicated [$($it.Timestamp)] to #1 Latest & Copied to Clipboard (old item kept in place)!"
    }.GetNewClosure())

    $grid = [System.Windows.Controls.Grid]::new()
    
    # Col 0: TIME (70px)
    $colTime = [System.Windows.Controls.ColumnDefinition]::new()
    $colTime.Width = [System.Windows.GridLength]::new(70)
    $grid.ColumnDefinitions.Add($colTime)

    # Col 1: PLAIN TEXT (1.1*)
    $c1 = [System.Windows.Controls.ColumnDefinition]::new()
    $c1.Width = [System.Windows.GridLength]::new(1.1, [System.Windows.GridUnitType]::Star)
    $grid.ColumnDefinitions.Add($c1)

    # Col 2: FILE PATH (1*)
    $c2 = [System.Windows.Controls.ColumnDefinition]::new()
    $c2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
    $grid.ColumnDefinitions.Add($c2)

    # Col 3: FILE CONTENT (FIRST 15 CHARS) (1.2*)
    $c3 = [System.Windows.Controls.ColumnDefinition]::new()
    $c3.Width = [System.Windows.GridLength]::new(1.2, [System.Windows.GridUnitType]::Star)
    $grid.ColumnDefinitions.Add($c3)

    # Col 4: EXACT FILE (NAME | SIZE) (1.5*)
    $c4 = [System.Windows.Controls.ColumnDefinition]::new()
    $c4.Width = [System.Windows.GridLength]::new(1.5, [System.Windows.GridUnitType]::Star)
    $grid.ColumnDefinitions.Add($c4)

    # Col 5: ACTIONS (110px)
    $colAct = [System.Windows.Controls.ColumnDefinition]::new()
    $colAct.Width = [System.Windows.GridLength]::new(110)
    $grid.ColumnDefinitions.Add($colAct)

    # 0. TIME BUTTON
    $bTime = [System.Windows.Controls.Button]::new()
    $bTime.Content = [string]$item.Timestamp
    $bTime.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A78BFA")
    $bTime.FontWeight = [System.Windows.FontWeights]::SemiBold
    $bTime.Margin = [System.Windows.Thickness]::new(2)
    $bTime.Tag = $item
    $bTime.ToolTip = "Left-click or Right-click: Duplicate to #1 & Copy to Clipboard"
    $bTime.Add_Click({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $it = if ($senderObj.Tag) { $senderObj.Tag } else { $item }
        $null = Promote-ToFirst $it
        Render-AllRows
        Set-PanelStatus "Duplicated [$($it.Timestamp)] to #1 Latest & Copied to Clipboard (old item kept in place)."
    }.GetNewClosure())
    [System.Windows.Controls.Grid]::SetColumn($bTime, 0)
    $grid.Children.Add($bTime) | Out-Null

    # 1. Plain Text Cell (Fits column width with ellipsis; expands to scrollable textbox on '...')
    if ($item.Mode1_Text -and $item.Mode1_Text -ne "-") {
        $c1Cell = New-ExpandableCell -FullText [string]$item.Mode1_Text -DisplayText [string]$item.Mode1_Text -TargetMode 1 -SnapshotItem $item
        [System.Windows.Controls.Grid]::SetColumn($c1Cell, 1)
        $grid.Children.Add($c1Cell) | Out-Null
    } else {
        $ph1 = New-BlueOutPlaceholder -Message "-" -ToolTipText "Copy not available: No plain text in clip"
        [System.Windows.Controls.Grid]::SetColumn($ph1, 1)
        $grid.Children.Add($ph1) | Out-Null
    }

    # 2. File Path Cell: Drive Color Coded (Red for C:, Blue for D:, Green for E: or higher) with Selectable TextBox
    $pathAvailable = $item.Mode2_Path -and $item.Mode2_Path -ne "-" -and (Test-Path -LiteralPath $item.Mode2_Path)
    if ($pathAvailable) {
        $fullPathStr = [string]$item.Mode2_Path
        $driveHex = Get-DriveColorHex -Path $fullPathStr
        $c2Cell = New-ExpandableCell -FullText $fullPathStr -DisplayText $fullPathStr -TargetMode 2 -SnapshotItem $item -FgHex $driveHex -IsSelectableTextBox
        [System.Windows.Controls.Grid]::SetColumn($c2Cell, 2)
        $grid.Children.Add($c2Cell) | Out-Null
    } elseif ($item.Mode2_Path -and $item.Mode2_Path -ne "-") {
        $missingLabel = [string]$item.Mode2_Path + " (missing)"
        $ph2 = New-BlueOutPlaceholder -Message $missingLabel -ToolTipText ("Copy not available: File was deleted or moved from " + [string]$item.Mode2_Path)
        [System.Windows.Controls.Grid]::SetColumn($ph2, 2)
        $grid.Children.Add($ph2) | Out-Null
    } else {
        $ph2 = New-BlueOutPlaceholder -Message "-" -ToolTipText "Copy not available: No file path in clip"
        [System.Windows.Controls.Grid]::SetColumn($ph2, 2)
        $grid.Children.Add($ph2) | Out-Null
    }

    # 3. Content Cell: FIRST 15 CHARACTERS PREVIEW -> Expands into full scrollable script textbox on '...'
    if ($item.IsOpenable -and $item.Mode3_Content) {
        $preview15 = Get-First15Chars -Content $item.Mode3_Content
        $c3Cell = New-ExpandableCell -FullText [string]$item.Mode3_Content -DisplayText $preview15 -TargetMode 3 -SnapshotItem $item -BgHex "#065F46" -FgHex "#34D399" -BorderHex "#059669"
        [System.Windows.Controls.Grid]::SetColumn($c3Cell, 3)
        $grid.Children.Add($c3Cell) | Out-Null
    } elseif ($item.DetectedPath) {
        $binLabel = [string]$item.FileName + " (binary)"
        $ph3 = New-BlueOutPlaceholder -Message $binLabel -ToolTipText "Copy not available: Cannot read binary/symbol file as text"
        [System.Windows.Controls.Grid]::SetColumn($ph3, 3)
        $grid.Children.Add($ph3) | Out-Null
    } else {
        $ph3 = New-BlueOutPlaceholder -Message "-" -ToolTipText "Copy not available: No file content"
        [System.Windows.Controls.Grid]::SetColumn($ph3, 3)
        $grid.Children.Add($ph3) | Out-Null
    }

    # 4. Exact File Cell: SUBCOLUMNS [FILE NAME (Click->Explorer)] | [CLIPBOARD BTN] | [FILE SIZE]
    $exactAvailable = $item.Mode4_File -and $item.Mode4_File -ne "-" -and (Test-Path -LiteralPath $item.Mode4_File)
    if ($exactAvailable) {
        $exactGrid = [System.Windows.Controls.Grid]::new()
        
        $exactColName = [System.Windows.Controls.ColumnDefinition]::new()
        $exactColName.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $exactGrid.ColumnDefinitions.Add($exactColName)

        $exactColClip = [System.Windows.Controls.ColumnDefinition]::new()
        $exactColClip.Width = [System.Windows.GridLength]::Auto
        $exactGrid.ColumnDefinitions.Add($exactColClip)

        $exactColSize = [System.Windows.Controls.ColumnDefinition]::new()
        $exactColSize.Width = [System.Windows.GridLength]::new(62)
        $exactGrid.ColumnDefinitions.Add($exactColSize)

        # Sub-col 0: File Name Text Button -> Opens and selects in File Explorer
        $bExactName = [System.Windows.Controls.Button]::new()
        $bExactName.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#18181C")
        $bExactName.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#27272A")
        $bExactName.BorderThickness = [System.Windows.Thickness]::new(1)
        $bExactName.Margin = [System.Windows.Thickness]::new(2, 2, 1, 2)
        $bExactName.Padding = [System.Windows.Thickness]::new(6, 2, 6, 2)
        $bExactName.HorizontalContentAlignment = [System.Windows.HorizontalAlignment]::Left
        $bExactName.ToolTip = "Left-click: Reveal and select '$($item.FileName)' in File Explorer"
        
        $tbExact = [System.Windows.Controls.TextBlock]::new()
        $tbExact.Text = [string]$item.FileName
        $tbExact.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E4E4E7")
        $tbExact.TextTrimming = [System.Windows.TextTrimming]::CharacterEllipsis
        $bExactName.Content = $tbExact
        $bExactName.Tag = $item.Mode4_File
        $bExactName.Add_Click({
            param($s, $e)
            $senderObj = if ($s) { $s } else { $this }
            $targetPath = if ($senderObj.Tag) { $senderObj.Tag } else { $item.Mode4_File }
            Open-InFileExplorer -FilePath $targetPath
        }.GetNewClosure())
        [System.Windows.Controls.Grid]::SetColumn($bExactName, 0)
        $exactGrid.Children.Add($bExactName) | Out-Null

        # Sub-col 1: Dedicated Clipboard Button -> Copies CF_HDROP file drop to Clipboard
        $bExactClip = [System.Windows.Controls.Button]::new()
        $bExactClip.Content = [System.Char]::ConvertFromUtf32(0x1F4CB)
        $bExactClip.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI Emoji, Segoe UI Symbol")
        $bExactClip.FontSize = 11
        $bExactClip.Width = 30
        $bExactClip.Height = 22
        $bExactClip.Margin = [System.Windows.Thickness]::new(1, 2, 1, 2)
        $bExactClip.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#162032")
        $bExactClip.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $bExactClip.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E3A5F")
        $bExactClip.ToolTip = "Click to copy file (Mode 4: CF_HDROP) to Clipboard (Ready to paste in Explorer)"
        $bExactClip.Tag = $item
        $bExactClip.Add_Click({
            param($s, $e)
            $senderObj = if ($s) { $s } else { $this }
            $it = if ($senderObj.Tag) { $senderObj.Tag } else { $item }
            Invoke-ApplyMode -TargetMode 4 -Snapshot $it | Out-Null
            Set-PanelStatus "Applied Mode 4 (CF_HDROP) to Clipboard (Ready to paste in Explorer)."
        }.GetNewClosure())
        [System.Windows.Controls.Grid]::SetColumn($bExactClip, 1)
        $exactGrid.Children.Add($bExactClip) | Out-Null

        # Sub-col 2: File Size Badge
        $bExactSize = [System.Windows.Controls.Border]::new()
        $bExactSize.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1C1C24")
        $bExactSize.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2E2E38")
        $bExactSize.BorderThickness = [System.Windows.Thickness]::new(1)
        $bExactSize.CornerRadius = [System.Windows.CornerRadius]::new(3)
        $bExactSize.Margin = [System.Windows.Thickness]::new(1, 2, 2, 2)
        $tbSize = [System.Windows.Controls.TextBlock]::new()
        $tbSize.Text = [string]$item.FileSizeStr
        $tbSize.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F472B6")
        $tbSize.FontSize = 10
        $tbSize.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
        $tbSize.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        $bExactSize.Child = $tbSize
        [System.Windows.Controls.Grid]::SetColumn($bExactSize, 2)
        $exactGrid.Children.Add($bExactSize) | Out-Null

        [System.Windows.Controls.Grid]::SetColumn($exactGrid, 4)
        $grid.Children.Add($exactGrid) | Out-Null
    } elseif ($item.Mode4_File -and $item.Mode4_File -ne "-") {
        $missingExact = [string]$item.FileName + " (missing)"
        $ph4 = New-BlueOutPlaceholder -Message $missingExact -ToolTipText ("Copy not available: File does not exist at " + [string]$item.Mode4_File)
        [System.Windows.Controls.Grid]::SetColumn($ph4, 4)
        $grid.Children.Add($ph4) | Out-Null
    } else {
        $ph4 = New-BlueOutPlaceholder -Message "-" -ToolTipText "Copy not available: No file drop in clip"
        [System.Windows.Controls.Grid]::SetColumn($ph4, 4)
        $grid.Children.Add($ph4) | Out-Null
    }

    # 5. ACTIONS COLUMN: [Edit] [Dup] [Del]
    $actStack = [System.Windows.Controls.StackPanel]::new()
    $actStack.Orientation = [System.Windows.Controls.Orientation]::Horizontal
    $actStack.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

    # Button: Edit
    $btnEdit = [System.Windows.Controls.Button]::new()
    $btnEdit.Content = "Edit"
    $btnEdit.Padding = [System.Windows.Thickness]::new(4, 2, 4, 2)
    $btnEdit.Margin = [System.Windows.Thickness]::new(1)
    $btnEdit.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#162032")
    $btnEdit.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
    $btnEdit.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E3A5F")
    $btnEdit.ToolTip = "Edit clip content"
    $btnEdit.Tag = $item
    $btnEdit.Add_Click({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $it = if ($senderObj.Tag) { $senderObj.Tag } else { $item }
        Open-EditModal -Item $it
    }.GetNewClosure())
    $actStack.Children.Add($btnEdit) | Out-Null

    # Button: Duplicate & Set as #1 Latest (Keeps original in place)
    $btnDup = [System.Windows.Controls.Button]::new()
    $btnDup.Content = "Dup"
    $btnDup.Padding = [System.Windows.Thickness]::new(4, 2, 4, 2)
    $btnDup.Margin = [System.Windows.Thickness]::new(1)
    $btnDup.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#162A22")
    $btnDup.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
    $btnDup.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E4D3A")
    $btnDup.ToolTip = "Duplicate as #1 latest & copy to clipboard (original stays in history)"
    $btnDup.Tag = $item
    $btnDup.Add_Click({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $it = if ($senderObj.Tag) { $senderObj.Tag } else { $item }
        $null = Promote-ToFirst $it
        Render-AllRows
        Set-PanelStatus "Duplicated [$($it.Timestamp)] to #1 Latest & Copied to Clipboard (old item kept in place)."
    }.GetNewClosure())
    $actStack.Children.Add($btnDup) | Out-Null

    # Button: Remove
    $btnDel = [System.Windows.Controls.Button]::new()
    $btnDel.Content = "Del"
    $btnDel.Padding = [System.Windows.Thickness]::new(4, 2, 4, 2)
    $btnDel.Margin = [System.Windows.Thickness]::new(1)
    $btnDel.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A1414")
    $btnDel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F87171")
    $btnDel.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#4D1E1E")
    $btnDel.ToolTip = "Remove from history"
    $btnDel.Tag = $item
    $btnDel.Add_Click({
        param($s, $e)
        $senderObj = if ($s) { $s } else { $this }
        $it = if ($senderObj.Tag) { $senderObj.Tag } else { $item }
        $global:PolyClipHistory.Remove($it) | Out-Null
        Save-PersistentHistory
        Render-AllRows
        Set-PanelStatus "Removed item from history."
    }.GetNewClosure())
    $actStack.Children.Add($btnDel) | Out-Null

    [System.Windows.Controls.Grid]::SetColumn($actStack, 5)
    $grid.Children.Add($actStack) | Out-Null

    $rowBorder.Child = $grid
    if ($script:rowsContainer) {
        $script:rowsContainer.Children.Add($rowBorder) | Out-Null
    }
    return $rowBorder
}

function Render-AllRows {
    if (-not $script:rowsContainer) { return }
    $script:rowsContainer.Children.Clear()
    $script:currentRenderCount = 0
    $total = $global:PolyClipHistory.Count
    $countToLoad = if ($script:showAll) { $total } else { [math]::Min(5, $total) }
    for ($i = 0; $i -lt $countToLoad; $i++) {
        $null = Add-RowCard -item $global:PolyClipHistory[$i] -rowIdx $i
    }
    $script:currentRenderCount = $countToLoad
    Update-ToggleVisual
}
