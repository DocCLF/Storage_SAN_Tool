function New-LiveChartsChartModel {
    <#
    .SYNOPSIS
        Creates a common data model for LiveCharts history views.

    .DESCRIPTION
        Combines chart series, axes, history, metric metadata,
        statistics and request information into one reusable object.

        The function is independent of Storage, SAN and Tape.

    .PARAMETER Series
        LiveCharts series collection.

    .PARAMETER XAxes
        LiveCharts X-axis collection.

    .PARAMETER YAxes
        LiveCharts Y-axis collection.

    .PARAMETER History
        Historical source objects used to build the chart.

    .PARAMETER MetricInfo
        Metadata for the selected metric.

    .PARAMETER Statistics
        Statistical summary created by New-LiveChartsStatistics.

    .PARAMETER CustomerNbr
        Customer number associated with the history.

    .PARAMETER RowID
        Stable identifier of the selected source object or port.

    .PARAMETER Metric
        Selected metric property name.

    .PARAMETER StartTime
        Beginning of the displayed period.

    .PARAMETER EndTime
        End of the displayed period.

    .OUTPUTS
        PSCustomObject
    #>

[CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.Collections.Generic.List[
            LiveChartsCore.ISeries
        ]]$Series,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $XAxes,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $YAxes,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [object[]]$History,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $MetricInfo,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        $Statistics,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RowID,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Metric,

        [Parameter(Mandatory)]
        [datetime]$StartTime,

        [Parameter(Mandatory)]
        [datetime]$EndTime
    )

$ChartModel = [PSCustomObject]@{
    History      = $History
    MetricInfo   = $MetricInfo

    CustomerNbr  = $CustomerNbr
    RowID        = $RowID
    Metric       = $Metric
    StartTime    = $StartTime
    EndTime      = $EndTime

    CurrentValue = $Statistics.CurrentValue
    MinimumValue = $Statistics.MinimumValue
    MaximumValue = $Statistics.MaximumValue
    AverageValue = $Statistics.AverageValue
    PointCount   = $Statistics.PointCount
}

# Explicitly add the typed collections as individual property values.
# This prevents PowerShell from resolving them.
$ChartModel.PSObject.Properties.Add([System.Management.Automation.PSNoteProperty]::new('Series',$Series))
$ChartModel.PSObject.Properties.Add([System.Management.Automation.PSNoteProperty]::new('XAxes',$XAxes))
$ChartModel.PSObject.Properties.Add([System.Management.Automation.PSNoteProperty]::new('YAxes',$YAxes))

Write-Output -NoEnumerate $ChartModel

}