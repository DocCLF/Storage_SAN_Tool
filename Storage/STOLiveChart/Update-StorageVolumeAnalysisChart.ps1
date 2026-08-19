function Update-StorageVolumeAnalysisChart {
    <#
    .SYNOPSIS
        Builds the LiveCharts data model for one or multiple IBM Storage volumes.

    .DESCRIPTION
        Loads historical volume analysis data for one or multiple Storage
        volumes and prepares one or multiple selected metrics.

        Supported combinations:

            1 Source  x 1 Metric
            1 Source  x n Metrics
            n Sources x 1 Metric
            n Sources x n Metrics

        All selected metrics must belong to the same UnitGroup.

    .PARAMETER CustomerNbr
        Customer number used to locate the SQLite database.

    .PARAMETER RowIDs
        One or multiple stable volume identifiers:

            SerialNumber|VOLUME|VolumeID

    .PARAMETER Metric
        One or multiple volume analysis metrics to display.

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

        [datetime]$StartTime = (Get-Date).AddDays(-30),

        [datetime]$EndTime = (Get-Date),

        [ValidateNotNullOrEmpty()]
        [string]$DateTimeLabelFormat = 'dd.MM. HH:mm',

        [TimeSpan]$DateTimeStep = ([TimeSpan]::FromHours(1))
    )

    if (-not (Initialize-LiveCharts)) {
        SST_ToolMessageCollector -TD_ToolMSGCollector ('LiveCharts could not be initialized.') -TD_ToolMSGType 'Error' -TD_Shown 'yes'
    }

    if ($StartTime -gt $EndTime) {
        SST_ToolMessageCollector -TD_ToolMSGCollector ('StartTime must not be later than EndTime.') -TD_ToolMSGType 'Error' -TD_Shown 'yes'
    }

    if ($DateTimeStep -le [TimeSpan]::Zero) {
        SST_ToolMessageCollector -TD_ToolMSGCollector ('DateTimeStep must be greater than zero.') -TD_ToolMSGType 'Error' -TD_Shown 'yes'
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
        SST_ToolMessageCollector -TD_ToolMSGCollector ('At least one volume RowID is required.') -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
    }

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
        SST_ToolMessageCollector -TD_ToolMSGCollector ('At least one volume metric is required.') -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
    }

    # ---------------------------------------------------------------------
    # Load metric definitions
    # ---------------------------------------------------------------------

    $MetricDefinitions = @(
        foreach ($MetricName in $RequestedMetrics) {

            Get-StorageVolumeLiveChartsMetricInfo `
                -Metric $MetricName
        }
    )

    if ($MetricDefinitions.Count -eq 0) {
        SST_ToolMessageCollector -TD_ToolMSGCollector ('No usable Storage volume metric definitions were found.') -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
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
        SST_ToolMessageCollector -TD_ToolMSGCollector ('Selected volume metrics must belong to the same UnitGroup.') -TD_ToolMSGType 'Debug' -TD_Shown 'yes'
    }

    # ---------------------------------------------------------------------
    # Build runtime MetricInfo
    # ---------------------------------------------------------------------

    $IsMultiMetric = ($MetricDefinitions.Count -gt 1)

    if ($IsMultiMetric) {

        $FirstMetric = $MetricDefinitions[0]

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

            Metrics = @($MetricDefinitions)

            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }
    }else {
        $MetricInfo = $MetricDefinitions[0]
    }

    # ---------------------------------------------------------------------
    # Load available volume metadata once
    # ---------------------------------------------------------------------

    $AvailableVolumes = @(
        Get-StorageVolumeHistoryVolumes `
            -CustomerNbr $CustomerNbr
    )

    # ---------------------------------------------------------------------
    # Build one prepared history per requested source
    # ---------------------------------------------------------------------

    $SeriesDefinitions = @()
    $AllChartHistory   = @()
    $MetricValues      = @()

    foreach ($CurrentRowID in $RequestedRowIDs) {

        # -------------------------------------------------------------
        # Load raw history
        # -------------------------------------------------------------

        $RawHistory = @(Get-StorageVolumeAnalysisHistory -CustomerNbr $CustomerNbr -RowID $CurrentRowID -StartTime $StartTime -EndTime $EndTime)

        if ($RawHistory.Count -eq 0) {
            SST_ToolMessageCollector -TD_ToolMSGCollector ("No Storage volume analysis history was found for " + "RowID '$CurrentRowID' in the selected time range.") -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
            continue
        }

        # -------------------------------------------------------------
        # Convert DB values into display values
        # -------------------------------------------------------------

        $ChartHistory = @(ConvertTo-LiveChartsDisplayHistory -History $RawHistory -MetricInfo $MetricInfo)

        if ($ChartHistory.Count -eq 0) {
            SST_ToolMessageCollector -TD_ToolMSGCollector ("No usable chart history could be created for " + "RowID '$CurrentRowID'.") -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
            continue
        }

        # -------------------------------------------------------------
        # Collect values for axis scaling
        # -------------------------------------------------------------

        foreach ($HistoryItem in $ChartHistory) {

            if ($null -eq $HistoryItem) {
                continue
            }

            foreach ($Definition in $MetricDefinitions) {

                $MetricName = [string]$Definition.Metric

                if ([string]::IsNullOrWhiteSpace($MetricName)) {
                    continue
                }

                $MetricProperty = $HistoryItem.PSObject.Properties[$MetricName]

                if ($null -eq $MetricProperty) {
                    continue
                }

                $RawValue = $MetricProperty.Value

                if ($null -eq $RawValue -or $RawValue -is [DBNull] -or [string]::IsNullOrWhiteSpace([string]$RawValue)) {
                    continue
                }

                try {
                    $MetricValues += [double]$RawValue
                }
                catch {
                    SST_ToolMessageCollector -TD_ToolMSGCollector ("Value '$RawValue' of metric '$MetricName' " + "for RowID '$CurrentRowID' could not be " + 'converted to Double and was skipped.') -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
                }
            }
        }

        # -------------------------------------------------------------
        # Resolve readable source name
        # -------------------------------------------------------------

        $VolumeInfo =
            $AvailableVolumes |
            Where-Object {
                [string]$_.RowID -eq
                [string]$CurrentRowID
            } |
            Select-Object -First 1

        if ($null -ne $VolumeInfo) {

            $SeriesName =
                [string]$VolumeInfo.VolumeName
        }
        else {

            $SeriesName =
                [string]$CurrentRowID
        }

        # -------------------------------------------------------------
        # Add prepared source
        # -------------------------------------------------------------

        $SeriesDefinitions +=
            [PSCustomObject]@{
                RowID   = $CurrentRowID
                Name    = $SeriesName
                History = $ChartHistory
            }

        $AllChartHistory +=
            $ChartHistory
    }

    # ---------------------------------------------------------------------
    # Validate resulting source collection
    # ---------------------------------------------------------------------

    if ($SeriesDefinitions.Count -eq 0) {
        SST_ToolMessageCollector -TD_ToolMSGCollector ('No Storage volume analysis history was found for the ' + 'requested source(s) in the selected time range.') -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
        return
    }

    if ($MetricValues.Count -eq 0) {
        SST_ToolMessageCollector -TD_ToolMSGCollector ('Storage volume history data was found, but no usable values ' + 'exist for the selected metric(s): ' + ($RequestedMetrics -join ', ')) -TD_ToolMSGType 'Warning' -TD_Shown 'yes'
        return
    }

    # ---------------------------------------------------------------------
    # Determine comparison mode
    # ---------------------------------------------------------------------

    $IsComparison =
        ($SeriesDefinitions.Count -gt 1)

    # ---------------------------------------------------------------------
    # First usable RowID remains the primary RowID for compatibility
    # with the common chart model.
    # ---------------------------------------------------------------------

    $PrimaryRowID =
        [string]$SeriesDefinitions[0].RowID

    # ---------------------------------------------------------------------
    # Build common chart model
    # ---------------------------------------------------------------------

    return New-LiveChartsHistoryChartModel `
        -SeriesDefinitions $SeriesDefinitions `
        -AllChartHistory $AllChartHistory `
        -MetricValues $MetricValues `
        -MetricInfo $MetricInfo `
        -CustomerNbr $CustomerNbr `
        -RowID $PrimaryRowID `
        -RowIDs ([string[]]$SeriesDefinitions.RowID) `
        -Metric ([string]$MetricInfo.Metric) `
        -StartTime $StartTime `
        -EndTime $EndTime `
        -DateTimeLabelFormat $DateTimeLabelFormat `
        -DateTimeStep $DateTimeStep `
        -IsComparison $IsComparison
}