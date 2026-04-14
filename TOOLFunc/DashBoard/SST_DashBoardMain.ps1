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
    

        #region Storage
        try {
            $SST_SQLiteSTODashBoardQuery = $null
            $SST_SQLiteSTODashBoardQuery = "WITH Ranked AS (SELECT *, ROW_NUMBER() OVER ( PARTITION BY SerialNumber ORDER BY TimeStamp DESC, ID DESC ) AS rn FROM IBMSTOHWTable) SELECT ID, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, MDiskTotalCapacity, MDiskUsedCapacity, TimeStamp FROM Ranked WHERE rn = 1 ORDER BY ID;"
            SST_DashBoardSTO -Query $SST_SQLiteSTODashBoardQuery -SQLConnection $SQLiteDBConnection
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
}