function Update-StoragePoolCapacityChart {
    <#
    .SYNOPSIS
        Builds the LiveCharts data model for one or multiple IBM Storage pools.

    .DESCRIPTION
        Loads historical Storage pool capacity data for one or multiple pools
        and prepares one or multiple selected metrics.

        Supported combinations:

            1 Pool  x 1 Metric
            1 Pool  x n Metrics
            n Pools x 1 Metric
            n Pools x n Metrics

        Multiple selected metrics must belong to the same UnitGroup.

        Capacity values are stored in SQLite as bytes and are converted
        into the display unit configured by the metric definitions.

        The legacy CapacityOverview metric remains supported as a preset.

        The function contains only Storage-pool-specific orchestration.
        Series, axes, statistics and the final chart model are created by
        the generic LiveCharts framework.

    .PARAMETER CustomerNbr
        Customer number used to locate the SQLite database.

    .PARAMETER RowID
        Stable identifier of one Storage pool:

            SerialNumber|PoolID

    .PARAMETER RowIDs
        Stable identifiers of multiple Storage pools.

        A maximum of four pools can currently be compared.

    .PARAMETER Metric
        One or multiple Storage pool metrics.

        Supported individual metrics include:

            Capacity
            FreeCapacity
            UsedCapacity
            VirtualCapacity
            RealCapacity
            Overallocation

        CapacityOverview remains supported as a legacy MultiMetric preset.

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
    #>

    [CmdletBinding(DefaultParameterSetName = 'Single')]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Single'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$RowID,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Comparison'
        )]
        [ValidateNotNull()]
        [string[]]$RowIDs,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string[]]$Metric,

        [datetime]$StartTime = (Get-Date).AddDays(-30),

        [datetime]$EndTime = (Get-Date),

        [ValidateNotNullOrEmpty()]
        [string]$DateTimeLabelFormat = 'dd.MM. HH:mm',

        [TimeSpan]$DateTimeStep = ([TimeSpan]::FromHours(1))
    )

    # ---------------------------------------------------------------------
    # Initialize LiveCharts
    # ---------------------------------------------------------------------

    if (-not (Initialize-LiveCharts)) {
        throw 'LiveCharts could not be initialized.'
    }

    # ---------------------------------------------------------------------
    # Validate time range
    # ---------------------------------------------------------------------

    if ($StartTime -gt $EndTime) {
        throw 'StartTime must not be later than EndTime.'
    }

    if ($DateTimeStep -le [TimeSpan]::Zero) {
        throw 'DateTimeStep must be greater than zero.'
    }

    # ---------------------------------------------------------------------
    # Normalize requested pool IDs
    # ---------------------------------------------------------------------

    if ($PSCmdlet.ParameterSetName -eq 'Single') {

        $RequestedRowIDs = @(
            [string]$RowID
        )
    }
    else {

        $RequestedRowIDs = @(
            $RowIDs |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$_
                    )
                } |
                ForEach-Object {
                    [string]$_
                } |
                Select-Object -Unique
        )
    }

    if ($RequestedRowIDs.Count -eq 0) {
        throw 'At least one valid Storage pool RowID is required.'
    }

    if ($RequestedRowIDs.Count -gt 4) {
        throw (
            'A maximum of four Storage pools can currently be ' +
            "displayed together. $($RequestedRowIDs.Count) RowIDs " +
            'were supplied.'
        )
    }

    $PrimaryRowID =
        [string]$RequestedRowIDs[0]

    # ---------------------------------------------------------------------
    # Normalize requested metrics
    # ---------------------------------------------------------------------

    $RequestedMetrics = @(
        $Metric |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace(
                    [string]$_
                )
            } |
            ForEach-Object {
                [string]$_
            } |
            Select-Object -Unique
    )

    if ($RequestedMetrics.Count -eq 0) {
        throw 'At least one Storage pool metric is required.'
    }

    # ---------------------------------------------------------------------
    # Legacy CapacityOverview handling
    #
    # CapacityOverview already contains a predefined MultiMetric bundle.
    # Mixing it with normal metrics would duplicate definitions and is
    # therefore intentionally rejected.
    # ---------------------------------------------------------------------

    $UsesCapacityOverview =
        ($RequestedMetrics -contains 'CapacityOverview')

    if (
        $UsesCapacityOverview -and
        $RequestedMetrics.Count -gt 1
    ) {
        throw (
            "'CapacityOverview' cannot be combined with additional " +
            'Storage pool metrics.'
        )
    }

    # ---------------------------------------------------------------------
    # Build MetricInfo
    # ---------------------------------------------------------------------

    if ($UsesCapacityOverview) {

        $MetricInfo =
            Get-StoragePoolLiveChartsMetricInfo `
                -Metric 'CapacityOverview'

        $MetricDefinitions = @(
            foreach ($OverviewMetric in @($MetricInfo.Metrics)) {

                $MetricName =
                    [string]$OverviewMetric.Metric

                if (
                    [string]::IsNullOrWhiteSpace(
                        $MetricName
                    )
                ) {
                    continue
                }

                # Load the complete single metric definition so that
                # UnitGroup, divisor, precision etc. are available.
                Get-StoragePoolLiveChartsMetricInfo `
                    -Metric $MetricName
            }
        )
    }
    else {

        $MetricDefinitions = @(
            foreach ($MetricName in $RequestedMetrics) {

                Get-StoragePoolLiveChartsMetricInfo `
                    -Metric $MetricName
            }
        )

        if ($MetricDefinitions.Count -eq 0) {
            throw (
                'No usable Storage pool metric definitions were found.'
            )
        }

        # -------------------------------------------------------------
        # Validate UnitGroup compatibility
        # -------------------------------------------------------------

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
                'Selected Storage pool metrics must belong to the ' +
                'same UnitGroup.'
            )
        }

        # -------------------------------------------------------------
        # Single metric
        # -------------------------------------------------------------

        if ($MetricDefinitions.Count -eq 1) {

            $MetricInfo =
                $MetricDefinitions[0]
        }

        # -------------------------------------------------------------
        # Multi metric
        # -------------------------------------------------------------

        else {

            $FirstMetric =
                $MetricDefinitions[0]

            $MinimumPaddingValues = @(
                $MetricDefinitions |
                    ForEach-Object {

                        if (
                            $_.PSObject.Properties[
                                'MinimumPadding'
                            ] -and
                            $null -ne $_.MinimumPadding
                        ) {
                            [double]$_.MinimumPadding
                        }
                    }
            )

            if ($MinimumPaddingValues.Count -gt 0) {

                $MinimumPadding = (
                    $MinimumPaddingValues |
                        Measure-Object -Maximum
                ).Maximum
            }
            else {

                $MinimumPadding =
                    [double]1
            }

            $MetricInfo = [PSCustomObject]@{
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
    }

    if ($null -eq $MetricInfo) {
        throw 'No usable Storage pool MetricInfo could be created.'
    }

    # ---------------------------------------------------------------------
    # Load pools for readable series names
    # ---------------------------------------------------------------------

    $AvailablePools = @(
        Get-StoragePoolHistoryPools `
            -CustomerNbr $CustomerNbr
    )

    # ---------------------------------------------------------------------
    # Prepare collections
    # ---------------------------------------------------------------------

    $SeriesDefinitions = @()
    $AllChartHistory   = @()
    $MetricValues      = @()

    # ---------------------------------------------------------------------
    # Load and prepare history for every requested pool
    # ---------------------------------------------------------------------

    foreach ($CurrentRowID in $RequestedRowIDs) {

        # -------------------------------------------------------------
        # Load raw history
        # -------------------------------------------------------------

        $RawHistory = @(
            Get-StoragePoolCapacityHistory `
                -CustomerNbr $CustomerNbr `
                -RowID $CurrentRowID `
                -StartTime $StartTime `
                -EndTime $EndTime
        )

        if ($RawHistory.Count -eq 0) {

            Write-Warning (
                "No Storage pool capacity history was found for " +
                "RowID '$CurrentRowID' in the selected time range."
            )

            continue
        }

        # -------------------------------------------------------------
        # Convert database values into chart-ready display values
        #
        # Example:
        #
        #   Bytes -> TB
        #
        # MultiMetric mode automatically converts all definitions
        # contained in MetricInfo.Metrics.
        # -------------------------------------------------------------

        $CurrentChartHistory = @(
            ConvertTo-LiveChartsDisplayHistory `
                -History $RawHistory `
                -MetricInfo $MetricInfo
        )

        if ($CurrentChartHistory.Count -eq 0) {

            Write-Warning (
                "No usable chart history could be created for " +
                "Storage pool RowID '$CurrentRowID'."
            )

            continue
        }

        # -------------------------------------------------------------
        # Extract numeric values for all selected metrics
        # -------------------------------------------------------------

        $CurrentMetricValues = @(
            foreach ($HistoryItem in $CurrentChartHistory) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                foreach ($Definition in $MetricDefinitions) {

                    if ($null -eq $Definition) {
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
                            "for Storage pool RowID '$CurrentRowID' " +
                            'could not be converted to Double and ' +
                            'was skipped.'
                        )
                    }
                }
            }
        )

        if ($CurrentMetricValues.Count -eq 0) {

            Write-Warning (
                "Storage pool RowID '$CurrentRowID' contains no " +
                'usable values for the selected metric(s).'
            )

            continue
        }

        # -------------------------------------------------------------
        # Create readable series name
        # -------------------------------------------------------------

        $PoolInfo =
            $AvailablePools |
                Where-Object {
                    [string]$_.RowID -eq
                    [string]$CurrentRowID
                } |
                Select-Object -First 1

        if ($null -ne $PoolInfo) {

            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$PoolInfo.PoolName
                )
            ) {

                $SeriesName =
                    '{0} – {1}' -f
                        $PoolInfo.SerialNumber,
                        $PoolInfo.PoolName
            }
            else {

                $SeriesName =
                    '{0} – Pool {1}' -f
                        $PoolInfo.SerialNumber,
                        $PoolInfo.PoolID
            }
        }
        else {

            $SeriesName =
                [string]$CurrentRowID
        }

        # -------------------------------------------------------------
        # Add prepared Source
        # -------------------------------------------------------------

        $SeriesDefinitions +=
            [PSCustomObject]@{
                RowID   = [string]$CurrentRowID
                Name    = $SeriesName
                History = $CurrentChartHistory
            }

        $AllChartHistory +=
            $CurrentChartHistory

        $MetricValues +=
            $CurrentMetricValues
    }

    # ---------------------------------------------------------------------
    # Validate usable histories
    # ---------------------------------------------------------------------

    if ($SeriesDefinitions.Count -eq 0) {
        throw (
            'No usable Storage pool histories were found for the ' +
            'requested sources.'
        )
    }

    if ($MetricValues.Count -eq 0) {
        throw (
            'The Storage pool histories contain no usable values for ' +
            'the selected metric(s).'
        )
    }

    # ---------------------------------------------------------------------
    # Determine actual comparison state
    #
    # A requested source without history may have been skipped.
    # ---------------------------------------------------------------------

    $IsComparison =
        ($SeriesDefinitions.Count -gt 1)

    $UsableRowIDs = @(
        $SeriesDefinitions |
            ForEach-Object {
                [string]$_.RowID
            }
    )

    $PrimaryRowID =
        [string]$SeriesDefinitions[0].RowID

    # ---------------------------------------------------------------------
    # Hand prepared histories to the generic LiveCharts framework
    # ---------------------------------------------------------------------

    return New-LiveChartsHistoryChartModel `
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
}