function Update-StorageSFPHistoryViewer {
    <#
    .SYNOPSIS
        Updates the Storage SFP history viewer.

    .DESCRIPTION
        Reads the selected port, metric and time range from the supplied
        WPF controls, creates a Storage SFP history request and updates
        the Window DataContext with the resulting chart data.

        The function contains the orchestration for refreshing the viewer.
        Database access and LiveCharts object creation remain separated in
        their corresponding helper functions.

    .PARAMETER Window
        WPF Window or UserControl whose DataContext should be updated.

    .PARAMETER CustomerNbr
        Customer number used to select the corresponding SQLite database.

    .PARAMETER PortComboBox
        ComboBox containing the available Storage FC ports.

    .PARAMETER MetricComboBox
        ComboBox containing the available Storage metrics.

    .PARAMETER TimeRangeComboBox
        ComboBox containing the available history time ranges.

    .PARAMETER StatusTextBlock
        TextBlock used to display status and error messages.

    .PARAMETER RefreshButton
        Optional refresh button. It is disabled while the chart is updated.

    .OUTPUTS
        PSCustomObject

        Returns the created ChartData object when the update succeeds.
        Returns nothing when the selection is incomplete.

    .EXAMPLE
        Update-StorageSFPHistoryViewer `
            -Window $Window `
            -CustomerNbr '123456' `
            -PortComboBox $CB_Port `
            -MetricComboBox $CB_Metric `
            -TimeRangeComboBox $CB_TimeRange `
            -StatusTextBlock $TB_Status `
            -RefreshButton $BTN_Refresh
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $Window,

        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

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

    # SelectionChanged is triggered while the combo boxes are still being populated.
    # At this point, not all
    # required selections may be available yet.
        $ComparisonEnabled =
            ($ComparisonCheckBox.IsChecked -eq $true)

        if (
            $null -eq $MetricComboBox.SelectedItem -or
            $null -eq $TimeRangeComboBox.SelectedItem
        ) {
            return
        }

        if (
            -not $ComparisonEnabled -and
            $null -eq $PortComboBox.SelectedItem
        ) {
            return
        }

        if (
            $ComparisonEnabled -and
            $ComparisonListBox.SelectedItems.Count -lt 2
        ) {
            $StatusTextBlock.Text =
                'Bitte mindestens zwei Storage-Ports für den Vergleich auswählen.'
        
            return
        }

            try {
                if ($null -ne $RefreshButton) {
                    $RefreshButton.IsEnabled = $false
                }
            
                $StatusTextBlock.Text = 'History wird geladen …'
            
        $SelectedMetric    = $MetricComboBox.SelectedItem
        $SelectedTimeRange = $TimeRangeComboBox.SelectedItem
            
        $SelectedPort  = $null
        $SelectedPorts = @()

        if ($ComparisonEnabled) {
            $SelectedPorts = @(
                $ComparisonListBox.SelectedItems
            )
        }
        else {
            $SelectedPort = $PortComboBox.SelectedItem
        }

        # Check the selected port.
        $RequiredPortProperties = @(
            'RowID'
            'DisplayName'
        )

        if ($ComparisonEnabled) {
            foreach ($CurrentPort in $SelectedPorts) {
                foreach ($PropertyName in $RequiredPortProperties) {
                    if (-not $CurrentPort.PSObject.Properties[$PropertyName]) {
                        throw (
                            "Selected comparison port property " +
                            "'$PropertyName' is missing."
                        )
                    }
                }
            }
        }
        else {
            foreach ($PropertyName in $RequiredPortProperties) {
                if (-not $SelectedPort.PSObject.Properties[$PropertyName]) {
                    throw "Selected port property '$PropertyName' is missing."
                }
            }
        }

        # Check the selected metric.
        $RequiredMetricProperties = @(
            'Metric'
            'DisplayName'
        )

        foreach ($PropertyName in $RequiredMetricProperties) {
            if (-not $SelectedMetric.PSObject.Properties[$PropertyName]) {
                throw "Selected metric property '$PropertyName' is missing."
            }
        }

        # Check the selected time period.
        $RequiredTimeRangeProperties = @(
            'Duration'
            'LabelFormat'
            'DateTimeStep'
        )

        foreach ($PropertyName in $RequiredTimeRangeProperties) {
            if (-not $SelectedTimeRange.PSObject.Properties[$PropertyName]) {
                throw "Selected time-range property '$PropertyName' is missing."
            }
        }

        $EndTime = Get-Date

        $StartTime = $EndTime.Subtract(
            [TimeSpan]$SelectedTimeRange.Duration
        )

        # Build a request for the selected port, metric, and time period.
        if ($ComparisonEnabled) {
            $SelectedRowIDs = @(
                foreach ($CurrentPort in $SelectedPorts) {
                    [string]$CurrentPort.RowID
                }
            )
            
            $Request = New-StorageSFPHistoryRequest `
                -CustomerNbr $CustomerNbr `
                -RowIDs $SelectedRowIDs `
                -Metric ([string]$SelectedMetric.Metric) `
                -StartTime $StartTime `
                -EndTime $EndTime `
                -DateTimeLabelFormat ([string]$SelectedTimeRange.LabelFormat) `
                -DateTimeStep ([TimeSpan]$SelectedTimeRange.DateTimeStep)
        }
        else {
            $Request = New-StorageSFPHistoryRequest `
                -CustomerNbr $CustomerNbr `
                -RowID ([string]$SelectedPort.RowID) `
                -Metric ([string]$SelectedMetric.Metric) `
                -StartTime $StartTime `
                -EndTime $EndTime `
                -DateTimeLabelFormat ([string]$SelectedTimeRange.LabelFormat) `
                -DateTimeStep ([TimeSpan]$SelectedTimeRange.DateTimeStep)
        }

        # Generate chart data.
        $ChartData = Update-StorageSFPHistoryChart `
            -Request $Request

        if ($null -eq $ChartData) {
            throw 'Update-StorageSFPHistoryChart returned no chart data.'
        }

        # PowerShell can automatically resolve collections when a function returns
        # a result:
        #
        #   one series  -> a single LineSeries object
        #   two series -> Object[]
        #
        # However, LiveCharts always expects a collection. Therefore,
        # series and axes are reliably retyped here.

        $NormalizedSeries =
            [System.Collections.Generic.List[
                LiveChartsCore.ISeries
            ]]::new()

        foreach ($SeriesItem in @($ChartData.Series)) {
            if ($null -eq $SeriesItem) {
                continue
            }

            $NormalizedSeries.Add(
                [LiveChartsCore.ISeries]$SeriesItem
            )
        }

        $NormalizedXAxes =
            [System.Collections.Generic.List[
                LiveChartsCore.SkiaSharpView.Axis
            ]]::new()

        foreach ($AxisItem in @($ChartData.XAxes)) {
            if ($null -eq $AxisItem) {
                continue
            }

            $NormalizedXAxes.Add(
                [LiveChartsCore.SkiaSharpView.Axis]$AxisItem
            )
        }

        $NormalizedYAxes =
            [System.Collections.Generic.List[
                LiveChartsCore.SkiaSharpView.Axis
            ]]::new()

        foreach ($AxisItem in @($ChartData.YAxes)) {
            if ($null -eq $AxisItem) {
                continue
            }

            $NormalizedYAxes.Add(
                [LiveChartsCore.SkiaSharpView.Axis]$AxisItem
            )
        }

        if ($NormalizedSeries.Count -eq 0) {
            throw 'The chart model contains no usable LiveCharts series.'
        }

        if ($NormalizedXAxes.Count -eq 0) {
            throw 'The chart model contains no usable X axis.'
        }

        if ($NormalizedYAxes.Count -eq 0) {
            throw 'The chart model contains no usable Y axis.'
        }

        # Replace the properties that may have been resolved with the
        # typed collections.
        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name Series `
                -Value $NormalizedSeries `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name XAxes `
                -Value $NormalizedXAxes `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name YAxes `
                -Value $NormalizedYAxes `
                -Force

        $Unit      = [string]$ChartData.MetricInfo.Unit
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

            if ($null -eq $Value -or $Value -is [DBNull]) {
                return '-'
            }

            $FormattedValue = ([double]$Value).ToString(
                $NumberFormat,
                [System.Globalization.CultureInfo]::CurrentCulture
            )

            if ([string]::IsNullOrWhiteSpace($Unit)) {
                return $FormattedValue
            }

            return "$FormattedValue $Unit"
        }

        # Add statistical texts formatted for the GUI.
        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name CurrentValueText `
                -Value (& $FormatValue $ChartData.CurrentValue) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name MinimumValueText `
                -Value (& $FormatValue $ChartData.MinimumValue) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name MaximumValueText `
                -Value (& $FormatValue $ChartData.MaximumValue) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name AverageValueText `
                -Value (& $FormatValue $ChartData.AverageValue) `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name PointCountText `
                -Value ([string]$ChartData.PointCount) `
                -Force

        # Also store the current selection in the DataContext.
        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name SelectedPort `
                -Value $SelectedPort `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name SelectedPorts `
                -Value $SelectedPorts `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name ComparisonEnabled `
                -Value $ComparisonEnabled `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name SelectedMetric `
                -Value $SelectedMetric `
                -Force

        $ChartData |
            Add-Member `
                -MemberType NoteProperty `
                -Name SelectedTimeRange `
                -Value $SelectedTimeRange `
                -Force

        # Update the standard XAML bindings as follows:
        #
        #   Series="{Binding Series}"
        #   XAxes="{Binding XAxes}"
        #   YAxes="{Binding YAxes}"
        #
        # Direct access to CartesianChart is not required due to the
        # ToolTip/Tooltip conflict.
        $Window.DataContext = $ChartData

if ($ComparisonEnabled) {
    $StatusTextBlock.Text = (
        '{0} Ports | {1} | {2} Messpunkte | {3:dd.MM.yyyy HH:mm:ss} bis {4:dd.MM.yyyy HH:mm:ss}' -f
        $ChartData.SourceCount,
        $SelectedMetric.DisplayName,
        $ChartData.PointCount,
        $StartTime,
        $EndTime
    )
}
else {
    $StatusTextBlock.Text = (
        '{0} | {1} | {2} Messpunkte | {3:dd.MM.yyyy HH:mm:ss} bis {4:dd.MM.yyyy HH:mm:ss}' -f
        $SelectedPort.DisplayName,
        $SelectedMetric.DisplayName,
        $ChartData.PointCount,
        $StartTime,
        $EndTime
    )
}

        return $ChartData
    }
    catch {
        $ErrorMessage = [string]$_.Exception.Message

        # An empty time slot is not a technical error.
        if ($ErrorMessage -like 'No Storage SFP history was found*') {
            $SelectedPort      = $PortComboBox.SelectedItem
            $SelectedTimeRange = $TimeRangeComboBox.SelectedItem

            # Remove old chart data so that values from a previous
            # selection are not displayed under the new port or time period.
            $EmptySeries =
                [System.Collections.Generic.List[
                    LiveChartsCore.ISeries
                ]]::new()

            $EmptyXAxes =
                [System.Collections.Generic.List[
                    LiveChartsCore.SkiaSharpView.Axis
                ]]::new()

            $EmptyYAxes =
                [System.Collections.Generic.List[
                    LiveChartsCore.SkiaSharpView.Axis
                ]]::new()

            $Window.DataContext = [PSCustomObject]@{
                Series          = $EmptySeries
                XAxes           = $EmptyXAxes
                YAxes           = $EmptyYAxes

                CurrentValueText = '-'
                MinimumValueText = '-'
                MaximumValueText = '-'
                AverageValueText = '-'
                PointCount       = 0
                PointCountText   = '0'
            }

            $StatusTextBlock.Text = (
                "Für '{0}' liegen im Zeitraum '{1}' keine Messwerte vor." -f
                $SelectedPort.DisplayName,
                $SelectedTimeRange.DisplayName
            )

            return
        }

        # Provide detailed output for actual technical errors.
        $StatusTextBlock.Text = "Fehler: $ErrorMessage"

        Write-Host (
            "Storage SFP History Fehler: $ErrorMessage"
        ) -ForegroundColor Red

        Write-Host ''
        Write-Host (
            "Fehlertyp: $($_.Exception.GetType().FullName)"
        ) -ForegroundColor Yellow

        Write-Host 'Position:' -ForegroundColor Yellow
        Write-Host $_.InvocationInfo.PositionMessage
        Write-Host ''
        Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
    }
    finally {
        if ($null -ne $RefreshButton) {
            $RefreshButton.IsEnabled = $true
        }
    }
}