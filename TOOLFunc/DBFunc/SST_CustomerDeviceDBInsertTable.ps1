function SST_CustomerDeviceDBInsertTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("StorageDrive","StorageBase","StorageHostInfo","StorageEventLog","SANBase","SANPortInfo","FCPortStats","PowerHMC","PowerSysSummary","LPARSummary")]
        [string]$SST_InfoType,
        $SST_NewDBObject =$null,
        $SST_CollectedInformations,
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
        Write-Host "Customer $Customer"
        $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
        $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
        $SQLiteCommand = $null

    }
    
    process {

        # Objekt zum Einfügen
        switch ($SST_InfoType) {
            "StorageDrive" { 

                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){ 
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSTODriveTable (CustomerNbr, DriveID, SlotID, ProductID, DriveStatus, CurrentDriveFW, DriveCap, PhyDriveCap, PhyUsedDriveCap, EffeUsedDriveCap, SerialNumber, WWNN, TimeStamp)`
                                                    VALUES (@CustomerNbr, @DriveID, @SlotID, @ProductID, @DriveStatus, @CurrentDriveFW, @DriveCap, @PhyDriveCap, @PhyUsedDriveCap, @EffeUsedDriveCap, @SerialNumber, @WWNN, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@DriveID", $SST_CollectedInformation.ID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SlotID", $SST_CollectedInformation.SlotID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ProductID", $SST_CollectedInformation.ProductID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@DriveStatus", $SST_CollectedInformation.Status) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CurrentDriveFW", $SST_CollectedInformation.FirmwareLevel) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@DriveCap", $SST_CollectedInformation.Capacity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhyDriveCap", $SST_CollectedInformation.PhysicalCapacity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhyUsedDriveCap", $SST_CollectedInformation.PhysicalUsedCapacity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@EffeUsedDriveCap", $SST_CollectedInformation.EffectiveUsedCapacity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 256 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTODriveTable WHERE ID NOT IN ( SELECT ID FROM IBMSTODriveTable ORDER BY TimeStamp DESC LIMIT 256 );"
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                        
                    }
                }
                catch {
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
            "StorageBase" { 

                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations[0]){ 
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSTOHWTable (CustomerNbr, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, RecommendedPTF, MDiskTotalCapacity, MDiskFreeCapacity, MDiskUsedCapacity,`
                                                    PhysicalTotalCapacity, PhysicalFreeCapacity, HostUnmap, BackendUnmap, Topology, Layer, QuorumMode, TimeStamp)`
                                                    VALUES (@CustomerNbr, @Name, @ClusterName, @WWNN, @Status, @IOgroupid, @IOgroupName, @SerialNumber, @CodeLevel, @ConfigNode, @SideID, @SideName, @ProdMTM, @RecommendedPTF, @MDiskTotalCapacity, @MDiskFreeCapacity, @MDiskUsedCapacity,`
                                                    @PhysicalTotalCapacity, @PhysicalFreeCapacity, @HostUnmap, @BackendUnmap, @Topology, @Layer, @QuorumMode, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.Name) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ClusterName", $SST_CollectedInformation.ClusterName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@IOgroupid", $SST_CollectedInformation.IO_group_id) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@IOgroupName", $SST_CollectedInformation.IO_group_Name) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.CodeLevel) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ConfigNode", $SST_CollectedInformation.ConfigNode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SideID", $SST_CollectedInformation.SideID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SideName", $SST_CollectedInformation.SideName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ProdMTM", $SST_CollectedInformation.ProdMTM) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RecommendedPTF", $SST_CollectedInformation.RecommendedPTF) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MDiskTotalCapacity", $SST_CollectedInformation.'MDiskTotalCapacity') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MDiskFreeCapacity", $SST_CollectedInformation.'MDiskFreeCapacity') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MDiskUsedCapacity", $SST_CollectedInformation.'MDiskUsedCapacity') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhysicalTotalCapacity", $SST_CollectedInformation.'PhysicalTotalCapacity') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhysicalFreeCapacity", $SST_CollectedInformation.'PhysicalFreeCapacity') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HostUnmap", $SST_CollectedInformation.'HostUnmap') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BackendUnmap", $SST_CollectedInformation.'BackendUnmap') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Topology", $SST_CollectedInformation.Topology) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Layer", $SST_CollectedInformation.Layer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@QuorumMode", $SST_CollectedInformation.QuorumMode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTOHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOHWTable ORDER BY TimeStamp DESC LIMIT 128 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                }
                finally {
                        <#Do this after the try block regardless of whether an exception occurred or not#>
                        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                        if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }

                        # If you want to delete files afterwards, extra good:
                        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            "StorageHostInfo" { 
                
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSTOHostTable (CustomerNbr, HID, HostName, Status, HostClusterName, SideName, STOName, WWNN, SerialNumber, TimeStamp) VALUES (@CustomerNbr, @HID, @HostName, @Status, @HostClusterName, @SideName, @STOName, @WWNN, @SerialNumber, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HID", $SST_CollectedInformation.ID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HostName", $SST_CollectedInformation.HostName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HostClusterName", $SST_CollectedInformation.HostClusterName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SideName", $SST_CollectedInformation.SiteName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@STOName", $SST_CollectedInformation.STOName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTOHostTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOHostTable ORDER BY TimeStamp DESC LIMIT 128 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                }
                finally {
                        <#Do this after the try block regardless of whether an exception occurred or not#>
                        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                        if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }

                        # If you want to delete files afterwards, extra good:
                        [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            "StorageEventLog" {

                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSTOEventsTable (CustomerNbr, SeqID, LastTime, ObjectType, ObjectID, ObjectName, CopyID, Status, Fixed, ErrorCode, Description, WWNN, SerialNumber, TimeStamp)`
                                                    VALUES (@CustomerNbr, @SeqID, @LastTime, @ObjectType, @ObjectID, @ObjectName, @CopyID, @Status, @Fixed, @ErrorCode, @Description, @WWNN, @SerialNumber, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SeqID", $SST_CollectedInformation.SeqID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LastTime", $SST_CollectedInformation.LastTime) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ObjectType", $SST_CollectedInformation.ObjectType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ObjectID", $SST_CollectedInformation.ObjectID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ObjectName", $SST_CollectedInformation.ObjectName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CopyID", $SST_CollectedInformation.CopyID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Fixed", $SST_CollectedInformation.Fixed) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ErrorCode", $SST_CollectedInformation.ErrorCode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Description", $SST_CollectedInformation.Description) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 500 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTOEventsTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOEventsTable ORDER BY TimeStamp DESC LIMIT 500 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
                    if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }
                    # If you want to delete files afterwards, extra good:
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }

            }
            "FCPortStats" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSTOFCPortStatsTable (CustomerNbr, CardType, CardID, PortID, WWPN, LinkFailure, LoseSync, LoseSig, PSErrCount, InvTransErr, CRCErr, ZeroBtB, SFPTemp, TXPwr, RXPwr, WWNN, SerialNumber, TimeStamp)`
                                                            VALUES (@CustomerNbr, @CardType, @CardID, @PortID, @WWPN, @LinkFailure, @LoseSync, @LoseSig, @PSErrCount, @InvTransErr, @CRCErr, @ZeroBtB, @SFPTemp, @TXPwr, @RXPwr, @WWNN, @SerialNumber, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CardType", $SST_CollectedInformation.CardType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CardID", $SST_CollectedInformation.CardID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PortID", $SST_CollectedInformation.PortID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWPN", $SST_CollectedInformation.WWPN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LinkFailure", $SST_CollectedInformation.LinkFailure) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LoseSync", $SST_CollectedInformation.LoseSync) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LoseSig", $SST_CollectedInformation.LoseSig) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PSErrCount", $SST_CollectedInformation.PSErrCount) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@InvTransErr", $SST_CollectedInformation.InvTransErr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CRCErr", $SST_CollectedInformation.CRCErr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ZeroBtB", $SST_CollectedInformation.ZeroBtB) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SFPTemp", $SST_CollectedInformation.SFPTemp) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TXPwr", $SST_CollectedInformation.TXPwr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RXPwr", $SST_CollectedInformation.RXPwr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                        # DB save
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 1000 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTOFCPortStatsTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOFCPortStatsTable ORDER BY TimeStamp DESC LIMIT 1000 );"
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
            "SANBase" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSANHWTable (CustomerNbr, Name, Status, CodeLevel, BrocadeProdName, MTM, SerialNumber, SwitchWWNN, TimeStamp) VALUES (@CustomerNbr, @Name, @Status, @CodeLevel, @BrocadeProdName, @MTM, @SerialNumber, @SwitchWWNN, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.'SwichtName') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.'SwitchState') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.'FabricOS') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BrocadeProdName", $SST_CollectedInformation.'BrocadeProductName') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.'MTM') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.'SerialNumber') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.'SwitchWWNN') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 16 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSANHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSANHWTable ORDER BY TimeStamp DESC LIMIT 16 );"
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
            "SANPortInfo" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSANPortInfoTable (CustomerNbr, Port, State, Speed, PortConnect, SerialNumber, SwitchWWNN, TimeStamp) VALUES (@CustomerNbr, @Port, @State, @Speed, @PortConnect, @SerialNumber, @SwitchWWNN, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Port", $SST_CollectedInformation.Port) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Speed", $SST_CollectedInformation.Speed) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PortConnect", $SST_CollectedInformation.PortConnect) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.SwitchWWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Then automatically clean up for this exact switch
                        $SQLiteCommand.CommandText ="DELETE FROM IBMSANPortInfoTable WHERE ID NOT IN (SELECT ID FROM (SELECT ID FROM IBMSANPortInfoTable AS t WHERE (SELECT COUNT(*) FROM IBMSANPortInfoTable AS x WHERE x.SwitchWWNN = t.SwitchWWNN AND x.Port = t.Port AND datetime(x.TimeStamp) >= datetime(t.TimeStamp) ) <= 1 ));" 
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

                        $SQLiteCommand.CommandText ="INSERT INTO PowerSysSummary (CustomerNbr, SystemName, MachineTypeModel, SerialNumber, State, UUID, TimeStamp)`
                                                    VALUES (@CustomerNbr, @SystemName, @MachineTypeModel, @SerialNumber, @State, @UUID, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SystemName", $SST_CollectedInformation.SystemName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MachineTypeModel", $SST_CollectedInformation.MachineTypeModel) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@UUID", $SST_CollectedInformation.UUID) | Out-Null
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
        #Verbindung schließen
        #$SST_CollectedInformations =$null
        #$SST_SQLiteCon.Close()
        #$SST_SQLiteCon.Dispose()
    }
}