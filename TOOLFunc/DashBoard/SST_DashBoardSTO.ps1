function SST_DashBoardSTO {
[CmdletBinding()]
 param (
        $STOHWCollection,
        $SQLReader
    )
    
    begin {

        $SQLReader.CommandText = $STOHWCollection
        $SST_SQLiteDBReader = $SQLReader.ExecuteReader()
    }
    
    process {

        #ID, Name, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, ProdMTM, TimeStamp
        while ($SST_SQLiteDBReader.Read()) {
            
            $DashBoardSTOsObj = [PSCustomObject]@{
                Name  = $SST_SQLiteDBReader["Name"]
                Status  = $SST_SQLiteDBReader["Status"]
                ClusterName = $SST_SQLiteDBReader["ClusterName"]
                SerialNumber = $SST_SQLiteDBReader["SerialNumber"]
                CodeLevel = $SST_SQLiteDBReader["CodeLevel"]
                ProdMTM  = $SST_SQLiteDBReader["ProdMTM"]
                RecommendedPTF  = $SST_SQLiteDBReader["RecommendedPTF"]
                MDiskTC = $SST_SQLiteDBReader["MDiskTC"]
                MDiskTCfPGB = $SST_SQLiteDBReader["MDiskTC"] -replace '(MB|TB|PB)',''
                MDiskUC = $SST_SQLiteDBReader["MDiskUC"] -replace '(MB|TB|PB)',''
                STOIcon = "$PSRootPath\Resources\icons\ibmstoicon.png"
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
                ClockIcon96 = "$PSRootPath\Resources\icons\icons8-clock-96.png"
            }
            $DashBoardSTODeviceView.Add($DashBoardSTOsObj)
        }
        $SST_SQLiteDBReader.Close()
        $TD_IC_DashBoardSTODevice.ItemsSource = $DashBoardSTODeviceView

    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}