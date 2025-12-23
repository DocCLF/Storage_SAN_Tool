function SST_ToolDB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("SaveToolSettings","LoadToolSettings")]
        [string]$SST_InfoType,

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

        # Table sicherstellen
        $SQLiteCommandCreate = $SQLiteDBConnection.CreateCommand()
        $SQLiteCommandCreate.CommandText = " CREATE TABLE IF NOT EXISTS ToolSettings ( Id INTEGER PRIMARY KEY CHECK (Id = 1), LoadSettingsOnStartUp INTEGER NOT NULL, OnlineCheckbyImport INTEGER NOT NULL, PRISMactiv INTEGER NOT NULL, IsCustomer INTEGER NOT NULL, TimeStamp TEXT);"
        $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

        switch ($SST_InfoType) {

            "SaveToolSettings" {
                # UPSERT auf Id=1
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "INSERT INTO ToolSettings (Id, LoadSettingsOnStartUp, OnlineCheckbyImport, PRISMactiv, IsCustomer, TimeStamp) VALUES (1, @LoadSettingsOnStartUp, @OnlineCheckbyImport, @PRISMactiv, @IsCustomer, @TimeStamp) ON CONFLICT(Id) DO UPDATE SET LoadSettingsOnStartUp = excluded.LoadSettingsOnStartUp, OnlineCheckbyImport = excluded.OnlineCheckbyImport, PRISMactiv = excluded.PRISMactiv, IsCustomer = excluded.IsCustomer, TimeStamp = excluded.TimeStamp;"
                $SQLiteCommand.Parameters.AddWithValue("@LoadSettingsOnStartUp", [int]$SST_NewDBObject.LoadSettingsOnStartUp) | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@OnlineCheckbyImport",   [int]$SST_NewDBObject.OnlineCheckbyImport)   | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@PRISMactiv",            [int]$SST_NewDBObject.PRISMactiv)            | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@IsCustomer",            [int]$SST_NewDBObject.IsCustomer)            | Out-Null
                $SQLiteCommand.Parameters.AddWithValue("@TimeStamp",             $TimeStamp)                                  | Out-Null

                $SQLiteCommand.ExecuteNonQuery() | Out-Null
                return
            }

            "LoadToolSettings" {
                $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                $SQLiteCommand.CommandText = "SELECT LoadSettingsOnStartUp, OnlineCheckbyImport, PRISMactiv, IsCustomer, TimeStamp FROM ToolSettings WHERE Id = 1;"

                $SQLiteReader = $SQLiteCommand.ExecuteReader()
                if ($SQLiteReader.Read()) {
                    return [pscustomobject]@{
                        LoadSettingsOnStartUp = ([int]$SQLiteReader["LoadSettingsOnStartUp"] -ne 0)
                        OnlineCheckbyImport   = ([int]$SQLiteReader["OnlineCheckbyImport"]   -ne 0)
                        PRISMactiv            = ([int]$SQLiteReader["PRISMactiv"]            -ne 0)
                        IsCustomer            = ([int]$SQLiteReader["IsCustomer"]            -ne 0)
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

        # extra sicher für spätere Deletes:
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}
