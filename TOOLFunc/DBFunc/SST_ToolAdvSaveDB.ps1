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
            $SQLiteCommandCreate.CommandText = " CREATE TABLE IF NOT EXISTS AdvSettings ( Id INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNBR INTEGER NOT NULL UNIQUE, AZConString TEXT NOT NULL, CustomerP TEXT NOT NULL, AZDBNAM TEXT NOT NULL,TimeStamp TEXT);"
        }
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        switch ($SST_InfoType) {

            "SavePRISMSettings" {
                # UPSERT per customer number
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "INSERT INTO AdvSettings (CustomerNBR, AZConString, CustomerP, AZDBNAM, TimeStamp) VALUES (@CustomerNBR, @AZConString, @CustomerP, @AZDBNAM, @TimeStamp) ON CONFLICT(CustomerNBR) DO UPDATE SET AZConString = excluded.AZConString, CustomerP = excluded.CustomerP, AZDBNAM = excluded.AZDBNAM, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@CustomerNBR",  [int]$SST_NewDBObject.CustomerNBR)              | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@AZConString",  [string]$SST_NewDBObject.AZConString)           | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@CustomerP",    [string]$SST_NewDBObject.CustomerP)           | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@AZDBNAM",      [string]$SST_NewDBObject.AZDBNAM)               | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp",     $TimeStamp)                                    | Out-Null

                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return
            }

            "LoadPRISMSettings" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT CustomerNBR, AZConString, CustomerP, AZDBNAM, TimeStamp FROM AdvSettings WHERE CustomerNBR = @CustomerNBR;"
                $SQLiteCommand.Parameters.AddWithValue("@CustomerNBR", $GUICustomerNBR) | Out-Null

                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if ($SQLiteReader.Read()) {
                    return [pscustomobject]@{
                        IsCustomerNBR   = [int]$SQLiteReader["CustomerNBR"]
                        AZConString     = [string]$SQLiteReader["AZConString"]
                        CustomerP       = [string]$SQLiteReader["CustomerP"]
                        AZDBNAM         = [string]$SQLiteReader["AZDBNAM"]
                        TimeStamp       = $SQLiteReader["TimeStamp"]
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
