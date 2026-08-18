function Initialize-SANPortErrorHistoryView {
    <#
    .SYNOPSIS
        Initializes the SAN port-error history viewer.

    .DESCRIPTION
        Initializes the Brocade SAN port-error history viewer using the
        generic LiveCharts selector architecture.

        Selection hierarchy:

            SAN Switch
                -> Port
                    -> Metric / Series

        Multiple ports and multiple compatible metrics can be displayed
        simultaneously.

        All currently supported SAN port-error metrics belong to the
        Counter UnitGroup.

        The SAN-Switch selector is only visible when ports from more than
        one switch are available.

        Legacy single-source / comparison controls are retained only for
        compatibility with the shared XAML and are hidden by this
        initializer.

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
        Multi-select list containing the available SAN ports.

    .PARAMETER SeriesSelectorListBox
        Multi-select list containing the available SAN port-error metrics.

    .PARAMETER GroupSelectorListBox
        List containing the available SAN switches.

    .PARAMETER GroupSelectorPanel
        Container of the SAN-switch selector.

    .PARAMETER MetricComboBox
        Quick metric selector.

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
    # Load available SAN ports
    # ---------------------------------------------------------------------

    $Ports = @(
        Get-SANPortErrorHistoryPorts `
            -CustomerNbr $CustomerNbr
    )

    if ($Ports.Count -eq 0) {

        $StatusTextBlock.Text = (
            "Keine SAN-Port-Error-History-Daten für Kunde " +
            "$CustomerNbr gefunden."
        )

        return $false
    }

    # ---------------------------------------------------------------------
    # Build generic Source selector
    #
    # SourceKey   = RowID
    # DisplayName = readable Switch / Port name
    # SourceGroup = Switch SerialNumber
    # ---------------------------------------------------------------------

    $SourceSelectorModel =
        New-LiveChartsSourceSelectorModel `
            -Sources $Ports `
            -KeyProperty 'RowID' `
            -DisplayNameProperty 'DisplayName' `
            -GroupProperty 'SerialNumber'

    # ---------------------------------------------------------------------
    # Build SAN-Switch Group selector
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
    # Replace generic Group DisplayName with readable SwitchName
    #
    # GroupKey remains SerialNumber because it is the stable identifier.
    # ---------------------------------------------------------------------

    foreach ($Group in $GroupSelectorModel.Groups) {

        $MatchingPort =
            $Ports |
                Where-Object {
                    [string]$_.SerialNumber -eq
                    [string]$Group.GroupKey
                } |
                Select-Object -First 1

        if (
            $null -ne $MatchingPort -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$MatchingPort.SwitchName
            )
        ) {

            $Group.DisplayName =
                [string]$MatchingPort.SwitchName
        }
    }

    # ---------------------------------------------------------------------
    # Load available SAN metrics
    # ---------------------------------------------------------------------

    $Metrics = @(
        Get-SANPortErrorLiveChartsMetricInfo -All
    )

    if ($Metrics.Count -eq 0) {

        $StatusTextBlock.Text =
            'Es wurden keine SAN-Port-Error-Metriken gefunden.'

        return $false
    }

    # ---------------------------------------------------------------------
    # Load available time ranges
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
            -MetricDefinitions $Metrics

    # ---------------------------------------------------------------------
    # Select CRC Errors as initial metric
    #
    # This is a useful and easily understandable SAN error counter.
    # ---------------------------------------------------------------------

    $DefaultMetric =
        $Metrics |
            Where-Object {
                $_.Metric -eq 'CrcErr'
            } |
            Select-Object -First 1

    if ($null -eq $DefaultMetric) {

        $DefaultMetric =
            $Metrics |
                Select-Object -First 1
    }

    foreach ($SeriesItem in $SelectorModel.Series) {

        $SeriesItem.IsSelected = (
            [string]$SeriesItem.Metric -eq
            [string]$DefaultMetric.Metric
        )
    }

    $null =
        Update-LiveChartsSeriesSelectorState `
            -SelectorModel $SelectorModel

    # ---------------------------------------------------------------------
    # Fill controls
    # ---------------------------------------------------------------------

    $PortComboBox.ItemsSource =
        $Ports

    $MetricComboBox.ItemsSource =
        $Metrics

    $TimeRangeComboBox.ItemsSource =
        $TimeRanges

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
    # Hide legacy comparison controls
    #
    # SourceSelectorListBox handles single and multiple ports.
    # ---------------------------------------------------------------------

    $ComparisonCheckBox.IsChecked =
        $false

    $ComparisonCheckBox.IsEnabled =
        $false

    $ComparisonCheckBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    $ComparisonListBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    $PortComboBox.Visibility =
        [System.Windows.Visibility]::Collapsed

    # ---------------------------------------------------------------------
    # Show SAN-Switch selector only if multiple switches exist
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
    # Default control selections
    # ---------------------------------------------------------------------

    $PortComboBox.SelectedIndex =
        0

    $MetricComboBox.SelectedItem =
        $DefaultMetric

    $TimeRangeComboBox.SelectedItem =
        $DefaultTimeRange

    # ---------------------------------------------------------------------
    # Select first visible Port initially
    # ---------------------------------------------------------------------

    $InitialSources = @(
        Get-LiveChartsFilteredSources `
            -SourceSelectorModel $SourceSelectorModel `
            -GroupSelectorModel $GroupSelectorModel
    )

    if ($InitialSources.Count -gt 0) {

        if (
            $InitialSources[0].PSObject.Properties[
                'IsSelected'
            ]
        ) {

            $InitialSources[0].IsSelected =
                $true
        }
    }

    $SourceSelectorListBox.Items.Refresh()

    # ---------------------------------------------------------------------
    # Helper:
    # Return selected ports belonging to active switch groups.
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

        if ($SelectedGroupKeys.Count -eq 0) {
            return @()
        }

        $SelectedPorts = @(
            Get-LiveChartsSelectedSources `
                -SelectorModel $SourceSelectorModel |
                Where-Object {
                    [string]$_.SerialNumber -in
                    $SelectedGroupKeys
                }
        )

        return $SelectedPorts

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Helper:
    # Refresh visible Sources after SAN-Switch filter changes.
    # ---------------------------------------------------------------------

    $RefreshSourceSelector = {

        $FilteredSources = @(
            Get-LiveChartsFilteredSources `
                -SourceSelectorModel $SourceSelectorModel `
                -GroupSelectorModel $GroupSelectorModel
        )

        $SourceSelectorListBox.ItemsSource =
            $FilteredSources

        $SourceSelectorListBox.Items.Refresh()

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Common chart update action
    # ---------------------------------------------------------------------

    $UpdateChart = {

        # Reset status appearance from a possible previous warning.
        $StatusTextBlock.Foreground =
            [System.Windows.Media.Brushes]::Black

        $StatusTextBlock.FontWeight =
            [System.Windows.FontWeights]::Normal

        # -------------------------------------------------------------
        # Recalculate compatible Series
        # -------------------------------------------------------------

        $null =
            Update-LiveChartsSeriesSelectorState `
                -SelectorModel $SelectorModel

        $SeriesSelectorListBox.Items.Refresh()

        # -------------------------------------------------------------
        # Resolve selected Metrics
        # -------------------------------------------------------------

        $SelectedMetricDefinitions = @(
            Get-LiveChartsSelectedMetricDefinitions `
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
        # Resolve selected Ports
        # -------------------------------------------------------------

        $SelectedPorts = @(
            & $GetSelectedPorts
        )

        if ($SelectedPorts.Count -eq 0) {

            $StatusTextBlock.Text =
                'Bitte mindestens einen SAN-Port auswählen.'

            return
        }

        if ($SelectedPorts.Count -gt 4) {

            $StatusTextBlock.Text =
                'Es können maximal vier SAN-Ports gleichzeitig angezeigt werden.'

            return
        }

        # -------------------------------------------------------------
        # Check total Series limit
        #
        # n Sources x n Metrics must stay <= 12.
        # -------------------------------------------------------------

        $ExpectedSeriesCount =
            $SelectedPorts.Count *
            $SelectedMetricDefinitions.Count

        if (
            $SelectedPorts.Count -gt 1 -and
            $ExpectedSeriesCount -gt 12
        ) {

            $StatusTextBlock.Text = (
                'Die aktuelle Auswahl würde {0} Series erzeugen. ' +
                'Maximal 12 sind gleichzeitig möglich.'
            ) -f $ExpectedSeriesCount

            return
        }

        if (
            $SelectedPorts.Count -eq 1 -and
            $SelectedMetricDefinitions.Count -gt 10
        ) {

            $StatusTextBlock.Text =
                'Für einen SAN-Port können maximal zehn Series gleichzeitig angezeigt werden.'

            return
        }

        $SelectedRowIDs = @(
            $SelectedPorts |
                ForEach-Object {
                    [string]$_.RowID
                }
        )

        # -------------------------------------------------------------
        # Resolve selected time range
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
                'SAN-Port-Error-History wird geladen …'

            $ChartData =
                Update-SANPortErrorHistoryChart `
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

            # ---------------------------------------------------------
            # Prepare formatted values for shared XAML
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
            # Update Viewer
            # ---------------------------------------------------------

            $ViewRoot.DataContext =
                $ChartData

            if ($SelectedPorts.Count -eq 1) {

                $SourceText =
                    [string]$SelectedPorts[0].DisplayName
            }
            else {

                $SourceText =
                    '{0} Ports' -f
                    $SelectedPorts.Count
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
                "SAN Port Error History Fehler: " +
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
    # Quick Metric preset
    # ---------------------------------------------------------------------

    $ApplyMetricPreset = {

        $SelectedMetric =
            $MetricComboBox.SelectedItem

        if ($null -eq $SelectedMetric) {
            return
        }

        foreach ($SeriesItem in $SelectorModel.Series) {

            $SeriesItem.IsSelected = (
                [string]$SeriesItem.Metric -eq
                [string]$SelectedMetric.Metric
            )
        }

        $null =
            Update-LiveChartsSeriesSelectorState `
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

                $SelectedPorts = @(
                    & $GetSelectedPorts
                )

                if ($SelectedPorts.Count -gt 4) {

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
                        'Es können maximal vier SAN-Ports gleichzeitig angezeigt werden.'

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
    # SAN-Switch Group CheckBox handler
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

                & $RefreshSourceSelector

                $VisibleSources = @(
                    Get-LiveChartsFilteredSources `
                        -SourceSelectorModel $SourceSelectorModel `
                        -GroupSelectorModel $GroupSelectorModel
                )

                $SelectedPorts = @(
                    & $GetSelectedPorts
                )

                if (
                    $SelectedPorts.Count -eq 0 -and
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