function IBM_SANHealthCheck {
    [CmdletBinding()]
    param (
        $SST_DeviceLoggingInfo,
        $UCOBJ
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
                        [int]$MainWith = 480

                        <# Create the Basic Layout in the Main StackPanel for the Device#>
                        SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANBaseInfoFunc$($_.ID)" -SST_StackPFuncName "FuncBROSANBaseInfoStackPN$($_.ID)" -SST_LabelVisuNameofCheck "SwitchInfo" -SST_StackPResultsName "ResultsBROSANBaseInfoStackPN$($_.ID)" -SST_DeviceID $_.ID -SST_MainStackPWith $MainWith -DeviceIP $_.IPAddress
                        
                        #region SANSwitch_Base_Info
                        $FOS_BasicSwitch = FOS_BasicSwitchInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "SANSwitch_Base_Info" -TD_ToolMSGType Debug -TD_Shown no
                        [int]$i=0
                        SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANBaseInfoFunc$DeviceIDPlaceHolder" -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANBaseInfoStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANBaseInfoStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANBaseInfoCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "SwitchInfo" -DataGridSecOption $true -SST_MainStackPWith $MainWith
                        $DGforKeyValueStatusInfoText = $UCOBJ.FindName("DGforKeyValueSwitchInfoStatusInfoText$DeviceIDPlaceHolder")
                        $DGforKeyValueStatusInfoText.ItemsSource = $FOS_BasicSwitch
                        
                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region FOS_PortbufferShowInfo
                        [array]$FOS_PortbufferShowInfo = FOS_PortbufferShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortbufferShowInfo" -TD_ToolMSGType Debug -TD_Shown no

                        [int]$i=0
                        if(!([String]::IsNullOrEmpty($FOS_PortbufferShowInfo))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANPortbufferFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANPortbufferStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANPortbufferStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANPortbufferCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "PortbufferCheck" -SST_MainStackPWith $MainWith
                        }

                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region FOS_PortErrShowInfos
                        [array]$FOS_PortErrShowInfos = FOS_PortErrShowInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortErrShowInfos" -TD_ToolMSGType Debug -TD_Shown no

                        if(!([String]::IsNullOrEmpty($FOS_PortErrShowInfos))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANPortErrFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANPortErrStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANPortErrStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANPortErrCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "PortErrorCheck" -SST_MainStackPWith $MainWith
                        }
                        [int]$i=0

                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region FOS_PortLicenseShowInfo
                        [array]$FOS_PortLicenseShowInfo = FOS_PortLicenseShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_PortLicenseShowInfo" -TD_ToolMSGType Debug -TD_Shown no
                        
                        if(!([String]::IsNullOrEmpty($FOS_PortLicenseShowInfo))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANPortLicenseFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANPortLicenseStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANPortLicenseStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANPortLicenseCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "LicenseCheck" -SST_MainStackPWith $MainWith
                        }
                        
                        #endregion

                        #region FOS_SensorShow
                        [array]$FOS_SensorShow   = FOS_SensorShow -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SensorShow" -TD_ToolMSGType Debug -TD_Shown no
                        
                        if(!([String]::IsNullOrEmpty($FOS_SensorShow))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSensorShowFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANSensorShowStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSensorShowStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSensorShowCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "SensorCheck" -SST_MainStackPWith $MainWith
                        }
                        
                        #endregion

                        #region FOS_SFPDetails
                        [array]$FOS_SFPDetails = FOS_SFPDetails -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SFPDetails" -TD_ToolMSGType Debug -TD_Shown no
                        [int]$i=0
                        $FOS_SFPDetails |ForEach-Object {
                            $i++
                            if(($_.HealthStatus -eq "Yellow") -or ([string]::IsNullOrWhiteSpace($_.HealthStatus)) -or ($_.HealthStatus -eq "Unknown") -or ($_.HealthStatus -like "No License")){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSFPDetailsFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Port: $($_.Port)"+" - "+"SFPTyp: $($_.SFPTyp)"+" - "+"Speed: $($_.SpeedRange)"+" - "+"HealthStatus: $($_.HealthStatus)") -SST_LabelColorForCheck "Yellow" -SST_StackPFuncName "FuncBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSFPDetailsCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "SFPDetails" -SST_MainStackPWith $MainWith
                            }
                        }
                        if((($FOS_SFPDetails | Where-Object {$_}).Count) -eq (($FOS_SFPDetails | Where-Object {$_.HealthStatus -eq "Green"}).Count)){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSFPDetailsFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSFPDetailsStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSFPDetailsCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "SFPDetails" -SST_MainStackPWith $MainWith
                        }
                        $i=0
                        #endregion

                        #region FOS_SwitchShowInfo
                        [array]$FOS_SwitchShowInfo = FOS_SwitchShowInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_SwitchShowInfo" -TD_ToolMSGType Debug -TD_Shown no

                        if(!([String]::IsNullOrEmpty($FOS_SwitchShowInfo))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANSwitchShowFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANSwitchShowStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANSwitchShowStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANSwitchShowCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "SwitchShow" -SST_MainStackPWith $MainWith
                        }

                        #endregion

                        #region FOS_ZoneDetails
                        $FOS_ZoneDetails = FOS_ZoneDetails -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) 
                        SST_ToolMessageCollector -TD_ToolMSGCollector "FOS_ZoneDetails" -TD_ToolMSGType Debug -TD_Shown yes

                        if(!([String]::IsNullOrEmpty($FOS_ZoneDetails))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$BROSANDeviceMainSTPName" -SST_GridFuncName "BROSANZoneDetailsFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: Done ") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncBROSANZoneDetailsStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsBROSANZoneDetailsStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("BROSANZoneDetailsCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "ZoneDetails" -SST_MainStackPWith $MainWith
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