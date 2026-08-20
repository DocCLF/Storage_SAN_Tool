function Get-SANPortErrorHistoryPorts {
    <#
    .SYNOPSIS
        Returns all Brocade SAN ports with available port-error history.

    .DESCRIPTION
        Reads IBMSANPortErrorStatsTable and returns one object per unique
        SAN switch port.

        The result is intended for LiveCharts source selection controls.

        Each returned object contains:

            RowID
            SwitchName
            SerialNumber
            SwitchWWNN
            VFID
            Port
            FirstMeasurement
            LastMeasurement
            MeasurementCount
            DisplayName

        RowID is expected in the format:

            SerialNumber|VFID|Port

        Example:

            786713E|BASE|0/12

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER SerialNumber
        Optional switch serial-number filter.

    .PARAMETER SwitchName
        Optional switch-name filter.

    .PARAMETER VFID
        Optional Virtual Fabric ID filter.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        $Ports =
            Get-SANPortErrorHistoryPorts `
                -CustomerNbr '123456'

    .EXAMPLE
        $Ports =
            Get-SANPortErrorHistoryPorts `
                -CustomerNbr '123456' `
                -SerialNumber '786713E'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SwitchName,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$VFID
    )

    # ---------------------------------------------------------------------
    # Resolve customer database
    # ---------------------------------------------------------------------

    $DBPath =
        Join-Path `
            -Path $PSRootPath `
            -ChildPath "Resources\DBFolder\$CustomerNbr.db"

    if (
        -not (
            Test-Path `
                -LiteralPath $DBPath `
                -PathType Leaf
        )
    ) {
        throw "SQLite database not found: $DBPath"
    }

    $SQLiteConnection = $null
    $SQLiteCommand    = $null
    $SQLiteReader     = $null

    try {

        # -----------------------------------------------------------------
        # Open SQLite database
        # -----------------------------------------------------------------

        $ConnectionString =
            "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteConnection =
            [System.Data.SQLite.SQLiteConnection]::new(
                $ConnectionString
            )

        $SQLiteConnection.Open()

        $SQLiteCommand =
            $SQLiteConnection.CreateCommand()

        # -----------------------------------------------------------------
        # Build optional filters
        # -----------------------------------------------------------------

        $WhereClauses =
            [System.Collections.Generic.List[string]]::new()

        $WhereClauses.Add(
            'CustomerNbr = @CustomerNbr'
        )

        if (
            -not [string]::IsNullOrWhiteSpace(
                $SerialNumber
            )
        ) {
            $WhereClauses.Add(
                'SerialNumber = @SerialNumber'
            )
        }

        if (
            -not [string]::IsNullOrWhiteSpace(
                $SwitchName
            )
        ) {
            $WhereClauses.Add(
                'SwitchName = @SwitchName'
            )
        }

        if (
            -not [string]::IsNullOrWhiteSpace(
                $VFID
            )
        ) {
            $WhereClauses.Add(
                'VFID = @VFID'
            )
        }

        $WhereText =
            $WhereClauses -join "`n  AND "

        # -----------------------------------------------------------------
        # Return one Source per unique SAN port
        # -----------------------------------------------------------------

        $SQLiteCommand.CommandText = @"
SELECT
    RowID,
    SwitchName,
    SerialNumber,
    SwitchWWNN,
    VFID,
    Port,

    MIN(TimeStamp) AS FirstMeasurement,
    MAX(TimeStamp) AS LastMeasurement,
    COUNT(*) AS MeasurementCount

FROM IBMSANPortErrorStatsTable

WHERE $WhereText

GROUP BY
    RowID,
    SwitchName,
    SerialNumber,
    SwitchWWNN,
    VFID,
    Port

ORDER BY
    SwitchName ASC,
    SerialNumber ASC,
    VFID ASC,
    CAST(
        SUBSTR(
            Port,
            INSTR(Port, '/') + 1
        ) AS INTEGER
    ) ASC;
"@

        # -----------------------------------------------------------------
        # SQL parameters
        # -----------------------------------------------------------------

        $SQLiteCommand.Parameters.AddWithValue(
            '@CustomerNbr',
            $CustomerNbr
        ) | Out-Null

        if (
            -not [string]::IsNullOrWhiteSpace(
                $SerialNumber
            )
        ) {

            $SQLiteCommand.Parameters.AddWithValue(
                '@SerialNumber',
                $SerialNumber
            ) | Out-Null
        }

        if (
            -not [string]::IsNullOrWhiteSpace(
                $SwitchName
            )
        ) {

            $SQLiteCommand.Parameters.AddWithValue(
                '@SwitchName',
                $SwitchName
            ) | Out-Null
        }

        if (
            -not [string]::IsNullOrWhiteSpace(
                $VFID
            )
        ) {

            $SQLiteCommand.Parameters.AddWithValue(
                '@VFID',
                $VFID
            ) | Out-Null
        }

        # -----------------------------------------------------------------
        # Execute query
        # -----------------------------------------------------------------

        $SQLiteReader =
            $SQLiteCommand.ExecuteReader()

        $Result =
            while ($SQLiteReader.Read()) {

                # ---------------------------------------------------------
                # Read raw history-range values
                # ---------------------------------------------------------

                $FirstMeasurementRaw =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'FirstMeasurement'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader[
                            'FirstMeasurement'
                        ]
                    }

                $LastMeasurementRaw =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'LastMeasurement'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader[
                            'LastMeasurement'
                        ]
                    }

                # ---------------------------------------------------------
                # Convert timestamps
                #
                # SAN history starts with the new schema, therefore only
                # the current seconds format is expected.
                # ---------------------------------------------------------
