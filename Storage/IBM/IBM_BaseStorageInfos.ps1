function IBM_BaseStorageInfos {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [string]$TD_Storage = "FSystem",
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        $BaseUrl = "https://$TD_Device_DeviceIP"+":7443"

        if(Test-Path -Path "$PSRootPath\Resources\DBFolder\SSTLocalDB.db"){
            $RESTInfo = SST_RESTDBControl -SST_InfoType "UseStorageToken" -SST_BaseUrl $BaseUrl
            if(([string]::IsNullOrEmpty($RESTInfo)) -and ($TD_Device_ConnectionTyp -eq "REST")){
                SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            }
        }
        if([string]::IsNullOrWhiteSpace($TD_Device_ConnectionTyp)){
            $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW 
        }
        <# Connect to Device and get all needed Data #>
        switch ($TD_Storage) {
            "SVC" { 
                if($TD_Device_ConnectionTyp -eq "REST"){
                    $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -SST_BaseUrl $BaseUrl -RESTInfo $RESTInfo
                    $STOSystemInfo = SST_SpectrumSystemAPI -Endpoint lssystem -Body $null -SST_BaseUrl $BaseUrl -RESTInfo $RESTInfo
                }else {
                    $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnode -delim : && lsnode -nohdr |while read id name IO_group_id;do lsnode -delim : $id ;echo;done && lssystem -delim , |grep name'
                    $TD_BaseInformations = $TD_BaseInformations |Select-Object -Skip 1
                }
             }
            Default {
                if($TD_Device_ConnectionTyp -eq "REST"){
                    $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnodecanister -Body $null -SST_BaseUrl $BaseUrl -RESTInfo $RESTInfo
                    $STOSystemInfo = SST_SpectrumSystemAPI -Endpoint lssystem -Body $null -SST_BaseUrl $BaseUrl -RESTInfo $RESTInfo
                }else {
                    $TD_BaseInformations = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsnodecanister -delim : && lsnodecanister -nohdr |while read id name IO_group_id;do lsnodecanister -delim : $id ;echo;done && lssystem -delim , |grep name'
                    $TD_BaseInformations = $TD_BaseInformations |Select-Object -Skip 1
                }
            }
        }
    }

    process {

        if($TD_Device_ConnectionTyp -eq "REST"){
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
                $TD_FSBaseTemp.Serial_Number   =   $STONodeInfo.enclosure_serial_number[$i]
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
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($STONodeInfo.name[$i])" -PercentComplete (($ProgCounter/$TD_BaseInformations.Count) * 100)
            }
        }else{
            $TD_SystemInfo = IBM_SystemInfo -TD_Line_ID $TD_Line_ID -TD_Device_ConnectionTyp $TD_Device_ConnectionTyp -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            $TD_StorageInfo = foreach($TD_FSBaseInfo in $TD_BaseInformations){
                $TD_FSBaseTemp = "" | Select-Object ID,Name,ClusterName,WWNN,Status,IO_group_id,IO_group_Name,Serial_Number,Code_Level,Config_Node,SideID,SideName,Prod_MTM,RecommendedPTF,MDiskTotalCapacity,MDiskFreeCapacity,MDiskUsedCapacity,PhysicalTotalCapacity,PhysicalFreeCapacity,HostUnmap,BackendUnmap,Topology,Layer,QuorumMode
                $TD_FSBaseTemp.ID = ($TD_FSBaseInfo|Select-String -Pattern '^(\d+):' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseTemp.Name = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseTemp.ClusterName = ($TD_BaseInformations|Select-String -Pattern '^name\,([\w\-]+)' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseTemp.WWNN = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseTemp.Status = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9-_]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[2].Value
                $TD_FSBaseTemp.IO_group_id = ($TD_FSBaseInfo|Select-String -Pattern '^\d+:[a-zA-Z0-9-_]+:.*:([a-zA-Z0-9-_]+):(online|offline|service|flushing|adding|deleting|service):(\d+)' -AllMatches).Matches.Groups[3].Value
                $TD_FSBaseTemp.IO_group_Name = ($TD_FSBaseInfo|Select-String -Pattern '\d+:([a-zA-Z0-9-_]+):(yes|no):' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseBackEndSerial_Number = ($TD_FSBaseInfo|Select-String -Pattern ':\d+:\d+:([a-zA-Z0-9]+):' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseSVCSerialNumber = ($TD_FSBaseInfo|Select-String -Pattern ':(\w{6,8}):(|\d+):(|\d+):(|\w{6,8}):' -AllMatches).Matches.Groups[1].Value
                if($TD_Storage -eq "SVC"){
                   $TD_FSBaseTemp.Serial_Number = $TD_FSBaseSVCSerialNumber
                }else {
                    $TD_FSBaseTemp.Serial_Number = $TD_FSBaseBackEndSerial_Number
                }
                $TD_FSBaseTemp.Config_Node = ($TD_FSBaseInfo|Select-String -Pattern '\d+:([\w\-]+):(yes|no):' -AllMatches).Matches.Groups[2].Value
                $TD_FSBaseTemp.SideID = ($TD_FSBaseInfo|Select-String -Pattern ':(\d+|):([a-zA-Z0-9-_]+)$' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseTemp.SideName = ($TD_FSBaseInfo|Select-String -Pattern ':(\d+|):([a-zA-Z0-9-_]+)$' -AllMatches).Matches.Groups[2].Value
                $TD_FSBaseTemp.Prod_MTM = ($TD_BaseInformations|Select-String -Pattern '^product_mtm:([a-zA-Z0-9-]+)' -AllMatches).Matches.Groups[1].Value
                $TD_FSBaseTemp.Code_Level = ($TD_BaseInformations|Select-String -Pattern '^code_level:(\d+.\d+.\d+.\d+)' -AllMatches).Matches.Groups[1].Value

                if ((![string]::IsNullOrEmpty($TD_FSBaseTemp.Prod_MTM))-and(![string]::IsNullOrEmpty($TD_FSBaseTemp.Code_Level))){
                    if(($TD_FSBaseTemp.Code_Level)-ne($TD_FSBaseTempCode_Level)){
                        $TD_SpectrVirtuFWInfos = IBM_StorageSWCheck -IBM_CurrentSpectrVirtuFW $TD_FSBaseTemp.Code_Level -IBM_ProdMTM $TD_FSBaseTemp.Prod_MTM
                        $TD_FSBaseTempCode_Level = $TD_FSBaseTemp.Code_Level

                        Write-Debug -Message $TD_FSBaseTemp.Code_Level $TD_SpectrVirtuFWInfos

                        [string]$TD_FSBaseTemp.RecommendedPTF = $TD_SpectrVirtuFWInfos.RecommendedPTF
                    }else {
                        [string]$TD_FSBaseTemp.RecommendedPTF = $TD_SpectrVirtuFWInfos.RecommendedPTF
                    }
                }
                $TD_FSBaseTemp.MDiskTotalCapacity=$TD_SystemInfo.'MDiskTotalCapacity'
                $TD_FSBaseTemp.MDiskFreeCapacity=$TD_SystemInfo.'MDiskFreeCapacity'
                $TD_FSBaseTemp.MDiskUsedCapacity=$TD_SystemInfo.'MDiskUsedCapacity'
                $TD_FSBaseTemp.PhysicalTotalCapacity=$TD_SystemInfo.'PhysicalTotalCapacity'
                $TD_FSBaseTemp.PhysicalFreeCapacity=$TD_SystemInfo.'PhysicalFreeCapacity'
                $TD_FSBaseTemp.HostUnmap=$TD_SystemInfo.'HostUnmap'
                $TD_FSBaseTemp.BackendUnmap=$TD_SystemInfo.'BackendUnmap'
                if(([String]::IsNullOrEmpty($TD_FSBaseTemp.ID))){continue}
                $TD_FSBaseTemp
                <# Progressbar  #>
                $ProgCounter++
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_BaseInformations.Count) * 100)
            }
        }
        
    }
    
    end {
        if($TD_Line_ID -eq 1){$TD_CB_STO_DG1.Visibility="visible";$TD_LB_STO_DG1.Visibility="visible"; $TD_LB_STO_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_CB_STO_DG2.Visibility="visible";$TD_LB_STO_DG2.Visibility="visible"; $TD_LB_STO_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_CB_STO_DG3.Visibility="visible";$TD_LB_STO_DG3.Visibility="visible"; $TD_LB_STO_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_CB_STO_DG4.Visibility="visible";$TD_LB_STO_DG4.Visibility="visible"; $TD_LB_STO_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_CB_STO_DG5.Visibility="visible";$TD_LB_STO_DG5.Visibility="visible"; $TD_LB_STO_DG5.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 6){$TD_CB_STO_DG6.Visibility="visible";$TD_LB_STO_DG6.Visibility="visible"; $TD_LB_STO_DG6.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 7){$TD_CB_STO_DG7.Visibility="visible";$TD_LB_STO_DG7.Visibility="visible"; $TD_LB_STO_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_CB_STO_DG8.Visibility="visible";$TD_LB_STO_DG8.Visibility="visible"; $TD_LB_STO_DG8.Content=$TD_Device_DeviceName}

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