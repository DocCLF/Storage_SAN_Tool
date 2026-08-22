function Get-StorageLiveChartsMetricInfo {
    <#
    .SYNOPSIS
        Returns LiveCharts metric metadata for Storage SFP history data.

    .DESCRIPTION
        Defines the available Storage SFP metrics and their presentation
        properties.

        Metrics are grouped by UnitGroup so that the generic
        LiveCharts Series Selector can determine which metrics may share
        the same Y axis.

        UnitGroups:

            Temperature
                SFPTemp

            OpticalPower
                TXPwr
                RXPwr

            Counter
                LinkFailure
                LoseSync
                LoseSig
                PSErrCount
                InvTransErr
                CRCErr
                ZeroBtB

        Counter values are cumulative in the database.
        
        Each counter is available in two representations:
        
            Total
                Displays the raw cumulative counter value.
        
            Increase
                Displays the increase between consecutive measurements.

    .PARAMETER Metric
        Name of one specific Storage SFP metric.

    .PARAMETER All
        Returns all available Storage SFP metrics. 

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

    $Metrics = @(

        # -----------------------------------------------------------------
        # Temperature
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'SFPTemp'
            DisplayName      = 'SFP Temperature'
            Description      = 'Optical transceiver temperature'

            Unit             = '°C'
            UnitGroup        = 'Temperature'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#2E86DE'

            MinimumPadding   = 1

            ChartType        = 'Trend'
            ShowArea         = $true
            ValueMode        = 'Raw'

            ReferenceMetric  = 'SFPTempHt'
            ReferenceName    = 'SFP High Temp'
            ReferenceColor   = '#E74C3C'
        }

        # -----------------------------------------------------------------
        # Optical Power
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'TXPwr'
            DisplayName      = 'TX Power'
            Description      = 'Transmit optical power'

            Unit             = 'µW'
            UnitGroup        = 'OpticalPower'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#2ECC71'

            MinimumPadding   = 50

            ChartType        = 'Trend'
            ShowArea         = $true
            ValueMode        = 'Raw'

            ReferenceMetric  = 'TXPwrLow'
            ReferenceName    = 'TX Low Limit'
            ReferenceColor   = '#E74C3C'
        }

        [PSCustomObject]@{
            Metric           = 'RXPwr'
            DisplayName      = 'RX Power'
            Description      = 'Receive optical power'

            Unit             = 'µW'
            UnitGroup        = 'OpticalPower'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#9B59B6'

            MinimumPadding   = 50

            ChartType        = 'Trend'
            ShowArea         = $true
            ValueMode        = 'Raw'

            ReferenceMetric  = 'RXPwrLow'
            ReferenceName    = 'RX Low Limit'
            ReferenceColor   = '#E74C3C'
        }

         # -----------------------------------------------------------------
        # Counter metrics
        #
        # Each cumulative counter is available in two representations:
        #
        #   <Metric>
        #       Total / raw cumulative counter value
        #
        #   <Metric>Delta
        #       Increase between two consecutive measurements
        #
        # SourceMetric always points to the original database property.
        # -----------------------------------------------------------------

        # -----------------------------------------------------------------
        # Link Failures
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'LinkFailure'
            SourceMetric     = 'LinkFailure'
            DisplayName      = 'Link Failures - Total'
            Description      = 'Accumulated link failures'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Raw'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'LinkFailureDelta'
            SourceMetric     = 'LinkFailure'
            DisplayName      = 'Link Failures - Increase'
            Description      = 'Increase of link failures between measurements'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        # -----------------------------------------------------------------
        # Loss of Sync
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'LoseSync'
            SourceMetric     = 'LoseSync'
            DisplayName      = 'Loss of Sync - Total'
            Description      = 'Accumulated loss of synchronization events'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Raw'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'LoseSyncDelta'
            SourceMetric     = 'LoseSync'
            DisplayName      = 'Loss of Sync - Increase'
            Description      = 'Increase of loss of synchronization events between measurements'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        # -----------------------------------------------------------------
        # Loss of Signal
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'LoseSig'
            SourceMetric     = 'LoseSig'
            DisplayName      = 'Loss of Signal - Total'
            Description      = 'Accumulated loss of signal events'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Raw'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'LoseSigDelta'
            SourceMetric     = 'LoseSig'
            DisplayName      = 'Loss of Signal - Increase'
            Description      = 'Increase of loss of signal events between measurements'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        # -----------------------------------------------------------------
        # Primitive Sequence Errors
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'PSErrCount'
            SourceMetric     = 'PSErrCount'
            DisplayName      = 'Primitive Sequence Errors - Total'
            Description      = 'Accumulated primitive sequence protocol errors'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Raw'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'PSErrCountDelta'
            SourceMetric     = 'PSErrCount'
            DisplayName      = 'Primitive Sequence Errors - Increase'
            Description      = 'Increase of primitive sequence protocol errors between measurements'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        # -----------------------------------------------------------------
        # Invalid Transmission Words
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'InvTransErr'
            SourceMetric     = 'InvTransErr'
            DisplayName      = 'Invalid Transmission Words - Total'
            Description      = 'Accumulated invalid transmission words'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Raw'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'InvTransErrDelta'
            SourceMetric     = 'InvTransErr'
            DisplayName      = 'Invalid Transmission Words - Increase'
            Description      = 'Increase of invalid transmission words between measurements'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        # -----------------------------------------------------------------
        # CRC Errors
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'CRCErr'
            SourceMetric     = 'CRCErr'
            DisplayName      = 'CRC Errors - Total'
            Description      = 'Accumulated CRC errors'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Raw'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'CRCErrDelta'
            SourceMetric     = 'CRCErr'
            DisplayName      = 'CRC Errors - Increase'
            Description      = 'Increase of CRC errors between measurements'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        # -----------------------------------------------------------------
        # Zero BB Credit
        # -----------------------------------------------------------------

        [PSCustomObject]@{
            Metric           = 'ZeroBtB'
            SourceMetric     = 'ZeroBtB'
            DisplayName      = 'Zero BB Credit - Total'
            Description      = 'Accumulated zero buffer-to-buffer credits'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Raw'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'ZeroBtBDelta'
            SourceMetric     = 'ZeroBtB'
            DisplayName      = 'Zero BB Credit - Increase'
            Description      = 'Increase of zero buffer-to-buffer credits between measurements'

            Unit             = ''
            UnitGroup        = 'Counter'
            Precision        = 0
            ValueDivisor     = [double]1

            Color            = '#34495E'
            MinimumPadding   = 1

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode        = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }
    )

    if ($All) {
        return $Metrics
    }

    $Result =
        $Metrics |
            Where-Object {
                $_.Metric -eq $Metric
            } |
            Select-Object -First 1

    if ($null -eq $Result) {
        throw "Unknown Storage SFP metric '$Metric'."
    }

    return $Result
}