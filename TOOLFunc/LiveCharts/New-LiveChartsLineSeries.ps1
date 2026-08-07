function New-LiveChartsLineSeries {
    <#
    .SYNOPSIS
        Creates a LiveCharts line series from historical PowerShell objects.

    .DESCRIPTION
        Converts PowerShell objects containing a TimeStamp property and a
        selectable numeric metric into a LiveCharts LineSeries<DateTimePoint>.

        The function is independent of the data source. It does not know
        anything about SQLite, IBM Storage, SAN switches or SFPs.

        Each valid input object is converted into a DateTimePoint:

            TimeStamp -> X value
            Metric    -> Y value

        Objects with an empty TimeStamp or metric value are skipped.

    .PARAMETER History
        Collection of historical PowerShell objects.

        Each object must contain:

            TimeStamp
            The property specified by Metric

    .PARAMETER Metric
        Name of the property that supplies the Y value.

        Examples:

            SFPTemp
            TXPwr
            RXPwr
            CRCErr

    .PARAMETER SeriesName
        Display name of the generated line series.

        If omitted, the metric name is used.

    .PARAMETER LineSmoothness
        Defines how strongly the line is smoothed.

        0 creates straight technical measurement lines.
        The default value is 0.

    .PARAMETER GeometrySize
        Size of the visible point markers.

        Use 0 to hide individual point markers.
        The default value is 8.

    .OUTPUTS
        LiveChartsCore.SkiaSharpView.LineSeries[
            LiveChartsCore.Defaults.DateTimePoint
        ]

    .EXAMPLE
        $Series = New-LiveChartsLineSeries `
            -History $History `
            -Metric 'SFPTemp' `
            -SeriesName 'SFP-Temperatur'

    .EXAMPLE
        $Series = New-LiveChartsLineSeries `
            -History $History `
            -Metric 'RXPwr' `
            -SeriesName 'RX-Leistung' `
            -GeometrySize 0
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$History,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Metric,

        [ValidateNotNullOrEmpty()]
        [string]$SeriesName,

        [ValidateRange(0.0, 1.0)]
        [double]$LineSmoothness = 0,

        [ValidateRange(0.0, 100.0)]
        [double]$GeometrySize = 8,

        [string]$Color,

        [switch]$IsReference,

        [bool]$ShowArea = $true
    )

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    if ([string]::IsNullOrWhiteSpace($SeriesName)) {
        $SeriesName = $Metric
    }

    if ($History.Count -eq 0) {
        throw 'The History collection does not contain any entries.'
    }

    # Check whether at least one object has the required properties.
    $SampleItem = $History | Where-Object { $null -ne $_ } | Select-Object -First 1

    if ($null -eq $SampleItem) {
        throw 'The History collection contains no valid objects.'
    }

    if (-not $SampleItem.PSObject.Properties['TimeStamp']) {
        throw "The history objects do not contain a 'TimeStamp' property."
    }

    if (-not $SampleItem.PSObject.Properties[$Metric]) {
        throw "The history objects do not contain the metric property '$Metric'."
    }

    # Store LiveCharts timestamps in a typed ObservableCollection.
    # This collection can also be dynamically expanded later.
    $Points = [System.Collections.ObjectModel.ObservableCollection[
        LiveChartsCore.Defaults.DateTimePoint
    ]]::new()

    foreach ($HistoryItem in ($History | Sort-Object TimeStamp)) {
        if ($null -eq $HistoryItem) {continue}

        $RawTimeStamp = $HistoryItem.TimeStamp
        $RawValue     = $HistoryItem.$Metric

        # Do not display empty or invalid values.
        if (
            $null -eq $RawTimeStamp -or
            $RawTimeStamp -is [DBNull] -or
            $null -eq $RawValue -or
            $RawValue -is [DBNull] -or
            [string]::IsNullOrWhiteSpace([string]$RawValue)
        ) {
            continue
        }

        try {
            $PointTimeStamp = [datetime]$RawTimeStamp
            $PointValue     = [double]$RawValue
        }
        catch {
            Write-Warning (
                "History entry was skipped because TimeStamp or metric " +
                "'$Metric' could not be converted. " +
                "TimeStamp='$RawTimeStamp', Value='$RawValue'."
            )

            continue
        }

        $Point = [LiveChartsCore.Defaults.DateTimePoint]::new(
            $PointTimeStamp,
            $PointValue
        )

        $Points.Add($Point)
    }

    if ($Points.Count -eq 0) {throw "No valid chart points could be created for metric '$Metric'."}

    # Dynamically create a LineSeries<DateTimePoint>.
    # This method works more reliably in PowerShell 5.1 and PowerShell 7.
    $OpenSeriesType = [LiveChartsCore.SkiaSharpView.LineSeries``1]

    $ClosedSeriesType = $OpenSeriesType.MakeGenericType([LiveChartsCore.Defaults.DateTimePoint])

    $Series = [Activator]::CreateInstance($ClosedSeriesType)

    $Series.Name           = $SeriesName
    $Series.Values         = $Points
    $Series.LineSmoothness = $LineSmoothness
    $Series.GeometrySize   = $GeometrySize

    # Optionally, use a fixed color for the series.
    if (-not [string]::IsNullOrWhiteSpace($Color)) {
        try {
            $SKColor = [SkiaSharp.SKColor]::Parse($Color)

            $Stroke = New-Object LiveChartsCore.SkiaSharpView.Painting.SolidColorPaint -ArgumentList $SKColor, ([single]2)

            $Series.Stroke = $Stroke

            # Display markers in the same color.
            if (-not $IsReference -and $GeometrySize -gt 0) {
                $Series.GeometryStroke = New-Object LiveChartsCore.SkiaSharpView.Painting.SolidColorPaint -ArgumentList $SKColor, ([single]2)

                $Series.GeometryFill = New-Object LiveChartsCore.SkiaSharpView.Painting.SolidColorPaint -ArgumentList $SKColor
            }
        }
        catch {
            Write-Warning (
                "The color '$Color' could not be applied to series " +
                "'$SeriesName': $($_.Exception.Message)"
            )
        }
    }

    # Only intervene for metrics without an area representation.
    if (-not $ShowArea) {
        $Series.Fill = $null
    }

    # Always display reference series without area or markers.
    if ($IsReference) {
        $Series.Fill         = $null
        $Series.GeometrySize = 0

        if ($null -ne $Series.Stroke) {
            $DashPattern = [single[]]@(10, 6)

            $Series.Stroke.PathEffect =
                [LiveChartsCore.SkiaSharpView.Painting.Effects.DashEffect]::new(
                    $DashPattern
                )
        }
    }

    Write-Verbose (
        "Created LiveCharts series '$SeriesName' with " +
        "$($Points.Count) points using metric '$Metric'."
    )

    return $Series
}