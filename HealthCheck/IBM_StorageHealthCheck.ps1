Add-Type -AssemblyName PresentationFramework
function IBM_StorageHealthCheck {
    [CmdletBinding()]
    param (
        $SST_DeviceLoggingInfo,
        $UCOBJ
    )
    
    begin {
        

    }
    
    process {

        $TD_DeviceManufacturer = "IBM"
        switch ($TD_DeviceManufacturer) {
            "IBM" 
                {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Starting HealthCheck for IP: $($Temp_Credentials.IPAddress) with Name: $($Temp_Credentials.DeviceName)" -TD_ToolMSGType Message -TD_Shown no

                    $SST_DeviceLoggingInfo | ForEach-Object {
                        
                        <# Create the Name for Main StackPanel for each Device#>
                        $IBMSTODeviceMainSTPName = "IBMSTO"+"$($_.DeviceName)"+"$($_.ID)"
                        [int]$DeviceIDPlaceHolder = $_.ID

                        <# Create the Basic Layout in the Main StackPanel for the Device#>
                        SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMSTOBaseInfoFunc$($_.ID)" -SST_StackPFuncName "FuncIBMSTOBaseInfoStackPN$($_.ID)" -SST_LabelVisuNameofCheck "StorageInfo" -SST_StackPResultsName "ResultsIBMSTOBaseInfoStackPN$($_.ID)" -SST_DeviceID $_.ID -DeviceIP $_.IPAddress
                        
                        #region Storage_Base_Info
                        [array]$TD_BaseStorageInfo = IBM_BaseStorageInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_Eventlog" -TD_ToolMSGType Debug -TD_Shown no
                        [int]$i=0
                        $TD_BaseStorageInfo | ForEach-Object{
                            $i++
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMSTOBaseInfoFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.Name)"+" - "+"MTM: $($_.Prod_MTM)"+" - "+"SerialNumber: $($_.Serial_Number)"+" - "+"CodeLevel: $($_.Code_Level)"+" - "+"RecommendedPTF: $($_.RecommendedPTF)") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncIBMSTOBaseInfoStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMSTOBaseInfoStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOBaseInfoCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "StorageInfo"
						}
                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region Storage_HS_Eventlog
                        [array]$TD_IBM_EventLogCheck = IBM_EventLog -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_Eventlog" -TD_ToolMSGType Debug -TD_Shown no


                        [int]$i=0
                        $TD_IBM_EventLogCheck | ForEach-Object{
                            $i++
                            if(($_.Status -eq "alert")-and($_.Fixed -eq "no")){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBM_EventlogFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Time: $($_.LastTime)"+" - "+"Fixed: $($_.Fixed)"+" - "+"ErrorCode: $($_.ErrorCode)"+" - "+"Description: $($_.Description)") -SST_LabelColorForCheck "red" -SST_StackPFuncName "FuncIBMEventlogStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMEventlogStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOEventLogCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "Eventlog"
                            }
                            elseif(($_.Status -eq "monitoring")-and($_.Fixed -eq "expired")){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBM_EventlogFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Time: $($_.LastTime)"+" - "+"Fixed: $($_.Fixed)"+" - "+"ErrorCode: $($_.ErrorCode)"+" - "+"Description: $($_.Description)") -SST_LabelColorForCheck "yellow" -SST_StackPFuncName "FuncIBMEventlogStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMEventlogStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOEventLogCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "Eventlog"
                            }
                        }
						if((($TD_IBM_EventLogCheck | Where-Object {($_.Status -eq "alert") -and ($_.Fixed -eq "no")}).Count -lt 1)-and(($TD_IBM_EventLogCheck | Where-Object {($_.Status -eq "monitoring")-and($_.Fixed -eq "expired")}).Count -lt 1)){
							SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBM_EventlogFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck "No Events in the List" -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncIBMEventlogStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMEventlogStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOEventLogCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "Eventlog"
						}
                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region Storage_HS_HostCheck
                        [array]$TD_IBM_HostInfo = IBM_HostInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage IBM_HostInfo" -TD_ToolMSGType Debug -TD_Shown no

                        <# Create the Basic Layout in the Main StackPanel for the Device#>
                        SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMHostCheckFunc$($_.ID)" -SST_StackPFuncName "FuncIBMHostCheckStackPN$($_.ID)" -SST_LabelVisuNameofCheck "HostCheck" -SST_StackPResultsName "ResultsIBMHostCheckStackPN$($_.ID)" -SST_DeviceID $_.ID
                        
                        [int]$i=0
                        $TD_IBM_HostInfo = $TD_IBM_HostInfo
                        $TD_IBM_HostInfo | ForEach-Object{
                            $i++
                            if($_.Status -eq "offline"){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMHostCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.HostName)"+" - "+"HostClusterName: $($_.HostClusterName)"+" - "+"SiteName: $($_.SiteName)") -SST_LabelColorForCheck "red" -SST_StackPFuncName "FuncIBMHostCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMHostCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOHostCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "HostCheck"
                            }
                            elseif($_.Status -eq "degraded"){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMHostCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.HostName)"+" - "+"HostClusterName: $($_.HostClusterName)"+" - "+"SiteName: $($_.SiteName)") -SST_LabelColorForCheck "yellow" -SST_StackPFuncName "FuncIBMHostCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMHostCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOHostCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "HostCheck"
                            }
                        }
                        $i=0
                        $UCOBJ.Dispatcher.Invoke([System.Action]{},"Render")
                        #endregion

                        #region Storage_HS_MDiskCheck
                        [array]$TD_IBM_MDiskCheck = IBM_MDiskInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_MDiskCheck" -TD_ToolMSGType Debug -TD_Shown no
                        
                        <# Create the Basic Layout in the Main StackPanel for the Device#>
                        SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMHostCheckFunc$($_.ID)" -SST_StackPFuncName "FuncIBMHostCheckStackPN$($_.ID)" -SST_LabelVisuNameofCheck "MDiskCheck" -SST_StackPResultsName "ResultsIBMHostCheckStackPN$($_.ID)" -SST_DeviceID $_.ID
                        
                        [int]$i=0
                        $TD_IBM_MDiskCheck |ForEach-Object {
                            $i++
                            if(($_.Status -eq "offline")-or($_.Status -eq "excluded")){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMMDiskCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.Name)"+" - "+"Capacity: $($_.Capacity)"+" - "+"FreeCapacity: $($_.FreeCapacity)") -SST_LabelColorForCheck "red" -SST_StackPFuncName "FuncIBMMDiskCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMMDiskCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOMDiskCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "MDiskCheck"
                            }
                            elseif($_.Status -eq "degraded"){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMMDiskCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.Name)"+" - "+"Capacity: $($_.Capacity)"+" - "+"FreeCapacity: $($_.FreeCapacity)") -SST_LabelColorForCheck "yellow" -SST_StackPFuncName "FuncIBMMDiskCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMMDiskCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOMDiskCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "MDiskCheck"
                            }else{
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMMDiskCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.Name)"+" - "+"Capacity: $($_.Capacity)"+" - "+"FreeCapacity: $($_.FreeCapacity)") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncIBMMDiskCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMMDiskCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOMDiskCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "MDiskCheck"
                            }
                        }
                        $i=0

                        #endregion

                        #region Storage_HS_VolumeCheck
                        [array]$TD_IBM_VolumeCheck   = IBM_VolumeInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_VolumeCheck" -TD_ToolMSGType Debug -TD_Shown no
                        $TD_VdiskResault = foreach($TD_VdiskFunc in $TD_IBM_VolumeCheck){
                            if(($TD_VdiskFunc.VolFunc -eq 'master')-or($TD_VdiskFunc.VolFunc -eq 'none')){
                                $TD_VdiskFunc
                            }
                        }

                        $TD_VdiskResault |ForEach-Object {
                            $i++
                            if($_.Status -eq "offline"){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMVolumeCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.Volume_Name)"+" - "+"Pool: $($_.Pool)"+" - "+"UUID: $($_.Volume_UID)") -SST_LabelColorForCheck "red" -SST_StackPFuncName "FuncIBMVolumeCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMVolumeCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOVolumekCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "VolumeCheck"
                            }elseif ($_.Status -eq "degraded") {
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMVolumeCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.Volume_Name)"+" - "+"Pool: $($_.Pool)"+" - "+"UUID: $($_.Volume_UID)") -SST_LabelColorForCheck "yellow" -SST_StackPFuncName "FuncIBMVolumeCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMVolumeCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOVolumekCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "VolumeCheck"
                            }
                            <# not a option right now #>
                            #else{
                            #    SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMVolumeCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("Status: $($_.Status)"+" - "+"Name: $($_.Name)"+" - "+"Capacity: $($_.Capacity)"+" - "+"FreeCapacity: $($_.FreeCapacity)") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncIBMMDiskCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMVolumeCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOVolumekCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "VolumeCheck"
                            #}
                        }
                        $i=0

                        #endregion

                        #region Storage_HS_IPQuorumCheck
                        [array]$TD_IBM_IPQuorumCheck = IBM_IPQuorum -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_IPQuorumCheck" -TD_ToolMSGType Debug -TD_Shown no

                        if(!([String]::IsNullOrEmpty($TD_IBM_IPQuorumCheck))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMIPQuorumCheckFunc$DeviceIDPlaceHolder" -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncIBMQuorumCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMQuorumCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOQuorumkCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "QuorumCheck" -DataGridOption $true
                            $DGQuorumStatusInfo = $UCOBJ.FindName("QuorumCheck"+"green"+"_"+$DeviceIDPlaceHolder)
                            $DGQuorumStatusInfo.ItemsSource = $TD_IBM_IPQuorumCheck
                        }else{
                            $QuorumErrorMsg = "Your current quorum configuration differs from the default and does not`n seem to have the minimum number of 3 quorum devices, please check this!"
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMIPQuorumCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $QuorumErrorMsg -SST_LabelColorForCheck "red" -SST_StackPFuncName "FuncIBMQuorumCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMQuorumCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOQuorumkCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "QuorumCheck" -DataGridOption $false
                        }
                        #endregion
                        #region Storage_HS_UserCheck
                        [array]$TD_IBM_UserCheck = IBM_UserInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage HS_UserCheck" -TD_ToolMSGType Debug -TD_Shown no
                        $TD_IBM_UserCheck |ForEach-Object {
                            $i++
                            if($_.PW_Change_required -eq "yes"){
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMUserCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("UserName: $($_.User_Name)"+" - "+"Password: $($_.Password)"+" - "+"Change_required: $($_.PW_Change_required)"+" - "+"SSHKey: $($_.SSH_Key)"+" - "+"Locked: $($_.Locked)"+" - "+"UserGrp: $($_.UserGrp)"+" - "+"Remote: $($_.Remote)") -SST_LabelColorForCheck "red" -SST_StackPFuncName "FuncIBMUserCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMUserCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOUserCheckkCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "UserCheck"
                            }elseif ($_.Locked -ne "yes") {
                                <# Create a InfoLabel with the MSG and push the color for the Device#>
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMUserCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("UserName: $($_.User_Name)"+" - "+"Password: $($_.Password)"+" - "+"Change_required: $($_.PW_Change_required)"+" - "+"SSHKey: $($_.SSH_Key)"+" - "+"Locked: $($_.Locked)"+" - "+"UserGrp: $($_.UserGrp)"+" - "+"Remote: $($_.Remote)") -SST_LabelColorForCheck "yellow" -SST_StackPFuncName "FuncIBMUserCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMUserCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOUserCheckkCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "UserCheck"
                            }else {
                                SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMUserCheckFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $("UserName: $($_.User_Name)"+" - "+"Password: $($_.Password)"+" - "+"Change_required: $($_.PW_Change_required)"+" - "+"SSHKey: $($_.SSH_Key)"+" - "+"Locked: $($_.Locked)"+" - "+"UserGrp: $($_.UserGrp)"+" - "+"Remote: $($_.Remote)") -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncIBMUserCheckStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMUserCheckStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOUserCheckkCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "UserCheck"
                            }
                        }
                        $i=0
                        #endregion

                        #region Storage_HS_StorSecuCheck
                        $TD_IBM_StorSecuCheck = IBM_StorageSecurity -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $TD_Credential.SVCorVF -TD_Export "no"
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage IBM_StorageSecurity" -TD_ToolMSGType Debug -TD_Shown yes
                        
                        if(!([String]::IsNullOrEmpty($TD_IBM_StorSecuCheck))){
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMSecurityFunc$DeviceIDPlaceHolder" -SST_LabelColorForCheck "green" -SST_StackPFuncName "FuncIBMSecurityStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMSecurityStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOSecurityCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "StorageSecurity" -DataGridSecOption $true -Storage $true
                            $DGSecurityStatusInfo = $UCOBJ.FindName("DGforKeyValueStorageSecurityStatusInfoText$DeviceIDPlaceHolder")
                            $DGSecurityStatusInfo.ItemsSource = $TD_IBM_StorSecuCheck

                            $TBSecurityStatusInfo = $UCOBJ.FindName("TBforKeyValueStorageSecurityStatusInfoText$DeviceIDPlaceHolder")
                            $TBSecurityStatusInfo.Text ="*For further information visit the IBM Docs page of your system,`ne.g. for FS5X00 :https://www.ibm.com/docs/en/flashsystem-5x00/8.6.x?topic=csc-lssecurity-2"
                            $TBSecurityStatusInfo.Visibility = "Visible"

                        }else{
                            $SecurityStatusErrorMsgText = "There is a problem, please check your storage system settings!"
                            SST_CreateHealthLayout -SST_UCOBJ $UCOBJ -SST_MainStackPName "$IBMSTODeviceMainSTPName" -SST_GridFuncName "IBMSecurityFunc$DeviceIDPlaceHolder" -SST_LabelVisuResultsofCheck $SecurityStatusErrorMsgText -SST_LabelColorForCheck "red" -SST_StackPFuncName "FuncIBMSecurityStackPN$DeviceIDPlaceHolder" -SST_StackPResultsName "ResultsIBMSecurityStackPN$DeviceIDPlaceHolder" -SST_LabelNameHelper "$("IBMSTOSecurityCheck$DeviceIDPlaceHolder"+"_"+$i)" -SST_DeviceID $DeviceIDPlaceHolder -SST_LabelVisuNameofCheck "StorageSecurity"
                        }
                        #endregion
                        SST_ToolMessageCollector -TD_ToolMSGCollector "Storage Health Check Func End" -TD_ToolMSGType Debug -TD_Shown no
                    }
                }
            "some other" 
                { 

                }
            Default {}
        }
            
    }
    
    end {
        
    }
}