function SAN_PortStateInfo {
    [CmdletBinding()]
    param (
        [string]$SANSwitchWWNN,
        [string]$SANSerialNumber,
        [string]$SANPort,
        [string]$SANState
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
    $SQLiteCommand.CommandText = "WITH LastEntry AS (SELECT State, TimeStamp FROM IBMSANPortInfoTable WHERE SwitchWWNN = @SwitchWWNN AND Port = @Port AND SerialNumber = @SerialNumber ORDER BY TimeStamp DESC LIMIT 1)`
                                    SELECT CASE WHEN NOT EXISTS (SELECT 1 FROM LastEntry) THEN 'NEW_PORT'`
                                    WHEN (SELECT State FROM LastEntry) IS NOT @CurrentState THEN 'STATE_CHANGED'`
                                    ELSE 'NO_CHANGE' END AS CheckResult,`
                                    @CurrentState AS CurrentState, @CurrentTimeStamp AS CurrentTimeStamp, (SELECT State FROM LastEntry) AS StoredState, (SELECT TimeStamp FROM LastEntry) AS StoredTimeStamp;"
    $SQLiteCommand.Parameters.Clear()
    $SQLiteCommand.Parameters.AddWithValue("@SwitchWWNN", $SANSwitchWWNN) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@Port", $SANPort) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SANSerialNumber) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@CurrentState", $SANState) | Out-Null
    $SQLiteCommand.Parameters.AddWithValue("@CurrentTimeStamp", $TimeStamp) | Out-Null
    $Reader = $SQLiteCommand.ExecuteReader()
    
    try {
        if ($Reader.Read()) {
        
            $Result = [PSCustomObject]@{
                CheckResult      = $Reader["CheckResult"]
            
                WWNN             = $SANSwitchWWNN
                Port              = $SANPort
                SerialNumber     = $SANSerialNumber
            
                CurrentStatus    = $Reader["CurrentStatus"]
                CurrentTimeStamp = $Reader["CurrentTimeStamp"]
            
                StoredStatus     = $Reader["StoredStatus"]
                StoredTimeStamp  = $Reader["StoredTimeStamp"]
            }
        
            switch ($Result.CheckResult) {
            
                "NEW_PORT" {
                    $Message = "NEW PORT | Port: $($Result.Port) | WWNN: $($Result.SerialNumber) | State: $($Result.CurrentStatus)"
                    #Write-Host "NEW PORT found: Port $($Result.Port), WWNN $($Result.WWNN)" -ForegroundColor Cyan
                    $Global:HostStatusChanges.Add($Message)
                }
            
                "STATE_CHANGED" {
                    $Message = "STATE CHANGED | Port: $($Result.Port) | WWNN: $($Result.SerialNumber) | State: $($Result.CurrentStatus)"
                    #Write-Host "STATE CHANGED: $($Result.StoredStatus) -> $($Result.CurrentStatus)" -ForegroundColor Yellow
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
function Get-BrocadeVFIDsFromDB {
    param (
        $Device
    )
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    if (-not [string]::IsNullOrWhiteSpace($TD_TB_CustomerInfoName.Text)) {
        $Customer = $TD_TB_CustomerInfoName.Text
    } else {
        $Customer = $SST_NewDBObject.CustomerNumber
    }
    $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
    $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"
    $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
    $SQLiteDBConnection.Open()
    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
    $SQLiteCommand.CommandText = "SELECT DISTINCT VFID FROM IBMSANHWTable WHERE CustomerNbr = @CustomerNbr AND Name = @Name AND TimeStamp = (SELECT MAX(TimeStamp)`
                                    FROM IBMSANHWTable WHERE CustomerNbr = @CustomerNbr AND Name = @Name)`
                                    AND VFID IS NOT NULL AND VFID <> '' ORDER BY VFID;"

    $null = $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer)
    $null = $SQLiteCommand.Parameters.AddWithValue('@Name',$Device.DeviceName)
    try{
        $Reader = $SQLiteCommand.ExecuteReader()

        $VFIDs = @()

        while($Reader.Read()){

            $VFIDs += $Reader['VFID']
        }

        $Reader.Close()

        return @($VFIDs -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
            )
    }
    finally {
        if ($Reader) {
            $Reader.Close()
            $Reader.Dispose()
        }
    }
}