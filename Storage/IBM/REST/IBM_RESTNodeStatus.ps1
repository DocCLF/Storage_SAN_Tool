function IBM_RESTNodeStatus {
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
            #$TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsuser -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
    }

    process{
        [int]$imax = $STONodeInfo.Count
        for ($i = 0; $i -le $imax; $i++) {
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsnodestatus/$STONodeInfo.id[$i] -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            [int]$nbrmax = $TD_DeviceInformation.Count
            [array]$TD_NodeStatusResault = for ($nbr = 0; $nbr -le $nbrmax; $nbr++) {
                $NodeStatus = "" | Select-Object ID,User_Name,Password,SSH_Key,Remote,UserGrp_ID,UserGrp_Name,Owner_ID,Owner_Name,Locked,PW_Change_required,WWNN,SerialNumber

                $NodeStatus.ID                 = $TD_DeviceInformation.cluster_id[$nbr]
                $NodeStatus.User_Name          = $TD_DeviceInformation.cluster_name[$nbr]
                $NodeStatus.Password           = $TD_DeviceInformation.cluster_status[$nbr]
                $NodeStatus.SSH_Key            = $TD_DeviceInformation.cluster_ip_count[$nbr]
                for ($clnbr = 0; $clnbr -lt $($TD_DeviceInformation.clusters).count; $clnbr++) {
                    if($clnbr -eq 0){
                        $NodeStatus.WWPNOne                = $TD_DeviceInformation.clusters.cluster_port[$clnbr]
                        $NodeStatus.NodeLoggedInCountOne   = $TD_DeviceInformation.clusters.cluster_ip[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.clusters.cluster_gw[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.clusters.cluster_mask[$clnbr]
                    }elseif ($clnbr -eq 1) {
                        $NodeStatus.WWPNTwo                = $TD_DeviceInformation.clusters.cluster_port[$clnbr]
                        $NodeStatus.NodeLoggedInCountTwo   = $TD_DeviceInformation.clusters.cluster_ip[$clnbr]
                        $NodeStatus.StateTwo               = $TD_DeviceInformation.clusters.cluster_gw[$clnbr]
                        $NodeStatus.StateTwo               = $TD_DeviceInformation.clusters.cluster_mask[$clnbr]
                    }elseif ($clnbr -eq 2) {
                        $NodeStatus.WWPNThree                = $TD_DeviceInformation.clusters.cluster_port[$clnbr]
                        $NodeStatus.NodeLoggedInCountThree   = $TD_DeviceInformation.clusters.cluster_ip[$clnbr]
                        $NodeStatus.StateThree               = $TD_DeviceInformation.clusters.cluster_gw[$clnbr]
                        $NodeStatus.StateThree               = $TD_DeviceInformation.clusters.cluster_mask[$clnbr]
                    }elseif ($clnbr -eq 3) {
                        $NodeStatus.WWPNFour                = $TD_DeviceInformation.clusters.cluster_port[$clnbr]
                        $NodeStatus.NodeLoggedInCountFour   = $TD_DeviceInformation.clusters.cluster_ip[$clnbr]
                        $NodeStatus.StateFour               = $TD_DeviceInformation.clusters.cluster_gw[$clnbr]
                        $NodeStatus.StateFour               = $TD_DeviceInformation.clusters.cluster_mask[$clnbr]
                    }
                }
                $NodeStatus.Remote             = $TD_DeviceInformation.node_id[$i]
                $NodeStatus.UserGrp_ID         = $TD_DeviceInformation.node_name[$i]
                $NodeStatus.UserGrp_Name       = $TD_DeviceInformation.node_status[$i]
                $NodeStatus.Owner_ID           = $TD_DeviceInformation.config_node[$i]
                $NodeStatus.Owner_Name         = $TD_DeviceInformation.hardware[$i]
                $NodeStatus.Locked             = $TD_DeviceInformation.service_IP_address[$i]
                $NodeStatus.Remote             = $TD_DeviceInformation.service_gateway[$i]
                $NodeStatus.UserGrp_ID         = $TD_DeviceInformation.service_subnet_mask[$i]
                $NodeStatus.UserGrp_Name       = $TD_DeviceInformation.node_code_version[$i]
                $NodeStatus.Owner_ID           = $TD_DeviceInformation.node_code_build[$i]
                $NodeStatus.Owner_Name         = $TD_DeviceInformation.cluster_code_build[$i]
                $NodeStatus.Locked             = $TD_DeviceInformation.node_error_count[$i]
                $NodeStatus.PW_Change_required = $TD_DeviceInformation.fc_ports[$i]
                for ($clnbr = 0; $clnbr -lt $($TD_DeviceInformation.ports).count; $clnbr++) {
                    if($clnbr -eq 0){
                        $NodeStatus.WWPNOne                = $TD_DeviceInformation.ports.port_id[$clnbr]
                        $NodeStatus.NodeLoggedInCountOne   = $TD_DeviceInformation.ports.port_status[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_speed[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_WWPN[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.SFP_type[$clnbr]
                    }elseif ($clnbr -eq 1) {
                        $NodeStatus.WWPNOne                = $TD_DeviceInformation.ports.port_id[$clnbr]
                        $NodeStatus.NodeLoggedInCountOne   = $TD_DeviceInformation.ports.port_status[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_speed[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_WWPN[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.SFP_type[$clnbr]
                    }elseif ($clnbr -eq 2) {
                        $NodeStatus.WWPNOne                = $TD_DeviceInformation.ports.port_id[$clnbr]
                        $NodeStatus.NodeLoggedInCountOne   = $TD_DeviceInformation.ports.port_status[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_speed[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_WWPN[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.SFP_type[$clnbr]
                    }elseif ($clnbr -eq 3) {
                        $NodeStatus.WWPNOne                = $TD_DeviceInformation.ports.port_id[$clnbr]
                        $NodeStatus.NodeLoggedInCountOne   = $TD_DeviceInformation.ports.port_status[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_speed[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.port_WWPN[$clnbr]
                        $NodeStatus.StateOne               = $TD_DeviceInformation.ports.SFP_type[$clnbr]
                    }
                }
                $NodeStatus

                <# Progressbar  #>
                $ProgCounter++
                Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
            }
        }
    }
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_NodeStatusResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_TD_NodeStatusResault_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_TD_NodeStatusResault_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_NodeStatusResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_TD_NodeStatusResault_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_TD_NodeStatusResault_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_NodeStatusResault
        }
        return $TD_NodeStatusResault
    }
}

<#
https://192.168.107.35:7443/rest/v1/lsnodestatus/1
{
  "panel_name": "01-2",
  "cluster_id": "00000204a00064c8",
  "cluster_name": "FS5200_RZ2",
  "cluster_status": "Active",
  "cluster_ip_count": "2",
  "clusters": [
    {
      "cluster_port": "1",
      "cluster_ip": "192.168.107.35",
      "cluster_gw": "192.168.107.1",
      "cluster_mask": "255.255.255.0",
      "cluster_ip_6": "",
      "cluster_gw_6": "",
      "cluster_prefix_6": ""
    },
    {
      "cluster_port": "2",
      "cluster_ip": "",
      "cluster_gw": "",
      "cluster_mask": "",
      "cluster_ip_6": "",
      "cluster_gw_6": "",
      "cluster_prefix_6": ""
    }
  ],
  "node_id": "1",
  "node_name": "node1",
  "node_status": "Active",
  "config_node": "No",
  "hardware": "6H2",
  "service_IP_address": "192.168.107.37",
  "service_gateway": "192.168.107.1",
  "service_subnet_mask": "255.255.255.0",
  "service_IP_address_6": "",
  "service_gateway_6": "",
  "service_prefix_6": "",
  "node_code_version": "8.6.0.8",
  "node_code_build": "169.28.2507011701000",
  "cluster_code_build": "169.28.2507011701000",
  "node_error_count": "0",
  "fc_ports": "4",
  "ports": [
    {
      "port_id": "1",
      "port_status": "Active",
      "port_speed": "32Gb",
      "port_WWPN": "5005076812113264",
      "SFP_type": "Short-wave"
    },
    {
      "port_id": "2",
      "port_status": "Active",
      "port_speed": "32Gb",
      "port_WWPN": "5005076812123264",
      "SFP_type": "Short-wave"
    },
    {
      "port_id": "3",
      "port_status": "Inactive",
      "port_speed": "N/A",
      "port_WWPN": "5005076812133264",
      "SFP_type": "N/A"
    },
    {
      "port_id": "4",
      "port_status": "Inactive",
      "port_speed": "N/A",
      "port_WWPN": "5005076812143264",
      "SFP_type": "N/A"
    }
  ],
  "ethernet_ports": "2",
  "subcollection": [
    {
      "ethernet_port_id": "1",
      "port_status": "Link Online",
      "port_speed": "1Gb/s - Full",
      "MAC": "98:be:94:7d:db:fc",
      "node_IP_address": "",
      "node_gateway": "",
      "node_subnet_mask": "",
      "rdma_type": ""
    },
    {
      "ethernet_port_id": "2",
      "port_status": "Not Configured",
      "port_speed": "",
      "MAC": "98:be:94:7d:db:fd",
      "node_IP_address": "",
      "node_gateway": "",
      "node_subnet_mask": "",
      "rdma_type": ""
    }
  ],
  "product_mtm": "4662-6H2",
  "product_serial": "78F1CZ5",
  "time_to_charge": "0",
  "battery_charging": "100",
  "dump_name": "78F1CZ5-2",
  "node_WWNN": "",
  "disk_WWNN_suffix": "",
  "panel_WWNN_suffix": "",
  "UPS_serial_number": "",
  "UPS_status": "",
  "enclosure_WWNN_1": "5005076812003263",
  "enclosure_WWNN_2": "5005076812003264",
  "node_part_identity": "11S02YJ105YS14UE33505X",
  "node_FRU_part": "03JK828",
  "enclosure_identity": "11S02YJ103YS12UE32T025",
  "PSU_count": "0",
  "PSU_ids": [
    {
      "PSU_id": "1",
      "PSU_status": ""
    },
    {
      "PSU_id": "2",
      "PSU_status": ""
    }
  ],
  "Battery_count": "1",
  "Battery_id": "1",
  "Battery_status": "active",
  "Battery_FRU_part": "03GH753",
  "Battery_part_identity": "11S02YJ112YS10ZR2AR1H9",
  "Battery_fault_led": "off",
  "Battery_charging_status": "charged",
  "Battery_cycle_count": "30",
  "Battery_power_on_hours": "0",
  "Battery_last_recondition": "",
  "node_location_copy": "2",
  "node_product_mtm_copy": "4662-6H2",
  "node_product_serial_copy": "78F1CZ5",
  "node_WWNN_1_copy": "5005076812003263",
  "node_WWNN_2_copy": "5005076812003264",
  "latest_cluster_id": "204a00064c8",
  "next_cluster_id": "204a02064c8",
  "console_IP": "192.168.107.35:443",
  "has_nas_key": "no",
  "fc_io_ports": "4",
  "fcs": [
    {
      "fc_io_port_id": "1",
      "fc_io_port_WWPN": "5005076812113264",
      "fc_io_port_switch_WWPN": "200c38bab028e9c0",
      "fc_io_port_state": "Active",
      "fc_io_port_FCF_MAC": "N/A",
      "fc_io_port_vlanid": "N/A",
      "fc_io_port_type": "FC",
      "fc_io_port_type_port_id": "1"
    },
    {
      "fc_io_port_id": "2",
      "fc_io_port_WWPN": "5005076812123264",
      "fc_io_port_switch_WWPN": "200838bab0293e70",
      "fc_io_port_state": "Active",
      "fc_io_port_FCF_MAC": "N/A",
      "fc_io_port_vlanid": "N/A",
      "fc_io_port_type": "FC",
      "fc_io_port_type_port_id": "2"
    },
    {
      "fc_io_port_id": "3",
      "fc_io_port_WWPN": "5005076812133264",
      "fc_io_port_switch_WWPN": "0000000000000000",
      "fc_io_port_state": "Inactive",
      "fc_io_port_FCF_MAC": "N/A",
      "fc_io_port_vlanid": "N/A",
      "fc_io_port_type": "FC",
      "fc_io_port_type_port_id": "3"
    },
    {
      "fc_io_port_id": "4",
      "fc_io_port_WWPN": "5005076812143264",
      "fc_io_port_switch_WWPN": "0000000000000000",
      "fc_io_port_state": "Inactive",
      "fc_io_port_FCF_MAC": "N/A",
      "fc_io_port_vlanid": "N/A",
      "fc_io_port_type": "FC",
      "fc_io_port_type_port_id": "4"
    }
  ],
  "service_IP_mode": "static",
  "service_IP_mode_6": "",
  "machine_part_number": "",
  "node_machine_part_number_copy": "",
  "local_fc_port_mask": "1111111111111111111111111111111111111111111111111111111111111111",
  "partner_fc_port_mask": "1111111111111111111111111111111111111111111111111111111111111111",
  "topology": "standard",
  "site_id": "",
  "site_name": "",
  "password_reset_enabled": "yes",
  "identify_LED": "off",
  "Battery_midplane_FRU_part": "",
  "Battery_midplane_part_identity": "",
  "Battery_midplane_FW_version": "",
  "Battery_power_cable_FRU_part": "",
  "Battery_power_sense_cable_FRU_part": "",
  "Battery_comms_cable_FRU_part": "",
  "Battery_EPOW_cable_FRU_part": "",
  "product_name": "IBM FlashSystem 5200",
  "techport": "permanent",
  "node_usb": "on",
  "superuser_locked": "no",
  "superuser_multi_factor": "no",
  "superuser_password_sshkey_required": "no",
  "superuser_gui_disabled": "yes",
  "superuser_rest_disabled": "yes",
  "superuser_cim_disabled": "no",
  "patch_count": "0",
  "system_cos": "0"
}
#>