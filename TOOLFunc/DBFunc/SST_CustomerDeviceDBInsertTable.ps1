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
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTOFCPortStatsTable (CardType, CardID, PortID, WWPN, LinkFailure, LoseSync, LoseSig, PSErrCount, InvTransErr, CRCErr, ZeroBtB, SFPTemp, TXPwr, RXPwr, WWNN, SerialNumber, TimeStamp) VALUES (@CardType, @CardID, @PortID, @WWPN, @LinkFailure, @LoseSync, @LoseSig, @PSErrCount, @InvTransErr, @CRCErr, @ZeroBtB, @SFPTemp, @TXPwr, @RXPwr, @WWNN, @SerialNumber, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CardType", $SST_CollectedInformation.CardType) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CardID", $SST_CollectedInformation.CardID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PortID", $SST_CollectedInformation.PortID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@WWPN", $SST_CollectedInformation.WWPN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LinkFailure", $SST_CollectedInformation.LinkFailure) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LoseSync", $SST_CollectedInformation.LoseSync) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LoseSig", $SST_CollectedInformation.LoseSig) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PSErrCount", $SST_CollectedInformation.PSErrCount) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@InvTransErr", $SST_CollectedInformation.InvTransErr) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CRCErr", $SST_CollectedInformation.CRCErr) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ZeroBtB", $SST_CollectedInformation.ZeroBtB) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SFPTemp", $SST_CollectedInformation.SFPTemp) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TXPwr", $SST_CollectedInformation.TXPwr) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@RXPwr", $SST_CollectedInformation.RXPwr) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.NodeWWNN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.NodeSN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                    # DB save
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Delete | Keep only the 1000 most recent entries after TimeStamp
                    $SST_SQliteInsertCMD.CommandText = "DELETE FROM IBMSTOFCPortStatsTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOFCPortStatsTable ORDER BY TimeStamp DESC LIMIT 1000 );"
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "SANBase" {
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSANHWTable (Name, Status, CodeLevel, CodeLevelLV, BrocadeProdName, MTM, SerialNumber, TimeStamp) VALUES (@Name, @Status, @CodeLevel, @CodeLevelLV, @BrocadeProdName, @MTM, @SerialNumber, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Name", $SST_CollectedInformation.'Swicht Name') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Status", $SST_CollectedInformation.'Switch State') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.'Fabric OS') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CodeLevelLV", $SST_CollectedInformation.'Fabric OSLV') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@BrocadeProdName", $SST_CollectedInformation.'Brocade Product Name') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.'MTM') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.'Serial Num') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                
                    # DB save 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Delete | Keep only the 16 most recent entries after TimeStamp
                    $SST_SQliteInsertCMD.CommandText = "DELETE FROM IBMSANHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSANHWTable ORDER BY TimeStamp DESC LIMIT 16 );"
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "SANPortInfo" {
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSANPortInfoTable (Port, State, Speed, PortConnect, SwitchWWN, TimeStamp) VALUES (@Port, @State, @Speed, @PortConnect, @SwitchWWN, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Port", $SST_CollectedInformation.Port) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Speed", $SST_CollectedInformation.Speed) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PortConnect", $SST_CollectedInformation.PortConnect) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SwitchWWN", $SST_CollectedInformation.SwitchWWN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                
                    # DB save 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Then automatically clean up for this exact switch
                    $SST_SQliteInsertCMD.CommandText ="DELETE FROM IBMSANPortInfoTable WHERE ID NOT IN (SELECT ID FROM (SELECT ID FROM IBMSANPortInfoTable AS t WHERE (SELECT COUNT(*) FROM IBMSANPortInfoTable AS x WHERE x.SwitchWWN = t.SwitchWWN AND x.Port = t.Port AND datetime(x.TimeStamp) >= datetime(t.TimeStamp) ) <= 1 ));" 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "PowerHMC" {
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO PowerHMC (HMCName, HMCHWModell, HMCHWSN, HMCHWBios, HMCSWVersion, HMCSWBuildLevel, HMCSWBaseVersion, HMCSWFixes, TimeStamp) VALUES (@HMCName, @HMCHWModell, @HMCHWSN, @HMCHWBios, @HMCSWVersion, @HMCSWBuildLevel, @HMCSWBaseVersion, @HMCSWFixes, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCName", $SST_CollectedInformation.HMCName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCHWModell", $SST_CollectedInformation.HMCHWModell) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCHWSN", $SST_CollectedInformation.HMCHWSN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCHWBios", $SST_CollectedInformation.HMCHWBios) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCSWVersion", $SST_CollectedInformation.HMCSWVersion) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCSWBuildLevel", $SST_CollectedInformation.HMCSWBuildLevel) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCSWBaseVersion", $SST_CollectedInformation.HMCSWBaseVersion) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HMCSWFixes", $SST_CollectedInformation.HMCSWFixes) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                
                    # DB save 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Delete | Keep only the 64 most recent entries after TimeStamp
                    $SST_SQliteInsertCMD.CommandText = "DELETE FROM PowerHMC WHERE ID NOT IN ( SELECT ID FROM PowerHMC ORDER BY TimeStamp DESC LIMIT 64 );"
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "PowerSysSummary" {
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO PowerSysSummary (PowerSysManagedSystem, PowerSysSystemStatus, PowerSysSystemMTM, PowerSysSystemSN, PowerSysMGRIPAddr, PowerSysPrimSPIPAddr, PowerSysECNumber, PowerSysIPLLevel, PowerSysIPLActivatedLevel, PowerSysCoDEvent, TimeStamp) VALUES (@PowerSysManagedSystem, @PowerSysSystemStatus, @PowerSysSystemMTM, @PowerSysSystemSN, @PowerSysMGRIPAddr, @PowerSysPrimSPIPAddr, @PowerSysECNumber, @PowerSysIPLLevel, @PowerSysIPLActivatedLevel, @PowerSysCoDEvent, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysManagedSystem", $SST_CollectedInformation.ManagedSystem) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysSystemStatus", $SST_CollectedInformation.SystemStatus) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysSystemMTM", $SST_CollectedInformation.SystemMTM) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysSystemSN", $SST_CollectedInformation.SystemSN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysMGRIPAddr", $SST_CollectedInformation.MGRIPAddr) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysPrimSPIPAddr", $SST_CollectedInformation.PrimSPIPAddr) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysECNumber", $SST_CollectedInformation.ECNumber) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysIPLLevel", $SST_CollectedInformation.IPLLevel) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysIPLActivatedLevel", $SST_CollectedInformation.IPLActivatedLevel) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PowerSysCoDEvent", $SST_CollectedInformation.CoDEvent) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                    # DB save 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Delete | Keep only the 128 most recent entries after TimeStamp
                    $SST_SQliteInsertCMD.CommandText = "DELETE FROM PowerSysSummary WHERE ID NOT IN ( SELECT ID FROM PowerSysSummary ORDER BY TimeStamp DESC LIMIT 128 );"
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "LPARSummary" {
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO LPARSummary (LPARName, LPARID, LPARStatus, LPAREnvironment, LPAROSVersion, LPARRMCIP, LPARManagedSystemName, LPARManagedSystemSN, TimeStamp) VALUES (@LPARName, @LPARID, @LPARStatus, @LPAREnvironment, @LPAROSVersion, @LPARRMCIP, @LPARManagedSystemName, @LPARManagedSystemSN, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPARName", $SST_CollectedInformation.LPARName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPARID", $SST_CollectedInformation.LPARID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPARStatus", $SST_CollectedInformation.LPARStatus) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPAREnvironment", $SST_CollectedInformation.LPAREnvironment) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPAROSVersion", $SST_CollectedInformation.LPAROSVersion) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPARRMCIP", $SST_CollectedInformation.RMCIP) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPARManagedSystemName", $SST_CollectedInformation.ManagedSystemName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LPARManagedSystemSN", $SST_CollectedInformation.ManagedSystemSN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                
                    # DB save 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Delete | Keep only the 1024 most recent entries after TimeStamp
                    $SST_SQliteInsertCMD.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong during saving the $SST_InfoType data in the local db.") -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {
        #Verbindung schließen
        $SST_CollectedInformations =$null
        $SST_SQLiteCon.Close()
        $SST_SQLiteCon.Dispose()
    }
}