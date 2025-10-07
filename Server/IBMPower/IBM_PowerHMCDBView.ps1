function IBM_PowerHMCDBView {
    [CmdletBinding()]
    param (
        $UCOBJ,
        $HMCCollection,
        $SQLReader
    )
    
    begin {     
        $TD_IC_IBMPowerHMCObjView = $UCOBJ.FindName("IC_IBMPowerHMCObjView")
        $SQLReader.CommandText = $HMCCollection
        $SST_SQLiteDBReader = $SQLReader.ExecuteReader()
    }
    
    process {
        $IBMPowerHMCView = [System.Collections.Generic.List[object]]::new()
        #ID, HMCName, HMCHWModell, HMCHWSN, HMCHWBios, HMCSWVersion, HMCSWBuildLevel, HMCSWBaseVersion, HMCSWFixes, TimeStamp
        while ($SST_SQLiteDBReader.Read()) {
            $IBMPowerHMCsObj = [PSCustomObject]@{
                HMCName  = $SST_SQLiteDBReader["HMCName"]
                HMCProdMTM  = $SST_SQLiteDBReader["HMCHWModell"]
                HMCSerialNumber = $SST_SQLiteDBReader["HMCHWSN"]
                HMCBios = $SST_SQLiteDBReader["HMCHWBios"]
                HMCSWVersion = $SST_SQLiteDBReader["HMCSWVersion"]
                HMCBuildLevel  = $SST_SQLiteDBReader["HMCSWBuildLevel"]
                HMCBaseVersion  = $SST_SQLiteDBReader["HMCSWBaseVersion"]
                HMCSWFixes = $SST_SQLiteDBReader["HMCSWFixes"]
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
                STOIcon = "$PSRootPath\Resources\Icons\ibmstoicon.png"
                ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
            }
            $IBMPowerHMCView.Add($IBMPowerHMCsObj)
        }
        $SST_SQLiteDBReader.Close()
        $TD_IC_IBMPowerHMCObjView.ItemsSource = $IBMPowerHMCView
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}