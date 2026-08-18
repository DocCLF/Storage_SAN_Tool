function Get-StorageVolumeLiveChartsPresets {
    <#
    .SYNOPSIS
        Returns predefined LiveCharts series selections for
        Storage volume analysis data.

    .DESCRIPTION
        Defines useful initial series selections.

        A preset only defines the initial selection. After a preset
        has been applied, the user may freely add or remove compatible
        series through the generic series selector.

    .OUTPUTS
        PSCustomObject[]
    #>

    [CmdletBinding()]
    param ()

    return @(
        [PSCustomObject]@{
            Name        = 'Capacity'
            DisplayName = 'Capacity'
            UnitGroup   = 'Capacity'
            Metrics     = @(
                'Capacity'
                'ThinSize'
                'CompressedSize'
            )
            IsDefault   = $true
        }

        [PSCustomObject]@{
            Name        = 'Savings'
            DisplayName = 'Savings'
            UnitGroup   = 'Capacity'
            Metrics     = @(
                'ThinSavings'
                'CompressionSavings'
                'TotalSavings'
            )
            IsDefault   = $false
        }

        [PSCustomObject]@{
            Name        = 'Ratios'
            DisplayName = 'Savings Ratios'
            UnitGroup   = 'Percent'
            Metrics     = @(
                'ThinSavingsRatio'
                'CompressionSavingsRatio'
                'TotalSavingsRatio'
            )
            IsDefault   = $false
        }

        [PSCustomObject]@{
            Name        = 'AnalysisQuality'
            DisplayName = 'Analysis Quality'
            UnitGroup   = 'Percent'
            Metrics     = @(
                'TotalSavingsRatio'
                'MarginOfError'
            )
            IsDefault   = $false
        }
    )
}