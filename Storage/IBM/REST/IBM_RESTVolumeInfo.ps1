function IBM_RESTVolumeInfo {
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsvdisk -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
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
        $TD_VDiskFuncResault = for ($i = 0; $i -lt $imax; $i++) {
            <# Node Info#>
            $TD_VDiskinfo = "" | Select-Object RowID,ID,Name,IOGroupID,IOGroupName,Status,MdiskGrpID,MdiskGrpName,Capacity,Type,FCID,FCName,`
                                            RCID,RCName,VdiskUID,FCMapCount,CopyCount,FastWriteState,SECopyCount,RCChange,CompressedCopyCount,ParentMdiskGrpID,ParentMdiskGrpName,`
                                            OwnerID,OwnerName,Formatting,Encrypt,VolumeID,VolumeName,Function,VolumeGroupID,VolumeGroupName,Protocol,PreferredNodeID,PreferredNodeName,isSnapshot,`
                                            SnapshotCount,VolumeType,ReplicationMode,isSafeguardedSnapshot,SafeguardedSnapshotCount,WWNN,SerialNumber

            $TD_VDiskinfo.ID                         = $TD_DeviceInformation.id[$i]
            $TD_VDiskinfo.Name                       = $TD_DeviceInformation.name[$i]
            $TD_VDiskinfo.IOGroupID                  = $TD_DeviceInformation.IO_group_id[$i]
            $TD_VDiskinfo.IOGroupName                = $TD_DeviceInformation.IO_group_name[$i]
            $TD_VDiskinfo.Status                     = $TD_DeviceInformation.status[$i]
            $TD_VDiskinfo.MdiskGrpID                 = $TD_DeviceInformation.mdisk_grp_id[$i]
            $TD_VDiskinfo.MdiskGrpName               = $TD_DeviceInformation.mdisk_grp_name[$i]
            $TD_VDiskinfo.Capacity                   = $TD_DeviceInformation.capacity[$i]
            $TD_VDiskinfo.Type                       = $TD_DeviceInformation.type[$i]
            $TD_VDiskinfo.FCID                       = $TD_DeviceInformation.FC_id[$i]
            $TD_VDiskinfo.FCName                     = $TD_DeviceInformation.FC_name[$i]
            #   RCID,RCName,VdiskUID,FCMapCount,CopyCount,FastWriteState,SECopyCount,RCChange,CompressedCopyCount,ParentMdiskGrpID,ParentMdiskGrpName,`
            $TD_VDiskinfo.RCID                       = $TD_DeviceInformation.RC_id[$i]
            $TD_VDiskinfo.RCName                     = $TD_DeviceInformation.RC_name[$i]
            $TD_VDiskinfo.VdiskUID                   = $TD_DeviceInformation.vdisk_UID[$i]
            $TD_VDiskinfo.FCMapCount                 = $TD_DeviceInformation.fc_map_count[$i]
            $TD_VDiskinfo.CopyCount                  = $TD_DeviceInformation.copy_count[$i]
            $TD_VDiskinfo.FastWriteState             = $TD_DeviceInformation.fast_write_state[$i]
            $TD_VDiskinfo.SECopyCount                = $TD_DeviceInformation.se_copy_count[$i]
            $TD_VDiskinfo.RCChange                   = $TD_DeviceInformation.RC_change[$i]
            $TD_VDiskinfo.CompressedCopyCount        = $TD_DeviceInformation.compressed_copy_count[$i]
            $TD_VDiskinfo.ParentMdiskGrpID           = $TD_DeviceInformation.parent_mdisk_grp_id[$i]
            $TD_VDiskinfo.ParentMdiskGrpName         = $TD_DeviceInformation.parent_mdisk_grp_name[$i]
            #   OwnerID,OwnerName,Formatting,Encrypt,VolumeID,VolumeName,Function,VolumeGroupID,VolumeGroupName,Protocol,isSnapshot,`
            $TD_VDiskinfo.OwnerID                    = $TD_DeviceInformation.owner_id[$i]
            $TD_VDiskinfo.OwnerName                  = $TD_DeviceInformation.owner_name[$i]
            $TD_VDiskinfo.Formatting                 = $TD_DeviceInformation.formatting[$i]
            $TD_VDiskinfo.Encrypt                    = $TD_DeviceInformation.encrypt[$i]
            $TD_VDiskinfo.VolumeID                   = $TD_DeviceInformation.volume_id[$i]
            $TD_VDiskinfo.VolumeName                 = $TD_DeviceInformation.volume_name[$i]
            $TD_VDiskinfo.Function                   = $TD_DeviceInformation.function[$i]
            $TD_VDiskinfo.VolumeGroupID              = $TD_DeviceInformation.volume_group_id[$i]
            $TD_VDiskinfo.VolumeGroupName            = $TD_DeviceInformation.volume_group_name[$i]
            $TD_VDiskinfo.Protocol                   = $TD_DeviceInformation.protocol[$i]
            $TD_VDiskinfo.PreferredNodeID            = $TD_DeviceInformation.preferred_node_id[$i]
            $TD_VDiskinfo.PreferredNodeName          = $TD_DeviceInformation.preferred_node_name[$i]
            $TD_VDiskinfo.isSnapshot                 = $TD_DeviceInformation.is_snapshot[$i]
            #   SnapshotCount,VolumeType,ReplicationMode,isSafeguardedSnapshot,SafeguardedSnapshotCount
            $TD_VDiskinfo.SnapshotCount              = $TD_DeviceInformation.snapshot_count[$i]
            $TD_VDiskinfo.VolumeType                 = $TD_DeviceInformation.volume_type[$i]
            $TD_VDiskinfo.ReplicationMode            = $TD_DeviceInformation.replication_mode[$i]
            $TD_VDiskinfo.isSafeguardedSnapshot      = $TD_DeviceInformation.is_safeguarded_snapshot[$i]
            $TD_VDiskinfo.SafeguardedSnapshotCount   = $TD_DeviceInformation.safeguarded_snapshot_count[$i]


            $TD_VDiskinfo.WWNN           = $IBMSTOWWNN
            $TD_VDiskinfo.SerialNumber   = $IBMSTOSN
            $TD_VDiskinfo.RowID          = "$IBMSTOSN|$($TD_VDiskinfo.VdiskUID)"
            $TD_VDiskinfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {
        
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){

            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_VDiskFuncResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_VDiskFuncResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_VDiskFuncResault
        }
        return $TD_VDiskFuncResault
    }
}