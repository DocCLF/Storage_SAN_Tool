function New-LiveChartsStatistics {
    <#
    .SYNOPSIS
        Creates statistical summary values for a LiveCharts metric history.

    .DESCRIPTION
        Calculates the current, minimum, maximum and average value for one
        metric based on historical PowerShell objects.

        The function is independent of the data source and application domain.

    .PARAMETER History
        Historical objects containing a TimeStamp property and the selected
        metric property.

    .PARAMETER Metric
        Name of the property whose values should be analyzed.

    .PARAMETER Values
        Optional prevalidated numeric values.

        If supplied, these values are used for minimum, maximum, average and
        point count. This avoids converting the same values twice.

    .OUTPUTS
        PSCustomObject containing:

            CurrentValue
            MinimumValue
            MaximumValue
            AverageValue
            PointCount

    .EXAMPLE
        $Statistics = New-LiveChartsStatistics `
            -History $History `
            -Metric 'SFPTemp' `
            -Values $MetricValues
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$History,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Metric,

        [Parameter()]
        [double[]]$Values
    )

    if ($History.Count -eq 0) {
        throw 'The History collection does not contain any entries.'
    }

    # If no previously verified values have been provided,
    # they are generated from the history.
    if ($null -eq $Values -or $Values.Count -eq 0) {
        $Values = @(
            foreach ($HistoryItem in $History) {
                if ($null -eq $HistoryItem) {
                    continue
                }

                $MetricProperty =
                    $HistoryItem.PSObject.Properties[$Metric]

                if ($null -eq $MetricProperty) {
                    continue
                }

                $RawValue = $MetricProperty.Value

                if (
                    $null -eq $RawValue -or
                    $RawValue -is [DBNull] -or
                    [string]::IsNullOrWhiteSpace([string]$RawValue)
                ) {
                    continue
                }

                try {
                    [double]$RawValue
                }
                catch {
                    Write-Warning (
                        "Value '$RawValue' of metric '$Metric' could not " +
                        'be converted to Double and was skipped.'
                    )
                }
            }
        )
    }

    if ($Values.Count -eq 0) {
        throw "No usable values were found for metric '$Metric'."
    }

    $Measurement = $Values |
        Measure-Object -Minimum -Maximum -Average

    # The most recent value is determined based on the timestamp,
    # not on the original order of the collection.
    $LastHistoryItem = $History |
        Where-Object { $null -ne $_ } |
        Sort-Object TimeStamp |
        Select-Object -Last 1

    $CurrentValue = $null

    if ($null -ne $LastHistoryItem) {
        $CurrentProperty =
            $LastHistoryItem.PSObject.Properties[$Metric]

        if (
            $null -ne $CurrentProperty -and
            $null -ne $CurrentProperty.Value -and
            $CurrentProperty.Value -isnot [DBNull] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$CurrentProperty.Value
            )
        ) {
            try {
                $CurrentValue = [double]$CurrentProperty.Value
            }
            catch {
                $CurrentValue = $null
            }
        }
    }

    [PSCustomObject]@{
        CurrentValue = $CurrentValue
        MinimumValue = [double]$Measurement.Minimum
        MaximumValue = [double]$Measurement.Maximum
        AverageValue = [double]$Measurement.Average
        PointCount   = [int]$Values.Count
    }
}