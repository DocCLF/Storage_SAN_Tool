function SST_DashBoardMain {
    [CmdletBinding()]
    param (
        [string]$MainPath,
        $SST_SQLiteSTODashBoardQuery = $null,
        $SST_SQLiteDBReader = $null
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
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, DID, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, TimeStamp FROM IBMSTOHWTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHWTable WHERE DID = d.DID ) ORDER BY DID; "
            $SST_SQliteReadCMD.CommandText = $SST_SQLiteSTODashBoardQuery
            $SST_SQLiteDBReader = $SST_SQliteReadCMD.ExecuteReader()

            SST_DashBoardSTO -STOHWCollection $SST_SQLiteDBReader
            $SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no Table" -TD_ToolMSGType Warning -TD_Shown yes
        }

        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, HID, Name, Status, HostClusterName, SideName, TimeStamp FROM IBMSTOHostTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHostTable WHERE HID = d.HID ) AND Status != 'online' ORDER BY HID; "
            $SST_SQliteReadCMD.CommandText = $SST_SQLiteSTODashBoardQuery
            $SST_SQLiteDBReader = $SST_SQliteReadCMD.ExecuteReader()

            SST_DashBoardHosts -STOHWCollection $SST_SQLiteDBReader
            $SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no Table" -TD_ToolMSGType Warning -TD_Shown yes
        }

        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT Name, Status, CodeLevel, BrocadeProdName, SerialNumber, TimeStamp FROM IBMSANHWTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSANHWTable WHERE SerialNumber = d.SerialNumber ) ORDER BY SerialNumber; "
            $SST_SQliteReadCMD.CommandText = $SST_SQLiteSTODashBoardQuery
            $SST_SQLiteDBReader = $SST_SQliteReadCMD.ExecuteReader()

            SST_DashBoardSAN -STOHWCollection $SST_SQLiteDBReader
            $SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
    }
    
    end {
        $SST_SQLiteCon.Close()
        $SST_SQLiteCon.Dispose()
    }
}