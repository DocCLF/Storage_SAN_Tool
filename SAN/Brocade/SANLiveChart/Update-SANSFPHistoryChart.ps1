function Update-SANSFPHistoryChart {
    <#
    .SYNOPSIS
        Builds the LiveCharts model for SAN SFP history.

    .DESCRIPTION
        Loads historical SAN SFP values for one or multiple ports and
        one or multiple compatible metrics.

        Supported metrics are provided by
        Get-SANSFPLiveChartsMetricInfo.

        Multiple metrics may only be displayed together when they belong
        to the same UnitGroup.

        Example:

            RxPower + TxPower
                -> allowed

            Temperature + RxPower
                -> not allowed

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER RowIDs
        One or multiple stable SAN SFP port RowIDs.

    .PARAMETER Metric
        One or multiple SAN SFP metrics.

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range.

    .PARAMETER DateTimeLabelFormat
        Format used for X-axis labels.

    .PARAMETER DateTimeStep
        Minimum distance between X-axis labels.

    .OUTPUTS
        PSCustomObject created by New-LiveChartsHistoryChartModel.

    .EXAMPLE
        Update-SANSFPHistoryChart `
            -CustomerNbr '349872' `
            -RowIDs '786713E|BASE|0/0' `
            -Metric @(
                'RxPower'
                'TxPower'
            ) `
            -StartTime (Get-Date).AddDays(-1)
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$RowIDs,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$Metric,

        [datetime]$StartTime =
            (Get-Date).AddDays(-30),

        [datetime]$EndTime =
            (Get-Date),

        [ValidateNotNullOrEmpty()]
        [string]$DateTimeLabelFormat =
            'dd.MM. HH:mm',

        [TimeSpan]$DateTimeStep =
            ([TimeSpan]::FromHours(1))
    )

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    if ($StartTime -gt $EndTime) {
        throw 'StartTime must not be later than EndTime.'
    }

    if ($DateTimeStep -le [TimeSpan]::Zero) {
        throw 'DateTimeStep must be greater than zero.'
    }

    # -----------------------------------------------------------------
    # Normalize RowIDs
    # -----------------------------------------------------------------

    $RequestedRowIDs = @(
        $RowIDs |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace(
                    [string]$_
                )
            } |
            Select-Object -Unique
    )

    if ($RequestedRowIDs.Count -eq 0) {
        throw 'At least one SAN SFP RowID is required.'
    }

    # -----------------------------------------------------------------
    # Normalize metrics
    # -----------------------------------------------------------------

    $RequestedMetrics = @(
        $Metric |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace(
                    [string]$_
                )
            } |
            Select-Object -Unique
    )

    if ($RequestedMetrics.Count -eq 0) {
        throw 'At least one SAN SFP metric is required.'
    }

    # -----------------------------------------------------------------
    # Load metric definitions
    # -----------------------------------------------------------------

    $MetricDefinitions = @(
        foreach ($MetricName in $RequestedMetrics) {

            Get-SANSFPLiveChartsMetricInfo `
                -Metric $MetricName
        }
    )

    if ($MetricDefinitions.Count -eq 0) {
        throw 'No usable SAN SFP metric definitions were found.'
    }

    # -----------------------------------------------------------------
    # Validate UnitGroup compatibility
    # -----------------------------------------------------------------

    $UnitGroups = @(
        $MetricDefinitions |
            ForEach-Object {
                [string]$_.UnitGroup
            } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Select-Object -Unique
    )

    if ($UnitGroups.Count -gt 1) {
        throw (
            'Selected SAN SFP metrics must belong to the same UnitGroup.'
        )
    }

    # -----------------------------------------------------------------
    # Build runtime MetricInfo
    # -----------------------------------------------------------------

    $IsMultiMetric =
        ($MetricDefinitions.Count -gt 1)

    if ($IsMultiMetric) {

        $FirstMetric =
            $MetricDefinitions[0]

        $MinimumPadding = @(
            $MetricDefinitions |
                ForEach-Object {
                    if ($null -ne $_.MinimumPadding) {
                        [double]$_.MinimumPadding
                    }
                }
        ) |
            Measure-Object -Maximum |
            Select-Object -ExpandProperty Maximum

        if ($null -eq $MinimumPadding) {
            $MinimumPadding = 1
        }

        $MetricInfo =
            [PSCustomObject]@{
                Metric          = 'CustomSelection'
                DisplayName     = [string]$FirstMetric.UnitGroup
                Unit            = [string]$FirstMetric.Unit
                UnitGroup       = [string]$FirstMetric.UnitGroup
                Precision       = [int]$FirstMetric.Precision
                ValueMode       = 'MultiMetric'
                ValueDivisor    = [double]$FirstMetric.ValueDivisor
                MinimumPadding  = [double]$MinimumPadding
                ShowArea        = $false

                Metrics = @(
                    $MetricDefinitions
                )

                ReferenceMetric = $null
                ReferenceName   = $null
                ReferenceColor  = $null
            }
    }
    else {

        $MetricInfo =
            $MetricDefinitions[0]
    }

    # -----------------------------------------------------------------
    # Available ports
    # -----------------------------------------------------------------

    $AvailablePorts = @(
        Get-SANSFPHistoryPorts `
            -CustomerNbr $CustomerNbr
    )

    # -----------------------------------------------------------------
    # Build prepared histories per selected port
    # -----------------------------------------------------------------

    $SeriesDefinitions =
        [System.Collections.Generic.List[object]]::new()

    $AllChartHistory =
        [System.Collections.Generic.List[object]]::new()

    $MetricValues =
        [System.Collections.Generic.List[double]]::new()

    foreach ($CurrentRowID in $RequestedRowIDs) {

        $RawHistory = @(
            Get-SANSFPHistory `
                -CustomerNbr $CustomerNbr `
                -RowID $CurrentRowID `
                -StartTime $StartTime `
                -EndTime $EndTime
        )

        if ($RawHistory.Count -eq 0) {

            Write-Warning (
                "SAN SFP RowID '$CurrentRowID' contains no history " +
                'in the selected time range.'
            )

            continue
        }

        # -------------------------------------------------------------
        # Raw history is already chart-ready.
        # -------------------------------------------------------------

        $CurrentChartHistory =
            @($RawHistory)

        # -------------------------------------------------------------
        # Extract usable numeric values
        # -------------------------------------------------------------

        $CurrentMetricValues = @(
            foreach ($HistoryItem in $CurrentChartHistory) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                foreach ($Definition in $MetricDefinitions) {

                    $MetricName =
                        [string]$Definition.Metric

                    $MetricProperty =
                        $HistoryItem.PSObject.Properties[
                            $MetricName
                        ]

                    if ($null -eq $MetricProperty) {
                        continue
                    }

                    $RawValue =
                        $MetricProperty.Value

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
                            "Value '$RawValue' of metric '$MetricName' " +
                            "for SAN SFP RowID '$CurrentRowID' could " +
                            'not be converted to Double.'
                        )
                    }
                }
            }
        )

        if ($CurrentMetricValues.Count -eq 0) {

            Write-Warning (
                "SAN SFP RowID '$CurrentRowID' contains no usable " +
                'values for the selected metric(s).'
            )

            continue
        }

        # -------------------------------------------------------------
        # Resolve readable port information
        # -------------------------------------------------------------

        $PortInfo =
            $AvailablePorts |
                Where-Object {
                    [string]$_.RowID -eq
                    [string]$CurrentRowID
                } |
                Select-Object -First 1

        if ($null -ne $PortInfo) {

            $SeriesName =
                '{0} P{1}' -f
                    $PortInfo.SwitchName,
                    $PortInfo.PortDisplay
        }
        else {

            $SeriesName =
                [string]$CurrentRowID
        }

        # -------------------------------------------------------------
        # Series definition
        # -------------------------------------------------------------

        $SeriesDefinitions.Add(
            [PSCustomObject]@{
                RowID       = [string]$CurrentRowID
                Name        = $SeriesName
                DisplayName = $SeriesName
                History     = $CurrentChartHistory
            }
        )

        # -------------------------------------------------------------
        # Collect complete history
        # -------------------------------------------------------------

        foreach ($HistoryItem in $CurrentChartHistory) {
            $AllChartHistory.Add($HistoryItem)
        }

        # -------------------------------------------------------------
        # Collect metric values for scaling/statistics
        # -------------------------------------------------------------

        foreach ($Value in $CurrentMetricValues) {
            $MetricValues.Add(
                [double]$Value
            )
        }
    }

    if ($SeriesDefinitions.Count -eq 0) {
        throw (
            'No usable SAN SFP histories were found for the ' +
            'requested Sources.'
        )
    }

    if ($MetricValues.Count -eq 0) {
        throw (
            'The SAN SFP histories contain no usable values for ' +
            'the selected metric(s).'
        )
    }

    # -----------------------------------------------------------------
    # Determine comparison mode
    # -----------------------------------------------------------------

    $IsComparison =
        ($SeriesDefinitions.Count -gt 1)

    $PrimaryRowID =
        [string]$SeriesDefinitions[0].RowID

    $UsableRowIDs = @(
        $SeriesDefinitions |
            ForEach-Object {
                [string]$_.RowID
            }
    )

    # -----------------------------------------------------------------
    # Build generic LiveCharts model
    # -----------------------------------------------------------------

    $ChartModel =
        New-LiveChartsHistoryChartModel `
            -SeriesDefinitions $SeriesDefinitions `
            -AllChartHistory $AllChartHistory `
            -MetricValues $MetricValues `
            -MetricInfo $MetricInfo `
            -CustomerNbr $CustomerNbr `
            -RowID $PrimaryRowID `
            -RowIDs $UsableRowIDs `
            -Metric ([string]$MetricInfo.Metric) `
            -StartTime $StartTime `
            -EndTime $EndTime `
            -DateTimeLabelFormat $DateTimeLabelFormat `
            -DateTimeStep $DateTimeStep `
            -IsComparison $IsComparison

    return $ChartModel
}