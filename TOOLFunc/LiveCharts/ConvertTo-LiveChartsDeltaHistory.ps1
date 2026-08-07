function ConvertTo-LiveChartsDeltaHistory {
    <#
    .SYNOPSIS
        Converts a cumulative metric history into delta values.

    .DESCRIPTION
        Creates copies of the supplied history objects and replaces the
        selected cumulative metric with the difference from the previous
        measurement.

        The original History collection is not modified.

        Example:

            Raw:
                73, 73, 75, 75, 78

            Delta:
                 0,  0,  2,  0,  3

        If the current value is lower than the previous value,
        a counter reset is assumed. In that case,
        the current value is used as the delta instead of returning a
        negative value.

    .PARAMETER History
        Historical objects containing TimeStamp and the selected metric.

    .PARAMETER Metric
        Name of the cumulative metric property.

    .OUTPUTS
        PSCustomObject[]

    .EXAMPLE
        $DeltaHistory = ConvertTo-LiveChartsDeltaHistory `
            -History $History `
            -Metric 'CRCErr'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$History,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Metric
    )

    if ($History.Count -eq 0) {
        throw 'The History collection does not contain any entries.'
    }

    $SampleItem = $History |
        Where-Object { $null -ne $_ } |
        Select-Object -First 1

    if ($null -eq $SampleItem) {
        throw 'The History collection contains no valid objects.'
    }

    if (-not $SampleItem.PSObject.Properties['TimeStamp']) {
        throw "The history objects do not contain a 'TimeStamp' property."
    }

    if (-not $SampleItem.PSObject.Properties[$Metric]) {
        throw "The history objects do not contain the metric property '$Metric'."
    }

    $PreviousValue = $null

    $DeltaHistory = @(
        foreach ($HistoryItem in ($History | Sort-Object TimeStamp)) {
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
                $CurrentValue = [double]$RawValue
            }
            catch {
                Write-Warning (
                    "Value '$RawValue' of metric '$Metric' could not " +
                    'be converted to Double and was skipped.'
                )

                continue
            }

            if ($null -eq $PreviousValue) {
                # There is no previous measurement available for the first measurement.
                $DeltaValue = [double]0
            }
            elseif ($CurrentValue -ge $PreviousValue) {
                $DeltaValue = $CurrentValue - $PreviousValue
            }
            else {
                # The reading has been reset.
                # Negative delta values would be technically misleading.
                $DeltaValue = $CurrentValue
            }

            # Create an independent copy of the original object.
            $CopiedProperties = [ordered]@{}

            foreach ($Property in $HistoryItem.PSObject.Properties) {
                $CopiedProperties[$Property.Name] = $Property.Value
            }

            # Replace only the selected metric with the delta.
            $CopiedProperties[$Metric] = [double]$DeltaValue

            [PSCustomObject]$CopiedProperties

            $PreviousValue = $CurrentValue
        }
    )

    if ($DeltaHistory.Count -eq 0) {
        throw (
            "No delta history could be created for metric '$Metric'."
        )
    }

    return $DeltaHistory
}