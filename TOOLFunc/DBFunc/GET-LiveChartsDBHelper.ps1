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

function Get-StoragePoolCapacityHistory {
    <#
    .SYNOPSIS
        Reads the stored capacity history of one IBM Storage pool.

    .DESCRIPTION
        Returns all stored capacity measurements for one Storage pool
        within the requested time range.

        Capacity values are returned as Int64 byte values.

        The function returns normal PowerShell objects and does not create
        any LiveCharts objects.

    .PARAMETER CustomerNbr
        Customer number used to locate the corresponding SQLite database.

    .PARAMETER RowID
        Stable pool identifier in the format:

            SerialNumber|PoolID

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        $History = Get-StoragePoolCapacityHistory `
            -CustomerNbr '123456' `
            -RowID '78F27FR|0' `
            -StartTime (Get-Date).AddDays(-30)
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
        $ConnectionString =
            "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteConnection =
            [System.Data.SQLite.SQLiteConnection]::new(
                $ConnectionString
            )

        $SQLiteConnection.Open()

        $SQLiteCommand =
            $SQLiteConnection.CreateCommand()

        $SQLiteCommand.CommandText = @"
SELECT
    ID,
    CustomerNbr,
    RowID,
    PoolID,
    PoolName,

    Capacity,
    FreeCapacity,
    VirtualCapacity,
    UsedCapacity,
    RealCapacity,
    Overallocation,

    SerialNumber,
    WWNN,
    TimeStamp
FROM IBMSTOPoolCapacityTable
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
            $StartTime.ToString(
                'yyyy-MM-dd HH:mm:ss'
            )
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@EndTime',
            $EndTime.ToString(
                'yyyy-MM-dd HH:mm:ss'
            )
        ) | Out-Null

        $SQLiteReader =
            $SQLiteCommand.ExecuteReader()

        $Result = while ($SQLiteReader.Read()) {

            [PSCustomObject]@{
                ID = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'ID'

                CustomerNbr =
                    [string]$SQLiteReader['CustomerNbr']

                RowID =
                    [string]$SQLiteReader['RowID']

                PoolID =
                    [string]$SQLiteReader['PoolID']

                PoolName =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'PoolName'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader['PoolName']
                    }

                Capacity = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'Capacity'

                FreeCapacity = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'FreeCapacity'

                VirtualCapacity = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'VirtualCapacity'

                UsedCapacity = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'UsedCapacity'

                RealCapacity = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'RealCapacity'

                Overallocation = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'Overallocation'

                SerialNumber =
                    [string]$SQLiteReader['SerialNumber']

                WWNN =
                    [string]$SQLiteReader['WWNN']

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
        throw (
            "Reading the Storage pool capacity history failed: " +
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
function Get-StoragePoolHistoryPools {
    <#
    .SYNOPSIS
        Returns all Storage pools with available capacity history.

    .DESCRIPTION
        Reads IBMSTOPoolCapacityTable and returns one object per unique
        Storage pool.

        The result is intended for GUI selection controls and contains
        the stable RowID, pool information and the available history range.

    .PARAMETER CustomerNbr
        Customer number used to locate the corresponding SQLite database.

    .PARAMETER SerialNumber
        Optional Storage serial-number filter.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber
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
        $ConnectionString =
            "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteConnection =
            [System.Data.SQLite.SQLiteConnection]::new(
                $ConnectionString
            )

        $SQLiteConnection.Open()

        $SQLiteCommand =
            $SQLiteConnection.CreateCommand()

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

        $WhereText =
            $WhereClauses -join "`n  AND "

        $SQLiteCommand.CommandText = @"
SELECT
    RowID,
    PoolID,
    PoolName,
    SerialNumber,
    WWNN,

    MIN(TimeStamp) AS FirstMeasurement,
    MAX(TimeStamp) AS LastMeasurement,
    COUNT(*) AS MeasurementCount

FROM IBMSTOPoolCapacityTable
WHERE $WhereText

GROUP BY
    RowID,
    PoolID,
    PoolName,
    SerialNumber,
    WWNN

ORDER BY
    SerialNumber ASC,
    CAST(PoolID AS INTEGER) ASC;
"@

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

        $SQLiteReader =
            $SQLiteCommand.ExecuteReader()

        $Result = while ($SQLiteReader.Read()) {

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

            $FirstMeasurement =
                if (
                    [string]::IsNullOrWhiteSpace(
                        $FirstMeasurementRaw
                    )
                ) {
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
                if (
                    [string]::IsNullOrWhiteSpace(
                        $LastMeasurementRaw
                    )
                ) {
                    $null
                }
                else {
                    [datetime]::ParseExact(
                        $LastMeasurementRaw,
                        'yyyy-MM-dd HH:mm:ss',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                }

            $RowIDValue =
                [string]$SQLiteReader['RowID']

            $PoolIDValue =
                [string]$SQLiteReader['PoolID']

            $PoolNameValue =
                [string]$SQLiteReader['PoolName']

            $SerialValue =
                [string]$SQLiteReader['SerialNumber']

            $WWNNValue =
                [string]$SQLiteReader['WWNN']

            $MeasurementCount =
                [long]$SQLiteReader['MeasurementCount']

            [PSCustomObject]@{
                CustomerNbr      = $CustomerNbr
                RowID            = $RowIDValue
                PoolID           = $PoolIDValue
                PoolName         = $PoolNameValue
                SerialNumber     = $SerialValue
                WWNN             = $WWNNValue

                FirstMeasurement = $FirstMeasurement
                LastMeasurement  = $LastMeasurement
                MeasurementCount = $MeasurementCount

                DisplayName = '{0} – Pool {1} – {2}' -f (
                    $SerialValue,
                    $PoolIDValue,
                    $PoolNameValue
                )
            }
        }

        return $Result
    }
    catch {
        throw (
            "Reading the available Storage pool histories failed: " +
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

function Get-StorageVolumeAnalysisHistory {
    <#
    .SYNOPSIS
        Reads the stored analysis history of one IBM Storage volume.

    .DESCRIPTION
        Resolves the supplied RowID against IBMSTOVolumeInventoryTable and
        uses the permanent volume identity for the actual history query:

            CustomerNbr
            SerialNumber
            VdiskUID

        RowID is kept as the external selector key so existing GUI and
        LiveCharts code does not need to change immediately.

        Capacity values are returned as Int64 byte values.
        Ratio and margin values are returned as Double values.

    .PARAMETER CustomerNbr
        Customer number used to locate the corresponding SQLite database.

    .PARAMETER RowID
        Current inventory RowID in the format:

            SerialNumber|VOLUME|VolumeID

        RowID is used only to resolve the current inventory object.

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        $History = Get-StorageVolumeAnalysisHistory `
            -CustomerNbr '123456' `
            -RowID '78F27FR|VOLUME|0' `
            -StartTime (Get-Date).AddDays(-30)
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

        $ConnectionString =
            "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteConnection =
            [System.Data.SQLite.SQLiteConnection]::new(
                $ConnectionString
            )

        $SQLiteConnection.Open()

        # -------------------------------------------------------------
        # Resolve current inventory identity from RowID.
        #
        # RowID is only the GUI/source selector key.
        #
        # Permanent identity:
        #
        #   CustomerNbr
        #   SerialNumber
        #   VdiskUID
        # -------------------------------------------------------------

        $SQLiteCommand =
            $SQLiteConnection.CreateCommand()

        $SQLiteCommand.CommandText = @"
SELECT
    SerialNumber,
    VdiskUID,
    VolumeID,
    VolumeName,
    RowID,
    WWNN
FROM IBMSTOVolumeInventoryTable
WHERE
    CustomerNbr = @CustomerNbr
    AND RowID = @RowID
    AND IsActive = 1
LIMIT 1;
"@

        $SQLiteCommand.Parameters.AddWithValue(
            '@CustomerNbr',
            $CustomerNbr
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@RowID',
            $RowID
        ) | Out-Null

        $SQLiteReader =
            $SQLiteCommand.ExecuteReader()

        if (-not $SQLiteReader.Read()) {

            throw (
                "No active Storage volume inventory entry was found " +
                "for RowID '$RowID'."
            )
        }

        $ResolvedSerialNumber =
            [string]$SQLiteReader['SerialNumber']

        $ResolvedVdiskUID =
            [string]$SQLiteReader['VdiskUID']

        $ResolvedVolumeID =
            [string]$SQLiteReader['VolumeID']

        $ResolvedVolumeName =
            [string]$SQLiteReader['VolumeName']

        $ResolvedWWNN =
            [string]$SQLiteReader['WWNN']

        $SQLiteReader.Close()
        $SQLiteReader.Dispose()
        $SQLiteReader = $null

        $SQLiteCommand.Dispose()
        $SQLiteCommand = $null

        if (
            [string]::IsNullOrWhiteSpace(
                $ResolvedVdiskUID
            )
        ) {

            throw (
                "The active inventory entry for RowID '$RowID' " +
                'does not contain a VdiskUID.'
            )
        }

        # -------------------------------------------------------------
        # Read history through permanent volume identity.
        # -------------------------------------------------------------

        $SQLiteCommand =
            $SQLiteConnection.CreateCommand()

        $SQLiteCommand.CommandText = @"
SELECT
    ID,
    CustomerNbr,
    RowID,
    VolumeID,
    VdiskUID,
    VolumeName,
    State,
    AnalysisTime,

    Capacity,
    ThinSize,
    ThinSavings,
    ThinSavingsRatio,
    CompressedSize,
    CompressionSavings,
    CompressionSavingsRatio,
    TotalSavings,
    TotalSavingsRatio,
    MarginOfError,

    SerialNumber,
    WWNN,
    TimeStamp

FROM IBMSTOVolumeAnalysisTable

WHERE
    CustomerNbr  = @CustomerNbr
    AND SerialNumber = @SerialNumber
    AND VdiskUID = @VdiskUID
    AND TimeStamp >= @StartTime
    AND TimeStamp <= @EndTime

ORDER BY
    TimeStamp ASC;
"@

        $SQLiteCommand.Parameters.AddWithValue(
            '@CustomerNbr',
            $CustomerNbr
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@SerialNumber',
            $ResolvedSerialNumber
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@VdiskUID',
            $ResolvedVdiskUID
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@StartTime',
            $StartTime.ToString(
                'yyyy-MM-dd HH:mm:ss'
            )
        ) | Out-Null

        $SQLiteCommand.Parameters.AddWithValue(
            '@EndTime',
            $EndTime.ToString(
                'yyyy-MM-dd HH:mm:ss'
            )
        ) | Out-Null

        $SQLiteReader =
            $SQLiteCommand.ExecuteReader()

        $Result = while ($SQLiteReader.Read()) {

            [PSCustomObject]@{
                ID = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'ID'

                CustomerNbr =
                    [string]$SQLiteReader['CustomerNbr']

                RowID =
                    [string]$SQLiteReader['RowID']

                VolumeID =
                    [string]$SQLiteReader['VolumeID']

                VdiskUID =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'VdiskUID'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader['VdiskUID']
                    }

                VolumeName =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'VolumeName'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader['VolumeName']
                    }

                State =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'State'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader['State']
                    }

                AnalysisTime =
                    if (
                        $SQLiteReader.IsDBNull(
                            $SQLiteReader.GetOrdinal(
                                'AnalysisTime'
                            )
                        )
                    ) {
                        $null
                    }
                    else {
                        [string]$SQLiteReader['AnalysisTime']
                    }

                Capacity = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'Capacity'

                ThinSize = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'ThinSize'

                ThinSavings = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'ThinSavings'

                ThinSavingsRatio = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'ThinSavingsRatio'

                CompressedSize = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'CompressedSize'

                CompressionSavings = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'CompressionSavings'

                CompressionSavingsRatio = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'CompressionSavingsRatio'

                TotalSavings = Get-SQLiteNullableInt64 `
                    -Reader $SQLiteReader `
                    -ColumnName 'TotalSavings'

                TotalSavingsRatio = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'TotalSavingsRatio'

                MarginOfError = Get-SQLiteNullableDouble `
                    -Reader $SQLiteReader `
                    -ColumnName 'MarginOfError'

                SerialNumber =
                    [string]$SQLiteReader['SerialNumber']

                WWNN =
                    [string]$SQLiteReader['WWNN']

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

        throw (
            "Reading the Storage volume analysis history failed: " +
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

function Get-StorageVolumeHistoryVolumes {
    <#
    .SYNOPSIS
        Returns all active Storage volumes with available analysis history.

    .DESCRIPTION
        Uses IBMSTOVolumeInventoryTable as the authoritative source for
        the current Storage volume identity.

        The permanent identity of a volume is:

            CustomerNbr
            SerialNumber
            VdiskUID

        IBMSTOVolumeAnalysisTable is joined only to determine the
        available history range and measurement count.

        This prevents renamed volumes from appearing as separate
        volumes in the LiveCharts source selector.

        Inactive/deleted volumes are not returned.

    .PARAMETER CustomerNbr
        Customer number used to locate the corresponding SQLite database.

    .PARAMETER SerialNumber
        Optional Storage serial-number filter.

    .OUTPUTS
        PSCustomObject
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$SerialNumber
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

        $ConnectionString =
            "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteConnection =
            [System.Data.SQLite.SQLiteConnection]::new(
                $ConnectionString
            )

        $SQLiteConnection.Open()

        $SQLiteCommand =
            $SQLiteConnection.CreateCommand()

        # -------------------------------------------------------------
        # Build optional inventory filters.
        # -------------------------------------------------------------

        $WhereClauses =
            [System.Collections.Generic.List[string]]::new()

        $WhereClauses.Add(
            'I.CustomerNbr = @CustomerNbr'
        )

        $WhereClauses.Add(
            'I.IsActive = 1'
        )

        if (
            -not [string]::IsNullOrWhiteSpace(
                $SerialNumber
            )
        ) {

            $WhereClauses.Add(
                'I.SerialNumber = @SerialNumber'
            )
        }

        $WhereText =
            $WhereClauses -join "`n  AND "

        # -------------------------------------------------------------
        # Inventory is the authoritative source for:
        #
        #   VolumeID
        #   VdiskUID
        #   VolumeName
        #   RowID
        #   SerialNumber
        #   WWNN
        #
        # Analysis history is joined through the permanent identity:
        #
        #   CustomerNbr + SerialNumber + VdiskUID
        #
        # LEFT JOIN is intentional:
        # a newly discovered volume may already exist in the inventory
        # before its first analysis measurement was written.
        # -------------------------------------------------------------

        $SQLiteCommand.CommandText = @"
SELECT
    I.RowID,
    I.VolumeID,
    I.VdiskUID,
    I.VolumeName,
    I.SerialNumber,
    I.WWNN,
    I.IsActive,

    MIN(A.TimeStamp) AS FirstMeasurement,
    MAX(A.TimeStamp) AS LastMeasurement,
    COUNT(A.ID)      AS MeasurementCount

FROM IBMSTOVolumeInventoryTable I

LEFT JOIN IBMSTOVolumeAnalysisTable A
    ON  A.CustomerNbr  = I.CustomerNbr
    AND A.SerialNumber = I.SerialNumber
    AND A.VdiskUID     = I.VdiskUID

WHERE
    $WhereText

GROUP BY
    I.CustomerNbr,
    I.SerialNumber,
    I.VdiskUID,
    I.RowID,
    I.VolumeID,
    I.VolumeName,
    I.WWNN,
    I.IsActive

ORDER BY
    I.SerialNumber ASC,
    CAST(I.VolumeID AS INTEGER) ASC;
"@

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

        $SQLiteReader =
            $SQLiteCommand.ExecuteReader()

        $Result = while ($SQLiteReader.Read()) {

            # ---------------------------------------------------------
            # Read nullable history timestamps.
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

            $FirstMeasurement =
                if (
                    [string]::IsNullOrWhiteSpace(
                        $FirstMeasurementRaw
                    )
                ) {
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
                if (
                    [string]::IsNullOrWhiteSpace(
                        $LastMeasurementRaw
                    )
                ) {
                    $null
                }
                else {
                    [datetime]::ParseExact(
                        $LastMeasurementRaw,
                        'yyyy-MM-dd HH:mm:ss',
                        [System.Globalization.CultureInfo]::InvariantCulture
                    )
                }

            # ---------------------------------------------------------
            # Current inventory identity.
            # ---------------------------------------------------------

            $RowIDValue =
                [string]$SQLiteReader['RowID']

            $VolumeIDValue =
                [string]$SQLiteReader['VolumeID']

            $VdiskUIDValue =
                [string]$SQLiteReader['VdiskUID']

            $VolumeNameValue =
                [string]$SQLiteReader['VolumeName']

            $SerialValue =
                [string]$SQLiteReader['SerialNumber']

            $WWNNValue =
                [string]$SQLiteReader['WWNN']

            $MeasurementCount =
                [long]$SQLiteReader['MeasurementCount']

            # ---------------------------------------------------------
            # Return selector model.
            # ---------------------------------------------------------

            [PSCustomObject]@{
                CustomerNbr      = $CustomerNbr

                RowID            = $RowIDValue
                VolumeID         = $VolumeIDValue
                VdiskUID         = $VdiskUIDValue
                VolumeName       = $VolumeNameValue

                SerialNumber     = $SerialValue
                WWNN             = $WWNNValue

                IsActive         = 1

                FirstMeasurement = $FirstMeasurement
                LastMeasurement  = $LastMeasurement
                MeasurementCount = $MeasurementCount

                DisplayName = '{0} – Volume {1} – {2}' -f (
                    $SerialValue,
                    $VolumeIDValue,
                    $VolumeNameValue
                )
            }
        }

        return $Result
    }
    catch {

        throw (
            "Reading the available Storage volume histories failed: " +
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