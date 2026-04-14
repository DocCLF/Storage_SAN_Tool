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
        $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
        $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
        $SQLiteCommandCreate = $null
    }
    
    process {
        try {
            $SQLiteDBConnection.Open()
            $SQLiteCommandCreate = $SQLiteDBConnection.CreateCommand()
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

