function Get-SQLiteNullableDouble {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Reader,

        [Parameter(Mandatory)]
        [string]$ColumnName
    )

    $Ordinal = $Reader.GetOrdinal($ColumnName)

    if ($Reader.IsDBNull($Ordinal)) {
        return $null
    }

    return [double]$Reader.GetValue($Ordinal)
}
function Get-SQLiteNullableInt64 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Reader,

        [Parameter(Mandatory)]
        [string]$ColumnName
    )

    $Ordinal = $Reader.GetOrdinal($ColumnName)

    if ($Reader.IsDBNull($Ordinal)) {
        return $null
    }

    return [long]$Reader.GetValue($Ordinal)
}
function Get-SFPHistory {
    <#
    .SYNOPSIS
        Reads the stored history of one IBM Storage FC port.

    .DESCRIPTION
        Returns all stored SFP measurements and cumulative port error
        counters for one FC port within the requested time range.

        The function returns normal PowerShell objects and does not create
        any LiveCharts objects.

    .PARAMETER CustomerNbr
        Customer number used to locate the corresponding SQLite database.

    .PARAMETER RowID
        Stable port identifier in the format:

        SerialNumber|WWNN|WWPN

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range. Defaults to the current time.

    .EXAMPLE
        $History = Get-SFPHistory `
            -CustomerNbr '123456' `
            -RowID '78F27FR|5005076815000ADC|5005076815110adc' `
            -StartTime (Get-Date).AddDays(-30)

    .OUTPUTS
        PSCustomObject
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

    $DBPath = Join-Path `
        -Path $PSRootPath `
        -ChildPath "Resources\DBFolder\$CustomerNbr.db"

    if (-not (Test-Path -LiteralPath $DBPath -PathType Leaf)) {
        throw "SQLite database not found: $DBPath"
    }

    $SQLiteConnection = $null
    $SQLiteCommand    = $null
    $SQLiteReader     = $null

    try {
        $ConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteConnection =
            [System.Data.SQLite.SQLiteConnection]::new($ConnectionString)

        $SQLiteConnection.Open()

        $SQLiteCommand = $SQLiteConnection.CreateCommand()

        $SQLiteCommand.CommandText = @"
SELECT
    ID,
    CustomerNbr,
    RowID,
    NodeID,
    NodeName,
    CardType,
    CardID,
    PortID,
    WWPN,

    LinkFailure,
    LoseSync,
    LoseSig,
    PSErrCount,
    InvTransErr,
    CRCErr,
    ZeroBtB,

    SFPTemp,
    TXPwr,
    TXPwrLow,
    RXPwr,
    RXPwrLow,

    SerialNumber,
    WWNN,
    TimeStamp
FROM IBMSTOFCPortStatsTable
WHERE CustomerNbr = @CustomerNbr
  AND RowID        = @RowID
  AND TimeStamp   >= @StartTime
  AND TimeStamp   <= @EndTime
ORDER BY TimeStamp ASC;
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
            $StartTime.ToString('yyyy-MM-dd HH:mm:ss')
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@EndTime',
            $EndTime.ToString('yyyy-MM-dd HH:mm:ss')
        ) | Out-Null

        $SQLiteReader = $SQLiteCommand.ExecuteReader()

        $Result = while ($SQLiteReader.Read()) {
            [PSCustomObject]@{
                ID = if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('ID')
                    )) {
                    $null
                }
                else {
                    [long]$SQLiteReader['ID']
                }

                CustomerNbr = [string]$SQLiteReader['CustomerNbr']
                RowID       = [string]$SQLiteReader['RowID']

                NodeID = if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('NodeID')
                    )) {
                    $null
                }
                else {
                    [string]$SQLiteReader['NodeID']
                }

                NodeName = if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('NodeName')
                    )) {
                    $null
                }
                else {
                    [string]$SQLiteReader['NodeName']
                }

                CardType = if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('CardType')
                    )) {
                    $null
                }
                else {
                    [string]$SQLiteReader['CardType']
                }

                CardID = if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('CardID')
                    )) {
                    $null
                }
                else {
                    [long]$SQLiteReader['CardID']
                }

                PortID = if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('PortID')
                    )) {
                    $null
                }
                else {
                    [long]$SQLiteReader['PortID']
                }

                WWPN = [string]$SQLiteReader['WWPN']

                LinkFailure = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'LinkFailure'

                LoseSync = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'LoseSync'

                LoseSig = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'LoseSig'

                PSErrCount = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'PSErrCount'

                InvTransErr = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'InvTransErr'

                CRCErr = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'CRCErr'

                ZeroBtB = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'ZeroBtB'

                SFPTemp = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'SFPTemp'

                TXPwr = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'TXPwr'

                TXPwrLow = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'TXPwrLow'

                RXPwr = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'RXPwr'

                RXPwrLow = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'RXPwrLow'

                SerialNumber = [string]$SQLiteReader['SerialNumber']
                WWNN         = [string]$SQLiteReader['WWNN']

                TimeStamp = [datetime]::ParseExact(
                    [string]$SQLiteReader['TimeStamp'],
                    'yyyy-MM-dd HH:mm:ss',
                    [System.Globalization.CultureInfo]::InvariantCulture
                )
            }
        }

        return $Result
    }
    catch {
        throw "Reading the SFP history failed: $($_.Exception.Message)"
    }
    finally {
        if ($SQLiteReader) {
            $SQLiteReader.Close()
            $SQLiteReader.Dispose()
        }

        if ($SQLiteCommand) {
            $SQLiteCommand.Dispose()
        }

        if ($SQLiteConnection) {
            $SQLiteConnection.Close()
            $SQLiteConnection.Dispose()
        }

        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}
function Get-StorageSFPHistoryPorts {
    <#
    .SYNOPSIS
        Returns all Storage FC ports with available SFP history data.

    .DESCRIPTION
        Reads the IBMSTOFCPortStatsTable and returns one object per unique
        Storage FC port.

        The result is intended for GUI selection controls such as a ComboBox.
        It contains the stable RowID, Storage and node information, WWPN and
        basic information about the available history range.

    .PARAMETER CustomerNbr
        Customer number used to locate the corresponding SQLite database.

    .PARAMETER SerialNumber
        Optional Storage serial-number filter.

    .PARAMETER NodeID
        Optional node filter.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        $Ports = Get-StorageSFPHistoryPorts -CustomerNbr '123456'

    .EXAMPLE
        $Ports = Get-StorageSFPHistoryPorts `
            -CustomerNbr '123456' `
            -SerialNumber '78F27FR'
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
        [string]$NodeID
    )

    $DBPath = Join-Path `
        -Path $PSRootPath `
        -ChildPath "Resources\DBFolder\$CustomerNbr.db"

    if (-not (Test-Path -LiteralPath $DBPath -PathType Leaf)) {
        throw "SQLite database not found: $DBPath"
    }

    $SQLiteConnection = $null
    $SQLiteCommand    = $null
    $SQLiteReader     = $null

    try {
        $ConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteConnection =
            [System.Data.SQLite.SQLiteConnection]::new($ConnectionString)

        $SQLiteConnection.Open()

        $SQLiteCommand = $SQLiteConnection.CreateCommand()

        $WhereClauses = [System.Collections.Generic.List[string]]::new()

        $WhereClauses.Add('CustomerNbr = @CustomerNbr')

        if (-not [string]::IsNullOrWhiteSpace($SerialNumber)) {
            $WhereClauses.Add('SerialNumber = @SerialNumber')
        }

        if (-not [string]::IsNullOrWhiteSpace($NodeID)) {
            $WhereClauses.Add('NodeID = @NodeID')
        }

        $WhereText = $WhereClauses -join "`n  AND "

        $SQLiteCommand.CommandText = @"
SELECT
    RowID,
    SerialNumber,
    NodeID,
    NodeName,
    CardType,
    CardID,
    PortID,
    WWNN,
    WWPN,
    MIN(TimeStamp) AS FirstMeasurement,
    MAX(TimeStamp) AS LastMeasurement,
    COUNT(*) AS MeasurementCount
FROM IBMSTOFCPortStatsTable
WHERE $WhereText
GROUP BY
    RowID,
    SerialNumber,
    NodeID,
    NodeName,
    CardType,
    CardID,
    PortID,
    WWNN,
    WWPN
ORDER BY
    SerialNumber ASC,
    CAST(NodeID AS INTEGER) ASC,
    CAST(PortID AS INTEGER) ASC;
"@

        $SQLiteCommand.Parameters.AddWithValue(
            '@CustomerNbr',
            $CustomerNbr
        ) | Out-Null

        if (-not [string]::IsNullOrWhiteSpace($SerialNumber)) {
            $SQLiteCommand.Parameters.AddWithValue(
                '@SerialNumber',
                $SerialNumber
            ) | Out-Null
        }

        if (-not [string]::IsNullOrWhiteSpace($NodeID)) {
            $SQLiteCommand.Parameters.AddWithValue(
                '@NodeID',
                $NodeID
            ) | Out-Null
        }

        $SQLiteReader = $SQLiteCommand.ExecuteReader()

        $Result = while ($SQLiteReader.Read()) {
            $FirstMeasurementRaw =
                if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('FirstMeasurement')
                    )) {
                    $null
                }
                else {
                    [string]$SQLiteReader['FirstMeasurement']
                }

            $LastMeasurementRaw =
                if ($SQLiteReader.IsDBNull(
                        $SQLiteReader.GetOrdinal('LastMeasurement')
                    )) {
                    $null
                }
                else {
                    [string]$SQLiteReader['LastMeasurement']
                }

            $FirstMeasurement =
                if ([string]::IsNullOrWhiteSpace($FirstMeasurementRaw)) {
                    $null
                }
                else {
                    [datetime]::ParseExact(
                        $FirstMeasurementRaw,
                        'yyyy-MM-dd HH:mm:ss',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                }

            $LastMeasurement =
                if ([string]::IsNullOrWhiteSpace($LastMeasurementRaw)) {
                    $null
                }
                else {
                    [datetime]::ParseExact(
                        $LastMeasurementRaw,
                        'yyyy-MM-dd HH:mm:ss',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                }

            $RowIDValue        = [string]$SQLiteReader['RowID']
            $SerialValue       = [string]$SQLiteReader['SerialNumber']
            $NodeIDValue       = [string]$SQLiteReader['NodeID']
            $NodeNameValue     = [string]$SQLiteReader['NodeName']
            $CardTypeValue     = [string]$SQLiteReader['CardType']
            $CardIDValue       = [string]$SQLiteReader['CardID']
            $PortIDValue       = [string]$SQLiteReader['PortID']
            $WWNNValue         = [string]$SQLiteReader['WWNN']
            $WWPNValue         = [string]$SQLiteReader['WWPN']
            $MeasurementCount  = [long]$SQLiteReader['MeasurementCount']

            [PSCustomObject]@{
                CustomerNbr     = $CustomerNbr
                RowID           = $RowIDValue
                SerialNumber    = $SerialValue
                NodeID          = $NodeIDValue
                NodeName        = $NodeNameValue
                CardType        = $CardTypeValue
                CardID          = $CardIDValue
                PortID          = $PortIDValue
                WWNN            = $WWNNValue
                WWPN            = $WWPNValue

                FirstMeasurement = $FirstMeasurement
                LastMeasurement  = $LastMeasurement
                MeasurementCount = $MeasurementCount

                DisplayName = '{0} – Port {1} – {2}' -f (
                    $NodeNameValue,
                    $PortIDValue,
                    $WWPNValue
                )
            }
        }

        return $Result
    }
    catch {
        throw "Reading the available Storage SFP history ports failed: $($_.Exception.Message)"
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