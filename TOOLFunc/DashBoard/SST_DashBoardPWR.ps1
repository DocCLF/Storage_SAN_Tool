function SST_DashBoardPWR {
[CmdletBinding()]
 param (
        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        $SQLConnection
    )
    $DashBoardPWRDeviceView = [System.Collections.Generic.List[object]]::new()
    $DeviceCounter = 0

    try {
        $SQLConnection.Open()
        $SQLiteCommand = $SQLConnection.CreateCommand()
        $SQLiteCommand.CommandText = $Query

        $SST_SQLiteDBReader = $SQLiteCommand.ExecuteReader()
        #ID, SystemName, State, MachineTypeModel, SerialNumber, ECNumber, ActivatedLevel, TimeStamp
        # need a workaround if PB is used
        while ($SST_SQLiteDBReader.Read()) {
            $DeviceCounter++

            $DashBoardSTOsObj = [PSCustomObject]@{
                PWRSYSName  = $SST_SQLiteDBReader["SystemName"]
                PWRSYSStatus  = $SST_SQLiteDBReader["State"]
                PWRSYSProdMTM = $SST_SQLiteDBReader["MachineTypeModel"]
                PWRSYSSerialNumber = $SST_SQLiteDBReader["SerialNumber"]
                PWRSYSECNumber = $SST_SQLiteDBReader["ECNumber"]
                PWRSYSIPLActiLev  = $SST_SQLiteDBReader["ActivatedLevel"]
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
            }
            $DashBoardPWRDeviceView.Add($DashBoardSTOsObj)
        }

        $TD_IC_IBMPowerSYSObjView.ItemsSource = $DashBoardPWRDeviceView
        #$TD_TB_STODEVCount.Text = $DeviceCounter

    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message -ForegroundColor Red
        
    }finally{
        if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLConnection.State -eq 'Open') { $SQLConnection.Close() }
        $DashBoardPWRDeviceView = $null
        #$SQLConnection.Dispose()
    }
    
}