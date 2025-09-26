Add-Type -AssemblyName PresentationFramework
function SST_CreateHealthLayout {
    [CmdletBinding()]
    param (
        $SST_UCOBJ,
        $SST_MainStackPName,
        $SST_GridFuncName = $null,
        $SST_StackPFuncName,
        $SST_StackPResultsName,
        $SST_LabelVisuNameofCheck,
        $SST_LabelVisuResultsofCheck,
        $SST_LabelColorForCheck,
        $SST_DeviceID,
        $SST_LabelNameHelper = $null,
        $DummyNameSTP = $null,
        [int]$SST_MainStackPWith = 840,
        [bool]$DataGridOption = $false,
        [bool]$DataGridSecOption = $false,
        [bool]$Storage = $false
    )
    
    begin {

    }
    
    process {
        # ==============================
        # Gibt dem Main StackPanel einen Namen
        # ==============================
        # Haupt-StackPanel benötigt für jedes Device
        $DummyName = $SST_UCOBJ.FindName($SST_MainStackPName)
        if([string]::IsNullOrWhiteSpace($DummyName)){ 
            $SST_MainStackPName = $SST_MainStackPName.trim()
        }else{
            $DummyName = $SST_MainStackPName.Trim()
            $SST_MainStackPName = $SST_MainStackPName.trim()
        }
        
        if([string]::IsNullOrWhiteSpace($DummyName)){
            $SST_WPHealthResaults = $SST_UCOBJ.FindName("WP_HealthResaults")
            $SST_WPHealthResaults.MinWidth = 400
            $SST_WPHealthResaults.MinHeight = 400
            $SST_WPHealthResaults.Orientation="Horizontal"
            #$SST_WPHealthResaults.Background=[Windows.Media.Brushes]::"#FFD3D3D3"
            $MainDeviceStackP = New-Object Windows.Controls.StackPanel
            $MainDeviceStackP.Name = $SST_MainStackPName
            $SST_UCOBJ.RegisterName($MainDeviceStackP.Name, $MainDeviceStackP)
            $SST_WPHealthResaults.Children.Add($MainDeviceStackP)
        }


        # ==============================
        # Erstes Grid (grid0)
        # ==============================
        if(([string]::IsNullOrWhiteSpace($SST_UCOBJ.FindName($SST_GridFuncName)))-and (!([string]::IsNullOrWhiteSpace($DummyName)))){
            $MainStackPName = $SST_UCOBJ.FindName("$SST_MainStackPName")
            $MainFuncGrid = New-Object Windows.Controls.Grid
            $GridFuncCloDef = New-Object Windows.Controls.ColumnDefinition
            $GridResultsCloDef = New-Object Windows.Controls.ColumnDefinition
            $MainFuncGrid.Name = "$SST_GridFuncName"
            $MainFuncGrid.Margin = "5"
            #$MainFuncGrid.MinWidth = 400
            $MainFuncGrid.MaxWidth = 1200
            $MainFuncGrid.HorizontalAlignment = "Left"
            $MainFuncGrid.Background = [Windows.Media.Brushes]::"#FFD3D3D3"

            $MainFuncGridBorder = New-Object Windows.Controls.Border
            $MainFuncGridBorder.BorderBrush = [Windows.Media.Brushes]::Gray
            $MainFuncGridBorder.BorderThickness = 2
            [Windows.Controls.Grid]::SetColumnSpan($MainFuncGridBorder,2)
            $MainFuncGrid.Children.Add($MainFuncGridBorder)

            # ColumnDefinitions hinzufügen
            $GridFuncCloDef.Width = "180"
            $GridResultsCloDef.Width = $SST_MainStackPWith
            $MainFuncGrid.ColumnDefinitions.Add($GridFuncCloDef)
            $MainFuncGrid.ColumnDefinitions.Add($GridResultsCloDef)

            # StackPanel links (Check)
            $StackPFunc = New-Object Windows.Controls.StackPanel
            $StackPFunc.Name = "$SST_StackPFuncName"
            $StackPFunc.Margin = "0,10"
            [Windows.Controls.Grid]::SetColumn($StackPFunc,0)
            $StackPFunc.HorizontalAlignment = "Center"
            $StackPFunc.VerticalAlignment = "Center"
            $LabelNameoftheCheck = New-Object Windows.Controls.Label
            $LabelNameoftheCheck.Name = $SST_LabelVisuNameofCheck+"_"+$SST_DeviceID
            $LabelNameoftheCheck.Width = "160"
            $LabelNameoftheCheck.HorizontalContentAlignment = "Center"
            $LabelNameoftheCheck.HorizontalAlignment = "Center"
            $LabelNameoftheCheck.VerticalAlignment = "Center"
            $LabelNameoftheCheck.FontSize = 16
            #$LabelNameoftheCheck.Foreground = [Windows.Media.Brushes]::Black
            $LabelNameoftheCheck.FontWeight = "Bold"
            $LabelNameoftheCheck.Padding = 5
            $LabelNameoftheCheck.Content = "$SST_LabelVisuNameofCheck"
            $LabelNameoftheCheck.Background = [Windows.Media.Brushes]::Green

            $StackPFunc.Children.Add($LabelNameoftheCheck)
            # StackPanels ins Grid
            $MainFuncGrid.Children.Add($StackPFunc) | Out-Null
            
            # StackPanel rechts (Ergebnis)
            $StackPResults = New-Object Windows.Controls.StackPanel
            $StackPResults.Name = "$SST_StackPResultsName"
            $StackPResults.Margin = "0,5,5,5"
            [Windows.Controls.Grid]::SetColumn($StackPResults,1)
            $MainFuncGrid.Children.Add($StackPResults) | Out-Null
            $SST_UCOBJ.RegisterName($LabelNameoftheCheck.Name, $LabelNameoftheCheck)
            $SST_UCOBJ.RegisterName($StackPResults.Name, $StackPResults)
            $SST_UCOBJ.RegisterName($MainFuncGrid.Name, $MainFuncGrid)

            $MainStackPName.Children.Add($MainFuncGrid) | Out-Null
        }

        if(!($DataGridOption)){
            if(([string]::IsNullOrWhiteSpace($SST_UCOBJ.FindName($SST_LabelNameHelper)))-and(!([string]::IsNullOrWhiteSpace($SST_LabelVisuResultsofCheck)))){
                $LabelResultsoftheCheck = New-Object Windows.Controls.Label
                $StackPResults = $SST_UCOBJ.FindName("$SST_StackPResultsName")

                $LabelNameoftheCheck = $SST_UCOBJ.FindName($SST_LabelVisuNameofCheck+"_"+$SST_DeviceID)

                If(("#FF008000" -eq $LabelNameoftheCheck.Background) -and ($SST_LabelColorForCheck -eq "red")){
                    $LabelNameoftheCheck.Background = [Windows.Media.Brushes]::LightCoral
                }elseif (("#FFFFFF00" -eq $LabelNameoftheCheck.Background) -and ($SST_LabelColorForCheck -eq "red")) {
                    $LabelNameoftheCheck.Background = [Windows.Media.Brushes]::LightCoral
                }elseif ((("#FF008000" -eq $LabelNameoftheCheck.Background) -and ($SST_LabelColorForCheck -eq "yellow"))) {
                    $LabelNameoftheCheck.Background = [Windows.Media.Brushes]::Yellow
                }

                $LabelResultsoftheCheck.Name = "$SST_LabelNameHelper"
                $LabelResultsoftheCheck.Content = "$SST_LabelVisuResultsofCheck"
                $LabelResultsoftheCheck.FontSize = "14"

                $SST_UCOBJ.RegisterName($LabelResultsoftheCheck.Name, $LabelResultsoftheCheck)

                $StackPResults.Children.Add($LabelResultsoftheCheck) | Out-Null

            }
        }else{
            # DataGrid erstellen
            $DGQuorumStatusInfo = New-Object Windows.Controls.DataGrid
            $StackPResults = $SST_UCOBJ.FindName("$SST_StackPResultsName")
            $DGQuorumStatusInfo.Name = ($SST_LabelVisuNameofCheck+""+$SST_LabelColorForCheck+"_"+$SST_DeviceID)
            $DGQuorumStatusInfo.Margin = "10"
            $DGQuorumStatusInfo.MaxHeight = 400
            $DGQuorumStatusInfo.AutoGenerateColumns = $false
            # Style für DataGrid -> wenn keine Items -> ausblenden
            $dgStyle = New-Object Windows.Style([Windows.Controls.DataGrid])
            $trigger = New-Object Windows.Trigger
            $trigger.Property = [Windows.Controls.DataGrid]::HasItemsProperty
            $trigger.Value = $false
            $setter = New-Object Windows.Setter([Windows.UIElement]::VisibilityProperty, [Windows.Visibility]::Collapsed)
            $trigger.Setters.Add($setter)
            $dgStyle.Triggers.Add($trigger)
            $DGQuorumStatusInfo.Style = $dgStyle
            # Spalten hinzufügen
            $col1 = New-Object Windows.Controls.DataGridTextColumn
            $col1.Header = "Quorum ID"
            $col1.Width = "Auto"
            $col1.Binding = New-Object Windows.Data.Binding("QuorumIndex")
            $col1.IsReadOnly = $true
            $DGQuorumStatusInfo.Columns.Add($col1)

            $col2 = New-Object Windows.Controls.DataGridTextColumn
            $col2.Header = "Status"
            $col2.Width = "Auto"
            $col2.Binding = New-Object Windows.Data.Binding("Status")
            $col2.IsReadOnly = $true
            $DGQuorumStatusInfo.Columns.Add($col2)

            $col3 = New-Object Windows.Controls.DataGridTextColumn
            $col3.Header = "ID"
            $col3.Width = "Auto"
            $col3.Binding = New-Object Windows.Data.Binding("ID")
            $col3.IsReadOnly = $true
            $DGQuorumStatusInfo.Columns.Add($col3)

            $col4 = New-Object Windows.Controls.DataGridTextColumn
            $col4.Header = "Name"
            $col4.Width = "Auto"
            $col4.Binding = New-Object Windows.Data.Binding("Name")
            $col4.IsReadOnly = $true
            $DGQuorumStatusInfo.Columns.Add($col4)

            $col5 = New-Object Windows.Controls.DataGridTextColumn
            $col5.Header = "Site Name"
            $col5.Width = "Auto"
            $col5.Binding = New-Object Windows.Data.Binding("SiteName")
            $col5.IsReadOnly = $true
            $DGQuorumStatusInfo.Columns.Add($col5)

            # DataGrid jetzt in dein Grid oder Window einfügen:
            $SST_UCOBJ.RegisterName($DGQuorumStatusInfo.Name, $DGQuorumStatusInfo)

            $StackPResults.Children.Add($DGQuorumStatusInfo) | Out-Null
        }
        if($DataGridSecOption){
            # Neues DataGrid
            $DGSecurityStatusInfoText = New-Object Windows.Controls.DataGrid
            $DGSecurityStatusInfoText.Name = "DGforKeyValue$($SST_LabelVisuNameofCheck)StatusInfoText$SST_DeviceID"
            $DGSecurityStatusInfoText.Margin = "10,10,10,5"
            $DGSecurityStatusInfoText.MaxHeight = 400
            $DGSecurityStatusInfoText.AutoGenerateColumns = $false

            # --- Style: Collapsed wenn keine Items ---
            $DGStyle = New-Object Windows.Style([Windows.Controls.DataGrid])
            $StyleTriggerNoItems = New-Object Windows.Trigger
            $StyleTriggerNoItems.Property = [Windows.Controls.DataGrid]::HasItemsProperty
            $StyleTriggerNoItems.Value = $false
            $setterCollapsed = New-Object Windows.Setter([Windows.UIElement]::VisibilityProperty, [Windows.Visibility]::Collapsed)
            $StyleTriggerNoItems.Setters.Add($setterCollapsed)
            $DGStyle.Triggers.Add($StyleTriggerNoItems)
            $DGSecurityStatusInfoText.Style = $DGStyle

            # --- Column 1: Attribute Name ---
            $colAttributeName = New-Object Windows.Controls.DataGridTextColumn
            $colAttributeName.Header = "Name"
            $colAttributeName.Width  = "Auto"
            $colAttributeName.IsReadOnly = $true
            $colAttributeName.Binding = New-Object Windows.Data.Binding("Key")
            # --- Column 2: Configured Value mit Tooltip ---
            $colConfiguredValue = New-Object Windows.Controls.DataGridTextColumn
            $colConfiguredValue.Header = "Set Value"
            $colConfiguredValue.Width  = "Auto"
            $colConfiguredValue.IsReadOnly = $true
            $colConfiguredValue.Binding = New-Object Windows.Data.Binding("Value")
            # --- Columns zum DataGrid hinzufügen ---
            $DGSecurityStatusInfoText.Columns.Add($colAttributeName)    | Out-Null
            $DGSecurityStatusInfoText.Columns.Add($colConfiguredValue)  | Out-Null

            if($Storage){
                $styleConfigured = New-Object Windows.Style([Windows.Controls.DataGridCell])
                $styleConfigured.Setters.Add((New-Object Windows.Setter([Windows.Controls.ToolTipService]::ToolTipProperty, "Your current security settings.")))
                $colConfiguredValue.CellStyle = $styleConfigured
                $styleRecommended = New-Object Windows.Style([Windows.Controls.DataGridCell])
                $styleRecommended.Setters.Add((New-Object Windows.Setter([Windows.Controls.ToolTipService]::ToolTipProperty, "Shows the most common settings from the field, which do not claim to be the ideal solution for every environment.")))
                $colRecommendedValue.CellStyle = $styleRecommended
                # --- Column 3: Recommended Value mit Tooltip ---
                $colRecommendedValue = New-Object Windows.Controls.DataGridTextColumn
                $colRecommendedValue.Header = "Field Experiences*"
                $colRecommendedValue.Width  = "Auto"
                $colRecommendedValue.IsReadOnly = $true
                $colRecommendedValue.Binding = New-Object Windows.Data.Binding("RecommendedValue")
                # --- Columns zum DataGrid hinzufügen ---
                $DGSecurityStatusInfoText.Columns.Add($colRecommendedValue) | Out-Null
            }
            
            # DataGrid jetzt in dein Grid oder Window einfügen:
            $SST_UCOBJ.RegisterName($DGSecurityStatusInfoText.Name, $DGSecurityStatusInfoText)

            $StackPResults.Children.Add($DGSecurityStatusInfoText) | Out-Null

            # --- TextBox ---
            $TBSecurityStatusErrorMsg = New-Object Windows.Controls.TextBox
            $TBSecurityStatusErrorMsg.Name   = "TBforKeyValue$($SST_LabelVisuNameofCheck)StatusInfoText$SST_DeviceID"
            #$TBSecurityStatusErrorMsg.Text   = ""
            $TBSecurityStatusErrorMsg.Visibility = [Windows.Visibility]::Collapsed
            $TBSecurityStatusErrorMsg.IsReadOnly = $true
            $TBSecurityStatusErrorMsg.Background = [Windows.Media.Brushes]::Transparent
            $TBSecurityStatusErrorMsg.Foreground = [Windows.Media.Brushes]::Coral
            $TBSecurityStatusErrorMsg.Height     = 60
            $TBSecurityStatusErrorMsg.FontSize   = 14
            $TBSecurityStatusErrorMsg.BorderThickness = 0
            $TBSecurityStatusErrorMsg.TextWrapping    = "Wrap"
            $TBSecurityStatusErrorMsg.VerticalAlignment       = "Center"
            $TBSecurityStatusErrorMsg.VerticalContentAlignment = "Center"

            # Position im Grid (Spalte 2)
            $SST_UCOBJ.RegisterName($TBSecurityStatusErrorMsg.Name, $TBSecurityStatusErrorMsg)

            $StackPResults.Children.Add($TBSecurityStatusErrorMsg) | Out-Null

        }

    }
    
    end {
        
    }
}