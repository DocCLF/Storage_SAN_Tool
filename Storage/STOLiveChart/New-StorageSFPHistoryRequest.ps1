function New-StorageSFPHistoryRequest {
    <#
    .SYNOPSIS
        Creates a request for a Storage SFP history chart.

    .DESCRIPTION
        Creates a normalized request object for one or multiple Storage
        FC ports.

        A request can be created either with RowID for one port or with
        RowIDs for one to four ports.

        The returned object always contains both properties:

            RowID
            RowIDs

        RowID contains the first selected port and preserves compatibility
        with existing single-port code.

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER RowID
        Stable identifier of one Storage FC port.

    .PARAMETER RowIDs
        Stable identifiers of one to four Storage FC ports.

    .PARAMETER Metric
        Metric property to display.

    .PARAMETER StartTime
        Beginning of the requested period.

    .PARAMETER EndTime
        End of the requested period.

    .PARAMETER DateTimeLabelFormat
        Format used for labels on the X axis.

    .PARAMETER DateTimeStep
        Minimum distance between labels on the X axis.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        $Request = New-StorageSFPHistoryRequest `
            -CustomerNbr '123456' `
            -RowID 'SERIAL|WWNN|WWPN' `
            -Metric 'SFPTemp' `
            -StartTime (Get-Date).AddDays(-1) `
            -EndTime (Get-Date)

    .EXAMPLE
        $Request = New-StorageSFPHistoryRequest `
            -CustomerNbr '123456' `
            -RowIDs @(
                'SERIAL|WWNN|WWPN1'
                'SERIAL|WWNN|WWPN2'
            ) `
            -Metric 'TXPwr' `
            -StartTime (Get-Date).AddDays(-7) `
            -EndTime (Get-Date)
    #>

    [CmdletBinding(DefaultParameterSetName = 'SinglePort')]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(
            Mandatory,
            ParameterSetName = 'SinglePort'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$RowID,

        [Parameter(
            Mandatory,
            ParameterSetName = 'MultiplePorts'
        )]
        [ValidateNotNull()]
        [string[]]$RowIDs,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Metric,

        [Parameter(Mandatory)]
        [datetime]$StartTime,

        [Parameter(Mandatory)]
        [datetime]$EndTime,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DateTimeLabelFormat,

        [Parameter(Mandatory)]
        [TimeSpan]$DateTimeStep
    )

    if ($StartTime -gt $EndTime) {
        throw 'StartTime must not be later than EndTime.'
    }

    if ($DateTimeStep -le [TimeSpan]::Zero) {
        throw 'DateTimeStep must be greater than zero.'
    }

    # Unabhängig vom verwendeten Parametersatz immer ein Array erzeugen.
    $NormalizedRowIDs = @()

    if ($PSCmdlet.ParameterSetName -eq 'SinglePort') {
        $NormalizedRowIDs = @(
            [string]$RowID
        )
    }
    else {
        $NormalizedRowIDs = @(
            foreach ($CurrentRowID in $RowIDs) {
                if (
                    -not [string]::IsNullOrWhiteSpace(
                        [string]$CurrentRowID
                    )
                ) {
                    [string]$CurrentRowID
                }
            }
        )
    }

    if ($NormalizedRowIDs.Count -eq 0) {
        throw 'At least one valid RowID must be supplied.'
    }

    # Doppelte Ports entfernen, Reihenfolge aber beibehalten.
    $UniqueRowIDs = @(
        $NormalizedRowIDs |
            Select-Object -Unique
    )

    if ($UniqueRowIDs.Count -gt 4) {
        throw (
            'A maximum of four Storage FC ports can be compared. ' +
            "$($UniqueRowIDs.Count) RowIDs were supplied."
        )
    }

    [PSCustomObject]@{
        CustomerNbr         = $CustomerNbr

        # Rückwärtskompatibilität für den bisherigen Single-Port-Code.
        RowID               = [string]$UniqueRowIDs[0]

        # Neue gemeinsame Schnittstelle für Single und Multi.
        RowIDs              = [string[]]$UniqueRowIDs

        Metric              = $Metric
        StartTime           = $StartTime
        EndTime             = $EndTime
        DateTimeLabelFormat = $DateTimeLabelFormat
        DateTimeStep        = $DateTimeStep

        IsComparison        = ($UniqueRowIDs.Count -gt 1)
        PortCount           = $UniqueRowIDs.Count
    }
}