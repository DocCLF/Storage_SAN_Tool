function Get-StoragePoolLiveChartsMetricInfo {
    <#
    .SYNOPSIS
        Returns LiveCharts metric metadata for Storage pool capacity data.

    .DESCRIPTION
        Defines the available Storage pool metrics and their presentation
        properties.

        Capacity values are stored in the database as bytes. The pool chart
        builder is responsible for converting them into the configured
        display unit before creating the LiveCharts series.

        Metrics are grouped by UnitGroup so that the generic LiveCharts
        SeriesSelector can prevent incompatible Y-axis units from being
        selected simultaneously.

        CapacityOverview is retained as a MultiMetric preset and is not
        intended to be used as a normal selectable Series entry.

    .PARAMETER Metric
        Name of one specific pool metric.

    .PARAMETER All
        Returns all available pool metric definitions including
        CapacityOverview.

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

        # -------------------------------------------------------------
        # Capacity Overview
        #
        # Preset containing all relevant capacity metrics.
        # This definition is used by the Metric ComboBox but should not
        # become an individual entry in the Series selector.
        # -------------------------------------------------------------

        [PSCustomObject]@{
            Metric         = 'CapacityOverview'
            DisplayName    = 'Capacity Overview'
            Unit           = 'TB'
            UnitGroup      = 'Capacity'
            Precision      = 2
            ValueMode      = 'MultiMetric'
            ValueDivisor   = [double]1TB
            MinimumPadding = 0.5
            ShowArea       = $false

            Metrics = @(
                [PSCustomObject]@{
                    Metric      = 'Capacity'
                    DisplayName = 'Capacity'
                    Color       = '#2E86DE'
                }

                [PSCustomObject]@{
                    Metric      = 'FreeCapacity'
                    DisplayName = 'Free Capacity'
                    Color       = '#2ECC71'
                }

                [PSCustomObject]@{
                    Metric      = 'UsedCapacity'
                    DisplayName = 'Used Capacity'
                    Color       = '#E67E22'
                }

                [PSCustomObject]@{
                    Metric      = 'VirtualCapacity'
                    DisplayName = 'Virtual Capacity'
                    Color       = '#9B59B6'
                }

                [PSCustomObject]@{
                    Metric      = 'RealCapacity'
                    DisplayName = 'Real Capacity'
                    Color       = '#34495E'
                }
            )

            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        # -------------------------------------------------------------
        # Capacity
        # -------------------------------------------------------------

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

        # -------------------------------------------------------------
        # Free Capacity
        # -------------------------------------------------------------

        [PSCustomObject]@{
            Metric          = 'FreeCapacity'
            DisplayName     = 'Free Capacity'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $true
            Color           = '#2ECC71'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        # -------------------------------------------------------------
        # Used Capacity
        # -------------------------------------------------------------

        [PSCustomObject]@{
            Metric          = 'UsedCapacity'
            DisplayName     = 'Used Capacity'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $true
            Color           = '#E67E22'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        # -------------------------------------------------------------
        # Virtual Capacity
        # -------------------------------------------------------------

        [PSCustomObject]@{
            Metric          = 'VirtualCapacity'
            DisplayName     = 'Virtual Capacity'
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

        # -------------------------------------------------------------
        # Real Capacity
        # -------------------------------------------------------------

        [PSCustomObject]@{
            Metric          = 'RealCapacity'
            DisplayName     = 'Real Capacity'
            Unit            = 'TB'
            UnitGroup       = 'Capacity'
            Precision       = 2
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1TB
            MinimumPadding  = 0.5
            ShowArea        = $false
            Color           = '#34495E'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }

        # -------------------------------------------------------------
        # Overallocation
        #
        # Percentage metric and therefore deliberately separated from
        # Capacity metrics by UnitGroup.
        # -------------------------------------------------------------

        [PSCustomObject]@{
            Metric          = 'Overallocation'
            DisplayName     = 'Overallocation'
            Unit            = '%'
            UnitGroup       = 'Percent'
            Precision       = 1
            ValueMode       = 'Raw'
            ValueDivisor    = [double]1
            MinimumPadding  = 5
            ShowArea        = $false
            Color           = '#C0392B'
            ReferenceMetric = $null
            ReferenceName   = $null
            ReferenceColor  = $null
        }
    )

    if ($All) {
        return $MetricDefinitions
    }

    $Result =
        $MetricDefinitions |
            Where-Object {
                $_.Metric -eq $Metric
            } |
            Select-Object -First 1

    if ($null -eq $Result) {
        throw "Unknown Storage pool metric '$Metric'."
    }

    return $Result
}