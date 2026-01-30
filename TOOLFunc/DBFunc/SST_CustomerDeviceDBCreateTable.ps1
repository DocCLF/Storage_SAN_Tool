function SST_CustomerDeviceDBCreateTable {
    [CmdletBinding()]
    param (
        $SST_NewDBObject =$null,
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
        $SQLiteCommandCreate = $null
    }
    
    process {
        try {
            $SQLiteDBConnection.Open()
            $SQLiteCommandCreate = $SQLiteDBConnection.CreateCommand()
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
                                        Status TEXT, Fixed TEXT, ErrorCode TEXT, Description TEXT, SerialNumber TEXT, WWNN TEXT NOT NULL, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# FCPortStats #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOFCPortStatsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CardType TEXT, CardID TEXT, PortID TEXT, WWPN TEXT, LinkFailure TEXT, LoseSync TEXT, LoseSig TEXT, PSErrCount TEXT, InvTransErr TEXT, CRCErr TEXT, ZeroBtB TEXT, SFPTemp TEXT, TXPwr TEXT, RXPwr TEXT, WWNN TEXT, SerialNumber TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{}
            <# SANBase #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, Name TEXT NOT NULL, Status TEXT NOT NULL, BrocadeProdName TEXT, MTM TEXT, SerialNumber TEXT, CodeLevel TEXT, CodeLevelLV TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{}
            <# SANPortInfo #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANPortInfoTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, Port TEXT, State TEXT, Speed TEXT, PortConnect TEXT, SwitchWWN TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{}
            <# PowerHMC #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS PowerHMC (ID INTEGER PRIMARY KEY AUTOINCREMENT, HMCName TEXT, HMCHWModell TEXT, HMCHWSN TEXT, HMCHWBios TEXT, HMCSWVersion TEXT, HMCSWBuildLevel TEXT, HMCSWBaseVersion TEXT, HMCSWFixes TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{}
            <# PowerSysSummary #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS PowerSysSummary (ID INTEGER PRIMARY KEY AUTOINCREMENT, PowerSysManagedSystem TEXT NOT NULL, PowerSysSystemStatus TEXT NOT NULL, PowerSysSystemMTM TEXT, PowerSysSystemSN TEXT, PowerSysMGRIPAddr TEXT, PowerSysPrimSPIPAddr TEXT, PowerSysECNumber TEXT NOT NULL, PowerSysIPLLevel TEXT, PowerSysIPLActivatedLevel TEXT, PowerSysCoDEvent TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{}
            <# LPARSummary #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LPARSummary (ID INTEGER PRIMARY KEY AUTOINCREMENT, LPARName TEXT NOT NULL, LPARID TEXT NOT NULL, LPARStatus TEXT, LPAREnvironment TEXT, LPAROSVersion TEXT, LPARRMCIP TEXT, LPARManagedSystemName TEXT, LPARManagedSystemSN TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{}
            
            #SST_ToolMessageCollector -TD_ToolMSGCollector $("LocalDB is ready and loaded, SST_InfoType $SST_InfoType") -TD_ToolMSGType Message -TD_Shown no

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