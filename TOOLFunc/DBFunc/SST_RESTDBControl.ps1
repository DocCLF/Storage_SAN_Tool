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

        $SQLiteCommandCreate.CommandText = " CREATE TABLE IF NOT EXISTS TapeApiTokens ( BaseUrl TEXT PRIMARY KEY, Token TEXT NOT NULL, SkipCertificateCheck TEXT NOT NULL, WorkingEndpoint  TEXT, LoginTime TEXT, TimeStamp TEXT);"
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        switch ($SST_InfoType) {

            "SaveStorageToken" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = " INSERT INTO STOApiTokens (BaseUrl, Token, ExpiresAt, TimeStamp) VALUES (@BaseUrl, @Token, @ExpiresAt, @TimeStamp) ON CONFLICT(BaseUrl) DO UPDATE SET Token = excluded.Token, ExpiresAt = excluded.ExpiresAt, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl",   [string]$SST_NewDBObject.BaseUrl) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@Token",     [string]$SST_NewDBObject.Token)   | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@ExpiresAt", [string]$SST_NewDBObject.Expires) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp)                       | Out-Null

                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return "DataSaved"
            }
            "SaveTapeToken" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = " INSERT INTO TapeApiTokens (BaseUrl, Token, SkipCertificateCheck, LoginTime, WorkingEndpoint , TimeStamp) VALUES (@BaseUrl, @Token, @SkipCertificateCheck, @WorkingEndpoint , @LoginTime, @TimeStamp) ON CONFLICT(BaseUrl) DO UPDATE SET Token = excluded.Token, SkipCertificateCheck = excluded.SkipCertificateCheck, APIVersionEndpoint = excluded.APIVersionEndpoint, LoginTime = excluded.LoginTime, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl",   [string]$SST_NewDBObject.BaseUrl) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@Token",     [string]$SST_NewDBObject.Token)   | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@SkipCertificateCheck", [string]$SST_NewDBObject.SkipCertificateCheck) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@WorkingEndpoint ", [string]$SST_NewDBObject.WorkingEndpoint ) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@LoginTime", $LoginTime)                       | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp)                       | Out-Null

                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return "DataSaved"
            }

            "UseStorageToken" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT Token, ExpiresAt FROM STOApiTokens WHERE BaseUrl = @BaseUrl LIMIT 1;"
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl", $SST_BaseUrl) | Out-Null

                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if ($SQLiteReader.Read()) {
                    $Token = [string]$SQLiteReader["Token"]
                    $ExpiresAtTemp   = [string]$SQLiteReader["ExpiresAt"]

                    # ISO 8601 robust parsen
                    $ExpireTime = [datetime]::Parse(
                        $ExpiresAtTemp,
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::RoundtripKind
                    )

                    if ($ExpireTime -gt (Get-Date)) {
                        return $Token
                    }
                }
                return $null
            }

            "UseTapeToken" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT Token, SkipCertificateCheck, WorkingEndpoint , LoginTime FROM TapeApiTokens WHERE BaseUrl = @BaseUrl LIMIT 1;"
                $SQLiteCommand.Parameters.AddWithValue("@BaseUrl", $SST_BaseUrl) | Out-Null

                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if ($SQLiteReader.Read()) {

                    $TapeTokenObj = [pscustomobject]@{
                        $Token = [string]$SQLiteReader["Token"]
                        $SkipCertificateCheck   = [string]$SQLiteReader["SkipCertificateCheck"]
                        $WorkingEndpoint        = [string]$SQLiteReader["WorkingEndpoint "]
                    }
                    $LoginTime   = [string]$SQLiteReader["LoginTime"]

                    if (($LoginTime.AddHours(+1)) -lt (Get-Date)) {
                        return $TapeTokenObj
                    }
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
