function SST_DashBoardSTO {
[CmdletBinding()]
 param (
        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter(Mandatory)]
        $SQLConnection,

        $Events
    )
    $DashBoardSTODeviceView = [System.Collections.Generic.List[object]]::new()
    $DeviceCounter = 0
    
    try {
        $SQLConnection.Open()
        $SQLiteCommand = $SQLConnection.CreateCommand()
        $SQLiteCommand.CommandText = $Query

        $SST_SQLiteDBReader = $SQLiteCommand.ExecuteReader()
        #ID, Name, WWNN, Status, IOgroupid, IOgroupName, SerialNumber, CodeLevel, ConfigNode, SideID, ProdMTM, TimeStamp
        # need a workaround if PB is used
        while ($SST_SQLiteDBReader.Read()) {
            $DeviceCounter++

            $DashBoardSTOsObj = [PSCustomObject]@{
                Name  = $SST_SQLiteDBReader["Name"]
                Status  = $SST_SQLiteDBReader["Status"]
                ClusterName = $SST_SQLiteDBReader["ClusterName"]
                SerialNumber = $SST_SQLiteDBReader["SerialNumber"]
                CodeLevel = $SST_SQLiteDBReader["CodeLevel"] -replace '\s+\(.*\)',''
                ProdMTM  = $SST_SQLiteDBReader["ProdMTM"]
                MDiskTC = $SST_SQLiteDBReader["MDiskTotalCapacity"]
                MDiskTCfPGB = $SST_SQLiteDBReader["MDiskTotalCapacity"] -replace '(MB|TB|PB)',''
                MDiskUC = $SST_SQLiteDBReader["MDiskUsedCapacity"] -replace '(MB|TB|PB)',''
                TimeStamp    = $SST_SQLiteDBReader["TimeStamp"]
            }
            $DashBoardSTODeviceView.Add($DashBoardSTOsObj)
        }
        # Merge Devices to Events Function found in HelperFunction.ps1
        $eventMergeResult = Add-EventInfoToDevices -Devices $DashBoardSTODeviceView -Events $Events
        # split the pscustomobject
        $DashBoardSTODeviceView = $eventMergeResult.Devices
        $OrphanEvents = $eventMergeResult.OrphanEvents

        # Normally, the following section is used only by the SVC cluster
        # Hashtable for grouping OrphanEvents by ObjectName (e.g., ClusterName)
        # Goal: faster access instead of duplicate loops later on
        $orphanInfoByObjectName = @{}

        # Iterate through all OrphanEvents (events without a direct device match)
        foreach ($orphanEvent in $OrphanEvents) {
            # If no ObjectName exists → skip
            # (so we can map it properly later)
            if ([string]::IsNullOrWhiteSpace($orphanEvent.ObjectName)) {
                continue
            }
            # If no entry exists for this ObjectName → create a new one
            if (-not $orphanInfoByObjectName.ContainsKey($orphanEvent.ObjectName)) {
                # For each ObjectName, we store:
                # - Count (number of events)
                # - Descriptions (list of descriptions)
                $orphanInfoByObjectName[$orphanEvent.ObjectName] = [PSCustomObject]@{
                    Count        = 0
                    Descriptions = [System.Collections.Generic.List[string]]::new()
                }
            }
            # Increment the event counter for this ObjectName
            $orphanInfoByObjectName[$orphanEvent.ObjectName].Count++
            # Add description, if available
            if (-not [string]::IsNullOrWhiteSpace($orphanEvent.Description)) {
                $orphanInfoByObjectName[$orphanEvent.ObjectName].Descriptions.Add($orphanEvent.Description)
            }
        }

        # Now let's go through all the devices and enrich them with OrphanEvents
        foreach ($STODevice in $DashBoardSTODeviceView) {
            # ClusterName serves as the matching criterion here
            $STOClusterName = $STODevice.ClusterName
            # If no ClusterName is available → skip
            if ([string]::IsNullOrWhiteSpace($STOClusterName)) {
                continue
            }
            # Check whether there are any OrphanEvents for this cluster at all
            if ($orphanInfoByObjectName.ContainsKey($STOClusterName)) {
                # Get related event information
                $orphanInfo = $orphanInfoByObjectName[$STOClusterName]

                # Add event count to existing device
                # (Important: cast first if null or a string)
                $STODevice.Events = [int]$STODevice.Events + $orphanInfo.Count

                # Retrieve existing descriptions from the device
                # (e.g., from a previous serial number match)
                $existingDescriptions = @()
                if (-not [string]::IsNullOrWhiteSpace($STODevice.EventDescriptionsText)) {
                    # Split by line break → convert back to a list
                    $existingDescriptions = $STODevice.EventDescriptionsText -split "`n"
                }
                # Merge new and existing descriptions
                $allDescriptions = @(
                    $existingDescriptions       # Old descriptions
                    $orphanInfo.Descriptions    # News from OrphanEvents
                ) | 
                Where-Object { 
                    # Remove empty entries
                    -not [string]::IsNullOrWhiteSpace($_) 
                } | 
                Select-Object -Unique   # Remove duplicates

                # Reconstruct as a string (for GUI / tooltip)
                $STODevice.EventDescriptionsText = $allDescriptions -join "`n"
            }
        }
        $TD_IC_DashBoardSTODevice.ItemsSource = $DashBoardSTODeviceView
        $TD_TB_STODEVCount.Text = $DeviceCounter
    }
    catch {
        <#Do this if a terminating exception happens#>
        Write-Host $_.Exception.Message -ForegroundColor Red
        
    }finally{
        if ($SST_SQLiteDBReader) { $SST_SQLiteDBReader.Close() }
        if ($SQLiteCommand) { $SQLiteCommand.Dispose() }
        if ($SQLConnection.State -eq 'Open') { $SQLConnection.Close() }
        #$DashBoardSTODeviceView = $null
        #$SQLConnection.Dispose()
    }
}