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
                null, 0, 2, 0, 3

        The first measurement has no previous measurement and therefore
        receives no delta value.

        If the current value is lower than the previous value, a counter
        reset is assumed. In that case the delta is set to null because
        the actual increase since the previous measurement cannot be
        determined reliably.

    .PARAMETER History
        Historical objects containing TimeStamp and the selected metric.

    .PARAMETER Metric
        Name of the cumulative metric property.

    .OUTPUTS
        PSCustomObject[]

    .EXAMPLE
        $DeltaHistory =
            ConvertTo-LiveChartsDeltaHistory `
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

    $SampleItem =
        $History |
            Where-Object {
                $null -ne $_
            } |
            Select-Object -First 1

    if ($null -eq $SampleItem) {
        throw 'The History collection contains no valid objects.'
    }

    if (-not $SampleItem.PSObject.Properties['TimeStamp']) {
        throw "The history objects do not contain a 'TimeStamp' property."
    }

    if (-not $SampleItem.PSObject.Properties[$Metric]) {
        throw (
            "The history objects do not contain the metric property " +
            "'$Metric'."
        )
    }

    $PreviousValue =
        $null

    $DeltaHistory = @(
        foreach (
            $HistoryItem in (
                $History |
                    Sort-Object TimeStamp
            )
        ) {

            if ($null -eq $HistoryItem) {
                continue
            }

            $MetricProperty =
                $HistoryItem.PSObject.Properties[
                    $Metric
                ]

            if ($null -eq $MetricProperty) {
                continue
            }

            $RawValue =
                $MetricProperty.Value

            # ---------------------------------------------------------
            # Create an independent copy first.
            #
            # This is important because even if the selected metric is
            # null or invalid, the original time point may still be
            # required by other metrics in MultiMetric mode.
            # ---------------------------------------------------------

            $CopiedProperties =
                [ordered]@{}

            foreach (
                $Property in
                $HistoryItem.PSObject.Properties
            ) {

                $CopiedProperties[
                    $Property.Name
                ] =
                    $Property.Value
            }

            # ---------------------------------------------------------
            # Missing current value
            # ---------------------------------------------------------

            if (
                $null -eq $RawValue -or
                $RawValue -is [DBNull] -or
                [string]::IsNullOrWhiteSpace(
                    [string]$RawValue
                )
            ) {

                $CopiedProperties[$Metric] =
                    $null

                [PSCustomObject]$CopiedProperties

                continue
            }

            # ---------------------------------------------------------
            # Convert cumulative counter value
            # ---------------------------------------------------------

            try {

                $CurrentValue =
                    [double]$RawValue
            }
            catch {

                Write-Warning (
                    "Value '$RawValue' of metric '$Metric' could not " +
                    'be converted to Double. The delta was set to null.'
                )

                $CopiedProperties[$Metric] =
                    $null

                [PSCustomObject]$CopiedProperties

                continue
            }

            # ---------------------------------------------------------
            # Calculate delta
            # ---------------------------------------------------------

            if ($null -eq $PreviousValue) {

                # No previous measurement exists.
                #
                # The current cumulative value must not be interpreted
                # as events that occurred in the current interval.
                $DeltaValue =
                    $null
            }
            elseif ($CurrentValue -ge $PreviousValue) {

                $DeltaValue =
                    $CurrentValue -
                    $PreviousValue
            }
            else {

                # Counter decreased.
                #
                # This normally indicates a counter reset, switch restart
                # or similar event. The actual interval delta cannot be
                # determined reliably.
                $DeltaValue =
                    $null
            }

            # ---------------------------------------------------------
            # Replace only the selected metric
            # ---------------------------------------------------------

            if ($null -eq $DeltaValue) {

                $CopiedProperties[$Metric] =
                    $null
            }
            else {

                $CopiedProperties[$Metric] =
                    [double]$DeltaValue
            }

            [PSCustomObject]$CopiedProperties

            # Current cumulative value becomes the reference for the next
            # measurement, even after a reset.
            $PreviousValue =
                $CurrentValue
        }
    )

    if ($DeltaHistory.Count -eq 0) {
        throw (
            "No delta history could be created for metric '$Metric'."
        )
    }

    return $DeltaHistory
}