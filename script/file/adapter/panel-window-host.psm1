<#
.SYNOPSIS
    PolyClip WPF Window Host & Runtime Dispatcher Adapter
.DESCRIPTION
    Hosts the WPF Window UI, initializes the dark-themed XAML interface,
    wires user interaction event handlers, manages edit overlays,
    and coordinates the non-blocking background DispatcherTimer for live clipboard inspection.
#>

function Show-LightweightPanel {
    Stop-Process -Name "TextInputHost" -ErrorAction SilentlyContinue

    Load-PersistentHistory
    $null = Get-ClipboardSnapshot

    if ($global:PolyClipHistory.Count -eq 0) {
        $welcomeCard = [PSCustomObject]@{
            Id            = "init"
            Timestamp     = (Get-Date -Format "HH:mm:ss")
            RawType       = "SYSTEM_READY"
            FileName      = "PolyClip Ready"
            FileSizeStr   = "-"
            IsOpenable    = $true
            OpenStatus    = "READY"
            Mode1_Text    = "PolyClip Active. Copy any file or text in VS Code/Explorer!"
            Mode2_Path    = (Get-Location).Path
            Mode3_Content = "Copy any file in VS Code or Explorer. Openable files (.md, code) will appear here in Green!"
            Mode4_File    = ""
        }
        $global:PolyClipHistory.Add($welcomeCard)
        Save-PersistentHistory
    }

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="PolyClip 4-Mode Panel"
        Height="570" Width="1020"
        WindowStartupLocation="CenterScreen"
        Background="#101012" Foreground="#E4E4E7"
        WindowStyle="None" AllowsTransparency="True" BorderThickness="1" BorderBrush="#27272A"
        FontFamily="Segoe UI, Consolas" FontSize="12">
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

        <!-- Pure Dark ScrollBar: Recolors track, thumb, and eliminates white slider -->
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
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="Bdr" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="3" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bdr" Property="Background" Value="#2A2A30"/>
                                <Setter TargetName="Bdr" Property="BorderBrush" Value="#454550"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bdr" Property="Background" Value="#141416"/>
                                <Setter TargetName="Bdr" Property="BorderBrush" Value="#202024"/>
                                <Setter Property="Foreground" Value="#52525B"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    
    <Grid Margin="12">
        <Grid Name="MainGrid">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/> <!-- Header -->
                <RowDefinition Height="Auto"/> <!-- Column Titles -->
                <RowDefinition Height="*"/>    <!-- Scrollable 4-Col Grid -->
                <RowDefinition Height="Auto"/> <!-- Bottom Actions -->
            </Grid.RowDefinitions>

            <!-- Header -->
            <DockPanel Grid.Row="0" Margin="0,0,0,10">
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Left">
                    <TextBlock Text="POLYCLIP" FontWeight="Bold" FontSize="15" Foreground="#38BDF8" VerticalAlignment="Center"/>
                    <TextBlock Text=" - 4-Column Panel" FontSize="12" Foreground="#71717A" Margin="6,2,0,0" VerticalAlignment="Center"/>
                    <TextBlock Text=" [Right-click row to set as #1 latest]" FontSize="11" Foreground="#A78BFA" Margin="12,3,0,0" VerticalAlignment="Center"/>
                </StackPanel>
                <Button Name="BtnClose" Content="X" Width="26" Height="24" DockPanel.Dock="Right" Background="Transparent" BorderThickness="0" Foreground="#A1A1AA" FontWeight="Bold"/>
                <Button Name="BtnRefresh" Content="Refresh" Width="90" DockPanel.Dock="Right" Background="#0284C7" Foreground="#FFFFFF" FontWeight="SemiBold" Margin="0,0,10,0"/>
                <Button Name="BtnToggleAll" Content="Show All: OFF" Width="110" DockPanel.Dock="Right" FontWeight="SemiBold" Margin="0,0,8,0"/>
                <TextBlock Text="[ESC to Close]" FontSize="11" Foreground="#52525B" DockPanel.Dock="Right" Margin="0,4,12,0" VerticalAlignment="Center"/>
            </DockPanel>

            <!-- Column Headers (5 Columns: i | CONTENT | FILE PATH | EXACT FILE | ACTIONS) -->
            <Border Grid.Row="1" Background="#161618" BorderBrush="#27272A" BorderThickness="1" CornerRadius="4" Padding="6" Margin="0,0,0,8">
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="34"/>    <!-- Col 0: INFO (i) -->
                        <ColumnDefinition Width="1.6*"/>  <!-- Col 1: CONTENT (TEXT / FILE PREVIEW) -->
                        <ColumnDefinition Width="1.2*"/>  <!-- Col 2: FILE PATH -->
                        <ColumnDefinition Width="1.2*"/>  <!-- Col 3: EXACT FILE (NAME | SIZE) -->
                        <ColumnDefinition Width="90"/>    <!-- Col 4: ACTIONS (COPY) -->
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="i" FontWeight="Bold" Foreground="#38BDF8" HorizontalAlignment="Center" ToolTip="Inspect &amp; Edit"/>
                    <TextBlock Grid.Column="1" Text="CONTENT" FontWeight="SemiBold" Foreground="#38BDF8" HorizontalAlignment="Center"/>
                    <TextBlock Grid.Column="2" Text="FILE PATH" FontWeight="SemiBold" Foreground="#34D399" HorizontalAlignment="Center"/>
                    <TextBlock Grid.Column="3" Text="EXACT FILE (NAME | SIZE)" FontWeight="SemiBold" Foreground="#F472B6" HorizontalAlignment="Center"/>
                    <TextBlock Grid.Column="4" Text="ACTIONS" FontWeight="SemiBold" Foreground="#94A3B8" HorizontalAlignment="Center"/>
                </Grid>
            </Border>

            <!-- Scrollable Content -->
            <ScrollViewer Grid.Row="2" Name="Scroller" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Margin="0,0,0,8">
                <StackPanel Name="RowsContainer" Margin="0,0,4,0"/>
            </ScrollViewer>

            <!-- Bottom Status Dock -->
            <DockPanel Grid.Row="3" Margin="0,4,0,0">
                <TextBlock Name="TxtStatus" Text="Click Copy or right-click row to copy &amp; promote to #1 latest." FontSize="11" Foreground="#A1A1AA" VerticalAlignment="Center"/>
            </DockPanel>
        </Grid>

        <!-- Edit Modal Overlay -->
        <Grid Name="EditOverlay" Visibility="Collapsed" Background="#E6000000">
            <Border Background="#16161A" BorderBrush="#3F3F46" BorderThickness="1" CornerRadius="6" Padding="14" Width="680" Height="380" VerticalAlignment="Center" HorizontalAlignment="Center">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <DockPanel Grid.Row="0" Margin="0,0,0,8">
                        <TextBlock Text="Edit Item Content" FontWeight="Bold" FontSize="14" Foreground="#38BDF8"/>
                        <TextBlock Name="EditItemInfo" Text="" FontSize="11" Foreground="#71717A" Margin="10,2,0,0"/>
                    </DockPanel>

                    <TextBox Grid.Row="1" Name="EditTextBox" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Background="#0D0D10" Foreground="#E4E4E7" BorderBrush="#27272A" FontFamily="Consolas, Segoe UI" FontSize="12" Padding="8"/>

                    <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,10,0,0">
                        <Button Name="BtnEditCancel" Content="Cancel" Width="80" Margin="0,0,8,0" Background="#27272A" Foreground="#A1A1AA"/>
                        <Button Name="BtnEditSaveOnly" Content="Save Only" Width="90" Margin="0,0,8,0" Background="#1E3A5F" Foreground="#38BDF8" FontWeight="SemiBold"/>
                        <Button Name="BtnEditSaveFirst" Content="Save &amp; Set at First" Width="130" Background="#065F46" Foreground="#34D399" FontWeight="Bold"/>
                    </StackPanel>
                </Grid>
            </Border>
        </Grid>
    </Grid>
</Window>
"@

    $reader = [System.Xml.XmlNodeReader]::new($xaml)
    $window = [System.Windows.Markup.XamlReader]::Load($reader)

    $script:rowsContainer   = $window.FindName("RowsContainer")
    $script:btnClose        = $window.FindName("BtnClose")
    $script:btnRefresh      = $window.FindName("BtnRefresh")
    $script:btnToggleAll    = $window.FindName("BtnToggleAll")
    $script:txtStatus       = $window.FindName("TxtStatus")
    $script:editOverlay     = $window.FindName("EditOverlay")
    $script:editTextBox     = $window.FindName("EditTextBox")
    $script:editItemInfo    = $window.FindName("EditItemInfo")
    $script:btnEditCancel   = $window.FindName("BtnEditCancel")
    $script:btnEditSaveOnly = $window.FindName("BtnEditSaveOnly")
    $script:btnEditSaveFirst= $window.FindName("BtnEditSaveFirst")

    $script:currentRenderCount = 0
    $script:activeEditItem = $null
    if ($null -eq $script:showAll) {
        $script:showAll = $false
    }

    # Edit Overlay Handlers
    $script:btnEditCancel.Add_Click({
        Close-EditModal
    })

    $script:btnEditSaveOnly.Add_Click({
        if ($script:activeEditItem) {
            $newVal = $script:editTextBox.Text
            if ($newVal -match '(?s)^\[string\]@\{(?<props>.*)\}(?:\.Mode1_Text)?\s*$' -or $newVal -match '(?s)^@\{(?<props>.*)\}\s*$') {
                $propsStr = $Matches['props']
                foreach ($pair in ($propsStr -split ';')) {
                    if ($pair -match '^\s*(?<k>[A-Za-z0-9_]+)\s*=\s*(?<v>.*)$') {
                        $k = $Matches['k'].Trim()
                        $v = $Matches['v'].Trim()
                        if ($k -in @('Id','Timestamp','RawType','DetectedPath','FileName','FileSizeStr','OpenStatus','Mode1_Text','Mode2_Path','Mode3_Content','Mode4_File')) {
                            $script:activeEditItem.$k = $v
                        } elseif ($k -eq 'IsOpenable') {
                            $script:activeEditItem.IsOpenable = [System.Convert]::ToBoolean($v)
                        }
                    }
                }
            } else {
                # Defensive check: unwrap if it looks like an object dump
                $cleanedVal = Unwrap-Mode1Text $newVal
                if ($script:activeEditItem.IsOpenable -and $script:activeEditItem.Mode3_Content) {
                    $script:activeEditItem.Mode3_Content = $cleanedVal
                } else {
                    $script:activeEditItem.Mode1_Text = $cleanedVal
                }
            }
            Save-PersistentHistory
            Render-AllRows
            Set-PanelStatus "Saved changes to item [$($script:activeEditItem.Timestamp)]."
        }
        Close-EditModal
    })

    $script:btnEditSaveFirst.Add_Click({
        if ($script:activeEditItem) {
            $newVal = $script:editTextBox.Text
            if ($newVal -match '(?s)^\[string\]@\{(?<props>.*)\}(?:\.Mode1_Text)?\s*$' -or $newVal -match '(?s)^@\{(?<props>.*)\}\s*$') {
                $propsStr = $Matches['props']
                foreach ($pair in ($propsStr -split ';')) {
                    if ($pair -match '^\s*(?<k>[A-Za-z0-9_]+)\s*=\s*(?<v>.*)$') {
                        $k = $Matches['k'].Trim()
                        $v = $Matches['v'].Trim()
                        if ($k -in @('Id','Timestamp','RawType','DetectedPath','FileName','FileSizeStr','OpenStatus','Mode1_Text','Mode2_Path','Mode3_Content','Mode4_File')) {
                            $script:activeEditItem.$k = $v
                        } elseif ($k -eq 'IsOpenable') {
                            $script:activeEditItem.IsOpenable = [System.Convert]::ToBoolean($v)
                        }
                    }
                }
            } else {
                # Defensive check: unwrap if it looks like an object dump
                $cleanedVal = Unwrap-Mode1Text $newVal
                if ($script:activeEditItem.IsOpenable -and $script:activeEditItem.Mode3_Content) {
                    $script:activeEditItem.Mode3_Content = $cleanedVal
                } else {
                    $script:activeEditItem.Mode1_Text = $cleanedVal
                }
            }
            Promote-ToFirst $script:activeEditItem
            Render-AllRows
            Set-PanelStatus "Saved & Promoted [$($script:activeEditItem.Timestamp)] to #1 Latest!"
        }
        Close-EditModal
    })

    # Initial render
    Render-AllRows

    $script:btnToggleAll.Add_Click({
        $script:showAll = -not $script:showAll
        Render-AllRows
        $msg = if ($script:showAll) { "Show All: ON ($($global:PolyClipHistory.Count) items)." } else { "Show All: OFF (latest 5 items)." }
        Set-PanelStatus $msg
    })

    $script:btnRefresh.ToolTip = "Refresh clipboard snapshot now"
    $script:btnRefresh.Add_Click({
        $snap = Get-ClipboardSnapshot
        Render-AllRows
        Set-PanelStatus ("Refreshed [" + $snap.RawType + "] at " + (Get-Date -Format 'HH:mm:ss'))
    })

    # Live-Watcher Timer: auto-detects copied files/text while panel is open
    $liveTimer = New-Object System.Windows.Threading.DispatcherTimer
    $liveTimer.Interval = [TimeSpan]::FromMilliseconds(1000)
    $liveTimer.Add_Tick({
        # Do not capture if an internal copy / promote / duplicate was just triggered
        if ([DateTime]::UtcNow -lt $global:PolyClipSuppressUntil) {
            return
        }
        $countBefore = $global:PolyClipHistory.Count
        $snap = Get-ClipboardSnapshot
        if ($snap -and $global:PolyClipHistory.Count -gt $countBefore) {
            Render-AllRows
            Set-PanelStatus ("Auto-detected new [" + $snap.RawType + "] at " + $snap.Timestamp)
        }
    })
    $liveTimer.Start()

    $script:btnClose.Add_Click({ $window.Close() })
    $window.Add_KeyDown({
        param($s, $e)
        if ($e.Key -eq [System.Windows.Input.Key]::Escape) {
            if ($script:editOverlay.Visibility -eq [System.Windows.Visibility]::Visible) {
                $script:editOverlay.Visibility = [System.Windows.Visibility]::Collapsed
            } else {
                $window.Close()
            }
        }
    })

    $window.Add_Closed({
        $liveTimer.Stop()
    })

    $window.ShowDialog() | Out-Null
}




