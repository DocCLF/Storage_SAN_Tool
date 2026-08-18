function Get-SANSFPHistoryPorts {
    <#
    .SYNOPSIS
        Returns available SAN SFP history ports for one customer.

    .DESCRIPTION
        Reads the available SAN SFP history sources from the customer
        SQLite database.

        One result object represents one stable SAN port identified by:

            ChassisSN|VFID|Port

        Example:

            786713E|BASE|0/0

        The latest known port and SFP metadata is returned together with
        the number of available measurements.

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .OUTPUTS
        PSCustomObject[]

    .EXAMPLE
        Get-SANSFPHistoryPorts -CustomerNbr '349872'
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr
    )

    $DBPath =
        Join-Path `
            $PSRootPath `
            "Resources\DBFolder\$CustomerNbr.db"

    if (-not (Test-Path -LiteralPath $DBPath)) {
        throw "Customer database '$DBPath' was not found."
    }

    $SQLiteConnectionString =
        "Data Source=$DBPath;Version=3;Pooling=False;"

    $SQLiteDBConnection =
        New-Object System.Data.SQLite.SQLiteConnection(
            $SQLiteConnectionString
        )

    $SQLiteCommand =
        $null

    $Reader =
        $null

    try {

        $SQLiteDBConnection.Open()

        $SQLiteCommand =
            $SQLiteDBConnection.CreateCommand()

        # -------------------------------------------------------------
        # Return one row per stable SAN port.
        #
        # The correlated subqueries retrieve the latest known metadata
        # for that RowID while COUNT(*) reflects the complete history.
        # -------------------------------------------------------------

        $SQLiteCommand.CommandText = @"
SELECT
    s.RowID,

    (
        SELECT x.SwitchName
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS SwitchName,

    (
        SELECT x.SerialNumber
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS SerialNumber,

    (
        SELECT x.SwitchWWNN
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS SwitchWWNN,

    (
        SELECT x.VFID
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS VFID,

    (
        SELECT x.Port
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS Port,

    (
        SELECT x.SFPUsed
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS SFPUsed,

    (
        SELECT x.SFPTyp
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS SFPTyp,

    (
        SELECT x.Vendor
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS Vendor,

    (
        SELECT x.PartNumber
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS PartNumber,

    (
        SELECT x.SFPSerialNumber
        FROM SANSFPStatsTable x
        WHERE x.CustomerNbr = s.CustomerNbr
          AND x.RowID = s.RowID
        ORDER BY x.TimeStamp DESC, x.ID DESC
        LIMIT 1
    ) AS SFPSerialNumber,

    COUNT(*) AS MeasurementCount,

    MAX(s.TimeStamp) AS LastTimeStamp

FROM SANSFPStatsTable s

WHERE s.CustomerNbr = @CustomerNbr

GROUP BY
    s.CustomerNbr,
    s.RowID

ORDER BY
    SwitchName,
    Port;
"@

        $SQLiteCommand.Parameters.AddWithValue(
            '@CustomerNbr',
            $CustomerNbr
        ) | Out-Null

        $Reader =
            $SQLiteCommand.ExecuteReader()

        $Result = @(
            while ($Reader.Read()) {

                $RowID =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('RowID')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['RowID']
                    }

                $SwitchName =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('SwitchName')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['SwitchName']
                    }

                $SerialNumber =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('SerialNumber')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['SerialNumber']
                    }

                $SwitchWWNN =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('SwitchWWNN')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['SwitchWWNN']
                    }

                $VFID =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('VFID')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['VFID']
                    }

                $Port =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('Port')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['Port']
                    }

                $SFPUsed =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('SFPUsed')
                    )) {
                        $false
                    }
                    else {
                        [bool][int]$Reader['SFPUsed']
                    }

                $SFPTyp =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('SFPTyp')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['SFPTyp']
                    }

                $Vendor =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('Vendor')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['Vendor']
                    }

                $PartNumber =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('PartNumber')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['PartNumber']
                    }

                $SFPSerialNumber =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('SFPSerialNumber')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['SFPSerialNumber']
                    }

                $MeasurementCount =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('MeasurementCount')
                    )) {
                        0
                    }
                    else {
                        [int]$Reader['MeasurementCount']
                    }

                $LastTimeStampRaw =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('LastTimeStamp')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['LastTimeStamp']
                    }

                $LastTimeStamp =
                    $null

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        $LastTimeStampRaw
                    )
                ) {

                    $Formats = @(
                        'yyyy-MM-dd HH:mm:ss'
                        'yyyy-MM-dd HH:mm'
                    )

                    foreach ($Format in $Formats) {

                        $ParsedTime =
                            [datetime]::MinValue

                        if (
                            [datetime]::TryParseExact(
                                $LastTimeStampRaw,
                                $Format,
                                [System.Globalization.CultureInfo]::InvariantCulture,
                                [System.Globalization.DateTimeStyles]::None,
                                [ref]$ParsedTime
                            )
                        ) {

                            $LastTimeStamp =
                                $ParsedTime

                            break
                        }
                    }

                    if ($null -eq $LastTimeStamp) {

                        $ParsedTime =
                            [datetime]::MinValue

                        if (
                            [datetime]::TryParse(
                                $LastTimeStampRaw,
                                [System.Globalization.CultureInfo]::InvariantCulture,
                                [System.Globalization.DateTimeStyles]::None,
                                [ref]$ParsedTime
                            )
                        ) {

                            $LastTimeStamp =
                                $ParsedTime
                        }
                    }
                }

                # -----------------------------------------------------
                # Short port display
                #
                # "0/12" becomes "12" because fixed-port Brocade
                # switches are currently supported here.
                # -----------------------------------------------------

                $PortDisplay =
                    $Port

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        $PortDisplay
                    ) -and
                    $PortDisplay -match '^\d+/(.+)$'
                ) {

                    $PortDisplay =
                        $Matches[1]
                }

                if (
                    [string]::IsNullOrWhiteSpace(
                        $SwitchName
                    )
                ) {

                    $SwitchName =
                        "Unknown_$SerialNumber"
                }

                $DisplayName =
                    '{0} – Port {1}' -f
                        $SwitchName,
                        $PortDisplay

                [PSCustomObject]@{
                    RowID            = $RowID
                    SwitchName       = $SwitchName
                    SerialNumber     = $SerialNumber
                    SwitchWWNN       = $SwitchWWNN
                    VFID             = $VFID
                    Port             = $Port
                    PortDisplay      = $PortDisplay
                    SFPUsed          = $SFPUsed
                    SFPTyp           = $SFPTyp
                    Vendor           = $Vendor
                    PartNumber       = $PartNumber
                    SFPSerialNumber  = $SFPSerialNumber
                    MeasurementCount = $MeasurementCount
                    LastTimeStamp    = $LastTimeStamp
                    DisplayName      = $DisplayName
                }
            }
        )

        return $Result
    }
    catch {

        throw (
            'Reading the available SAN SFP history ports failed: ' +
            $_.Exception.Message
        )
    }
    finally {

        if ($null -ne $Reader) {
            $Reader.Dispose()
        }

        if ($null -ne $SQLiteCommand) {
            $SQLiteCommand.Dispose()
        }

        if ($null -ne $SQLiteDBConnection) {

            if (
                $SQLiteDBConnection.State -ne
                [System.Data.ConnectionState]::Closed
            ) {
                $SQLiteDBConnection.Close()
            }

            $SQLiteDBConnection.Dispose()
        }

        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}