function Update-SANPortErrorHistoryChart {
    <#
    .SYNOPSIS
        Builds the LiveCharts data model for one or multiple Brocade SAN ports.

    .DESCRIPTION
        Loads historical Brocade SAN port-error counters for one or multiple
        switch ports and prepares one or multiple selected metrics.

        Supported combinations:

            1 Source  x 1 Metric
            1 Source  x n Metrics
            n Sources x 1 Metric
            n Sources x n Metrics

        All currently defined SAN port-error metrics belong to UnitGroup
        'Counter' and use ValueMode 'Raw'.
        
        The cumulative database counter values are displayed directly so that
        counter development and explicit counter resets remain visible over time.

        RowID format:

            SerialNumber|VFID|Port

        Example:

            786713E|BASE|0/12

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER RowIDs
        One or multiple SAN port RowIDs.

        RowID remains available as an alias for single-source calls.

    .PARAMETER Metric
        One or multiple SAN port-error metrics.

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
        $ChartData =
            Update-SANPortErrorHistoryChart `
                -CustomerNbr '123456' `
                -RowIDs '786713E|BASE|0/12' `
                -Metric @(
                    'CrcErr'
                    'DiscC3'
                ) `
                -StartTime (Get-Date).AddDays(-1)
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [Alias('RowID')]
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
    # Normalize requested Sources
    # ---------------------------------------------------------------------

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

    if ($RequestedRowIDs.Count -eq 0) {
        throw 'At least one SAN port RowID is required.'
    }

    # Same source limit currently used by the other History viewers.
    if ($RequestedRowIDs.Count -gt 4) {
        throw (
            'A maximum of four SAN ports can currently be displayed ' +
            "together. $($RequestedRowIDs.Count) RowIDs were supplied."
        )
    }

    # ---------------------------------------------------------------------
    # Normalize requested Metrics
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
        throw 'At least one SAN port-error metric is required.'
    }

    # ---------------------------------------------------------------------
    # Generic LiveCharts currently allows:
    #
    #   Single Source + MultiMetric : max. 10 Series
    #   MultiSource + MultiMetric   : max. 12 Series
    #
    # Keep this validation here so the user gets a meaningful SAN-specific
    # error instead of a deeper generic LiveCharts error.
    # ---------------------------------------------------------------------

    if (
        $RequestedRowIDs.Count -eq 1 -and
        $RequestedMetrics.Count -gt 10
    ) {
        throw (
            'A maximum of ten SAN metrics can currently be displayed ' +
            'for one port.'
        )
    }

    $ExpectedSeriesCount =
        $RequestedRowIDs.Count *
        $RequestedMetrics.Count

    if (
        $RequestedRowIDs.Count -gt 1 -and
        $ExpectedSeriesCount -gt 12
    ) {
        throw (
            'The selected SAN ports and metrics would create ' +
            "$ExpectedSeriesCount series. Maximum allowed: 12."
        )
    }

    # ---------------------------------------------------------------------
    # Load and normalize Metric definitions
    #
    # The current SAN MetricInfo intentionally contains only the essential
    # properties. Add the standard LiveCharts defaults here so that the
    # generic chart framework receives a complete definition.
    # ---------------------------------------------------------------------

    $MetricDefinitions = @(
        foreach ($MetricName in $RequestedMetrics) {

            $Definition =
                Get-SANPortErrorLiveChartsMetricInfo `
                    -Metric $MetricName |
                Select-Object -First 1

            if ($null -eq $Definition) {
                throw (
                    "No metric information was found for SAN metric " +
                    "'$MetricName'."
                )
            }

            [PSCustomObject]@{
                Metric =
                    [string]$Definition.Metric

                DisplayName =
                    [string]$Definition.DisplayName

                Unit =
                    if ($Definition.PSObject.Properties['Unit']) {
                        [string]$Definition.Unit
                    }
                    else {
                        ''
                    }

                UnitGroup =
                    if ($Definition.PSObject.Properties['UnitGroup']) {
                        [string]$Definition.UnitGroup
                    }
                    else {
                        'Counter'
                    }

                Precision =
                    if (
                        $Definition.PSObject.Properties['Precision'] -and
                        $null -ne $Definition.Precision
                    ) {
                        [int]$Definition.Precision
                    }
                    else {
                        0
                    }

                ValueMode =
                    if ($Definition.PSObject.Properties['ValueMode']) {
                        [string]$Definition.ValueMode
                    }
                    else {
                        'Raw'
                    }

                ValueDivisor =
                    if (
                        $Definition.PSObject.Properties['ValueDivisor'] -and
                        $null -ne $Definition.ValueDivisor
                    ) {
                        [double]$Definition.ValueDivisor
                    }
                    else {
                        [double]1
                    }

                MinimumPadding =
                    if (
                        $Definition.PSObject.Properties['MinimumPadding'] -and
                        $null -ne $Definition.MinimumPadding
                    ) {
                        [double]$Definition.MinimumPadding
                    }
                    else {
                        [double]1
                    }

                ShowArea =
                    if (
                        $Definition.PSObject.Properties['ShowArea'] -and
                        $null -ne $Definition.ShowArea
                    ) {
                        [bool]$Definition.ShowArea
                    }
                    else {
                        $false
                    }

                Color =
                    if (
                        $Definition.PSObject.Properties['Color'] -and
                        -not [string]::IsNullOrWhiteSpace(
                            [string]$Definition.Color
                        )
                    ) {
                        [string]$Definition.Color
                    }
                    else {
                        $null
                    }

                ReferenceMetric = $null
                ReferenceName   = $null
                ReferenceColor  = $null
            }
        }
    )

    if ($MetricDefinitions.Count -eq 0) {
        throw 'No usable SAN port-error metric definitions were found.'
    }

    # ---------------------------------------------------------------------
    # Validate UnitGroup compatibility
    # ---------------------------------------------------------------------

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
            'Selected SAN port-error metrics must belong to the same ' +
            'UnitGroup.'
        )
    }

    # ---------------------------------------------------------------------
    # Build runtime MetricInfo
    # ---------------------------------------------------------------------

    $IsMultiMetric =
        ($MetricDefinitions.Count -gt 1)

    if ($IsMultiMetric) {

        $FirstMetric =
            $MetricDefinitions[0]

        $MinimumPaddingValues = @(
            $MetricDefinitions |
                ForEach-Object {
                    if ($null -ne $_.MinimumPadding) {
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

        $MetricInfo =
            [PSCustomObject]@{
                Metric          = 'CustomSelection'
                DisplayName     = 'SAN Port Errors'
                Unit            = [string]$FirstMetric.Unit
                UnitGroup       = [string]$FirstMetric.UnitGroup
                Precision       = [int]$FirstMetric.Precision
                ValueMode       = 'MultiMetric'
                ValueDivisor    = [double]1
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

    # ---------------------------------------------------------------------
    # Load known SAN ports once
    #
    # Used for readable series names.
    # ---------------------------------------------------------------------

    $AvailablePorts = @(
        Get-SANPortErrorHistoryPorts `
            -CustomerNbr $CustomerNbr
    )

    # ---------------------------------------------------------------------
    # Prepare result collections
    # ---------------------------------------------------------------------

    $SeriesDefinitions = @()
    $AllChartHistory   = @()
    $MetricValues      = @()

    # ---------------------------------------------------------------------
    # Prepare one History per selected SAN Port
    # ---------------------------------------------------------------------

    foreach ($CurrentRowID in $RequestedRowIDs) {

        # -------------------------------------------------------------
        # Load cumulative raw counters
        # -------------------------------------------------------------

        $RawHistory = @(
            Get-SANPortErrorHistory `
                -CustomerNbr $CustomerNbr `
                -RowID $CurrentRowID `
                -StartTime $StartTime `
                -EndTime $EndTime
        )

        if ($RawHistory.Count -eq 0) {

            Write-Warning (
                "No SAN port-error history was found for RowID " +
                "'$CurrentRowID' in the selected time range."
            )

            continue
        }

        # -------------------------------------------------------------
        # Convert cumulative counters into interval deltas.
        #
        # ConvertTo-LiveChartsDeltaHistory creates a new history object
        # collection and replaces only the requested metric.
        #
        # Therefore multiple selected SAN counters can safely be processed
        # one after another.
        # -------------------------------------------------------------

        # SAN port-error counters are cumulative values.
        #
        # Keep the raw history unchanged so that the complete counter development
        # remains visible, including an explicit counter reset back to zero.
        $CurrentChartHistory = @($RawHistory)

        if ($CurrentChartHistory.Count -eq 0) {

            Write-Warning (
                "No usable SAN chart history could be created for " +
                "RowID '$CurrentRowID'."
            )

            continue
        }

        # -------------------------------------------------------------
        # Collect numeric values from all selected metrics.
        #
        # SAN counters need no additional unit conversion.
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

                    if ([string]::IsNullOrWhiteSpace($MetricName)) {
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
                            "Value '$RawValue' of SAN metric " +
                            "'$MetricName' for RowID '$CurrentRowID' " +
                            'could not be converted to Double and was skipped.'
                        )
                    }
                }
            }
        )

        if ($CurrentMetricValues.Count -eq 0) {
        
            Write-Warning (
                "SAN RowID '$CurrentRowID' contains no usable values " +
                'for the selected metric(s).'
            )
        
            continue
        }

        # -------------------------------------------------------------
        # Resolve readable source name
        #
        # Example:
        #
        #   FC01-RZ1 P12
        #
        # Keep legend entries compact. The complete source name remains
        # available in Get-SANPortErrorHistoryPorts.
        # -------------------------------------------------------------

        $PortInfo =
            $AvailablePorts |
                Where-Object {
                    [string]$_.RowID -eq
                    [string]$CurrentRowID
                } |
                Select-Object -First 1

        if ($null -ne $PortInfo) {

            $DisplayPort =
                [string]$PortInfo.Port

            if ($DisplayPort -match '^\d+/(\d+)$') {
                $DisplayPort =
                    [string]$Matches[1]
            }

            if (
                -not [string]::IsNullOrWhiteSpace(
                    [string]$PortInfo.SwitchName
                )
            ) {

                $SeriesName =
                    '{0} P{1}' -f
                        $PortInfo.SwitchName,
                        $DisplayPort
            }
            else {

                $SeriesName =
                    'Port {0}' -f
                        $DisplayPort
            }
        }
        else {

            $RowIDParts =
                [string]$CurrentRowID -split '\|'

            if ($RowIDParts.Count -ge 3) {

                $DisplayPort =
                    [string]$RowIDParts[2]

                if ($DisplayPort -match '^\d+/(\d+)$') {
                    $DisplayPort =
                        [string]$Matches[1]
                }

                $SeriesName =
                    'Port {0}' -f
                        $DisplayPort
            }
            else {

                $SeriesName =
                    [string]$CurrentRowID
            }
        }

        # -------------------------------------------------------------
        # Add prepared source
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
    # Validate prepared Sources
    # ---------------------------------------------------------------------

    if ($SeriesDefinitions.Count -eq 0) {
        throw (
            'No usable SAN port-error histories were found for the ' +
            'requested Sources.'
        )
    }

    if ($MetricValues.Count -eq 0) {
        throw (
            'The SAN port-error histories contain no usable values for ' +
            'the selected metric(s).'
        )
    }

    # ---------------------------------------------------------------------
    # Determine actual comparison state
    #
    # A requested source without History may have been skipped.
    # ---------------------------------------------------------------------

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

    # ---------------------------------------------------------------------
    # Build generic LiveCharts model
    # ---------------------------------------------------------------------

    # ---------------------------------------------------------------------
    # Build generic LiveCharts model
    # ---------------------------------------------------------------------

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

    # ---------------------------------------------------------------------
    # SAN Counter Y axis
    #
    # Counter values always start at zero.
    # Add some headroom above the highest visible value so that the
    # highest series does not visually stick to the top of the chart.
    # ---------------------------------------------------------------------
            
    if (
        $null -ne $ChartModel.YAxes -and
        @($ChartModel.YAxes).Count -gt 0
    ) {
    
        $CounterYAxis =
            @($ChartModel.YAxes)[0]
    
        if ($null -ne $CounterYAxis) {
        
            # Counter values cannot be meaningfully negative.
            $CounterYAxis.MinLimit =
                [double]0
        
            $CounterYAxis.MinStep =
                [double]1
        
            # Highest currently displayed counter value.
            $MaximumCounterValue =
                (
                    $MetricValues |
                        Measure-Object -Maximum
                ).Maximum
        
            if ($null -ne $MaximumCounterValue) {
            
                $MaximumCounterValue =
                    [double]$MaximumCounterValue
            
                if ($MaximumCounterValue -gt 0) {
                
                    # Add 10 % vertical headroom.
                    $UpperPadding =
                        $MaximumCounterValue * 0.10
                
                    # Do not allow an extremely small padding for small
                    # counter values.
                    if ($UpperPadding -lt 1) {
                        $UpperPadding = 1
                    }
                
                    $CounterYAxis.MaxLimit =
                        $MaximumCounterValue +
                        $UpperPadding
                }
                else {
                
                    # All counter values are currently zero.
                    $CounterYAxis.MaxLimit =
                        [double]1
                }
            }
        }
    }

    return $ChartModel
}