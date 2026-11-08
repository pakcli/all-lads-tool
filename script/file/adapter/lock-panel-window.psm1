<#
.SYNOPSIS
    GUI UI: Interactive WPF Dark Card Window Host for File Lock & Disk Activity Inspector
.DESCRIPTION
    Conforms strictly to PolyClip UI standards & Rule #4 Privacy Default Masking Protocol:
    - Default state is MASKED (sensitive email, user, or paths masked to 2 visible letters).
    - Email mask rule: 2 first letters + '***' + '@' + 2 first domain letters + '***' (e.g. fa***@gm***.com).
    - General identifier mask rule: 2 first letters + '***' (e.g. fa***).
    - Unmasking via:
      1. HOLD TO REVEAL: Press and hold mouse/button to temporarily reveal; releases back to mask on mouse up.
      2. PERSISTENT EYE TOGGLE: Explicit click toggles mask on/off during session.
    - INVARIANT: Privacy reveal state is NEVER written or saved to JSON.
#>

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$adapterDir = $PSScriptRoot
if (Test-Path -LiteralPath (Join-Path $adapterDir "file-lock-inspector.psm1")) {
    Import-Module -Name (Join-Path $adapterDir "file-lock-inspector.psm1") -DisableNameChecking -Force
}

function Format-PrivacyMaskString {
    param(
        [string]$InputString,
        [bool]$Unmask = $false
    )
    if ([string]::IsNullOrWhiteSpace($InputString)) { return "" }
    if ($Unmask) { return $InputString }

    # If it contains an email address (e.g., name@gmail.com)
    if ($InputString -match '(?i)\b([a-zA-Z0-9_.+-]{1,2})([a-zA-Z0-9_.+-]*)@([a-zA-Z0-9-]{1,2})([a-zA-Z0-9-]*\.[a-zA-Z0-9-.]+)\b') {
        return [regex]::Replace($InputString, '(?i)\b([a-zA-Z0-9_.+-]{1,2})([a-zA-Z0-9_.+-]*)@([a-zA-Z0-9-]{1,2})([a-zA-Z0-9-]*\.[a-zA-Z0-9-.]+)\b', {
            param($m)
            $userPrefix = $m.Groups[1].Value
            $domainPrefix = $m.Groups[3].Value
            $domainSuffix = $m.Groups[4].Value
            $ext = if ($domainSuffix -match '(\.[a-zA-Z0-9]+)$') { $matches[1] } else { "" }
            return "$($userPrefix)***@$($domainPrefix)***$($ext)"
        })
    }

    # If it contains a user profile path (C:\Users\<username>\...)
    if ($InputString -match '(?i)(users[\\/])([a-zA-Z0-9_-]{1,2})([a-zA-Z0-9_-]+)') {
        return [regex]::Replace($InputString, '(?i)(users[\\/])([a-zA-Z0-9_-]{1,2})([a-zA-Z0-9_-]+)', {
            param($m)
            return "$($m.Groups[1].Value)$($m.Groups[2].Value)***"
        })
    }

    return $InputString
}

