function New-LiveChartsMultiMetricSeriesCollection {
    <#
    .SYNOPSIS
        Creates multiple LiveCharts line series from one shared history.

    .DESCRIPTION
        Creates one line series for every supplied metric definition.

        All metrics are read from the same prepared history collection.
        The history must already contain chart-ready display values.

        The function is independent of Storage, SAN or Tape.

    .PARAMETER History
        Prepared history objects containing the metrics to display.

    .PARAMETER MetricDefinitions
        Collection describing the metrics that should become chart series.

        Each definition must contain:

            Metric
            DisplayName

        Optionally:

            Color
            GeometrySize
            LineSmoothness
            ShowArea

    .PARAMETER MaximumSeries
        Maximum number of series that may be created.

    .OUTPUTS
        System.Collections.Generic.List[LiveChartsCore.ISeries]
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$History,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$MetricDefinitions,

        [ValidateRange(1, 10)]
        [int]$MaximumSeries = 5
    )

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    if ($History.Count -eq 0) {
        throw 'No history entries were supplied.'
    }

    if ($MetricDefinitions.Count -eq 0) {
        throw 'No metric definitions were supplied.'
    }

    if ($MetricDefinitions.Count -gt $MaximumSeries) {
        throw (
            "A maximum of $MaximumSeries metric series is allowed. " +
            "$($MetricDefinitions.Count) definitions were supplied."
        )
    }

    $DefaultColors = @(
        '#2E86DE'
        '#2ECC71'
        '#E67E22'
        '#9B59B6'
        '#34495E'
    )

    $SeriesCollection =
        [System.Collections.Generic.List[
            LiveChartsCore.ISeries
        ]]::new()

    for (
        $SeriesIndex = 0
        $SeriesIndex -lt $MetricDefinitions.Count
        $SeriesIndex++
    ) {
        $Definition =
            $MetricDefinitions[$SeriesIndex]

        if ($null -eq $Definition) {
            throw (
                "Metric definition at index $SeriesIndex is null."
            )
        }

        foreach ($PropertyName in @(
            'Metric',
            'DisplayName'
        )) {
            if (
                -not $Definition.PSObject.Properties[
                    $PropertyName
                ]
            ) {
                throw (
                    "Metric definition at index $SeriesIndex does not " +
                    "contain property '$PropertyName'."
                )
            }
        }

        $Metric =
            [string]$Definition.Metric

        $SeriesName =
            [string]$Definition.DisplayName

        if ([string]::IsNullOrWhiteSpace($Metric)) {
            throw (
                "Metric definition at index $SeriesIndex has no metric."
            )
        }

        if ([string]::IsNullOrWhiteSpace($SeriesName)) {
            $SeriesName = $Metric
        }

        $SeriesColor =
            $DefaultColors[
                $SeriesIndex % $DefaultColors.Count
            ]

        if (
            $Definition.PSObject.Properties['Color'] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$Definition.Color
            )
        ) {
            $SeriesColor =
                [string]$Definition.Color
        }

        $GeometrySize = 6

        if (
            $Definition.PSObject.Properties['GeometrySize'] -and
            $null -ne $Definition.GeometrySize
        ) {
            $GeometrySize =
                [double]$Definition.GeometrySize
        }

        $LineSmoothness = 0

        if (
            $Definition.PSObject.Properties['LineSmoothness'] -and
            $null -ne $Definition.LineSmoothness
        ) {
            $LineSmoothness =
                [double]$Definition.LineSmoothness
        }

        $ShowArea = $false

        if (
            $Definition.PSObject.Properties['ShowArea'] -and
            $null -ne $Definition.ShowArea
        ) {
            $ShowArea =
                [bool]$Definition.ShowArea
        }

        $Series =
            New-LiveChartsLineSeries `
                -History $History `
                -Metric $Metric `
                -SeriesName $SeriesName `
                -LineSmoothness $LineSmoothness `
                -GeometrySize $GeometrySize `
                -Color $SeriesColor `
                -ShowArea $ShowArea

        if ($null -eq $Series) {
            throw (
                "Series for metric '$Metric' could not be created."
            )
        }

        $SeriesCollection.Add(
            $Series
        )
    }

    Write-Output -NoEnumerate $SeriesCollection
}