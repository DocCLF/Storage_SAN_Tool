function SST_DashBoardEvents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Query,
        [Parameter(Mandatory)]
        $SQLConnection,
        [int]$EventCounter = 0
    )
    
    try {
        $DashBoardEventsView = [System.Collections.Generic.List[object]]::new()
        $SQLConnection.Open()
        $SQLiteCommand = $SQLConnection.CreateCommand()
        $SQLiteCommand.CommandText = $Query
        $SST_SQLiteDBReader = $SQLiteCommand.ExecuteReader()
        #ID, SerialNumber, ObjectName, Status, ErrorCode, Description, TimeStamp
        while ($SST_SQLiteDBReader.Read()) {
            $EventCounter++
            $DashBoardEventsObj = [PSCustomObject]@{
                SerialNumber  = $SST_SQLiteDBReader["SerialNumber"]
                ObjectName  = $SST_SQLiteDBReader["ObjectName"]
                Status = $SST_SQLiteDBReader["Status"]
                ErrorCode = $SST_SQLiteDBReader["ErrorCode"]
                Description = $SST_SQLiteDBReader["Description"]
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
            }
            $DashBoardEventsView.Add($DashBoardEventsObj)
        }

        $TD_TB_STOEventsCount.Text = $EventCounter
        if($EventCounter -ge 1){
            $TD_TB_HealthStatus.Text = "Attention"
            $TD_TB_HealthStatus.Foreground = "Orange"
            $TD_TB_STOEventsCount.Foreground = "Orange"
        }
        return $DashBoardEventsView
    }
    catch {
        Write-Host $_.Exception.Message
    }
    finally{
        #if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLConnection.State -eq 'Open') { $SQLConnection.Close() }
        #$SQLConnection.Dispose()
    }
    
}