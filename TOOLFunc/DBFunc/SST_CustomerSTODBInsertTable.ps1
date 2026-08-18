function SST_CustomerSTODBInsertTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("StorageDrive","StorageBase","StorageHostInfo","StorageEventLog","FCPortStats","PoolCapacity","VDiskAnalysis","VolumeInventory","StorageInventory","StorageInventoryFinalize")]
        [string]$SST_InfoType,
        $SST_NewDBObject =$null,
        $SST_CollectedInformations,
        $SST_Customer,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

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
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 128 most recent entries after TimeStamp 
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTOHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOHWTable ORDER BY TimeStamp DESC LIMIT 64 );"
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
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
                    $HostCounter = 0

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){

                        # Debug part becaue sometimes O,o
                        $HostCounter++
                        # Debugging: Prüfen, ob alle Pflichtwerte für den DB-Insert vorhanden sind
                        $MissingValues = [System.Collections.Generic.List[string]]::new()

                        if ($null -eq $SST_CollectedInformation) {
                            Write-Host "Hostdatensatz $HostCounter will be skipped. Object is null." -ForegroundColor DarkCyan
                            SST_ToolMessageCollector -TD_ToolMSGCollector "Hostdatensatz $HostCounter will be skipped. Object is null." -TD_ToolMSGType Error -TD_Shown yes
                            continue
                        }
                    
                        if ([string]::IsNullOrWhiteSpace([string]$SST_CollectedInformation.HostName)) {$null = $MissingValues.Add('HostName')}
                        if ([string]::IsNullOrWhiteSpace([string]$SST_CollectedInformation.Status)) {$null = $MissingValues.Add('Status')}
                        if ([string]::IsNullOrWhiteSpace([string]$SST_CollectedInformation.WWNN)) {$null = $MissingValues.Add('WWNN')}
                    
                        if ($MissingValues.Count -gt 0) {
                        
                            $MissingValuesText = $MissingValues -join ', '
                        
                            $DebugMessage = (
                                "Hostdatensatz $HostCounter will be skipped. " +
                                "Missing required values: $MissingValuesText"
                            )
                        
                            Write-Host $DebugMessage -ForegroundColor DarkCyan
                        
                            SST_ToolMessageCollector -TD_ToolMSGCollector $DebugMessage -TD_ToolMSGType Error -TD_Shown yes
                            # Display only on the console; do not write to the function pipeline
                            $SST_CollectedInformation | Format-List * | Out-Host
                            continue
                        }
                        
                        # normal function goes on
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
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTOHostTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOHostTable ORDER BY TimeStamp DESC LIMIT 128 );"
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
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
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 500 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSTOEventsTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOEventsTable ORDER BY TimeStamp DESC LIMIT 512 );"
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
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
            "PoolCapacity" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations) {
                        $SQLiteCommand.Parameters.Clear()
                    
                        $SQLiteCommand.CommandText = "INSERT INTO IBMSTOPoolCapacityTable (CustomerNbr,RowID,PoolID,PoolName,Capacity,FreeCapacity,VirtualCapacity,UsedCapacity,RealCapacity,Overallocation,WWNN,SerialNumber,TimeStamp)`
                                                        VALUES (@CustomerNbr,@RowID,@PoolID,@PoolName,@Capacity,@FreeCapacity,@VirtualCapacity,@UsedCapacity,@RealCapacity,@Overallocation,@WWNN,@SerialNumber,@TimeStamp);"
                    
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr",$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RowID",$SST_CollectedInformation.RowID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PoolID",$SST_CollectedInformation.ID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PoolName",$SST_CollectedInformation.Name) | Out-Null
                        # Capacity values are returned by the Storage API as strings
                        # such as "19.99TB". Normalize them to bytes before storing.
                        $SQLiteCommand.Parameters.AddWithValue("@Capacity",(ConvertTo-ByteValue -Value $SST_CollectedInformation.Capacity)) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@FreeCapacity",(ConvertTo-ByteValue -Value $SST_CollectedInformation.FreeCapacity)) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VirtualCapacity",(ConvertTo-ByteValue -Value $SST_CollectedInformation.VirtualCapacity)) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@UsedCapacity",(ConvertTo-ByteValue -Value $SST_CollectedInformation.UsedCapacity)) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RealCapacity",(ConvertTo-ByteValue -Value $SST_CollectedInformation.RealCapacity)) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Overallocation",[double]$SST_CollectedInformation.Overallocation) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN",$SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber",$SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp",$TimeStamp) | Out-Null
                    
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                    
                    # Apply all pool measurements from this run at once.
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null
                    
                    # Cleanup only after all new measurements were committed.
                    $SQLiteCommand.Transaction = $null
                    $SQLiteCommand.Parameters.Clear()
                    
                    $SQLiteCommand.CommandText = "DELETE FROM IBMSTOPoolCapacityTable WHERE TimeStamp < datetime('now', '-2 years');"
                    
                    $SQLiteCommand.ExecuteNonQuery() | Out-Null
                }catch {
                    if ($null -ne $SQLiteTransaction) {
                        try {
                            $SQLiteTransaction.Rollback()
                        }
                        catch {
                            Write-Host (
                                "Rollback fehlgeschlagen: $($_.Exception.Message)"
                            )
                        }
                    }
                    
                    Write-Host ("SQL Fehler: $($_.Exception.Message)") -ForegroundColor Red
                    
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }finally {
                    if ($null -ne $SQLiteTransaction) {
                        $SQLiteTransaction.Dispose()
                    }
                    
                    if ($null -ne $SQLiteCommand) {
                        $SQLiteCommand.Dispose()
                    }
                    
                    if ($null -ne $SQLiteDBConnection) {
                        if ($SQLiteDBConnection.State -ne [System.Data.ConnectionState]::Closed) {
                            $SQLiteDBConnection.Close()
                        }
                        $SQLiteDBConnection.Dispose()
                    }
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }
            }
            "FCPortStats" {
                try {
                    $SQLiteDBConnection.Open()

                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()

                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.Transaction = $SQLiteTransaction

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()
                        
                        $SQLiteCommand.CommandText ="INSERT INTO IBMSTOFCPortStatsTable (CustomerNbr,RowID,NodeID,NodeName,CardType,CardID,PortID,WWPN,LinkFailure,LoseSync,LoseSig,PSErrCount,InvTransErr,CRCErr,ZeroBtB,SFPTemp,TXPwr,TXPwrLow,RXPwr,RXPwrLow,WWNN,SerialNumber,TimeStamp)`
                                                        VALUES (@CustomerNbr,@RowID,@NodeID,@NodeName,@CardType,@CardID,@PortID,@WWPN,@LinkFailure,@LoseSync,@LoseSig,@PSErrCount,@InvTransErr,@CRCErr,@ZeroBtB,@SFPTemp,@TXPwr,@TXPwrLow,@RXPwr,@RXPwrLow,@WWNN,@SerialNumber,@TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RowID", $SST_CollectedInformation.RowID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@NodeID", $SST_CollectedInformation.NodeID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@NodeName", $SST_CollectedInformation.NodeName) | Out-Null
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
                        $SQLiteCommand.Parameters.AddWithValue("@TXPwrLow", $SST_CollectedInformation.TXPwrLow) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RXPwr", $SST_CollectedInformation.RXPwr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RXPwrLow", $SST_CollectedInformation.RXPwrLow) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }

                    # Apply all measurements from this run at once.
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null

                    # Do not perform history cleanup until after all INSERTs have been completed.
                    $SQLiteCommand.Transaction = $null
                    $SQLiteCommand.Parameters.Clear()

                    # Example:
                    # Remove data older than two years.
                    $SQLiteCommand.CommandText = "DELETE FROM IBMSTOFCPortStatsTable WHERE TimeStamp < datetime('now', '-2 years');"
                    $SQLiteCommand.ExecuteNonQuery() | Out-Null

                    
                }catch {
                    if ($null -ne $SQLiteTransaction) {
                        try {
                                $SQLiteTransaction.Rollback()
                            }catch {
                                Write-Host "Rollback fehlgeschlagen: $($_.Exception.Message)"
                            }
                    }
                    Write-Host "SQL Fehler: $($_.Exception.Message)" -ForegroundColor Red
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()

                }finally {
                    if ($null -ne $SQLiteTransaction) {$SQLiteTransaction.Dispose()}
                    if ($null -ne $SQLiteCommand) {$SQLiteCommand.Dispose()}
                        
                    if ($null -ne $SQLiteDBConnection) {
                        if ($SQLiteDBConnection.State -ne [System.Data.ConnectionState]::Closed) {$SQLiteDBConnection.Close()}
                        $SQLiteDBConnection.Dispose()
                    }
                        
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }
            }
            "VDiskAnalysis" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations) {
                    
                        $SQLiteCommand.Parameters.Clear()
                    
                        $SQLiteCommand.CommandText = "INSERT INTO IBMSTOVolumeAnalysisTable (CustomerNbr,RowID,VolumeID,VdiskUID,VolumeName,State,AnalysisTime,Capacity,ThinSize,ThinSavings,ThinSavingsRatio,CompressedSize,CompressionSavings,CompressionSavingsRatio,`
                                                        TotalSavings,TotalSavingsRatio,MarginOfError,WWNN,SerialNumber,TimeStamp)`
                                                        VALUES (@CustomerNbr,@RowID,@VolumeID,@VdiskUID,@VolumeName,@State,@AnalysisTime,@Capacity,@ThinSize,@ThinSavings,@ThinSavingsRatio,@CompressedSize,@CompressionSavings,@CompressionSavingsRatio,@TotalSavings,`
                                                        @TotalSavingsRatio,@MarginOfError,@WWNN,@SerialNumber,@TimeStamp);"
                    
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr",$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RowID",$SST_CollectedInformation.RowID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VolumeID",$SST_CollectedInformation.VolumeID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VdiskUID",$SST_CollectedInformation.VdiskUID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VolumeName",$SST_CollectedInformation.VolumeName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State",$SST_CollectedInformation.State) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@AnalysisTime",$SST_CollectedInformation.AnalysisTime) | Out-Null
                        # Capacity values such as "5.00TB" or "391.11GB"
                        # are normalized to bytes before they are stored.
                        $SQLiteCommand.Parameters.AddWithValue("@Capacity",$SST_CollectedInformation.Capacity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ThinSize",$SST_CollectedInformation.ThinSize) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ThinSavings",$SST_CollectedInformation.ThinSavings) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@ThinSavingsRatio",$SST_CollectedInformation.ThinSavingsRatio) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CompressedSize",$SST_CollectedInformation.CompressedSize) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CompressionSavings",$SST_CollectedInformation.CompressionSavings) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CompressionSavingsRatio",$SST_CollectedInformation.CompressionSavingsRatio) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TotalSavings",$SST_CollectedInformation.TotalSavings) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TotalSavingsRatio",$SST_CollectedInformation.TotalSavingsRatio) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MarginOfError",$SST_CollectedInformation.MarginOfError) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN",$SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber",$SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp",$TimeStamp) | Out-Null
                    
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                    
                    # Apply all volume analysis measurements from this run at once.
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null
                    
                    # Cleanup only after all new measurements were committed.
                    $SQLiteCommand.Transaction = $null
                    $SQLiteCommand.Parameters.Clear()
                    
                    $SQLiteCommand.CommandText = "DELETE FROM IBMSTOVolumeAnalysisTable WHERE TimeStamp < datetime('now', '-2 years');"
                    
                    $SQLiteCommand.ExecuteNonQuery() | Out-Null
                }
                catch {
                    if ($null -ne $SQLiteTransaction) {
                        try {
                            $SQLiteTransaction.Rollback()
                        }
                        catch {
                            Write-Host ("Rollback fehlgeschlagen: $($_.Exception.Message)")
                        }
                    }
                    
                    Write-Host ("SQL Fehler: $($_.Exception.Message)") -ForegroundColor Red
                    
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    if ($null -ne $SQLiteTransaction) {
                        $SQLiteTransaction.Dispose()
                    }
                    
                    if ($null -ne $SQLiteCommand) {
                        $SQLiteCommand.Dispose()
                    }
                    
                    if ($null -ne $SQLiteDBConnection) {
                        if ($SQLiteDBConnection.State -ne [System.Data.ConnectionState]::Closed) {
                            $SQLiteDBConnection.Close()
                        }
                    
                        $SQLiteDBConnection.Dispose()
                    }
                    
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }
            }
            "VolumeInventory" {
                $SQLiteTransaction = $null
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations) {
                    
                        $SQLiteCommand.Parameters.Clear()
                    
                        $SQLiteCommand.CommandText = "INSERT INTO IBMSTOVolumeInventoryTable (CustomerNbr,SerialNumber,WWNN,VolumeID,VdiskUID,VolumeName,RowID,IsActive,FirstSeen,LastSeen,TimeStamp)`
                                                        VALUES (@CustomerNbr,@SerialNumber,@WWNN,@VolumeID,@VdiskUID,@VolumeName,@RowID,1,@FirstSeen,@LastSeen,@TimeStamp)`
                                                        ON CONFLICT (CustomerNbr,SerialNumber,VdiskUID)`
                                                        DO UPDATE SET WWNN = excluded.WWNN, VolumeID = excluded.VolumeID, VolumeName = excluded.VolumeName,RowID = excluded.RowID, IsActive   = 1, LastSeen   = excluded.LastSeen, TimeStamp  = excluded.TimeStamp;"
                    
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr",$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber",$SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@WWNN",$SST_CollectedInformation.WWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VolumeID",$SST_CollectedInformation.VolumeID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VdiskUID",$SST_CollectedInformation.VdiskUID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VolumeName",$SST_CollectedInformation.VolumeName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@RowID",$SST_CollectedInformation.RowID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@FirstSeen",$TimeStamp) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@LastSeen",$TimeStamp) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp",$TimeStamp) | Out-Null
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }

                    # -------------------------------------------------------------
                    # Mark volumes as inactive when they were not part of the
                    # current successful inventory scan.
                    #
                    # This is done separately for every Storage system.
                    #
                    # Permanent identity:
                    #
                    #   CustomerNbr
                    #   SerialNumber
                    #   VdiskUID
                    # -------------------------------------------------------------

                    $ScannedSystems = @(
                        $SST_CollectedInformations |
                            Where-Object {
                                $null -ne $_ -and
                                -not [string]::IsNullOrWhiteSpace(
                                    [string]$_.SerialNumber
                                )
                            } |
                            Group-Object SerialNumber
                    )
                        
                    foreach ($SystemGroup in $ScannedSystems) {
                    
                        $SerialNumber =
                            [string]$SystemGroup.Name
                    
                        # ---------------------------------------------------------
                        # Collect all VdiskUIDs that exist in the current scan
                        # for this Storage system.
                        # ---------------------------------------------------------
                    
                        $CurrentUIDs = @(
                            $SystemGroup.Group |
                                ForEach-Object {
                                    [string]$_.VdiskUID
                                } |
                                Where-Object {
                                    -not [string]::IsNullOrWhiteSpace($_)
                                } |
                                Select-Object -Unique
                        )
                            
                        if ($CurrentUIDs.Count -eq 0) {
                            continue
                        }
                    
                        $SQLiteCommand.Parameters.Clear()
                    
                        # ---------------------------------------------------------
                        # Build one SQL parameter for every current VdiskUID.
                        #
                        # Example:
                        #
                        #   NOT IN (
                        #       @UID0,
                        #       @UID1,
                        #       @UID2
                        #   )
                        # ---------------------------------------------------------
                    
                        $UIDParameters =
                            [System.Collections.Generic.List[string]]::new()
                    
                        for ($i = 0; $i -lt $CurrentUIDs.Count; $i++) {
                        
                            $ParameterName =
                                "@UID$i"
                        
                            $UIDParameters.Add(
                                $ParameterName
                            )
                        
                            $SQLiteCommand.Parameters.AddWithValue(
                                $ParameterName,
                                $CurrentUIDs[$i]
                            ) | Out-Null
                        }
                    
                        $UIDParameterList =
                            $UIDParameters -join ','
                    
                        # ---------------------------------------------------------
                        # Everything that belongs to this Storage system but was
                        # not returned by the current scan is no longer active.
                        #
                        # We deliberately do NOT delete the inventory entry.
                        # The historical identity remains available.
                        # ---------------------------------------------------------
                    
                        $SQLiteCommand.CommandText = "UPDATE IBMSTOVolumeInventoryTable SET IsActive  = 0, TimeStamp = @TimeStamp WHERE CustomerNbr = @CustomerNbr AND SerialNumber = @SerialNumber AND IsActive = 1 AND VdiskUID NOT IN ($UIDParameterList);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr",$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber",$SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp",$TimeStamp) | Out-Null
                    
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                    
                    # -------------------------------------------------------------
                    # All current volumes were written successfully.
                    # -------------------------------------------------------------
                    
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null

                    # -------------------------------------------------------------
                    # Remove old inactive inventory entries.
                    #
                    # Only volumes which:
                    #
                    #   - are no longer active
                    #   - have not been seen for more than 3 months
                    #
                    # are removed.
                    #
                    # Active volumes are never affected by this cleanup.
                    # -------------------------------------------------------------

                    $SQLiteCommand.Parameters.Clear()
                    $SQLiteCommand.CommandText = "DELETE FROM IBMSTOVolumeInventoryTable WHERE CustomerNbr = @CustomerNbr AND IsActive = 0 AND LastSeen < @InventoryRetentionDate;"
                    $InventoryRetentionDate = (Get-Date).AddMonths(-3).ToString('yyyy-MM-dd HH:mm:ss')
                    $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                    $SQLiteCommand.Parameters.AddWithValue('@InventoryRetentionDate',$InventoryRetentionDate) | Out-Null

                    $DeletedInventoryRows =$SQLiteCommand.ExecuteNonQuery()

                    if ($DeletedInventoryRows -gt 0) {
                        SST_ToolMessageCollector -TD_ToolMSGCollector ("Volume inventory cleanup removed " + "$DeletedInventoryRows inactive entries older than 3 months.") -TD_ToolMSGType Message -TD_Shown "no"
                    }

                }catch {
                    if ($null -ne $SQLiteTransaction) {                    
                        try {
                            $SQLiteTransaction.Rollback()
                        }
                        catch {
                            Write-Host (
                                "Rollback fehlgeschlagen: $($_.Exception.Message)"
                            )
                        }
                    }
                    Write-Host ("SQL Fehler: $($_.Exception.Message)") -ForegroundColor Red
                    
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    if ($null -ne $SQLiteTransaction) {$SQLiteTransaction.Dispose()}
                    if ($null -ne $SQLiteCommand) {$SQLiteCommand.Dispose()}
                    if ($null -ne $SQLiteDBConnection) {                    
                        if (
                            $SQLiteDBConnection.State -ne
                            [System.Data.ConnectionState]::Closed
                        ) {
                            $SQLiteDBConnection.Close()
                        }
                    
                        $SQLiteDBConnection.Dispose()
                    }
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }
            }
            "StorageInventory" {
                $SQLiteTransaction = $null
            
                try {
                    # -------------------------------------------------------------
                    # Open database connection and start one transaction for the complete Storage inventory synchronization.
                    # -------------------------------------------------------------
                
                    $SQLiteDBConnection.Open()
                
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations) {
                    
                        # ---------------------------------------------------------
                        # Normalize the current Storage identity information.
                        # ---------------------------------------------------------
                        $SerialNumber = [string]$SST_CollectedInformation.SerialNumber
                        $WWNN = [string]$SST_CollectedInformation.WWNN
                        $ClusterName = [string]$SST_CollectedInformation.ClusterName
                        $ProdMTM = [string]$SST_CollectedInformation.ProdMTM
                    
                        # ---------------------------------------------------------
                        # A Storage system without SerialNumber or WWNN cannot be safely handled by the identity logic.
                        # ---------------------------------------------------------
                        if ([string]::IsNullOrWhiteSpace($SerialNumber) -or [string]::IsNullOrWhiteSpace($WWNN)) {
                            Write-Warning ('StorageInventory: Storage system without ' + 'SerialNumber or WWNN was skipped.')
                        
                            continue
                        }
                    
                        # =========================================================
                        # STEP 1
                        # Search by SerialNumber.
                        # Same SerialNumber means:
                        #
                        #   -> same physical Storage system
                        #
                        # This has the highest priority.
                        # =========================================================
                        $SQLiteCommand.Parameters.Clear()
                        $SQLiteCommand.CommandText = "SELECT ID, SystemIdentity, SerialNumber, WWNN FROM IBMSTOSystemInventoryTable WHERE CustomerNbr = @CustomerNbr AND SerialNumber = @SerialNumber LIMIT 1; "
                    
                        $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SerialNumber',$SerialNumber) | Out-Null
                        $Reader = $SQLiteCommand.ExecuteReader()

                        $ExistingBySerial = $null
                    
                        if ($Reader.Read()) {
                            $ExistingBySerial = [PSCustomObject]@{
                                    ID = $Reader['ID']
                                    SystemIdentity = [string]$Reader['SystemIdentity']
                                    SerialNumber = [string]$Reader['SerialNumber']
                                    WWNN = [string]$Reader['WWNN']
                                }
                        }
                    
                        $Reader.Close()
                        $Reader.Dispose()
                    
                        # ---------------------------------------------------------
                        # Existing SerialNumber:
                        #
                        # Same physical Storage system.
                        # Refresh its current information.
                        # ---------------------------------------------------------
                    
                        if ($null -ne $ExistingBySerial) {
                            $SQLiteCommand.Parameters.Clear()

                            $SQLiteCommand.CommandText = "UPDATE IBMSTOSystemInventoryTable SET WWNN = @WWNN, ClusterName = @ClusterName, ProdMTM = @ProdMTM, IsActive = 1, LastSeen = @LastSeen, TimeStamp = @TimeStamp WHERE ID = @ID; "

                            $SQLiteCommand.Parameters.AddWithValue('@WWNN',$WWNN) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@ClusterName',$ClusterName) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@ProdMTM',$ProdMTM) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@LastSeen',$TimeStamp) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@ID',$ExistingBySerial.ID) | Out-Null

                            $SQLiteCommand.ExecuteNonQuery() |
                                Out-Null

                            continue
                        }
                    
                        # =========================================================
                        # STEP 2
                        # SerialNumber is unknown.
                        # Search by WWNN.
                        # Unknown SerialNumber + known WWNN means:
                        #
                        #   -> likely Storage hardware replacement
                        #   -> keep SystemIdentity
                        #   -> replace physical SerialNumber
                        # =========================================================
                    
                        $SQLiteCommand.Parameters.Clear()
                    
                        $SQLiteCommand.CommandText = "SELECT ID, SystemIdentity, SerialNumber, WWNN FROM IBMSTOSystemInventoryTable WHERE CustomerNbr = @CustomerNbr AND WWNN = @WWNN LIMIT 1;"
                    
                        $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@WWNN',$WWNN) | Out-Null
                        $Reader = $SQLiteCommand.ExecuteReader()
                        $ExistingByWWNN = $null
                    
                        if ($Reader.Read()) {

                            $ExistingByWWNN = [PSCustomObject]@{
                                    ID = $Reader['ID']
                                    SystemIdentity = [string]$Reader['SystemIdentity']
                                    SerialNumber = [string]$Reader['SerialNumber']
                                    WWNN = [string]$Reader['WWNN']
                                }
                        }
                    
                        $Reader.Close()
                        $Reader.Dispose()
                    
                        if ($null -ne $ExistingByWWNN) {

                            # -----------------------------------------------------
                            # Hardware replacement detected.
                            #
                            # IMPORTANT:
                            # SystemIdentity is deliberately NOT changed.
                            # Only the current physical SerialNumber and current
                            # system information are replaced.
                            # -----------------------------------------------------

                            $SQLiteCommand.Parameters.Clear()
                            $SQLiteCommand.CommandText = "UPDATE IBMSTOSystemInventoryTable SET SerialNumber = @SerialNumber, ClusterName = @ClusterName, ProdMTM = @ProdMTM, IsActive = 1, LastSeen = @LastSeen, TimeStamp = @TimeStamp WHERE ID = @ID;"

                            $SQLiteCommand.Parameters.AddWithValue('@SerialNumber',$SerialNumber) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@ClusterName',$ClusterName) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@ProdMTM',$ProdMTM) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@LastSeen',$TimeStamp) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null
                            $SQLiteCommand.Parameters.AddWithValue('@ID',$ExistingByWWNN.ID) | Out-Null

                            $SQLiteCommand.ExecuteNonQuery() |
                                Out-Null

                            continue
                        }
                    
                        # =========================================================
                        # STEP 3
                        #
                        # Neither SerialNumber nor WWNN is known.
                        # This is a completely new Storage system.
                        # Generate a new permanent logical SystemIdentity.
                        # =========================================================
                    
                        $SystemIdentity = [guid]::NewGuid().ToString()
                    
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText = "INSERT INTO IBMSTOSystemInventoryTable (CustomerNbr,SystemIdentity,SerialNumber,WWNN,ClusterName,ProdMTM,IsActive,FirstSeen,LastSeen,TimeStamp)`
                                                        VALUES (@CustomerNbr,@SystemIdentity,@SerialNumber,@WWNN,@ClusterName,@ProdMTM,1,@FirstSeen,@LastSeen,@TimeStamp);"
                    
                        $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@SystemIdentity',$SystemIdentity) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SerialNumber',$SerialNumber) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@WWNN',$WWNN) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@ClusterName',$ClusterName) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@ProdMTM',$ProdMTM) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@FirstSeen',$TimeStamp) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@LastSeen',$TimeStamp) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null
                    
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                    
                    # -------------------------------------------------------------
                    # Everything succeeded.
                    # -------------------------------------------------------------
                    
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null
                }
                catch {
                    
                    # -------------------------------------------------------------
                    # Roll back only when a valid transaction still exists.
                    # -------------------------------------------------------------
                    
                    if ($null -ne $SQLiteTransaction) {
                        try {
                            $SQLiteTransaction.Rollback()
                        }
                        catch {
                            Write-Host (
                                "Rollback fehlgeschlagen: " +
                                $_.Exception.Message
                            )
                        }
                    }
                    
                    Write-Host ("SQL Fehler: " + $_.Exception.Message) -ForegroundColor Red
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    
                    if ($null -ne $SQLiteTransaction) {$SQLiteTransaction.Dispose()}
                    if ($null -ne $SQLiteCommand) {$SQLiteCommand.Dispose()}
                    
                    if ($null -ne $SQLiteDBConnection) {
                        if ($SQLiteDBConnection.State -ne [System.Data.ConnectionState]::Closed) {
                            $SQLiteDBConnection.Close()
                        }
                    
                        $SQLiteDBConnection.Dispose()
                    }
                    
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }
            }
            "StorageInventoryFinalize" {
            
                $SQLiteTransaction = $null
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                    # -------------------------------------------------------------
                    # Normalize all successfully scanned Storage systems.
                    # We deliberately keep both identifiers:
                    #
                    #   SerialNumber
                    #   WWNN
                    #
                    # A Storage system counts as "seen" when either its current
                    # SerialNumber OR its current WWNN was present in the successful
                    # scan.
                    # -------------------------------------------------------------
                
                    $ScannedSerialNumbers = @( $SST_CollectedInformations |
                            Where-Object {$null -ne $_ -and -not [string]::IsNullOrWhiteSpace( [string]$_.SerialNumber )} |
                            ForEach-Object {[string]$_.SerialNumber} |
                            Select-Object -Unique
                    )
                    $ScannedWWNNs = @($SST_CollectedInformations |
                        Where-Object {$null -ne $_ -and -not [string]::IsNullOrWhiteSpace( [string]$_.WWNN)} |
                            ForEach-Object {[string]$_.WWNN} |
                            Select-Object -Unique
                    )
                        
                    # -------------------------------------------------------------
                    # Safety check.
                    #
                    # Finalize should only have been called after a successful scan.
                    # Nevertheless, an empty input must never deactivate everything.
                    # -------------------------------------------------------------
                        
                    if ($ScannedSerialNumbers.Count -eq 0 -and $ScannedWWNNs.Count -eq 0) {
                        throw (
                            'StorageInventoryFinalize received no valid ' +
                            'SerialNumber or WWNN values. Finalization was aborted.'
                        )
                    }
                
                    # -------------------------------------------------------------
                    # Read all currently active Storage inventory entries for this customer.
                    # -------------------------------------------------------------
                
                    $SQLiteCommand.Parameters.Clear()
                    $SQLiteCommand.CommandText = "SELECT ID, SystemIdentity, SerialNumber, WWNN FROM IBMSTOSystemInventoryTable WHERE CustomerNbr = @CustomerNbr AND IsActive = 1; "
                
                    $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr', $Customer) | Out-Null
                    $Reader = $SQLiteCommand.ExecuteReader()
                
                    $ActiveInventory = @(while ($Reader.Read()) {
                            [PSCustomObject]@{
                                ID = [long]$Reader['ID']
                                SystemIdentity = [string]$Reader['SystemIdentity']
                                SerialNumber = [string]$Reader['SerialNumber']
                                WWNN = [string]$Reader['WWNN']
                            }
                        }
                    )

                    $Reader.Close()
                    $Reader.Dispose()
                    $Reader = $null

                    # -------------------------------------------------------------
                    # Check every currently active inventory object.
                    # Seen means:
                    #
                    #   SerialNumber was found
                    #       OR
                    #   WWNN was found
                    #
                    # The OR is important for Storage hardware replacement.
                    # -------------------------------------------------------------

                    foreach ($InventoryItem in $ActiveInventory) {
                        $SerialSeen = $ScannedSerialNumbers -contains [string]$InventoryItem.SerialNumber

                        $WWNNSeen = $ScannedWWNNs -contains [string]$InventoryItem.WWNN

                        if ($SerialSeen -or $WWNNSeen) {continue}

                        # ---------------------------------------------------------
                        # Storage system was not present in the complete successful scan anymore.
                        #
                        # LastSeen is deliberately NOT changed.
                        # ---------------------------------------------------------

                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText = "UPDATE IBMSTOSystemInventoryTable SET IsActive  = 0, TimeStamp = @TimeStamp WHERE ID = @ID;"

                        $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@ID',$InventoryItem.ID) | Out-Null
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                
                    # -------------------------------------------------------------
                    # Remove old inactive Storage inventory entries.
                    #
                    # Only systems which:
                    #
                    #   - are inactive
                    #   - have not been seen for more than 3 months
                    #
                    # are removed.
                    # -------------------------------------------------------------

                    $SQLiteCommand.Parameters.Clear()

                    $InventoryRetentionDate = (Get-Date).AddMonths(-3).ToString('yyyy-MM-dd HH:mm:ss')

                    $SQLiteCommand.CommandText = "DELETE FROM IBMSTOSystemInventoryTable WHERE CustomerNbr = @CustomerNbr AND IsActive = 0 AND LastSeen < @InventoryRetentionDate;"

                    $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                    $SQLiteCommand.Parameters.AddWithValue('@InventoryRetentionDate',$InventoryRetentionDate) | Out-Null
                    $DeletedInventoryRows = $SQLiteCommand.ExecuteNonQuery()

                    if ($DeletedInventoryRows -gt 0) {
                        SST_ToolMessageCollector -TD_ToolMSGCollector ("Storage inventory cleanup removed " + "$DeletedInventoryRows inactive entries older than 3 months.") -TD_ToolMSGType Debug -TD_Shown "no"
                    }

                    # -------------------------------------------------------------
                    # Finalization completed successfully.
                    # -------------------------------------------------------------
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null
                    
                }catch {
                
                    if ($null -ne $SQLiteTransaction) {
                        try {
                            $SQLiteTransaction.Rollback()
                        }catch {
                            Write-Host (
                                "Rollback fehlgeschlagen: " +
                                $_.Exception.Message
                            )
                        }
                    }
                
                    Write-Host ("SQL Fehler: " + $_.Exception.Message ) -ForegroundColor Red

                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }
                finally {
                
                    if ($null -ne $Reader) {$Reader.Close();$Reader.Dispose()}
                
                    if ($null -ne $SQLiteTransaction) {$SQLiteTransaction.Dispose()}
                
                    if ($null -ne $SQLiteCommand) {$SQLiteCommand.Dispose()}
                
                    if ($null -ne $SQLiteDBConnection) {
                        if ($SQLiteDBConnection.State -ne [System.Data.ConnectionState]::Closed) {
                            $SQLiteDBConnection.Close()
                        }
                        $SQLiteDBConnection.Dispose()
                    }
                
                    [System.Data.SQLite.SQLiteConnection]::ClearAllPools()
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong during saving the $SST_InfoType data in the local db.") -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {

    }
}