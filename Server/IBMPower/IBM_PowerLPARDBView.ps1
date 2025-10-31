function IBM_PowerLPARDBView {
    [CmdletBinding()]
    param (
        $UCOBJ,
        $HMCCollection,
        $SQLReader
    )
    
    begin {     
        $TD_IC_IBMPowerLPARObjView = $UCOBJ.FindName("IC_IBMPowerLPARObjView")
        $SQLReader.CommandText = $HMCCollection
        $SST_SQLiteDBReader = $SQLReader.ExecuteReader()
    }
    
    process {
        $IBMPowerLPARView = [System.Collections.Generic.List[object]]::new()
        #LPARName, LPARID, LPARStatus, LPAREnvironment, LPAROSVersion, LPARRMCIP, LPARManagedSystemName, LPARManagedSystemSN, TimeStamp
        while ($SST_SQLiteDBReader.Read()) {
            $IBMPowerLPARsObj = [PSCustomObject]@{
                LPARName  = $SST_SQLiteDBReader["LPARName"]
                LPARID  = $SST_SQLiteDBReader["LPARID"]
                LPARStatus = $SST_SQLiteDBReader["LPARStatus"]
                LPAREnvironment = $SST_SQLiteDBReader["LPAREnvironment"]
                LPAROSVersion = $SST_SQLiteDBReader["LPAROSVersion"]
                LPARRMCIP  = $SST_SQLiteDBReader["LPARRMCIP"]
                LPARManagedSystemName  = $SST_SQLiteDBReader["LPARManagedSystemName"]
                LPARManagedSystemSN = $SST_SQLiteDBReader["LPARManagedSystemSN"]
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
                LPARIcon = "$PSRootPath\Resources\Icons\powericon01.png"
                ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
            }
            switch ($IBMPowerLPARsObj.LPAROSVersion) {
                {$_ -like "*400*"}  { $IBMPowerLPARsObj.LPARIcon = "$PSRootPath\Resources\Icons\IBMiicon.png" }
                {$_ -like "*AIX*"}  { $IBMPowerLPARsObj.LPARIcon = "$PSRootPath\Resources\Icons\AIXicon.png" }
                {$_ -like "*Linux/Red*"}  { $IBMPowerLPARsObj.LPARIcon = "$PSRootPath\Resources\Icons\RedHatLinuxicon.png" }
                {$_ -like "*Linux/SLES*"}  { $IBMPowerLPARsObj.LPARIcon = "$PSRootPath\Resources\Icons\SLESicon.png" }
                Default {
                    if($IBMPowerLPARsObj.LPAREnvironment -eq "os400"){
                        $IBMPowerLPARsObj.LPARIcon = "$PSRootPath\Resources\Icons\IBMiicon.png"
                    }
                }
            }
 
            $IBMPowerLPARView.Add($IBMPowerLPARsObj)
        }
        $SST_SQLiteDBReader.Close()
        $TD_IC_IBMPowerLPARObjView.ItemsSource = $IBMPowerLPARView
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}