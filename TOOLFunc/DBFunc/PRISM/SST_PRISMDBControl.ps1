function SST_PRISMDBControl {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("StorageDrive","StorageBase","StorageEventLog","SANBase","PowerHMC","PowerSysSummary","LPARSummary","LibraryBaseInfo","LibraryDrive","LibraryEvents","LibraryReports")]
        [string]$SST_InfoType,
        $CustomerNumber =$null,
        [bool]$AZConnection = $false,
        $SST_CollectedInformations,
        [string]$TimeStamp
    )
    
    begin {
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar

        try {
            $TD_AZDBObj = SST_ToolAdvSaveDB -SST_InfoType "LoadPRISMSettings"

            $ConString = Convert-SecureStringToPlainText ($TD_AZDBObj.AZConString | ConvertTo-SecureString)
            $AZCredN  = $TD_AZDBObj.CustomerNBR
            $AZCredP  = Convert-SecureStringToPlainText ($TD_AZDBObj.CustomerP | ConvertTo-SecureString)
            $AZDBNAM = Convert-SecureStringToPlainText ($TD_AZDBObj.AZDBNAM | ConvertTo-SecureString)

            if($AZCredN -like $CustomerNumber){
                $ConnectionStringPRISM = $ConString.Replace('{replaceone}',[string]$AZDBNAM).Replace('{replacetwo}',"$AZCredN").Replace('{replacethree}',"$AZCredP")
            }
            $ConString = $null
            $AZCredP = $null
            $AZDBNAM = $null
        }
        catch {
            <#Do this if a terminating exception happens#>
            SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        }
       
        try {
            if (-not $SQLConnection) {
                $SQLConnection=New-Object System.Data.SqlClient.SqlConnection($ConnectionStringPRISM)
            }
            $ConnectionStringPRISM = $null
            Write-Host $SQLConnection.State -ForegroundColor Yellow
            while (!($AZConnection)) {
                $ProgCounter++
                <# Progressbar  #>
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Please wait for connection" -PercentComplete ((10/50) * 100)
                Write-Host $SQLConnection.State -ForegroundColor Blue
                if($SQLConnection.State -eq "open"){
                    $AZConnection =$true
                    SST_ToolMessageCollector -TD_ToolMSGCollector $("SST_PRISMDBControl Func State $($SQLConnection.State)") -TD_ToolMSGType Message -TD_Shown yes
                }else {
                    try {
                        if ($SQLConnection.State -ne [System.Data.ConnectionState]::Open) {
                            $SQLConnection.Open()
                        }
                    }
                    catch {
                        <#Do this if a terminating exception happens#>
                        Write-Host "$($SQLConnection.State) - $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                    SST_ToolMessageCollector -TD_ToolMSGCollector $("SST_PRISMDBControl Func State $($SQLConnection.State)") -TD_ToolMSGType Message -TD_Shown no
                }
                <# While killer ;) #>
                if($ProgCounter -gt 20){break}
            }
            Write-Host $SQLConnection.State -ForegroundColor Red
            Close-ProgressBar -ProgressBar $ProgressBar
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "PRISM Status $($SQLConnection.Open()) Info: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
            SST_ToolMessageCollector -TD_ToolMSGCollector $("SST_PRISMDBControl Func there is a problem with the CustomerNumber") -TD_ToolMSGType Error -TD_Shown yes
        }
        
    }

    process {

        switch ($SST_InfoType) {
            "StorageBase" { 

                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){ 
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="UPDATE IBMSTOHWTable SET Name = @Name,ClusterName = @ClusterName,Status = @Status,IOgroupid = @IOgroupid,IOgroupName = @IOgroupName,CodeLevel = @CodeLevel,ConfigNode = @ConfigNode,SideID = @SideID,SideName = @SideName,ProdMTM = @ProdMTM,`
                                                    RecommendedPTF = @RecommendedPTF, MDiskTotalCapacity = @MDiskTotalCapacity, MDiskFreeCapacity = @MDiskFreeCapacity, MDiskUsedCapacity = @MDiskUsedCapacity, PhysicalTotalCapacity = @PhysicalTotalCapacity, PhysicalFreeCapacity = @PhysicalFreeCapacity,`
                                                    HostUnmap = @HostUnmap, BackendUnmap = @BackendUnmap, Topology = @Topology, Layer = @Layer, QuorumMode = @QuorumMode, TimeStamp = @TimeStamp`
                                                WHERE CustomerNbr = @CustomerNbr AND WWNN = @WWNN AND SerialNumber = @SerialNumber;
                                                IF @@ROWCOUNT = 0`
                                                BEGIN`
                                                INSERT INTO IBMSTOHWTable (CustomerNbr, Name, ClusterName, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, SideName, ProdMTM, RecommendedPTF, MDiskTotalCapacity, MDiskFreeCapacity, MDiskUsedCapacity,`
                                                    PhysicalTotalCapacity, PhysicalFreeCapacity, HostUnmap, BackendUnmap, Topology, Layer, QuorumMode, TimeStamp)`
                                                    VALUES (@CustomerNbr, @Name, @ClusterName, @WWNN, @Status, @IOgroupid, @IOgroupName, @SerialNumber, @CodeLevel, @ConfigNode, @SideID, @SideName, @ProdMTM, @RecommendedPTF, @MDiskTotalCapacity, @MDiskFreeCapacity, @MDiskUsedCapacity,`
                                                    @PhysicalTotalCapacity, @PhysicalFreeCapacity, @HostUnmap, @BackendUnmap, @Topology, @Layer, @QuorumMode, @TimeStamp);END"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.Name) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ClusterName", $SST_CollectedInformation.ClusterName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@IOgroupid", $SST_CollectedInformation.IOgroupid) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@IOgroupName", $SST_CollectedInformation.IOgroupName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.CodeLevel) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ConfigNode", $SST_CollectedInformation.ConfigNode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SideID", $SST_CollectedInformation.SideID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SideName", $SST_CollectedInformation.SideName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ProdMTM", $SST_CollectedInformation.ProdMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RecommendedPTF", (Get-SqlParameterValue -Value $SST_CollectedInformation.RecommendedPTF -Default "Not available" -TreatEmptyStringAsNull)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MDiskTotalCapacity", $SST_CollectedInformation.'MDiskTotalCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MDiskFreeCapacity", $SST_CollectedInformation.'MDiskFreeCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MDiskUsedCapacity", $SST_CollectedInformation.'MDiskUsedCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhysicalTotalCapacity", $SST_CollectedInformation.'PhysicalTotalCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhysicalFreeCapacity", $SST_CollectedInformation.'PhysicalFreeCapacity') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HostUnmap", $SST_CollectedInformation.'HostUnmap') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BackendUnmap", $SST_CollectedInformation.'BackendUnmap') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Topology", $SST_CollectedInformation.Topology) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Layer", $SST_CollectedInformation.Layer) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@QuorumMode", $SST_CollectedInformation.QuorumMode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LocalCreationTimeStamp", $SST_CollectedInformation.TimeStamp) | Out-Null  #maybe for later
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save
                        $SQLCommand.ExecuteNonQuery() | Out-Null
                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        #$SQLiteCommand.CommandText = "DELETE FROM IBMSTOHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOHWTable ORDER BY TimeStamp DESC LIMIT 128 );"
                        #$SQLiteCommand.ExecuteNonQuery() | Out-Null
                    }
                }catch{
                    Write-Host $_.Exception.Message -ForegroundColor DarkMagenta
                }
                finally {
                        
                        <#Do this after the try block regardless of whether an exception occurred or not#>
                        if ($SQLCommand) { $SQLCommand.Dispose() }
                        # If you want to delete files afterwards, extra good:
                        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "StorageDrive" { 

                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations | Where-Object { -not [string]::IsNullOrWhiteSpace($_.ProductID) }){ 

                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText ="UPDATE IBMSTODriveTable SET DriveID = @DriveID, SlotID = @SlotID, ProductID = @ProductID, DriveStatus = @DriveStatus, CurrentDriveFW = @CurrentDriveFW, DriveCap = @DriveCap, PhyDriveCap = @PhyDriveCap,`
                                                    PhyUsedDriveCap = @PhyUsedDriveCap, EffeUsedDriveCap = @EffeUsedDriveCap, TimeStamp = @TimeStamp`
                                                WHERE CustomerNbr = @CustomerNbr AND DriveID = @DriveID AND SerialNumber = @SerialNumber AND WWNN = @WWNN;`
                                                IF @@ROWCOUNT = 0`
                                                BEGIN`
                                                INSERT INTO IBMSTODriveTable (CustomerNbr, DriveID, SlotID, ProductID, DriveStatus, CurrentDriveFW, DriveCap, PhyDriveCap, PhyUsedDriveCap, EffeUsedDriveCap, SerialNumber, WWNN, TimeStamp)`
                                                VALUES (@CustomerNbr, @DriveID, @SlotID, @ProductID, @DriveStatus, @CurrentDriveFW, @DriveCap, @PhyDriveCap, @PhyUsedDriveCap, @EffeUsedDriveCap, @SerialNumber, @WWNN, @TimeStamp); END"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DriveID", $SST_CollectedInformation.DriveID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SlotID", $SST_CollectedInformation.SlotID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ProductID", $SST_CollectedInformation.ProductID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DriveStatus", $SST_CollectedInformation.DriveStatus) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CurrentDriveFW", $SST_CollectedInformation.CurrentDriveFW) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DriveCap", $SST_CollectedInformation.DriveCap) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhyDriveCap", $SST_CollectedInformation.PhyDriveCap) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhyUsedDriveCap", $SST_CollectedInformation.PhyUsedDriveCap) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@EffeUsedDriveCap", $SST_CollectedInformation.EffeUsedDriveCap) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 256 most recent entries after TimeStamp
                        #$SQLiteCommand.CommandText = "DELETE FROM IBMSTODriveTable WHERE ID NOT IN ( SELECT ID FROM IBMSTODriveTable ORDER BY TimeStamp DESC LIMIT 256 );"
                        #$SQLiteCommand.ExecuteNonQuery() | Out-Null
                        
                    }
                }
                catch {
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }               
                finally {
                        <#Do this after the try block regardless of whether an exception occurred or not#>
                        if ($SQLCommand) { $SQLCommand.Dispose() }

                        # If you want to delete files afterwards, extra good:
                        [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }
            }
            "StorageEventLog" {

                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE IBMSTOEventsTable SET LastTime = @LastTime, ObjectType = @ObjectType, ObjectID = @ObjectID, ObjectName = @ObjectName, CopyID = @CopyID, Status = @Status, Fixed = @Fixed,`
                                                                                ErrorCode = @ErrorCode, Description = @Description, TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND SeqID = @SeqID AND WWNN = @WWNN AND SerialNumber = @SerialNumber;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO IBMSTOEventsTable (CustomerNbr, SeqID, LastTime, ObjectType, ObjectID, ObjectName, CopyID, Status, Fixed, ErrorCode, Description, WWNN, SerialNumber, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @SeqID, @LastTime, @ObjectType, @ObjectID, @ObjectName, @CopyID, @Status, @Fixed, @ErrorCode, @Description, @WWNN, @SerialNumber, @TimeStamp); END"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SeqID", $SST_CollectedInformation.SeqID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LastTime", $SST_CollectedInformation.LastTime) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ObjectType", $SST_CollectedInformation.ObjectType) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ObjectID", $SST_CollectedInformation.ObjectID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ObjectName", $SST_CollectedInformation.ObjectName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CopyID", $SST_CollectedInformation.CopyID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.Status) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Fixed", $SST_CollectedInformation.Fixed) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorCode", $SST_CollectedInformation.ErrorCode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Description", $SST_CollectedInformation.Description) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 500 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM IBMSTOEventsTable WHERE ID NOT IN ( SELECT ID FROM IBMSTOEventsTable ORDER BY TimeStamp DESC LIMIT 500 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }catch{
                    Write-Host $_.Exception.Message -ForegroundColor DarkMagenta
                }finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "SANBase" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE IBMSANHWTable SET Name = @Name, Status = @Status, CodeLevel = @CodeLevel, BrocadeProdName = @BrocadeProdName, MTM = @MTM, SwitchWWNN = @SwitchWWNN, TimeStamp = @TimeStamp`
                                                                                WHERE CustomerNbr = @CustomerNbr AND SerialNumber = @SerialNumber AND SwitchWWNN = @SwitchWWNN;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO IBMSANHWTable (CustomerNbr, Name, Status, CodeLevel, BrocadeProdName, MTM, SerialNumber, SwitchWWNN, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @Name, @Status, @CodeLevel, @BrocadeProdName, @MTM, @SerialNumber, @SwitchWWNN, @TimeStamp); END"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.'Name') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.'Status') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.'CodeLevel') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BrocadeProdName", $SST_CollectedInformation.'BrocadeProdName') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.'MTM') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.'SerialNumber') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.'SwitchWWNN') | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 16 most recent entries after TimeStamp
                        # $SQLCommand.CommandText = "DELETE FROM IBMSANHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSANHWTable ORDER BY TimeStamp DESC LIMIT 16 );"
                        # $SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "PowerHMC" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()

                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE PowerHMC SET HMCName = @HMCName, HMCMTM = @HMCMTM, BIOS = @BIOS, DisplayVersion = @DisplayVersion, BaseVersion = @BaseVersion, BuildLevel = @BuildLevel,IFix = @IFix,`
                                                                                ManagedSystemCount = @ManagedSystemCount, ManagedSystemUUIDs = @ManagedSystemUUIDs,TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND SerialNumber = @SerialNumber AND HMCUUID = @HMCUUID;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO PowerHMC (CustomerNbr, HMCName, HMCMTM, SerialNumber, HMCUUID, BIOS, DisplayVersion, BaseVersion, BuildLevel, IFix,ManagedSystemCount, ManagedSystemUUIDs, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @HMCName, @HMCMTM, @SerialNumber, @HMCUUID, @BIOS, @DisplayVersion, @BaseVersion, @BuildLevel, @IFix, @ManagedSystemCount, @ManagedSystemUUIDs, @TimeStamp); END"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HMCName", $SST_CollectedInformation.HMCName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HMCMTM", $SST_CollectedInformation.HMCMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HMCUUID", $SST_CollectedInformation.HMCUUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BIOS", $SST_CollectedInformation.BIOS) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DisplayVersion", $SST_CollectedInformation.DisplayVersion) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BaseVersion", $SST_CollectedInformation.BaseVersion) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BuildLevel", $SST_CollectedInformation.BuildLevel) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@IFix", $SST_CollectedInformation.IFix) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemCount", $SST_CollectedInformation.ManagedSystemCount) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemUUIDs", $SST_CollectedInformation.ManagedSystemUUIDs) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 64 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM PowerHMC WHERE ID NOT IN ( SELECT ID FROM PowerHMC ORDER BY TimeStamp DESC LIMIT 64 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "PowerSysSummary" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()
                        
                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE PowerSysSummary SET SystemName = @SystemName, MachineTypeModel = @MachineTypeModel, State = @State, ECNumber = @ECNumber,ActivatedLevel = @ActivatedLevel, URL = @URL, TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND SerialNumber = @SerialNumber AND UUID = @UUID;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO PowerSysSummary ( CustomerNbr, SystemName, MachineTypeModel, SerialNumber, State, ECNumber, ActivatedLevel, UUID, URL, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @SystemName, @MachineTypeModel, @SerialNumber, @State, @ECNumber, @ActivatedLevel, @UUID, @URL, @TimeStamp); END"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SystemName", $SST_CollectedInformation.SystemName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MachineTypeModel", $SST_CollectedInformation.MachineTypeModel) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ECNumber", (Get-SqlParameterValue -Value $SST_CollectedInformation.ECNumber -Default "Not available" -TreatEmptyStringAsNull)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ActivatedLevel", (Get-SqlParameterValue -Value $SST_CollectedInformation.ActivatedLevel -Default "Not available" -TreatEmptyStringAsNull)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@UUID", $SST_CollectedInformation.UUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@URL", (Get-SqlParameterValue -Value $SST_CollectedInformation.URL -Default "Not available" -TreatEmptyStringAsNull)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null

                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 128 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM PowerSysSummary WHERE ID NOT IN ( SELECT ID FROM PowerSysSummary ORDER BY TimeStamp DESC LIMIT 128 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "LPARSummary" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()

                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){
                        $SQLCommand.Parameters.Clear()
                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE LPARSummary SET ManagedSystemName = @ManagedSystemName, ManagedSystemUUID = @ManagedSystemUUID, ManagedSystemMTMS = @ManagedSystemMTMS, ManagedSystemSerial = @ManagedSystemSerial, LparName = @LparName,`
                                                                                PartitionId = @PartitionId, State = @State, Environment = @Environment, OsVersion = @OsVersion, RmcIp = @RmcIp, RmcState = @RmcState, DefaultProfile = @DefaultProfile,`
                                                                                CurrentProcessingUnits = @CurrentProcessingUnits,CurrentMemoryMB = @CurrentMemoryMB, TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND ManagedSystemSerial = @ManagedSystemSerial AND LparUUID = @LparUUID;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO LPARSummary (CustomerNbr, ManagedSystemName, ManagedSystemUUID, ManagedSystemMTMS, ManagedSystemSerial, LparName, LparUUID, PartitionId, State, Environment,OsVersion,`
                                                                            RmcIp, RmcState, DefaultProfile, CurrentProcessingUnits, CurrentMemoryMB, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @ManagedSystemName, @ManagedSystemUUID, @ManagedSystemMTMS, @ManagedSystemSerial, @LparName, @LparUUID, @PartitionId, @State, @Environment, @OsVersion, @RmcIp,`
                                                                            @RmcState, @DefaultProfile, @CurrentProcessingUnits, @CurrentMemoryMB, @TimeStamp); END"
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemName", $SST_CollectedInformation.ManagedSystemName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemUUID", $SST_CollectedInformation.ManagedSystemUUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemMTMS", $SST_CollectedInformation.ManagedSystemMTMS) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ManagedSystemSerial", $SST_CollectedInformation.ManagedSystemSerial) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LparName", $SST_CollectedInformation.LparName) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LparUUID", $SST_CollectedInformation.LparUUID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PartitionId", $SST_CollectedInformation.PartitionId) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Environment", $SST_CollectedInformation.Environment) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@OsVersion", $SST_CollectedInformation.OsVersion) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RmcIp", (Get-SqlParameterValue -Value $SST_CollectedInformation.RmcIp -Default "Not available" -TreatEmptyStringAsNull)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RmcState", (Get-SqlParameterValue -Value $SST_CollectedInformation.RmcState -Default "Not available" -TreatEmptyStringAsNull)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@DefaultProfile", (Get-SqlParameterValue -Value $SST_CollectedInformation.DefaultProfile -Default "Not available" -TreatEmptyStringAsNull)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CurrentProcessingUnits", $SST_CollectedInformation.CurrentProcessingUnits) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CurrentMemoryMB", $SST_CollectedInformation.CurrentMemoryMB) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 1024 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "LibraryBaseInfo" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()
                    
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){

                        $SQLCommand.Parameters.Clear()
                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE LibraryBaseInfo SET Name = @Name, Status = @Status, Vendor = @Vendor, ProductID = @ProductID, BaseFWRevision = @BaseFWRevision, SerialNumber = @SerialNumber, MTM = @MTM,`
                                                                                TotalCartridges = @TotalCartridges, AssignedCartridges = @AssignedCartridges, TotalCapacity = @TotalCapacity, LicensedCapacity = @LicensedCapacity, BaseFWBuildDate = @BaseFWBuildDate,`
                                                                                ExpansionFWRevision = @ExpansionFWRevision, WWNN = @WWNN, RoboticHWRevision = @RoboticHWRevision, RoboticFWRevision = @RoboticFWRevision, RoboticSerialNumber = @RoboticSerialNumber,`
                                                                                NoOfModules = @NoOfModules, LibraryType = @LibraryType, SecureCommunications = @SecureCommunications, SerialNumberMTM = @SerialNumberMTM, TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND SerialNumberMTM = @SerialNumberMTM;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO LibraryBaseInfo (CustomerNbr, Name, Status, Vendor, ProductID, BaseFWRevision, SerialNumber, MTM, TotalCartridges, AssignedCartridges, TotalCapacity, LicensedCapacity,`
                                                                                BaseFWBuildDate, ExpansionFWRevision, WWNN, RoboticHWRevision, RoboticFWRevision, RoboticSerialNumber, NoOfModules, LibraryType, SecureCommunications, SerialNumberMTM, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @Name, @Status, @Vendor, @ProductID, @BaseFWRevision, @SerialNumber, @MTM, @TotalCartridges, @AssignedCartridges, @TotalCapacity, @LicensedCapacity,`
                                                                                @BaseFWBuildDate, @ExpansionFWRevision, @WWNN, @RoboticHWRevision, @RoboticFWRevision, @RoboticSerialNumber, @NoOfModules, @LibraryType, @SecureCommunications, @SerialNumberMTM, @TimeStamp); END"

                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Name", (Get-DbValue $SST_CollectedInformation.Name)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.status) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Vendor", $SST_CollectedInformation.Vendor) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ProductID", $SST_CollectedInformation.ProductID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BaseFWRevision", $SST_CollectedInformation.BaseFWRevision) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.MTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TotalCartridges", $SST_CollectedInformation.TotalCartridges) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@AssignedCartridges", $SST_CollectedInformation.AssignedCartridges) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TotalCapacity", $SST_CollectedInformation.TotalCapacity) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LicensedCapacity", $SST_CollectedInformation.LicensedCapacity) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@BaseFWBuildDate", $SST_CollectedInformation.BaseFWBuildDate) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ExpansionFWRevision", $SST_CollectedInformation.ExpansionFWRevision) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RoboticHWRevision", $SST_CollectedInformation.RoboticHWRevision) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RoboticFWRevision", $SST_CollectedInformation.RoboticFWRevision) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@RoboticSerialNumber", $SST_CollectedInformation.RoboticSerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@NoOfModules", $SST_CollectedInformation.NoOfModules) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LibraryType", $SST_CollectedInformation.LibraryType) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SecureCommunications", $SST_CollectedInformation.SecureCommunications) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_CollectedInformation.SerialNumberMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 1024 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "LibraryDrive" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()
                    
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){

                        $SQLCommand.Parameters.Clear()
                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE LibraryDrive SET Location = @Location, SerialNumber = @SerialNumber, MFGSerialNumber = @MFGSerialNumber, MediaType = @MediaType, State = @State, MTM = @MTM, Interface = @Interface,`
                                                                                LogicalLibrary = @LogicalLibrary, LogicalLibraryID = @LogicalLibraryID, Usage = @Usage, Firmware = @Firmware, Encryption = @Encryption,Mounts = @Mounts, Barcode = @Barcode, WWNN = @WWNN,`
                                                                                ElementAddress = @ElementAddress, LogicalNumber = @LogicalNumber,PhysicalNumber = @PhysicalNumber, Module = @Module, Generation = @Generation, Cartridge = @Cartridge,`
                                                                                Vendor = @Vendor, ErrorState = @ErrorState, Power = @Power, Presence = @Presence, ADTMode = @ADTMode, SerialNumberMTM = @SerialNumberMTM, TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND SerialNumberMTM = @SerialNumberMTM AND SerialNumber = @SerialNumber;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO LibraryDrive (CustomerNbr, Location, SerialNumber, MFGSerialNumber, MediaType, State, MTM, Interface, LogicalLibrary, LogicalLibraryID, Usage, Firmware, Encryption, Mounts, Barcode, WWNN,`
                                                                                ElementAddress, LogicalNumber, PhysicalNumber, Module, Generation, Cartridge, Vendor, ErrorState, Power, Presence, ADTMode, SerialNumberMTM, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @Location, @SerialNumber, @MFGSerialNumber, @MediaType, @State, @MTM, @Interface, @LogicalLibrary, @LogicalLibraryID, @Usage, @Firmware, @Encryption, @Mounts, @Barcode, @WWNN,`
                                                                                @ElementAddress, @LogicalNumber, @PhysicalNumber, @Module, @Generation, @Cartridge, @Vendor, @ErrorState, @Power, @Presence, @ADTMode, @SerialNumberMTM, @TimeStamp); END"
                        <# if there is a $null error use the helper func (Get-DbValue $SST_CollectedInformation.<value>)#>
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Location", (Get-DbValue $SST_CollectedInformation.Location)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MFGSerialNumber", $SST_CollectedInformation.MFGSerialNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MediaType", $SST_CollectedInformation.MediaType) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.MTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Interface", $SST_CollectedInformation.Interface) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LogicalLibrary", $SST_CollectedInformation.LogicalLibrary) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LogicalLibraryID", $SST_CollectedInformation.LogicalLibraryID) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Usage", $SST_CollectedInformation.USE) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Firmware", $SST_CollectedInformation.Firmware) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Encryption", $SST_CollectedInformation.Encryption) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Mounts", $SST_CollectedInformation.Mounts) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Barcode", $SST_CollectedInformation.Barcode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@WWNN", $SST_CollectedInformation.WWNN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ElementAddress", $SST_CollectedInformation.ElementAddress) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LogicalNumber", $SST_CollectedInformation.LogicalNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@PhysicalNumber", $SST_CollectedInformation.PhysicalNumber) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Module", $SST_CollectedInformation.Module) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Generation", $SST_CollectedInformation.Generation) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Cartridge", $SST_CollectedInformation.Cartridge) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Vendor", $SST_CollectedInformation.Vendor) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorState", $SST_CollectedInformation.ErrorState) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Power", $SST_CollectedInformation.Power) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Presence", $SST_CollectedInformation.Presence) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ADTMode", $SST_CollectedInformation.ADTMode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_CollectedInformation.SerialNumberMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 1024 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "LibraryEvents" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()
                    
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){

                        $SQLCommand.Parameters.Clear()
                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE LibraryEvents SET LibID = @LibID, Severity = @Severity, Type = @Type, Location = @Location, Description = @Description, ErrorCode = @ErrorCode, EventTime = @EventTime,`
                                                                                SerialNumberMTM = @SerialNumberMTM, TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND SerialNumberMTM = @SerialNumberMTM AND LibID = @LibID;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO LibraryEvents (CustomerNbr, LibID, Severity, Type, Location, Description, ErrorCode, EventTime, SerialNumberMTM, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @LibID, @Severity, @Type, @Location, @Description, @ErrorCode, @EventTime, @SerialNumberMTM, @TimeStamp); END"
                        <# if there is a $null error use the helper func (Get-DbValue $SST_CollectedInformation.<value>)#>
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LibID", (Get-DbValue $SST_CollectedInformation.LibID)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Severity", $SST_CollectedInformation.Severity) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Type", $SST_CollectedInformation.Type) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Location", (Get-DbValue $SST_CollectedInformation.Location)) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Description", $SST_CollectedInformation.Description) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorCode", $SST_CollectedInformation.ErrorCode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@EventTime", $SST_CollectedInformation.EventTime) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_CollectedInformation.SerialNumberMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 1024 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            "LibraryReports" {
                try {
                    $SQLCommand = $SQLConnection.CreateCommand()
                    
                    foreach ($SST_CollectedInformation in $SST_CollectedInformations){

                        $SQLCommand.Parameters.Clear()
                        $SQLCommand.CommandText =$SQLCommand.CommandText = "UPDATE LibraryReports SET Barcode = @Barcode, LogicalLibrary = @LogicalLibrary, Location = @Location, MountTime = @MountTime, UnmountTime = @UnmountTime, HostIOReads = @HostIOReads, HostIOWrites = @HostIOWrites,`
                                                                                CompressionRate = @CompressionRate, ErrorsCorrectedWrites = @ErrorsCorrectedWrites, ErrorsUncorrectedWrites = @ErrorsUncorrectedWrites, ErrorsCorrectedReads = @ErrorsCorrectedReads, ErrorsUncorrectedReads = @ErrorsUncorrectedReads,`
                                                                                SerialNumberMTM = @SerialNumberMTM, TimeStamp = @TimeStamp`
                                                                            WHERE CustomerNbr = @CustomerNbr AND SerialNumberMTM = @SerialNumberMTM AND Barcode = @Barcode;`
                                                                            IF @@ROWCOUNT = 0`
                                                                            BEGIN`
                                                                            INSERT INTO LibraryReports (CustomerNbr, Barcode, LogicalLibrary, Location, MountTime, UnmountTime, HostIOReads, HostIOWrites, CompressionRate, ErrorsCorrectedWrites, ErrorsUncorrectedWrites, ErrorsCorrectedReads, ErrorsUncorrectedReads, SerialNumberMTM, TimeStamp)`
                                                                            VALUES (@CustomerNbr, @Barcode, @LogicalLibrary, @Location, @MountTime, @UnmountTime, @HostIOReads, @HostIOWrites, @CompressionRate, @ErrorsCorrectedWrites, @ErrorsUncorrectedWrites, @ErrorsCorrectedReads, @ErrorsUncorrectedReads, @SerialNumberMTM, @TimeStamp); END"
                        <# if there is a $null error use the helper func (Get-DbValue $SST_CollectedInformation.<value>)#>
                        $SQLCommand.Parameters.AddWithValue("@CustomerNbr", $AZCredN) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Barcode", $SST_CollectedInformation.Barcode) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@LogicalLibrary", $SST_CollectedInformation.LogicalLibrary) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@Location", $SST_CollectedInformation.Location) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@MountTime", $SST_CollectedInformation.MountTime) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@UnmountTime", $SST_CollectedInformation.UnmountTime) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HostIOReads", $SST_CollectedInformation.HostIOReads) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@HostIOWrites", $SST_CollectedInformation.HostIOWrites) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@CompressionRate", $SST_CollectedInformation.CompressionRate) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorsCorrectedWrites", $SST_CollectedInformation.ErrorsCorrectedWrites) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorsUncorrectedWrites", $SST_CollectedInformation.ErrorsUncorrectedWrites) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorsCorrectedReads", $SST_CollectedInformation.ErrorsCorrectedReads) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@ErrorsUncorrectedReads", $SST_CollectedInformation.ErrorsUncorrectedReads) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@SerialNumberMTM", $SST_CollectedInformation.SerialNumberMTM) | Out-Null
                        $SQLCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 1024 most recent entries after TimeStamp
                        #$SQLCommand.CommandText = "DELETE FROM LPARSummary WHERE ID NOT IN ( SELECT ID FROM LPARSummary ORDER BY TimeStamp DESC LIMIT 1024 );"
                        #$SQLCommand.ExecuteNonQuery()
                    }
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host "SQL Fehler: $($_.Exception.Message)"
                    Write-Host $_.Exception.ToString()
                }
                finally {
                    <#Do this after the try block regardless of whether an exception occurred or not#>
                    if ($SQLCommand) { $SQLCommand.Dispose() }

                    # If you want to delete files afterwards, extra good:
                    [System.Data.SqlClient.SqlConnection]::ClearAllPools()
                }

            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong during saving the $SST_InfoType data in the local db.") -TD_ToolMSGType Error -TD_Shown yes
                Write-Host $_.Exception.Message -ForegroundColor DarkMagenta
                if ($SQLConnection) { 
                    if ($SQLConnection.State -ne [System.Data.ConnectionState]::Closed) {
                        $SQLConnection.Close()
                    } 
                    $SQLConnection.Dispose() 
                }
            }
        }

    }
    
    end {
        if ($SQLCommand) { $SQLCommand.Dispose() }
        if ($SQLConnection) { 
            if ($SQLConnection.State -ne [System.Data.ConnectionState]::Closed) {
                $SQLConnection.Close()
                Write-Host $SQLConnection.State -ForegroundColor Blue
            } 
            $SQLConnection.Dispose() 
        }
    }
}