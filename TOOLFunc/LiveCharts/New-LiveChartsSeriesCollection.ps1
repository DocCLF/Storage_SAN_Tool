function New-LiveChartsSeriesCollection {
    <#
    .SYNOPSIS
        Creates a LiveCharts series collection for one metric.

    .DESCRIPTION
        Creates the main line series for the selected metric and,
        if configured, an optional reference series.

        The function is independent of Storage, SAN, Tape and the
        underlying data source.

        Required MetricInfo properties:

            Metric
            DisplayName

        Optional MetricInfo properties:

            Color
            ShowArea
            ReferenceMetric
            ReferenceName
            ReferenceColor

    .PARAMETER History
        Historical source objects containing TimeStamp and the configured
        metric properties.

    .PARAMETER MetricInfo
        Metric metadata returned by a metric-information function.

    .OUTPUTS
        System.Collections.Generic.List[LiveChartsCore.ISeries]

    .EXAMPLE
        $SeriesCollection = New-LiveChartsSeriesCollection `
            -History $History `
            -MetricInfo $MetricInfo
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$History,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $MetricInfo
    )

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    if ($History.Count -eq 0) {
        throw 'The History collection does not contain any entries.'
    }

    $RequiredProperties = @(
        'Metric'
        'DisplayName'
    )

    foreach ($PropertyName in $RequiredProperties) {
        if (-not $MetricInfo.PSObject.Properties[$PropertyName]) {
            throw "MetricInfo property '$PropertyName' is missing."
        }
    }

    if ([string]::IsNullOrWhiteSpace([string]$MetricInfo.Metric)) {
        throw "MetricInfo property 'Metric' is empty."
    }

    if ([string]::IsNullOrWhiteSpace([string]$MetricInfo.DisplayName)) {
        throw "MetricInfo property 'DisplayName' is empty."
    }

    $SeriesCollection =
        [System.Collections.Generic.List[
            LiveChartsCore.ISeries
        ]]::new()

    $ShowArea = $true

    if (
        $MetricInfo.PSObject.Properties['ShowArea'] -and
        $null -ne $MetricInfo.ShowArea
    ) {
        $ShowArea = [bool]$MetricInfo.ShowArea
    }

    # Create the main series.
    $MainSeriesParameters = @{
        History        = $History
        Metric         = [string]$MetricInfo.Metric
        SeriesName     = [string]$MetricInfo.DisplayName
        LineSmoothness = 0
        GeometrySize   = 8
        ShowArea       = $ShowArea
    }

    if (
        $MetricInfo.PSObject.Properties['Color'] -and
        -not [string]::IsNullOrWhiteSpace([string]$MetricInfo.Color)
    ) {
        $MainSeriesParameters.Color = [string]$MetricInfo.Color
    }

    $MainSeries = New-LiveChartsLineSeries @MainSeriesParameters

    if ($null -eq $MainSeries) {
        throw (
            "The main series for metric '$($MetricInfo.Metric)' " +
            'could not be created.'
        )
    }

    $SeriesCollection.Add($MainSeries)

    # Generate an optional reference series.
    $ReferenceMetric = $null

    if ($MetricInfo.PSObject.Properties['ReferenceMetric']) {
        $ReferenceMetric = [string]$MetricInfo.ReferenceMetric
    }

    if (-not [string]::IsNullOrWhiteSpace($ReferenceMetric)) {
        $ReferenceName = $ReferenceMetric

        if (
            $MetricInfo.PSObject.Properties['ReferenceName'] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$MetricInfo.ReferenceName
            )
        ) {
            $ReferenceName = [string]$MetricInfo.ReferenceName
        }

        $ReferenceSeriesParameters = @{
            History        = $History
            Metric         = $ReferenceMetric
            SeriesName     = $ReferenceName
            LineSmoothness = 0
            GeometrySize   = 0
            ShowArea       = $false
            IsReference    = $true
        }

        if (
            $MetricInfo.PSObject.Properties['ReferenceColor'] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$MetricInfo.ReferenceColor
            )
        ) {
            $ReferenceSeriesParameters.Color =
                [string]$MetricInfo.ReferenceColor
        }

        $ReferenceSeries = New-LiveChartsLineSeries @ReferenceSeriesParameters

        if ($null -eq $ReferenceSeries) {
            throw (
                "The reference series for metric '$ReferenceMetric' " +
                'could not be created.'
            )
        }

        $SeriesCollection.Add($ReferenceSeries)
    }

    # Return the typed list as a single object.
    # Prevents PowerShell from outputting the contained arrays individually.
    Write-Output -NoEnumerate $SeriesCollection

}