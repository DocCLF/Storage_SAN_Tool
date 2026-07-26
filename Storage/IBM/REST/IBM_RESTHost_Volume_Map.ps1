function IBM_RESTHost_Volume_Map {
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lshostvdiskmap -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $TD_VdiskInfo = SST_SpectrumSystemAPI -Endpoint lsvdisk -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
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
        $VdiskLookup = @{}

        foreach ($vdisk in $TD_VdiskInfo) {
            $key = "$($vdisk.vdisk_UID)|$($vdisk.id)"
            $VdiskLookup[$key] = $vdisk
        }

        [int]$imax = $TD_DeviceInformation.Count

        [array]$TD_MappingResult = for ($i = 0; $i -lt $imax; $i++) {

            $device = $TD_DeviceInformation[$i]

            $TD_SplitInfos = [pscustomobject]@{
                RowID         = $null
                HostID        = $device.id
                HostName      = $device.name
                HostClusterID = $device.host_cluster_id
                HostCluster   = $device.host_cluster_name
                MappingType   = $device.mapping_type
                SCSIID        = $device.SCSI_id
                VolumeID      = $device.vdisk_id
                VolumeName    = $device.vdisk_name
                UID           = $device.vdisk_UID
                Capacity      = $null
                VolumeGroupName = $null
                WWNN          = $IBMSTOWWNN
                SerialNumber  = $IBMSTOSN
            }

            $key = "$($TD_SplitInfos.UID)|$($TD_SplitInfos.VolumeID)"

            if ($VdiskLookup.ContainsKey($key)) {
                $TD_SplitInfos.Capacity = $VdiskLookup[$key].capacity
                $TD_SplitInfos.VolumeGroupName = $VdiskLookup[$key].volume_group_name
            }

            $TD_SplitInfos.RowID = "$IBMSTOSN|$($TD_SplitInfos.HostID)|$($TD_SplitInfos.VolumeID)"

            $TD_SplitInfos

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
        
    end{
        #$TD_MappingResult | Select-Object -First 5 | Format-List * | Out-String | Write-Host

        <# if update is clicked update the right list #>
        if($TD_RefreshView -eq "Update"){
            if($TD_Line_ID -eq 1){
                $TD_lb_HostVolInfo.ItemsSource = $TD_Host_Volume_Map
            }elseif($TD_Line_ID -eq 2){
                $TD_lb_HostVolInfoTwo.ItemsSource = $TD_Host_Volume_Map
            }
        }
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_MappingResult | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_MappingResult | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_MappingResult
        }
        return $TD_MappingResult 
    }
}