function IBM_SANHealthCheck {
    [CmdletBinding()]
    param (
        $SST_DeviceLoggingInfo
        
    )
    
    begin {
        
    }
    
    process {
        Write-Host $TD_Device_DeviceIP -ForegroundColor Red
        
        $TD_DeviceManufacturer = "Brocade"
        switch ($TD_DeviceManufacturer) {
            "Brocade" 
                {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Starting HealthCheck for IP: $($Temp_Credentials.IPAddress) with Name: $($Temp_Credentials.DeviceName)" -TD_ToolMSGType Message -TD_Shown no

                    $SST_DeviceLoggingInfo | ForEach-Object {
                        
                        <# Create the Name for Main StackPanel for each Device#>
                        $BROSANDeviceMainSTPName = "BROSAN"+"$($_.DeviceName)"+"$($_.ID)"
                        [int]$DeviceIDPlaceHolder = $_.ID

                        <# Create the Basic Layout in the Main StackPanel for the Device#>
                        SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANBaseInfoFunc$($_.ID)" -SST_StackPFuncName "FuncBROSANBaseInfoStackPN$($_.ID)" -SST_LabelVisuNameofCheck "SwitchInfo" -SST_StackPResultsName "ResultsBROSANBaseInfoStackPN$($_.ID)" -SST_DeviceID $_.ID
                        
                        #region SANSwitch_Base_Info
                        $FOS_BasicSwitch = FOS_BasicSwitchInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "SANSwitch_Base_Info" -TD_ToolMSGType Debug -TD_Shown no
                        [int]$i=0
                        SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANBaseInfoFunc$DeviceIDPlaceHolder" -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANBaseInfoStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANBaseInfoStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANBaseInfoCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "SwitchInfo" -DataGridSecOption $true
                        $DGforKeyValueStatusInfoText = $UCOBJ.FindName("DGforKeyValueSwitchInfoStatusInfoText$DeviceIDPlaceHolder")
                        $DGforKeyValueStatusInfoText.ItemsSource = $FOS_BasicSwitch
                        
                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region FOS_PortbufferShowInfo
                        [array]$FOS_PortbufferShowInfo = FOS_PortbufferShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortbufferShowInfo" -TD_ToolMSGType Debug -TD_Shown no

                        [int]$i=0
                        if(!([String]::IsNullOrEmpty($FOS_PortbufferShowInfo))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANPortbufferFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANPortbufferStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANPortbufferStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANPortbufferCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "Portbuffer Check"
                        }

                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region FOS_PortErrShowInfos
                        [array]$FOS_PortErrShowInfos = FOS_PortErrShowInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortErrShowInfos" -TD_ToolMSGType Debug -TD_Shown no

                        if(!([String]::IsNullOrEmpty($FOS_PortErrShowInfos))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANPortErrFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANPortErrStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANPortErrStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANPortErrCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "PortError Check"
                        }
                        [int]$i=0

                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region FOS_PortLicenseShowInfo
                        [array]$FOS_PortLicenseShowInfo = FOS_PortLicenseShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortLicenseShowInfo" -TD_ToolMSGType Debug -TD_Shown no
                        
                        if(!([String]::IsNullOrEmpty($FOS_PortLicenseShowInfo))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANPortLicenseFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANPortLicenseStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANPortLicenseStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANPortLicenseCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "License Check"
                        }
                        
                        #endregion

                        #region FOS_SensorShow
                        [array]$FOS_SensorShow   = FOS_SensorShow -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SensorShow" -TD_ToolMSGType Debug -TD_Shown no
                        
                        if(!([String]::IsNullOrEmpty($FOS_SensorShow))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSensorShowFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANSensorShowStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSensorShowStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSensorShowCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "Sensor Check"
                        }
                        
                        #endregion

                        #region FOS_SFPDetails
                        [array]$FOS_SFPDetails = FOS_SFPDetails -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SFPDetails" -TD_ToolMSGType Debug -TD_Shown no
                        [int]$i=0
                        $FOS_SFPDetails |ForEach-Object {
                            $i++
                            if($_.HealthStatus -eq "Yellow"){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSFPDetailsFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Port: $($_.Port)"+" - "+"SFPTyp: $($_.SFPTyp)"+" - "+"Vendor: $($_.Vendor)"+" - "+"Serial: $($_.SerialNo)"+" - "+"Speed: $($_.SpeedRange)"+" - "+"HealthStatus: $($_.HealthStatus)") -SST_LabelColorForCheck "Yellow" -SST_StackPFuncName "FuncBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSFPDetailsCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "SFP Details"
                            }else {
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSFPDetailsFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Port: $($_.Port)"+" - "+"SFPTyp: $($_.SFPTyp)"+" - "+"Vendor: $($_.Vendor)"+" - "+"Serial: $($_.SerialNo)"+" - "+"Speed: $($_.SpeedRange)"+" - "+"HealthStatus: $($_.HealthStatus)") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSFPDetailsCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "UserCheck"
                            }
                        }
                        $i=0
                        #endregion

                        #region FOS_SwitchShowInfo
                        [array]$FOS_SwitchShowInfo = FOS_SwitchShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SwitchShowInfo" -TD_ToolMSGType Debug -TD_Shown no

                        if(!([String]::IsNullOrEmpty($FOS_SwitchShowInfo))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSwitchShowFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANSwitchShowStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSwitchShowStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSwitchShowCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "Switch Show"
                        }

                        #endregion

                        #region Storage_HS_StorSecuCheck
                        $FOS_ZoneDetails = FOS_ZoneDetails -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_ZoneDetails" -TD_ToolMSGType Debug -TD_Shown yes

                        if(!([String]::IsNullOrEmpty($FOS_ZoneDetails))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANZoneDetailsFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANZoneDetailsStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANZoneDetailsStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANZoneDetailsCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "Zone Details"
                        }
                        #endregion
                        SST_ToolMessageCollector -TD_ToolMSGCollector "SAN Health Check Func End" -TD_ToolMSGType Debug -TD_Shown no
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