function SST_DashBoardMain {
    [CmdletBinding()]
    param (
        [string]$MainPath,
        $SST_SQLiteSTODashBoardQuery = $null,
        $SST_SQLiteDBReader = $null,
        $SST_UCOBJ
    )
    
    begin {

        $Extension = Get-Item -Path "$MainPath\Extensions\*" -Exclude *.ps1
        
        if(($Extension).count -lt 1){ 
            $TD_CB_DashBoardPWR.IsChecked=$false
        }
        
        $SST_ConnectionString = "Data Source=$MainPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
        
        # SELECT-Abfrage vorbereiten
        $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
        
    }
    
    process {
        #region Storage
        try {
            $DashBoardSTODeviceView = [System.Collections.Generic.List[object]]::new()
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, DID, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, RecommendedPTF, MDiskTC, MDiskUC, TimeStamp FROM IBMSTOHWTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHWTable WHERE SerialNumber = d.SerialNumber ) GROUP BY SerialNumber ORDER BY ID; "
            SST_DashBoardSTO -STOHWCollection $SST_SQLiteSTODashBoardQuery -SQLReader $SST_SQliteReadCMD
            #$SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOHWTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region Storage Host
        try {
            $DashBoardHostsView = [System.Collections.Generic.List[object]]::new()
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, HID, Name, Status, HostClusterName, STOName, SideName, WWNN, TimeStamp FROM IBMSTOHostTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHostTable WHERE HID = d.HID ) AND Status = 'offline' ORDER BY HID; "
            SST_DashBoardHosts -STOHWCollection $SST_SQLiteSTODashBoardQuery -SST_IBMHostDeviceCounter 0 -SQLReader $SST_SQliteReadCMD
            #$SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOHostTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }

        try {
            $SST_SQliteReadCMD.CommandText = "SELECT COUNT(DISTINCT Name) AS DeviceCount FROM IBMSTOHostTable;"
            $SST_IBMHostDeviceCounter = $SST_SQliteReadCMD.ExecuteScalar()
            SST_DashBoardHosts -SST_IBMHostDeviceCounter $SST_IBMHostDeviceCounter
            #$SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOHostTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }

        try {
            $DashBoardHostsView = [System.Collections.Generic.List[object]]::new()
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, HID, Name, Status, HostClusterName, STOName, SideName, WWNN, TimeStamp FROM IBMSTOHostTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHostTable WHERE HID = d.HID ) AND Status IN ('online', 'degraded') ORDER BY HID; "
            SST_DashBoardHosts -STOHWCollection $SST_SQLiteSTODashBoardQuery -SST_IBMHostDeviceCounter 0 -SQLReader $SST_SQliteReadCMD -HostStatus "online"
            #$SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOHostTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region SAN
        try {
            $DashBoardSANDeviceView = [System.Collections.Generic.List[object]]::new()
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT Name, Status, CodeLevel, CodeLevelLV, BrocadeProdName, MTM, SerialNumber, TimeStamp FROM IBMSANHWTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSANHWTable WHERE SerialNumber = d.SerialNumber ) ORDER BY SerialNumber; "
            SST_DashBoardSAN -SANHWCollection $SST_SQLiteSTODashBoardQuery -SQLReader $SST_SQliteReadCMD
            #$SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSANHWTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region Storage Drives
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
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTODriveTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region Storage Events
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT * FROM IBMSTOEventsTable e WHERE Status = 'alert' AND TimeStamp >= datetime('now', '-28 days') AND TimeStamp = (SELECT MAX(TimeStamp) FROM IBMSTOEventsTable WHERE Status = 'alert' AND TimeStamp >= datetime('now', '-28 days'));"
            $SST_SQliteReadCMD.CommandText = $SST_SQLiteSTODashBoardQuery
            $SST_SQLiteDBReader = $SST_SQliteReadCMD.ExecuteReader()
            SST_DashBoardEvents -STOEVCollection $SST_SQLiteDBReader 
            $SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOEventsTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region Power Systems
        try {
            $SST_SQLiteHMCQuery = $null
            $SST_SQLiteHMCQuery = "SELECT ID, PowerSysManagedSystem, PowerSysSystemStatus, PowerSysSystemMTM, PowerSysSystemSN, PowerSysMGRIPAddr, PowerSysPrimSPIPAddr, PowerSysECNumber, PowerSysIPLLevel, PowerSysIPLActivatedLevel, PowerSysCoDEvent, TimeStamp FROM PowerSysSummary d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM PowerSysSummary WHERE PowerSysSystemSN = d.PowerSysSystemSN ) GROUP BY PowerSysSystemSN ORDER BY ID; "
            IBM_PowerSYSDBView -HMCCollection $SST_SQLiteHMCQuery -SQLReader $SST_SQliteReadCMD -UCOBJ $SST_UCOBJ
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no PowerSysSummary Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
    }
    
    end {
        $SST_SQLiteCon.Close()
        $SST_SQLiteCon.Dispose()
    }
}