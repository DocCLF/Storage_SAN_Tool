function SST_LiteDBControl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("Drive","StorageBase","StorageHostInfo","SANBase")]
        $SST_InfoType,
        $SST_NewDBObject =$null,
        [array]$SST_CollectedInformations,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -UFormat "%Y-%m-%d %R"
        $PSRootPath = Split-Path -Path $PSScriptRoot -Parent

        try {
            # Pfad zur Datenbank
            $SST_ConnectionString = "Data Source=$PSRootPath\Resources\DBFolder\SSTLocalDB.db;Version=3;"
            # Verbindung öffnen
            $SST_SQLiteCon = New-Object System.Data.SQLite.SQLiteConnection $SST_ConnectionString
            $SST_SQLiteCon.Open()
            # Tabelle anlegen (nur beim ersten Mal nötig)
            $SST_SQliteCreateTBCMD = $SST_SQLiteCon.CreateCommand()
            switch ($SST_InfoType) {
                "Drive" { $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTODriveTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, DriveID INTEGER, Slot INTEGER NOT NULL, ProductID TEXT, DriveStatus TEXT NOT NULL, FWlev TEXT, LatestDriveFW TEXT, DriveCap TEXT, PhyDriveCap TEXT, PhyUsedDriveCap TEXT, EffeUsedDriveCap TEXT, DeviceSN TEXT, DeviceWWNN TEXT, TimeStamp TEXT );"}
                "StorageBase" { $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, DID INTEGER NOT NULL, Name TEXT NOT NULL, ClusterName TEXT, WWNN TEXT NOT NULL, Status TEXT NOT NULL, IOgroupid INTEGER, IOgroupName TEXT, SerialNumber TEXT, CodeLevel TEXT, ConfigNode TEXT, SideID INTEGER, SideName TEXT, ProdMTM TEXT, RecommendedPTF TEXT, TimeStamp TEXT );"}
                "StorageHostInfo" { $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOHostTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, HID INTEGER NOT NULL, Name TEXT NOT NULL, Status TEXT NOT NULL, HostClusterName TEXT, SideName TEXT, TimeStamp TEXT );" }
                "SANBase" { $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Status TEXT NOT NULL, BrocadeProdName TEXT, SerialNumber TEXT, CodeLevel TEXT, TimeStamp TEXT );" }
                Default {SST_ToolMessageCollector -TD_ToolMSGCollector "$($_.exception.message)" -TD_ToolMSGType Error -TD_Shown yes}
            }
            $SST_SQliteCreateTBCMD.CommandText = $SST_SQLiteTabelQuery

            $SST_SQliteCreateTBCMD.ExecuteNonQuery()
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
            "Drive" { 
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTODriveTable (DriveID, Slot, ProductID, DriveStatus, FWlev, LatestDriveFW, DriveCap, PhyDriveCap, PhyUsedDriveCap, EffeUsedDriveCap, DeviceSN, DeviceWWNN, TimeStamp) VALUES (@DriveID, @Slot, @ProductID, @DriveStatus, @FWlev, @LatestDriveFW, @DriveCap, @PhyDriveCap, @PhyUsedDriveCap, @EffeUsedDriveCap, @DeviceSN, @DeviceWWNN, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DriveID", $SST_CollectedInformation.DriveID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Slot", $SST_CollectedInformation.Slot) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@ProductID", $SST_CollectedInformation.ProductID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@DriveStatus", $SST_CollectedInformation.DriveStatus) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@FWlev", $SST_CollectedInformation.FWlev) | Out-Null
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
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){ 
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTOHWTable (DID, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, RecommendedPTF, TimeStamp) VALUES (@DID, @Name, @ClusterName, @WWNN, @Status, @IOgroupid, @IOgroupName, @SerialNumber, @CodeLevel, @ConfigNode, @SideID, @SideName, @ProdMTM, @RecommendedPTF, @TimeStamp);"
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
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
 
                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "StorageHostInfo" { 
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSTOHostTable (HID, Name, Status, HostClusterName, SideName, TimeStamp) VALUES (@HID, @Name, @Status, @HostClusterName, @SideName, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HID", $SST_CollectedInformation.HostID) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Name", $SST_CollectedInformation.HostName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@HostClusterName", $SST_CollectedInformation.HostClusterName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SideName", $SST_CollectedInformation.SiteName) | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
 
                    # In DB speichern 
                    $SST_SQliteInsertCMD.ExecuteNonQuery()
                }
            }
            "SANBase" {
                foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                    $SST_SQliteInsertCMD.CommandText ="INSERT INTO IBMSANHWTable (Name, Status, CodeLevel, BrocadeProdName, SerialNumber, TimeStamp) VALUES (@Name, @Status, @CodeLevel, @BrocadeProdName, @SerialNumber, @TimeStamp);"
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Name", $SST_CollectedInformation.'Swicht Name') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@Status", $SST_CollectedInformation.'Switch State') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.'Fabric OS') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@BrocadeProdName", $SST_CollectedInformation.'Brocade Product Name') | Out-Null
                    $SST_SQliteInsertCMD.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.'Serial Num') | Out-Null
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