function IBM_RESTBaseStorageInfos {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        #[string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
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
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STOSystemInfo = SST_SpectrumSystemAPI -Endpoint lssystem -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
    }
    
    process {
        [int]$imax = $STONodeInfo.Count
        $TD_StorageInfo = for ($i = 0; $i -le $imax; $i++) {
            $TD_FSBaseTemp = "" | Select-Object ID,Name,ClusterName,WWNN,Status,IO_group_id,IO_group_Name,Serial_Number,Code_Level,Config_Node,SideID,SideName,Prod_MTM,RecommendedPTF,MDiskTotalCapacity,MDiskFreeCapacity,MDiskUsedCapacity,PhysicalTotalCapacity,PhysicalFreeCapacity,HostUnmap,BackendUnmap,Topology,Layer,QuorumMode
            $TD_FSBaseTemp.ID   =   $STONodeInfo.id[$i]
            $TD_FSBaseTemp.Name   =   $STONodeInfo.name[$i]
            $TD_FSBaseTemp.ClusterName   =   $STOSystemInfo.name
            $TD_FSBaseTemp.WWNN   =   $STONodeInfo.WWNN[$i]
            $TD_FSBaseTemp.Status   =   $STONodeInfo.status[$i]
            $TD_FSBaseTemp.IO_group_id   =   $STONodeInfo.IO_group_id[$i]
            $TD_FSBaseTemp.IO_group_Name   =   $STONodeInfo.IO_group_name[$i]
            $TD_FSBaseTemp.Serial_Number   =   if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}
            $TD_FSBaseTemp.Config_Node   =   $STONodeInfo.config_node[$i]
            $TD_FSBaseTemp.SideID   =   $STONodeInfo.site_id[$i]
            $TD_FSBaseTemp.SideName   =   $STONodeInfo.site_name[$i]
            $TD_FSBaseTemp.Prod_MTM   =   $STOSystemInfo.product_name
            $TD_FSBaseTemp.Code_Level   =   $STOSystemInfo.code_level
            <#try to get a RecommendedPTF level#>
            if ((![string]::IsNullOrEmpty($TD_FSBaseTemp.Prod_MTM))-and(![string]::IsNullOrEmpty($TD_FSBaseTemp.Code_Level))){
                if(($TD_FSBaseTemp.Code_Level)-ne($TD_FSBaseTempCode_Level)){
                    $TD_SpectrVirtuFWInfos = IBM_StorageSWCheck -IBM_CurrentSpectrVirtuFW $TD_FSBaseTemp.Code_Level -IBM_ProdMTM $TD_FSBaseTemp.Prod_MTM
                    $TD_FSBaseTempCode_Level = $TD_FSBaseTemp.Code_Level
                    [string]$TD_FSBaseTemp.RecommendedPTF = $TD_SpectrVirtuFWInfos.RecommendedPTF
                }else {
                    [string]$TD_FSBaseTemp.RecommendedPTF = $TD_SpectrVirtuFWInfos.RecommendedPTF
                }
            }
            $TD_FSBaseTemp.MDiskTotalCapacity   =   $STOSystemInfo.total_mdisk_capacity
            $TD_FSBaseTemp.MDiskFreeCapacity   =   $STOSystemInfo.total_free_space
            $TD_FSBaseTemp.MDiskUsedCapacity   =   $STOSystemInfo.total_used_capacity
            $TD_FSBaseTemp.PhysicalTotalCapacity   =   $STOSystemInfo.physical_capacity
            $TD_FSBaseTemp.PhysicalFreeCapacity   =   $STOSystemInfo.physical_free_capacity
            $TD_FSBaseTemp.HostUnmap   =   $STOSystemInfo.host_unmap
            $TD_FSBaseTemp.BackendUnmap   =   $STOSystemInfo.backend_unmap
            $TD_FSBaseTemp.Topology   =   $STOSystemInfo.topology
            $TD_FSBaseTemp.Layer   =   $STOSystemInfo.layer
            $TD_FSBaseTemp.QuorumMode   =   $STOSystemInfo.quorum_mode
            $TD_FSBaseTemp
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($STONodeInfo.name[$i])" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        if([string]::IsNullOrEmpty($TD_Device_DeviceName)){$TD_Device_DeviceName = $TD_StorageInfo.Name[0]}
        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_StorageInfo | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_StorageInfo | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_StorageBaseInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }
        [PSCustomObject]@{
            StorageInfo     = $TD_StorageInfo
            ConnectionTyp   = $TD_Device_ConnectionTyp
        }
    }
}