function Show-FileLockPanel {
    [CmdletBinding()]
    param(
        [array]$AppLocks = @(),
        [array]$Drives = @(),
        [string]$InitialPath = ""
    )

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Active File Lock &amp; Disk Activity Inspector"
        Height="660" Width="1080"
        WindowStartupLocation="CenterScreen"
        Background="#101012" Foreground="#E4E4E7"
        WindowStyle="None" AllowsTransparency="True" BorderThickness="1" BorderBrush="#27272A"
        FontFamily="Segoe UI, Consolas" FontSize="12"
        AllowDrop="True">
    <Window.Resources>
        <!-- Dark ScrollBar Thumb Style -->
        <Style x:Key="DarkScrollBarThumb" TargetType="{x:Type Thumb}">
            <Setter Property="OverridesDefaultStyle" Value="true"/>
            <Setter Property="IsTabStop" Value="false"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Thumb}">
                        <Border Name="ThumbBdr" Background="#2C2C34" CornerRadius="4" Margin="1,0"/>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="ThumbBdr" Property="Background" Value="#4A4A58"/>
                            </Trigger>
                            <Trigger Property="IsDragging" Value="True">
                                <Setter TargetName="ThumbBdr" Property="Background" Value="#656578"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Pure Dark ScrollBar -->
        <Style TargetType="{x:Type ScrollBar}">
            <Setter Property="Background" Value="#121215"/>
            <Setter Property="Width" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type ScrollBar}">
                        <Grid Background="#121215">
                            <Track Name="PART_Track" IsDirectionReversed="true">
                                <Track.Thumb>
                                    <Thumb Style="{StaticResource DarkScrollBarThumb}"/>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Dark Button Template -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="#1E1E22"/>
            <Setter Property="Foreground" Value="#E4E4E7"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#2D2D33"/>
            <Setter Property="Padding" Value="8,4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="Bdr" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bdr" Property="Background" Value="#2A2A30"/>
                                <Setter TargetName="Bdr" Property="BorderBrush" Value="#454550"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="12">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Row 0: Header -->
            <RowDefinition Height="Auto"/> <!-- Row 1: Target Scope Toolbar -->
            <RowDefinition Height="Auto"/> <!-- Row 2: Mode Selector Tabs & Filter -->
            <RowDefinition Height="*"/>    <!-- Row 3: Main Content Area -->
            <RowDefinition Height="Auto"/> <!-- Row 4: Bottom Status Bar -->
        </Grid.RowDefinitions>

        <!-- PolyClip Style Header -->
        <DockPanel Grid.Row="0" Margin="0,0,0,10" Name="HeaderDock">
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
                <TextBlock Text="LOCK INSPECTOR" FontWeight="Bold" FontSize="15" Foreground="#38BDF8" VerticalAlignment="Center"/>
                <TextBlock Text=" - Active File Lock &amp; Disk Activity" FontSize="12" Foreground="#71717A" Margin="6,2,0,0" VerticalAlignment="Center"/>
                <TextBlock Text=" [Drag to Move]" FontSize="11" Foreground="#A78BFA" Margin="12,3,0,0" VerticalAlignment="Center"/>
            </StackPanel>
            
            <Button Name="BtnClose" Content="X" Width="26" Height="24" DockPanel.Dock="Right" Background="Transparent" BorderThickness="0" Foreground="#A1A1AA" FontWeight="Bold"/>
            <Button Name="BtnRefresh" Content="Refresh" Width="80" DockPanel.Dock="Right" Background="#0284C7" Foreground="#FFFFFF" FontWeight="SemiBold" Margin="0,0,10,0"/>

            <!-- Privacy Controls: Hold to Reveal + Toggle Switch -->
            <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" Margin="0,0,12,0" VerticalAlignment="Center">
                <Button Name="BtnHoldReveal" Content="Hold to Reveal" Background="#1E293B" Foreground="#94A3B8" FontSize="11" Padding="8,3" Margin="0,0,6,0" ToolTip="Press &amp; Hold to temporarily unmask sensitive handles"/>
                <Button Name="BtnToggleMask" Content="Mask: ON (2-Letter)" Background="#065F46" Foreground="#34D399" FontWeight="Bold" FontSize="11" Padding="10,3" ToolTip="Click to toggle persistent mask state"/>
            </StackPanel>

            <TextBlock Text="[ESC to Close]" FontSize="11" Foreground="#52525B" DockPanel.Dock="Right" Margin="0,4,12,0" VerticalAlignment="Center"/>
        </DockPanel>

        <!-- Target Scope Toolbar & Drag-Drop Destination -->
        <Border Grid.Row="1" Background="#161618" BorderBrush="#27272A" BorderThickness="1" CornerRadius="4" Padding="6" Margin="0,0,0,8">
            <DockPanel>
                <TextBlock Text="Target Scope:" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <Button Name="BtnInspectPath" Content="Inspect Path" DockPanel.Dock="Right" Background="#0284C7" Foreground="#FFFFFF" FontWeight="Bold" Padding="12,4" Margin="6,0,0,0"/>
                <Button Name="BtnBrowseFolder" Content="Browse..." DockPanel.Dock="Right" Background="#1E1E22" Foreground="#94A3B8" Padding="8,4" Margin="6,0,0,0"/>
                <Button Name="BtnPasteClip" Content="Paste Clipboard" DockPanel.Dock="Right" Background="#1E1E22" Foreground="#94A3B8" Padding="8,4" Margin="6,0,0,0"/>
                <TextBox Name="TxtTargetPath" Height="26" Background="#0D0D10" Foreground="#E4E4E7" BorderBrush="#27272A" Padding="6,3" FontFamily="Consolas" FontSize="11" VerticalContentAlignment="Center" ToolTip="Drag and drop any folder or file here or enter path to inspect locks"/>
            </DockPanel>
        </Border>

        <!-- Mode Navigation & Filter Row -->
        <Border Grid.Row="2" Background="#161618" BorderBrush="#27272A" BorderThickness="1" CornerRadius="4" Padding="6" Margin="0,0,0,8">
            <DockPanel>
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
                    <Button Name="BtnModeApp" Content="Mode A: Group by Application" Background="#1E3A5F" Foreground="#38BDF8" FontWeight="Bold" Margin="0,0,8,0" Padding="12,5"/>
                    <Button Name="BtnModeDrive" Content="Mode B: Group by Drive &amp; Directory Tree" Background="#1E1E22" Foreground="#94A3B8" FontWeight="SemiBold" Margin="0,0,8,0" Padding="12,5"/>
                </StackPanel>
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Right" VerticalAlignment="Center">
                    <TextBlock Text="Filter:" Foreground="#71717A" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <TextBox Name="TxtFilter" Width="180" Height="24" Background="#0D0D10" Foreground="#E4E4E7" BorderBrush="#27272A" Padding="4,2"/>
                </StackPanel>
            </DockPanel>
        </Border>

        <!-- Main Content Area -->
        <Grid Grid.Row="3">
            <!-- View Mode A: Group by App -->
            <Grid Name="ViewApp" Visibility="Visible">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/> <!-- Column Title -->
                    <RowDefinition Height="*"/>    <!-- Rows -->
                </Grid.RowDefinitions>
                <Border Grid.Row="0" Background="#1E1E24" BorderBrush="#2D2D33" BorderThickness="1" CornerRadius="4" Padding="8,5" Margin="0,0,0,6">
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="190"/> <!-- Application & PID -->
                            <ColumnDefinition Width="190"/> <!-- File Name -->
                            <ColumnDefinition Width="*"/>   <!-- File Path -->
                            <ColumnDefinition Width="170"/> <!-- Lock Status -->
                            <ColumnDefinition Width="250"/> <!-- Actions -->
                        </Grid.ColumnDefinitions>
                        <TextBlock Grid.Column="0" Text="APPLICATION / PID" FontWeight="Bold" Foreground="#38BDF8"/>
                        <TextBlock Grid.Column="1" Text="FILE / FOLDER NAME" FontWeight="SemiBold" Foreground="#34D399"/>
                        <TextBlock Grid.Column="2" Text="LOCKED RESOURCE PATH" FontWeight="SemiBold" Foreground="#E4E4E7"/>
                        <TextBlock Grid.Column="3" Text="LOCK MODE" FontWeight="SemiBold" Foreground="#F59E0B" HorizontalAlignment="Center"/>
                        <TextBlock Grid.Column="4" Text="ACTIONS" FontWeight="SemiBold" Foreground="#94A3B8" HorizontalAlignment="Center"/>
                    </Grid>
                </Border>
                <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                    <StackPanel Name="AppRowsContainer" Margin="0,0,4,0"/>
                </ScrollViewer>
            </Grid>

            <!-- View Mode B: Group by Drive & Tree -->
            <Grid Name="ViewDrive" Visibility="Collapsed">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="330"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Left: Drive Selector Cards -->
                <Border Grid.Column="0" Background="#161618" BorderBrush="#27272A" BorderThickness="1" CornerRadius="6" Margin="0,0,8,0" Padding="10">
                    <DockPanel>
                        <TextBlock DockPanel.Dock="Top" Text="SYSTEM DRIVES OVERVIEW" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="DriveCardsContainer"/>
                        </ScrollViewer>
                    </DockPanel>
                </Border>

                <!-- Right: Interactive Foldering Tree -->
                <Border Grid.Column="1" Background="#161618" BorderBrush="#27272A" BorderThickness="1" CornerRadius="6" Padding="10">
                    <DockPanel>
                        <TextBlock DockPanel.Dock="Top" Name="TxtTreeTitle" Text="Interactive Directory Foldering" FontWeight="Bold" Foreground="#38BDF8" Margin="0,0,0,8"/>
                        <TreeView Name="TreeFolderView" Background="Transparent" BorderThickness="0" Foreground="#E4E4E7"/>
                    </DockPanel>
                </Border>
            </Grid>
        </Grid>

        <!-- Status Footer -->
        <Border Grid.Row="4" Background="#161618" BorderBrush="#27272A" BorderThickness="1" CornerRadius="4" Padding="8,4" Margin="0,8,0,0">
            <DockPanel>
                <TextBlock Name="TxtStatus" Text="Default state: Masked (2-letter). Hold button or toggle to reveal. Drop files or folders anytime." FontSize="11" Foreground="#A1A1AA" VerticalAlignment="Center"/>
                <TextBlock Text="all-lads-tool / file" FontSize="11" Foreground="#52525B" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </DockPanel>
        </Border>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    $headerDock          = $window.FindName("HeaderDock")
    $btnClose            = $window.FindName("BtnClose")
    $btnRefresh          = $window.FindName("BtnRefresh")
    $btnHoldReveal       = $window.FindName("BtnHoldReveal")
    $btnToggleMask       = $window.FindName("BtnToggleMask")
    $txtTargetPath       = $window.FindName("TxtTargetPath")
    $btnInspectPath      = $window.FindName("BtnInspectPath")
    $btnBrowseFolder     = $window.FindName("BtnBrowseFolder")
    $btnPasteClip        = $window.FindName("BtnPasteClip")
    $btnModeApp          = $window.FindName("BtnModeApp")
    $btnModeDrive        = $window.FindName("BtnModeDrive")
    $txtFilter           = $window.FindName("TxtFilter")
    $viewApp             = $window.FindName("ViewApp")
    $viewDrive           = $window.FindName("ViewDrive")
    $appRowsContainer    = $window.FindName("AppRowsContainer")
    $driveCardsContainer = $window.FindName("DriveCardsContainer")
    $treeFolderView      = $window.FindName("TreeFolderView")
    $txtTreeTitle        = $window.FindName("TxtTreeTitle")
    $txtStatus           = $window.FindName("TxtStatus")

    # In-memory state (NEVER saved to JSON)
    $script:isMasked = $true
    $script:isHoldingReveal = $false
    $script:currentAppLocks = $AppLocks
    $script:currentDrives = $Drives

    # Initial Target Path Resolution
    if ($InitialPath -and (Test-Path -LiteralPath $InitialPath)) {
        $txtTargetPath.Text = $InitialPath
    } elseif ($AppLocks -and $AppLocks.Count -gt 0) {
        $firstLock = $AppLocks[0]
        $parentFolder = Split-Path -Parent $firstLock.FilePath
        if ($parentFolder -and (Test-Path -LiteralPath $parentFolder)) {
            $txtTargetPath.Text = $parentFolder
        } else {
            $txtTargetPath.Text = $firstLock.FilePath
        }
    } else {
        $candidateTrashes = @("E:\proj\trash-bin", "D:\proj\trash-bin", (Join-Path (Get-Location).Path "trash-bin"))
        $foundTrash = $candidateTrashes | Where-Object { (Test-Path -LiteralPath $_) -and (Get-ChildItem -LiteralPath $_ -ErrorAction SilentlyContinue).Count -gt 0 } | Select-Object -First 1
        if (-not $foundTrash) {
            $foundTrash = $candidateTrashes | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
        }
        if ($foundTrash) {
            $txtTargetPath.Text = $foundTrash
        } else {
            $txtTargetPath.Text = (Get-Location).Path
        }
    }

    # Drag window via header
    $headerDock.Add_MouseDown({
        if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) {
            $window.DragMove()
        }
    })

    # Drag & Drop handling on the Window
    $window.Add_PreviewDragOver({
        if ($_.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
            $_.Effects = [System.Windows.DragDropEffects]::Copy
            $_.Handled = $true
        }
    })

    $window.Add_Drop({
        if ($_.Data.GetDataPresent([System.Windows.DataFormats]::FileDrop)) {
            $dropped = $_.Data.GetData([System.Windows.DataFormats]::FileDrop)
            if ($dropped -and $dropped.Length -gt 0) {
                $txtTargetPath.Text = $dropped[0]
                $txtStatus.Text = "Target dropped: $($dropped[0]). Inspecting locks..."
                &$TriggerInspect
            }
        }
    })

    # Close on Escape or close button
    $btnClose.Add_Click({ $window.Close() })
    $window.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Escape) {
            $window.Close()
        }
    })

    # Mode switching
    $script:activeMode = "App"

    $SwitchToApp = {
        $script:activeMode = "App"
        $viewApp.Visibility = [System.Windows.Visibility]::Visible
        $viewDrive.Visibility = [System.Windows.Visibility]::Collapsed
        $btnModeApp.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E3A5F")
        $btnModeApp.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $btnModeDrive.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E1E22")
        $btnModeDrive.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        $txtStatus.Text = "Mode A active: Grouped by holding applications."
    }

    $SwitchToDrive = {
        $script:activeMode = "Drive"
        $viewApp.Visibility = [System.Windows.Visibility]::Collapsed
        $viewDrive.Visibility = [System.Windows.Visibility]::Visible
        $btnModeDrive.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E3A5F")
        $btnModeDrive.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $btnModeApp.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E1E22")
        $btnModeApp.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        $txtStatus.Text = "Mode B active: Grouped by disk drive & directory foldering."
    }

    $btnModeApp.Add_Click($SwitchToApp)
    $btnModeDrive.Add_Click($SwitchToDrive)

    # Effective unmasked helper
    $IsCurrentlyUnmasked = {
        return ($script:isHoldingReveal -or (-not $script:isMasked))
    }

    # Inspect Trigger Handler
    $TriggerInspect = {
        $target = $txtTargetPath.Text.Trim()
        $txtStatus.Text = "Inspecting locks for: $target..."
        if ($target -and (-not (Test-Path -LiteralPath $target))) {
            $candidateTrashes = @("E:\proj\trash-bin", "D:\proj\trash-bin", (Join-Path (Get-Location).Path "trash-bin"))
            $foundTrash = $candidateTrashes | Where-Object { (Test-Path -LiteralPath $_) -and (Get-ChildItem -LiteralPath $_ -ErrorAction SilentlyContinue).Count -gt 0 } | Select-Object -First 1
            if ($foundTrash) {
                $target = $foundTrash
                $txtTargetPath.Text = $foundTrash
            }
        }
        $snap = Get-LockInspectorSnapshot -TargetScope $target
        $script:currentAppLocks = $snap.AppLocks
        &$RenderAppRows
        $count = if ($script:currentAppLocks) { $script:currentAppLocks.Count } else { 0 }
        $txtStatus.Text = "Inspection complete. Found $count active lock(s) in scope."
    }

    $btnInspectPath.Add_Click($TriggerInspect)
    $txtTargetPath.Add_KeyDown({
        if ($_.Key -eq [System.Windows.Input.Key]::Return) {
            &$TriggerInspect
        }
    })

    $btnBrowseFolder.Add_Click({
        Add-Type -AssemblyName System.Windows.Forms
        $dlg = [System.Windows.Forms.FolderBrowserDialog]::new()
        $dlg.Description = "Select a folder to inspect for active file/folder locks"
        if ($dlg.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $txtTargetPath.Text = $dlg.SelectedPath
            &$TriggerInspect
        }
    })

    $btnPasteClip.Add_Click({
        try {
            $txt = [System.Windows.Clipboard]::GetText().Trim('"', "'", " ")
            if ($txt) {
                $txtTargetPath.Text = $txt
                &$TriggerInspect
            }
        } catch {
            $txtStatus.Text = "Could not paste clipboard: $_"
        }
    })

    # Render App Rows Cards (PolyClip TableView Row Card Style)
    $RenderAppRows = {
        $appRowsContainer.Children.Clear()
        $filter = if ($txtFilter.Text) { $txtFilter.Text.Trim().ToLower() } else { "" }
        $unmask = &$IsCurrentlyUnmasked

        if (-not $script:currentAppLocks -or $script:currentAppLocks.Count -eq 0) {
            $emptyBdr = [System.Windows.Controls.Border]::new()
            $emptyBdr.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161618")
            $emptyBdr.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#27272A")
            $emptyBdr.BorderThickness = [System.Windows.Thickness]::new(1)
            $emptyBdr.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $emptyBdr.Padding = [System.Windows.Thickness]::new(20)
            $emptyBdr.Margin = [System.Windows.Thickness]::new(0, 8, 0, 0)

            $tb = [System.Windows.Controls.TextBlock]::new()
            $tb.Text = "No active file locks or sharing violations detected in this scope.`nAll files are clear and readable."
            $tb.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $tb.FontSize = 13
            $tb.TextAlignment = [System.Windows.TextAlignment]::Center
            $emptyBdr.Child = $tb
            [void]$appRowsContainer.Children.Add($emptyBdr)
            return
        }

        foreach ($lock in $script:currentAppLocks) {
            $rawPath = $lock.FilePath
            $displayPath = Format-PrivacyMaskString -InputString $rawPath -Unmask $unmask

            if ($filter -and ($lock.FileName.ToLower().IndexOf($filter) -lt 0) -and ($lock.ProcessName.ToLower().IndexOf($filter) -lt 0) -and ($displayPath.ToLower().IndexOf($filter) -lt 0)) {
                continue
            }

            $rowBdr = [System.Windows.Controls.Border]::new()
            $rowBdr.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#161618")
            $rowBdr.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#27272A")
            $rowBdr.BorderThickness = [System.Windows.Thickness]::new(1)
            $rowBdr.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $rowBdr.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6)
            $rowBdr.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)

            $grid = [System.Windows.Controls.Grid]::new()
            $col0 = [System.Windows.Controls.ColumnDefinition]::new(); $col0.Width = [System.Windows.GridLength]::new(190)
            $col1 = [System.Windows.Controls.ColumnDefinition]::new(); $col1.Width = [System.Windows.GridLength]::new(190)
            $col2 = [System.Windows.Controls.ColumnDefinition]::new(); $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $col3 = [System.Windows.Controls.ColumnDefinition]::new(); $col3.Width = [System.Windows.GridLength]::new(170)
            $col4 = [System.Windows.Controls.ColumnDefinition]::new(); $col4.Width = [System.Windows.GridLength]::new(250)
            $grid.ColumnDefinitions.Add($col0)
            $grid.ColumnDefinitions.Add($col1)
            $grid.ColumnDefinitions.Add($col2)
            $grid.ColumnDefinitions.Add($col3)
            $grid.ColumnDefinitions.Add($col4)

            # Col 0: Process Name & PID
            $pnlProc = [System.Windows.Controls.StackPanel]::new()
            $pnlProc.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $txtProc = [System.Windows.Controls.TextBlock]::new()
            $txtProc.Text = "$($lock.ProcessName)"
            $txtProc.FontWeight = [System.Windows.FontWeights]::Bold
            $txtProc.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            $txtProc.VerticalAlignment = [System.Windows.VerticalAlignment]::Center

            $txtPid = [System.Windows.Controls.TextBlock]::new()
            $txtPid.Text = if ($lock.ProcessId -and $lock.ProcessId -ne "-") { " (PID: $($lock.ProcessId))" } else { "" }
            $txtPid.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#71717A")
            $txtPid.FontSize = 11
            $txtPid.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            [void]$pnlProc.Children.Add($txtProc)
            [void]$pnlProc.Children.Add($txtPid)
            [System.Windows.Controls.Grid]::SetColumn($pnlProc, 0)

            # Col 1: File Name
            $txtFile = [System.Windows.Controls.TextBlock]::new()
            $txtFile.Text = "$($lock.FileName)"
            $txtFile.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtFile.FontWeight = [System.Windows.FontWeights]::SemiBold
            $txtFile.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            [System.Windows.Controls.Grid]::SetColumn($txtFile, 1)

            # Col 2: File Path (Selectable TextBox PolyClip style)
            $boxPath = [System.Windows.Controls.TextBox]::new()
            $boxPath.Text = $displayPath
            $boxPath.IsReadOnly = $true
            $boxPath.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#0D0D10")
            $boxPath.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#E4E4E7")
            $boxPath.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#27272A")
            $boxPath.BorderThickness = [System.Windows.Thickness]::new(1)
            $boxPath.Padding = [System.Windows.Thickness]::new(4, 2, 4, 2)
            $boxPath.FontFamily = [System.Windows.Media.FontFamily]::new("Consolas")
            $boxPath.FontSize = 11
            $boxPath.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            [System.Windows.Controls.Grid]::SetColumn($boxPath, 2)

            # Col 3: Status Badge
            $badge = [System.Windows.Controls.Border]::new()
            $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2A1E08")
            $badge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#78350F")
            $badge.BorderThickness = [System.Windows.Thickness]::new(1)
            $badge.CornerRadius = [System.Windows.CornerRadius]::new(3)
            $badge.Padding = [System.Windows.Thickness]::new(6, 2, 6, 2)
            $badge.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center
            $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $txtBadge = [System.Windows.Controls.TextBlock]::new()
            $txtBadge.Text = if ($lock.LockMode) { $lock.LockMode } else { "Locked (In-Use)" }
            $txtBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#F59E0B")
            $txtBadge.FontSize = 11
            $badge.Child = $txtBadge
            [System.Windows.Controls.Grid]::SetColumn($badge, 3)

            # Col 4: Action Buttons (Reveal, Re-test, Unlock)
            $pnlAct = [System.Windows.Controls.StackPanel]::new()
            $pnlAct.Orientation = [System.Windows.Controls.Orientation]::Horizontal
            $pnlAct.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Center

            $targetActualPath = $rawPath

            # 1. Reveal in Explorer
            $btnReveal = [System.Windows.Controls.Button]::new()
            $btnReveal.Content = "Reveal"
            $btnReveal.Tag = $rawPath
            $btnReveal.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
            $btnReveal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            $btnReveal.Margin = [System.Windows.Thickness]::new(2, 0, 2, 0)
            $btnReveal.Padding = [System.Windows.Thickness]::new(7, 2, 7, 2)
            $btnReveal.ToolTip = "Reveal and select item in File Explorer"
            $btnReveal.Add_Click({
                param($sender, $e)
                $rowPath = [string]$sender.Tag
                if ($rowPath -and (Test-Path -LiteralPath $rowPath)) {
                    [System.Diagnostics.Process]::Start("explorer.exe", "/select,`"$rowPath`"") | Out-Null
                    $txtStatus.Text = "Revealed in Explorer: $(Split-Path -Leaf $rowPath)"
                }
            })
            [void]$pnlAct.Children.Add($btnReveal)

            # 2. Re-test Button
            $btnProbe = [System.Windows.Controls.Button]::new()
            $btnProbe.Content = "Re-test"
            $btnProbe.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E1E22")
            $btnProbe.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
            $btnProbe.Margin = [System.Windows.Thickness]::new(2, 0, 2, 0)
            $btnProbe.Padding = [System.Windows.Thickness]::new(7, 2, 7, 2)
            $btnProbe.ToolTip = "Check if lock on this resource has cleared"

            # 3. UNLOCK Button
            $btnUnlock = [System.Windows.Controls.Button]::new()
            $btnUnlock.Content = "Unlock"
            $btnUnlock.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#D97706")
            $btnUnlock.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
            $btnUnlock.FontWeight = [System.Windows.FontWeights]::Bold
            $btnUnlock.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#B45309")
            $btnUnlock.Margin = [System.Windows.Thickness]::new(2, 0, 2, 0)
            $btnUnlock.Padding = [System.Windows.Thickness]::new(10, 2, 10, 2)
            $btnUnlock.ToolTip = "Force unlock this resource by closing handles and terminating holding processes"

            $rowCtx = [PSCustomObject]@{
                Path      = $rawPath
                Badge     = $badge
                TxtBadge  = $txtBadge
                BtnUnlock = $btnUnlock
            }
            $btnProbe.Tag = $rowCtx
            $btnUnlock.Tag = $rowCtx

            $btnProbe.Add_Click({
                param($sender, $e)
                $ctx = $sender.Tag
                if (-not $ctx -or [string]::IsNullOrWhiteSpace($ctx.Path)) { return }
                $isStill = Test-FileIsLocked -Path $ctx.Path
                if (-not $isStill) {
                    $ctx.Badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
                    $ctx.Badge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#047857")
                    $ctx.TxtBadge.Text = "Clear (Unlocked)"
                    $ctx.TxtBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                    $ctx.BtnUnlock.Content = "Unlocked"
                    $ctx.BtnUnlock.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
                    $ctx.BtnUnlock.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#047857")
                    $ctx.BtnUnlock.IsEnabled = $false
                    $txtStatus.Text = "Status checked: $(Split-Path -Leaf $ctx.Path) is no longer locked."
                } else {
                    $txtStatus.Text = "Status checked: $(Split-Path -Leaf $ctx.Path) is STILL LOCKED."
                }
            })
            [void]$pnlAct.Children.Add($btnProbe)

            $btnUnlock.Add_Click({
                param($sender, $e)
                $ctx = $sender.Tag
                try {
                    if (-not $ctx -or [string]::IsNullOrWhiteSpace($ctx.Path)) { return }
                    $txtStatus.Text = "Unlocking $(Split-Path -Leaf $ctx.Path)..."
                    $ctx.BtnUnlock.IsEnabled = $false
                    $ctx.BtnUnlock.Content = "Unlocking..."

                    # Execute multi-tier unlock protocol
                    $isUnlocked = Unlock-FileOrFolder -Path $ctx.Path
                    if ($isUnlocked) {
                        $ctx.Badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
                        $ctx.Badge.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#047857")
                        $ctx.TxtBadge.Text = "Clear (Unlocked)"
                        $ctx.TxtBadge.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
                        $ctx.BtnUnlock.Content = "Unlocked"
                        $ctx.BtnUnlock.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#064E3B")
                        $ctx.BtnUnlock.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#047857")
                        $ctx.BtnUnlock.IsEnabled = $false
                        $txtStatus.Text = "SUCCESS: $(Split-Path -Leaf $ctx.Path) has been UNLOCKED!"
                    } else {
                        $ctx.BtnUnlock.IsEnabled = $true
                        $ctx.BtnUnlock.Content = "Unlock"
                        $txtStatus.Text = "Attempted unlock on $(Split-Path -Leaf $ctx.Path). If lock persists, please close any external terminal/VS Code tab open to this folder or run as Administrator."
                    }
                } catch {
                    if ($ctx -and $ctx.BtnUnlock) {
                        $ctx.BtnUnlock.IsEnabled = $true
                        $ctx.BtnUnlock.Content = "Unlock"
                    }
                    $txtStatus.Text = "Unlock error: $_"
                }
            })
            [void]$pnlAct.Children.Add($btnUnlock)

            [System.Windows.Controls.Grid]::SetColumn($pnlAct, 4)

            [void]$grid.Children.Add($pnlProc)
            [void]$grid.Children.Add($txtFile)
            [void]$grid.Children.Add($boxPath)
            [void]$grid.Children.Add($badge)
            [void]$grid.Children.Add($pnlAct)
            $rowBdr.Child = $grid
            [void]$appRowsContainer.Children.Add($rowBdr)
        }
    }

    # Render Drive Overview Cards (PolyClip Card Style with Privacy Masking)
    $RenderDriveCards = {
        $driveCardsContainer.Children.Clear()
        $unmask = &$IsCurrentlyUnmasked

        foreach ($d in $script:currentDrives) {
            $rawLabel = $d.VolumeLabel
            $displayLabel = Format-PrivacyMaskString -InputString $rawLabel -Unmask $unmask

            $card = [System.Windows.Controls.Border]::new()
            $card.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E1E24")
            $card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#2D2D33")
            $card.BorderThickness = [System.Windows.Thickness]::new(1)
            $card.CornerRadius = [System.Windows.CornerRadius]::new(6)
            $card.Padding = [System.Windows.Thickness]::new(10)
            $card.Margin = [System.Windows.Thickness]::new(0, 0, 0, 8)
            $card.Cursor = [System.Windows.Input.Cursors]::Hand

            $dock = [System.Windows.Controls.DockPanel]::new()
            $tbTitle = [System.Windows.Controls.TextBlock]::new()
            $tbTitle.Text = "$($d.DriveLetter) [$displayLabel]"
            $tbTitle.FontWeight = [System.Windows.FontWeights]::Bold
            $tbTitle.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            [System.Windows.Controls.DockPanel]::SetDock($tbTitle, [System.Windows.Controls.Dock]::Top)

            $tbMetrics = [System.Windows.Controls.TextBlock]::new()
            $tbMetrics.Text = "Free: $($d.FreeGB) GB / $($d.TotalGB) GB ($($d.PercentFree)% free)"
            $tbMetrics.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $tbMetrics.FontSize = 11
            $tbMetrics.Margin = [System.Windows.Thickness]::new(0, 4, 0, 0)
            [System.Windows.Controls.DockPanel]::SetDock($tbMetrics, [System.Windows.Controls.Dock]::Bottom)

            [void]$dock.Children.Add($tbTitle)
            [void]$dock.Children.Add($tbMetrics)
            $card.Child = $dock

            $card.Tag = $d.DriveLetter
            $card.Add_MouseDown({
                param($sender, $e)
                $drv = [string]$sender.Tag
                $txtTreeTitle.Text = "Interactive Directory Foldering - Drive $drv"
                $treeFolderView.Items.Clear()
                $root = [System.Windows.Controls.TreeViewItem]::new()
                $root.Header = "$drv\"
                $root.IsExpanded = $true

                $dirs = Get-ChildItem -LiteralPath "$drv\" -Directory -ErrorAction SilentlyContinue | Select-Object -First 30
                foreach ($dir in $dirs) {
                    $item = [System.Windows.Controls.TreeViewItem]::new()
                    $maskedDirName = Format-PrivacyMaskString -InputString $dir.Name -Unmask (&$IsCurrentlyUnmasked)
                    $item.Header = "[DIR] $maskedDirName"
                    $item.Tag = $dir.FullName
                    $item.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
                    $item.Add_Selected({
                        param($sItem, $eItem)
                        $txtTargetPath.Text = [string]$sItem.Tag
                    })
                    [void]$root.Items.Add($item)
                }

                $files = Get-ChildItem -LiteralPath "$drv\" -File -ErrorAction SilentlyContinue | Select-Object -First 20
                foreach ($file in $files) {
                    $item = [System.Windows.Controls.TreeViewItem]::new()
                    $maskedFileName = Format-PrivacyMaskString -InputString $file.Name -Unmask (&$IsCurrentlyUnmasked)
                    $item.Header = "[FILE] $maskedFileName"
                    $item.Tag = $file.FullName
                    $item.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#A1A1AA")
                    $item.Add_Selected({
                        param($sItem, $eItem)
                        $txtTargetPath.Text = [string]$sItem.Tag
                    })
                    [void]$root.Items.Add($item)
                }

                [void]$treeFolderView.Items.Add($root)
                $txtStatus.Text = "Loaded top-level directory tree for drive $drv. Click item to set inspection target."
            })

            [void]$driveCardsContainer.Children.Add($card)
        }
    }

    # 1. HOLD-TO-REVEAL LOGIC (Mouse Press / Release)
    $btnHoldReveal.Add_PreviewMouseDown({
        $script:isHoldingReveal = $true
        $btnHoldReveal.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E3A5F")
        $btnHoldReveal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
        $txtStatus.Text = "HOLDING REVEAL: Sensitive data unmasked temporarily."
        &$RenderAppRows
        &$RenderDriveCards
    })

    $btnHoldReveal.Add_PreviewMouseUp({
        $script:isHoldingReveal = $false
        $btnHoldReveal.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#1E293B")
        $btnHoldReveal.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#94A3B8")
        $txtStatus.Text = "Released reveal: Reverted to default mask state."
        &$RenderAppRows
        &$RenderDriveCards
    })

    # 2. CLICK-TO-TOGGLE LOGIC (Mask ON / OFF)
    $btnToggleMask.Add_Click({
        $script:isMasked = -not $script:isMasked
        if ($script:isMasked) {
            $btnToggleMask.Content = "Mask: ON (2-Letter)"
            $btnToggleMask.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#065F46")
            $btnToggleMask.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#34D399")
            $txtStatus.Text = "Privacy Mask active: Sensitive identifiers masked to 2 letters."
        } else {
            $btnToggleMask.Content = "Mask: OFF (Revealed)"
            $btnToggleMask.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#7F1D1D")
            $btnToggleMask.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FCA5A5")
            $txtStatus.Text = "Privacy Mask OFF: Sensitive data revealed. (Session-only, not saved to JSON)."
        }
        &$RenderAppRows
        &$RenderDriveCards
    })

    # Search / Filter real-time typing
    $txtFilter.Add_TextChanged({
        &$RenderAppRows
    })

    # Refresh Button Handler (Active Re-query)
    $btnRefresh.Add_Click({
        $txtStatus.Text = "Refreshing file locks..."
        $target = $txtTargetPath.Text.Trim()
        if ($target -and (-not (Test-Path -LiteralPath $target))) {
            $candidateTrashes = @("E:\proj\trash-bin", "D:\proj\trash-bin", (Join-Path (Get-Location).Path "trash-bin"))
            $foundTrash = $candidateTrashes | Where-Object { (Test-Path -LiteralPath $_) -and (Get-ChildItem -LiteralPath $_ -ErrorAction SilentlyContinue).Count -gt 0 } | Select-Object -First 1
            if ($foundTrash) {
                $target = $foundTrash
                $txtTargetPath.Text = $foundTrash
            } else {
                $target = ""
            }
        }
        $snap = Get-LockInspectorSnapshot -TargetScope $target
        $script:currentAppLocks = $snap.AppLocks
        $script:currentDrives = $snap.Drives
        &$RenderAppRows
        &$RenderDriveCards
        $count = if ($script:currentAppLocks) { $script:currentAppLocks.Count } else { 0 }
        $txtStatus.Text = "Refreshed at $(Get-Date -Format 'HH:mm:ss'). Active locks: $count."
    })

    # Initial Render (Default Masked)
    &$RenderAppRows
    &$RenderDriveCards

    # Auto-load first drive in tree if available
    if ($Drives -and $Drives.Count -gt 0) {
        $firstLetter = $Drives[0].DriveLetter
        $txtTreeTitle.Text = "Interactive Directory Foldering - Drive $firstLetter"
        $root = [System.Windows.Controls.TreeViewItem]::new()
        $root.Header = "$firstLetter\"
        $root.IsExpanded = $true
        $dirs = Get-ChildItem -LiteralPath "$firstLetter\" -Directory -ErrorAction SilentlyContinue | Select-Object -First 30
        foreach ($dir in $dirs) {
            $item = [System.Windows.Controls.TreeViewItem]::new()
            $maskedDirName = Format-PrivacyMaskString -InputString $dir.Name -Unmask (&$IsCurrentlyUnmasked)
            $item.Header = "[DIR] $maskedDirName"
            $item.Tag = $dir.FullName
            $item.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#38BDF8")
            $item.Add_Selected({
                param($sItem, $eItem)
                $txtTargetPath.Text = [string]$sItem.Tag
            })
            [void]$root.Items.Add($item)
        }
        [void]$treeFolderView.Items.Add($root)
    }

    [void]$window.ShowDialog()
}

Export-ModuleMember -Function Show-FileLockPanel, Format-PrivacyMaskString
