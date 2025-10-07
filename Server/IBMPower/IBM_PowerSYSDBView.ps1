function IBM_PowerSYSDBView {
    [CmdletBinding()]
    param (
        $UCOBJ,
        $HMCCollection,
        $SQLReader
    )
    
    begin {     
        $TD_IC_IBMPowerSYSObjView = $UCOBJ.FindName("IC_IBMPowerSysObjView")
        $SQLReader.CommandText = $HMCCollection
        $SST_SQLiteDBReader = $SQLReader.ExecuteReader()
    }
    
    process {
        $IBMPowerSYSView = [System.Collections.Generic.List[object]]::new()
        #PowerSysManagedSystem, PowerSysSystemStatus, PowerSysSystemMTM, PowerSysSystemSN, PowerSysMGRIPAddr, PowerSysPrimSPIPAddr, PowerSysECNumber, PowerSysIPLLevel, PowerSysIPLActivatedLevel, PowerSysCoDEvent, TimeStamp
        while ($SST_SQLiteDBReader.Read()) {
            $IBMPowerSYSsObj = [PSCustomObject]@{
                PWRSYSName  = $SST_SQLiteDBReader["PowerSysManagedSystem"]
                PWRSYSStatus  = $SST_SQLiteDBReader["PowerSysSystemStatus"]
                PWRSYSProdMTM = $SST_SQLiteDBReader["PowerSysSystemMTM"]
                PWRSYSSerialNumber = $SST_SQLiteDBReader["PowerSysSystemSN"]
                PWRSYSMGRIPAddr = $SST_SQLiteDBReader["PowerSysMGRIPAddr"]
                PWRSYSPrimSPIPAddr  = $SST_SQLiteDBReader["PowerSysPrimSPIPAddr"]
                PWRSYSECNumber  = $SST_SQLiteDBReader["PowerSysECNumber"]
                PWRSYSIPLLevel = $SST_SQLiteDBReader["PowerSysIPLLevel"]
                PWRSYSIPLActivatedLevel  = $SST_SQLiteDBReader["PowerSysIPLActivatedLevel"]
                PWRSYSCoDEvent = $SST_SQLiteDBReader["PowerSysCoDEvent"]
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
                STOIcon = "$PSRootPath\Resources\Icons\ibmstoicon.png"
                ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
            }
            $IBMPowerSYSView.Add($IBMPowerSYSsObj)
        }
        $SST_SQLiteDBReader.Close()
        $TD_IC_IBMPowerSYSObjView.ItemsSource = $IBMPowerSYSView
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}