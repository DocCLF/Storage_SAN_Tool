function IBM_RESTPartitionInfos {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        #[string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        $body = @{} <# This is the only part you are allowed to change. #>
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        $BaseUrl = "https://$TD_Device_DeviceIP"+":7443"
        if(Test-Path -Path "$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db"){
            $RESTInfo = SST_RESTDBControl -SST_InfoType "UseStorageToken" -SST_BaseUrl $BaseUrl
            if(([string]::IsNullOrEmpty($RESTInfo)) -and ($TD_Device_ConnectionTyp -eq "REST")){
                SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            }
        }
        if([string]::IsNullOrWhiteSpace($TD_Device_ConnectionTyp)){
            $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW 
        }
        Clear-Variable -Name TD_Device_PW -Force
        if($TD_Device_ConnectionTyp -eq "REST"){
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lspartition -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
        [int]$imax = $STONodeInfo.Count
        for ($i = 0; $i -lt $imax; $i++) {
            if($STONodeInfo.config_node[$i] -eq "yes"){
                $IBMSTOWWNN = $STONodeInfo.WWNN[$i]
                $IBMSTOSN = if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}
            }
        }
    }
    
    process {
        $Partitions = @($TD_DeviceInformation)

        [int]$imax = $Partitions.Count
        [int]$ProgCounter = 0

        $TD_PartitionResult = foreach ($Partition in $Partitions) {
        
            [PSCustomObject][ordered]@{
                RowID                           = "$IBMSTOSN|PARTITION|$($Partition.id)"
                ID                              = $Partition.id
                Name                            = $Partition.name
                UUID                            = $Partition.uuid
                PreferredManagementSystemID     = $Partition.preferred_management_system_id
                PreferredManagementSystemName   = $Partition.preferred_management_system_name
                ActiveManagementSystemID        = $Partition.active_management_system_id
                ActiveManagementSystemName      = $Partition.active_management_system_name
                ReplicationPolicyID             = $Partition.replication_policy_id
                ReplicationPolicyName           = $Partition.replication_policy_name
                Location1SystemID               = $Partition.location1_system_id
                Location1SystemName             = $Partition.location1_system_name
                Location1Status                 = $Partition.location1_status
                Location2SystemID               = $Partition.location2_system_id
                Location2SystemName             = $Partition.location2_system_name
                Location2Status                 = $Partition.location2_status
                HostCount                       = [int]$Partition.host_count
                HostOfflineCount                = [int]$Partition.host_offline_count
                HostClusterCount                = [int]$Partition.host_cluster_count
                VolumeGroupCount                = [int]$Partition.volume_group_count
                VolumeGroupSynchronizedCount    = [int]$Partition.volume_group_synchronized_count
                VolumeGroupSynchronizingCount   = [int]$Partition.volume_group_synchronizing_count
                VolumeGroupStoppedCount         = [int]$Partition.volume_group_stopped_count
                DefaultVolumeGroupID            = $Partition.default_volume_group_id
                DefaultVolumeGroupName          = $Partition.default_volume_group_name
                HAStatus                        = $Partition.ha_status
                LinkStatus                      = $Partition.link_status
                MigrationStatus                 = $Partition.migration_status
                Draft                           = $Partition.draft
                DraftVolumeGroupCount           = [int]$Partition.draft_volume_group_count
                DraftHostCount                  = [int]$Partition.draft_host_count
                DraftHostClusterCount           = [int]$Partition.draft_host_cluster_count
                HostProvisionedCapacity         = $Partition.host_provisioned_capacity
                ProtectionProvisionedCapacity   = $Partition.protection_provisioned_capacity
                ProtectionWrittenCapacity       = $Partition.protection_written_capacity
                DesiredLocationSystemID         = $Partition.desired_location_system_id
                DesiredLocationSystemName       = $Partition.desired_location_system_name
                OwnershipGroupID                = $Partition.ownership_group_id
                OwnershipGroupName              = $Partition.ownership_group_name
                VolumeGroupSyncRemaining        = $Partition.volume_group_sync_remaining
                VolumeGroupSyncCompletionTime   = $Partition.volume_group_sync_estimated_completion_time
                ManagementPortsetID             = $Partition.management_portset_id
                ManagementPortsetName           = $Partition.management_portset_name
                VCenterID                       = $Partition.vcenter_id
                VCenterName                     = $Partition.vcenter_name
            
                WWNN                            = $IBMSTOWWNN
                SerialNumber                    = $IBMSTOSN
            }
        
            $ProgCounter++
        
            if ($imax -gt 0) {
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect partition data for Device $($TD_Line_ID) $IBMSTOSN" -PercentComplete (($ProgCounter / $imax) * 100)
            }
        }
    }
    
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_PartitionResult | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_PartitionResult | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_PartitionResult
        }
        
        return $TD_PartitionResult
    }
    
}