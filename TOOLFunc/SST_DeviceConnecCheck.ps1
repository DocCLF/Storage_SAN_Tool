function SST_DeviceConnecCheck {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "Storage")){$TD_UserInputCred = "SVC"};
        if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "SAN")){$TD_UserInputCred = "VF"};
        if(!($TD_CB_SVCorVF.IsChecked)){$TD_UserInputCred = ""};
    }
    
    process {

        switch ($TD_CB_DeviceType.Text) {
            "Storage" { 
                $TD_BasicDeviceInfos = IBM_BaseStorageInfos -TD_Device_ConnectionTyp $TD_CB_DeviceConnectionType.Text -TD_Device_DeviceIP $TD_TB_DeviceIPAddr.Text -TD_Device_UserName $TD_TB_DeviceUserName.Text -TD_Device_PW $TD_TB_DevicePassword.Password -TD_Storage $TD_UserInputCred
                <# not the best check but try-catch do not work, i have to check why #>
                if($TD_BasicDeviceInfos.count -gt 0){
                    $TD_BInfo = "" | Select-Object ProductDes,Prod_MTM,Code_Level
        
                    switch ($TD_BasicDeviceInfos.Prod_MTM[0]) {
                        {$_ -like "2078-324"}  { $TD_BInfo.ProductDes = "V5030 Gen2" }
            
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
                $TD_BasicDeviceInfos = FOS_BasicSwitchInfos -TD_Device_ConnectionTyp $TD_CB_DeviceConnectionType.Text -TD_Device_DeviceIP $TD_TB_DeviceIPAddr.Text -TD_Device_UserName $TD_TB_DeviceUserName.Text -TD_Device_PW $TD_TB_DevicePassword.Password
                if($TD_BasicDeviceInfos.count -gt 0){
                    $TD_BInfo = "" | Select-Object ProductDes,Prod_MTM,Code_Level
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

    }
    
    end {
        return $TD_BasicDeviceInfo
    }
}