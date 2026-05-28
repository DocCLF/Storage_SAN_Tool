function SST_CustomerSANDBInsertTable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateSet("SANBase","SANPortInfo")]
        [string]$SST_InfoType,
        $SST_NewDBObject =$null,
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
                        $SQLiteCommand.Parameters.AddWithValue("@Name", $SST_CollectedInformation.'SwichtName') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Status", $SST_CollectedInformation.'SwitchState') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@CodeLevel", $SST_CollectedInformation.'FabricOS') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@BrocadeProdName", $SST_CollectedInformation.'BrocadeProductName') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@MTM", $SST_CollectedInformation.'MTM') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.'SerialNumber') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.'SwitchWWNN') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VFID", $SST_CollectedInformation.'VFID') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VFenabled", $SST_CollectedInformation.'VFenabled') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@VFsupported", $SST_CollectedInformation.'VFsupported') | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null

                        # Delete | Keep only the 16 most recent entries after TimeStamp
                        $SQLiteCommand.CommandText = "DELETE FROM IBMSANHWTable WHERE ID NOT IN ( SELECT ID FROM IBMSANHWTable ORDER BY TimeStamp DESC LIMIT 16 );"
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

                        $SQLiteCommand.CommandText ="INSERT INTO IBMSANPortInfoTable (CustomerNbr, Port, State, Speed, PortConnect, SerialNumber, SwitchWWNN, TimeStamp) VALUES (@CustomerNbr, @Port, @State, @Speed, @PortConnect, @SerialNumber, @SwitchWWNN, @TimeStamp);"
                        $SQLiteCommand.Parameters.AddWithValue("@CustomerNbr", $Customer) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Port", $SST_CollectedInformation.Port) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@State", $SST_CollectedInformation.State) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@Speed", $SST_CollectedInformation.Speed) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@PortConnect", $SST_CollectedInformation.PortConnect) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SerialNumber", $SST_CollectedInformation.SerialNumber) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@SwitchWWNN", $SST_CollectedInformation.SwitchWWNN) | Out-Null
                        $SQLiteCommand.Parameters.AddWithValue("@TimeStamp", $TimeStamp) | Out-Null
                    
                        # DB save 
                        $SQLiteCommand.ExecuteNonQuery() | Out-Null
 
                        # Then automatically clean up for this exact switch
                        $SQLiteCommand.CommandText ="DELETE FROM IBMSANPortInfoTable WHERE ID NOT IN (SELECT ID FROM (SELECT ID FROM IBMSANPortInfoTable AS t WHERE (SELECT COUNT(*) FROM IBMSANPortInfoTable AS x WHERE x.SwitchWWNN = t.SwitchWWNN AND x.Port = t.Port AND datetime(x.TimeStamp) >= datetime(t.TimeStamp) ) <= 1 ));" 
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
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector $("Something went wrong during saving the $SST_InfoType data in the local db.") -TD_ToolMSGType Error -TD_Shown yes}
        }

    }
    
    end {

    }
}