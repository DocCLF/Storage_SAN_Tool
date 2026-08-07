function Get-StorageLiveChartsMetricInfo {

    [CmdletBinding()]
    param(
        [string]$Metric,
        [switch]$All
    )

    $Metrics = @(

        [PSCustomObject]@{
            Metric           = 'SFPTemp'
            DisplayName      = 'SFP Temperature'
            Description      = 'Optical transceiver temperature'
        
            Unit             = '°C'
            Precision        = 0
        
            Color            = '#2E86DE'
        
            MinimumPadding   = 1

            ChartType        = 'Trend'
            ShowArea         = $true
            ValueMode = 'Raw'
        
            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'TXPwr'
            DisplayName      = 'TX Power'
            Description      = 'Transmit optical power'

            Unit             = 'µW'
            Precision        = 0

            Color            = '#2ECC71'
            MinimumPadding   = 50
            ChartType        = 'Trend'
            ShowArea         = $true
            ValueMode = 'Raw'

            ReferenceMetric  = 'TXPwrLow'
            ReferenceName    = 'TX Low Limit'
            ReferenceColor   = '#E74C3C'
        }

        [PSCustomObject]@{
            Metric           = 'RXPwr'
            DisplayName      = 'RX Power'
            Description      = 'Receive optical power'

            Unit             = 'µW'
            Precision        = 0

            Color            = '#9B59B6'
            MinimumPadding   = 50
            ChartType        = 'Trend'
            ShowArea         = $true
            ValueMode = 'Raw'

            ReferenceMetric  = 'RXPwrLow'
            ReferenceName    = 'RX Low Limit'
            ReferenceColor   = '#E74C3C'
        }

        [PSCustomObject]@{
            Metric           = 'LinkFailure'
            DisplayName      = 'Link Failures'
            Description      = 'Accumulated link failures'

            Unit             = ''
            Precision        = 0

            Color            = '#34495E'
            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'LoseSync'
            DisplayName      = 'Loss of Sync'
            Description      = 'Loss of synchronization events'

            Unit             = ''
            Precision        = 0

            Color            = '#34495E'
            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'LoseSig'
            DisplayName      = 'Loss of Signal'
            Description      = 'Loss of signal events'

            Unit             = ''
            Precision        = 0

            Color            = '#34495E'
            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'PSErrCount'
            DisplayName      = 'Primitive Sequence Errors'
            Description      = 'Primitive sequence protocol errors'

            Unit             = ''
            Precision        = 0

            Color            = '#34495E'

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'InvTransErr'
            DisplayName      = 'Invalid Transmission Words'
            Description      = 'Invalid transmission words'

            Unit             = ''
            Precision        = 0

            Color            = '#34495E'

            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'CRCErr'
            DisplayName      = 'CRC Errors'
            Description      = 'CRC error counter'

            Unit             = ''
            Precision        = 0

            Color            = '#34495E'
            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

        [PSCustomObject]@{
            Metric           = 'ZeroBtB'
            DisplayName      = 'Zero BB Credit'
            Description      = 'Zero buffer-to-buffer credits'

            Unit             = ''
            Precision        = 0

            Color            = '#34495E'
            ChartType        = 'Counter'
            ShowArea         = $false
            ValueMode = 'Delta'

            ReferenceMetric  = $null
            ReferenceName    = $null
            ReferenceColor   = $null
        }

    )

    if ($All) {
        return $Metrics
    }

    return $Metrics |
        Where-Object Metric -eq $Metric |
        Select-Object -First 1
}