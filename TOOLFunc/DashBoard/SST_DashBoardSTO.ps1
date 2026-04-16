function SST_DashBoardSTO {
[CmdletBinding()]
 param (
        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        $SQLConnection,

        $Events
    )
    $DashBoardSTODeviceView = [System.Collections.Generic.List[object]]::new()
    $DeviceCounter = 0

    try {
        $SQLConnection.Open()
        $SQLiteCommand = $SQLConnection.CreateCommand()
        $SQLiteCommand.CommandText = $Query

        $SST_SQLiteDBReader = $SQLiteCommand.ExecuteReader()
        #ID, Name, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, ProdMTM, TimeStamp
        # need a workaround if PB is used
        while ($SST_SQLiteDBReader.Read()) {
            $DeviceCounter++

            $DashBoardSTOsObj = [PSCustomObject]@{
                Name  = $SST_SQLiteDBReader["Name"]
                Status  = $SST_SQLiteDBReader["Status"]
                ClusterName = $SST_SQLiteDBReader["ClusterName"]
                SerialNumber = $SST_SQLiteDBReader["SerialNumber"]
                CodeLevel = $SST_SQLiteDBReader["CodeLevel"] -replace '\s+\(.*\)',''
                ProdMTM  = $SST_SQLiteDBReader["ProdMTM"]
                MDiskTC = $SST_SQLiteDBReader["MDiskTotalCapacity"]
                MDiskTCfPGB = $SST_SQLiteDBReader["MDiskTotalCapacity"] -replace '(MB|TB|PB)',''
                MDiskUC = $SST_SQLiteDBReader["MDiskUsedCapacity"] -replace '(MB|TB|PB)',''
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
            }
            $DashBoardSTODeviceView.Add($DashBoardSTOsObj)
        }

        $eventMergeResult = Add-EventInfoToDevices -Devices $DashBoardSTODeviceView -Events $Events
        $DashBoardSTODeviceView = $eventMergeResult.Devices
        $OrphanEvents = $eventMergeResult.OrphanEvents
        <# Woraround for ClusterSystem like IBM SVC #>
        foreach ($STODevice in $DashBoardSTODeviceView) {
            $STOClusterName = $STODevice.ClusterName
            foreach($OrphanEvent in $OrphanEvents){
                if($STOClusterName -eq $OrphanEvent.ObjectName){
                    $ECounter = $STODevice.Events
                    $STODevice.Events = $ECounter + 1
                    $STODevice.EventDescriptionsText = $OrphanEvent.Description
                }
            }
        }
        
        Write-Host $OrphanEvents
        $TD_IC_DashBoardSTODevice.ItemsSource = $DashBoardSTODeviceView
        $TD_TB_STODEVCount.Text = $DeviceCounter

    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message -ForegroundColor Red
        
    }finally{
        if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLConnection.State -eq 'Open') { $SQLConnection.Close() }
        #$DashBoardSTODeviceView = $null
        #$SQLConnection.Dispose()
    }
}