function SST_DashBoardMain {
    [CmdletBinding()]
    param (
        [string]$MainPath
    )
    
    begin {
        
        $SST_ConnectionString = "Data Source=$MainPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
        
        # SELECT-Abfrage vorbereiten
        $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
        
    }
    
    process {
        try {
        $SST_SQliteReadCMD.CommandText = "SELECT ID, DID, Name, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, TimeStamp FROM IBMSTOHWTable;"
        $SST_SQLiteDBReader = $SST_SQliteReadCMD.ExecuteReader()

        SST_DashBoardSTO -STOHWCollection $SST_SQLiteDBReader
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no Table" -TD_ToolMSGType Warning -TD_Shown yes
        }

    }
    
    end {
        $SST_SQLiteCon.Close()
        $SST_SQLiteCon.Dispose()
    }
}