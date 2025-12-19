function SST_CustomerDB {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("SaveCustomerSetUp","LoadCustomerSetUp")]
        [string]$SST_InfoType,
        [string]$SST_Customer,
        $SST_NewDBObject
    )
    
    begin {
        try {
            $TimeStamp = Get-Date -UFormat "%Y-%m-%d %R"
            if(!([string]::IsNullOrEmpty($SST_Customer))){
                $Customer = $SST_Customer
            }elseif([string]::IsNullOrEmpty($SST_Customer)){
                $Customer = $TD_TB_CustomerInfoName.Text
            }else {
                $Customer = $SST_NewDBObject.CustomerName
            }
            $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db;Version=3;"
            $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
            $SST_SQLiteCon.Open()
        }
        catch {
            Write-Error $_.exception.message
            #SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
        }
    }
    
    process {
        <# Create Table if not exists #>
        switch ($SST_InfoType) {
            "SaveCustomerSetUp" { 
                $SST_SQliteCreateTBCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS CustomerToolSetUpDB (CustomerName TEXT PRIMARY KEY, ExportPath TEXT, ExportPathCredential TEXT NOT NULL, TimeStamp TEXT) "
                $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                $SST_SQliteCheckTableCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQliteCheckTableCMD.CommandText = "SELECT COUNT(*) FROM CustomerToolSetUpDB WHERE CustomerName = @CustomerName"
                $SST_SQliteCheckTableCMD.Parameters.AddWithValue("@CustomerName", $Customer) | Out-Null
                $TableCount = [Int16]$SST_SQliteCheckTableCMD.ExecuteScalar()
                if ($TableCount -eq 0) {
                    $SST_SQliteInsertDummysCMD = $SST_SQLiteCon.CreateCommand()
                    $SST_SQliteInsertDummysCMD.CommandText = "INSERT INTO CustomerToolSetUpDB (CustomerName, ExportPath, ExportPathCredential, TimeStamp) VALUES (@CustomerName, '', '', @TimeStamp);"
                    $SST_SQliteInsertDummysCMD.Parameters.AddWithValue("@CustomerName", $Customer) | Out-Null
                    $SST_SQliteInsertDummysCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    $SST_SQliteInsertDummysCMD.ExecuteNonQuery() | Out-Null
                }
            }
            "SaveCustomerSetUp" { 
                $SST_SQliteInsertCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQliteInsertCMD.CommandText ="INSERT INTO CustomerToolSetUpDB (CustomerName, ExportPath, ExportPathCredential, TimeStamp) VALUES (@CustomerName, @ExportPath, @ExportPathCredential, @TimeStamp) ON CONFLICT(CustomerName) DO UPDATE SET ExportPath = excluded.ExportPath, ExportPathCredential = excluded.ExportPathCredential, TimeStamp = excluded.TimeStamp ;"
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@CustomerName", $Customer) | Out-Null
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@ExportPath", $SST_NewDBObject.ExportPath) | Out-Null
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@ExportPathCredential", $SST_NewDBObject.ExportPathCredential) | Out-Null
                $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null   
                $SST_SQliteInsertCMD.ExecuteNonQuery() | Out-Null         
            }
            "LoadCustomerSetUp" { 
                $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
                $SST_SQliteReadCMD.CommandText = "SELECT * FROM CustomerToolSetUpDB WHERE CustomerName = @CustomerName"
                $SST_SQliteReadCMD.Parameters.AddWithValue("@CustomerName", $Customer) | Out-Null

                $SST_SQliteReader = $SST_SQliteReadCMD.ExecuteReader()
                if ($SST_SQliteReader.Read()) {
                    $CustomerSettingsObj = [pscustomobject]@{
                        CustomerName            = $SST_SQliteReader["CustomerName"]
                        ExportPath              = $SST_SQliteReader["ExportPath"]
                        ExportPathCredential    = $SST_SQliteReader["ExportPathCredential"]
                        TimeStamp               = $SST_SQliteReader["TimeStamp"]
                    }
                }
                $SST_SQliteReader.Close()
                return $CustomerSettingsObj
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