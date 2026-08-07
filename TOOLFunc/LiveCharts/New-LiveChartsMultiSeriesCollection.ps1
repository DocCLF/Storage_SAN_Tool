function New-LiveChartsMultiSeriesCollection {
    <#
    .SYNOPSIS
        Creates multiple LiveCharts line series for one shared metric.

    .DESCRIPTION
        Creates one line series for every supplied series definition.

        Each definition must contain:

            Name
            History

        Optionally, a definition may contain:

            Color

        All series use the same metric from MetricInfo. The function is 
        independent of the data source and application domain.

        The histories may already contain raw or delta values.

    .PARAMETER SeriesDefinitions
        Collection of definitions describing the histories to display.

        Example:

            @(
                [PSCustomObject]@{
                    Name    = 'Node 1 - Port 1'
                    History = $History1
                }
                [PSCustomObject]@{
                    Name    = 'Node 1 - Port 2'
                    History = $History2
                }
            )

    .PARAMETER MetricInfo
        Metadata of the metric shared by all series.

        The object must contain:

            Metric
            DisplayName

    .PARAMETER MaximumSeries
        Maximum number of comparison series.

        The default is four.

    .OUTPUTS
        System.Collections.Generic.List[LiveChartsCore.ISeries]

    .EXAMPLE
        $SeriesCollection = New-LiveChartsMultiSeriesCollection `
            -SeriesDefinitions $Definitions `
            -MetricInfo $MetricInfo
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$SeriesDefinitions,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $MetricInfo,

        [ValidateRange(1, 10)]
        [int]$MaximumSeries = 4
    )

    if (-not (Initialize-LiveCharts)) {throw 'LiveCharts could not be initialized.'}

    if ($SeriesDefinitions.Count -eq 0) {throw 'No series definitions were supplied.'}

    if ($SeriesDefinitions.Count -gt $MaximumSeries) {
        throw (
            "A maximum of $MaximumSeries comparison series is allowed. " +
            "$($SeriesDefinitions.Count) definitions were supplied."
        )
    }

    foreach ($PropertyName in 'Metric', 'DisplayName') {
        if (-not $MetricInfo.PSObject.Properties[$PropertyName]) {
            throw "MetricInfo property '$PropertyName' is missing."
        }
    }

    $Metric = [string]$MetricInfo.Metric

    if ([string]::IsNullOrWhiteSpace($Metric)) {throw "MetricInfo property 'Metric' is empty."}

    # Default colors for comparison series.
    # If there are more series than colors, the color sequence restarts.
    # A definition can override the color specified by `Color`.
    $DefaultColors = @(
        '#2E86DE'
        '#E67E22'
        '#2ECC71'
        '#9B59B6'
    )

    $SeriesCollection = [System.Collections.Generic.List[LiveChartsCore.ISeries]]::new()

    for (
        $SeriesIndex = 0
        $SeriesIndex -lt $SeriesDefinitions.Count
        $SeriesIndex++
    ) {
        $Definition = $SeriesDefinitions[$SeriesIndex]

        if ($null -eq $Definition) {
            throw "Series definition at index $SeriesIndex is null."
        }

        foreach ($PropertyName in 'Name', 'History') {
            if (-not $Definition.PSObject.Properties[$PropertyName]) {
                throw (
                    "Series definition at index $SeriesIndex does not " +
                    "contain property '$PropertyName'."
                )
            }
        }

        $SeriesName = [string]$Definition.Name
        $History    = @($Definition.History)

        if ([string]::IsNullOrWhiteSpace($SeriesName)) {throw "Series definition at index $SeriesIndex has no name."}

        if ($History.Count -eq 0) {throw "Series '$SeriesName' contains no history entries."}

        $SeriesColor = $DefaultColors[$SeriesIndex % $DefaultColors.Count]

        if ($Definition.PSObject.Properties['Color'] -and -not [string]::IsNullOrWhiteSpace([string]$Definition.Color)) {
            $SeriesColor = [string]$Definition.Color
        }

        $SeriesParameters = @{
            History        = $History
            Metric         = $Metric
            SeriesName     = $SeriesName
            LineSmoothness = 0
            GeometrySize   = 6
            Color          = $SeriesColor

            # Overlapping areas would make the comparison difficult to follow
            #. The comparison view therefore uses only lines.
            ShowArea       = $false
        }

        $Series = New-LiveChartsLineSeries @SeriesParameters

        if ($null -eq $Series) {throw "Series '$SeriesName' could not be created."}

        $SeriesCollection.Add($Series)
    }

    # Return the typed collection as a single object.
    Write-Output -NoEnumerate $SeriesCollection
}