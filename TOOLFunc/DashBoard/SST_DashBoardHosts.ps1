function SST_DashBoardHosts {
    [CmdletBinding()]
 param (
        $STOHWCollection,
        $SQLReader,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("online","offline")]
        $HostStatus,
        [int]$SST_IBMHostDeviceCounter
    )
    
    begin {
        if($SST_IBMHostDeviceCounter -lt 1){
            $SQLReader.CommandText = $STOHWCollection
            $SST_SQLiteDBReader = $SQLReader.ExecuteReader()
        }
    }
    
    process {

        #ID, HID, Name, Status, HostClusterName, SideName, TimeStamp FROM IBMSTOHostTable
        if($SST_IBMHostDeviceCounter -lt 1){
            [int]$SST_OfflineHost = 0
            while ($SST_SQLiteDBReader.Read()) {
                $SST_OfflineHost++
                $DashBoardHostsObj = [PSCustomObject]@{
                    Name  = $SST_SQLiteDBReader["Name"]
                    Status  = $SST_SQLiteDBReader["Status"]
                    HostClusterName = $SST_SQLiteDBReader["HostClusterName"]
                    SideName = $SST_SQLiteDBReader["SideName"]
                    STOName = $SST_SQLiteDBReader["STOName"]
                    HostIcon = "$PSRootPath\Resources\Icons\icons8-server-96.png"
                    TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
                    ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
                }
                $DashBoardHostsView.Add($DashBoardHostsObj)
            }
            $SST_SQLiteDBReader.Close()

            if($HostStatus -eq "online"){
                $TD_IC_DashBoardOnlineHosts.ItemsSource = $DashBoardHostsView
            }else {
               $TD_IC_DashBoardOfflineHosts.ItemsSource = $DashBoardHostsView
               $TD_TB_OfflHostCount.Text = "$SST_OfflineHost"
            }

        }else{

            if("0" -eq $TD_TB_ALLHostCount.Text){
                $TD_TB_ALLHostCount.Text = "$SST_IBMHostDeviceCounter"
            }else {
                [int]$SST_OLDDeviceCounter = $TD_TB_ALLHostCount.Text
                $TD_TB_ALLHostCount.Text = $SST_OLDDeviceCounter + $SST_IBMHostDeviceCounter
                $SST_OLDDeviceCounter =$null
            }
            
            $SST_OfflineHost = $TD_TB_OfflHostCount.Text
            $SST_OnlineHosts = $SST_IBMHostDeviceCounter - $SST_OfflineHost
            $TD_TB_OnlinelHostCount.Text = "$SST_OnlineHosts"
        }
    }
    
    end {
        if ($reader) { $reader.Close() }
    }
}