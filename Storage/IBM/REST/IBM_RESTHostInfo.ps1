function IBM_RESTHostInfo {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName=$null,
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lshost -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STOSystemInfo = SST_SpectrumSystemAPI -Endpoint lssystem -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
        [int]$imax = $STONodeInfo.Count
        for ($i = 0; $i -le $imax; $i++) {
            if($STONodeInfo.config_node[$i] -eq "yes"){
                $IBMSTOWWNN = $STONodeInfo.WWNN[$i]
                $IBMSTOSideName = $STONodeInfo.site_name[$i]
                $IBMSTOSN = if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}
            }
        }
        $TD_Device_DeviceName = $STONodeInfo.name[0]
    }

    process{
        [int]$imax = $TD_DeviceInformation.Count
        [array]$CollectedHostInfo = for ($i = 0; $i -lt $imax; $i++) {
            $TD_HostIDInformation = SST_SpectrumSystemAPI -Endpoint lshost/$($TD_DeviceInformation.id[$i]) -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            
            <# Host Info#> 
            <# HostStateInfo is this part where is check if the host state is different as at the last check see ssh func hostinfo #>
            $TD_HostBaseTemp = "" | Select-Object RowID,ID,HostName,PortCount,Type,IOGrpCount,Status,SiteID,SiteName,HostStateInfo,HostClusterID,HostClusterName,Protocol,StatusPolicy,StatusSite,`
                                    WWPNOne,NodeLoggedInCountOne,StateOne,WWPNTwo,NodeLoggedInCountTwo,StateTwo,WWPNThree,NodeLoggedInCountThree,StateThree,WWPNFour,NodeLoggedInCountFour,StateFour,`
                                    OwnerID,OwnerName,PortsetID,PortsetName,PartitionID,PartitionName,Location1Status,Location2Status,DraftPartitionID,DraftPartitionName,UngroupedVolumeMapping,`
                                    AutoStorageDiscovery,LocationSystemName,AuthMethod,HostUsername,StorageUsername,HostSecret,StorageSecret,OfflineAlertSuppressed,WWNN,SerialNumber,STOName,SideName
            $TD_HostBaseTemp.ID                 = $TD_HostIDInformation.id
            $TD_HostBaseTemp.HostName           = $TD_HostIDInformation.name
            $TD_HostBaseTemp.PortCount          = $TD_HostIDInformation.port_count
            #$TD_HostBaseTemp.Type               = $TD_HostIDInformation.type
            $TD_HostBaseTemp.IOGrpCount         = $TD_HostIDInformation.iogrp_count
            $TD_HostBaseTemp.Status             = $TD_HostIDInformation.status
            $HostCheckResult = STO_HostStateInfo -STOWWN $IBMSTOWWNN -STOSN $IBMSTOSN -STOHostID $($TD_HostIDInformation.id) -STOHostStatus $($TD_HostIDInformation.status)
            $TD_HostBaseTemp.HostStateInfo      = $HostCheckResult.CheckResult
            $TD_HostBaseTemp.SiteID             = $TD_HostIDInformation.site_id
            $TD_HostBaseTemp.SiteName           = $TD_HostIDInformation.site_name
            $TD_HostBaseTemp.HostClusterID      = $TD_HostIDInformation.host_cluster_id
            $TD_HostBaseTemp.HostClusterName    = $TD_HostIDInformation.host_cluster_name
            $TD_HostBaseTemp.Protocol           = $TD_HostIDInformation.protocol
            $TD_HostBaseTemp.StatusPolicy       = $TD_HostIDInformation.status_policy
            $TD_HostBaseTemp.StatusSite         = $TD_HostIDInformation.status_site

            for ($nbr = 0; $nbr -lt $($TD_HostIDInformation.nodes).count; $nbr++) {
                if($nbr -eq 0){
                    $TD_HostBaseTemp.WWPNOne                = $TD_HostIDInformation.nodes.WWPN[$nbr]
                    $TD_HostBaseTemp.NodeLoggedInCountOne   = $TD_HostIDInformation.nodes.node_logged_in_count[$nbr]
                    $TD_HostBaseTemp.StateOne               = $TD_HostIDInformation.nodes.state[$nbr]
                }elseif ($nbr -eq 1) {
                    $TD_HostBaseTemp.WWPNTwo                = $TD_HostIDInformation.nodes.WWPN[$nbr]
                    $TD_HostBaseTemp.NodeLoggedInCountTwo   = $TD_HostIDInformation.nodes.node_logged_in_count[$nbr]
                    $TD_HostBaseTemp.StateTwo               = $TD_HostIDInformation.nodes.state[$nbr]
                }elseif ($nbr -eq 2) {
                    $TD_HostBaseTemp.WWPNThree              = $TD_HostIDInformation.nodes.WWPN[$nbr]
                    $TD_HostBaseTemp.NodeLoggedInCountThree = $TD_HostIDInformation.nodes.node_logged_in_count[$nbr]
                    $TD_HostBaseTemp.StateThree             = $TD_HostIDInformation.nodes.state[$nbr]
                }elseif ($nbr -eq 3) {
                    $TD_HostBaseTemp.WWPNFour               = $TD_HostIDInformation.nodes.WWPN[$nbr]
                    $TD_HostBaseTemp.NodeLoggedInCountFour  = $TD_HostIDInformation.nodes.node_logged_in_count[$nbr]
                    $TD_HostBaseTemp.StateFour              = $TD_HostIDInformation.nodes.state[$nbr]
                }
            }
            $TD_HostBaseTemp.OwnerID           = $TD_HostIDInformation.owner_id
            $TD_HostBaseTemp.OwnerName         = $TD_HostIDInformation.owner_name
            $TD_HostBaseTemp.PortsetID         = $TD_HostIDInformation.portset_id
            $TD_HostBaseTemp.PortsetName       = $TD_HostIDInformation.portset_name
            $TD_HostBaseTemp.PartitionID       = $TD_HostIDInformation.partition_id
            $TD_HostBaseTemp.PartitionName     = $TD_HostIDInformation.partition_name
            $TD_HostBaseTemp.Location1Status   = $TD_HostIDInformation.location1_status
            $TD_HostBaseTemp.Location2Status   = $TD_HostIDInformation.location2_status
            $TD_HostBaseTemp.DraftPartitionID = $TD_HostIDInformation.draft_partition_id
            $TD_HostBaseTemp.DraftPartitionName       = $TD_HostIDInformation.draft_partition_name
            $TD_HostBaseTemp.UngroupedVolumeMapping   = $TD_HostIDInformation.ungrouped_volume_mapping
            $TD_HostBaseTemp.AutoStorageDiscovery     = $TD_HostIDInformation.auto_storage_discovery
            $TD_HostBaseTemp.LocationSystemName       = $TD_HostIDInformation.location_system_name
            $TD_HostBaseTemp.AuthMethod        = $TD_HostIDInformation.auth_method
            $TD_HostBaseTemp.HostUsername      = $TD_HostIDInformation.host_username
            $TD_HostBaseTemp.StorageUsername   = $TD_HostIDInformation.storage_username
            $TD_HostBaseTemp.HostSecret        = $TD_HostIDInformation.host_secret
            $TD_HostBaseTemp.StorageSecret     = $TD_HostIDInformation.storage_secret
            $TD_HostBaseTemp.OfflineAlertSuppressed   = $TD_HostIDInformation.offline_alert_suppressed

            $TD_HostBaseTemp.WWNN = $IBMSTOWWNN
            $TD_HostBaseTemp.SerialNumber = $IBMSTOSN
            $TD_HostBaseTemp.RowID = "$IBMSTOSN|$($TD_HostBaseTemp.ID)"
            $TD_HostBaseTemp.STOName = $STOSystemInfo.name
            $TD_HostBaseTemp.SideName = $IBMSTOSideName

            $TD_HostBaseTemp

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($IBMSTOSN)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        SST_CustomerSTODBInsertTable -SST_InfoType "StorageHostInfo" -SST_CollectedInformations $CollectedHostInfo
        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $CollectedHostInfo | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $CollectedHostInfo | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_IBM_HostInfo_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $CollectedHostInfo
        }
        return $CollectedHostInfo 
    }
}