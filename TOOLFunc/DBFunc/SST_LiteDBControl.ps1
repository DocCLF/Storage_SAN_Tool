function SST_LiteDBControl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("StorageDrive","StorageBase","StorageHostInfo","StorageEventLog","SANBase","FCPortStats","PowerHMC","PowerSysSummary","LPARSummary")]
        $SST_InfoType,
        $SST_NewDBObject =$null,
        [array]$SST_CollectedInformations,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -UFormat "%Y-%m-%d %R"
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent
        $PSRootPath = Split-Path -Path $PSRootPath -Parent
        
        try {
            # Pfad zur Datenbank
            $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"

            # Verbindung öffnen
            $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
            $SST_SQLiteCon.Open()
            # Tabelle anlegen (nur beim ersten Mal nötig)
            $SST_SQliteCreateTBCMD = $SST_SQLiteCon.CreateCommand()
            switch ($SST_InfoType) {
                "StorageBase" { 
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, DID INTEGER NOT NULL, Name TEXT NOT NULL, ClusterName TEXT, WWNN TEXT NOT NULL, Status TEXT NOT NULL, IOgroupid INTEGER, IOgroupName TEXT, SerialNumber TEXT, CodeLevel TEXT, ConfigNode TEXT, SideID INTEGER, SideName TEXT, ProdMTM TEXT, RecommendedPTF TEXT, MDiskTC TEXT, MDiskFC TEXT, MDiskUC TEXT, PhysicalTC TEXT, PhysicalFC TEXT, TimeStamp TEXT );"
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "StorageHostInfo" { 
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOHostTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, HID INTEGER, Name TEXT NOT NULL, Status TEXT NOT NULL, HostClusterName TEXT, SideName TEXT, STOName TEXT, WWNN TEXT, SerialNumber TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "StorageDrive" { 
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTODriveTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, DriveID INTEGER NOT NULL, Slot INTEGER, ProductID TEXT NOT NULL, DriveStatus TEXT NOT NULL, CurrentDriveFW TEXT, LatestDriveFW TEXT, DriveCap TEXT, PhyDriveCap TEXT, PhyUsedDriveCap TEXT, EffeUsedDriveCap TEXT, DeviceSN TEXT, DeviceWWNN TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "StorageEventLog" {
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOEventsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, SeqID INTEGER NOT NULL, LastTime TEXT, ObjectType TEXT, ObjectID INTEGER, ObjectName TEXT, CopyID INTEGER, Status TEXT, Fixed TEXT, ErrorCode TEXT, Description TEXT, WWNN TEXT, SerialNumber TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "FCPortStats" {
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOFCPortStatsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CardType TEXT, CardID TEXT, PortID TEXT, WWPN TEXT, LinkFailure TEXT, LoseSync TEXT, LoseSig TEXT, PSErrCount TEXT, InvTransErr TEXT, CRCErr TEXT, ZeroBtB TEXT, SFPTemp TEXT, TXPwr TEXT, RXPwr TEXT, WWNN TEXT, SerialNumber TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "SANBase" { 
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Status TEXT NOT NULL, BrocadeProdName TEXT, MTM TEXT, SerialNumber TEXT, CodeLevel TEXT, CodeLevelLV TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "PowerHMC" { 
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS PowerHMC (ID INTEGER PRIMARY KEY AUTOINCREMENT, HMCName TEXT NOT NULL, HMCHWModell TEXT NOT NULL, HMCHWSN TEXT, HMCHWBios TEXT, HMCSWVersion TEXT, HMCSWBuildLevel TEXT, HMCSWBaseVersion TEXT, HMCSWFixes TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "PowerSysSummary" { 
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS PowerSysSummary (ID INTEGER PRIMARY KEY AUTOINCREMENT, PowerSysManagedSystem TEXT NOT NULL, PowerSysSystemStatus TEXT NOT NULL, PowerSysSystemMTM TEXT, PowerSysSystemSN TEXT, PowerSysMGRIPAddr TEXT, PowerSysPrimSPIPAddr TEXT, PowerSysECNumber TEXT NOT NULL, PowerSysIPLLevel TEXT, PowerSysIPLActivatedLevel TEXT, PowerSysCoDEvent TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                "LPARSummary" { 
                    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LPARSummary (ID INTEGER PRIMARY KEY AUTOINCREMENT, LPARName TEXT NOT NULL, LPARID TEXT NOT NULL, LPARStatus TEXT, LPAREnvironment TEXT, LPAROSVersion TEXT, LPARRMCIP TEXT, LPARManagedSystemName TEXT, LPARManagedSystemSN TEXT, TimeStamp TEXT );" 
                    $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery
                    $SST_SQliteCreateTBCMD.ExecuteNonQuery()
                }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at LocalDB in combination with $SST_InfoType" -TD_ToolMSGType Message -TD_Shown no}
            }

            SST_ToolMessageCollector -TD_ToolMSGCollector "LocalDB is ready and loaded" -TD_ToolMSGType Message -TD_Shown no
        }
        catch {
            Write-Host $_.exception.message
            SST_ToolMessageCollector -TD_ToolMSGCollector "$($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes
        }
    }
    
    process {
        $SST_SQliteInsertCMD = $SST_SQLiteCon.CreateCommand()
        # Objekt zum Einfügen
        switch ($SST_InfoType) {
            "StorageDrive" { 
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTODriveTable (DriveID, Slot, ProductID, DriveStatus, CurrentDriveFW, LatestDriveFW, DriveCap, PhyDriveCap, PhyUsedDriveCap, EffeUsedDriveCap, DeviceSN, DeviceWWNN, TimeStamp) VALUES (@DriveID, @Slot, @ProductID, @DriveStatus, @CurrentDriveFW, @LatestDriveFW, @DriveCap, @PhyDriveCap, @PhyUsedDriveCap, @EffeUsedDriveCap, @DeviceSN, @DeviceWWNN, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DriveID", $SST_CollectedInformation.DriveID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Slot", $SST_CollectedInformation.Slot) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ProductID", $SST_CollectedInformation.ProductID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DriveStatus", $SST_CollectedInformation.DriveStatus) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CurrentDriveFW", $SST_CollectedInformation.FWlev) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LatestDriveFW", $SST_CollectedInformation.LatestDriveFW) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DriveCap", $SST_CollectedInformation.DriveCap) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PhyDriveCap", $SST_CollectedInformation.PhyDriveCap) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PhyUsedDriveCap", $SST_CollectedInformation.PhyUsedDriveCap) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@EffeUsedDriveCap", $SST_CollectedInformation.EffeUsedDriveCap) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DeviceSN", $SST_CollectedInformation.DeviceSN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DeviceWWNN", $SST_CollectedInformation.DeviceWWNN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
             }
            "StorageBase" { 
                foreach ($SST_CollectedInformation in $SST_CollectedInformations[0]){ 
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTOHWTable (DID, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, RecommendedPTF, MDiskTC, MDiskFC, MDiskUC, PhysicalTC, PhysicalFC, TimeStamp) VALUES (@DID, @Name, @ClusterName, @WWNN, @Status, @IOgroupid, @IOgroupName, @SerialNumber, @CodeLevel, @ConfigNode, @SideID, @SideName, @ProdMTM, @RecommendedPTF, @MDiskTC, @MDiskFC, @MDiskUC, @PhysicalTC, @PhysicalFC, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DID", $SST_CollectedInformation.ID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Name", $SST_CollectedInformation.Name) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ClusterName", $SST_CollectedInformation.ClusterName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@IOgroupid", $SST_CollectedInformation.IO_group_id) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@IOgroupName", $SST_CollectedInformation.IO_group_Name) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.Serial_Number) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.Code_Level) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ConfigNode", $SST_CollectedInformation.ConfigNode) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SideID", $SST_CollectedInformation.SideID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SideName", $SST_CollectedInformation.SideName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ProdMTM", $SST_CollectedInformation.Prod_MTM) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@RecommendedPTF", $SST_CollectedInformation.RecommendedPTF) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@MDiskTC", $SST_CollectedInformation.'MDiskTotalCapacity') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@MDiskFC", $SST_CollectedInformation.'MDiskFreeCapacity') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@MDiskUC", $SST_CollectedInformation.'MDiskUsedCapacity') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PhysicalTC", $SST_CollectedInformation.'PhysicalTotalCapacity') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@PhysicalFC", $SST_CollectedInformation.'PhysicalFreeCapacity') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
 
                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "StorageHostInfo" { 
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTOHostTable (HID, Name, Status, HostClusterName, SideName, STOName, WWNN, SerialNumber, TimeStamp) VALUES (@HID, @Name, @Status, @HostClusterName, @SideName, @STOName, @WWNN, @SerialNumber, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HID", $SST_CollectedInformation.HostID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Name", $SST_CollectedInformation.HostName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HostClusterName", $SST_CollectedInformation.HostClusterName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SideName", $SST_CollectedInformation.SiteName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@STOName", $SST_CollectedInformation.STOName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
 
                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "StorageEventLog" {
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTOEventsTable (SeqID, LastTime, ObjectType, ObjectID, ObjectName, CopyID, Status, Fixed, ErrorCode, Description, WWNN, SerialNumber, TimeStamp) VALUES (@SeqID, @LastTime, @ObjectType, @ObjectID, @ObjectName, @CopyID, @Status, @Fixed, @ErrorCode, @Description, @WWNN, @SerialNumber, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SeqID", $SST_CollectedInformation.SeqID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@LastTime", $SST_CollectedInformation.LastTime) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ObjectType", $SST_CollectedInformation.ObjectType) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ObjectID", $SST_CollectedInformation.ObjectID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ObjectName", $SST_CollectedInformation.ObjectName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CopyID", $SST_CollectedInformation.CopyID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Fixed", $SST_CollectedInformation.Fixed) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ErrorCode", $SST_CollectedInformation.ErrorCode) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Description", $SST_CollectedInformation.Description) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
 
                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Delete | Keep only the 500 most recent entries after TimeStamp
                    $SST_SQliteInsertCMD.CommandText = "DELETE FROM IBMSTOEventsTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOEventsTable ORDER BY TimeStamp DESC LIMIT 500 );"
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
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

                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()

                    # Delete | Keep only the 500 most recent entries after TimeStamp
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
                
                    # In DB speichern 
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
                
                    # In DB speichern 
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
                    # In DB speichern 
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
                
                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong during saving the $SST_InfoType data in the local db." -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {
        #Verbindung schließen
        $SST_CollectedInformations =$null
        $SST_SQLiteCon.Close()
        $SST_SQLiteCon.Dispose()
    }
}