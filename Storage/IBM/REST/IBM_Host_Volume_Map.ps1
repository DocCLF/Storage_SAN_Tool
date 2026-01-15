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
                SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            }
        }
        if([string]::IsNullOrWhiteSpace($TD_Device_ConnectionTyp)){
            $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW 
        }
        Clear-Variable -Name TD_Device_PW -Force
        if($TD_Device_ConnectionTyp -eq "REST"){
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lshostvdiskmap -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
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
        [array]$TD_Mappingresault = for ($i = 0; $i -le $imax; $i++) {

            $TD_SplitInfos = "" | Select-Object HostID,HostName,HostClusterID,HostCluster,MappingType,VolumeID,VolumeName,UID,Capacity,WWNN,SerialNumber
            $TD_SplitInfos.HostID                 = $TD_DeviceInformation.id[$i]
            $TD_SplitInfos.HostName          = $TD_DeviceInformation.name[$i]
            $TD_SplitInfos.VolumeID           = $TD_DeviceInformation.vdisk_id[$i]
            $TD_SplitInfos.VolumeName            = $TD_DeviceInformation.vdisk_name[$i]
            $TD_SplitInfos.UID             = $TD_DeviceInformation.vdisk_UID[$i]
            $TD_SplitInfos.MappingType         = $TD_DeviceInformation.mapping_type[$i]
            $TD_SplitInfos.HostClusterID       = $TD_DeviceInformation.host_cluster_id[$i]
            $TD_SplitInfos.HostCluster           = $TD_DeviceInformation.host_cluster_name[$i]
            $TD_VdiskInfo = SST_SpectrumSystemAPI -Endpoint lshostvdiskmap/$TD_DeviceInformation.vdisk_id[$i] -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            if($TD_SplitInfos.UID -eq $TD_VdiskInfo.VdiskUID){
                $TD_SplitInfos.Capacity = $TD_VdiskInfo.capacity
            }

            $TD_SplitInfos.WWNN = $IBMSTOWWNN
            $TD_SplitInfos.SerialNumber = $IBMSTOSN

            $TD_SplitInfos

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
        
    end{

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
                $TD_Mappingresault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_Mappingresault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_Host_Volume_Map_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_Mappingresault
        }
        return $TD_Mappingresault 
    }
}