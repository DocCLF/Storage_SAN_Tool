function SST_MainHealthCheckFunc {
    [CmdletBinding()]
    param (
       
    )
    
    begin {
        $ErrorActionPreference="Continue"
        try {
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource |Where-Object {$_.DeviceTyp -eq "Storage"}
            SST_ToolMessageCollector -TD_ToolMSGCollector $TD_Credentials.DeviceTyp -TD_ToolMSGType Message -TD_Shown no
            $TD_Credentials | ForEach-Object {
                if(($_.ID -eq 1)-and ($TD_cb_Device_HealthCheck.Text -like "*First")) {
                    $Temp_Credentials = $_ 
                    $TD_TB_storageIPAdrOne.Text ="$($_.IPAddress)"
                    $TD_btn_HC_OpenGUI_One.Content = $_.DeviceName
                    $TD_btn_HC_OpenGUI_One.Background = "LightGreen"
                }
                if(($_.ID -eq 2)-and ($TD_cb_Device_HealthCheck.Text -like "*Second")) {
                    $Temp_Credentials = $_ 
                    $TD_TB_storageIPAdrTwo.Text ="$($_.IPAddress)"
                    $TD_btn_HC_OpenGUI_Two.Content = $_.DeviceName
                    $TD_btn_HC_OpenGUI_Two.Background = "LightGreen"
                }
                if(($_.ID -eq 3)-and ($TD_cb_Device_HealthCheck.Text -like "*Third")) {
                    $Temp_Credentials = $_ 
                    $TD_TB_storageIPAdrThree.Text ="$($_.IPAddress)"
                    $TD_btn_HC_OpenGUI_Three.Content = $_.DeviceName
                    $TD_btn_HC_OpenGUI_Three.Background = "LightGreen"
                }
                if(($_.ID -eq 4)-and ($TD_cb_Device_HealthCheck.Text -like "*Fourth")) {
                    $Temp_Credentials = $_ 
                    $TD_TB_storageIPAdrFour.Text ="$($_.IPAddress)"
                    $TD_btn_HC_OpenGUI_Four.Content =  $_.DeviceName
                    $TD_btn_HC_OpenGUI_Four.Background = "LightGreen"
                }
            }            
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes       
        }

    }
    
    process {
        $TD_DeviceManufacturer = "IBM"
        switch ($TD_DeviceManufacturer) {
            "IBM" 
                {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Starting HealthCheck for IP: $($Temp_Credentials.IPAddress) with Name: $($Temp_Credentials.DeviceName)" -TD_ToolMSGType Message -TD_Shown yes
                    $TD_lb_CurrentSpectVirtFW.Visibility="Visible"
                    $TD_lb_CurrentSpectVirtFW.Content="No Info"
                    try {
                        $TD_SpectrVirtuFWInfos = IBM_StorageSWCheck -IBM_CurrentSpectrVirtuFW $Temp_Credentials.MTMCode
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HealthCheck used this FW $($Temp_Credentials.MTMCode)" -TD_ToolMSGType Debug -TD_Shown no
                        SST_ToolMessageCollector -TD_ToolMSGCollector "And this was Found`$($TD_SpectrVirtuFWInfos)" -TD_ToolMSGType Debug -TD_Shown no                        
                    }
                    catch {
                        SST_ToolMessageCollector $_.Exception.Message -TD_ToolMSGType Error -TD_Shown yes
                    }

                    $TD_lb_MinimumPTF.Content = $TD_SpectrVirtuFWInfos.MinimumPTF
                    $TD_lb_RecommendedPTF.Content = $TD_SpectrVirtuFWInfos.RecommendedPTF
                    $TD_lb_LatestPTF.Content = $TD_SpectrVirtuFWInfos.LatestPTF
                    $TD_lb_MinimumDate.Content = $TD_SpectrVirtuFWInfos.MinimumPTFDate
                    $TD_lb_RecommendedDate.Content = $TD_SpectrVirtuFWInfos.RecommendedPTFDate
                    $TD_lb_LatestDate.Content = $TD_SpectrVirtuFWInfos.LatestPTFDate
                    if($null -ne $TD_SpectrVirtuFWInfos.MinimumPTF){
                        $TD_lb_MinimumHL.Visibility="Visible"
                        $TD_lb_RecommendedHL.Visibility="Visible"
                        $TD_lb_LatestHL.Visibility="Visible"
                        $TD_lb_MinimumPTF.Visibility="Visible"
                        $TD_lb_RecommendedPTF.Visibility="Visible"
                        $TD_lb_LatestPTF.Visibility="Visible"
                        $TD_lb_MinimumDate.Visibility="Visible"
                        $TD_lb_RecommendedDate.Visibility="Visible"
                        $TD_lb_LatestDate.Visibility="Visible"
                        $TD_lb_CurrentSpectVirtFW.Content = "Your current PTF is Version $TD_SpectVirtCode_Level"
                        $TD_lb_CurrentSpectVirtFW.Background="LightGreen"
                        $TD_lb_SpectVirtFWIfno.Background="green"
                    }else {
                        $TD_lb_MinimumHL.Visibility="Collapsed"
                        $TD_lb_RecommendedHL.Visibility="Collapsed"
                        $TD_lb_LatestHL.Visibility="Collapsed"
                        $TD_lb_MinimumPTF.Visibility="Collapsed"
                        $TD_lb_RecommendedPTF.Visibility="Collapsed"
                        $TD_lb_LatestPTF.Visibility="Collapsed"
                        $TD_lb_MinimumDate.Visibility="Collapsed"
                        $TD_lb_RecommendedDate.Visibility="Collapsed"
                        $TD_lb_LatestDate.Visibility="Collapsed"
                        $TD_lb_CurrentSpectVirtFW.Content = "Your current PTF Version $TD_SpectVirtCode_Level is out of Service!!"
                        $TD_lb_CurrentSpectVirtFW.Background="LightCoral"
                        $TD_lb_SpectVirtFWIfno.Background="red"
                    }
                    $Temp_Credentials | ForEach-Object {
                        #region Storage_HS_Eventlog
                        Write-Host "this is $($_)"
                        [array]$TD_IBM_EventLogCheck = IBM_EventLog -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_Eventlog`n$TD_IBM_EventLogCheck" -TD_ToolMSGType Debug -TD_Shown no
                        $TD_dg_EventlogStatusInfoText.ItemsSource=$EmptyVar
                        if($TD_IBM_EventLogCheck.Status -eq "alert"){
                            $TD_lb_EventlogLight.Background="red"
                            if(($TD_IBM_EventLogCheck | Where-Object {$_.Status -eq "alert"}).Count -ge 2){
                                $TD_dg_EventlogStatusInfoText.ItemsSource=$TD_IBM_EventLogCheck | Where-Object {(($_.Status -eq "alert")-and(($_.Fixed -eq "no")-or($_.Fixed -eq "yes")))} |Select-Object -Last 10
                
                            }else {
                                [array]$TD_OnlyOneEvent = $TD_IBM_EventLogCheck | Where-Object {(($_.Status -eq "alert")-and(($_.Fixed -eq "no")-or($_.Fixed -eq "yes")))}
                                
                                $TD_dg_EventlogStatusInfoText.ItemsSource=$TD_OnlyOneEvent
                            }
                        }elseif (($TD_IBM_EventLogCheck.Status -eq "monitoring")-or($TD_IBM_EventLogCheck.Status -eq "expired")) {
                            $TD_lb_EventlogLight.Background="yellow"
                            $TD_dg_EventlogStatusInfoText.ItemsSource=$TD_IBM_EventLogCheck | Where-Object {(($_.Status -ne "monitoring")-or($_.Status -eq "expired"))}
                        }else {
                            $TD_lb_EventlogLight.Background="green"
                        }
                        #endregion
                        #region Storage_HS_HostCheck
                        [array]$TD_IBM_MDiskCheck = IBM_HostInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"

                        #endregion
                        #region Storage_HS_MDiskCheck
                        [array]$TD_IBM_MDiskCheck    = IBM_MDiskInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_MDiskCheck`n$TD_IBM_MDiskCheck" -TD_ToolMSGType Debug -TD_Shown no
                        $TD_dg_MdiskStatusInfoText.ItemsSource=$EmptyVar
                        if(($TD_IBM_MDiskCheck.Status -eq "offline")-or($TD_IBM_MDiskCheck.Status -eq "excluded")){
                            $TD_lb_MdiskStatusLight.Background ="red"
                            $TD_dg_MdiskStatusInfoText.ItemsSource=$TD_IBM_MDiskCheck
                        }elseif ($TD_IBM_MDiskCheck.Status -like "degraded*") {
                            $TD_lb_MdiskStatusLight.Background ="yellow"
                            $TD_dg_MdiskStatusInfoText.ItemsSource=$TD_IBM_MDiskCheck
                        }elseif (($TD_IBM_MDiskCheck.Status -eq "online").count -eq ($TD_IBM_MDiskCheck.count)){
                            $TD_lb_MdiskStatusLight.Background ="green"
                        }
                        #endregion
                        #region Storage_HS_VolumeCheck
                        [array]$TD_IBM_VolumeCheck   = IBM_VolumeInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_VolumeCheck`n$TD_IBM_VolumeCheck" -TD_ToolMSGType Debug -TD_Shown no
                        $TD_VdiskResault = foreach($TD_VdiskFunc in $TD_IBM_VolumeCheck){
                            if(($TD_VdiskFunc.VolFunc -eq 'master')-or($TD_VdiskFunc.VolFunc -eq 'none')){
                                #Write-Host $_
                                $TD_VdiskFunc
                            }
                        }
                        $TD_dg_VDiskStatusInfoText.ItemsSource=$EmptyVar
                        if((($TD_VdiskResault| Where-Object {$_.Status -eq "offline"}).count) -gt 0){
                            $TD_lb_VDiskStatusLight.Background ="red"
                            if((($TD_VdiskResault| Where-Object {($_.Status -eq "offline")-or($_.Status -eq "deleting")-or($_.Status -eq "degraded")}).count) -ge 2){
                            $TD_dg_VDiskStatusInfoText.ItemsSource= $TD_VdiskResault | Where-Object {(($_.Status -eq "offline")-or($_.Status -eq "deleting")-or($_.Status -eq "degraded"))}
                            }else {
                                $TD_OneVdisk = $TD_VdiskResault | Where-Object {($_.Status -eq "offline")-or($_.Status -eq "deleting")}
                                $TD_dg_VDiskStatusInfoText.ItemsSource= ,$TD_OneVdisk
                            }
                        }elseif ((($TD_VdiskResault| Where-Object {$_.Status -eq "degraded"}).count) -gt 0) {
                            $TD_lb_VDiskStatusLight.Background ="yellow"
                            if((($TD_VdiskResault| Where-Object {$_.Status -eq "degraded"}).count) -ge 2){
                                $TD_dg_VDiskStatusInfoText.ItemsSource= $TD_VdiskResault | Where-Object {($_.Status -eq "degraded")}
                            }else{
                                $TD_OneVdisk = $TD_VdiskResault | Where-Object {($_.Status -eq "degraded")}
                                $TD_dg_VDiskStatusInfoText.ItemsSource= ,$TD_OneVdisk
                            }
                        }elseif ($TD_VdiskResault.Status -eq "online") {
                            $TD_lb_VDiskStatusLight.Background ="green"
                        }
                        #endregion
                        #region Storage_HS_IPQuorumCheck
                        [array]$TD_IBM_IPQuorumCheck = IBM_IPQuorum -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_IPQuorumCheck`n$TD_IBM_IPQuorumCheck" -TD_ToolMSGType Debug -TD_Shown no
                        if(!([String]::IsNullOrEmpty($TD_IBM_IPQuorumCheck))){
                            $TD_lb_QuorumStatusLight.Background ="green"
                            $TD_dg_QuorumStatusInfo.ItemsSource = $TD_IBM_IPQuorumCheck
                        }else{
                            $TD_lb_QuorumStatusLight.Background ="red"
                            $TD_tb_QuorumErrorMsg.Visibility = "Visible"
                            $TD_tb_QuorumErrorMsg.Text = "Your current quorum configuration differs from the default and does not`n seem to have the minimum number of 3 quorum devices, please check this!"
                        }
                        #endregion
                        #region Storage_HS_UserCheck
                        [array]$TD_IBM_UserCheck = IBM_UserInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_UserCheck`n$TD_IBM_UserCheck" -TD_ToolMSGType Debug -TD_Shown no
                        $TD_dg_UserStatusInfoText.ItemsSource=$EmptyVar
                        if(($TD_IBM_UserCheck.PW_Change_required -eq "yes")){
                            $TD_lb_UserStatusLight.Background ="red"
                            $TD_dg_UserStatusInfoText.ItemsSource=$TD_IBM_UserCheck
                        }elseif (($TD_IBM_UserCheck.PW_Change_required -like "yes")-or($TD_IBM_UserCheck.SSH_Key -eq "no")-or($TD_IBM_UserCheck.Locked -eq "auto")) {
                            $TD_lb_UserStatusLight.Background ="yellow"
                            $TD_dg_UserStatusInfoText.ItemsSource=$TD_IBM_UserCheck
                            $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
                        }elseif ($TD_IBM_UserCheck.PW_Change_required -eq "no"){
                            $TD_lb_UserStatusLight.Background ="green"
                        }
                        #endregion
                        #region Storage_HS_StorSecuCheck
                        $TD_IBM_StorSecuCheck = IBM_StorageSecurity -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_UserCheck`n$TD_IBM_StorSecuCheck" -TD_ToolMSGType Debug -TD_Shown yes
                        if(!([String]::IsNullOrEmpty($TD_IBM_StorSecuCheck))){
                            $TD_lb_SecurityStatusLight.Background ="green"
                            $TD_dg_SecurityStatusInfoText.ItemsSource = $TD_IBM_StorSecuCheck
                            $TD_tb_SecurityInfoMsg.Text ="*For further information visit the IBM Docs page of your system,`ne.g. for FS5X00 :https://www.ibm.com/docs/en/flashsystem-5x00/8.6.x?topic=csc-lssecurity-2"
                            $TD_tb_SecurityInfoMsg.Visibility = "Visible"
                        }else{
                            $TD_lb_SecurityStatusLight.Background ="red"
                            $TD_tb_SecurityStatusErrorMsg.Visibility = "Visible"
                            $TD_tb_SecurityStatusErrorMsg.Text = "There is a problem, please check your storage system settings!"
                        }
                        #endregion
                        $TD_UserControl3_1.Dispatcher.Invoke([System.Action]{},"Render")
                        $TD_UserControl3_2.Dispatcher.Invoke([System.Action]{},"Render")
                    }
                }
            "Brocade" 
                { 

                }
            Default {}
        }
    }
    
    end {
        
    }
}