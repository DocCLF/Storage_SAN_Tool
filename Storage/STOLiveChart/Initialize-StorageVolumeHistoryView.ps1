function Initialize-StorageVolumeHistoryView {
    <#
    .SYNOPSIS
        Initializes the Storage volume analysis history viewer.

    .DESCRIPTION
        Initializes the complete Volume history viewer.

        Selection hierarchy:

            Source Groups
                Storage systems

            Sources
                Volumes

            Series
                Volume analysis metrics

        Source Groups act only as filters.

        Sources determine which Volumes are displayed in the chart.

        Series determine which metrics are displayed.

        Supported chart combinations:

            1 Source  x 1 Metric
            1 Source  x n Metrics
            n Sources x 1 Metric
            n Sources x n Metrics

        The preset defines only the initial Series selection.
        Afterwards the user may freely modify the Series selection.

    .PARAMETER CustomerNbr
        Six-digit customer number.
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
        $VolumeComboBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ComparisonCheckBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $ComparisonListBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SourceGroupPanel,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SourceGroupSelectorListBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SourceSelectorListBox,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $SeriesSelectorListBox,

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
    # Load available Volumes
    # ---------------------------------------------------------------------

    $Volumes = @(
        Get-StorageVolumeHistoryVolumes `
            -CustomerNbr $CustomerNbr
    )

    if ($Volumes.Count -eq 0) {

        $StatusTextBlock.Text = (
            "Keine Storage-Volume-History-Daten für Kunde " +
            "$CustomerNbr gefunden."
        )

        return $false
    }

    # ---------------------------------------------------------------------
    # Build generic Source selector
    #
    # RowID:
    #   Unique Volume identifier.
    #
    # DisplayName:
    #   Visible Source name.
    #
    # SerialNumber:
    #   SourceGroup / Storage system.
    # ---------------------------------------------------------------------

    $SourceSelectorModel =
        New-LiveChartsSourceSelectorModel `
            -Sources $Volumes `
            -KeyProperty 'RowID' `
            -DisplayNameProperty 'DisplayName' `
            -GroupProperty 'SerialNumber'

    # ---------------------------------------------------------------------
    # Build generic SourceGroup selector
    # ---------------------------------------------------------------------

    $GroupSelectorModel =
        New-LiveChartsSourceGroupSelectorModel `
            -SourceSelectorModel $SourceSelectorModel

    # ---------------------------------------------------------------------
    # Load metrics
    # ---------------------------------------------------------------------

    $Metrics = @(
        Get-StorageVolumeLiveChartsMetricInfo -All
    )

    if ($Metrics.Count -eq 0) {

        $StatusTextBlock.Text =
            'Es wurden keine Storage-Volume-Metriken gefunden.'

        return $false
    }

    # ---------------------------------------------------------------------
    # Load presets
    # ---------------------------------------------------------------------

    $Presets = @(
        Get-StorageVolumeLiveChartsPresets
    )

    if ($Presets.Count -eq 0) {

        $StatusTextBlock.Text =
            'Es wurden keine Storage-Volume-Presets gefunden.'

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
    # Determine default preset
    # ---------------------------------------------------------------------

    $DefaultPresets = @(
        $Presets |
            Where-Object {
                $_.IsDefault -eq $true
            }
    )

    if ($DefaultPresets.Count -ne 1) {
        throw 'Exactly one default volume preset must be defined.'
    }

    $DefaultPreset =
        $DefaultPresets[0]

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
            -MetricDefinitions $Metrics `
            -Preset $DefaultPreset

    # ---------------------------------------------------------------------
    # Fill controls
    # ---------------------------------------------------------------------

    # Legacy controls are still populated for compatibility.
    $VolumeComboBox.ItemsSource =
        $Volumes

    $MetricComboBox.ItemsSource =
        $Presets

    $TimeRangeComboBox.ItemsSource =
        $TimeRanges

    $SourceGroupSelectorListBox.ItemsSource =
        $GroupSelectorModel.Groups

    $SeriesSelectorListBox.ItemsSource =
        $SelectorModel.Series

    # ---------------------------------------------------------------------
    # Hide obsolete source / comparison controls
    # ---------------------------------------------------------------------

    $ComparisonCheckBox.IsChecked =
        $false

    $ComparisonCheckBox.IsEnabled =
        $false

    $ComparisonCheckBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    $ComparisonListBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    $VolumeComboBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    # ---------------------------------------------------------------------
    # Show Storage-System selector only when more than one group exists
    # ---------------------------------------------------------------------

    if ($GroupSelectorModel.GroupCount -gt 1) {

        $SourceGroupPanel.Visibility =
            [System.Windows.Visibility]::Visible
    }
    else {

        $SourceGroupPanel.Visibility =
            [System.Windows.Visibility]::Collapsed
    }

    # ---------------------------------------------------------------------
    # Default selections
    # ---------------------------------------------------------------------

    $VolumeComboBox.SelectedIndex =
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

    $Fn_GetLiveChartsFilteredSources =
        ${function:Get-LiveChartsFilteredSources}

    $Fn_UpdateLiveChartsSeriesSelectorState =
        ${function:Update-LiveChartsSeriesSelectorState}

    $Fn_GetLiveChartsSelectedMetricDefinitions =
        ${function:Get-LiveChartsSelectedMetricDefinitions}

    $Fn_UpdateStorageVolumeAnalysisChart =
        ${function:Update-StorageVolumeAnalysisChart}

    # Fail early if one of the required functions is not available.
    $RequiredClosureFunctions = [ordered]@{
        'Get-LiveChartsFilteredSources' =
            $Fn_GetLiveChartsFilteredSources

        'Update-LiveChartsSeriesSelectorState' =
            $Fn_UpdateLiveChartsSeriesSelectorState

        'Get-LiveChartsSelectedMetricDefinitions' =
            $Fn_GetLiveChartsSelectedMetricDefinitions

        'Update-StorageVolumeAnalysisChart' =
            $Fn_UpdateStorageVolumeAnalysisChart
    }

    foreach ($RequiredFunction in $RequiredClosureFunctions.GetEnumerator()) {

        if ($null -eq $RequiredFunction.Value) {
            throw (
                "Required LiveCharts function '$($RequiredFunction.Key)' " +
                'could not be captured for the Volume viewer closure.'
            )
        }
    }

    # ---------------------------------------------------------------------
    # Update visible Sources according to SourceGroup filter
    # ---------------------------------------------------------------------

    $UpdateSourceFilter = {

        $FilteredSourceItems = @(
            & $Fn_GetLiveChartsFilteredSources `
                -SourceSelectorModel $SourceSelectorModel `
                -GroupSelectorModel $GroupSelectorModel
        )

        # -------------------------------------------------------------
        # If no visible Source is currently selected,
        # automatically select the first visible Source.
        # -------------------------------------------------------------

        $VisibleSelectedSources = @(
            $FilteredSourceItems |
                Where-Object {
                    $_.IsSelected -eq $true
                }
        )

        if (
            $FilteredSourceItems.Count -gt 0 -and
            $VisibleSelectedSources.Count -eq 0
        ) {
            $FilteredSourceItems[0].IsSelected =
                $true
        }

        # -------------------------------------------------------------
        # Important:
        #
        # We bind the existing SourceSelector items.
        # We do not create copies.
        #
        # Therefore IsSelected survives filtering.
        # -------------------------------------------------------------

        $SourceSelectorListBox.ItemsSource =
            $FilteredSourceItems

        $SourceSelectorListBox.Items.Refresh()

    }.GetNewClosure()

    # Apply initial Storage-System filter.
    & $UpdateSourceFilter

    # ---------------------------------------------------------------------
    # Common chart update action
    # ---------------------------------------------------------------------

    $UpdateChart = {

        # -------------------------------------------------------------
        # Recalculate compatible Series UnitGroups
        # -------------------------------------------------------------

        $null =
            & $Fn_UpdateLiveChartsSeriesSelectorState `
                -SelectorModel $SelectorModel

        $SeriesSelectorListBox.Items.Refresh()

        # -------------------------------------------------------------
        # Get currently visible Sources
        #
        # Filtered-out Storage systems must not contribute Sources
        # to the chart even if one of their Sources remains IsSelected.
        # -------------------------------------------------------------

        $FilteredSourceItems = @(
            & $Fn_GetLiveChartsFilteredSources `
                -SourceSelectorModel $SourceSelectorModel `
                -GroupSelectorModel $GroupSelectorModel
        )

        # -------------------------------------------------------------
        # Resolve selected visible Sources
        # -------------------------------------------------------------

        $SelectedSources = @(
            $FilteredSourceItems |
                Where-Object {
                    $_.IsSelected -eq $true
                } |
                ForEach-Object {
                    $_.Source
                }
        )

        if ($SelectedSources.Count -eq 0) {

            $StatusTextBlock.Text =
                'Bitte mindestens eine sichtbare Source auswählen.'

            return
        }

        # -------------------------------------------------------------
        # Convert selected Sources into RowIDs
        # -------------------------------------------------------------

        $RequestedRowIDs = @(
            $SelectedSources |
                ForEach-Object {
                    [string]$_.RowID
                }
        )

        # -------------------------------------------------------------
        # Resolve selected Metrics
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
                'History wird geladen …'

            $ChartData =
                & $Fn_UpdateStorageVolumeAnalysisChart `
                    -CustomerNbr $CustomerNbr `
                    -RowIDs $RequestedRowIDs `
                    -Metric $MetricNames `
                    -StartTime $StartTime `
                    -EndTime $EndTime `
                    -DateTimeLabelFormat (
                        [string]$SelectedTimeRange.LabelFormat
                    ) `
                    -DateTimeStep (
                        [TimeSpan]$SelectedTimeRange.DateTimeStep
                    )

            # ---------------------------------------------------------
            # Format statistics
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

                param(
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

            # ---------------------------------------------------------
            # Add formatted statistics
            # ---------------------------------------------------------

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
            # Store UI state in chart model
            # ---------------------------------------------------------

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name SelectedSources `
                    -Value $SelectedSources `
                    -Force

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name SelectedTimeRange `
                    -Value $SelectedTimeRange `
                    -Force

            $ChartData |
                Add-Member `
                    -MemberType NoteProperty `
                    -Name SelectedSeries `
                    -Value $SelectedMetricDefinitions `
                    -Force

            # ---------------------------------------------------------
            # Apply chart model
            # ---------------------------------------------------------

            $ViewRoot.DataContext =
                $ChartData

            # ---------------------------------------------------------
            # Status information
            # ---------------------------------------------------------

            if ($SelectedSources.Count -eq 1) {

                $StatusTextBlock.Text = (
                    '{0} | {1} Series | {2} Messpunkte' -f
                    $SelectedSources[0].DisplayName,
                    @($ChartData.Series).Count,
                    $ChartData.PointCount
                )
            }
            else {

                $StatusTextBlock.Text = (
                    '{0} Sources | {1} Series | {2} Messpunkte' -f
                    $SelectedSources.Count,
                    @($ChartData.Series).Count,
                    $ChartData.PointCount
                )
            }
        }
        catch {

            $StatusTextBlock.Text =
                "Fehler: $($_.Exception.Message)"

            Write-Host (
                "Storage Volume History Fehler: " +
                "$($_.Exception.Message)"
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
    # Apply preset
    #
    # A preset resets the Series CheckBoxes to its predefined selection.
    # Afterwards the user can modify the selection again.
    # ---------------------------------------------------------------------

    $ApplyPreset = {

        $SelectedPreset =
            $MetricComboBox.SelectedItem

        if ($null -eq $SelectedPreset) {
            return
        }

        $PresetMetrics = @(
            $SelectedPreset.Metrics |
                ForEach-Object {
                    [string]$_
                }
        )

        foreach ($SeriesItem in $SelectorModel.Series) {

            $SeriesItem.IsSelected = (
                [string]$SeriesItem.Metric -in
                $PresetMetrics
            )
        }

        $null =
            & $Fn_UpdateLiveChartsSeriesSelectorState `
                -SelectorModel $SelectorModel

        $SeriesSelectorListBox.Items.Refresh()

        & $UpdateChart

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Queue chart update
    #
    # PreviewMouseUp fires before WPF has written the new CheckBox state
    # into the TwoWay-bound IsSelected property.
    #
    # Dispatcher.Background performs the chart update after the binding.
    # ---------------------------------------------------------------------

    $QueueChartUpdate = {

        $UpdateAction =
            [System.Action]{
                & $UpdateChart
            }

        $null =
            $ViewRoot.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                $UpdateAction
            )

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Series selector
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

        & $QueueChartUpdate

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # Source selector
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

        & $QueueChartUpdate

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # SourceGroup / Storage-System selector
    # ---------------------------------------------------------------------

    $SourceGroupSelectorListBox.Add_PreviewMouseUp({

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

        # -------------------------------------------------------------
        # Wait until IsSelected of the Storage-System CheckBox has
        # been updated.
        #
        # Then:
        #
        #   1. update visible Sources
        #   2. rebuild the Chart
        # -------------------------------------------------------------

        $UpdateAction =
            [System.Action]{

                & $UpdateSourceFilter
                & $UpdateChart
            }

        $null =
            $ViewRoot.Dispatcher.BeginInvoke(
                [System.Windows.Threading.DispatcherPriority]::Background,
                $UpdateAction
            )

    }.GetNewClosure())

    # ---------------------------------------------------------------------
    # Register common controls
    # ---------------------------------------------------------------------

    if ($null -ne $RefreshButton) {

        $RefreshButton.Add_Click(
            $UpdateChart
        )
    }

    # Metric ComboBox now represents Presets.
    $MetricComboBox.Add_SelectionChanged(
        $ApplyPreset
    )

    # Time range keeps current Source and Series selections.
    $TimeRangeComboBox.Add_SelectionChanged(
        $UpdateChart
    )

    # ---------------------------------------------------------------------
    # Initial chart
    # ---------------------------------------------------------------------

    & $UpdateChart

    return $true
}