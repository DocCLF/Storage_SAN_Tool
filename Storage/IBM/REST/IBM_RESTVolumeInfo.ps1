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
        $null = IBM_RESTVDiskAnalysis -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo -STOSN $IBMSTOSN -STOWWNN $IBMSTOWWNN -TD_Exportpath $TD_Exportpath
    }

    process{
        [int]$imax = $TD_DeviceInformation.Count
        $TD_VolumeSnapshots = @()

        $VolumesWithSnapshots = @( $TD_DeviceInformation | Where-Object { [int]$_.snapshot_count -ge 1 } )

        if ($VolumesWithSnapshots.Count -gt 0) {
            $TD_VolumeSnapshots = @(SST_SpectrumSystemAPI -Endpoint lsvolumesnapshot -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo)
        }

        $TD_VDiskFuncResault = for ($i = 0; $i -lt $imax; $i++) {
            <# Max requests/sec to command endpoints = 10 -.- #>
            if ($i % 8 -eq 0) { Start-Sleep -Milliseconds 1500 }
            <# Node Info#>
            $TD_VDiskinfo = "" | Select-Object RowID,ID,Name,IOGroupID,IOGroupName,Status,MdiskGrpID,MdiskGrpName,Capacity,Type,FCID,FCName,`
                                            RCID,RCName,VdiskUID,FCMapCount,CopyCount,FastWriteState,SECopyCount,RCChange,CompressedCopyCount,ParentMdiskGrpID,ParentMdiskGrpName,`
                                            OwnerID,OwnerName,Formatting,Encrypt,VolumeID,VolumeName,Function,VolumeGroupID,VolumeGroupName,Protocol,PreferredNodeID,PreferredNodeName,isSnapshot,`
                                            SnapshotCount,VolumeType,ReplicationMode,isSafeguardedSnapshot,SafeguardedSnapshotCount,SnapshotID,SnapshotName,ParentUID,SnapshotTime,ExpirationTime,`
                                            SnapshotState,Safeguarded,VolumeSizeMismatch,Mirrored,WrittenCapacity,GroupKey,GroupName,RowType,RowOrder,CopyID,IsPrimary,Sync,AutoDelete,UsedCapacity,`
                                            RealCapacity,FreeCapacity,Overallocation,EasyTier,EasyTierStatus,CompressedCopy,DeduplicatedCopy,WWNN,SerialNumber

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

            $TD_VDiskinfo.WWNN         = $IBMSTOWWNN
            $TD_VDiskinfo.SerialNumber = $IBMSTOSN

            # Volume.ID is the common reference to Snapshot.volume_id.
            $TD_VDiskinfo.GroupKey  = "$IBMSTOSN|VOLUME|$($TD_VDiskinfo.ID)"
            $TD_VDiskinfo.GroupName = $TD_VDiskinfo.Name
            $TD_VDiskinfo.RowType   = "Volume"
            $TD_VDiskinfo.RowOrder  = 0

            $TD_VDiskinfo.RowID = "$IBMSTOSN|VOLUME|$($TD_VDiskinfo.ID)"

            # Display the volume on its own line.
            $TD_VDiskinfo

            # --------------------------------------------------------
            # Determine volume copies.
            #
            # A volume with more than one copy returns "many" for # properties such as mdisk_grp_name and type in lsvdisk.
            #
            # lsvdisk/<VolumeID> returns:
            #
            #   - the logical volume object
            #   - one object for every volume copy
            #
            # Copy objects are identified by the copy_id property.
            # --------------------------------------------------------

            [int]$NextRowOrder = 1

            if ([int]$TD_VDiskinfo.CopyCount -gt 1) {
            
                $VDiskDetail = @(SST_SpectrumSystemAPI -Endpoint "lsvdisk/$($TD_VDiskinfo.ID)" -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo)
            
                # ----------------------------------------------------
                # Do not rely on array positions.
                # Select only objects which really represent copies.
                # ----------------------------------------------------
            
                $VolumeCopies = @($VDiskDetail |Where-Object {$null -ne $_ -and $_.PSObject.Properties['copy_id']} | Sort-Object {[int]$_.copy_id})
                    
                foreach ($Copy in $VolumeCopies) {
                
                    $CopyID = [string]$Copy.copy_id
                    $IsPrimary = ([string]$Copy.primary -eq 'yes')
                
                    $CopyDisplayName = if ($IsPrimary) { "↳ Copy $CopyID *"}else {"↳ Copy $CopyID"}
                    
                    [PSCustomObject]@{
                        RowID                     = "$IBMSTOSN|VOLUMECOPY|$($TD_VDiskinfo.VdiskUID)|$CopyID"
                    
                        ID                        = $CopyID
                        Name                      = "Copy $CopyID"
                        DisplayName               = $CopyDisplayName
                    
                        IOGroupID                 = $TD_VDiskinfo.IOGroupID
                        IOGroupName               = $TD_VDiskinfo.IOGroupName
                    
                        Status                    = [string]$Copy.status
                    
                        MdiskGrpID                = [string]$Copy.mdisk_grp_id
                        MdiskGrpName              = [string]$Copy.mdisk_grp_name
                    
                        Capacity                  = $TD_VDiskinfo.Capacity
                        Type                      = [string]$Copy.type
                    
                        FCID                      = $null
                        FCName                    = $null
                        RCID                      = $null
                        RCName                    = $null
                    
                        VdiskUID                  = $TD_VDiskinfo.VdiskUID
                    
                        FCMapCount                = $null
                        CopyCount                 = $null
                    
                        FastWriteState            = [string]$Copy.fast_write_state
                    
                        SECopyCount               = $null
                        RCChange                  = $null
                        CompressedCopyCount       = $null
                    
                        ParentMdiskGrpID          = [string]$Copy.parent_mdisk_grp_id
                        ParentMdiskGrpName        = [string]$Copy.parent_mdisk_grp_name
                    
                        OwnerID                   = $TD_VDiskinfo.OwnerID
                        OwnerName                 = $TD_VDiskinfo.OwnerName
                    
                        Formatting                = $null
                        Encrypt                   = [string]$Copy.encrypt
                    
                        VolumeID                  = $TD_VDiskinfo.ID
                        VolumeName                = $TD_VDiskinfo.Name
                    
                        Function                  = $null
                    
                        VolumeGroupID             = $TD_VDiskinfo.VolumeGroupID
                        VolumeGroupName           = $TD_VDiskinfo.VolumeGroupName
                    
                        Protocol                  = $TD_VDiskinfo.Protocol
                    
                        PreferredNodeID           = $TD_VDiskinfo.PreferredNodeID
                        PreferredNodeName         = $TD_VDiskinfo.PreferredNodeName
                    
                        IsSnapshot                = $false
                        SnapshotCount             = $null
                    
                        VolumeType                = 'Copy'
                        ReplicationMode           = $TD_VDiskinfo.ReplicationMode
                    
                        IsSafeguardedSnapshot     = $false
                        SafeguardedSnapshotCount  = $null
                    
                        SnapshotID                = $null
                        SnapshotName              = $null
                        ParentUID                 = $null
                        SnapshotTime              = $null
                        ExpirationTime            = $null
                        SnapshotState             = $null
                        Safeguarded               = $null
                        VolumeSizeMismatch        = $null
                        Mirrored                  = $null
                        WrittenCapacity           = $null
                    
                        # ------------------------------------------------
                        # Additional copy-specific information.
                        # These properties must also be added to the
                        # Select-Object definition above.
                        # ------------------------------------------------
                    
                        CopyID                    = $CopyID
                        IsPrimary                 = $IsPrimary
                        Sync                      = [string]$Copy.sync
                        AutoDelete                = [string]$Copy.auto_delete
                    
                        UsedCapacity              = [string]$Copy.used_capacity
                        RealCapacity              = [string]$Copy.real_capacity
                        FreeCapacity              = [string]$Copy.free_capacity
                        Overallocation            = [string]$Copy.overallocation
                    
                        EasyTier                  = [string]$Copy.easy_tier
                        EasyTierStatus            = [string]$Copy.easy_tier_status
                    
                        CompressedCopy            = [string]$Copy.compressed_copy
                        DeduplicatedCopy          = [string]$Copy.deduplicated_copy
                    
                        # ------------------------------------------------
                        # Belongs to exactly the same logical volume.
                        # ------------------------------------------------
                    
                        GroupKey                  = "$IBMSTOSN|VOLUME|$($TD_VDiskinfo.ID)"
                        GroupName                 = $TD_VDiskinfo.Name
                    
                        RowType                   = 'VolumeCopy'
                        RowOrder                  = $NextRowOrder
                    
                        WWNN                      = $IBMSTOWWNN
                        SerialNumber              = $IBMSTOSN
                    }
                
                    $NextRowOrder++
                }
            }

            # --------------------------------------------------------
            # Determine snapshots of the current volume.
            # Assignment:
            #   Volume.ID = Snapshot.volume_id
            # --------------------------------------------------------
            if ([int]$TD_VDiskinfo.SnapshotCount -ge 1) {
                $MatchingSnapshots = @(
                    $TD_VolumeSnapshots | Where-Object {
                        [string]$_.volume_id -eq [string]$TD_VDiskinfo.ID
                    }
                )

                [int]$SnapshotOrder = 1

                foreach ($Snapshot in $MatchingSnapshots) {

                    # Prefer a unique snapshot ID. If it is empty,
                    # the name and sequential number are used as a fallback.
                    $SnapshotIdentity = $Snapshot.snapshot_id

                    if ([string]::IsNullOrWhiteSpace([string]$SnapshotIdentity)) {
                        $SnapshotIdentity = "$($Snapshot.snapshot_name)|$SnapshotOrder"
                    }

                    [PSCustomObject]@{
                        RowID                     = "$IBMSTOSN|SNAPSHOT|$SnapshotIdentity"
                        ID                        = $Snapshot.snapshot_id
                        Name                      = $Snapshot.snapshot_name
                        DisplayName               = "↳ $($Snapshot.snapshot_name)"
                        IOGroupID                 = $TD_VDiskinfo.IOGroupID
                        IOGroupName               = $TD_VDiskinfo.IOGroupName
                        Status                    = $Snapshot.state
                        MdiskGrpID                = $TD_VDiskinfo.MdiskGrpID
                        MdiskGrpName              = $TD_VDiskinfo.MdiskGrpName
                        Capacity                  = $Snapshot.written_capacity
                        Type                      = "Snapshot"
                        FCID                      = $null
                        FCName                    = $null
                        RCID                      = $null
                        RCName                    = $null
                        VdiskUID                  = $Snapshot.parent_uid
                        FCMapCount                = $null
                        CopyCount                 = $null
                        FastWriteState            = $null
                        SECopyCount               = $null
                        RCChange                  = $null
                        CompressedCopyCount       = $null
                        ParentMdiskGrpID           = $TD_VDiskinfo.ParentMdiskGrpID
                        ParentMdiskGrpName         = $TD_VDiskinfo.ParentMdiskGrpName
                        OwnerID                   = $TD_VDiskinfo.OwnerID
                        OwnerName                 = $TD_VDiskinfo.OwnerName
                        Formatting                = $null
                        Encrypt                   = $TD_VDiskinfo.Encrypt
                        VolumeID                  = $Snapshot.volume_id
                        VolumeName                = $Snapshot.volume_name
                        Function                  = $null
                        VolumeGroupID             = $Snapshot.volume_group_id
                        VolumeGroupName           = $Snapshot.volume_group_name
                        Protocol                  = $null
                        PreferredNodeID           = $TD_VDiskinfo.PreferredNodeID
                        PreferredNodeName         = $TD_VDiskinfo.PreferredNodeName
                        IsSnapshot                = $true
                        SnapshotCount             = $null
                        VolumeType                = "Snapshot"
                        ReplicationMode           = $TD_VDiskinfo.ReplicationMode
                        IsSafeguardedSnapshot     = $Snapshot.safeguarded
                        SafeguardedSnapshotCount  = $null
                        SnapshotID                = $Snapshot.snapshot_id
                        SnapshotName              = $Snapshot.snapshot_name
                        ParentUID                 = $Snapshot.parent_uid
                        SnapshotTime              = $Snapshot.time
                        ExpirationTime            = $Snapshot.expiration_time
                        SnapshotState             = $Snapshot.state
                        Safeguarded               = $Snapshot.safeguarded
                        VolumeSizeMismatch        = $Snapshot.volume_size_mismatch
                        Mirrored                  = $Snapshot.mirrored
                        WrittenCapacity           = $Snapshot.written_capacity

                        # The same group key as the source volume.
                        GroupKey                  = "$IBMSTOSN|VOLUME|$($Snapshot.volume_id)"
                        GroupName                 = $TD_VDiskinfo.Name
                        RowType                   = "Snapshot"
                        RowOrder                  = $SnapshotOrder

                        WWNN                      = $IBMSTOWWNN
                        SerialNumber              = $IBMSTOSN
                    }

                    $SnapshotOrder++
                }
            }

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($IBMSTOSN)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {
        
        if($TD_VDiskFuncResault.count -gt 0){
            $null = Save-StorageVolumeHistory -SourceType 'Volume' -InputObject $TD_VDiskFuncResault
        }
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){

            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_VDiskFuncResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_VDiskFuncResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_Volume_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_VDiskFuncResault
        }
        return $TD_VDiskFuncResault
    }
}