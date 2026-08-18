function Get-SANSFPHistory {
    <#
    .SYNOPSIS
        Returns historical SAN SFP measurements for one port.

    .DESCRIPTION
        Reads the historical SAN SFP measurements for one stable
        SAN port identified by RowID.

        RowID format:

            ChassisSN|VFID|Port

        Example:

            786713E|BASE|0/0

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER RowID
        Stable SAN SFP port identifier.

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range.

    .OUTPUTS
        PSCustomObject[]

    .EXAMPLE
        Get-SANSFPHistory `
            -CustomerNbr '349872' `
            -RowID '786713E|BASE|0/0' `
            -StartTime (Get-Date).AddDays(-1)
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$RowID,

        [datetime]$StartTime = (Get-Date).AddDays(-30),

        [datetime]$EndTime = (Get-Date)
    )

    if ($StartTime -gt $EndTime) {
        throw 'StartTime must not be later than EndTime.'
    }

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

    $SQLiteCommand = $null
    $Reader = $null

    try {

        $SQLiteDBConnection.Open()

        $SQLiteCommand =
            $SQLiteDBConnection.CreateCommand()

        $SQLiteCommand.CommandText = @"
SELECT
    ID,
    CustomerNbr,
    RowID,
    SwitchName,
    SerialNumber,
    SwitchWWNN,
    VFID,
    Port,
    SFPUsed,
    SFPTyp,
    Connector,
    Media,
    Vendor,
    PartNumber,
    SFPSerialNumber,
    SpeedRange,
    Temperature,
    RxPower,
    TxPower,
    Voltage,
    Wavelength,
    PowerOnTime,
    TimeStamp
FROM SANSFPStatsTable
WHERE CustomerNbr = @CustomerNbr
  AND RowID = @RowID
  AND TimeStamp >= @StartTime
  AND TimeStamp <= @EndTime
ORDER BY TimeStamp ASC, ID ASC;
"@

        $SQLiteCommand.Parameters.AddWithValue(
            '@CustomerNbr',
            $CustomerNbr
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@RowID',
            $RowID
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@StartTime',
            $StartTime.ToString(
                'yyyy-MM-dd HH:mm:ss',
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@EndTime',
            $EndTime.ToString(
                'yyyy-MM-dd HH:mm:ss',
                [System.Globalization.CultureInfo]::InvariantCulture
            )
        ) | Out-Null

        $Reader =
            $SQLiteCommand.ExecuteReader()

        $Result = @(
            while ($Reader.Read()) {

                # -----------------------------------------------------
                # Timestamp
                # -----------------------------------------------------

                $TimeStampRaw =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('TimeStamp')
                    )) {
                        $null
                    }
                    else {
                        [string]$Reader['TimeStamp']
                    }

                $TimeStamp =
                    $null

                if (
                    -not [string]::IsNullOrWhiteSpace(
                        $TimeStampRaw
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
                                $TimeStampRaw,
                                $Format,
                                [System.Globalization.CultureInfo]::InvariantCulture,
                                [System.Globalization.DateTimeStyles]::None,
                                [ref]$ParsedTime
                            )
                        ) {

                            $TimeStamp =
                                $ParsedTime

                            break
                        }
                    }

                    if ($null -eq $TimeStamp) {

                        $ParsedTime =
                            [datetime]::MinValue

                        if (
                            [datetime]::TryParse(
                                $TimeStampRaw,
                                [System.Globalization.CultureInfo]::InvariantCulture,
                                [System.Globalization.DateTimeStyles]::None,
                                [ref]$ParsedTime
                            )
                        ) {

                            $TimeStamp =
                                $ParsedTime
                        }
                    }
                }

                # -----------------------------------------------------
                # Numeric helper values
                # -----------------------------------------------------

                $Temperature =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('Temperature')
                    )) {
                        $null
                    }
                    else {
                        [double]$Reader['Temperature']
                    }

                $RxPower =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('RxPower')
                    )) {
                        $null
                    }
                    else {
                        [double]$Reader['RxPower']
                    }

                $TxPower =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('TxPower')
                    )) {
                        $null
                    }
                    else {
                        [double]$Reader['TxPower']
                    }

                $Voltage =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('Voltage')
                    )) {
                        $null
                    }
                    else {
                        [double]$Reader['Voltage']
                    }

                $Wavelength =
                    if ($Reader.IsDBNull(
                        $Reader.GetOrdinal('Wavelength')
                    )) {
                        $null
                    }
                    else {
                        [double]$Reader['Wavelength']
                    }

                # -----------------------------------------------------
                # Result object
                # -----------------------------------------------------

                [PSCustomObject]@{
                    ID =
                        [int64]$Reader['ID']

                    CustomerNbr =
                        [string]$Reader['CustomerNbr']

                    RowID =
                        [string]$Reader['RowID']

                    SwitchName =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('SwitchName')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['SwitchName']
                        }

                    SerialNumber =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('SerialNumber')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['SerialNumber']
                        }

                    SwitchWWNN =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('SwitchWWNN')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['SwitchWWNN']
                        }

                    VFID =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('VFID')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['VFID']
                        }

                    Port =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('Port')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['Port']
                        }

                    SFPUsed =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('SFPUsed')
                        )) {
                            $false
                        }
                        else {
                            [bool][int]$Reader['SFPUsed']
                        }

                    SFPTyp =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('SFPTyp')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['SFPTyp']
                        }

                    Connector =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('Connector')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['Connector']
                        }

                    Media =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('Media')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['Media']
                        }

                    Vendor =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('Vendor')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['Vendor']
                        }

                    PartNumber =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('PartNumber')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['PartNumber']
                        }

                    SFPSerialNumber =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('SFPSerialNumber')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['SFPSerialNumber']
                        }

                    SpeedRange =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('SpeedRange')
                        )) {
                            $null
                        }
                        else {
                            [string]$Reader['SpeedRange']
                        }

                    Temperature =
                        $Temperature

                    RxPower =
                        $RxPower

                    TxPower =
                        $TxPower

                    Voltage =
                        $Voltage

                    Wavelength =
                        $Wavelength

                    PowerOnTime =
                        if ($Reader.IsDBNull(
                            $Reader.GetOrdinal('PowerOnTime')
                        )) {
                            $null
                        }
                        else {
                            $Reader['PowerOnTime']
                        }

                    TimeStamp =
                        $TimeStamp
                }
            }
        )

        return $Result
    }
    catch {

        throw (
            "Reading SAN SFP history for RowID '$RowID' failed: " +
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