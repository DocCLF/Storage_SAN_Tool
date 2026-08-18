function SST_CustomerDeviceDBCreateTable {
    [CmdletBinding()]
    param (
        $SST_NewDBObject =$null,
        [string]$SST_Customer =$null,
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
        $SQLiteCommandCreate = $null
    }
    
    process {
        try {
            $SQLiteDBConnection.Open()
            $SQLiteCommandCreate = $SQLiteDBConnection.CreateCommand()

            <# für alte tabellen #>
            
            #    $SST_SQLiteTabelQuery = "ALTER TABLE IBMSTOVolumeAnalysisTable ADD COLUMN VdiskUID TEXT;"
            #
            #    $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
            #    $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
#
            #    $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOVolumeAnalysis_UID_TimeStamp ON IBMSTOVolumeAnalysisTable (CustomerNbr,SerialNumber,VdiskUID,TimeStamp);"
            #    $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

            <# StorageBase #>
            try{     
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Name TEXT NOT NULL, ClusterName TEXT, Status TEXT NOT NULL, IOgroupid INTEGER, IOgroupName TEXT,`
                                        CodeLevel TEXT, ConfigNode TEXT, SideID INTEGER, SideName TEXT, ProdMTM TEXT, RecommendedPTF TEXT, MDiskTotalCapacity TEXT, MDiskFreeCapacity TEXT, MDiskUsedCapacity TEXT, PhysicalTotalCapacity TEXT,`
                                        PhysicalFreeCapacity TEXT, HostUnmap TEXT, BackendUnmap TEXT, Topology TEXT, Layer TEXT, QuorumMode TEXT, SerialNumber TEXT, WWNN TEXT NOT NULL, TimeStamp TEXT );"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# StorageBase InventoryTable  #>
            try{     
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOSystemInventoryTable (ID INTEGER PRIMARY KEY AUTOINCREMENT,CustomerNbr TEXT NOT NULL,SystemIdentity TEXT NOT NULL,SerialNumber TEXT NOT NULL,WWNN TEXT NOT NULL,ClusterName TEXT,`
                                        ProdMTM TEXT,IsActive INTEGER NOT NULL DEFAULT 1, FirstSeen TEXT NOT NULL,LastSeen TEXT NOT NULL,TimeStamp TEXT NOT NULL, UNIQUE (CustomerNbr, SystemIdentity));"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOSystemInventory_SN ON IBMSTOSystemInventoryTable (CustomerNbr,SerialNumber);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOSystemInventory_WWNN ON IBMSTOSystemInventoryTable (CustomerNbr,WWNN);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# StorageHostInfo #> 
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOHostTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, HID INTEGER, HostName TEXT NOT NULL, Status TEXT NOT NULL, HostClusterName TEXT, SideName TEXT,`
                                        STOName TEXT, SerialNumber TEXT, WWNN TEXT NOT NULL, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# StorageDrive #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTODriveTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, DriveID INTEGER, SlotID INTEGER, ProductID TEXT, DriveStatus TEXT,`
                                        CurrentDriveFW TEXT, LatestDriveFW TEXT, DriveCap TEXT, PhyDriveCap TEXT, PhyUsedDriveCap TEXT, EffeUsedDriveCap TEXT, SerialNumber TEXT, WWNN TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# StorageEventLog #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOEventsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, SeqID INTEGER NOT NULL, LastTime TEXT, ObjectType TEXT, ObjectID INTEGER, ObjectName TEXT, CopyID INTEGER,`
                                        Status TEXT, Fixed TEXT, ErrorCode TEXT, Description TEXT, SerialNumber TEXT, WWNN TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            #<# FCPortStats for "old" Customers #>
            #try {
            #
            #    Update-IBMSTOFCPortStatsTableSchema -SQLiteDBConnection $SQLiteDBConnection
            #
            #}
            #catch {
            #    Write-Host "SQL Fehler: $($_.Exception.Message)"
            #    Write-Host $_.Exception.ToString()
            #}
            #<# FCPortStats for new Customers #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOFCPortStatsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, RowID TEXT NOT NULL,NodeID INTEGER, NodeName TEXT, CardType TEXT, CardID INTEGER, PortID INTEGER, WWPN TEXT NOT NULL,`
                                        LinkFailure INTEGER, LoseSync INTEGER, LoseSig INTEGER, PSErrCount INTEGER, InvTransErr INTEGER, CRCErr INTEGER, ZeroBtB INTEGER, SFPTemp REAL, TXPwr REAL, TXPwrLow REAL, RXPwr REAL, RXPwrLow REAL, SerialNumber TEXT NOT NULL,`
                                        WWNN TEXT NOT NULL, TimeStamp TEXT NOT NULL);" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
                # Beschleunigt die spätere Abfrage eines Ports über einen Zeitraum.
                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOFCPortStats_RowID_TimeStamp ON IBMSTOFCPortStatsTable (CustomerNbr,RowID,TimeStamp);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# PoolCapacity #>
            try {
                $SST_SQLiteTabelQuery = "CREATE TABLE IF NOT EXISTS IBMSTOPoolCapacityTable (ID INTEGER PRIMARY KEY AUTOINCREMENT,CustomerNbr TEXT NOT NULL,RowID TEXT NOT NULL,PoolID TEXT NOT NULL,PoolName TEXT,Capacity INTEGER,FreeCapacity INTEGER,VirtualCapacity INTEGER,`
                                            UsedCapacity INTEGER,RealCapacity INTEGER,Overallocation REAL,SerialNumber TEXT NOT NULL,WWNN TEXT NOT NULL,TimeStamp TEXT NOT NULL);"
            
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            
                # Speeds up history queries for one pool over a time range.
                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOPoolCapacity_RowID_TimeStamp ON IBMSTOPoolCapacityTable (CustomerNbr,RowID,TimeStamp);"
            
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            }
            catch {
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# VolumeInventory #>
            try {
                $SST_SQLiteTabelQuery = "CREATE TABLE IF NOT EXISTS IBMSTOVolumeInventoryTable (ID INTEGER PRIMARY KEY AUTOINCREMENT,CustomerNbr TEXT NOT NULL,SerialNumber TEXT NOT NULL,WWNN TEXT,VolumeID INTEGER,VdiskUID TEXT NOT NULL,VolumeName TEXT,`
                                            RowID TEXT,IsActive INTEGER NOT NULL DEFAULT 1, FirstSeen TEXT NOT NULL,LastSeen TEXT NOT NULL,TimeStamp TEXT NOT NULL,`
                                        UNIQUE (CustomerNbr,SerialNumber,VdiskUID));"
            
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

                # Fast lookup of the current active volume inventory per system.
                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOVolumeInventory_Active ON IBMSTOVolumeInventoryTable (CustomerNbr,SerialNumber,IsActive);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

                # Fast lookup by current VolumeID within one Storage system.
                #
                # VolumeID is not the permanent identity, but it is useful when
                # correlating lsvdisk with lsvdiskanalysis from the same scan.
                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOVolumeInventory_VolumeID ON IBMSTOVolumeInventoryTable (CustomerNbr,SerialNumber,VolumeID);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            
            }
            catch {
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# VolumeAnalysisTable #>
            try {
                $SST_SQLiteTabelQuery = "CREATE TABLE IF NOT EXISTS IBMSTOVolumeAnalysisTable (ID INTEGER PRIMARY KEY AUTOINCREMENT,CustomerNbr TEXT NOT NULL,RowID TEXT NOT NULL,VolumeID TEXT NOT NULL,VolumeName TEXT,State TEXT,AnalysisTime TEXT,Capacity INTEGER,`
                                            ThinSize INTEGER,ThinSavings INTEGER,ThinSavingsRatio REAL,CompressedSize INTEGER,CompressionSavings INTEGER,CompressionSavingsRatio REAL,TotalSavings INTEGER,TotalSavingsRatio REAL,MarginOfError REAL,WWNN TEXT NOT NULL,`
                                            SerialNumber TEXT NOT NULL,TimeStamp TEXT NOT NULL);"
            
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOVolumeAnalysis_UID_TimeStamp ON IBMSTOVolumeAnalysisTable (CustomerNbr,SerialNumber,VdiskUID,TimeStamp);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

                # Speeds up history queries for one pool over a time range.
                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSTOVolumeAnalysis_RowID_TimeStamp ON IBMSTOVolumeAnalysisTable (CustomerNbr,RowID,TimeStamp);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            }
            catch {
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# SANBase #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Name TEXT NOT NULL, Status TEXT NOT NULL, BrocadeProdName TEXT, MTM TEXT, CodeLevel TEXT, SerialNumber TEXT, SwitchWWNN TEXT, VFID TEXT, VFenabled TEXT, VFsupported TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# SAN Switch InventoryTable #>
            try {
            
                $SST_SQLiteTabelQuery = "CREATE TABLE IF NOT EXISTS SANSwitchInventoryTable (ID INTEGER PRIMARY KEY AUTOINCREMENT,CustomerNbr TEXT NOT NULL,SwitchWWNN TEXT NOT NULL,SwitchName TEXT,SerialNumber TEXT,IsActive INTEGER NOT NULL DEFAULT 1,`
                                            FirstSeen TEXT NOT NULL,LastSeen TEXT NOT NULL,TimeStamp TEXT NOT NULL,UNIQUE (CustomerNbr,SwitchWWNN));"
            
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            
                # -------------------------------------------------------------
                # Fast lookup by WWNN.
                # -------------------------------------------------------------
                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_SANSwitchInventory_WWNN ON SANSwitchInventoryTable (CustomerNbr,SwitchWWNN);"
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            
                # -------------------------------------------------------------
                # Fast lookup of currently active SAN switches.
                # -------------------------------------------------------------
                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_SANSwitchInventory_Active ON SANSwitchInventoryTable (CustomerNbr,IsActive);"
                $SQLiteCommandCreate.ExecuteNonQuery() |Out-Null

            }catch {
            
                Write-Host ("SQL Fehler: $($_.Exception.Message)")
                Write-Host $_.Exception.ToString()
            }
            <# SANPortInfo #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANPortInfoTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Port TEXT, State TEXT, Speed TEXT, PortConnect TEXT, VFID TEXT, SerialNumber TEXT, SwitchWWNN TEXT, TimeStamp TEXT );"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# SANPortErrorStats #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANPortErrorStatsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, RowID TEXT NOT NULL, SwitchName TEXT, SerialNumber TEXT NOT NULL, SwitchWWNN TEXT, VFID TEXT,`
                                         Port TEXT NOT NULL, EncIn INTEGER, CrcErr INTEGER, TooShort INTEGER, TooLong INTEGER, BadEOF INTEGER, EncOut INTEGER, DiscC3 INTEGER, LinkFail INTEGER,LossSync INTEGER, LossSig INTEGER, StateTransitions INTEGER,`
                                         BBZero INTEGER, FECuncorrected INTEGER, TimeStamp TEXT NOT NULL);"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()

                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSANPortErrorStats_RowID_TimeStamp ON IBMSANPortErrorStatsTable (CustomerNbr,RowID,TimeStamp);"            
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# Get-BrocadeSFPShow #>
            try{
                $SST_SQLiteTabelQuery = "CREATE TABLE IF NOT EXISTS SANSFPStatsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT,CustomerNbr TEXT NOT NULL,RowID TEXT NOT NULL,SwitchName TEXT,SerialNumber TEXT NOT NULL,SwitchWWNN TEXT,VFID TEXT,Port TEXT NOT NULL,`
                                        SFPUsed INTEGER,SFPTyp TEXT,Connector TEXT,Media TEXT,Vendor TEXT,PartNumber TEXT,SFPSerialNumber TEXT,SpeedRange TEXT,Temperature REAL,RxPower REAL,TxPower REAL,Voltage REAL,Wavelength REAL,PowerOnTime INTEGER,TimeStamp TEXT NOT NULL);"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()

                $SQLiteCommandCreate.CommandText = "CREATE INDEX IF NOT EXISTS IX_IBMSANSFPStats_RowID_TimeStamp ON SANSFPStatsTable (CustomerNbr,RowID,TimeStamp);"            
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null

            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# PowerHMC #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS PowerHMC (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, HMCName TEXT, HMCMTM TEXT, SerialNumber TEXT, HMCUUID TEXT, BIOS TEXT, DisplayVersion TEXT,`
                                        BuildLevel TEXT, BaseVersion TEXT, IFix TEXT, ManagedSystemCount TEXT, ManagedSystemUUIDs TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# PowerSysSummary #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS PowerSysSummary (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, SystemName TEXT, MachineTypeModel TEXT, SerialNumber TEXT, State TEXT, ECNumber TEXT, ActivatedLevel TEXT, UUID TEXT, URL TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# LPARSummary #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LPARSummary (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, ManagedSystemName TEXT, ManagedSystemUUID TEXT, ManagedSystemMTMS TEXT, ManagedSystemSerial TEXT, LparName TEXT,`
                                        LparUUID TEXT , PartitionId TEXT, State TEXT, Environment TEXT, OsVersion TEXT, RmcIp TEXT, RmcState TEXT, DefaultProfile TEXT, CurrentProcessingUnits TEXT, CurrentMemoryMB TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# TapeBase #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMTapeHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, SerialNumber TEXT, MachineTypeModel Text, BaseFW TEXT,`
                                        ExpansionFW TEXT, RoboticHW TEXT, RoboticFW TEXT, RoboticSerialNumber TEXT, NoOfModules TEXT, LibraryType TEXT, WWNodeName TEXT, ProductID TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# LibraryBaseInfo with library Endpoint #>
            try{     
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryBaseInfo (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Name TEXT, Status TEXT, Vendor TEXT, ProductID TEXT, BaseFWRevision TEXT, SerialNumber TEXT, MTM TEXT, TotalCartridges TEXT, AssignedCartridges TEXT, TotalCapacity TEXT, LicensedCapacity TEXT,`
                                        BaseFWBuildDate TEXT, ExpansionFWRevision TEXT, WWNN TEXT, RoboticHWRevision TEXT, RoboticFWRevision TEXT, RoboticSerialNumber TEXT, NoOfModules TEXT, LibraryType TEXT, SecureCommunications TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT );"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery() | Out-Null
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# LibraryEvents #> 
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryEvents (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, LibID TEXT, Severity TEXT, Type TEXT, Location TEXT, Description TEXT,`
                                        ErrorCode INTEGER, EventTime TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT);" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# library/status #>
            # for later use!?!
            #try{ 
            #    $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryStatus (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, BaseInformation TEXT, BaseRobStatus TEXT, BaseMoveCount INTEGER, BasePowerUpCount INTEGER,`
            #                            BasePowerOnTime TEXT, BaseLibHealth TEXT, ModulesPhysicalNumber TEXT, ModulesLogicalNumber TEXT, ModulesHealth TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT );" 
            #    $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
            #    $SQLiteCommandCreate.ExecuteNonQuery()
            #}catch{
            #    Write-Host "SQL Fehler: $($_.Exception.Message)"
            #    Write-Host $_.Exception.ToString()
            #}
            <# library/inventory Slots #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryInventorySlots (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, PhysicalNumber INTEGER, LogicalNumber TEXT, Module INTEGER, LogicalLibrary INTEGER, Mailslot TEXT, Cartridge TEXT, Barcode TEXT,`
                                        CartridgeType TEXT, CartridgeSubType TEXT, CartridgeGeneration TEXT, CartridgeEncrypted TEXT, Access TEXT, Blocked TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT);" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# library/inventory Drives #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryInventoryDrives (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, PhysicalNumber INTEGER, LogicalNumber INTEGER, Module INTEGER, LogicalLibrary INTEGER, Barcode TEXT, Vendor TEXT, Product TEXT, FWRevision TEXT,`
                                        SerialNumber TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT);" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# Drive not the same as Drives #>
            # A combination of endpoints drive and drive/infomation
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryDrive (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Location TEXT, SerialNumber TEXT, MFGSerialNumber TEXT, MediaType TEXT, State TEXT, MTM TEXT, Interface TEXT, LogicalLibrary TEXT, LogicalLibraryID INTEGER, USE TEXT, Firmware TEXT,`
                                        Encryption TEXT, Mounts INTEGER, Barcode TEXT, WWNN TEXT, ElementAddress TEXT, LogicalNumber INTEGER, PhysicalNumber INTEGER, Module TEXT, Generation TEXT, Cartridge TEXT, Vendor TEXT, ErrorState TEXT, Power TEXT, Presence TEXT, ADTMode TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# library/mediainfo #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryMediaInfo (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Barcode TEXT, LocationType TEXT, LogicalNumber INTEGER, PhysicalNumber INTEGER, Cleaning TEXT, LogicalLibrary INTEGER, Generation INTEGER,`
                                        SubType INTEGER, Protection TEXT, Encryption TEXT, NoLoads INTEGER, MBRead INTEGER, MBReadLoad INTEGER, MBWritten INTEGER, MBWrittenLoad INTEGER, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT );"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# logicalLibrary/information #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LogicalLibraryInfo (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, LogicalLibraryNumber INTEGER, Name TEXT, SerialNumber TEXT, NumSlots INTEGER, NumIOSlots INTEGER, NumDrives INTEGER, LunPrimaryDrive TEXT, LunPrimaryDrivePhys TEXT,`
                                        LunPrimaryDriveArr TEXT, LunPrimaryDrivePhysArr TEXT, EncryptionMode TEXT, BarcodeAlign TEXT, BarcodeLength INTEGER, AutoClean TEXT, WWNode TEXT, Micw TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT);" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# reports/mountHistory #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryReports (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Barcode TEXT, LogicalLibrary TEXT, Location TEXT, MountTime TEXT, UnmountTime TEXT, HostIOReads INTEGER, HostIOWrites INTEGER, CompressionRate TEXT, ErrorsCorrectedWrites INTEGER,`
                                        ErrorsUncorrectedWrites INTEGER, ErrorsCorrectedReads INTEGER, ErrorsUncorrectedReads INTEGER, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
        }finally {
            
            if ($SQLiteCommandCreate) { $SQLiteCommandCreate.Dispose() }
            if ($SQLiteDBConnection) { $SQLiteDBConnection.Close(); $SQLiteDBConnection.Dispose() }

            # wenn du danach Dateien löschen willst, extra gut:
            [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
        }
    }
    
    end {
        
    }
}