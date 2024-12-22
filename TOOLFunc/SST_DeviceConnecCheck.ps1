function SST_DeviceConnecCheck {
    [CmdletBinding()]
    param (
        $TD_Selected_Items,
        $TD_Selected_DeviceType,
        $TD_Selected_DeviceConnectionType,
        $TD_Selected_DeviceIPAddr,
        $TD_Selected_DeviceUserName,
        $TD_Selected_DevicePassword,
        $TD_Selected_SVCorVF
    )
    
    begin {
        switch ($TD_Selected_Items) {
            "yes" { 
                $TD_Selected_DeviceType
                $TD_Selected_DeviceConnectionType
                $TD_Selected_DeviceIPAddr
                $TD_Selected_DeviceUserName
                $TD_Selected_DevicePassword
                $TD_UserInputCred = $TD_Selected_SVCorVF
             }
            "no" { 
                $TD_Selected_DeviceConnectionType = $TD_CB_DeviceConnectionType.Text
                $TD_Selected_DeviceIPAddr = $TD_TB_DeviceIPAddr.Text
                $TD_Selected_DeviceUserName = $TD_TB_DeviceUserName.Text
                $TD_Selected_DevicePassword = $TD_TB_DevicePassword.Password
                $TD_Selected_DeviceType = $TD_CB_DeviceType.Text
                if($TD_CB_SVCorVF.IsChecked -and ($TD_Selected_DeviceType -eq "Storage")){$TD_UserInputCred = "SVC"};
                if($TD_CB_SVCorVF.IsChecked -and ($TD_Selected_DeviceType -eq "SAN")){$TD_UserInputCred = "VF"};
                if(!($TD_CB_SVCorVF.IsChecked)){$TD_UserInputCred = ""};
             }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at SST_DeviceConnecCheck Func please check the promt or close the gui and write $error in the promt." -TD_ToolMSGType Warning}
        }

    }
    
    process {

        switch ($TD_Selected_DeviceType) {
            "Storage" { 
                $TD_BasicDeviceInfos = IBM_BaseStorageInfos -TD_Device_ConnectionTyp $TD_Selected_DeviceConnectionType -TD_Device_DeviceIP $TD_Selected_DeviceIPAddr -TD_Device_UserName $TD_Selected_DeviceUserName -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Selected_DevicePassword).Password) -TD_Storage $TD_UserInputCred
                <# not the best check but try-catch do not work, i have to check why #>
                if($TD_BasicDeviceInfos.count -gt 0){
                    $TD_BInfo = "" | Select-Object DeviceName,ProductDes,Prod_MTM,Code_Level

                    if($TD_BasicDeviceInfos.Name[0] -ne ""){
                        $TD_BInfo.DeviceName = $TD_BasicDeviceInfos.Name[0]
                    }else {
                        $TD_BInfo.DeviceName = $TD_BasicDeviceInfos.Serial_Number[0]
                    }

                    switch ($TD_BasicDeviceInfos.Prod_MTM[0]) {
                        {$_ -like "2078-324"}  { $TD_BInfo.ProductDes = "V5030 Gen2" }
                        {$_ -like "2077-4H4" -or $_ -like "2078-4H4" }  { $TD_BInfo.ProductDes = "FlashSystem 5100" }
                        {$_ -like "4662-6H2" -or $_ -like "4662-UH6" }  { $TD_BInfo.ProductDes = "FlashSystem 5200" }
                        {$_ -like "4662-7H2"}  { $TD_BInfo.ProductDes = "FlashSystem 5300" }
                        {$_ -like "2076-824" -or $_ -like "4664-824" -or $_ -like "*-U7C" }  { $TD_BInfo.ProductDes = "FlashSystem 7200" }
                        {$_ -like "4657-924" -or $_ -like "4657-U7D"}  { $TD_BInfo.ProductDes = "FlashSystem 7300" }
                        {$_ -like "4666-AH8" -or $_ -like "4666-UH8" -or $_ -like "4983-AH8" }  { $TD_BInfo.ProductDes = "FlashSystem 9500" }
                        {$_ -like "4666-AG8" -or $_ -like "4666-UG8" -or $_ -like "984*G8" }  { $TD_BInfo.ProductDes = "FlashSystem 9200" }
                        {$_ -like "2145-DH8"}  { $TD_BInfo.ProductDes = "SVC DH8" }
                        {$_ -like "2145-SV1"}  { $TD_BInfo.ProductDes = "SVC SV1" }
                        {$_ -like "2145-SV2"}  { $TD_BInfo.ProductDes = "SVC SV2" }
                        {$_ -like "2145-SA2"}  { $TD_BInfo.ProductDes = "SVC SA2" }
                        {$_ -like "2145-SV3"}  { $TD_BInfo.ProductDes = "SVC SV3" }
            
                        Default {
                            $TD_BInfo.ProductDes = "Unknown Type"
                            SST_ToolMessageCollector -TD_ToolMSGCollector "Unknown Storage MTM, please check this MTM Number via google $($TD_BasicDeviceInfos.Prod_MTM[0])" -TD_ToolMSGType Warning
                        }
                    }
                    
                    $TD_BInfo.Prod_MTM = $TD_BasicDeviceInfos.Prod_MTM[0]
                    $TD_BInfo.Code_Level = $TD_BasicDeviceInfos.Code_Level[0]
                    $TD_BasicDeviceInfo += $TD_BInfo
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Added Storage Device to the List" -TD_ToolMSGType Message
                }else {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong, no data could be received from Storage device." -TD_ToolMSGType Error
                    break
                }
            }
            "SAN" { 
                $TD_BasicDeviceInfos = FOS_BasicSwitchInfos -TD_Device_ConnectionTyp $TD_Selected_DeviceConnectionType -TD_Device_DeviceIP $TD_Selected_DeviceIPAddr -TD_Device_UserName $TD_Selected_DeviceUserName -TD_Device_PW $([Net.NetworkCredential]::new('', $TD_Selected_DevicePassword).Password)
                if($TD_BasicDeviceInfos.count -gt 0){
                    $TD_BInfo = "" | Select-Object DeviceName,ProductDes,Prod_MTM,Code_Level
                    $TD_BInfo.DeviceName = $TD_BasicDeviceInfos.'Swicht Name'
                    $TD_BInfo.ProductDes = $TD_BasicDeviceInfos.'Brocade Product Name'
                    $TD_BInfo.Prod_MTM = "unknown"
                    $TD_BInfo.Code_Level = $TD_BasicDeviceInfos.'Fabric OS'
                    $TD_BasicDeviceInfo += $TD_BInfo
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Added SAN Device to the List" -TD_ToolMSGType Message
                }else {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong, no data could be received from SAN device." -TD_ToolMSGType Error
                    break
                }
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at SST_DeviceConnecCheck Func or no Device Type was found, please check the promt." -TD_ToolMSGType Warning}
        }
        
        if($TD_Selected_Items -eq "yes"){
            $TD_Credentials = $TD_DG_KnownDeviceList.ItemsSource
            <# ForEach is needed if you import ced, because you musst add the pw this was not exported  #>
            [array]$TD_Credentials = foreach ($TD_ExistingCred in $TD_Credentials) {
                if($TD_ExistingCred.IPAddress -eq $TD_Selected_DeviceIPAddr){
                    $TD_UserInputCred = "" | Select-Object ID,DeviceTyp,ConnectionTyp,IPAddress,DeviceName,UserName,Password,SSHKeyPath,SVCorVF,MTMCode,ProductDescr,CurrentFirmware,Exportpath
                    $TD_UserInputCred.ID               =   $TD_ExistingCred.ID;
                    $TD_UserInputCred.DeviceTyp        =   $TD_ExistingCred.DeviceTyp;
                    $TD_UserInputCred.ConnectionTyp    =   $TD_ExistingCred.ConnectionTyp;
                    $TD_UserInputCred.IPAddress        =   $TD_ExistingCred.IPAddress;
                    $TD_UserInputCred.DeviceName       =   $TD_BasicDeviceInfo.DeviceName;
                    $TD_UserInputCred.UserName         =   $TD_ExistingCred.UserName;
                    <# The PwLine needs a better Option #>
                    $TD_UserInputCred.Password         =   $TD_Selected_DevicePassword;
                    $TD_UserInputCred.SSHKeyPath       =   $TD_ExistingCred.SSHKeyPath;
                    $TD_UserInputCred.SVCorVF          =   $TD_ExistingCred.SVCorVF;
                    $TD_UserInputCred.MTMCode          =   $TD_BasicDeviceInfo.Prod_MTM;
                    $TD_UserInputCred.ProductDescr     =   $TD_BasicDeviceInfo.ProductDes;
                    $TD_UserInputCred.CurrentFirmware  =   $TD_BasicDeviceInfo.Code_Level;
                    
                    $TD_ExistingCredUpdate = $TD_UserInputCred
                }else{
                    $TD_ExistingCredUpdate = $TD_ExistingCred |Where-Object {$_}
                }
                $TD_ExistingCredUpdate
            }
            $TD_DG_KnownDeviceList.ItemsSource = $TD_Credentials
        }
    }
    
    end {
        if($TD_Selected_Items -eq "no"){
            return $TD_BasicDeviceInfo
        }
    }
}