function IBM_RESTDriveInfo {
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsdrive -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            #'https://192.168.249.115:7443/rest/v1/lsdrive/0'
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
        [array]$TD_DriveOverview = for ($i = 0; $i -le $imax; $i++) {
            $TD_DriveIDInformation = SST_SpectrumSystemAPI -Endpoint lsdrive/$TD_DeviceInformation.id[$i] -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $TD_DriveSplitInfos = "" | Select-Object ID,Status,ErrorSequenceNumber,Use,TechType,UID,Capacity,BlockSize,VendorID,ProductID,FRUPartNumber,FRUIdentity,`
                                        RPM,FirmwareLevel,MdiskID,MdiskName,MemberID,EnclosureID,SlotID,NodeID,NodeName,QuorumID,Port1Status,`
                                        Port2Status,ErrorSequenceNumber,ProtectionEnabled,AutoManage,DriveClassID,ReplacementDate,TransportProtocol,Compressed,PhysicalCapacity,PhysicalUsedCapacity,EffectiveUsedCapacity,WWNN,SerialNumber
            #   ID,Status,ErrorSequenceNumber,Use,TechType,UID,Capacity,BlockSize,VendorID,ProductID,FRUPartNumber,FRUIdentity
            $TD_DriveSplitInfos.ID                     = $TD_DriveIDInformation.id[$i]
            $TD_DriveSplitInfos.Status                 = $TD_DriveIDInformation.status[$i]
            $TD_DriveSplitInfos.ErrorSequenceNumber    = $TD_DriveIDInformation.error_sequence_number[$i]
            $TD_DriveSplitInfos.Use                    = $TD_DriveIDInformation.use[$i]
            $TD_DriveSplitInfos.TechType               = $TD_DriveIDInformation.tech_type[$i]
            $TD_DriveSplitInfos.UID                    = $TD_DriveIDInformation.UID[$i]
            $TD_DriveSplitInfos.Capacity               = $TD_DriveIDInformation.capacity[$i]
            $TD_DriveSplitInfos.BlockSize              = $TD_DriveIDInformation.block_size[$i]
            $TD_DriveSplitInfos.VendorID               = $TD_DriveIDInformation.vendor_id[$i]
            $TD_DriveSplitInfos.ProductID              = $TD_DriveIDInformation.product_id[$i]
            $TD_DriveSplitInfos.FRUPartNumber          = $TD_DriveIDInformation.FRU_part_number[$i]
            $TD_DriveSplitInfos.FRUIdentity            = $TD_DriveIDInformation.FRU_identity[$i]
            #   RPM,FirmwareLevel,MdiskID,MdiskName,MemberID,EnclosureID,SlotID,NodeID,NodeName,QuorumID,Port1Status    
            $TD_DriveSplitInfos.RPM                    = $TD_DriveIDInformation.RPM[$i]
            $TD_DriveSplitInfos.FirmwareLevel          = $TD_DriveIDInformation.firmware_level[$i]
            $TD_DriveSplitInfos.MdiskID                = $TD_DriveIDInformation.mdisk_id[$i]
            $TD_DriveSplitInfos.MdiskName              = $TD_DriveIDInformation.mdisk_name[$i]
            $TD_DriveSplitInfos.MemberID               = $TD_DriveIDInformation.member_id[$i]
            $TD_DriveSplitInfos.EnclosureID            = $TD_DriveIDInformation.enclosure_id[$i]
            $TD_DriveSplitInfos.SlotID                 = $TD_DriveIDInformation.slot_id[$i]
            $TD_DriveSplitInfos.NodeID                 = $TD_DriveIDInformation.node_id[$i]
            $TD_DriveSplitInfos.NodeName               = $TD_DriveIDInformation.node_name[$i]
            $TD_DriveSplitInfos.QuorumID               = $TD_DriveIDInformation.quorum_id[$i]
            $TD_DriveSplitInfos.Port1Status            = $TD_DriveIDInformation.port_1_status[$i]
            #   Port2Status,ErrorSequenceNumber,ProtectionEnabled,AutoManage,DriveClassID,ReplacementDate,TransportProtocol,Compressed,PhysicalCapacity,PhysicalUsedCapacity,EffectiveUsedCapacity,WWNN,SerialNumber 
            $TD_DriveSplitInfos.Port2Status            = $TD_DriveIDInformation.port_2_status[$i]
            $TD_DriveSplitInfos.ErrorSequenceNumber    = $TD_DriveIDInformation.interface_speed[$i]
            $TD_DriveSplitInfos.ProtectionEnabled      = $TD_DriveIDInformation.protection_enabled[$i]
            $TD_DriveSplitInfos.AutoManage             = $TD_DriveIDInformation.auto_manage[$i]
            $TD_DriveSplitInfos.DriveClassID           = $TD_DriveIDInformation.drive_class_id[$i]
            $TD_DriveSplitInfos.ReplacementDate        = $TD_DriveIDInformation.replacement_date[$i]
            $TD_DriveSplitInfos.TransportProtocol      = $TD_DriveIDInformation.transport_protocol[$i]
            $TD_DriveSplitInfos.Compressed             = $TD_DriveIDInformation.compressed[$i]
            $TD_DriveSplitInfos.PhysicalCapacity       = $TD_DriveIDInformation.physical_capacity[$i]
            $TD_DriveSplitInfos.PhysicalUsedCapacity   = $TD_DriveIDInformation.physical_used_capacity[$i]
            $TD_DriveSplitInfos.EffectiveUsedCapacity  = $TD_DriveIDInformation.effective_used_capacity[$i]
            $TD_DriveSplitInfos.WWNN = $IBMSTOWWNN
            $TD_DriveSplitInfos.SerialNumber = $IBMSTOSN

            $TD_DriveSplitInfos

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }

    end{
        Close-ProgressBar -ProgressBar $ProgressBar

        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_DriveOverview | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug -TD_Shown no
            }else {
                $TD_DriveOverview | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Drive_Overview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug -TD_Shown no
            }
            Start-Sleep -Seconds 0.2
        }else {
            <# output on the promt #>
            SST_ToolMessageCollector -TD_ToolMSGCollector "Result for:`nName: $($TD_NodeSplitInfo.NodeName) `nProduct: $($TD_NodeSplitInfo.ProdName) `nFirmware: $($TD_NodeSplitInfo.NodeFW)" -TD_ToolMSGType Debug -TD_Shown no
            Start-Sleep -Seconds 0.2
            return $TD_DriveOverview
        }
        return $TD_DriveOverview
    }
}