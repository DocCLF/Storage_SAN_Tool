function IBM_RESTMDiskInfo {
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsmdiskgrp -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
        [int]$imax = $STONodeInfo.Count
        for ($i = 0; $i -le $imax; $i++) {
            if($STONodeInfo.config_node[$i] -eq "yes"){
                $IBMSTOWWNN = $STONodeInfo.WWNN[$i]
                $IBMSTOSN = if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}
            }
        }
    }

    process{
        [int]$imax = $TD_DeviceInformation.Count
        [array]$TD_MDiskInfoResault = for ($i = 0; $i -le $imax; $i++) {
            <# Node Info#>
            $TD_MDiskInfo = "" | Select-Object ID,Name,Status,MDdiskCount,VdiskCount,Capacity,ExtentSize,FreeCapacity,VirtualCapacity,UsedCapacity,RealCapacity,`
                                            Overallocation,Warning,EasyTier,EasyTierStatus,CompressionActive,CompressionVirtualCapacity,CompressionCompressedCapacity,CompressionUncompressedCapacity,ParentMdiskGrpID,ParentMdiskGrpName,ChildMdiskGrpCount,`
                                            ChildMdiskGrpCapacity,Type,Encrypt,OwnerType,OwnerID,OwnerName,SiteID,SiteName,DataReduction,UsedCapacityBeforeReduction,UsedCapacityAfterReduction,`
                                            OverheadCapacity,DeduplicationCapacitySaving,ReclaimableCapacity,EasyTierFCMOverAllocationMax,ProvisioningPolicyID,ProvisioningPolicyName,ReplicationPoolLinkUID,WWNN,SerialNumber
            #   ID,Name,Status,DdiskCount,VdiskCount,Capacity,ExtentSize,FreeCapacity,VirtualCapacity,UsedCapacity,RealCapacity     
            $TD_MDiskInfo.ID                                 = $TD_DeviceInformation.id[$i]
            $TD_MDiskInfo.Name                               = $TD_DeviceInformation.name[$i]
            $TD_MDiskInfo.Status                             = $TD_DeviceInformation.status[$i]
            $TD_MDiskInfo.MDdiskCount                         = $TD_DeviceInformation.mdisk_count[$i]
            $TD_MDiskInfo.VdiskCount                         = $TD_DeviceInformation.vdisk_count[$i]
            $TD_MDiskInfo.Capacity                           = $TD_DeviceInformation.capacity[$i]
            $TD_MDiskInfo.ExtentSize                         = $TD_DeviceInformation.extent_size[$i]
            $TD_MDiskInfo.FreeCapacity                       = $TD_DeviceInformation.free_capacity[$i]
            $TD_MDiskInfo.VirtualCapacity                    = $TD_DeviceInformation.virtual_capacity[$i]
            $TD_MDiskInfo.UsedCapacity                       = $TD_DeviceInformation.used_capacity[$i]
            $TD_MDiskInfo.RealCapacity                       = $TD_DeviceInformation.real_capacity[$i]
            #   Overallocation, Warning, EasyTier, EasyTierStatus, CompressionActive, CompressionVirtualCapacity, CompressionCompressedCapacity, CompressionUncompressedCapacity, ParentMdiskGrpID, ParentMdiskGrpName, ChildMdiskGrpCount              
            $TD_MDiskInfo.Overallocation                     = $TD_DeviceInformation.overallocation[$i]
            $TD_MDiskInfo.Warning                            = $TD_DeviceInformation.warning[$i]
            $TD_MDiskInfo.EasyTier                           = $TD_DeviceInformation.easy_tier[$i]
            $TD_MDiskInfo.EasyTierStatus                     = $TD_DeviceInformation.easy_tier_status[$i]
            $TD_MDiskInfo.CompressionActive                  = $TD_DeviceInformation.compression_active[$i]
            $TD_MDiskInfo.CompressionVirtualCapacity         = $TD_DeviceInformation.compression_virtual_capacity[$i]
            $TD_MDiskInfo.CompressionCompressedCapacity      = $TD_DeviceInformation.compression_compressed_capacity[$i]
            $TD_MDiskInfo.CompressionUncompressedCapacity    = $TD_DeviceInformation.compression_uncompressed_capacity[$i]
            $TD_MDiskInfo.ParentMdiskGrpID                   = $TD_DeviceInformation.parent_mdisk_grp_id[$i]
            $TD_MDiskInfo.ParentMdiskGrpName                 = $TD_DeviceInformation.parent_mdisk_grp_name[$i]
            $TD_MDiskInfo.ChildMdiskGrpCount                 = $TD_DeviceInformation.child_mdisk_grp_count[$i]
            #   ChildMdiskGrpCapacity, Type, Encrypt, OwnerType, OwnerID, OwnerName, SiteID, SiteName, DataReduction, UsedCapacityBeforeReduction, UsedCapacityAfterReduction  
            $TD_MDiskInfo.ChildMdiskGrpCapacity              = $TD_DeviceInformation.child_mdisk_grp_capacity[$i]
            $TD_MDiskInfo.Type                               = $TD_DeviceInformation.type[$i]
            $TD_MDiskInfo.Encrypt                            = $TD_DeviceInformation.encrypt[$i]
            $TD_MDiskInfo.OwnerType                          = $TD_DeviceInformation.owner_type[$i]
            $TD_MDiskInfo.OwnerID                            = $TD_DeviceInformation.owner_id[$i]
            $TD_MDiskInfo.OwnerName                          = $TD_DeviceInformation.owner_name[$i]
            $TD_MDiskInfo.SiteID                             = $TD_DeviceInformation.site_id[$i]
            $TD_MDiskInfo.SiteName                           = $TD_DeviceInformation.site_name[$i]
            $TD_MDiskInfo.DataReduction                      = $TD_DeviceInformation.data_reduction[$i]
            $TD_MDiskInfo.UsedCapacityBeforeReduction        = $TD_DeviceInformation.used_capacity_before_reduction[$i]
            $TD_MDiskInfo.UsedCapacityAfterReduction         = $TD_DeviceInformation.used_capacity_after_reduction[$i]
            #   OverheadCapacity, DeduplicationCapacitySaving, ReclaimableCapacity, EasyTierFCMOverAllocationMax, ProvisioningPolicyID,ProvisioningPolicyName,ReplicationPoolLinkUID      
            $TD_MDiskInfo.OverheadCapacity                   = $TD_DeviceInformation.overhead_capacity[$i]
            $TD_MDiskInfo.DeduplicationCapacitySaving        = $TD_DeviceInformation.deduplication_capacity_saving[$i]
            $TD_MDiskInfo.ReclaimableCapacity                = $TD_DeviceInformation.reclaimable_capacity[$i]
            $TD_MDiskInfo.EasyTierFCMOverAllocationMax       = $TD_DeviceInformation.easy_tier_fcm_over_allocation_max[$i]
            $TD_MDiskInfo.ProvisioningPolicyID               = $TD_DeviceInformation.provisioning_policy_id[$i]
            $TD_MDiskInfo.ProvisioningPolicyName             = $TD_DeviceInformation.provisioning_policy_name[$i]
            $TD_MDiskInfo.ReplicationPoolLinkUID             = $TD_DeviceInformation.replication_pool_link_uid[$i]

            $TD_MDiskInfo.WWNN = $IBMSTOWWNN
            $TD_MDiskInfo.SerialNumber = $IBMSTOSN

            $TD_MDiskInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_MDiskInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_MDiskInfoResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Mdisk_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_MDiskInfoResault
        }
        return $TD_MDiskInfoResault
    }
}