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
                    $Global:HostStatusChanges.Add($Message) | Out-Null
                }
            
                "STATUS_CHANGED" {
                    $Message = "STATUS CHANGED | HID: $($Result.HID) | WWNN: $($Result.SerialNumber) | Status: $($Result.CurrentStatus)"
                    #Write-Host "STATUS CHANGED: $($Result.StoredStatus) -> $($Result.CurrentStatus)" -ForegroundColor Yellow
                    $Global:HostStatusChanges.Add($Message) | Out-Null
                }
            
                "NO_CHANGE" {
                    #Write-Host "NO CHANGE: $($Result.CurrentStatus)" -ForegroundColor Green
                }
            }
        
            return $Result
        }
        return $null
    }
    finally {
        if ($Reader) {
            $Reader.Close()
            $Reader.Dispose()
        }
    }
}

function Get-StorageVolumeInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^\d{6}$')]
        [string]$CustomerNbr,

        [string]$SerialNumber,

        [switch]$OnlyActive
    )

    $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$CustomerNbr.db"

    $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

    $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString

    $SQLiteCommand = $null
    $Reader = $null

    try {

        $SQLiteDBConnection.Open()
        $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
        $WhereParts = [System.Collections.Generic.List[string]]::new()

        $WhereParts.Add( 'CustomerNbr = @CustomerNbr')
        $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$CustomerNbr) | Out-Null

        if (-not [string]::IsNullOrWhiteSpace($SerialNumber)) {
            $WhereParts.Add('SerialNumber = @SerialNumber')
            $SQLiteCommand.Parameters.AddWithValue('@SerialNumber',$SerialNumber) | Out-Null
        }

        if ($OnlyActive) {$WhereParts.Add('IsActive = 1')}

        $SQLiteCommand.CommandText = "SELECT CustomerNbr,SerialNumber,WWNN,VolumeID,VdiskUID,VolumeName,RowID,IsActive,FirstSeen,LastSeen,TimeStamp FROM IBMSTOVolumeInventoryTable WHERE $($WhereParts -join ' AND ') ORDER BY SerialNumber,VolumeID;"
        $Reader = $SQLiteCommand.ExecuteReader()
        $Result = @(
            while ($Reader.Read()) {

                [PSCustomObject]@{
                    CustomerNbr  = [string]$Reader['CustomerNbr']
                    SerialNumber = [string]$Reader['SerialNumber']
                    WWNN         = [string]$Reader['WWNN']
                    VolumeID     = [string]$Reader['VolumeID']
                    VdiskUID     = [string]$Reader['VdiskUID']
                    VolumeName   = [string]$Reader['VolumeName']
                    RowID        = [string]$Reader['RowID']
                    IsActive     = [int]$Reader['IsActive']
                    FirstSeen    = [string]$Reader['FirstSeen']
                    LastSeen     = [string]$Reader['LastSeen']
                    TimeStamp    = [string]$Reader['TimeStamp']
                }
            }
        )
        return $Result
    }
    catch {

        Write-Host ('Get-StorageVolumeInventory Fehler: ' + $_.Exception.Message) -ForegroundColor Red
        Write-Host $_.InvocationInfo.PositionMessage
        Write-Host $_.Exception.ToString()

        throw
    }
    finally {

        if ($null -ne $Reader) {$Reader.Close(); $Reader.Dispose()}
        if ($null -ne $SQLiteCommand) {$SQLiteCommand.Dispose()}
        if ($null -ne $SQLiteDBConnection) {
            if ($SQLiteDBConnection.State -ne [System.Data.ConnectionState]::Closed) {
                $SQLiteDBConnection.Close()
            }
            $SQLiteDBConnection.Dispose()
        }
        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
    }
}