function SST_DashBoardSAN {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        $SQLConnection
    )
    
        $DashBoardSANDeviceView = [System.Collections.Generic.List[object]]::new()
        $DeviceCounter = 0

    try {
        $SQLConnection.Open()
        $SQLiteCommand = $SQLConnection.CreateCommand()
        $SQLiteCommand.CommandText = $Query

        $SST_SQLiteDBReader = $SQLiteCommand.ExecuteReader()

        #Name, Status, CodeLevel, BrocadeProdName, MTM, SerialNumber, TimeStamp
        while ($SST_SQLiteDBReader.Read()) {
            $DeviceCounter++
            $DashBoardSANsObj = [PSCustomObject]@{
            Name  = $SST_SQLiteDBReader["Name"]
            Status    = $SST_SQLiteDBReader["Status"]
            CodeLevel  = $SST_SQLiteDBReader["CodeLevel"]
            BrocadeProdName = $SST_SQLiteDBReader["BrocadeProdName"]
            MTM = $SST_SQLiteDBReader["MTM"]
            SerialNumber    = $SST_SQLiteDBReader["SerialNumber"]
            TimeStamp = $SST_SQLiteDBReader["TimeStamp"]
            }
            $DashBoardSANDeviceView.Add($DashBoardSANsObj)
        }
        
        $TD_IC_DashBoardSANDevice.ItemsSource = $DashBoardSANDeviceView

        $TD_TB_SANDEVCount.Text = $DeviceCounter
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message -ForegroundColor Red
        
    }finally{
        if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLConnection.State -eq 'Open') { $SQLConnection.Close() }
        #$SQLConnection.Dispose()
    }
}