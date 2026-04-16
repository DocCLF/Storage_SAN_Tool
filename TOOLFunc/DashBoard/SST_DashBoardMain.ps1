function SST_DashBoardMain {
    [CmdletBinding()]
    param (
        [string]$MainPath,
        $SST_SQLiteSTODashBoardQuery = $null,
        $SST_SQLiteDBReader = $null,
        [string]$FoundLocalDB,
        $SST_UCOBJ
    )

        if(!([string]::IsNullOrWhiteSpace($FoundLocalDB))){
            $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$FoundLocalDB.db"
        }

        $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"
        
        $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString   
        #region Storage Events
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = "SELECT ID, SerialNumber, ObjectName, Status, ErrorCode, Description, TimeStamp FROM IBMSTOEventsTable WHERE Status = 'alert' AND TimeStamp >= datetime('now', '-28 days') ORDER BY TimeStamp DESC;"
            $SST_DeviceEvents = SST_DashBoardEvents -Query $SST_SQLiteSTODashBoardQuery -SQLConnection $SQLiteDBConnection
        }
        catch {
            Write-Host $_.Exception.Message
            #SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOEventsTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region Storage
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = "WITH Ranked AS (SELECT *, ROW_NUMBER() OVER ( PARTITION BY SerialNumber ORDER BY TimeStamp DESC, ID DESC ) AS rn FROM IBMSTOHWTable) SELECT ID, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, MDiskTotalCapacity, MDiskUsedCapacity, TimeStamp FROM Ranked WHERE rn = 1 ORDER BY ID;"
            SST_DashBoardSTO -Query $SST_SQLiteSTODashBoardQuery -SQLConnection $SQLiteDBConnection -Events $SST_DeviceEvents
        }
        catch {
            Write-Host $_.Exception.Message
        }
        #endregion
        #region SAN
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = "WITH Ranked AS (SELECT *, ROW_NUMBER() OVER ( PARTITION BY SerialNumber ORDER BY TimeStamp DESC, ID DESC ) AS rn FROM IBMSANHWTable) SELECT Name, Status, CodeLevel, BrocadeProdName, MTM, SerialNumber, TimeStamp FROM Ranked WHERE rn = 1 ORDER BY ID;"
            SST_DashBoardSAN -Query $SST_SQLiteSTODashBoardQuery -SQLConnection $SQLiteDBConnection
        }
        catch {
            Write-Host $_.Exception.Message
            #SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSANHWTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region Power Systems
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = "WITH Ranked AS (SELECT *, ROW_NUMBER() OVER ( PARTITION BY SerialNumber ORDER BY TimeStamp DESC, ID DESC ) AS rn FROM PowerSysSummary) SELECT ID, SystemName, State, MachineTypeModel, SerialNumber, ECNumber, ActivatedLevel, TimeStamp FROM Ranked WHERE rn = 1 ORDER BY ID;"
            SST_DashBoardPWR -Query $SST_SQLiteSTODashBoardQuery -SQLConnection $SQLiteDBConnection
        }
        catch {
            Write-Debug $_.Exception.Message
            #SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no PowerSysSummary Table $($_.Exception.Message)" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
        #region Storage Host
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, HID, HostName, Status, HostClusterName, STOName, SideName, WWNN, TimeStamp FROM IBMSTOHostTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHostTable WHERE HID = d.HID ) AND Status = 'offline' ORDER BY HID; "
            SST_DashBoardHosts -Query $SST_SQLiteSTODashBoardQuery -SST_IBMHostDeviceCounter 0 -SQLConnection $SQLiteDBConnection
            #$SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOHostTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = " SELECT ID, HID, HostName, Status, HostClusterName, STOName, SideName, WWNN, TimeStamp FROM IBMSTOHostTable d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM IBMSTOHostTable WHERE HID = d.HID ) AND Status IN ('online', 'degraded') ORDER BY HID; "
            SST_DashBoardHosts -Query $SST_SQLiteSTODashBoardQuery -SST_IBMHostDeviceCounter 0 -SQLConnection $SQLiteDBConnection -HostStatus "online"
            #$SST_SQLiteDBReader.Close()
        }
        catch {
            Write-Host $_.Exception.Message
            #SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no IBMSTOHostTable Table" -TD_ToolMSGType Warning -TD_Shown yes
        }
        #endregion
}