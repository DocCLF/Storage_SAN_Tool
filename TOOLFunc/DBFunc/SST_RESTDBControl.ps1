function SST_RESTDBControl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("SaveStorageToken","UseStorageToken","DeleteStorageToken")]
        [string]$SST_InfoType,
        [string]$SST_BaseUrl,
        [string]$Result,
        $SST_NewDBObject
    )
    
    begin {
        $TimeStamp = Get-Date -UFormat "%Y-%m-%d %R"
        # Pfad zur Datenbank
        $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db;Version=3;"
        # Verbindung öffnen
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
        # Tabelle anlegen (nur beim ersten Mal nötig)
        $SST_SQliteCreateTBCMD = $SST_SQLiteCon.CreateCommand()
    }
    
    process {
        <# Create Table if not exists #>
        switch ($SST_InfoType) {
            "SaveStorageToken" { 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS STOApiTokens (BaseUrl TEXT PRIMARY KEY,Token TEXT NOT NULL, ExpiresAt TEXT NOT NULL, TimeStamp TEXT) "
                $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                $SST_SQliteCreateTBCMD.ExecuteNonQuery()                
            }
            Default {}
        }

        switch ($SST_InfoType) {
            "SaveStorageToken" { 
                    $SST_SQliteInsertCMD = $SST_SQLiteCon.CreateCommand()
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO STOApiTokens (BaseUrl, Token, ExpiresAt, TimeStamp) VALUES (@BaseUrl, @Token, @ExpiresAt, @TimeStamp) ON CONFLICT(BaseUrl) DO UPDATE SET Token = excluded.Token, ExpiresAt = excluded.ExpiresAt, TimeStamp = excluded.TimeStamp ;"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@BaseUrl", $SST_NewDBObject.BaseUrl) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Token", $SST_NewDBObject.Token) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ExpiresAt", $SST_NewDBObject.Expires) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    try {
                        $SST_SQliteInsertCMD.ExecuteNonQuery() | Out-Null
                        $Result = "DataSaved"
                    }
                    catch {
                        $Result = $null
                    }

            }
            "UseStorageToken" { 
                    $SST_SQliteUseCMD = $SST_SQLiteCon.CreateCommand()
                    $SST_SQliteUseCMD.CommandText ="SELECT Token, ExpiresAt FROM STOApiTokens WHERE BaseUrl = @BaseUrl ORDER BY ExpiresAt DESC LIMIT 1;"
                    $SST_SQliteUseCMD.Parameters.AddWithValue("@BaseUrl", $SST_BaseUrl) | Out-Null
                    $DataReader = $SST_SQliteUseCMD.ExecuteReader()

                    if ($DataReader.Read()) {
                        $Token     = $DataReader["Token"]
                        $ExpireTime = [datetime]$DataReader["ExpiresAt"]
                        if ($ExpireTime -gt (Get-Date)) {
                            $Result = $Token
                        }else {
                            $Result = $null
                        }
                    }
            }
            "DeleteStorageToken" { 
                    $SST_SQliteDeleteCMD = $SST_SQLiteCon.CreateCommand()
                    $SST_SQliteDeleteCMD.CommandText ="DELETE FROM STOApiTokens;"
                    $SST_SQliteDeleteCMD.ExecuteNonQuery() | Out-Null
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