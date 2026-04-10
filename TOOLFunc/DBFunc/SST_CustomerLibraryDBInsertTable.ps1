function SST_CustomerDeviceDBInsertTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("LibraryBaseInfo","LibraryEvents","LibraryReports","LogicalLibraryInfo","LibraryInventorySlots","LibraryInventoryDrives","LibraryDrive","LibraryMediaInfo")]
        [string]$SST_InfoType,
        $SST_NeededInformations,
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
        
        $DBPath = Join-Path $PSRootPath "Resources\DBFolder\$Customer.db"
        $SQLiteConnectionString = "Data Source=$DBPath;Version=3;Pooling=False;"

        $SQLiteDBConnection = New-Object System.Data.SQLite.SQLiteConnection $SQLiteConnectionString
        $SQLiteCommand = $null
    }
    
    process {

        # Objekt zum EinfÃ¼gen
        switch ($SST_InfoType) {
            "LibraryBaseInfo" { 

                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){ 
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LibraryBaseInfo (CustomerNbr, Name, Status, Vendor, ProductID, BaseFWRevision, SerialNumber, MTM, TotalCartridges, AssignedCartridges, TotalCapacity, LicensedCapacity,`
                                                    BaseFWBuildDate, ExpansionFWRevision, WWNN, RoboticHWRevision, RoboticFWRevision, RoboticSerialNumber, NoOfModules, LibraryType, SecureCommunications, SerialNumberMTM, TimeStamp)`
                                                    VALUES (@CustomerNbr, @Name, @Status, @Vendor, @ProductID, @BaseFWRevision, @SerialNumber, @MTM, @TotalCartridges, @AssignedCartridges, @TotalCapacity, @LicensedCapacity,`
                                                    @BaseFWBuildDate, @ExpansionFWRevision, @WWNN, @RoboticHWRevision, @RoboticFWRevision, @RoboticSerialNumber, @NoOfModules, @LibraryType, @SecureCommunications, @SerialNumberMTM, @TimeStamp);"
                        <# get SN and MTM #>
                        $CombiSNMTM = $SST_CollectedInformation.SerialNumber
                        $SN = $CombiSNMTM.Substring($CombiSNMTM.Length -7)

                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.name) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.status) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Vendor", $SST_CollectedInformation.Vendor) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ProductID", $SST_CollectedInformation.ProductID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BaseFWRevision", $SST_CollectedInformation.BaseFWRevision) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MTM", $($CombiSNMTM.TrimEnd($SN)).Insert(4,"-")) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TotalCartridges", $SST_CollectedInformation.totalCartridges) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@AssignedCartridges", $SST_CollectedInformation.assignedCartridges) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TotalCapacity", $SST_CollectedInformation.totalCartridges) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LicensedCapacity", $SST_CollectedInformation.licensedCapacity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BaseFWBuildDate", $SST_CollectedInformation.BaseFWBuildDate) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ExpansionFWRevision", $SST_CollectedInformation.ExpansionFWRevision) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNodeName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RoboticHWRevision", $SST_CollectedInformation.RoboticHWRevision) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RoboticFWRevision", $SST_CollectedInformation.RoboticFWRevision) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("RoboticSerialNumber", $SST_CollectedInformation.RoboticSerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@NoOfModules", $SST_CollectedInformation.NoOfModules) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LibraryType", $SST_CollectedInformation.LibraryType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SecureCommunications", $SST_CollectedInformation.secureCommunications) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 256 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LibraryBaseInfo WHERE ID NOT IN ( SELECT ID FROM LibraryBaseInfo ORDER BY TimeStamp DESC LIMIT 256 );"
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
            "LibraryEvents" { 

                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){ 
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LibraryEvents (CustomerNbr, LibID, Severity, Type, Location, Description, ErrorCode, EventTime, SerialNumberMTM, TimeStamp)`
                                                    VALUES (@CustomerNbr, @LibID, @Severity, @Type, @Location, @Description, @ErrorCode, @EventTime, @SerialNumberMTM, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LibID", $SST_CollectedInformation.ID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Severity", $SST_CollectedInformation.severity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Type", $SST_CollectedInformation.type) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Location", $SST_CollectedInformation.location) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Description", $SST_CollectedInformation.description) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ErrorCode", $SST_CollectedInformation.errorCode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@EventTime", $SST_CollectedInformation.time) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_NeededInformations) | Out-Null 
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LibraryEvents WHERE ID NOT IN ( SELECT ID FROM LibraryEvents ORDER BY TimeStamp DESC LIMIT 256 );"
                        $SQLiteCommand.ExecuteNonQuery()
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
            "LibraryReports" { 
                
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LibraryReports (CustomerNbr, Barcode, Location, MountTime, UnmountTime, HostIOReads, HostIOWrites, CompressionRate, ErrorsCorrectedWrites, ErrorsUncorrectedWrites, ErrorsCorrectedReads, ErrorsUncorrectedReads, SerialNumberMTM, TimeStamp)`
                                                    VALUES (@CustomerNbr, @Barcode, @Location, @MountTime, @UnmountTime, @HostIOReads, @HostIOWrites, @CompressionRate, @ErrorsCorrectedWrites, @ErrorsUncorrectedWrites, @ErrorsCorrectedReads, @ErrorsUncorrectedReads, @SerialNumberMTM, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Barcode", $SST_CollectedInformation.HostName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Location", $SST_CollectedInformation.Status) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MountTime", $SST_CollectedInformation.HostClusterName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@UnmountTime", $SST_CollectedInformation.SiteName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HostIOReads", $SST_CollectedInformation.ID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@HostIOWrites", $SST_CollectedInformation.HostName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CompressionRate", $SST_CollectedInformation.Status) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ErrorsCorrectedWrites", $SST_CollectedInformation.HostClusterName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ErrorsUncorrectedWrites", $SST_CollectedInformation.SiteName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ErrorsCorrectedReads", $SST_CollectedInformation.STOName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ErrorsUncorrectedReads", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_NeededInformations) | Out-Null 
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LibraryReports WHERE ID NOT IN ( SELECT ID FROM LibraryReports ORDER BY TimeStamp DESC LIMIT 128 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                } catch {
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
            "LogicalLibraryInfo" {

                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LogicalLibraryInfo (CustomerNbr, LogicalLibraryNumber, Name, SerialNumber, NumSlots, NumIOSlots, NumDrives, LunPrimaryDrive, LunPrimaryDrivePhys,`
                                                    LunPrimaryDriveArr, LunPrimaryDrivePhysArr, EncryptionMode, BarcodeAlign, BarcodeLength, AutoClean, WWNode, Micw, SerialNumberMTM, TimeStamp)`
                                                    VALUES (@CustomerNbr, @LogicalLibraryNumber, @Name, @SerialNumber, @NumSlots, @NumIOSlots, @NumDrives, @LunPrimaryDrive, @LunPrimaryDrivePhys,`
                                                    @LunPrimaryDriveArr, @LunPrimaryDrivePhysArr, @EncryptionMode, @BarcodeAlign, @BarcodeLength, @AutoClean, @WWNode, @Micw, @SerialNumberMTM, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalLibraryNumber", $SST_CollectedInformation.LogicalLibraryNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.Name) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@NumSlots", $SST_CollectedInformation.NumSlots) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@NumIOSlots", $SST_CollectedInformation.NumIOSlots) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@NumDrives", $SST_CollectedInformation.NumDrives) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LunPrimaryDrive", $SST_CollectedInformation.LunPrimaryDrive) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LunPrimaryDrivePhys", $SST_CollectedInformation.LunPrimaryDrivePhys) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LunPrimaryDriveArr", $SST_CollectedInformation.LunPrimaryDriveArr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LunPrimaryDrivePhysArr", $SST_CollectedInformation.LunPrimaryDrivePhysArr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@EncryptionMode", $SST_CollectedInformation.EncryptionMode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BarcodeAlign", $SST_CollectedInformation.BarcodeAlign) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BarcodeLength", $SST_CollectedInformation.BarcodeLength) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@AutoClean", $SST_CollectedInformation.AutoClean) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNode", $SST_CollectedInformation.WWNode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Micw", $SST_CollectedInformation.Micw) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_NeededInformations) | Out-Null 
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null 
                    
                        # DB save
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 500 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LogicalLibraryInfo WHERE ID NOT IN ( SELECT ID FROM LogicalLibraryInfo ORDER BY TimeStamp DESC LIMIT 256 );"
                        $SQLiteCommand.ExecuteNonQuery()
                    }
                } catch {
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
            "LibraryInventorySlots" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LibraryInventorySlots (CustomerNbr, PhysicalNumber, LogicalNumber, Module, LogicalLibrary, Mailslot, Cartridge, Barcode, CartridgeType, CartridgeSubType, CartridgeGeneration, CartridgeEncrypted, Access, Blocked, SerialNumberMTM, TimeStamp)`
                                                            VALUES (@CustomerNbr, @PhysicalNumber, @LogicalNumber, @Module, @LogicalLibrary, @Mailslot, @Cartridge, @Barcode, @CartridgeType, @CartridgeSubType, @CartridgeGeneration, @CartridgeEncrypted, @Access, @Blocked, @SerialNumberMTM, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhysicalNumber", $SST_CollectedInformation.PhysicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalNumber", $SST_CollectedInformation.LogicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Module", $SST_CollectedInformation.Module) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalLibrary", $SST_CollectedInformation.LogicalLibrary) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Mailslot", $SST_CollectedInformation.Mailslot) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Cartridge", $SST_CollectedInformation.Cartridge) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Barcode", $SST_CollectedInformation.Barcode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CartridgeType", $SST_CollectedInformation.CartridgeType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CartridgeSubType", $SST_CollectedInformation.CartridgeSubType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CartridgeGeneration", $SST_CollectedInformation.CartridgeGeneration) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CartridgeEncrypted", $SST_CollectedInformation.CartridgeEncrypted) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Access", $SST_CollectedInformation.Access) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Blocked", $SST_CollectedInformation.Blocked) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_NeededInformations) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                        # DB save
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 1000 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LibraryInventorySlots WHERE ID NOT IN ( SELECT ID FROM LibraryInventorySlots ORDER BY TimeStamp DESC LIMIT 512 );"
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
            "LibraryInventoryDrives" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LibraryInventoryDrives (CustomerNbr, PhysicalNumber, LogicalNumber, Module, LogicalLibrary, Barcode, Vendor, Product, FWRevision, SerialNumber, SerialNumberMTM, TimeStamp)`
                                                    VALUES (@CustomerNbr, @PhysicalNumber, @LogicalNumber, @Module, @LogicalLibrary, @Barcode, @Vendor, @Product, @FWRevision, @SerialNumber, @SerialNumberMTM, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhysicalNumber", $SST_CollectedInformation.PhysicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalNumber", $SST_CollectedInformation.LogicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Module", $SST_CollectedInformation.Module) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalLibrary", $SST_CollectedInformation.LogicalLibrary) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Barcode", $SST_CollectedInformation.Barcode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Vendor", $SST_CollectedInformation.Vendor) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Product", $SST_CollectedInformation.Product) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@FWRevision", $SST_CollectedInformation.FWRevision) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_NeededInformations) | Out-Null 
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 16 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LibraryInventoryDrives WHERE ID NOT IN ( SELECT ID FROM LibraryInventoryDrives ORDER BY TimeStamp DESC LIMIT 512 );"
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
            "LibraryDrive" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LibraryDrive (CustomerNbr, Location, SerialNumber, MFGSerialNumber, MediaType, State, MTM, Interface, LogicalLibrary, LogicalLibraryID, USE, Firmware, Encryption, Mounts, Barcode, WWNN,`
                                                        ElementAddress, LogicalNumber, PhysicalNumber, Module, Generation, Cartridge, Vendor, ErrorState, Power, Presence, ADTMode, SerialNumberMTM, TimeStamp)`
                                                    VALUES (@CustomerNbr, @Location, @SerialNumber, @MFGSerialNumber, @MediaType, @State, @MTM, @Interface, @LogicalLibrary, @LogicalLibraryID, @USE, @Firmware, @Encryption, @Mounts, @Barcode, @WWNN,`
                                                        @ElementAddress, @LogicalNumber, @PhysicalNumber, @Module, @Generation, @Cartridge, @Vendor, @ErrorState, @Power, @Presence, @ADTMode, @SerialNumberMTM, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Location", $SST_CollectedInformation.location) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MFGSerialNumber", $SST_CollectedInformation.MFGSerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MediaType", $SST_CollectedInformation.mediaType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.state) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.mtm) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Interface", $SST_CollectedInformation.Interface) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalLibrary", $SST_CollectedInformation.logicalLibrary) | Out-Null      #string
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalLibraryID", $SST_CollectedInformation.LogicalLibrary) | Out-Null    #id
                        $SQLiteCommand.Parameters.AddWithValue("@USE", $SST_CollectedInformation.use) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Firmware", $SST_CollectedInformation.firmware) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Encryption", $SST_CollectedInformation.encryption) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Mounts", $SST_CollectedInformation.mounts) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Barcode", $SST_CollectedInformation.barcode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.wwnn) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ElementAddress", $SST_CollectedInformation.elementAddress) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalNumber", $SST_CollectedInformation.LogicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhysicalNumber", $SST_CollectedInformation.PhysicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Module", $SST_CollectedInformation.Module) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Generation", $SST_CollectedInformation.Generation) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Cartridge", $SST_CollectedInformation.Cartridge) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Vendor", $SST_CollectedInformation.Vendor) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ErrorState", $SST_CollectedInformation.ErrorState) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Power", $SST_CollectedInformation.Power) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Presence", $SST_CollectedInformation.Presence) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ADTMode", $SST_CollectedInformation.ADTMode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_NeededInformations) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Then automatically clean up for this exact switch
                        $SQLiteCommand.CommandText ="DELETE FROM LibraryDrive WHERE ID NOT IN ( SELECT ID FROM LibraryDrive ORDER BY TimeStamp DESC LIMIT 512 );" 
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
            "LibraryMediaInfo" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO LibraryMediaInfo (CustomerNbr, Barcode, LocationType, LogicalNumber, PhysicalNumber, Cleaning, LogicalLibrary, Generation, SubType, Protection, Encryption, NoLoads, MBRead,`
                                                        MBReadLoad, MBWritten, MBWrittenLoad, SerialNumberMTM, TimeStamp)`
                                                    VALUES (@CustomerNbr, @Barcode, @LocationType, @LogicalNumber, @PhysicalNumber, @Cleaning, @LogicalLibrary, @Generation, @SubType, @Protection, @Encryption, @NoLoads, @MBRead,`
                                                        @MBReadLoad, @MBWritten, @MBWrittenLoad, @SerialNumberMTM, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Barcode", $SST_CollectedInformation.Barcode) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LocationType", $SST_CollectedInformation.LocationType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalNumber", $SST_CollectedInformation.LogicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PhysicalNumber", $SST_CollectedInformation.PhysicalNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Cleaning", $SST_CollectedInformation.Cleaning) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LogicalLibrary", $SST_CollectedInformation.LogicalLibrary) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Generation", $SST_CollectedInformation.Generation) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SubType", $SST_CollectedInformation.SubType) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Protection", $SST_CollectedInformation.Protection) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Encryption", $SST_CollectedInformation.Encryption) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@NoLoads", $SST_CollectedInformation.NoLoads) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MBRead", $SST_CollectedInformation.MBRead) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MBReadLoad", $SST_CollectedInformation.MBReadLoad) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MBWritten", $SST_CollectedInformation.MBWritten) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MBWrittenLoad", $SST_CollectedInformation.MBWrittenLoad) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_NeededInformations) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery()

                        # Delete | Keep only the 64 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM LibraryMediaInfo WHERE ID NOT IN ( SELECT ID FROM LibraryMediaInfo ORDER BY TimeStamp DESC LIMIT 512 );"
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