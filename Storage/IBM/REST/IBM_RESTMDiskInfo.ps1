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
                $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            }
        }
        if([string]::IsNullOrWhiteSpace($TD_Device_ConnectionTyp)){
            $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW 
        }
        Clear-Variable -Name TD_Device_PW -Force
        if($TD_Device_ConnectionTyp -eq "REST"){
            $TD_DeviceInformation = @(SST_SpectrumSystemAPI -Endpoint lsmdiskgrp -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo)
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

    process{
        [int]$imax = $TD_DeviceInformation.Count
        $TD_MDiskInfoResault = for ($i = 0; $i -lt $imax; $i++) {
            $item = $TD_DeviceInformation[$i]
            if ($null -eq $item) { continue }
            <# Node Info#>
            $TD_MDiskInfo = "" | Select-Object RowID,ID,Name,Status,MDiskCount,VdiskCount,Capacity,ExtentSize,FreeCapacity,VirtualCapacity,UsedCapacity,RealCapacity,`
                                            Overallocation,Warning,EasyTier,EasyTierStatus,CompressionActive,CompressionVirtualCapacity,CompressionCompressedCapacity,CompressionUncompressedCapacity,ParentMdiskGrpID,ParentMdiskGrpName,ChildMdiskGrpCount,`
                                            ChildMdiskGrpCapacity,Type,Encrypt,OwnerType,OwnerID,OwnerName,SiteID,SiteName,DataReduction,UsedCapacityBeforeReduction,UsedCapacityAfterReduction,`
                                            OverheadCapacity,DeduplicationCapacitySaving,ReclaimableCapacity,EasyTierFCMOverAllocationMax,ProvisioningPolicyID,ProvisioningPolicyName,ReplicationPoolLinkUID,WWNN,SerialNumber
            #   ID,Name,Status,DdiskCount,VdiskCount,Capacity,ExtentSize,FreeCapacity,VirtualCapacity,UsedCapacity,RealCapacity     
            $TD_MDiskInfo.ID                              = $item.id
            $TD_MDiskInfo.Name                            = $item.name
            $TD_MDiskInfo.Status                          = $item.status
            $TD_MDiskInfo.MDiskCount                      = $item.mdisk_count
            $TD_MDiskInfo.VdiskCount                      = $item.vdisk_count
            $TD_MDiskInfo.Capacity                        = $item.capacity
            $TD_MDiskInfo.ExtentSize                      = $item.extent_size
            $TD_MDiskInfo.FreeCapacity                    = $item.free_capacity
            $TD_MDiskInfo.VirtualCapacity                 = $item.virtual_capacity
            $TD_MDiskInfo.UsedCapacity                    = $item.used_capacity
            $TD_MDiskInfo.RealCapacity                    = $item.real_capacity
            #   Overallocation, Warning, EasyTier, EasyTierStatus, CompressionActive, CompressionVirtualCapacity, CompressionCompressedCapacity, CompressionUncompressedCapacity, ParentMdiskGrpID, ParentMdiskGrpName, ChildMdiskGrpCount              
            $TD_MDiskInfo.Overallocation                  = $item.overallocation
            $TD_MDiskInfo.Warning                         = $item.warning
            $TD_MDiskInfo.EasyTier                        = $item.easy_tier
            $TD_MDiskInfo.EasyTierStatus                  = $item.easy_tier_status
            $TD_MDiskInfo.CompressionActive               = $item.compression_active
            $TD_MDiskInfo.CompressionVirtualCapacity      = $item.compression_virtual_capacity
            $TD_MDiskInfo.CompressionCompressedCapacity   = $item.compression_compressed_capacity
            $TD_MDiskInfo.CompressionUncompressedCapacity = $item.compression_uncompressed_capacity
            $TD_MDiskInfo.ParentMdiskGrpID                = $item.parent_mdisk_grp_id
            $TD_MDiskInfo.ParentMdiskGrpName              = $item.parent_mdisk_grp_name
            $TD_MDiskInfo.ChildMdiskGrpCount              = $item.child_mdisk_grp_count
            #   ChildMdiskGrpCapacity, Type, Encrypt, OwnerType, OwnerID, OwnerName, SiteID, SiteName, DataReduction, UsedCapacityBeforeReduction, UsedCapacityAfterReduction  
            $TD_MDiskInfo.ChildMdiskGrpCapacity           = $item.child_mdisk_grp_capacity
            $TD_MDiskInfo.Type                            = $item.type
            $TD_MDiskInfo.Encrypt                         = $item.encrypt
            $TD_MDiskInfo.OwnerType                       = $item.owner_type
            $TD_MDiskInfo.OwnerID                         = $item.owner_id
            $TD_MDiskInfo.OwnerName                       = $item.owner_name
            $TD_MDiskInfo.SiteID                          = $item.site_id
            $TD_MDiskInfo.SiteName                        = $item.site_name
            $TD_MDiskInfo.DataReduction                   = $item.data_reduction
            $TD_MDiskInfo.UsedCapacityBeforeReduction     = $item.used_capacity_before_reduction
            $TD_MDiskInfo.UsedCapacityAfterReduction      = $item.used_capacity_after_reduction
            #   OverheadCapacity, DeduplicationCapacitySaving, ReclaimableCapacity, EasyTierFCMOverAllocationMax, ProvisioningPolicyID,ProvisioningPolicyName,ReplicationPoolLinkUID      
            $TD_MDiskInfo.OverheadCapacity                = $item.overhead_capacity
            $TD_MDiskInfo.DeduplicationCapacitySaving     = $item.deduplication_capacity_saving
            $TD_MDiskInfo.ReclaimableCapacity             = $item.reclaimable_capacity
            $TD_MDiskInfo.EasyTierFCMOverAllocationMax    = $item.easy_tier_fcm_over_allocation_max
            $TD_MDiskInfo.ProvisioningPolicyID            = $item.provisioning_policy_id
            $TD_MDiskInfo.ProvisioningPolicyName          = $item.provisioning_policy_name
            $TD_MDiskInfo.ReplicationPoolLinkUID          = $item.replication_pool_link_uid

            $TD_MDiskInfo.WWNN          = $IBMSTOWWNN
            $TD_MDiskInfo.SerialNumber  = $IBMSTOSN
            $TD_MDiskInfo.RowID         = "$IBMSTOSN|$($TD_MDiskInfo.ID)"

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