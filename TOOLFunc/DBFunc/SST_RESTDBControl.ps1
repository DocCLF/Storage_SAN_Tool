function SST_RESTDBControl {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("SaveStorageToken","UseStorageToken","SaveTapeToken","UseTapeToken","DeleteToken")]
        [string]$SST_InfoType,

        [string]$SST_BaseUrl,
        $SST_NewDBObject
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $DBPath = Join-Path $PSRootPath "Resources\DBFolder\ToolDB\ToolDB.db"
    $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

    $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
    $SQLiteCommandCreate = $null
    $SQLiteCommand = $null
    $SQLiteReader = $null

    try {
        $SQLiteDBConnection.Open()

        # Ensure the table is secure (works for all modes)
        $SQLiteCommandCreate = $SQLiteDBConnection.CreateCommand()

        $SQLiteCommandCreate.CommandText = " CREATE TABLE IF NOT EXISTS STOApiTokens ( BaseUrl TEXT PRIMARY KEY, Token TEXT NOT NULL, ExpiresAt TEXT NOT NULL, TimeStamp TEXT);"
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        $SQLiteCommandCreate.CommandText = " CREATE TABLE IF NOT EXISTS TapeApiTokens ( BaseUrl TEXT PRIMARY KEY, Token TEXT, SkipCertificateCheck TEXT, LoginTime TEXT, TimeStamp TEXT);"
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        switch ($SST_InfoType) {

            "SaveStorageToken" {
                $BaseUrlValue   = [string]$SST_NewDBObject.BaseUrl
                $TokenValue     = [string]$SST_NewDBObject.Token
                $ExpiresAtValue = [string]$SST_NewDBObject.Expires
                if ([string]::IsNullOrWhiteSpace($BaseUrlValue)) {throw "The storage token cannot be saved because BaseUrl is empty."}
                if ([string]::IsNullOrWhiteSpace($TokenValue)) {throw "The storage token cannot be saved because Token is empty."}
                $ParsedExpiresAt = [datetime]::MinValue
                $HasValidExpiresAt = -not [string]::IsNullOrWhiteSpace($ExpiresAtValue) -and [datetime]::TryParse(
                        $ExpiresAtValue,
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::RoundtripKind,
                        [ref]$ParsedExpiresAt
                    )
                if (-not $HasValidExpiresAt) {throw "The storage token cannot be saved because ExpiresAt is empty or invalid: '$ExpiresAtValue'."}

                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = " INSERT INTO STOApiTokens (BaseUrl, Token, ExpiresAt, TimeStamp) VALUES (@BaseUrl, @Token, @ExpiresAt, @TimeStamp) ON CONFLICT(BaseUrl) DO UPDATE SET Token = excluded.Token, ExpiresAt = excluded.ExpiresAt, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl",   $BaseUrlValue) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@Token",     $TokenValue)   | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@ExpiresAt", $ParsedExpiresAt.ToString("o")) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp)                       | Out-Null

                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return "DataSaved"
            }
            "SaveTapeToken" {
                $TapeLoginTime = if ($SST_NewDBObject.LoginTime -is [datetime]) {
                    ([datetime]$SST_NewDBObject.LoginTime).ToString("o",[System.Globalization.CultureInfo]::InvariantCulture)
                }
                else {
                    [string]$SST_NewDBObject.LoginTime
                }
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = " INSERT INTO TapeApiTokens (BaseUrl, Token, SkipCertificateCheck, LoginTime, TimeStamp) VALUES (@BaseUrl, @Token, @SkipCertificateCheck, @LoginTime, @TimeStamp) ON CONFLICT(BaseUrl) DO UPDATE SET Token = excluded.Token, SkipCertificateCheck = excluded.SkipCertificateCheck, LoginTime = excluded.LoginTime, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl",   $SST_NewDBObject.BaseUrl) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@Token",     $SST_NewDBObject.Token)   | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@SkipCertificateCheck", $SST_NewDBObject.SkipCertificateCheck) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@LoginTime", $TapeLoginTime)                       | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp)                       | Out-Null

                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                #return "DataSaved"
            }

            "UseStorageToken" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT Token, ExpiresAt FROM STOApiTokens WHERE BaseUrl = @BaseUrl LIMIT 1;"
            
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl",[string]$SST_BaseUrl) | Out-Null
                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if (-not $SQLiteReader.Read()) {return $null}
            
                $Token = if ($SQLiteReader.IsDBNull($SQLiteReader.GetOrdinal("Token"))) {
                    $null
                }else {
                    [string]$SQLiteReader["Token"]
                }
            
                $ExpiresAtText = if ($SQLiteReader.IsDBNull($SQLiteReader.GetOrdinal("ExpiresAt"))) {
                    $null
                }else {
                    [string]$SQLiteReader["ExpiresAt"]
                }
            
                $ExpireTime = [datetime]::MinValue
            
                $HasValidExpireTime =
                    -not [string]::IsNullOrWhiteSpace($ExpiresAtText) -and [datetime]::TryParse(
                        $ExpiresAtText,
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::RoundtripKind,
                        [ref]$ExpireTime
                    )
            
                $HasValidToken = -not [string]::IsNullOrWhiteSpace($Token)
            
                if ($HasValidToken -and $HasValidExpireTime -and $ExpireTime -gt (Get-Date)) {return $Token}
            
                # Remove invalid or expired records.
                $SQLiteReader.Close()
                $SQLiteReader.Dispose()
                $SQLiteReader = $null
            
                $DeleteCommand = $SQLiteDBConnection.CreateCommand()
            
                try {
                    $DeleteCommand.CommandText = "DELETE FROM STOApiTokens WHERE BaseUrl = @BaseUrl;"

                    $DeleteCommand.Parameters.AddWithValue("@BaseUrl",[string]$SST_BaseUrl) | Out-Null
                    $DeleteCommand.ExecuteNonQuery() | Out-Null
                }
                finally {
                    $DeleteCommand.Dispose()
                }
            
                return $null
            }

            "UseTapeToken" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
            
                $SQLiteCommand.CommandText = "SELECT Token, SkipCertificateCheck, LoginTime FROM TapeApiTokens WHERE BaseUrl = @BaseUrl LIMIT 1; "
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl", [string]$SST_BaseUrl) | Out-Null
                $SQLiteReader = $SQLiteCommand.ExecuteReader()

                if (-not $SQLiteReader.Read()) {return $null}

                $Token = if ($SQLiteReader.IsDBNull($SQLiteReader.GetOrdinal("Token"))) {
                    $null
                }else {
                    [string]$SQLiteReader["Token"]
                }
            
                $SkipCertificateCheck = if ($SQLiteReader.IsDBNull($SQLiteReader.GetOrdinal("SkipCertificateCheck"))) {
                    $null
                }else {
                    [string]$SQLiteReader["SkipCertificateCheck"]
                }
            
                $LoginTimeText = if ($SQLiteReader.IsDBNull($SQLiteReader.GetOrdinal("LoginTime"))) {
                    $null
                }
                else {
                    [string]$SQLiteReader["LoginTime"]
                }
            
                $LoginTime = [datetime]::MinValue
            
                $HasValidLoginTime = -not [string]::IsNullOrWhiteSpace($LoginTimeText) -and [datetime]::TryParse(
                        $LoginTimeText,
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::AllowWhiteSpaces,
                        [ref]$LoginTime
                    )
            
                $HasValidToken = -not [string]::IsNullOrWhiteSpace($Token)
            
                if ($HasValidToken -and $HasValidLoginTime -and $LoginTime.AddHours(1) -gt (Get-Date)) {
                    return [PSCustomObject]@{
                        Token                = $Token
                        SkipCertificateCheck = $SkipCertificateCheck
                        LoginTime            = $LoginTime
                    }
                }
            
                $SQLiteReader.Close()
                $SQLiteReader.Dispose()
                $SQLiteReader = $null
            
                $DeleteCmd = $SQLiteDBConnection.CreateCommand()
            
                try {
                    $DeleteCmd.CommandText = "DELETE FROM TapeApiTokens WHERE BaseUrl = @BaseUrl; "
                    $DeleteCmd.Parameters.AddWithValue("@BaseUrl", [string]$SST_BaseUrl) | Out-Null
                    $DeleteCmd.ExecuteNonQuery() | Out-Null
                }
                finally {
                    $DeleteCmd.Dispose()
                }
            
                return $null
            }

            "DeleteToken" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "DELETE FROM STOApiTokens;"
                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return "Deleted"
            }
        }
    }
    finally {
        if ($SQLiteReader) { $SQLiteReader.Close(); $SQLiteReader.Dispose() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLiteCommandCreate) { $SQLiteCommandCreate.Dispose() }
        if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}