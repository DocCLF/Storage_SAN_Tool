function STO_HostStateInfo {
    [CmdletBinding()]
    param (
        [string]$STOWWN,
        [string]$STOSN,
        [string]$STOHostID,
        [string]$STOHostStatus
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    if (-not [string]::IsNullOrWhiteSpace($TD_TB_CustomerInfoName.Text)) {
        $Customer = $TD_TB_CustomerInfoName.Text
    } else {
        $Customer = $SST_NewDBObject.CustomerNumber
    }
    #Write-Host "Customer $Customer"
    $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
    $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"
    $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
    $SQLiteDBConnection.Open()
    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
    $SQLiteCommand.CommandText = "WITH LastEntry AS (SELECT Status, TimeStamp FROM IBMSTOHostTable WHERE WWNN = @WWNN AND HID = @HID AND SerialNumber = @SerialNumber ORDER BY TimeStamp DESC LIMIT 1)`
                                    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM LastEntry) THEN 'NEW_HOST'`
                                    WHEN (SELECT Status FROM LastEntry) IS NOT @CurrentStatus THEN 'STATUS_CHANGED'`
                                    ELSE 'NO_CHANGE' END AS CheckResult,`
                                    @CurrentStatus AS CurrentStatus, @CurrentTimeStamp AS CurrentTimeStamp, (SELECT Status FROM LastEntry) AS StoredStatus, (SELECT TimeStamp FROM LastEntry) AS StoredTimeStamp;"
    $SQLiteCommand.Parameters.Clear()
    $SQLiteCommand.Parameters.AddWithValue("@WWNN", $STOWWN) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@HID", $STOHostID) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $STOSN) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@CurrentStatus", $STOHostStatus) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@CurrentTimeStamp", $TimeStamp) | Out-Null
    $Reader = $SQLiteCommand.ExecuteReader()
    
    try {
        if ($Reader.Read()) {
        
            $Result = [PSCustomObject]@{
                CheckResult      = $Reader["CheckResult"]
            
                WWNN             = $STOWWN
                HID              = $STOHostID
                SerialNumber     = $STOSN
            
                CurrentStatus    = $Reader["CurrentStatus"]
                CurrentTimeStamp = $Reader["CurrentTimeStamp"]
            
                StoredStatus     = $Reader["StoredStatus"]
                StoredTimeStamp  = $Reader["StoredTimeStamp"]
            }
        
            switch ($Result.CheckResult) {
            
                "NEW_HOST" {
                    $Message = "NEW HOST | HID: $($Result.HID) | WWNN: $($Result.SerialNumber) | Status: $($Result.CurrentStatus)"
                    #Write-Host "NEW HOST found: HID $($Result.HID), WWNN $($Result.WWNN)" -ForegroundColor Cyan
                    $Global:HostStatusChanges.Add($Message)
                }
            
                "STATUS_CHANGED" {
                    $Message = "STATUS CHANGED | HID: $($Result.HID) | WWNN: $($Result.SerialNumber) | Status: $($Result.CurrentStatus)"
                    #Write-Host "STATUS CHANGED: $($Result.StoredStatus) -> $($Result.CurrentStatus)" -ForegroundColor Yellow
                    $Global:HostStatusChanges.Add($Message)
                }
            
                "NO_CHANGE" {
                    #Write-Host "NO CHANGE: $($Result.CurrentStatus)" -ForegroundColor Green
                }
            }
        
            $Result
        }
    }
    finally {
        if ($Reader) {
            $Reader.Close()
            $Reader.Dispose()
        }
    }
}