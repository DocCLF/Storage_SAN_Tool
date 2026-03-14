function SST_PRISMDBControl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("StorageDrive","StorageBase","StorageHostInfo","StorageEventLog","SANBase","FCPortStats")]
        [string]$SST_InfoType,
        $CustomerNumber =$null,
        [bool]$AZConnection = $false,
        [array]$SST_CollectedInformations,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar

        try {
            $TD_AZDBObj = SST_ToolAdvSaveDB -SST_InfoType "LoadPRISMSettings"
            $ConString = Convert-SecureStringToPlainText ($TD_AZDBObj.AZConString | ConvertTo-SecureString)
            $AZCredP  = Convert-SecureStringToPlainText ($TD_AZDBObj.AZCredP | ConvertTo-SecureString)
            $ConnectionStringPRISM = $ConString.Replace('{replaceone}',[string]$TD_AZDBObj.IsCustomerNBR).Replace('{replacetwo}',"$AZCredP")
            $ConString = $null
            $AZCredP = $null
        }
        catch {
            <#Do this if a terminating exception happens#>
            #SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        }

        try {
            $SQLConnection=New-Object System.Data.SqlClient.SqlConnection
            $SQLConnection.ConnectionString=$ConnectionStringPRISM 
            $ConnectionStringPRISM = $null
            while (!($AZConnection)) {
                if($SQLConnection.State -eq "open"){
                    $AZConnection =$true
                    SST_ToolMessageCollector -TD_ToolMSGCollector $("SST_PRISMDBControl Func State $($SQLConnection.State)") -TD_ToolMSGType Message -TD_Shown yes
                }else {
                    $SQLConnection.Open()
                    SST_ToolMessageCollector -TD_ToolMSGCollector $("SST_PRISMDBControl Func State $($SQLConnection.State)") -TD_ToolMSGType Message -TD_Shown no
                }
                <# Progressbar  #>
                $ProgCounter++
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Please wait while the connection is being established" -PercentComplete ((10/50) * 100)
            }
            Close-ProgressBar -ProgressBar $ProgressBar
        }
        catch {
            #SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM Status $($SQLConnection.Open()) Info: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
            #SST_ToolMessageCollector -TD_ToolMSGCollector $("SST_PRISMDBControl Func there is a problem with the CustomerNumber") -TD_ToolMSGType Error -TD_Shown yes
        }
    }
    
    process {

        switch ($SST_InfoType) {
            "StorageBase" { 

                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations[0]){ 
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="INSERT INTO IBMSTOHWTable (CustomerNbr, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, RecommendedPTF, MDiskTotalCapacity, MDiskFreeCapacity, MDiskUsedCapacity,`
                                                    PhysicalTotalCapacity, PhysicalFreeCapacity, HostUnmap, BackendUnmap, Topology, Layer, QuorumMode, TimeStamp)`
                                                    VALUES (@CustomerNbr, @Name, @ClusterName, @WWNN, @Status, @IOgroupid, @IOgroupName, @SerialNumber, @CodeLevel, @ConfigNode, @SideID, @SideName, @ProdMTM, @RecommendedPTF, @MDiskTotalCapacity, @MDiskFreeCapacity, @MDiskUsedCapacity,`
                                                    @PhysicalTotalCapacity, @PhysicalFreeCapacity, @HostUnmap, @BackendUnmap, @Topology, @Layer, @QuorumMode, @TimeStamp);"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.Name) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ClusterName", $SST_CollectedInformation.ClusterName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@IOgroupid", $SST_CollectedInformation.IO_group_id) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@IOgroupName", $SST_CollectedInformation.IO_group_Name) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.CodeLevel) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ConfigNode", $SST_CollectedInformation.ConfigNode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SideID", $SST_CollectedInformation.SideID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SideName", $SST_CollectedInformation.SideName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ProdMTM", $SST_CollectedInformation.ProdMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RecommendedPTF", $SST_CollectedInformation.RecommendedPTF) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MDiskTotalCapacity", $SST_CollectedInformation.'MDiskTotalCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MDiskFreeCapacity", $SST_CollectedInformation.'MDiskFreeCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MDiskUsedCapacity", $SST_CollectedInformation.'MDiskUsedCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhysicalTotalCapacity", $SST_CollectedInformation.'PhysicalTotalCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhysicalFreeCapacity", $SST_CollectedInformation.'PhysicalFreeCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HostUnmap", $SST_CollectedInformation.'HostUnmap') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BackendUnmap", $SST_CollectedInformation.'BackendUnmap') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Topology", $SST_CollectedInformation.Topology) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Layer", $SST_CollectedInformation.Layer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@QuorumMode", $SST_CollectedInformation.QuorumMode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save
                        $SQLCommand.ExecuteNonQuery()

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        #$SQLiteCommand.CommandText = "DELETE FROM IBMSTOHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOHWTable ORDER BY TimeStamp DESC LIMIT 128 );"
                        #$SQLiteCommand.ExecuteNonQuery()
                    }
                }
                finally {
                        <#Do this after the try block regardless of whether an exception occurred or not#>
                        if ($SQLCommand) { $SQLCommand.Dispose() }
                        if ($SQLConnection) { $SQLConnection.Close(); $SQLConnection.Dispose() }

                        # If you want to delete files afterwards, extra good:
                        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "StorageDrive" { 

                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){ 
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="INSERT INTO IBMSTODriveTable (CustomerNbr, DriveID, SlotID, ProductID, DriveStatus, CurrentDriveFW, DriveCap, PhyDriveCap, PhyUsedDriveCap, EffeUsedDriveCap, SerialNumber, WWNN, TimeStamp)`
                                                    VALUES (@CustomerNbr, @DriveID, @SlotID, @ProductID, @DriveStatus, @CurrentDriveFW, @DriveCap, @PhyDriveCap, @PhyUsedDriveCap, @EffeUsedDriveCap, @SerialNumber, @WWNN, @TimeStamp);"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DriveID", $SST_CollectedInformation.ID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SlotID", $SST_CollectedInformation.SlotID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ProductID", $SST_CollectedInformation.ProductID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DriveStatus", $SST_CollectedInformation.Status) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CurrentDriveFW", $SST_CollectedInformation.FirmwareLevel) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DriveCap", $SST_CollectedInformation.Capacity) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhyDriveCap", $SST_CollectedInformation.PhysicalCapacity) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhyUsedDriveCap", $SST_CollectedInformation.PhysicalUsedCapacity) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@EffeUsedDriveCap", $SST_CollectedInformation.EffectiveUsedCapacity) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 256 most recent entries after TimeStamp
                        #$SQLiteCommand.CommandText = "DELETE FROM IBMSTODriveTable WHERE ID NOT IN ( SELECT ID FROM IBMSTODriveTable ORDER BY TimeStamp DESC LIMIT 256 );"
                        #$SQLiteCommand.ExecuteNonQuery() | Out-Null
                        
                    }
                }
                catch {
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }               
                finally {
                        <#Do this after the try block regardless of whether an exception occurred or not#>
                        if ($SQLCommand) { $SQLCommand.Dispose() }
                        if ($SQLConnection) { $SQLConnection.Close(); $SQLConnection.Dispose() }

                        # If you want to delete files afterwards, extra good:
                        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }
            }
            "StorageEventLog" {

                try {
                    $SQLConnection.Open()
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="INSERT INTO IBMSTOEventsTable (CustomerNbr, SeqID, LastTime, ObjectType, ObjectID, ObjectName, CopyID, Status, Fixed, ErrorCode, Description, WWNN, SerialNumber, TimeStamp)`
                                                    VALUES (@CustomerNbr, @SeqID, @LastTime, @ObjectType, @ObjectID, @ObjectName, @CopyID, @Status, @Fixed, @ErrorCode, @Description, @WWNN, @SerialNumber, @TimeStamp);"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SeqID", $SST_CollectedInformation.SeqID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LastTime", $SST_CollectedInformation.LastTime) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ObjectType", $SST_CollectedInformation.ObjectType) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ObjectID", $SST_CollectedInformation.ObjectID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ObjectName", $SST_CollectedInformation.ObjectName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CopyID", $SST_CollectedInformation.CopyID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Fixed", $SST_CollectedInformation.Fixed) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorCode", $SST_CollectedInformation.ErrorCode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Description", $SST_CollectedInformation.Description) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save
                        $SQLCommand.ExecuteNonQuery()

                        # Delete | Keep only the 500 most recent entries after TimeStamp
                        $SQLCommand.CommandText = "DELETE FROM IBMSTOEventsTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOEventsTable ORDER BY TimeStamp DESC LIMIT 500 );"
                        $SQLCommand.ExecuteNonQuery()
                    }
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }
                    if ($SQLConnection) { $SQLConnection.Close(); $SQLConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "SANBase" {
                try {
                    $SQLConnection.Open()
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="INSERT INTO IBMSANHWTable (CustomerNbr, Name, Status, CodeLevel, BrocadeProdName, MTM, SerialNumber, SwitchWWNN, TimeStamp) VALUES (@CustomerNbr, @Name, @Status, @CodeLevel, @BrocadeProdName, @MTM, @SerialNumber, @SwitchWWNN, @TimeStamp);"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.'SwichtName') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.'SwitchState') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.'FabricOS') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BrocadeProdName", $SST_CollectedInformation.'BrocadeProductName') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.'MTM') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.'SerialNumber') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.'SwitchWWNN') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery()

                        # Delete | Keep only the 16 most recent entries after TimeStamp
                        # $SQLCommand.CommandText = "DELETE FROM IBMSANHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSANHWTable ORDER BY TimeStamp DESC LIMIT 16 );"
                        # $SQLCommand.ExecuteNonQuery()
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
                    if ($SQLConnection) { $SQLConnection.Close(); $SQLConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "PowerHMC" {
                try {
                    $SQLConnection.Open()
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="INSERT INTO PowerHMC (CustomerNbr, HMCName, HMCMTM, SerialNumber, HMCUUID, BIOS, DisplayVersion, BaseVersion, BuildLevel, IFix, ManagedSystemCount, ManagedSystemUUIDs, TimeStamp)`
                                                    VALUES (@CustomerNbr, @HMCName, @HMCMTM, @SerialNumber, @HMCUUID, @BIOS, @DisplayVersion, @BaseVersion, @BuildLevel, @IFix, @ManagedSystemCount , @ManagedSystemUUIDs , @TimeStamp);"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HMCName", $SST_CollectedInformation.HMCName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HMCMTM", $SST_CollectedInformation.HMCMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HMCUUID", $SST_CollectedInformation.UUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BIOS", $SST_CollectedInformation.BIOS) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DisplayVersion", $SST_CollectedInformation.DisplayVersion) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BaseVersion", $SST_CollectedInformation.BaseVersion) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BuildLevel", $SST_CollectedInformation.BuildLevel) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@IFix", $SST_CollectedInformation.IFix) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemCount", $SST_CollectedInformation.ManagedSystemCount) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemUUIDs", $SST_CollectedInformation.ManagedSystemUUIDs) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery()

                        # Delete | Keep only the 64 most recent entries after TimeStamp
                        $SQLCommand.CommandText = "DELETE FROM PowerHMC WHERE ID NOT IN ( SELECT ID FROM PowerHMC ORDER BY TimeStamp DESC LIMIT 64 );"
                        $SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }
                    if ($SQLConnection) { $SQLConnection.Close(); $SQLConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            "PowerSysSummary" {
                try {
                    $SQLConnection.Open()
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="INSERT INTO PowerSysSummary (CustomerNbr, SystemName, MachineTypeModel, SerialNumber, State, UUID, TimeStamp)`
                                                    VALUES (@CustomerNbr, @SystemName, @MachineTypeModel, @SerialNumber, @State, @UUID, @TimeStamp);"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SystemName", $SST_CollectedInformation.SystemName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MachineTypeModel", $SST_CollectedInformation.MachineTypeModel) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@UUID", $SST_CollectedInformation.UUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                        # DB save 
                        $SQLCommand.ExecuteNonQuery()

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        $SQLCommand.CommandText = "DELETE FROM PowerSysSummary WHERE ID NOT IN ( SELECT ID FROM PowerSysSummary ORDER BY TimeStamp DESC LIMIT 128 );"
                        $SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }
                    if ($SQLConnection) { $SQLConnection.Close(); $SQLConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            "LPARSummary" {
                try {
                    $SQLConnection.Open()
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="INSERT INTO LPARSummary (CustomerNbr, ManagedSystemName, ManagedSystemUUID, ManagedSystemMTMS, ManagedSystemSerial, LparName, LparUUID, PartitionId, State,Environment,OsVersion, RmcIp, RmcState, DefaultProfile, CurrentProcessingUnits, CurrentMemoryMB, TimeStamp)`
                                                    VALUES (@CustomerNbr, @ManagedSystemName, @ManagedSystemUUID, @ManagedSystemMTMS, @ManagedSystemSerial, @LparName, @LparUUID, @PartitionId, @State, @Environment, @OsVersion, @RmcIp, @RmcState, @DefaultProfile, @CurrentProcessingUnits, @CurrentMemoryMB, @TimeStamp);"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemName", $SST_CollectedInformation.ManagedSystemName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemUUID", $SST_CollectedInformation.ManagedSystemUUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemMTMS", $SST_CollectedInformation.ManagedSystemMTMS) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemSerial", $SST_CollectedInformation.ManagedSystemSerial) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LparName", $SST_CollectedInformation.LparName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LparUUID", $SST_CollectedInformation.LparUUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PartitionId", $SST_CollectedInformation.PartitionId) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Environment", $SST_CollectedInformation.Environment) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@OsVersion", $SST_CollectedInformation.OsVersion) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RmcIp", $SST_CollectedInformation.RmcIp) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RmcState", $SST_CollectedInformation.RmcState) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DefaultProfile", $SST_CollectedInformation.DefaultProfile) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CurrentProcessingUnits", $SST_CollectedInformation.CurrentProcessingUnits) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CurrentMemoryMB", $SST_CollectedInformation.CurrentMemoryMB) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery()

                        # Delete | Keep only the 1024 most recent entries after TimeStamp
                        $SQLCommand.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                        $SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }
                    if ($SQLConnection) { $SQLConnection.Close(); $SQLConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong during saving the $SST_InfoType data in the local db.") -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {
        $SQLConnection.Close()
    }
}