function SST_CustomerLibraryDBCreateTable {
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
            <# LibraryBaseInfo #>
            try{     
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS LibraryBaseInfo (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Name TEXT, Vendor TEXT, ProductID TEXT, BaseFWRevision TEXT, SerialNumber TEXT, MTM TEXT,`
                                        BaseFWBuildDate TEXT, ExpansionFWRevision TEXT, WWNN TEXT, RoboticHWRevision TEXT, RoboticFWRevision TEXT, RoboticSerialNumber TEXT, NoOfModules TEXT, LibraryType TEXT, SerialNumberMTM TEXT NOT NULL, TimeStamp TEXT );"
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
                                        Status TEXT, Fixed TEXT, ErrorCode TEXT, Description TEXT, SerialNumber TEXT, WWNN TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# FCPortStats #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSTOFCPortStatsTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, CardType TEXT, CardID TEXT, PortID TEXT, WWPN TEXT, LinkFailure TEXT, LoseSync TEXT, LoseSig TEXT,`
                                        PSErrCount TEXT, InvTransErr TEXT, CRCErr TEXT, ZeroBtB TEXT, SFPTemp TEXT, TXPwr TEXT, RXPwr TEXT, SerialNumber TEXT, WWNN TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# SANBase #>
            try{ 
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANHWTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Name TEXT NOT NULL, Status TEXT NOT NULL, BrocadeProdName TEXT, MTM TEXT, CodeLevel TEXT, SerialNumber TEXT, SwitchWWNN TEXT, TimeStamp TEXT );" 
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
            }catch{
                Write-Host "SQL Fehler: $($_.Exception.Message)"
                Write-Host $_.Exception.ToString()
            }
            <# SANPortInfo #>
            try{
                $SST_SQLiteTabelQuery ="CREATE TABLE IF NOT EXISTS IBMSANPortInfoTable (ID INTEGER PRIMARY KEY AUTOINCREMENT, CustomerNbr TEXT NOT NULL, Port TEXT, State TEXT, Speed TEXT, PortConnect TEXT, SerialNumber TEXT, SwitchWWNN TEXT, TimeStamp TEXT );"
                $SQLiteCommandCreate.CommandText = $SST_SQLiteTabelQuery
                $SQLiteCommandCreate.ExecuteNonQuery()
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