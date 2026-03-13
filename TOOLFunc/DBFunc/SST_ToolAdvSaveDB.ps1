function SST_ToolAdvSaveDB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("SavePRISMSettings","LoadPRISMSettings")]
        [string]$SST_InfoType,

        $SST_NewDBObject
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    $GUICustomerNBR = [int]$TD_TB_CustomerInfoName.Text
    $DBPath = Join-Path $PSRootPath "Resources\DBFolder\ToolDB\ToolDB.db"
    $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

    $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
    $SQLiteCommandCreate = $null
    $SQLiteCommand = $null
    $SQLiteReader = $null

    try {
        $SQLiteDBConnection.Open()

        # Ensure table
        $SQLiteCommandCreate = $SQLiteDBConnection.CreateCommand()
        if($SST_InfoType -like "*PRISM*"){
            $SQLiteCommandCreate.CommandText = " CREATE TABLE IF NOT EXISTS AdvSettings ( Id INTEGER PRIMARY KEY AUTOINCREMENT, IsCustomerNBR INTEGER NOT NULL UNIQUE, AZConString TEXT NOT NULL, AZCredP TEXT NOT NULL, TimeStamp TEXT);"
        }
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        switch ($SST_InfoType) {

            "SavePRISMSettings" {
                # UPSERT per customer number
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "INSERT INTO AdvSettings (IsCustomerNBR, AZConString, AZCredP, TimeStamp) VALUES (@IsCustomerNBR, @AZConString, @AZCredP, @TimeStamp) ON CONFLICT(IsCustomerNBR) DO UPDATE SET AZConString = excluded.AZConString, AZCredP = excluded.AZCredP, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@IsCustomerNBR", [int]$SST_NewDBObject.CustomerNBR) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@AZConString",   [string]$SST_NewDBObject.ConnectionStringPRISM)   | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@AZCredP",       [string]$SST_NewDBObject.CustomerAZP)       | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp",     $TimeStamp)                          | Out-Null

                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return
            }

            "LoadPRISMSettings" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT IsCustomerNBR, AZConString, AZCredP, TimeStamp FROM AdvSettings WHERE IsCustomerNBR = @CustomerNBR;"
                $SQLiteCommand.Parameters.AddWithValue("@CustomerNBR", $GUICustomerNBR) | Out-Null

                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if ($SQLiteReader.Read()) {
                    return [pscustomobject]@{
                        IsCustomerNBR = [int]$SQLiteReader["IsCustomerNBR"]
                        AZConString   = [string]$SQLiteReader["AZConString"]
                        AZCredP       = [string]$SQLiteReader["AZCredP"]
                        TimeStamp             = $SQLiteReader["TimeStamp"]
                    }
                }
                return $null
            }
        }
    }
    finally {
        if ($SQLiteReader) { $SQLiteReader.Close(); $SQLiteReader.Dispose() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLiteCommandCreate) { $SQLiteCommandCreate.Dispose() }
        if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }

        # extra secure for later deletions:
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}
