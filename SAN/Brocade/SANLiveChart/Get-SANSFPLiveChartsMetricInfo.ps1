function Get-SANSFPLiveChartsMetricInfo {
    <#
    .SYNOPSIS
        Returns LiveCharts metric definitions for SAN SFP history.

    .DESCRIPTION
        Provides metric metadata used by the SAN SFP history viewer.

        Metrics are grouped by compatible units:

            Temperature  -> Temperature
            RxPower      -> OpticalPower
            TxPower      -> OpticalPower
            Voltage      -> Voltage

        Metrics from different UnitGroups must not share the same
        Y axis.

    .PARAMETER Metric
        Optional single metric name.

    .PARAMETER All
        Returns all available SAN SFP metric definitions.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        Get-SANSFPLiveChartsMetricInfo -All

    .EXAMPLE
        Get-SANSFPLiveChartsMetricInfo -Metric 'RxPower'
    #>

    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(
            'Temperature',
            'RxPower',
            'TxPower',
            'Voltage'
        )]
        [string]$Metric,

        [Parameter()]
        [switch]$All
    )

    $MetricDefinitions = @(

        [PSCustomObject]@{
            Metric          = 'Temperature'
            DisplayName     = 'Temperature'
            Unit            = '°C'
            UnitGroup       = 'Temperature'
            ValueMode       = 'Raw'
            Precision       = 1
            ValueDivisor    = 1
            MinimumPadding  = 2
            ShowArea        = $false
        }

        [PSCustomObject]@{
            Metric          = 'RxPower'
            DisplayName     = 'RX Power'
            Unit            = ''
            UnitGroup       = 'OpticalPower'
            ValueMode       = 'Raw'
            Precision       = 2
            ValueDivisor    = 1
            MinimumPadding  = 10
            ShowArea        = $false
        }

        [PSCustomObject]@{
            Metric          = 'TxPower'
            DisplayName     = 'TX Power'
            Unit            = ''
            UnitGroup       = 'OpticalPower'
            ValueMode       = 'Raw'
            Precision       = 2
            ValueDivisor    = 1
            MinimumPadding  = 10
            ShowArea        = $false
        }

        [PSCustomObject]@{
            Metric          = 'Voltage'
            DisplayName     = 'Voltage'
            Unit            = ''
            UnitGroup       = 'Voltage'
            ValueMode       = 'Raw'
            Precision       = 2
            ValueDivisor    = 1
            MinimumPadding  = 10
            ShowArea        = $false
        }
    )

    if ($All) {
        return $MetricDefinitions
    }

    if (-not [string]::IsNullOrWhiteSpace($Metric)) {

        $Result =
            $MetricDefinitions |
                Where-Object {
                    $_.Metric -eq $Metric
                } |
                Select-Object -First 1

        if ($null -eq $Result) {
            throw "Unknown SAN SFP metric '$Metric'."
        }

        return $Result
    }

    return $MetricDefinitions
}