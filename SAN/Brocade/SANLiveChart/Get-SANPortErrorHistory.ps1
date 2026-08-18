function Get-SANPortErrorHistory {
    <#
    .SYNOPSIS
        Reads the stored Brocade SAN port-error history for one port.

    .DESCRIPTION
        Returns all stored cumulative SAN port-error counters for one
        Brocade switch port within the requested time range.

        The function returns normal PowerShell objects and does not create
        any LiveCharts objects.

        RowID format:

            SerialNumber|VFID|Port

        Example:

            786713E|BASE|0/12

    .PARAMETER CustomerNbr
        Six-digit customer number.

    .PARAMETER RowID
        Stable SAN port identifier.

    .PARAMETER StartTime
        Beginning of the requested history range.

    .PARAMETER EndTime
        End of the requested history range.

    .OUTPUTS
        PSCustomObject

    .EXAMPLE
        $History =
            Get-SANPortErrorHistory `
                -CustomerNbr '123456' `
                -RowID '786713E|BASE|0/12' `
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
    SwitchName,
    SerialNumber,
    SwitchWWNN,
    VFID,
    Port,

    EncIn,
    CrcErr,
    TooShort,
    TooLong,
    BadEOF,
    EncOut,
    DiscC3,
    LinkFail,
    LossSync,
    LossSig,
    StateTransitions,
    BBZero,
    FECuncorrected,

    TimeStamp

FROM IBMSANPortErrorStatsTable

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

        $Result =
            while ($SQLiteReader.Read()) {

                [PSCustomObject]@{
                    ID =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'ID'

                    CustomerNbr =
                        [string]$SQLiteReader['CustomerNbr']

                    RowID =
                        [string]$SQLiteReader['RowID']

                    SwitchName =
                        if (
                            $SQLiteReader.IsDBNull(
                                $SQLiteReader.GetOrdinal(
                                    'SwitchName'
                                )
                            )
                        ) {
                            $null
                        }
                        else {
                            [string]$SQLiteReader['SwitchName']
                        }

                    SerialNumber =
                        [string]$SQLiteReader['SerialNumber']

                    SwitchWWNN =
                        if (
                            $SQLiteReader.IsDBNull(
                                $SQLiteReader.GetOrdinal(
                                    'SwitchWWNN'
                                )
                            )
                        ) {
                            $null
                        }
                        else {
                            [string]$SQLiteReader['SwitchWWNN']
                        }

                    VFID =
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

                    Port =
                        [string]$SQLiteReader['Port']

                    EncIn =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'EncIn'

                    CrcErr =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'CrcErr'

                    TooShort =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'TooShort'

                    TooLong =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'TooLong'

                    BadEOF =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'BadEOF'

                    EncOut =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'EncOut'

                    DiscC3 =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'DiscC3'

                    LinkFail =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'LinkFail'

                    LossSync =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'LossSync'

                    LossSig =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'LossSig'

                    StateTransitions =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'StateTransitions'

                    BBZero =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'BBZero'

                    FECuncorrected =
                        Get-SQLiteNullableInt64 `
                            -Reader $SQLiteReader `
                            -ColumnName 'FECuncorrected'

                    TimeStamp =
                        ConvertFrom-SANSQLiteDateTime `
                            -Value (
                                [string]$SQLiteReader['TimeStamp']
                            )
                }
            }

        return $Result
    }
    catch {

        throw (
            'Reading the SAN port-error history failed: ' +
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