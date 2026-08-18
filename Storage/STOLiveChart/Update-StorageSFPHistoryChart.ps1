function Update-StorageSFPHistoryChart {
    <#
    .SYNOPSIS
        Builds the LiveCharts data model for one or multiple Storage FC ports.

    .DESCRIPTION
        Loads historical SFP / FC-port data for one or multiple ports and
        prepares one or multiple selected metrics.

        Supported combinations:

            1 Source  x 1 Metric
            1 Source  x n Metrics
            n Sources x 1 Metric
            n Sources x n Metrics

        All selected metrics must belong to the same UnitGroup.

        Counter metrics may use a separate SourceMetric.

        Example:

            ZeroBtB
                SourceMetric = ZeroBtB
                ValueMode    = Raw

            ZeroBtBDelta
                SourceMetric = ZeroBtB
                ValueMode    = Delta

        This makes it possible to display both the cumulative counter and
        the increase between measurements at the same time.

        Delta calculation is performed in this function before display
        conversion. ConvertTo-LiveChartsDisplayHistory therefore receives
        temporary metric definitions with ValueMode 'Raw' so that calculated
        Delta values are not converted a second time.

    .PARAMETER Request
        Optional request object created by New-StorageSFPHistoryRequest.

        Existing single-metric requests remain supported.

    .PARAMETER CustomerNbr
        Customer number used to locate the SQLite database.

    .PARAMETER RowIDs
        One or multiple stable FC-port identifiers:

            SerialNumber|WWNN|WWPN

        The alias RowID remains available for existing callers.

    .PARAMETER Metric
        One or multiple SFP metrics.

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range.

    .PARAMETER DateTimeLabelFormat
        Format used for labels on the X axis.

    .PARAMETER DateTimeStep
        Minimum distance between labels on the X axis.

    .OUTPUTS
        PSCustomObject created by New-LiveChartsHistoryChartModel.
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByParameters')]
    param (
        [Parameter(
            Mandatory,
            ParameterSetName = 'ByRequest'
        )]
        [ValidateNotNull()]
        [object]$Request,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ByParameters'
        )]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ByParameters'
        )]
        [Alias('RowID')]
        [ValidateNotNull()]
        [string[]]$RowIDs,

        [Parameter(
            Mandatory,
            ParameterSetName = 'ByParameters'
        )]
        [ValidateNotNull()]
        [string[]]$Metric,

        [Parameter(ParameterSetName = 'ByParameters')]
        [datetime]$StartTime = (Get-Date).AddDays(-30),

        [Parameter(ParameterSetName = 'ByParameters')]
        [datetime]$EndTime = (Get-Date),

        [Parameter(ParameterSetName = 'ByParameters')]
        [ValidateNotNullOrEmpty()]
        [string]$DateTimeLabelFormat = 'dd.MM. HH:mm',

        [Parameter(ParameterSetName = 'ByParameters')]
        [TimeSpan]$DateTimeStep = ([TimeSpan]::FromHours(1))
    )

    # ---------------------------------------------------------------------
    # Normalize request
    # ---------------------------------------------------------------------

    if ($PSCmdlet.ParameterSetName -eq 'ByRequest') {

        $RequiredProperties = @(
            'CustomerNbr'
            'Metric'
            'StartTime'
            'EndTime'
            'DateTimeLabelFormat'
            'DateTimeStep'
        )

        foreach ($PropertyName in $RequiredProperties) {

            if (-not $Request.PSObject.Properties[$PropertyName]) {
                throw "Request property '$PropertyName' is missing."
            }
        }

        $CustomerNbr =
            [string]$Request.CustomerNbr

        $Metric = @(
            $Request.Metric |
                Where-Object {
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$_
                    )
                } |
                ForEach-Object {
                    [string]$_
                }
        )

        $StartTime =
            [datetime]$Request.StartTime

        $EndTime =
            [datetime]$Request.EndTime

        $DateTimeLabelFormat =
            [string]$Request.DateTimeLabelFormat

        $DateTimeStep =
            [TimeSpan]$Request.DateTimeStep

        # -------------------------------------------------------------
        # New requests may contain RowIDs.
        # Existing requests using RowID remain supported.
        # -------------------------------------------------------------

        if (
            $Request.PSObject.Properties['RowIDs'] -and
            $null -ne $Request.RowIDs
        ) {
            $RowIDs = @(
                $Request.RowIDs |
                    Where-Object {
                        -not [string]::IsNullOrWhiteSpace(
                            [string]$_
                        )
                    } |
                    ForEach-Object {
                        [string]$_
                    }
            )
        }
        elseif (
            $Request.PSObject.Properties['RowID'] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$Request.RowID
            )
        ) {
            $RowIDs = @(
                [string]$Request.RowID
            )
        }
        else {
            throw "Request property 'RowID' or 'RowIDs' is missing."
        }
    }

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
    # Normalize requested RowIDs
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
        throw 'At least one Storage FC-port RowID is required.'
    }

    # 4 Sources x 3 Metrics = 12 Series.
    if ($RequestedRowIDs.Count -gt 4) {
        throw (
            'A maximum of four Storage FC ports can currently be ' +
            "displayed together. $($RequestedRowIDs.Count) RowIDs " +
            'were supplied.'
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
        throw 'At least one Storage SFP metric is required.'
    }

    # ---------------------------------------------------------------------
    # Load original Metric definitions
    #
    # IMPORTANT:
    # These definitions retain their real ValueMode.
    # ---------------------------------------------------------------------

    $MetricDefinitions = @(
        foreach ($MetricName in $RequestedMetrics) {

            Get-StorageLiveChartsMetricInfo `
                -Metric $MetricName
        }
    )

    if ($MetricDefinitions.Count -eq 0) {
        throw 'No usable Storage SFP metric definitions were found.'
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
            'Selected Storage SFP metrics must belong to the same ' +
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

                    if (
                        $_.PSObject.Properties['MinimumPadding'] -and
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
    else {

        $MetricInfo =
            $MetricDefinitions[0]
    }

    # ---------------------------------------------------------------------
    # Build DISPLAY metric definitions
    #
    # Delta calculation is already performed below.
    #
    # ConvertTo-LiveChartsDisplayHistory must therefore only perform
    # display conversion such as ValueDivisor handling.
    #
    # It must NOT calculate Delta a second time.
    # ---------------------------------------------------------------------

    $DisplayMetricDefinitions = @(
        foreach ($Definition in $MetricDefinitions) {

            $CopiedDefinition =
                [ordered]@{}

            foreach ($Property in $Definition.PSObject.Properties) {

                $CopiedDefinition[
                    $Property.Name
                ] =
                    $Property.Value
            }

            # Prevent a second Delta conversion.
            $CopiedDefinition['ValueMode'] =
                'Raw'

            [PSCustomObject]$CopiedDefinition
        }
    )

    # ---------------------------------------------------------------------
    # Build display-only MetricInfo
    # ---------------------------------------------------------------------

    if ($IsMultiMetric) {

        $DisplayMetricInfoProperties =
            [ordered]@{}

        foreach ($Property in $MetricInfo.PSObject.Properties) {

            $DisplayMetricInfoProperties[
                $Property.Name
            ] =
                $Property.Value
        }

        # MultiMetric must remain MultiMetric on the parent object.
        $DisplayMetricInfoProperties['ValueMode'] =
            'MultiMetric'

        # But every individual metric is already prepared.
        $DisplayMetricInfoProperties['Metrics'] =
            @($DisplayMetricDefinitions)

        $DisplayMetricInfo =
            [PSCustomObject]$DisplayMetricInfoProperties
    }
    else {

        $DisplayMetricInfo =
            $DisplayMetricDefinitions[0]
    }

    # ---------------------------------------------------------------------
    # Load known Ports once
    #
    # Used only for readable Series names.
    # ---------------------------------------------------------------------

    $AvailablePorts = @(
        Get-StorageSFPHistoryPorts `
            -CustomerNbr $CustomerNbr
    )

    # ---------------------------------------------------------------------
    # Helper:
    # Create a stable key for matching raw and calculated History objects.
    #
    # Prefer database ID when available.
    # Fall back to TimeStamp.
    # ---------------------------------------------------------------------

    $GetHistoryKey = {

        param (
            $HistoryItem
        )

        if ($null -eq $HistoryItem) {
            return $null
        }

        if (
            $HistoryItem.PSObject.Properties['ID'] -and
            $null -ne $HistoryItem.ID
        ) {
            return (
                'ID|{0}' -f
                [string]$HistoryItem.ID
            )
        }

        if (
            $HistoryItem.PSObject.Properties['TimeStamp'] -and
            $null -ne $HistoryItem.TimeStamp
        ) {
            return (
                'TS|{0}' -f
                ([datetime]$HistoryItem.TimeStamp).Ticks
            )
        }

        return $null

    }.GetNewClosure()

    # ---------------------------------------------------------------------
    # Prepare result collections
    # ---------------------------------------------------------------------

    $SeriesDefinitions = @()
    $AllChartHistory   = @()
    $MetricValues      = @()

    # ---------------------------------------------------------------------
    # Build one prepared History per selected Port
    # ---------------------------------------------------------------------

    foreach ($CurrentRowID in $RequestedRowIDs) {

        # -------------------------------------------------------------
        # Load raw history
        # -------------------------------------------------------------

        $RawHistory = @(
            Get-SFPHistory `
                -CustomerNbr $CustomerNbr `
                -RowID $CurrentRowID `
                -StartTime $StartTime `
                -EndTime $EndTime
        )

        if ($RawHistory.Count -eq 0) {

            Write-Warning (
                "No Storage SFP history was found for RowID " +
                "'$CurrentRowID' in the selected time range."
            )

            continue
        }

        # -------------------------------------------------------------
        # Sort raw history once.
        # -------------------------------------------------------------

        $SortedRawHistory = @(
            $RawHistory |
                Sort-Object TimeStamp
        )

        # -------------------------------------------------------------
        # Create an independent copy of the RAW history.
        #
        # This is the common chart history.
        #
        # IMPORTANT:
        # Original database values are retained here.
        #
        # Example:
        #
        #   ZeroBtB = 596916051
        #
        # They must never be overwritten merely because another selected
        # metric uses ZeroBtB as its SourceMetric.
        # -------------------------------------------------------------

        $CurrentChartHistory = @(
            foreach ($HistoryItem in $SortedRawHistory) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                $CopiedProperties =
                    [ordered]@{}

                foreach ($Property in $HistoryItem.PSObject.Properties) {

                    $CopiedProperties[
                        $Property.Name
                    ] =
                        $Property.Value
                }

                [PSCustomObject]$CopiedProperties
            }
        )

        # -------------------------------------------------------------
        # Prepare calculated metrics
        # -------------------------------------------------------------

        foreach ($Definition in $MetricDefinitions) {

            $MetricName =
                [string]$Definition.Metric

            # ---------------------------------------------------------
            # Resolve actual source property.
            #
            # Example:
            #
            #   Metric       = ZeroBtBDelta
            #   SourceMetric = ZeroBtB
            # ---------------------------------------------------------

            $SourceMetric =
                if (
                    $Definition.PSObject.Properties['SourceMetric'] -and
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$Definition.SourceMetric
                    )
                ) {
                    [string]$Definition.SourceMetric
                }
                else {
                    $MetricName
                }

            # ---------------------------------------------------------
            # RAW metric
            #
            # Normally Metric and SourceMetric are identical.
            #
            # If they differ, expose the source value under the display
            # metric name without modifying the original source property.
            # ---------------------------------------------------------

            if (
                -not $Definition.PSObject.Properties['ValueMode'] -or
                [string]$Definition.ValueMode -ne 'Delta'
            ) {

                if ($MetricName -ne $SourceMetric) {

                    foreach ($HistoryItem in $CurrentChartHistory) {

                        if ($null -eq $HistoryItem) {
                            continue
                        }

                        $SourceProperty =
                            $HistoryItem.PSObject.Properties[
                                $SourceMetric
                            ]

                        $SourceValue =
                            if ($null -ne $SourceProperty) {
                                $SourceProperty.Value
                            }
                            else {
                                $null
                            }

                        $HistoryItem |
                            Add-Member `
                                -MemberType NoteProperty `
                                -Name $MetricName `
                                -Value $SourceValue `
                                -Force
                    }
                }

                continue
            }

            # ---------------------------------------------------------
            # DELTA metric
            #
            # Calculate from the untouched raw history.
            #
            # The returned objects may contain the Delta in SourceMetric,
            # but these objects are temporary and never replace the common
            # CurrentChartHistory.
            # ---------------------------------------------------------

            $DeltaHistory = @(
                ConvertTo-LiveChartsDeltaHistory `
                    -History $SortedRawHistory `
                    -Metric $SourceMetric
            )

            # ---------------------------------------------------------
            # Build lookup:
            #
            # History key -> calculated Delta value
            # ---------------------------------------------------------

            $DeltaValues =
                @{}

            foreach ($DeltaItem in $DeltaHistory) {

                if ($null -eq $DeltaItem) {
                    continue
                }

                $HistoryKey =
                    & $GetHistoryKey $DeltaItem

                if ([string]::IsNullOrWhiteSpace($HistoryKey)) {
                    continue
                }

                $DeltaProperty =
                    $DeltaItem.PSObject.Properties[
                        $SourceMetric
                    ]

                if ($null -eq $DeltaProperty) {
                    continue
                }

                $DeltaValues[$HistoryKey] =
                    $DeltaProperty.Value
            }

            # ---------------------------------------------------------
            # Add Delta to the common History.
            #
            # Example:
            #
            #   ZeroBtB      = 596916051
            #   ZeroBtBDelta = 852404
            #
            # ZeroBtB stays untouched.
            # ---------------------------------------------------------

            foreach ($HistoryItem in $CurrentChartHistory) {

                if ($null -eq $HistoryItem) {
                    continue
                }

                $HistoryKey =
                    & $GetHistoryKey $HistoryItem

                $DeltaValue =
                    $null

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        $HistoryKey
                    ) -and
                    $DeltaValues.ContainsKey(
                        $HistoryKey
                    )
                ) {
                    $DeltaValue =
                        $DeltaValues[$HistoryKey]
                }

                if ($MetricName -ne $SourceMetric) {

                    # -------------------------------------------------
                    # Derived Delta metric.
                    #
                    # Example:
                    #
                    #   ZeroBtBDelta
                    #
                    # Add a new property and preserve ZeroBtB.
                    # -------------------------------------------------

                    $HistoryItem |
                        Add-Member `
                            -MemberType NoteProperty `
                            -Name $MetricName `
                            -Value $DeltaValue `
                            -Force
                }
                else {

                    # -------------------------------------------------
                    # Legacy Delta metric.
                    #
                    # Existing metrics such as LinkFailure currently
                    # use the same property name for Source and display.
                    #
                    # For these metrics the property itself intentionally
                    # contains the calculated Delta.
                    # -------------------------------------------------

                    $MetricProperty =
                        $HistoryItem.PSObject.Properties[
                            $MetricName
                        ]

                    if ($null -ne $MetricProperty) {

                        $MetricProperty.Value =
                            $DeltaValue
                    }
                    else {

                        $HistoryItem |
                            Add-Member `
                                -MemberType NoteProperty `
                                -Name $MetricName `
                                -Value $DeltaValue `
                                -Force
                    }
                }
            }
        }

        # -------------------------------------------------------------
        # Convert prepared values into chart-ready display values.
        #
        # IMPORTANT:
        #
        # Use DisplayMetricInfo here.
        #
        # Delta values have already been calculated above, therefore the
        # display converter sees every individual metric as Raw.
        # -------------------------------------------------------------

        $CurrentChartHistory = @(
            ConvertTo-LiveChartsDisplayHistory `
                -History $CurrentChartHistory `
                -MetricInfo $DisplayMetricInfo
        )

        if ($CurrentChartHistory.Count -eq 0) {

            Write-Warning (
                "No usable chart history could be created for " +
                "RowID '$CurrentRowID'."
            )

            continue
        }

        # -------------------------------------------------------------
        # Collect numeric values for all selected metrics
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
                            "for RowID '$CurrentRowID' could not be " +
                            'converted to Double and was skipped.'
                        )
                    }
                }
            }
        )

        if ($CurrentMetricValues.Count -eq 0) {

            Write-Warning (
                "RowID '$CurrentRowID' contains no usable values for " +
                'the selected metric(s).'
            )

            continue
        }

        # -------------------------------------------------------------
        # Resolve readable Port name
        # -------------------------------------------------------------

        $PortInfo =
            $AvailablePorts |
                Where-Object {
                    [string]$_.RowID -eq
                    [string]$CurrentRowID
                } |
                Select-Object -First 1

        if (
            $null -ne $PortInfo -and
            $PortInfo.PSObject.Properties['NodeID'] -and
            $PortInfo.PSObject.Properties['PortID'] -and
            $null -ne $PortInfo.NodeID -and
            $null -ne $PortInfo.PortID
        ) {
            $SeriesName =
                'Node{0} P{1}' -f
                    $PortInfo.NodeID,
                    $PortInfo.PortID
        }
        elseif (
            $null -ne $PortInfo -and
            $PortInfo.PSObject.Properties['DisplayName'] -and
            -not [string]::IsNullOrWhiteSpace(
                [string]$PortInfo.DisplayName
            )
        ) {
            $SeriesName =
                [string]$PortInfo.DisplayName
        }
        else {

            $RowIDParts =
                [string]$CurrentRowID -split '\|'

            if ($RowIDParts.Count -ge 3) {

                $SeriesName =
                    [string]$RowIDParts[2]
            }
            else {

                $SeriesName =
                    [string]$CurrentRowID
            }
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
    # Validate prepared Sources
    # ---------------------------------------------------------------------

    if ($SeriesDefinitions.Count -eq 0) {
        throw (
            'No usable Storage SFP histories were found for the ' +
            'requested Sources.'
        )
    }

    if ($MetricValues.Count -eq 0) {
        throw (
            'The Storage SFP histories contain no usable values for ' +
            'the selected metric(s): ' +
            ($RequestedMetrics -join ', ')
        )
    }

    # ---------------------------------------------------------------------
    # Determine actual comparison mode
    #
    # A requested Port without History may have been skipped.
    # Therefore use the number of actually usable Sources.
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
    # Build generic chart model
    #
    # IMPORTANT:
    #
    # The ORIGINAL MetricInfo is passed here.
    #
    # DisplayMetricInfo was used only for value conversion.
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