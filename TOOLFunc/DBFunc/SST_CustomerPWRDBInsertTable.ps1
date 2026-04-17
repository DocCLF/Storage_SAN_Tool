function SST_CustomerPWRDBInsertTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("PowerHMC","PowerSysSummary","LPARSummary")]
        [string]$SST_InfoType,
        $SST_NewDBObject =$null,
        $SST_CollectedInformations,
        $SST_Customer,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"

        if (-not [string]::IsNullOrWhiteSpace($SST_Customer)) {
            $Customer = $SST_Customer
        } elseif (-not [string]::IsNullOrWhiteSpace($TD_TB_CustomerInfoName.Text)) {
            $Customer = $TD_TB_CustomerInfoName.Text
        } else {
            $Customer = $SST_NewDBObject.CustomerNumber
        }
        #Write-Host "Customer $Customer"
        $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
        $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
        $SQLiteCommand = $null
    }
    
    process {

        # Objekt zum Einfügen
        switch ($SST_InfoType) {
            "PowerHMC" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO PowerHMC (CustomerNbr, HMCName, HMCMTM, SerialNumber, HMCUUID, BIOS, DisplayVersion, BaseVersion, BuildLevel, IFix, ManagedSystemCount, ManagedSystemUUIDs, TimeStamp)`
                                                    VALUES (@CustomerNbr, @HMCName, @HMCMTM, @SerialNumber, @HMCUUID, @BIOS, @DisplayVersion, @BaseVersion, @BuildLevel, @IFix, @ManagedSystemCount , @ManagedSystemUUIDs , @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HMCName", $SST_CollectedInformation.HMCName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HMCMTM", $SST_CollectedInformation.HMCMTM) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HMCUUID", $SST_CollectedInformation.UUID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BIOS", $SST_CollectedInformation.BIOS) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@DisplayVersion", $SST_CollectedInformation.DisplayVersion) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BaseVersion", $SST_CollectedInformation.BaseVersion) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BuildLevel", $SST_CollectedInformation.BuildLevel) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@IFix", $SST_CollectedInformation.IFix) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ManagedSystemCount", $SST_CollectedInformation.ManagedSystemCount) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ManagedSystemUUIDs", $SST_CollectedInformation.ManagedSystemUUIDs) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 64 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM PowerHMC WHERE ID NOT IN ( SELECT ID FROM PowerHMC ORDER BY TimeStamp DESC LIMIT 64 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                    if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            "PowerSysSummary" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO PowerSysSummary (CustomerNbr, SystemName, MachineTypeModel, SerialNumber, ECNumber, ActivatedLevel, State, UUID, URL, TimeStamp)`
                                                    VALUES (@CustomerNbr, @SystemName, @MachineTypeModel, @SerialNumber, @ECNumber, @ActivatedLevel, @State, @UUID, @URL, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SystemName", $SST_CollectedInformation.SystemName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MachineTypeModel", $SST_CollectedInformation.MachineTypeModel) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ECNumber", $SST_CollectedInformation.ECNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ActivatedLevel", $SST_CollectedInformation.ActivatedLevel) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@UUID", $SST_CollectedInformation.UUID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@URL", $SST_CollectedInformation.Url) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM PowerSysSummary WHERE ID NOT IN ( SELECT ID FROM PowerSysSummary ORDER BY TimeStamp DESC LIMIT 128 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                    if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            "LPARSummary" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LPARSummary (CustomerNbr, ManagedSystemName, ManagedSystemUUID, ManagedSystemMTMS, ManagedSystemSerial, LparName, LparUUID, PartitionId, State,Environment,OsVersion, RmcIp, RmcState, DefaultProfile, CurrentProcessingUnits, CurrentMemoryMB, TimeStamp)`
                                                    VALUES (@CustomerNbr, @ManagedSystemName, @ManagedSystemUUID, @ManagedSystemMTMS, @ManagedSystemSerial, @LparName, @LparUUID, @PartitionId, @State, @Environment, @OsVersion, @RmcIp, @RmcState, @DefaultProfile, @CurrentProcessingUnits, @CurrentMemoryMB, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ManagedSystemName", $SST_CollectedInformation.ManagedSystemName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ManagedSystemUUID", $SST_CollectedInformation.ManagedSystemUUID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ManagedSystemMTMS", $SST_CollectedInformation.ManagedSystemMTMS) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ManagedSystemSerial", $SST_CollectedInformation.ManagedSystemSerial) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LparName", $SST_CollectedInformation.LparName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LparUUID", $SST_CollectedInformation.LparUUID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PartitionId", $SST_CollectedInformation.PartitionId) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Environment", $SST_CollectedInformation.Environment) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@OsVersion", $SST_CollectedInformation.OsVersion) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RmcIp", $SST_CollectedInformation.RmcIp) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RmcState", $SST_CollectedInformation.RmcState) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@DefaultProfile", $SST_CollectedInformation.DefaultProfile) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CurrentProcessingUnits", $SST_CollectedInformation.CurrentProcessingUnits) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CurrentMemoryMB", $SST_CollectedInformation.CurrentMemoryMB) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 1024 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                    if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong during saving the $SST_InfoType data in the local db.") -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {

    }
}