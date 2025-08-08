function SST_DashBoardSAN {
    [CmdletBinding()]
    param (
        $SANHWCollection,
        $SQLReader
    )
    
    begin {
        $DeviceCounter = 0
        $SQLReader.CommandText = $SANHWCollection
        $SST_SQLiteDBReader = $SQLReader.ExecuteReader()
    }
    
    process {

        #ID, DID, Name, Status, CodeLevel, BrocadeProdName, SerialNumber, TimeStamp FROM IBMSANHWTabl
        while ($SST_SQLiteDBReader.Read()) {
            $DeviceCounter++
            $DashBoardSANsObj = [PSCustomObject]@{
            Name  = $SST_SQLiteDBReader["Name"]
            Status    = $SST_SQLiteDBReader["Status"]
            CodeLevel  = $SST_SQLiteDBReader["CodeLevel"]
            BrocadeProdName = $SST_SQLiteDBReader["BrocadeProdName"]
            SerialNumber    = $SST_SQLiteDBReader["SerialNumber"]
            TimeStamp = $SST_SQLiteDBReader["TimeStamp"]
            BrocadeIcon = "$PSRootPath\Resources\Icons\broadcom-96.png"
            ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
            }
            $DashBoardSANDeviceView.Add($DashBoardSANsObj)
        }
        $SST_SQLiteDBReader.Close()
        $TD_IC_DashBoardSANDevice.ItemsSource = $DashBoardSANDeviceView

        $TD_TB_SANDEVCount.Text = $DeviceCounter
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}