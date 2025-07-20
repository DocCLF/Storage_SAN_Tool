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
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, DID, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, RecommendedPTF, TimeStamp FROM IBMSTOHWTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHWTable WHERE SerialNumber = d.SerialNumber ) GROUP BY SerialNumber ORDER BY ID; "
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
            SST_DashBoardHosts -STOHWCollection $SST_SQLiteDBReader -SST_IBMHostDeviceCounter 0
            $SST_SQLiteDBReader.Close()
            $SST_SQliteReadCMD.CommandText = "SELECT COUNT(DISTINCT Name) AS DeviceCount FROM IBMSTOHostTable;"
            $SST_IBMHostDeviceCounter = $SST_SQliteReadCMD.ExecuteScalar()
            SST_DashBoardHosts -SST_IBMHostDeviceCounter $SST_IBMHostDeviceCounter
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

        try {
            #DriveID, Slot, ProductID, DriveStatus, FWlev, LatestDriveFW, DriveCap, PhyDriveCap, PhyUsedDriveCap, EffeUsedDriveCap, DeviceSN, DeviceWWNN, TimeStamp
            $SST_SQLiteSTODashBoardQuery = $null
            #$SST_SQLiteSTODashBoardQuery = " SELECT d.DeviceSN, d.FWlev, d.LatestDriveFW, n.ClusterName AS Name FROM IBMSTODriveTable d JOIN ( SELECT DeviceSN, MAX(TimeStamp) AS MaxTime FROM IBMSTODriveTable GROUP BY DeviceSN ) latestDrive ON d.DeviceSN = latestDrive.DeviceSN AND d.TimeStamp = latestDrive.MaxTime JOIN ( SELECT SerialNumber, MAX(TimeStamp) AS MaxTime FROM IBMSTOHWTable GROUP BY SerialNumber ) latestNode ON d.DeviceSN = latestNode.SerialNumber JOIN IBMSTOHWTable n ON n.SerialNumber = latestNode.SerialNumber AND n.TimeStamp = latestNode.MaxTime ORDER BY d.DeviceSN; "
            $SST_SQLiteSTODashBoardQuery = " SELECT d.*, n.ClusterName AS Name FROM IBMSTODriveTable d JOIN ( SELECT DeviceSN, ProductID, MAX(TimeStamp) AS MaxTime FROM IBMSTODriveTable GROUP BY DeviceSN, ProductID ) latest ON d.DeviceSN = latest.DeviceSN AND d.ProductID = latest.ProductID AND d.TimeStamp = latest.MaxTime JOIN IBMSTOHWTable n ON d.DeviceSN = n.SerialNumber ORDER BY d.DeviceSN, d.ProductID; "
            $SST_SQliteReadCMD.CommandText = $SST_SQLiteSTODashBoardQuery
            $SST_SQLiteDBReader = $SST_SQliteReadCMD.ExecuteReader()

            SST_DashBoardDrives -STODriveCollection $SST_SQLiteDBReader
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