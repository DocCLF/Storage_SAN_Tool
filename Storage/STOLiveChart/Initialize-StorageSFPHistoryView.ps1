function Initialize-StorageSFPHistoryView {
    <#
    .SYNOPSIS
        Initializes the Storage SFP history viewer.

    .DESCRIPTION
        Initializes the SFP history viewer using the generic
        LiveCharts selector architecture.

        Selection hierarchy:

            Storage System
                -> FC Port / SFP
                    -> Metric / Series

        Multiple ports and multiple compatible metrics can be displayed
        simultaneously.

        Metrics from different UnitGroups cannot be selected together.

        The Storage-System selector is only visible when ports from more
        than one Storage system are available.

        The former single-port / comparison controls are retained only as
        legacy controls and are hidden by this initializer.

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER ViewRoot
        Root Window or UserControl of the viewer.

    .PARAMETER PortComboBox
        Legacy single-port ComboBox. Hidden by this initializer.

    .PARAMETER ComparisonCheckBox
        Legacy comparison CheckBox. Hidden by this initializer.

    .PARAMETER ComparisonListBox
        Legacy comparison ListBox. Hidden by this initializer.

    .PARAMETER SourceSelectorListBox
        Multi-select list containing the available Storage FC ports.

    .PARAMETER SeriesSelectorListBox
        Multi-select list containing the available SFP metrics.

    .PARAMETER GroupSelectorListBox
        List containing the available Storage systems.

    .PARAMETER GroupSelectorPanel
        Container of the Storage-System selector. It is collapsed when
        only one Storage system is available.

    .PARAMETER MetricComboBox
        Quick metric selector. Selecting an entry resets the Series
        selection to that single metric. Additional compatible metrics
        may afterwards be selected in the Series selector.

    .PARAMETER TimeRangeComboBox
        ComboBox containing the available time ranges.

    .PARAMETER StatusTextBlock
        TextBlock used for viewer status messages.

    .PARAMETER RefreshButton
        Optional refresh button.

    .OUTPUTS
        Boolean
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ViewRoot,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $PortComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ComparisonCheckBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ComparisonListBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SourceSelectorListBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SeriesSelectorListBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $GroupSelectorListBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $GroupSelectorPanel,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $MetricComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $TimeRangeComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $StatusTextBlock,

        [Parameter()]
        $RefreshButton
    )

    # ---------------------------------------------------------------------
    # Load available Storage FC ports
    # ---------------------------------------------------------------------

    $Ports = @(
        Get-StorageSFPHistoryPorts `
            -CustomerNbr $CustomerNbr
    )

    if ($Ports.Count -eq 0) {
        $StatusTextBlock.Text = ("Keine Storage-SFP-History-Daten für Kunde " + "$CustomerNbr gefunden.")

        return $false
    }

    # ---------------------------------------------------------------------
    # Build generic Source selector
    #
    # SourceKey   = RowID
    # DisplayName = readable Port name
    # SourceGroup = Storage SerialNumber
    # ---------------------------------------------------------------------
    $SourceSelectorModel = New-LiveChartsSourceSelectorModel -Sources $Ports -KeyProperty 'RowID' -DisplayNameProperty 'DisplayName' -GroupProperty 'SerialNumber'

    # ---------------------------------------------------------------------
    # Build Storage-System Group selector
    #
    # Get-LiveChartsSourceGroups already returns:
    #
    #   GroupKey
    #   DisplayName
    #   SourceCount
    #   IsSelected
    #
    # Get-LiveChartsFilteredSources expects an object containing Groups.
    # --------------------------------------------------------------------
    $SourceGroups = @(Get-LiveChartsSourceGroups -SelectorModel $SourceSelectorModel)

    $GroupSelectorModel = [PSCustomObject]@{Groups = $SourceGroups}

    # ---------------------------------------------------------------------
    # Load available metrics
    # ---------------------------------------------------------------------
    $Metrics = @(Get-StorageLiveChartsMetricInfo -All)

    if ($Metrics.Count -eq 0) {
        $StatusTextBlock.Text = 'Es wurden keine Storage-SFP-Metriken gefunden.'
        return $false
    }

    # ---------------------------------------------------------------------
    # Load available time ranges
    # ---------------------------------------------------------------------
    $TimeRanges = @(Get-LiveChartsTimeRanges)

    if ($TimeRanges.Count -eq 0) {
        $StatusTextBlock.Text = 'Es wurden keine LiveCharts-Zeiträume gefunden.'

        return $false
    }

    # ---------------------------------------------------------------------
    # Determine default time range
    # ---------------------------------------------------------------------
    $DefaultTimeRanges = @($TimeRanges | Where-Object {$_.Default -eq $true})

    if ($DefaultTimeRanges.Count -ne 1) {
        SST_ToolMessageCollector -TD_ToolMSGCollector "Exactly one default time range must be defined." -TD_ToolMSGType Debug -TD_Shown "no"
    }

    $DefaultTimeRange = $DefaultTimeRanges[0]

    # ---------------------------------------------------------------------
    # Build generic Series selector
    # ---------------------------------------------------------------------
    $SelectorModel = New-LiveChartsSeriesSelectorModel -MetricDefinitions $Metrics

    # ---------------------------------------------------------------------
    # Select SFP Temperature as initial metric
    # ---------------------------------------------------------------------
    $DefaultMetric =
        $Metrics |
            Where-Object {
                $_.Metric -eq 'SFPTemp'
            } |
            Select-Object -First 1

    if ($null -eq $DefaultMetric) {
        $DefaultMetric = $Metrics | Select-Object -First 1
    }

    foreach ($SeriesItem in $SelectorModel.Series) {
        $SeriesItem.IsSelected = ([string]$SeriesItem.Metric -eq [string]$DefaultMetric.Metric)
    }

    $null = Update-LiveChartsSeriesSelectorState -SelectorModel $SelectorModel

    # ---------------------------------------------------------------------
    # Fill controls
    # ---------------------------------------------------------------------
    $PortComboBox.ItemsSource = $Ports
    $MetricComboBox.ItemsSource = $Metrics
    $TimeRangeComboBox.ItemsSource = $TimeRanges
    $SourceSelectorListBox.ItemsSource =
        @(
            Get-LiveChartsFilteredSources -SourceSelectorModel $SourceSelectorModel -GroupSelectorModel $GroupSelectorModel
        )

    $SeriesSelectorListBox.ItemsSource = $SelectorModel.Series
    $GroupSelectorListBox.ItemsSource = $GroupSelectorModel.Groups

    # ---------------------------------------------------------------------
    # Hide old comparison controls
    #
    # SourceSelectorListBox now handles both single and multiple ports.
    # ---------------------------------------------------------------------
    $ComparisonCheckBox.IsChecked = $false
    $ComparisonCheckBox.IsEnabled = $false

    $ComparisonCheckBox.Visibility = [System.Windows.Visibility]::Collapsed
    $ComparisonListBox.Visibility = [System.Windows.Visibility]::Collapsed
    $PortComboBox.Visibility = [System.Windows.Visibility]::Collapsed

    # ---------------------------------------------------------------------
    # Show Storage-System selector only when multiple systems exist
    # ---------------------------------------------------------------------
    if ($GroupSelectorModel.Groups.Count -gt 1) {
        $GroupSelectorPanel.Visibility = [System.Windows.Visibility]::Visible
    } else {
        $GroupSelectorPanel.Visibility = [System.Windows.Visibility]::Collapsed
    }

    # ---------------------------------------------------------------------
    # Default control selections
    # ---------------------------------------------------------------------
    $PortComboBox.SelectedIndex = 0
    $MetricComboBox.SelectedItem = $DefaultMetric
    $TimeRangeComboBox.SelectedItem = $DefaultTimeRange

    # ---------------------------------------------------------------------
    # Windows PowerShell 5.1 compatibility layer
    #
    # Event handlers below are closures. Windows PowerShell 5.1 does not
    # always resolve module-scope functions reliably from these closures.
    # Capture only the required functions as ScriptBlocks here.
    #
    # PowerShell 7 also supports this approach. The compatibility block is
    # intentionally isolated so it can be removed easily in the future.
    # ---------------------------------------------------------------------
    $Fn_GetLiveChartsSelectedSources = ${function:Get-LiveChartsSelectedSources}
    $Fn_GetLiveChartsFilteredSources = ${function:Get-LiveChartsFilteredSources}
    $Fn_UpdateLiveChartsSeriesSelectorState = ${function:Update-LiveChartsSeriesSelectorState}
    $Fn_GetLiveChartsSelectedMetricDefinitions = ${function:Get-LiveChartsSelectedMetricDefinitions}
    $Fn_UpdateStorageSFPHistoryChart = ${function:Update-StorageSFPHistoryChart}

    $RequiredClosureFunctions = @(
        [PSCustomObject]@{
            Name        = 'Get-LiveChartsSelectedSources'
            ScriptBlock = $Fn_GetLiveChartsSelectedSources
        }
        [PSCustomObject]@{
            Name        = 'Get-LiveChartsFilteredSources'
            ScriptBlock = $Fn_GetLiveChartsFilteredSources
        }
        [PSCustomObject]@{
            Name        = 'Update-LiveChartsSeriesSelectorState'
            ScriptBlock = $Fn_UpdateLiveChartsSeriesSelectorState
        }
        [PSCustomObject]@{
            Name        = 'Get-LiveChartsSelectedMetricDefinitions'
            ScriptBlock = $Fn_GetLiveChartsSelectedMetricDefinitions
        }
        [PSCustomObject]@{
            Name        = 'Update-StorageSFPHistoryChart'
            ScriptBlock = $Fn_UpdateStorageSFPHistoryChart
        }
    )

    foreach ($RequiredClosureFunction in $RequiredClosureFunctions) {
        if ($null -eq $RequiredClosureFunction.ScriptBlock) {
            SST_ToolMessageCollector -TD_ToolMSGCollector ("Required function '{0}' is not available in module scope." -f $RequiredClosureFunction.Name) -TD_ToolMSGType Debug -TD_Shown "no"
        }
    }

    # ---------------------------------------------------------------------
    # Helper:
    # Return selected ports that belong to currently enabled groups.
    # ---------------------------------------------------------------------
    $GetSelectedPorts = {
        $SelectedGroupKeys = @(
            $GroupSelectorModel.Groups |
                Where-Object {
                    $_.IsSelected -eq $true
                } |
                ForEach-Object {
                    [string]$_.GroupKey
                }
        )
        if ($SelectedGroupKeys.Count -eq 0) {return @()}
        $SelectedPorts = @(
            & $Fn_GetLiveChartsSelectedSources -SelectorModel $SourceSelectorModel | Where-Object {
                [string]$_.SerialNumber -in $SelectedGroupKeys
            }
        )
        return $SelectedPorts
    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Helper:
    # Refresh visible Sources after Storage-System filter changes.
    # ---------------------------------------------------------------------
    $RefreshSourceSelector = {

        $FilteredSources = @(
            & $Fn_GetLiveChartsFilteredSources -SourceSelectorModel $SourceSelectorModel -GroupSelectorModel $GroupSelectorModel
        )
        $SourceSelectorListBox.ItemsSource = $FilteredSources
        $SourceSelectorListBox.Items.Refresh()

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Common chart update action
    #
    # SourceSelector and SeriesSelector are authoritative.
    # ---------------------------------------------------------------------
    $UpdateChart = {

        # -------------------------------------------------------------
        # Recalculate compatible metric UnitGroups
        # -------------------------------------------------------------
        $null = & $Fn_UpdateLiveChartsSeriesSelectorState -SelectorModel $SelectorModel
        $SeriesSelectorListBox.Items.Refresh()

        # -------------------------------------------------------------
        # Resolve selected metrics
        # -------------------------------------------------------------
        $SelectedMetricDefinitions = @(& $Fn_GetLiveChartsSelectedMetricDefinitions -SelectorModel $SelectorModel)

        if ($SelectedMetricDefinitions.Count -eq 0) {

            $StatusTextBlock.Text = 'Bitte mindestens eine Series auswählen.'
            return
        }

        $MetricNames = @($SelectedMetricDefinitions | ForEach-Object {[string]$_.Metric})

        # -------------------------------------------------------------
        # Resolve selected Sources
        # -------------------------------------------------------------
        $SelectedPorts = @(& $GetSelectedPorts)

        if ($SelectedPorts.Count -eq 0) {
            $StatusTextBlock.Text = 'Bitte mindestens einen Storage-Port auswählen.'
            return
        }

        # -------------------------------------------------------------
        # Keep maximum Source count consistent with backend
        # -------------------------------------------------------------
        if ($SelectedPorts.Count -gt 4) {
            $StatusTextBlock.Text = 'Es können maximal vier Storage-Ports gleichzeitig angezeigt werden.'
            return
        }

        $SelectedRowIDs = @($SelectedPorts | ForEach-Object {[string]$_.RowID})

        # -------------------------------------------------------------
        # Resolve selected time range
        # -------------------------------------------------------------
        $SelectedTimeRange = $TimeRangeComboBox.SelectedItem

        if ($null -eq $SelectedTimeRange) {return}

        $EndTime = Get-Date

        $StartTime = $EndTime.Subtract([TimeSpan]$SelectedTimeRange.Duration)

        # -------------------------------------------------------------
        # Build chart
        # -------------------------------------------------------------
        try {

            if ($null -ne $RefreshButton) {
                $RefreshButton.IsEnabled = $false
            }

            $StatusTextBlock.Text = 'SFP-History wird geladen …'

            $ChartData = & $Fn_UpdateStorageSFPHistoryChart -CustomerNbr $CustomerNbr -RowIDs $SelectedRowIDs -Metric $MetricNames -StartTime $StartTime -EndTime $EndTime -DateTimeLabelFormat ([string]$SelectedTimeRange.LabelFormat) `
                -DateTimeStep ([TimeSpan]$SelectedTimeRange.DateTimeStep)

            # ---------------------------------------------------------
            # Prepare formatted values for the shared XAML
            # ---------------------------------------------------------
            $Unit = [string]$ChartData.MetricInfo.Unit
            $Precision = [int]$ChartData.MetricInfo.Precision

            $NumberFormat = switch ($Precision) {

                0       { '0' }
                1       { '0.0' }
                2       { '0.00' }
                3       { '0.000' }
                default { '0.##' }
            }

            $FormatValue = {
                param (
                    $Value
                )

                if ($null -eq $Value -or $Value -is [DBNull]) {return '-'}

                $FormattedValue = ([double]$Value).ToString($NumberFormat,[System.Globalization.CultureInfo]::CurrentCulture)

                if ([string]::IsNullOrWhiteSpace($Unit)) {return $FormattedValue}

                return "$FormattedValue $Unit"

            }.GetNewClosure()

            $ChartData | Add-Member -MemberType NoteProperty -Name CurrentValueText -Value (& $FormatValue $ChartData.CurrentValue) -Force
            $ChartData | Add-Member -MemberType NoteProperty -Name MinimumValueText -Value (& $FormatValue $ChartData.MinimumValue) -Force
            $ChartData | Add-Member -MemberType NoteProperty -Name MaximumValueText -Value (& $FormatValue $ChartData.MaximumValue) -Force
            $ChartData | Add-Member -MemberType NoteProperty -Name AverageValueText -Value (& $FormatValue $ChartData.AverageValue) -Force
            $ChartData | Add-Member -MemberType NoteProperty -Name PointCountText -Value ([string]$ChartData.PointCount) -Force

            # ---------------------------------------------------------
            # Update viewer
            # ---------------------------------------------------------
            $ViewRoot.DataContext = $ChartData

            if ($SelectedPorts.Count -eq 1) {
                $SourceText = [string]$SelectedPorts[0].DisplayName
            }else {
                $SourceText = '{0} Ports' -f $SelectedPorts.Count
            }

            $StatusTextBlock.Text = ('{0} | {1} Series | {2} Messpunkte' -f $SourceText, $SelectedMetricDefinitions.Count, $ChartData.PointCount)
        }catch {

            $StatusTextBlock.Text = "Fehler: $($_.Exception.Message)"
            SST_ToolMessageCollector -TD_ToolMSGCollector ( "Storage SFP History Fehler: " +"$($_.Exception.Message)") -TD_ToolMSGType Error -TD_Shown "yes"
            Write-Host $_.InvocationInfo.PositionMessage
            Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
        }finally {

            if ($null -ne $RefreshButton) {$RefreshButton.IsEnabled = $true}
        }

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Quick metric preset
    #
    # Selecting an item in the Metric ComboBox resets the Series selection
    # to that one metric.
    #
    # Additional compatible metrics can afterwards be added manually.
    # ---------------------------------------------------------------------
    $ApplyMetricPreset = {

        $SelectedMetric = $MetricComboBox.SelectedItem
        if ($null -eq $SelectedMetric) {return}

        foreach ($SeriesItem in $SelectorModel.Series) {
            $SeriesItem.IsSelected = (
                [string]$SeriesItem.Metric -eq
                [string]$SelectedMetric.Metric
            )
        }

        $null = & $Fn_UpdateLiveChartsSeriesSelectorState -SelectorModel $SelectorModel
        $SeriesSelectorListBox.Items.Refresh()

        & $UpdateChart

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Series CheckBox handler
    #
    # PreviewMouseUp is used instead of AddHandler because PowerShell/WPF
    # had overload problems with routed ToggleButton events.
    # ---------------------------------------------------------------------
    $SeriesSelectorListBox.Add_PreviewMouseUp({

        $Current = $_.OriginalSource
        $CheckBox = $null

        while ($null -ne $Current) {

            if ($Current -is [System.Windows.Controls.CheckBox]) {
                $CheckBox = $Current
                break
            }

            try {
                $Current = [System.Windows.Media.VisualTreeHelper]::GetParent($Current)
            }
            catch {
                $Current = $null
            }
        }

        if ($null -eq $CheckBox) {return}

        # Wait until the TwoWay binding has updated IsSelected.
        $UpdateAction =
            [System.Action]{
                & $UpdateChart
            }

        $null =
            $ViewRoot.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                $UpdateAction
            )

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # Source CheckBox handler
    # ---------------------------------------------------------------------
    $SourceSelectorListBox.Add_PreviewMouseUp({

        $Current = $_.OriginalSource
        $CheckBox = $null

        while ($null -ne $Current) {

            if ($Current -is [System.Windows.Controls.CheckBox]) {
                $CheckBox = $Current
                break
            }
            try {
                $Current = [System.Windows.Media.VisualTreeHelper]::GetParent($Current)
            }catch {
                $Current = $null
            }
        }

        if ($null -eq $CheckBox) {return}

        $ClickedItem = $CheckBox.DataContext

        # Wait until the TwoWay binding has applied the new state.
        $UpdateAction =
            [System.Action]{

                $SelectedPorts = @(& $GetSelectedPorts)

                if ($SelectedPorts.Count -gt 4) {

                    if ($null -ne $ClickedItem -and $ClickedItem.PSObject.Properties['IsSelected']) {
                        $ClickedItem.IsSelected = $false
                    }

                    $SourceSelectorListBox.Items.Refresh()
                    $StatusTextBlock.Text = 'Es können maximal vier Storage-Ports gleichzeitig angezeigt werden.'
                    return
                }

                & $UpdateChart
            }

        $null = $ViewRoot.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background,$UpdateAction)

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # Storage-System Group CheckBox handler
    # ---------------------------------------------------------------------
    $GroupSelectorListBox.Add_PreviewMouseUp({

        $Current = $_.OriginalSource

        $CheckBox = $null

        while ($null -ne $Current) {

            if ( $Current -is [System.Windows.Controls.CheckBox]) {
                $CheckBox = $Current
                break
            }

            try {
                $Current = [System.Windows.Media.VisualTreeHelper]::GetParent($Current)
            }catch {
                $Current = $null
            }
        }

        if ($null -eq $CheckBox) {return}

        $UpdateAction =
            [System.Action]{

                # Refresh the list of visible ports.
                & $RefreshSourceSelector

                $VisibleSources = @(& $Fn_GetLiveChartsFilteredSources -SourceSelectorModel $SourceSelectorModel -GroupSelectorModel $GroupSelectorModel)

                # -----------------------------------------------------
                # If the active groups contain no selected Source,
                # automatically select the first visible one.
                # -----------------------------------------------------
                $SelectedPorts = @(& $GetSelectedPorts)

                if ($SelectedPorts.Count -eq 0 -and $VisibleSources.Count -gt 0) {

                    $FirstVisibleSource = $VisibleSources[0]

                    if ($FirstVisibleSource.PSObject.Properties['IsSelected']) {
                        $FirstVisibleSource.IsSelected = $true
                    }
                    $SourceSelectorListBox.Items.Refresh()
                }

                & $UpdateChart
            }

        $null = $ViewRoot.Dispatcher.BeginInvoke([System.Windows.Threading.DispatcherPriority]::Background,$UpdateAction)

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # Register normal events
    # ---------------------------------------------------------------------
    if ($null -ne $RefreshButton) {
        $RefreshButton.Add_Click($UpdateChart)
    }

    $MetricComboBox.Add_SelectionChanged($ApplyMetricPreset)
    $TimeRangeComboBox.Add_SelectionChanged($UpdateChart)

    # ---------------------------------------------------------------------
    # Initial chart
    # ---------------------------------------------------------------------

    & $UpdateChart

    return $true
}