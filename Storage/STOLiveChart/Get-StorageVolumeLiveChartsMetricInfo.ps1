function Get-StorageVolumeLiveChartsMetricInfo {
    <#
    .SYNOPSIS
        Returns LiveCharts metric metadata for Storage volume analysis data.

    .DESCRIPTION
        Defines the available Storage volume analysis metrics and their
        presentation properties.

        Capacity values are stored in the database as bytes and are converted
        into the configured display unit before the LiveCharts series are
        created.

        UnitGroup is used to describe which metrics may later be displayed
        together in the same chart.

    .PARAMETER Metric
        Name of one specific volume metric.

    .PARAMETER All
        Returns all available volume metrics.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByMetric')]
    param (
        [Parameter(
            Mandatory,
            ParameterSetName = 'ByMetric'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Metric,

        [Parameter(
            Mandatory,
            ParameterSetName = 'All'
        )]
        [switch]$All
    )

    $MetricDefinitions = @(

        [PSCustomObject]@{
            Metric          = 'Capacity'
            DisplayName     = 'Capacity'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $false
            Color           = '#2E86DE'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'ThinSize'
            DisplayName     = 'Thin Size'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $false
            Color           = '#2ECC71'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'ThinSavings'
            DisplayName     = 'Thin Savings'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $false
            Color           = '#27AE60'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'CompressedSize'
            DisplayName     = 'Compressed Size'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $false
            Color           = '#9B59B6'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'CompressionSavings'
            DisplayName     = 'Compression Savings'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $false
            Color           = '#8E44AD'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'TotalSavings'
            DisplayName     = 'Total Savings'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $false
            Color           = '#E67E22'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'ThinSavingsRatio'
            DisplayName     = 'Thin Savings Ratio'
            Unit            = '%'
            UnitGroup       = 'Percent'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1
            MinimumPadding  = 5
            ShowArea        = $false
            Color           = '#16A085'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'CompressionSavingsRatio'
            DisplayName     = 'Compression Savings Ratio'
            Unit            = '%'
            UnitGroup       = 'Percent'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1
            MinimumPadding  = 5
            ShowArea        = $false
            Color           = '#2980B9'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'TotalSavingsRatio'
            DisplayName     = 'Total Savings Ratio'
            Unit            = '%'
            UnitGroup       = 'Percent'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1
            MinimumPadding  = 5
            ShowArea        = $false
            Color           = '#D35400'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        [PSCustomObject]@{
            Metric          = 'MarginOfError'
            DisplayName     = 'Margin of Error'
            Unit            = '%'
            UnitGroup       = 'Percent'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1
            MinimumPadding  = 1
            ShowArea        = $false
            Color           = '#7F8C8D'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }
    )

    if ($All) {
        return $MetricDefinitions
    }

    $Result = $MetricDefinitions |
        Where-Object {
            $_.Metric -eq $Metric
        } |
        Select-Object -First 1

    if ($null -eq $Result) {
        throw "Unknown Storage volume metric '$Metric'."
    }

    return $Result
}