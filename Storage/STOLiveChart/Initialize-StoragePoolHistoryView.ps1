function Initialize-StoragePoolHistoryView {
    <#
    .SYNOPSIS
        Initializes the Storage pool capacity history viewer.

    .DESCRIPTION
        Initializes the Storage pool history viewer using the generic
        LiveCharts selector architecture.

        Selection hierarchy:

            Storage System
                -> Storage Pool
                    -> Metric / Series

        Multiple pools and multiple compatible metrics can be displayed
        simultaneously.

        Metrics from different UnitGroups cannot be selected together.

        CapacityOverview is used as a quick preset. It selects the
        individual capacity metrics:

            Capacity
            FreeCapacity
            UsedCapacity
            VirtualCapacity
            RealCapacity

        CapacityOverview itself is not shown as an individual Series.

        The Storage-System selector is only visible when pools from more
        than one Storage system are available.

        The former single-pool / comparison controls remain available in
        the shared XAML for compatibility but are hidden for this viewer.

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER ViewRoot
        Root Window or UserControl of the viewer.

    .PARAMETER PoolComboBox
        Legacy single-pool ComboBox. Hidden by this initializer.

    .PARAMETER ComparisonCheckBox
        Legacy comparison CheckBox. Hidden by this initializer.

    .PARAMETER ComparisonListBox
        Legacy comparison ListBox. Hidden by this initializer.

    .PARAMETER SourceSelectorListBox
        Generic multi-select ListBox containing the available pools.

    .PARAMETER SeriesSelectorListBox
        Generic multi-select ListBox containing the available metrics.

    .PARAMETER GroupSelectorListBox
        Generic ListBox containing the available Storage systems.

    .PARAMETER GroupSelectorPanel
        Container of the Storage-System selector.

        The complete panel is collapsed when only one Storage system
        exists.

    .PARAMETER MetricComboBox
        Quick preset / metric selector.

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
        $PoolComboBox,

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
    # Load available pools
    # ---------------------------------------------------------------------

    $Pools = @(
        Get-StoragePoolHistoryPools `
            -CustomerNbr $CustomerNbr
    )

    if ($Pools.Count -eq 0) {

        $StatusTextBlock.Text = (
            "Keine Storage-Pool-History-Daten für Kunde " +
            "$CustomerNbr gefunden."
        )

        return $false
    }

    # ---------------------------------------------------------------------
    # Build generic Source selector
    #
    # Source:
    #   Storage Pool
    #
    # Group:
    #   Storage SerialNumber
    # ---------------------------------------------------------------------

    $SourceSelectorModel =
        New-LiveChartsSourceSelectorModel `
            -Sources $Pools `
            -KeyProperty 'RowID' `
            -DisplayNameProperty 'DisplayName' `
            -GroupProperty 'SerialNumber'

    # ---------------------------------------------------------------------
    # Build Storage-System selector
    # ---------------------------------------------------------------------

    $SourceGroups = @(
        Get-LiveChartsSourceGroups `
            -SelectorModel $SourceSelectorModel
    )

    $GroupSelectorModel =
        [PSCustomObject]@{
            Groups = $SourceGroups
        }

    # ---------------------------------------------------------------------
    # Load metrics
    #
    # $Metrics contains both:
    #
    #   CapacityOverview        -> preset
    #   individual metrics      -> selectable Series
    # ---------------------------------------------------------------------

    $Metrics = @(
        Get-StoragePoolLiveChartsMetricInfo -All
    )

    if ($Metrics.Count -eq 0) {

        $StatusTextBlock.Text =
            'Es wurden keine Storage-Pool-Metriken gefunden.'

        return $false
    }

    # ---------------------------------------------------------------------
    # Only real individual metrics become selectable Series.
    #
    # CapacityOverview is a MultiMetric preset and must not appear as
    # another individual line in the Series selector.
    # ---------------------------------------------------------------------

    $SelectableMetrics = @(
        $Metrics |
            Where-Object {
                [string]$_.ValueMode -ne 'MultiMetric'
            }
    )

    if ($SelectableMetrics.Count -eq 0) {

        $StatusTextBlock.Text =
            'Es wurden keine auswählbaren Storage-Pool-Series gefunden.'

        return $false
    }

    # ---------------------------------------------------------------------
    # Load time ranges
    # ---------------------------------------------------------------------

    $TimeRanges = @(
        Get-LiveChartsTimeRanges
    )

    if ($TimeRanges.Count -eq 0) {

        $StatusTextBlock.Text =
            'Es wurden keine LiveCharts-Zeiträume gefunden.'

        return $false
    }

    # ---------------------------------------------------------------------
    # Determine default time range
    # ---------------------------------------------------------------------

    $DefaultTimeRanges = @(
        $TimeRanges |
            Where-Object {
                $_.Default -eq $true
            }
    )

    if ($DefaultTimeRanges.Count -ne 1) {
        throw 'Exactly one default time range must be defined.'
    }

    $DefaultTimeRange =
        $DefaultTimeRanges[0]

    # ---------------------------------------------------------------------
    # Build generic Series selector
    # ---------------------------------------------------------------------

    $SelectorModel =
        New-LiveChartsSeriesSelectorModel `
            -MetricDefinitions $SelectableMetrics

    # ---------------------------------------------------------------------
    # Determine default preset
    #
    # Start with CapacityOverview when available.
    # Fallback: UsedCapacity.
    # Fallback 2: first available metric.
    # ---------------------------------------------------------------------

    $DefaultPreset =
        $Metrics |
            Where-Object {
                $_.Metric -eq 'CapacityOverview'
            } |
            Select-Object -First 1

    if ($null -eq $DefaultPreset) {

        $DefaultPreset =
            $Metrics |
                Where-Object {
                    $_.Metric -eq 'UsedCapacity'
                } |
                Select-Object -First 1
    }

    if ($null -eq $DefaultPreset) {

        $DefaultPreset =
            $Metrics |
                Select-Object -First 1
    }

    # ---------------------------------------------------------------------
    # Apply initial preset to Series selector
    # ---------------------------------------------------------------------

    if (
        [string]$DefaultPreset.ValueMode -eq 'MultiMetric' -and
        $DefaultPreset.PSObject.Properties['Metrics']
    ) {

        $PresetMetricNames = @(
            $DefaultPreset.Metrics |
                ForEach-Object {
                    [string]$_.Metric
                }
        )
    }
    else {

        $PresetMetricNames = @(
            [string]$DefaultPreset.Metric
        )
    }

    foreach ($SeriesItem in $SelectorModel.Series) {

        $SeriesItem.IsSelected = (
            [string]$SeriesItem.Metric -in
            $PresetMetricNames
        )
    }

    $null =
        Update-LiveChartsSeriesSelectorState `
            -SelectorModel $SelectorModel

    # ---------------------------------------------------------------------
    # Fill controls
    # ---------------------------------------------------------------------

    # Legacy controls are still filled so they remain in a valid state.
    $PoolComboBox.ItemsSource =
        $Pools

    $ComparisonListBox.ItemsSource =
        $Pools

    # Metric ComboBox works as Quick-Preset selector.
    $MetricComboBox.ItemsSource =
        $Metrics

    $TimeRangeComboBox.ItemsSource =
        $TimeRanges

    # Generic selectors.
    $SourceSelectorListBox.ItemsSource =
        @(
            Get-LiveChartsFilteredSources `
                -SourceSelectorModel $SourceSelectorModel `
                -GroupSelectorModel $GroupSelectorModel
        )

    $SeriesSelectorListBox.ItemsSource =
        $SelectorModel.Series

    $GroupSelectorListBox.ItemsSource =
        $GroupSelectorModel.Groups

    # ---------------------------------------------------------------------
    # Disable and hide old Comparison controls
    #
    # SourceSelector now handles one or multiple pools directly.
    # ---------------------------------------------------------------------

    $ComparisonCheckBox.IsChecked =
        $false

    $ComparisonCheckBox.IsEnabled =
        $false

    $ComparisonCheckBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    $ComparisonListBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    $PoolComboBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    # ---------------------------------------------------------------------
    # Show Storage Systems only when more than one exists
    # ---------------------------------------------------------------------

    if ($GroupSelectorModel.Groups.Count -gt 1) {

        $GroupSelectorPanel.Visibility =
            [System.Windows.Visibility]::Visible
    }
    else {

        $GroupSelectorPanel.Visibility =
            [System.Windows.Visibility]::Collapsed
    }

    # ---------------------------------------------------------------------
    # Default selections
    # ---------------------------------------------------------------------

    $PoolComboBox.SelectedIndex =
        0

    $MetricComboBox.SelectedItem =
        $DefaultPreset

    $TimeRangeComboBox.SelectedItem =
        $DefaultTimeRange


    # ---------------------------------------------------------------------
    # Capture module functions used inside closures.
    #
    # Windows PowerShell 5.1 may not resolve functions from the original
    # module scope when ScriptBlocks are created with GetNewClosure().
    #
    # Therefore every external function used from a closure is captured
    # explicitly and invoked with the call operator (&).
    # ---------------------------------------------------------------------

    $Fn_GetLiveChartsSelectedSources =
        ${function:Get-LiveChartsSelectedSources}

    $Fn_GetLiveChartsFilteredSources =
        ${function:Get-LiveChartsFilteredSources}

    $Fn_UpdateLiveChartsSeriesSelectorState =
        ${function:Update-LiveChartsSeriesSelectorState}

    $Fn_GetLiveChartsSelectedMetricDefinitions =
        ${function:Get-LiveChartsSelectedMetricDefinitions}

    $Fn_UpdateStoragePoolCapacityChart =
        ${function:Update-StoragePoolCapacityChart}

    # Fail early if one of the required functions is not available.
    $RequiredClosureFunctions = [ordered]@{
        'Get-LiveChartsSelectedSources' =
            $Fn_GetLiveChartsSelectedSources

        'Get-LiveChartsFilteredSources' =
            $Fn_GetLiveChartsFilteredSources

        'Update-LiveChartsSeriesSelectorState' =
            $Fn_UpdateLiveChartsSeriesSelectorState

        'Get-LiveChartsSelectedMetricDefinitions' =
            $Fn_GetLiveChartsSelectedMetricDefinitions

        'Update-StoragePoolCapacityChart' =
            $Fn_UpdateStoragePoolCapacityChart
    }

    foreach ($RequiredFunction in $RequiredClosureFunctions.GetEnumerator()) {

        if ($null -eq $RequiredFunction.Value) {
            throw (
                "Required LiveCharts function '$($RequiredFunction.Key)' " +
                'could not be captured for the Pool viewer closure.'
            )
        }
    }

    # ---------------------------------------------------------------------
    # Helper:
    # Return selected pools that belong to enabled Storage-System groups.
    # ---------------------------------------------------------------------

    $GetSelectedPools = {

        $SelectedGroupKeys = @(
            $GroupSelectorModel.Groups |
                Where-Object {
                    $_.IsSelected -eq $true
                } |
                ForEach-Object {
                    [string]$_.GroupKey
                }
        )

        if ($SelectedGroupKeys.Count -eq 0) {
            return @()
        }

        $SelectedPools = @(
            & $Fn_GetLiveChartsSelectedSources `
                -SelectorModel $SourceSelectorModel |
                Where-Object {
                    [string]$_.SerialNumber -in
                    $SelectedGroupKeys
                }
        )

        return $SelectedPools

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Helper:
    # Refresh visible pools after Storage-System selection changes.
    # ---------------------------------------------------------------------

    $RefreshSourceSelector = {

        $FilteredSources = @(
            & $Fn_GetLiveChartsFilteredSources `
                -SourceSelectorModel $SourceSelectorModel `
                -GroupSelectorModel $GroupSelectorModel
        )

        $SourceSelectorListBox.ItemsSource =
            $FilteredSources

        $SourceSelectorListBox.Items.Refresh()

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Common chart update
    # ---------------------------------------------------------------------

    $UpdateChart = {

        # -------------------------------------------------------------
        # Recalculate UnitGroup compatibility
        # -------------------------------------------------------------

        $null =
            & $Fn_UpdateLiveChartsSeriesSelectorState `
                -SelectorModel $SelectorModel

        $SeriesSelectorListBox.Items.Refresh()

        # -------------------------------------------------------------
        # Resolve selected metrics
        # -------------------------------------------------------------

        $SelectedMetricDefinitions = @(
            & $Fn_GetLiveChartsSelectedMetricDefinitions `
                -SelectorModel $SelectorModel
        )

        if ($SelectedMetricDefinitions.Count -eq 0) {

            $StatusTextBlock.Text =
                'Bitte mindestens eine Series auswählen.'

            return
        }

        $MetricNames = @(
            $SelectedMetricDefinitions |
                ForEach-Object {
                    [string]$_.Metric
                }
        )

        # -------------------------------------------------------------
        # Resolve selected pools
        # -------------------------------------------------------------

        $SelectedPools = @(
            & $GetSelectedPools
        )

        if ($SelectedPools.Count -eq 0) {

            $StatusTextBlock.Text =
                'Bitte mindestens einen Storage-Pool auswählen.'

            return
        }

        # Backend currently allows a maximum of four Sources.
        if ($SelectedPools.Count -gt 4) {

            $StatusTextBlock.Text =
                'Es können maximal vier Storage-Pools gleichzeitig angezeigt werden.'

            return
        }

        $SelectedRowIDs = @(
            $SelectedPools |
                ForEach-Object {
                    [string]$_.RowID
                }
        )

        # -------------------------------------------------------------
        # Resolve time range
        # -------------------------------------------------------------

        $SelectedTimeRange =
            $TimeRangeComboBox.SelectedItem

        if ($null -eq $SelectedTimeRange) {
            return
        }

        $EndTime =
            Get-Date

        $StartTime =
            $EndTime.Subtract(
                [TimeSpan]$SelectedTimeRange.Duration
            )

        # -------------------------------------------------------------
        # Build chart
        # -------------------------------------------------------------

        try {

            if ($null -ne $RefreshButton) {

                $RefreshButton.IsEnabled =
                    $false
            }

            $StatusTextBlock.Text =
                'Pool-History wird geladen …'

            # ---------------------------------------------------------
            # Single Source uses -RowID.
            #
            # Multi Source uses -RowIDs because the Pool backend still
            # has separate parameter sets for these two cases.
            # ---------------------------------------------------------

            if ($SelectedRowIDs.Count -eq 1) {

                $ChartData =
                    & $Fn_UpdateStoragePoolCapacityChart `
                        -CustomerNbr $CustomerNbr `
                        -RowID $SelectedRowIDs[0] `
                        -Metric $MetricNames `
                        -StartTime $StartTime `
                        -EndTime $EndTime `
                        -DateTimeLabelFormat (
                            [string]$SelectedTimeRange.LabelFormat
                        ) `
                        -DateTimeStep (
                            [TimeSpan]$SelectedTimeRange.DateTimeStep
                        )
            }
            else {

                $ChartData =
                    & $Fn_UpdateStoragePoolCapacityChart `
                        -CustomerNbr $CustomerNbr `
                        -RowIDs $SelectedRowIDs `
                        -Metric $MetricNames `
                        -StartTime $StartTime `
                        -EndTime $EndTime `
                        -DateTimeLabelFormat (
                            [string]$SelectedTimeRange.LabelFormat
                        ) `
                        -DateTimeStep (
                            [TimeSpan]$SelectedTimeRange.DateTimeStep
                        )
            }

            # ---------------------------------------------------------
            # Prepare formatted statistics for shared XAML
            # ---------------------------------------------------------

            $Unit =
                [string]$ChartData.MetricInfo.Unit

            $Precision =
                [int]$ChartData.MetricInfo.Precision

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

                if (
                    $null -eq $Value -or
                    $Value -is [DBNull]
                ) {
                    return '-'
                }

                $FormattedValue =
                    ([double]$Value).ToString(
                        $NumberFormat,
                        [System.Globalization.CultureInfo]::CurrentCulture
                    )

                if (
                    [string]::IsNullOrWhiteSpace(
                        $Unit
                    )
                ) {
                    return $FormattedValue
                }

                return "$FormattedValue $Unit"

            }.GetNewClosure()

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name CurrentValueText `
                    -Value (
                        & $FormatValue $ChartData.CurrentValue
                    ) `
                    -Force

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name MinimumValueText `
                    -Value (
                        & $FormatValue $ChartData.MinimumValue
                    ) `
                    -Force

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name MaximumValueText `
                    -Value (
                        & $FormatValue $ChartData.MaximumValue
                    ) `
                    -Force

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name AverageValueText `
                    -Value (
                        & $FormatValue $ChartData.AverageValue
                    ) `
                    -Force

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name PointCountText `
                    -Value (
                        [string]$ChartData.PointCount
                    ) `
                    -Force

            # ---------------------------------------------------------
            # Update viewer DataContext
            # ---------------------------------------------------------

            $ViewRoot.DataContext =
                $ChartData

            # ---------------------------------------------------------
            # Build readable status text
            # ---------------------------------------------------------

            if ($SelectedPools.Count -eq 1) {

                $SourceText =
                    [string]$SelectedPools[0].DisplayName
            }
            else {

                $SourceText =
                    '{0} Pools' -f
                    $SelectedPools.Count
            }

            $StatusTextBlock.Text = (
                '{0} | {1} Series | {2} Messpunkte' -f
                $SourceText,
                $SelectedMetricDefinitions.Count,
                $ChartData.PointCount
            )
        }
        catch {

            $StatusTextBlock.Text =
                "Fehler: $($_.Exception.Message)"

            Write-Host (
                'Storage Pool History Fehler: ' +
                $_.Exception.Message
            ) -ForegroundColor Red

            Write-Host `
                $_.InvocationInfo.PositionMessage

            Write-Host `
                $_.ScriptStackTrace `
                -ForegroundColor DarkGray
        }
        finally {

            if ($null -ne $RefreshButton) {

                $RefreshButton.IsEnabled =
                    $true
            }
        }

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Apply Quick-Preset from Metric ComboBox
    # ---------------------------------------------------------------------

    $ApplyMetricPreset = {

        $SelectedPreset =
            $MetricComboBox.SelectedItem

        if ($null -eq $SelectedPreset) {
            return
        }

        # -------------------------------------------------------------
        # MultiMetric preset:
        #
        # CapacityOverview -> select its five individual Series.
        # -------------------------------------------------------------

        if (
            [string]$SelectedPreset.ValueMode -eq 'MultiMetric' -and
            $SelectedPreset.PSObject.Properties['Metrics']
        ) {

            $PresetMetricNames = @(
                $SelectedPreset.Metrics |
                    ForEach-Object {
                        [string]$_.Metric
                    }
            )
        }

        # -------------------------------------------------------------
        # Normal metric:
        #
        # Select only that one Series.
        # -------------------------------------------------------------

        else {

            $PresetMetricNames = @(
                [string]$SelectedPreset.Metric
            )
        }

        foreach ($SeriesItem in $SelectorModel.Series) {

            $SeriesItem.IsSelected = (
                [string]$SeriesItem.Metric -in
                $PresetMetricNames
            )
        }

        $null =
            & $Fn_UpdateLiveChartsSeriesSelectorState `
                -SelectorModel $SelectorModel

        $SeriesSelectorListBox.Items.Refresh()

        & $UpdateChart

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Series CheckBox handler
    # ---------------------------------------------------------------------

    $SeriesSelectorListBox.Add_PreviewMouseUp({

        $Current =
            $_.OriginalSource

        $CheckBox =
            $null

        while ($null -ne $Current) {

            if (
                $Current -is
                [System.Windows.Controls.CheckBox]
            ) {

                $CheckBox =
                    $Current

                break
            }

            try {

                $Current =
                    [System.Windows.Media.VisualTreeHelper]::GetParent(
                        $Current
                    )
            }
            catch {

                $Current =
                    $null
            }
        }

        if ($null -eq $CheckBox) {
            return
        }

        # Binding is updated after the mouse event.
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
    # Source / Pool CheckBox handler
    # ---------------------------------------------------------------------

    $SourceSelectorListBox.Add_PreviewMouseUp({

        $Current =
            $_.OriginalSource

        $CheckBox =
            $null

        while ($null -ne $Current) {

            if (
                $Current -is
                [System.Windows.Controls.CheckBox]
            ) {

                $CheckBox =
                    $Current

                break
            }

            try {

                $Current =
                    [System.Windows.Media.VisualTreeHelper]::GetParent(
                        $Current
                    )
            }
            catch {

                $Current =
                    $null
            }
        }

        if ($null -eq $CheckBox) {
            return
        }

        $ClickedItem =
            $CheckBox.DataContext

        $UpdateAction =
            [System.Action]{

                $SelectedPools = @(
                    & $GetSelectedPools
                )

                if ($SelectedPools.Count -gt 4) {

                    if (
                        $null -ne $ClickedItem -and
                        $ClickedItem.PSObject.Properties[
                            'IsSelected'
                        ]
                    ) {

                        $ClickedItem.IsSelected =
                            $false
                    }

                    $SourceSelectorListBox.Items.Refresh()

                    $StatusTextBlock.Text =
                        'Es können maximal vier Storage-Pools gleichzeitig angezeigt werden.'

                    return
                }

                & $UpdateChart
            }

        $null =
            $ViewRoot.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                $UpdateAction
            )

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # Storage-System Group handler
    # ---------------------------------------------------------------------

    $GroupSelectorListBox.Add_PreviewMouseUp({

        $Current =
            $_.OriginalSource

        $CheckBox =
            $null

        while ($null -ne $Current) {

            if (
                $Current -is
                [System.Windows.Controls.CheckBox]
            ) {

                $CheckBox =
                    $Current

                break
            }

            try {

                $Current =
                    [System.Windows.Media.VisualTreeHelper]::GetParent(
                        $Current
                    )
            }
            catch {

                $Current =
                    $null
            }
        }

        if ($null -eq $CheckBox) {
            return
        }

        $UpdateAction =
            [System.Action]{

                # Refresh visible pools.
                & $RefreshSourceSelector

                $VisibleSources = @(
                    & $Fn_GetLiveChartsFilteredSources `
                        -SourceSelectorModel $SourceSelectorModel `
                        -GroupSelectorModel $GroupSelectorModel
                )

                # If the selected Storage systems contain no selected pool,
                # automatically choose the first visible one.
                $SelectedPools = @(
                    & $GetSelectedPools
                )

                if (
                    $SelectedPools.Count -eq 0 -and
                    $VisibleSources.Count -gt 0
                ) {

                    $FirstVisibleSource =
                        $VisibleSources[0]

                    if (
                        $FirstVisibleSource.PSObject.Properties[
                            'IsSelected'
                        ]
                    ) {

                        $FirstVisibleSource.IsSelected =
                            $true
                    }

                    $SourceSelectorListBox.Items.Refresh()
                }

                & $UpdateChart
            }

        $null =
            $ViewRoot.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                $UpdateAction
            )

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # Register normal events
    # ---------------------------------------------------------------------

    if ($null -ne $RefreshButton) {

        $RefreshButton.Add_Click(
            $UpdateChart
        )
    }

    $MetricComboBox.Add_SelectionChanged(
        $ApplyMetricPreset
    )

    $TimeRangeComboBox.Add_SelectionChanged(
        $UpdateChart
    )

    # ---------------------------------------------------------------------
    # Initial chart
    # ---------------------------------------------------------------------

    & $UpdateChart

    return $true
}