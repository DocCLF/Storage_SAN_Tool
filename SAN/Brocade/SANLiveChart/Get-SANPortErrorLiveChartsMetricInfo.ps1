function Get-SANPortErrorLiveChartsMetricInfo {
    <#
    .SYNOPSIS
        Returns LiveCharts metric definitions for Brocade SAN port errors.

    .DESCRIPTION
        Provides the available Brocade SAN port-error metrics for
        historical LiveCharts views.

        All values are cumulative switch counters and therefore use
        ValueMode 'Raw' for historical visualization.

    .PARAMETER Metric
        Optional metric name.

    .PARAMETER All
        Returns all available metric definitions.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateSet(
            'EncIn',
            'CrcErr',
            'TooShort',
            'TooLong',
            'BadEOF',
            'EncOut',
            'DiscC3',
            'LinkFail',
            'LossSync',
            'LossSig',
            'StateTransitions',
            'BBZero',
            'FECuncorrected'
        )]
        [string]$Metric,

        [Parameter()]
        [switch]$All
    )

    $Definitions = @(
        [PSCustomObject]@{
            Metric      = 'EncIn'
            DisplayName = 'Encoding Errors In'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'CrcErr'
            DisplayName = 'CRC Errors'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'TooShort'
            DisplayName = 'Frames Too Short'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'TooLong'
            DisplayName = 'Frames Too Long'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'BadEOF'
            DisplayName = 'Bad EOF'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'EncOut'
            DisplayName = 'Encoding Errors Outside Frame'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'DiscC3'
            DisplayName = 'Class 3 Discards'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'LinkFail'
            DisplayName = 'Link Failures'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'LossSync'
            DisplayName = 'Loss of Sync'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'LossSig'
            DisplayName = 'Loss of Signal'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'StateTransitions'
            DisplayName = 'State Transitions'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'BBZero'
            DisplayName = 'BB Credit Zero'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }

        [PSCustomObject]@{
            Metric      = 'FECuncorrected'
            DisplayName = 'FEC Uncorrected'
            Unit        = ''
            UnitGroup   = 'Counter'
            ValueMode   = 'Raw'
        }
    )

    if ($All) {
        return $Definitions
    }

    if (-not [string]::IsNullOrWhiteSpace($Metric)) {
        return @(
            $Definitions |
                Where-Object {
                    $_.Metric -eq $Metric
                }
        )
    }

    return $Definitions
}