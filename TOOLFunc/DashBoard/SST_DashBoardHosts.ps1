function SST_DashBoardHosts {
    [CmdletBinding()]
 param (
        [Parameter(Mandatory)]
        [string]$Query,
        [Parameter(Mandatory)]
        $SQLConnection,
        [string]$HostStatus = $null,
        [int]$SST_IBMHostDeviceCounter = 0
    )

    $DashBoardHostsView = [System.Collections.Generic.List[object]]::new()

    try {
        $SQLConnection.Open()
        $SQLiteCommand = $SQLConnection.CreateCommand()

        if($SST_IBMHostDeviceCounter -lt 1){
            $SQLiteCommand.CommandText = $Query
            $SST_SQLiteDBReader = $SQLiteCommand.ExecuteReader()
        }
    
        #ID, HID, HostName, Status, HostClusterName, STOName, SideName, WWNN, TimeStamp
        if($SST_IBMHostDeviceCounter -lt 1){
            [int]$SST_OfflineHost = 0
            while ($SST_SQLiteDBReader.Read()) {
                $SST_OfflineHost++
                $DashBoardHostsObj = [PSCustomObject]@{
                    Name  = $SST_SQLiteDBReader["HostName"]
                    Status  = $SST_SQLiteDBReader["Status"]
                    HostClusterName = $SST_SQLiteDBReader["HostClusterName"]
                    SideName = $SST_SQLiteDBReader["SideName"]
                    STOName = $SST_SQLiteDBReader["STOName"]
                    WWNN = $SST_SQLiteDBReader["WWNN"]
                    HostIcon = "$PSRootPath\Resources\Icons\icons8-server-96.png"
                    TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
                    ClockIcon96 = "$PSRootPath\Resources\Icons\icons8-clock-96.png"
                    
                }
                $DashBoardHostsView.Add($DashBoardHostsObj)
            }

            if($HostStatus -eq "online"){
                $TD_IC_DashBoardOnlineHosts.ItemsSource = $DashBoardHostsView
            }else {
               $TD_IC_DashBoardOfflineHosts.ItemsSource = $DashBoardHostsView
               $TD_TB_OfflHostCount.Text = "$SST_OfflineHost"
            }

        }
        if([string]::IsNullOrWhiteSpace($HostStatus)){
            try {
                if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
                $SQLiteCommand.CommandText = "SELECT COUNT(DISTINCT HostName) AS DeviceCount FROM IBMSTOHostTable;"
                $SST_IBMHostDeviceCounter = $SQLiteCommand.ExecuteScalar()
            }
            catch {
                Write-Host $_.Exception.Message
            }
            if($SST_IBMHostDeviceCounter -ge 1){
                if("0" -eq $TD_TB_ALLHostCount.Text){
                    $TD_TB_ALLHostCount.Text = "$SST_IBMHostDeviceCounter"
                }else {
                    [int]$SST_OLDDeviceCounter = $TD_TB_ALLHostCount.Text
                    $TD_TB_ALLHostCount.Text = $SST_OLDDeviceCounter + $SST_IBMHostDeviceCounter
                    $SST_OLDDeviceCounter =$null
                }

                [int]$SST_OfflineHost = $TD_TB_OfflHostCount.Text
                $SST_OnlineHosts = $SST_IBMHostDeviceCounter - $SST_OfflineHost
                $TD_TB_OnlinelHostCount.Text = "$SST_OnlineHosts"
            }
        }
    }catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message -ForegroundColor Red
        
    }finally{
        if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLConnection.State -eq 'Open') { $SQLConnection.Close() }
        $DashBoardHostsView = $null
        #$SQLConnection.Dispose()
    }
}