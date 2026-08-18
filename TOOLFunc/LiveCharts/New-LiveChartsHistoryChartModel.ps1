function New-LiveChartsHistoryChartModel {
    <#
    .SYNOPSIS
        Creates a complete LiveCharts history chart model.

    .DESCRIPTION
        Builds a chart model from prepared history series.

        The function is independent of Storage, SAN or Tape.
        All domain-specific processing must already be completed before
        calling this function.

        Supported combinations:

            Single source + single metric
            Multiple sources + single metric
            Single source + multiple metrics
            Multiple sources + multiple metrics

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$SeriesDefinitions,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$AllChartHistory,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$MetricValues,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $MetricInfo,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RowID,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$RowIDs,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Metric,

        [Parameter(Mandatory)]
        [datetime]$StartTime,

        [Parameter(Mandatory)]
        [datetime]$EndTime,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DateTimeLabelFormat,

        [Parameter(Mandatory)]
        [TimeSpan]$DateTimeStep,

        [Parameter(Mandatory)]
        [bool]$IsComparison
    )

    # ---------------------------------------------------------------------
    # Validate prepared history data
    # ---------------------------------------------------------------------

    if ($SeriesDefinitions.Count -eq 0) {
        throw (
            "No usable histories were found for metric " +
            "'$Metric'."
        )
    }

    # For a single source or single-source MultiMetric view,
    # use the first prepared history.
    $ChartHistory = @(
        $SeriesDefinitions[0].History
    )

    # ---------------------------------------------------------------------
    # Detect MultiMetric mode
    # ---------------------------------------------------------------------

    $IsMultiMetric = (
        $MetricInfo.PSObject.Properties['ValueMode'] -and
        [string]$MetricInfo.ValueMode -eq 'MultiMetric'
    )

    # ---------------------------------------------------------------------
    # MultiMetric value collection
    #
    # Important:
    #
    # Single Source:
    #     values are taken from ChartHistory.
    #
    # Multi Source:
    #     values must be taken from AllChartHistory so that all selected
    #     Sources participate in Y-axis scaling.
    # ---------------------------------------------------------------------

    if ($IsMultiMetric) {

        if (
            -not $MetricInfo.PSObject.Properties['Metrics'] -or
            $null -eq $MetricInfo.Metrics
        ) {
            throw (
                "Metric '$Metric' uses ValueMode 'MultiMetric', " +
                "but no Metrics definitions are available."
            )
        }

        $HistoryForMetricValues = if ($IsComparison) {
            $AllChartHistory
        }
        else {
            $ChartHistory
        }

        $MetricValues = @(
            foreach ($HistoryItem in $HistoryForMetricValues) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                foreach ($Definition in @($MetricInfo.Metrics)) {

                    if (
                        $null -eq $Definition -or
                        -not $Definition.PSObject.Properties['Metric']
                    ) {
                        continue
                    }

                    $MetricName =
                        [string]$Definition.Metric

                    if (
                        [string]::IsNullOrWhiteSpace(
                            $MetricName
                        )
                    ) {
                        continue
                    }

                    $Property =
                        $HistoryItem.PSObject.Properties[
                            $MetricName
                        ]

                    if (
                        $null -eq $Property -or
                        $null -eq $Property.Value -or
                        $Property.Value -is [DBNull] -or
                        [string]::IsNullOrWhiteSpace(
                            [string]$Property.Value
                        )
                    ) {
                        continue
                    }

                    try {
                        [double]$Property.Value
                    }
                    catch {
                        Write-Warning (
                            "Value '$($Property.Value)' of metric " +
                            "'$MetricName' could not be converted to Double."
                        )
                    }
                }
            }
        )
    }

    if ($MetricValues.Count -eq 0) {
        throw (
            "The history contains no usable values for " +
            "metric '$Metric'."
        )
    }

    # ---------------------------------------------------------------------
    # Optional reference values
    #
    # Reference metrics currently apply only to a single-source view.
    # ---------------------------------------------------------------------

    $ReferenceMetricValues = @()

    if (
        -not $IsComparison -and
        -not [string]::IsNullOrWhiteSpace(
            [string]$MetricInfo.ReferenceMetric
        )
    ) {
        $ReferenceMetric =
            [string]$MetricInfo.ReferenceMetric

        $ReferenceMetricValues = @(
            foreach ($HistoryItem in $ChartHistory) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                $ReferenceProperty =
                    $HistoryItem.PSObject.Properties[
                        $ReferenceMetric
                    ]

                if ($null -eq $ReferenceProperty) {
                    continue
                }

                $RawValue =
                    $ReferenceProperty.Value

                if (
                    $null -eq $RawValue -or
                    $RawValue -is [DBNull] -or
                    [string]::IsNullOrWhiteSpace(
                        [string]$RawValue
                    )
                ) {
                    continue
                }

                try {
                    [double]$RawValue
                }
                catch {
                    Write-Warning (
                        "Value '$RawValue' of reference metric " +
                        "'$ReferenceMetric' could not be converted " +
                        'to Double and was skipped.'
                    )
                }
            }
        )
    }

    # ---------------------------------------------------------------------
    # Build common Y-axis value collection
    # ---------------------------------------------------------------------

    $AxisValues = @(
        $MetricValues

        if ($ReferenceMetricValues.Count -gt 0) {
            $ReferenceMetricValues
        }
    )

    # ---------------------------------------------------------------------
    # Create series
    #
    # 1 Source x n Metrics
    #     New-LiveChartsMultiMetricSeriesCollection
    #
    # n Sources x 1 Metric
    #     New-LiveChartsMultiSeriesCollection
    #
    # n Sources x n Metrics
    #     New-LiveChartsMultiSourceMultiMetricSeriesCollection
    #
    # 1 Source x 1 Metric
    #     New-LiveChartsSeriesCollection
    # ---------------------------------------------------------------------

    if ($IsComparison -and $IsMultiMetric) {

        $SeriesCollection =
            New-LiveChartsMultiSourceMultiMetricSeriesCollection `
                -SeriesDefinitions $SeriesDefinitions `
                -MetricDefinitions @($MetricInfo.Metrics) `
                -MaximumSeries 12
    }
    elseif ($IsMultiMetric) {

        $SeriesCollection =
            New-LiveChartsMultiMetricSeriesCollection `
                -History $ChartHistory `
                -MetricDefinitions @($MetricInfo.Metrics) `
                -MaximumSeries 10
    }
    elseif ($IsComparison) {

        $SeriesCollection =
            New-LiveChartsMultiSeriesCollection `
                -SeriesDefinitions $SeriesDefinitions `
                -MetricInfo $MetricInfo `
                -MaximumSeries 4
    }
    else {

        $SeriesCollection =
            New-LiveChartsSeriesCollection `
                -History $ChartHistory `
                -MetricInfo $MetricInfo
    }

    # ---------------------------------------------------------------------
    # Select model history
    # ---------------------------------------------------------------------

    if ($IsComparison) {

        $ModelHistory =
            @($AllChartHistory)
    }
    else {

        $ModelHistory =
            @($ChartHistory)
    }

    # ---------------------------------------------------------------------
    # Determine effective DateTime step
    #
    # The configured DateTimeStep describes the preferred spacing.
    # When only a small part of the selected range contains data,
    # reduce the step so that useful labels remain visible.
    # ---------------------------------------------------------------------

    $EffectiveDateTimeStep =
        $DateTimeStep

    $TimeStamps = @(
        $ModelHistory |
            Where-Object {
                $null -ne $_ -and
                $_.PSObject.Properties['TimeStamp'] -and
                $null -ne $_.TimeStamp
            } |
            ForEach-Object {
                [datetime]$_.TimeStamp
            }
    )

    if ($TimeStamps.Count -ge 2) {

        $FirstTimeStamp = (
            $TimeStamps |
                Measure-Object -Minimum
        ).Minimum

        $LastTimeStamp = (
            $TimeStamps |
                Measure-Object -Maximum
        ).Maximum

        $VisibleDuration =
            $LastTimeStamp - $FirstTimeStamp

        if ($VisibleDuration -gt [TimeSpan]::Zero) {

            # Aim for approximately five visible X-axis intervals.
            $DynamicTicks = [long](
                $VisibleDuration.Ticks / 5
            )

            # Do not go below one minute.
            $MinimumTicks =
                [TimeSpan]::FromMinutes(1).Ticks

            if ($DynamicTicks -lt $MinimumTicks) {
                $DynamicTicks =
                    $MinimumTicks
            }

            $DynamicStep =
                [TimeSpan]::FromTicks(
                    $DynamicTicks
                )

            # Only reduce the configured step.
            if ($DynamicStep -lt $EffectiveDateTimeStep) {
                $EffectiveDateTimeStep =
                    $DynamicStep
            }
        }
    }

    # ---------------------------------------------------------------------
    # Create X axis
    #
    # The selected StartTime / EndTime explicitly define the visible
    # time window.
    #
    # This is important when only one or very few measurements exist in
    # the requested period. Without MinLimit / MaxLimit LiveCharts derives
    # the visible range from the available points and may display a much
    # larger time window than requested.
    # ---------------------------------------------------------------------
    
    $XAxis =
        New-LiveChartsDateTimeAxis `
            -Name '' `
            -LabelFormat $DateTimeLabelFormat `
            -MinStep $EffectiveDateTimeStep
    
    # DateTimePoint uses DateTime.Ticks as its X coordinate.
    $XAxis.MinLimit =
        [double]$StartTime.Ticks
    
    $XAxis.MaxLimit =
        [double]$EndTime.Ticks

    # ---------------------------------------------------------------------
    # Create Y axis
    # ---------------------------------------------------------------------

    $MinimumPadding =
        1

    if (
        $MetricInfo.PSObject.Properties.Match(
            'MinimumPadding'
        ).Count -gt 0 -and
        $null -ne $MetricInfo.MinimumPadding
    ) {
        $MinimumPadding =
            [double]$MetricInfo.MinimumPadding
    }

    $YAxis =
        New-LiveChartsValueAxis `
            -Name $MetricInfo.DisplayName `
            -Unit $MetricInfo.Unit `
            -Values $AxisValues `
            -MinimumPadding $MinimumPadding

    # ---------------------------------------------------------------------
    # LiveCharts expects collections for the axes
    # ---------------------------------------------------------------------

    $XAxisCollection =
        [System.Collections.Generic.List[
            LiveChartsCore.SkiaSharpView.Axis
        ]]::new()

    $YAxisCollection =
        [System.Collections.Generic.List[
            LiveChartsCore.SkiaSharpView.Axis
        ]]::new()

    $XAxisCollection.Add(
        $XAxis
    )

    $YAxisCollection.Add(
        $YAxis
    )

    # ---------------------------------------------------------------------
    # Create statistics
    # ---------------------------------------------------------------------

    if ($IsMultiMetric) {

        # Multiple different metrics have no single meaningful
        # current, minimum, maximum or average value.
        #
        # ModelHistory contains:
        #
        #   Single Source:
        #       history of this Source
        #
        #   Multi Source:
        #       histories of all selected Sources
        #
        # Therefore PointCount correctly represents all currently
        # participating history measurements.
        $Statistics = [PSCustomObject]@{
            CurrentValue = $null
            MinimumValue = $null
            MaximumValue = $null
            AverageValue = $null
            PointCount   = $ModelHistory.Count
        }
    }
    elseif ($IsComparison) {

        # Multiple Sources using the same metric.
        $Measurement =
            $MetricValues |
                Measure-Object `
                    -Minimum `
                    -Maximum `
                    -Average

        $Statistics = [PSCustomObject]@{
            CurrentValue = $null
            MinimumValue = [double]$Measurement.Minimum
            MaximumValue = [double]$Measurement.Maximum
            AverageValue = [double]$Measurement.Average
            PointCount   = $ModelHistory.Count
        }
    }
    else {

        # Normal single Source / single Metric statistics.
        $Statistics =
            New-LiveChartsStatistics `
                -History $ChartHistory `
                -Metric $Metric `
                -Values $MetricValues
    }

    # ---------------------------------------------------------------------
    # Create common chart model
    # ---------------------------------------------------------------------

    $ChartModel =
        New-LiveChartsChartModel `
            -Series $SeriesCollection `
            -XAxes $XAxisCollection `
            -YAxes $YAxisCollection `
            -History $ModelHistory `
            -MetricInfo $MetricInfo `
            -Statistics $Statistics `
            -CustomerNbr $CustomerNbr `
            -RowID $RowID `
            -Metric ([string]$MetricInfo.Metric) `
            -StartTime $StartTime `
            -EndTime $EndTime

    # ---------------------------------------------------------------------
    # Add source information
    # ---------------------------------------------------------------------

    $ChartModel |
        Add-Member `
            -MemberType NoteProperty `
            -Name RowIDs `
            -Value ([string[]]$RowIDs) `
            -Force

    $ChartModel |
        Add-Member `
            -MemberType NoteProperty `
            -Name IsComparison `
            -Value $IsComparison `
            -Force

    $ChartModel |
        Add-Member `
            -MemberType NoteProperty `
            -Name SourceCount `
            -Value $SeriesDefinitions.Count `
            -Force

    return $ChartModel
}