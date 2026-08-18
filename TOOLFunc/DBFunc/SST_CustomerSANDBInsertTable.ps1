function SST_CustomerSANDBInsertTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("SANBase","SANPortInfo","SANPortErrStats","SANSFPStats","SANSwitchInventory","SANSwitchInventoryFinalize")]
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
            "SANBase" {
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSANHWTable (CustomerNbr, Name, Status, CodeLevel, BrocadeProdName, MTM, SerialNumber, SwitchWWNN, VFID, VFenabled, VFsupported, TimeStamp) VALUES (@CustomerNbr, @Name, @Status, @CodeLevel, @BrocadeProdName, @MTM, @SerialNumber, @SwitchWWNN, @VFID, @VFenabled, @VFsupported, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.'SwitchName') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.'SwitchState') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.'FabricOS') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BrocadeProdName", $SST_CollectedInformation.'BrocadeProductName') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.'MTM') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.'SerialNumber') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.'SwitchWWNN') | Out-Null
                        $VFIDString = @($SST_CollectedInformation.'VFID') -join ','
                        $SQLiteCommand.Parameters.AddWithValue("@VFID", $VFIDString) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VFenabled", $SST_CollectedInformation.'VFenabled') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VFsupported", $SST_CollectedInformation.'VFsupported') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 16 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSANHWTable WHERE CustomerNbr = @CustomerNbr AND SerialNumber = @SerialNumber AND ID NOT IN (SELECT ID FROM IBMSANHWTable`
                                                        WHERE CustomerNbr = @CustomerNbr AND SerialNumber = @SerialNumber ORDER BY TimeStamp DESC LIMIT 16);"
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
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

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSANPortInfoTable (CustomerNbr, Port, State, Speed, PortConnect, SerialNumber, SwitchWWNN, VFID, TimeStamp) VALUES (@CustomerNbr, @Port, @State, @Speed, @PortConnect, @SerialNumber, @SwitchWWNN, @VFID, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Port", $SST_CollectedInformation.Port) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Speed", $SST_CollectedInformation.Speed) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PortConnect", $SST_CollectedInformation.PortConnect) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.SwitchWWNN) | Out-Null
                        $VFIDString = @($SST_CollectedInformation.'VFID') -join ','
                        $SQLiteCommand.Parameters.AddWithValue("@VFID", $VFIDString) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
 
                        # Then automatically clean up for this exact switch
                        $SQLiteCommand.CommandText ="DELETE FROM IBMSANPortInfoTable WHERE CustomerNbr = @CustomerNbr AND SwitchWWNN = @SwitchWWNN AND Port = @Port AND IFNULL(VFID,'') = IFNULL(@VFID,'') AND ID NOT IN (SELECT ID FROM IBMSANPortInfoTable`
                                                        WHERE CustomerNbr = @CustomerNbr AND SwitchWWNN = @SwitchWWNN AND Port = @Port AND IFNULL(VFID,'') = IFNULL(@VFID,'')`
                                                        ORDER BY datetime(TimeStamp) DESC, ID DESC LIMIT 1);"
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
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
            "SANPortErrStats"{
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.Transaction = $SQLiteTransaction

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations) {

                        $SQLiteCommand.Parameters.Clear()

                        $SQLiteCommand.CommandText = "INSERT INTO IBMSANPortErrorStatsTable (CustomerNbr,RowID,SwitchName,SerialNumber,SwitchWWNN,VFID,Port,EncIn,CrcErr,TooShort,TooLong,BadEOF,EncOut,DiscC3,LinkFail,LossSync,LossSig,StateTransitions,`
                                                        BBZero,FECuncorrected,TimeStamp)`
                                                    VALUES (@CustomerNbr,@RowID,@SwitchName,@SerialNumber,@SwitchWWNN,@VFID,@Port,@EncIn,@CrcErr,@TooShort,@TooLong,@BadEOF,@EncOut,@DiscC3,@LinkFail,@LossSync,@LossSig,@StateTransitions,@BBZero,`
                                                        @FECuncorrected,@TimeStamp);"

                        $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@RowID',$SST_CollectedInformation.RowID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SwitchName',$SST_CollectedInformation.SwitchName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SerialNumber',$SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SwitchWWNN',$SST_CollectedInformation.SwitchWWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@VFID',$SST_CollectedInformation.VFID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@Port',$SST_CollectedInformation.Port) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@EncIn',$SST_CollectedInformation.EncIn) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@CrcErr',$SST_CollectedInformation.CrcErr) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@TooShort',$SST_CollectedInformation.TooShort) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@TooLong',$SST_CollectedInformation.TooLong) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@BadEOF',$SST_CollectedInformation.BadEOF) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@EncOut',$SST_CollectedInformation.EncOut) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@DiscC3',$SST_CollectedInformation.DiscC3) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@LinkFail',$SST_CollectedInformation.LinkFail) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@LossSync',$SST_CollectedInformation.LossSync) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@LossSig',$SST_CollectedInformation.LossSig) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@StateTransitions',$SST_CollectedInformation.StateTransitions) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@BBZero',$SST_CollectedInformation.BBZero) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@FECuncorrected',$SST_CollectedInformation.FECuncorrected) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null
                        $SQLiteCommand.ExecuteNonQuery() |Out-Null
                    }

                    # Apply all measurements from this run at once.
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null

                    # History cleanup only after all INSERTs have completed.
                    $SQLiteCommand.Transaction = $null
                    $SQLiteCommand.Parameters.Clear()

                    $SQLiteCommand.CommandText = "DELETE FROM IBMSANPortErrorStatsTable WHERE TimeStamp < datetime('now', '-2 years');"
                    $SQLiteCommand.ExecuteNonQuery() | Out-Null
                }catch {

                    if ($null -ne $SQLiteTransaction) {
                        try {
                            $SQLiteTransaction.Rollback()
                        }
                        catch {
                            Write-Host (
                                "Rollback fehlgeschlagen: " +
                                "$($_.Exception.Message)"
                            )
                        }
                    }
                    Write-Host ("SQL Fehler: $($_.Exception.Message)") -ForegroundColor Red
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }finally {
                    
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
            "SANSFPStats"{
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations) {
                    
                        $SQLiteCommand.Parameters.Clear()
                    
                        $SQLiteCommand.CommandText = "INSERT INTO SANSFPStatsTable (CustomerNbr,RowID,SwitchName,SerialNumber,SwitchWWNN,VFID,Port,SFPUsed,SFPTyp,Connector,Media,Vendor,PartNumber,SFPSerialNumber,SpeedRange,Temperature,RxPower,TxPower,`
                                                        Voltage,Wavelength,PowerOnTime,TimeStamp)`
                                                    VALUES (@CustomerNbr,@RowID,@SwitchName,@SerialNumber,@SwitchWWNN,@VFID,@Port,@SFPUsed,@SFPTyp,@Connector,@Media,@Vendor,@PartNumber,@SFPSerialNumber,@SpeedRange,@Temperature,@RxPower,@TxPower,@Voltage,`
                                                    @Wavelength,@PowerOnTime,@TimeStamp);"
                    
                        $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@RowID',$SST_CollectedInformation.RowID) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SwitchName',$SST_CollectedInformation.SwitchName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SerialNumber',$SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SwitchWWNN',$SST_CollectedInformation.SwitchWWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@VFID',$SST_CollectedInformation.VFID) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@Port',$SST_CollectedInformation.Port) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@SFPUsed',[int][bool]$SST_CollectedInformation.SFPUsed) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@SFPTyp',$SST_CollectedInformation.SFPTyp) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@Connector',$SST_CollectedInformation.Connector) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@Media',$SST_CollectedInformation.Media) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@Vendor',$SST_CollectedInformation.Vendor) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@PartNumber',$SST_CollectedInformation.PartNumber) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@SFPSerialNumber',$SST_CollectedInformation.SerialNo) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@SpeedRange',$SST_CollectedInformation.SpeedRange) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@Temperature',$SST_CollectedInformation.Temperature) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@RxPower',$SST_CollectedInformation.RxPower) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@TxPower',$SST_CollectedInformation.TxPower) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@Voltage',$SST_CollectedInformation.Voltage) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@Wavelength',$SST_CollectedInformation.Wavelength) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@PowerOnTime',$SST_CollectedInformation.PowerOnTime) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null
                    
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                    
                    # -------------------------------------------------------------
                    # Apply all measurements from this collection run at once.
                    # -------------------------------------------------------------
                    
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null
                    
                    # -------------------------------------------------------------
                    # History cleanup
                    # -------------------------------------------------------------
                    $SQLiteCommand.Transaction = $null
                    
                    $SQLiteCommand.Parameters.Clear()
                    
                    $SQLiteCommand.CommandText = "DELETE FROM SANSFPStatsTable WHERE TimeStamp < datetime('now', '-2 years');"
                    $SQLiteCommand.ExecuteNonQuery() |Out-Null
                }catch {
                    
                    if ($null -ne $SQLiteTransaction) {                    
                        try {
                            $SQLiteTransaction.Rollback()
                        }catch {
                            Write-Host ("Rollback fehlgeschlagen: " +"$($_.Exception.Message)"
                            )
                        }
                    }
                    
                    Write-Host ("SQL Fehler: $($_.Exception.Message)") -ForegroundColor Red
                    
                    Write-Host $_.InvocationInfo.PositionMessage                    
                    Write-Host $_.Exception.ToString()
                }finally {
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
            "SANSwitchInventory" {
            
                $SQLiteTransaction = $null
            
                try {
                
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations) {

                        $SwitchWWNN = [string]$SST_CollectedInformation.SwitchWWNN
                        $SwitchName = [string]$SST_CollectedInformation.SwitchName
                        $SerialNumber = [string]$SST_CollectedInformation.SerialNumber
                    
                        # ---------------------------------------------------------
                        # A SAN switch without WWNN cannot be handled safely.
                        # ---------------------------------------------------------
                        if ([string]::IsNullOrWhiteSpace($SwitchWWNN)) {
                        
                            Write-Warning ('SANSwitchInventory: SAN switch without ' + 'SwitchWWNN was skipped.')
                            continue
                        }
                    
                        # ---------------------------------------------------------
                        # UPSERT
                        #
                        # Permanent identity:
                        #
                        #   CustomerNbr
                        #   SwitchWWNN
                        #
                        # SwitchName and SerialNumber are current properties.
                        # ---------------------------------------------------------
                    
                        $SQLiteCommand.Parameters.Clear()
                    
                        $SQLiteCommand.CommandText = "INSERT INTO SANSwitchInventoryTable (CustomerNbr,SwitchWWNN,SwitchName,SerialNumber,IsActive,FirstSeen,LastSeen,TimeStamp)`
                                                        VALUES (@CustomerNbr,@SwitchWWNN,@SwitchName,@SerialNumber,1,@FirstSeen,@LastSeen,@TimeStamp)`
                                                        ON CONFLICT (CustomerNbr,SwitchWWNN)`
                                                        DO UPDATE SET SwitchName   = excluded.SwitchName, SerialNumber = excluded.SerialNumber, IsActive = 1, LastSeen = excluded.LastSeen,TimeStamp = excluded.TimeStamp;"
                    
                        $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SwitchWWNN',$SwitchWWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SwitchName',$SwitchName) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@SerialNumber',$SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@FirstSeen',$TimeStamp) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue('@LastSeen',$TimeStamp) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null                    
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                    
                    $SQLiteTransaction.Commit()
                    $SQLiteTransaction.Dispose()
                    $SQLiteTransaction = $null
                }catch {
                    
                    if ($null -ne $SQLiteTransaction) {
                        try {
                            $SQLiteTransaction.Rollback()
                        }catch {
                            Write-Host ("Rollback fehlgeschlagen: " + $_.Exception.Message)
                        }
                    }
                    
                    Write-Host ("SQL Fehler: " + $_.Exception.Message) -ForegroundColor Red
                    
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }finally {
                    
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
            "SANSwitchInventoryFinalize" {
                $SQLiteTransaction = $null
                $Reader = $null
            
                try {
                    $SQLiteDBConnection.Open()
                    $SQLiteTransaction = $SQLiteDBConnection.BeginTransaction()
                    $SQLiteCommand = $SQLiteDBConnection.CreateCommand()
                    $SQLiteCommand.Transaction = $SQLiteTransaction
                
                    # -------------------------------------------------------------
                    # Collect all successfully scanned SAN Switch WWNNs.
                    #
                    # SwitchWWNN is the technical identity of a SAN Switch.
                    # -------------------------------------------------------------
                    $ScannedSwitchWWNNs = @($SST_CollectedInformations |
                            Where-Object {$null -ne $_ -and -not [string]::IsNullOrWhiteSpace([string]$_.SwitchWWNN)} |
                            ForEach-Object {[string]$_.SwitchWWNN} |
                            Select-Object -Unique
                    )
                        
                    # -------------------------------------------------------------
                    # Safety check.
                    #
                    # An empty successful-scan list must never deactivate all
                    # SAN switches.
                    # -------------------------------------------------------------
                    if ($ScannedSwitchWWNNs.Count -eq 0) {
                        throw ('SANSwitchInventoryFinalize received no valid ' + 'SwitchWWNN values. Finalization was aborted.')
                    }
                
                    # -------------------------------------------------------------
                    # Read all currently active SAN Switch inventory entries.
                    # -------------------------------------------------------------
                    $SQLiteCommand.Parameters.Clear()

                    $SQLiteCommand.CommandText = "SELECT ID, SwitchWWNN, SwitchName, SerialNumber FROM SANSwitchInventoryTable WHERE CustomerNbr = @CustomerNbr AND IsActive = 1; "
                
                    $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                
                    $Reader = $SQLiteCommand.ExecuteReader()
                
                    $ActiveInventory = @(
                        while ($Reader.Read()) {
                        
                            [PSCustomObject]@{
                                ID = [long]$Reader['ID']
                                SwitchWWNN = [string]$Reader['SwitchWWNN']
                                SwitchName = if ($Reader.IsDBNull($Reader.GetOrdinal('SwitchName'))) {$null}else {[string]$Reader['SwitchName']}
                                SerialNumber =if ($Reader.IsDBNull($Reader.GetOrdinal('SerialNumber'))) {$null}else {[string]$Reader['SerialNumber']}
                            }
                        }
                    )
                    
                    $Reader.Close()
                    $Reader.Dispose()
                    $Reader = $null
                    
                    # -------------------------------------------------------------
                    # Mark SAN switches as inactive when they were not part of
                    # the complete successful scan.
                    #
                    # LastSeen is deliberately NOT changed.
                    #
                    # LastSeen:
                    #   last time the switch was really seen
                    #
                    # TimeStamp:
                    #   last inventory state change
                    # -------------------------------------------------------------
                    foreach ($InventoryItem in $ActiveInventory) {
                        $SwitchSeen = $ScannedSwitchWWNNs -contains [string]$InventoryItem.SwitchWWNN                    
                        if ($SwitchSeen) {continue}
                    
                        $SQLiteCommand.Parameters.Clear()
                        $SQLiteCommand.CommandText = "UPDATE SANSwitchInventoryTable SET IsActive  = 0, TimeStamp = @TimeStamp WHERE ID = @ID;"
                    
                        $SQLiteCommand.Parameters.AddWithValue('@TimeStamp',$TimeStamp) | Out-Null                    
                        $SQLiteCommand.Parameters.AddWithValue('@ID',$InventoryItem.ID) | Out-Null
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                
                    # -------------------------------------------------------------
                    # Remove old inactive SAN Switch inventory entries.
                    #
                    # Retention:
                    #   IsActive = 0
                    #   AND LastSeen older than 3 months
                    #
                    # Active switches are never affected.
                    # -------------------------------------------------------------
                    $InventoryRetentionDate = (Get-Date).AddMonths(-3).ToString('yyyy-MM-dd HH:mm:ss')
                
                    $SQLiteCommand.Parameters.Clear()
                
                    $SQLiteCommand.CommandText = "DELETE FROM SANSwitchInventoryTable WHERE CustomerNbr = @CustomerNbr AND IsActive = 0 AND LastSeen < @InventoryRetentionDate; "
                
                    $SQLiteCommand.Parameters.AddWithValue('@CustomerNbr',$Customer) | Out-Null
                    $SQLiteCommand.Parameters.AddWithValue('@InventoryRetentionDate',$InventoryRetentionDate) | Out-Null
                
                    $DeletedInventoryRows = $SQLiteCommand.ExecuteNonQuery()
                
                    # -------------------------------------------------------------
                    # Optional debug logging when old inventory entries were
                    # actually removed.
                    # -------------------------------------------------------------
                    if ($DeletedInventoryRows -gt 0) {
                        SST_ToolMessageCollector -TD_ToolMSGCollector ('SAN Switch inventory cleanup removed ' + "$DeletedInventoryRows inactive entries " + 'older than 3 months.') -TD_ToolMSGType Debug -TD_Shown 'no'
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
                            Write-Host ('Rollback fehlgeschlagen: ' + $_.Exception.Message)
                        }
                    }
                
                    Write-Host ('SQL Fehler: ' + $_.Exception.Message) -ForegroundColor Red
                    Write-Host $_.InvocationInfo.PositionMessage
                    Write-Host $_.Exception.ToString()
                }finally {
                
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