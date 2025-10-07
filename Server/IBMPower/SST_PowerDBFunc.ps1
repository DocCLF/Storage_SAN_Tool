function SST_PowerDBFunc {
    [CmdletBinding()]
    param (
        [string]$MainPath,
        $UCOBJ,
        $SST_SQLiteHMCQuery = $null,
        $SST_SQLiteDBReader = $null,
        [string]$IBMPowerOperatorDB
    )
    
    begin {
        $SST_ConnectionString = "Data Source=$MainPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
        $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
        $SST_SQLiteCon.Open()
        
        # SELECT-Abfrage vorbereiten
        $SST_SQliteReadCMD = $SST_SQLiteCon.CreateCommand()
    }
    
    process {
        switch ($IBMPowerOperatorDB) {
            "CountHMCTabelleEntrys" { 
                try {
                    $SST_SQliteReadCMD.CommandText = "SELECT COUNT(*) FROM PowerHMC"
                    $TabelleEntryCounter = $SST_SQliteReadCMD.ExecuteScalar()
                    $PowerDBFuncReturn = $TabelleEntryCounter
                }
                catch {
                    Write-Host $_.Exception.Message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no PowerHMC Table" -TD_ToolMSGType Warning -TD_Shown yes
                }
            }
            "CountPowerSysTabelleEntrys" { 
                try {
                    $SST_SQliteReadCMD.CommandText = "SELECT COUNT(*) FROM PowerSysSummary"
                    $TabelleEntryCounter = $SST_SQliteReadCMD.ExecuteScalar()
                    $PowerDBFuncReturn = $TabelleEntryCounter
                }
                catch {
                    Write-Host $_.Exception.Message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no PowerSysSummary Table" -TD_ToolMSGType Warning -TD_Shown yes
                }
            }
            "CountLPARSTabelleEntrys" { 
                try {
                    $SST_SQliteReadCMD.CommandText = "SELECT COUNT(*) FROM LPARSummary"
                    $TabelleEntryCounter = $SST_SQliteReadCMD.ExecuteScalar()
                    $PowerDBFuncReturn = $TabelleEntryCounter
                    #$SST_SQLiteDBReader.Close()
                }
                catch {
                    Write-Host $_.Exception.Message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no LPARSummary Table" -TD_ToolMSGType Warning -TD_Shown yes
                }
            }
            "HMCGUIInfo" { 
                try {
                    $SST_SQLiteHMCQuery = $null
                    $SST_SQLiteHMCQuery = "SELECT ID, HMCName, HMCHWModell, HMCHWSN, HMCHWBios, HMCSWVersion, HMCSWBuildLevel, HMCSWBaseVersion, HMCSWFixes, TimeStamp FROM PowerHMC d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM PowerHMC WHERE HMCHWSN = d.HMCHWSN ) GROUP BY HMCHWSN ORDER BY ID; "
                    IBM_PowerHMCDBView -HMCCollection $SST_SQLiteHMCQuery -SQLReader $SST_SQliteReadCMD -UCOBJ $UCOBJ
                }
                catch {
                    Write-Host $_.Exception.Message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no PowerHMC Table" -TD_ToolMSGType Warning -TD_Shown yes
                }
            }
            "PWRSysGUIInfo" { 
                try {
                    $SST_SQLiteHMCQuery = $null
                    $SST_SQLiteHMCQuery = "SELECT ID, PowerSysManagedSystem, PowerSysSystemStatus, PowerSysSystemMTM, PowerSysSystemSN, PowerSysMGRIPAddr, PowerSysPrimSPIPAddr, PowerSysECNumber, PowerSysIPLLevel, PowerSysIPLActivatedLevel, PowerSysCoDEvent, TimeStamp FROM PowerSysSummary d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM PowerSysSummary WHERE PowerSysSystemSN = d.PowerSysSystemSN ) GROUP BY PowerSysSystemSN ORDER BY ID; "
                    IBM_PowerSYSDBView -HMCCollection $SST_SQLiteHMCQuery -SQLReader $SST_SQliteReadCMD -UCOBJ $UCOBJ
                }
                catch {
                    Write-Host $_.Exception.Message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no PowerSysSummary Table" -TD_ToolMSGType Warning -TD_Shown yes
                }
            }
            "LPARGUIInfo" { 
                try {
                    $SST_SQLiteHMCQuery = $null
                    $SST_SQLiteHMCQuery = "SELECT ID, LPARName, LPARID, LPARStatus, LPAREnvironment, LPAROSVersion, LPARRMCIP, LPARManagedSystemName, LPARManagedSystemSN, TimeStamp FROM LPARSummary d WHERE TimeStamp = ( SELECT MAX(TimeStamp) FROM LPARSummary WHERE LPARID = d.LPARID ) GROUP BY LPARID ORDER BY ID; "
                    IBM_PowerLPARDBView -HMCCollection $SST_SQLiteHMCQuery -SQLReader $SST_SQliteReadCMD -UCOBJ $UCOBJ
                }
                catch {
                    Write-Host $_.Exception.Message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "There is something wrong, mybe there is no LPARSummary Table" -TD_ToolMSGType Warning -TD_Shown yes
                }
            }
            Default {}
        }


    }
    
    end {
        return $PowerDBFuncReturn
    }
}