function IBM_RESTSystemInfo {
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lssystem -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
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
        $IBM_STOSysInfos =[ordered]@{}
        $IBM_STOSysInfos.Add('ID',$TD_DeviceInformation.id)
        $IBM_STOSysInfos.Add('Name',$TD_DeviceInformation.name)
        $IBM_STOSysInfos.Add('Location',$TD_DeviceInformation.location)
        $IBM_STOSysInfos.Add('Partnership',$TD_DeviceInformation.partnership)
        $IBM_STOSysInfos.Add('MDiskTotalCapacity',$TD_DeviceInformation.total_mdisk_capacity)
        $IBM_STOSysInfos.Add('SpaceinMdiskGrps',$TD_DeviceInformation.space_in_mdisk_grps)
        $IBM_STOSysInfos.Add('MDiskUsedCapacity',$TD_DeviceInformation.space_allocated_to_vdisks)
        $IBM_STOSysInfos.Add('TotalFreeSpace',$TD_DeviceInformation.total_free_space)
        $IBM_STOSysInfos.Add('TotalVdiskcopyCapacity',$TD_DeviceInformation.total_vdiskcopy_capacity)
        $IBM_STOSysInfos.Add('TotalUsedCapacity',$TD_DeviceInformation.total_used_capacity)
        $IBM_STOSysInfos.Add('TotalOverallocation',$TD_DeviceInformation.total_overallocation)
        $IBM_STOSysInfos.Add('TotalVdiskCapacity',$TD_DeviceInformation.total_vdisk_capacity)
        $IBM_STOSysInfos.Add('TotalAllocatedExtentCapacity',$TD_DeviceInformation.total_allocated_extent_capacity)
        $IBM_STOSysInfos.Add('StatisticsStatus',$TD_DeviceInformation.statistics_status)
        $IBM_STOSysInfos.Add('StatisticsFrequency',$TD_DeviceInformation.statistics_frequency)
        $IBM_STOSysInfos.Add('ClusterLocale',$TD_DeviceInformation.cluster_locale)
        $IBM_STOSysInfos.Add('TimeZone',$TD_DeviceInformation.time_zone)
        $IBM_STOSysInfos.Add('CodeLevel',$TD_DeviceInformation.code_level)
        $IBM_STOSysInfos.Add('ConsoleIP',$TD_DeviceInformation.console_IP)
        $IBM_STOSysInfos.Add('IDAlias',$TD_DeviceInformation.id_alias)
        $IBM_STOSysInfos.Add('GMLinkTolerance',$TD_DeviceInformation.gm_link_tolerance)
        $IBM_STOSysInfos.Add('GMInterClusterDelaySimulation',$TD_DeviceInformation.gm_inter_cluster_delay_simulation)
        $IBM_STOSysInfos.Add('GMIntraClusterDelaySimulation',$TD_DeviceInformation.gm_intra_cluster_delay_simulation)
        $IBM_STOSysInfos.Add('GMmaxHostDelay',$TD_DeviceInformation.gm_max_host_delay)
        $IBM_STOSysInfos.Add('EmailReply',$TD_DeviceInformation.email_reply)
        $IBM_STOSysInfos.Add('EmailContact',$TD_DeviceInformation.email_contact)
        $IBM_STOSysInfos.Add('EmailContactPrimary',$TD_DeviceInformation.email_contact_primary)
        $IBM_STOSysInfos.Add('EmailContactAlternate',$TD_DeviceInformation.email_contact_alternate)
        $IBM_STOSysInfos.Add('EmailContactLocation',$TD_DeviceInformation.email_contact_location)
        $IBM_STOSysInfos.Add('EmailContact2',$TD_DeviceInformation.email_contact2)
        $IBM_STOSysInfos.Add('EmailContact2Primary',$TD_DeviceInformation.email_contact2_primary)
        $IBM_STOSysInfos.Add('EmailContact2Alternate',$TD_DeviceInformation.email_contact2_alternate)
        $IBM_STOSysInfos.Add('EmailState',$TD_DeviceInformation.email_state)
        $IBM_STOSysInfos.Add('InventoryMailInterval',$TD_DeviceInformation.inventory_mail_interval)
        $IBM_STOSysInfos.Add('ClusterNTPIP',$TD_DeviceInformation.cluster_ntp_IP_address)
        $IBM_STOSysInfos.Add('ClusterIsnsIP',$TD_DeviceInformation.cluster_isns_IP_address)
        $IBM_STOSysInfos.Add('ISCSiAuthMethod',$TD_DeviceInformation.iscsi_auth_method)
        $IBM_STOSysInfos.Add('ISCSiChapSecret',$TD_DeviceInformation.iscsi_chap_secret)
        $IBM_STOSysInfos.Add('AuthServiceConfigured',$TD_DeviceInformation.auth_service_configured)
        $IBM_STOSysInfos.Add('AuthServiceEnabled',$TD_DeviceInformation.auth_service_enabled)
        $IBM_STOSysInfos.Add('AuthServiceURL',$TD_DeviceInformation.auth_service_url)
        $IBM_STOSysInfos.Add('AuthServiceUserName',$TD_DeviceInformation.auth_service_user_name)
        $IBM_STOSysInfos.Add('AuthServicePWDset',$TD_DeviceInformation.auth_service_pwd_set)
        $IBM_STOSysInfos.Add('AuthServiceCertset',$TD_DeviceInformation.auth_service_cert_set)
        $IBM_STOSysInfos.Add('AuthServiceType',$TD_DeviceInformation.auth_service_type)
        $IBM_STOSysInfos.Add('RelationshipBandwidthLimit',$TD_DeviceInformation.relationship_bandwidth_limit)
        $IBM_STOSysInfos.Add('EasyTierAcceleration',$TD_DeviceInformation.easy_tier_acceleration)
        $IBM_STOSysInfos.Add('HasNASkey',$TD_DeviceInformation.has_nas_key)
        $IBM_STOSysInfos.Add('Layer',$TD_DeviceInformation.layer)
        $IBM_STOSysInfos.Add('RCBufferSize',$TD_DeviceInformation.rc_buffer_size)
        $IBM_STOSysInfos.Add('CompressionActive',$TD_DeviceInformation.compression_active)
        $IBM_STOSysInfos.Add('CompressionVirtualCapacity',$TD_DeviceInformation.compression_virtual_capacity)
        $IBM_STOSysInfos.Add('CompressionCompressedCapacity',$TD_DeviceInformation.compression_compressed_capacity)
        $IBM_STOSysInfos.Add('CompressionUncompressedCapacity',$TD_DeviceInformation.compression_uncompressed_capacity)
        $IBM_STOSysInfos.Add('CachePrefetch',$TD_DeviceInformation.cache_prefetch)
        $IBM_STOSysInfos.Add('EmailOrganization',$TD_DeviceInformation.email_organization)
        $IBM_STOSysInfos.Add('EmailMachineAddress',$TD_DeviceInformation.email_machine_address)
        $IBM_STOSysInfos.Add('EmailMachineCity',$TD_DeviceInformation.email_machine_city)
        $IBM_STOSysInfos.Add('EmailMachineState',$TD_DeviceInformation.email_machine_state)
        $IBM_STOSysInfos.Add('EmailMachineZip',$TD_DeviceInformation.email_machine_zip)
        $IBM_STOSysInfos.Add('EmailMachineCountry',$TD_DeviceInformation.email_machine_country)
        $IBM_STOSysInfos.Add('EmailFrom',$TD_DeviceInformation.email_from)
        $IBM_STOSysInfos.Add('TotalDriveRawCapacity',$TD_DeviceInformation.total_drive_raw_capacity)
        $IBM_STOSysInfos.Add('CompressionDestageMode',$TD_DeviceInformation.compression_destage_mode)
        $IBM_STOSysInfos.Add('LocalFCPortMask',$TD_DeviceInformation.local_fc_port_mask)
        $IBM_STOSysInfos.Add('PartnerFCPortMask',$TD_DeviceInformation.partner_fc_port_mask)
        $IBM_STOSysInfos.Add('HighTempMode',$TD_DeviceInformation.high_temp_mode)
        $IBM_STOSysInfos.Add('Topology',$TD_DeviceInformation.topology)
        $IBM_STOSysInfos.Add('TopologyStatus',$TD_DeviceInformation.topology_status)
        $IBM_STOSysInfos.Add('RCAuthMethod',$TD_DeviceInformation.rc_auth_method)
        $IBM_STOSysInfos.Add('VdiskProtectionTime',$TD_DeviceInformation.vdisk_protection_time)
        $IBM_STOSysInfos.Add('VdiskProtectionEnabled',$TD_DeviceInformation.vdisk_protection_enabled)
        $IBM_STOSysInfos.Add('ProductName',$TD_DeviceInformation.product_name)
        $IBM_STOSysInfos.Add('ODX',$TD_DeviceInformation.odx)
        $IBM_STOSysInfos.Add('MaxReplicationDelay',$TD_DeviceInformation.max_replication_delay)
        $IBM_STOSysInfos.Add('PartnershipExclusionThreshold',$TD_DeviceInformation.partnership_exclusion_threshold)
        $IBM_STOSysInfos.Add('Gen1CompatibilityModeEnabled',$TD_DeviceInformation.gen1_compatibility_mode_enabled)
        $IBM_STOSysInfos.Add('IBMCustomer',$TD_DeviceInformation.ibm_customer)
        $IBM_STOSysInfos.Add('IBMComponent',$TD_DeviceInformation.ibm_component)
        $IBM_STOSysInfos.Add('IBMCountry',$TD_DeviceInformation.ibm_country)
        $IBM_STOSysInfos.Add('TierSCMCompressedDataUsed',$TD_DeviceInformation.tier_scm_compressed_data_used)
        $IBM_STOSysInfos.Add('Tier0FlashCompressedDataUsed',$TD_DeviceInformation.tier0_flash_compressed_data_used)
        $IBM_STOSysInfos.Add('Tier1FlashCompressedDataUsed',$TD_DeviceInformation.tier1_flash_compressed_data_used)
        $IBM_STOSysInfos.Add('TierEnterpriseCompressedDataUsed',$TD_DeviceInformation.tier_enterprise_compressed_data_used)
        $IBM_STOSysInfos.Add('TierNearlineCompressedDataUsed',$TD_DeviceInformation.tier_nearline_compressed_data_used)
        $IBM_STOSysInfos.Add('TotalReclaimableCapacity',$TD_DeviceInformation.total_reclaimable_capacity)
        $IBM_STOSysInfos.Add('PhysicalTotalCapacity',$TD_DeviceInformation.physical_capacity)
        $IBM_STOSysInfos.Add('PhysicalFreeCapacity',$TD_DeviceInformation.physical_free_capacity)
        $IBM_STOSysInfos.Add('UsedCapacityBeforeReduction',$TD_DeviceInformation.used_capacity_before_reduction)
        $IBM_STOSysInfos.Add('UsedCapacityAfterReduction',$TD_DeviceInformation.used_capacity_after_reduction)
        $IBM_STOSysInfos.Add('OverheadCapacity',$TD_DeviceInformation.overhead_capacity)
        $IBM_STOSysInfos.Add('DeduplicationCapacitySaving',$TD_DeviceInformation.deduplication_capacity_saving)
        $IBM_STOSysInfos.Add('EnhancedCallhome',$TD_DeviceInformation.enhanced_callhome)
        $IBM_STOSysInfos.Add('CensorCallhome',$TD_DeviceInformation.censor_callhome)
        $IBM_STOSysInfos.Add('HostUnmap',$TD_DeviceInformation.host_unmap)
        $IBM_STOSysInfos.Add('BackendUnmap',$TD_DeviceInformation.backend_unmap)
        $IBM_STOSysInfos.Add('QuorumMode',$TD_DeviceInformation.quorum_mode)
        $IBM_STOSysInfos.Add('QuorumSiteID',$TD_DeviceInformation.quorum_site_id)
        $IBM_STOSysInfos.Add('QuorumSiteName',$TD_DeviceInformation.quorum_site_name)
        $IBM_STOSysInfos.Add('QuorumLease',$TD_DeviceInformation.quorum_lease)
        $IBM_STOSysInfos.Add('AutomaticVdiskAnalysisEnabled',$TD_DeviceInformation.automatic_vdisk_analysis_enabled)
        $IBM_STOSysInfos.Add('CallhomeAcceptedUsage',$TD_DeviceInformation.callhome_accepted_usage)
        $IBM_STOSysInfos.Add('SafeguardedCopySuspended',$TD_DeviceInformation.safeguarded_copy_suspended)
        $IBM_STOSysInfos.Add('ProtectionProvisionedCapacity',$TD_DeviceInformation.protection_provisioned_capacity)
        $IBM_STOSysInfos.Add('ProtectionWrittenCapacity',$TD_DeviceInformation.protection_written_capacity)
        $IBM_STOSysInfos.Add('FlashcopyGuiEnabled',$TD_DeviceInformation.flashcopy_gui_enabled)
        $IBM_STOSysInfos.Add('SnapshotPolicySuspended',$TD_DeviceInformation.snapshot_policy_suspended)
        $IBM_STOSysInfos.Add('SnapshotPreserveParent',$TD_DeviceInformation.snapshot_preserve_parent)
        $IBM_STOSysInfos.Add('WWNN',$IBMSTOWWNN)
        $IBM_STOSysInfos.Add('SerialNumber',$IBMSTOSN)
    }
    
    end {
        
        return $IBM_STOSysInfos
    }
}
