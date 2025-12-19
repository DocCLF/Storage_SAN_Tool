function SST_ToolDB {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("SaveToolSettings","LoadToolSettings")]
        [string]$SST_InfoType,
        $SST_NewDBObject
    )
    
    begin {
        try {
            $TimeStamp = Get-Date -UFormat "%Y-%m-%d %R"
            $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db;Version=3;"
            $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
            $SST_SQLiteCon.Open()
        }
        catch {
            Write-Error $_.Exception.Message
            #SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
        }
    }
    
    process {
        switch ($SST_InfoType) {
            "SaveToolSettings" { 
                $SST_SQliteCreateTBCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS ToolSettings (Id INTEGER PRIMARY KEY CHECK (Id = 1), LoadSettingsOnStartUp INTEGER NOT NULL, OnlineCheckbyImport INTEGER NOT NULL, PRISMactiv INTEGER NOT NULL, IsCustomer INTEGER NOT NULL, TimeStamp TEXT) "
                $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                $SST_SQliteCreateTBCMD.ExecuteNonQuery()  
                $SST_SQliteCheckTableCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQliteCheckTableCMD.CommandText = "SELECT COUNT(*) FROM ToolSettings WHERE Id = 1"
                $TableCount = $SST_SQliteCheckTableCMD.ExecuteScalar()
                if ($TableCount -eq 0) {
                    $SST_SQliteInsertDummysCMD = $SST_SQLiteCon.CreateCommand()
                    $SST_SQliteInsertDummysCMD.CommandText = "INSERT INTO ToolSettings (Id, LoadSettingsOnStartUp, OnlineCheckbyImport, PRISMactiv, IsCustomer, TimeStamp) VALUES (1, '0', '0', '0', '0', @TimeStamp);"
                    $SST_SQliteInsertDummysCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp)
                    $SST_SQliteInsertDummysCMD.ExecuteNonQuery() | Out-Null
                }
            }
            Default {}
        }

        switch ($SST_InfoType) {
            "SaveToolSettings" { 
                $SST_SQliteInsertCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQliteInsertCMD.CommandText ="UPDATE ToolSettings SET LoadSettingsOnStartUp = @LoadSettingsOnStartUp, OnlineCheckbyImport = @OnlineCheckbyImport, PRISMactiv = @PRISMactiv, IsCustomer = @IsCustomer, TimeStamp = @TimeStamp;"
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@LoadSettingsOnStartUp", [Int16]$SST_NewDBObject.LoadSettingsOnStartUp)
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@OnlineCheckbyImport", [Int16]$SST_NewDBObject.OnlineCheckbyImport)
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@PRISMactiv", [Int16]$SST_NewDBObject.PRISMactiv)
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@IsCustomer", [Int16]$SST_NewDBObject.IsCustomer)
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp)
                $SST_SQliteInsertCMD.ExecuteNonQuery() 
            }
            "LoadToolSettings" { 
                $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQliteReadCMD.CommandText = "SELECT * FROM ToolSettings WHERE Id = 1"

                $SST_SQliteReader = $SST_SQliteReadCMD.ExecuteReader()
                if ($SST_SQliteReader.Read()) {
                    $SettingsObj = [pscustomobject]@{
                        LoadSettingsOnStartUp = [bool]$SST_SQliteReader["LoadSettingsOnStartUp"]
                        OnlineCheckbyImport   = [bool]$SST_SQliteReader["OnlineCheckbyImport"]
                        PRISMactiv            = [bool]$SST_SQliteReader["PRISMactiv"]
                        IsCustomer            = [bool]$SST_SQliteReader["IsCustomer"]
                        TimeStamp            = $SST_SQliteReader["TimeStamp"]
                    }
                }
                $SST_SQliteReader.Close()
                return $SettingsObj
            }
            Default {}
        }

    }
    
    end {
        #Verbindung schließen
        $SST_NewDBObject =$null
        $SST_SQLiteCon.Close()
        $SST_SQLiteCon.Dispose()
    }
}