$FirstMeasurement =
    ConvertFrom-SANSQLiteDateTime `
        -Value $FirstMeasurementRaw

$LastMeasurement =
    ConvertFrom-SANSQLiteDateTime `
        -Value $LastMeasurementRaw

                # ---------------------------------------------------------
                # Read Source information
                # ---------------------------------------------------------

                $RowIDValue =
                    [string]$SQLiteReader['RowID']

                $SwitchNameValue =
                    [string]$SQLiteReader['SwitchName']

                $SerialNumberValue =
                    [string]$SQLiteReader['SerialNumber']

                $SwitchWWNNValue =
                    [string]$SQLiteReader['SwitchWWNN']

                $VFIDValue =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'VFID'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader['VFID']
                    }

                $PortValue =
                    [string]$SQLiteReader['Port']

                $MeasurementCount =
                    [long]$SQLiteReader[
                        'MeasurementCount'
                    ]

                # For the current standalone switch support, only the actual
                # port number is required for display.
                #
                # Examples:
                #   0/0  -> 0
                #   0/12 -> 12
                #
                # The original Port value and RowID remain unchanged in the database.
                $DisplayPort =
                    if ($PortValue -match '^\d+/(\d+)$') {
                        $Matches[1]
                    }
                    else {
                        $PortValue
                    }

                    if (
                        [string]::IsNullOrWhiteSpace(
                            $VFIDValue
                        ) -or
                        $VFIDValue -eq 'BASE'
                    ) {
                    
                        $DisplayName =
                            '{0} – Port {1}' -f
                                $SwitchNameValue,
                                $DisplayPort
                    }
                    else {
                    
                        $DisplayName =
                            '{0} – VFID {1} – Port {2}' -f
                                $SwitchNameValue,
                                $VFIDValue,
                                $DisplayPort
                    }

                # ---------------------------------------------------------
                # Return Source object
                # ---------------------------------------------------------

                [PSCustomObject]@{
                    CustomerNbr      = $CustomerNbr

                    RowID            = $RowIDValue

                    SwitchName       = $SwitchNameValue
                    SerialNumber     = $SerialNumberValue
                    SwitchWWNN       = $SwitchWWNNValue

                    VFID             = $VFIDValue
                    Port             = $PortValue

                    FirstMeasurement = $FirstMeasurement
                    LastMeasurement  = $LastMeasurement
                    MeasurementCount = $MeasurementCount

                    DisplayName      = $DisplayName
                }
            }

        return $Result
    }
    catch {

        throw (
            'Reading the available SAN port-error histories failed: ' +
            "$($_.Exception.Message)"
        )
    }
    finally {

        if ($null -ne $SQLiteReader) {

            $SQLiteReader.Close()
            $SQLiteReader.Dispose()
        }

        if ($null -ne $SQLiteCommand) {

            $SQLiteCommand.Dispose()
        }

        if ($null -ne $SQLiteConnection) {

            if (
                $SQLiteConnection.State -ne
                [System.Data.ConnectionState]::Closed
            ) {

                $SQLiteConnection.Close()
            }

            $SQLiteConnection.Dispose()
        }

        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}