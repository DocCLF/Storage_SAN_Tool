function SST_GetCredfGUI {
    [CmdletBinding()]
    param(
        [int]$TD_ErrorCode =0,
        [string]$TD_AddaNewDevice
    )

    if($TD_AddaNewDevice -eq "yes"){
        switch ($TD_CB_DeviceType.Text) {
            "Storage" { 
                $TD_BasicDeviceInfo = SST_DeviceConnecCheck
                if([string]::IsNullOrEmpty($TD_BasicDeviceInfo)){$TD_ErrorCode = 1;break}
            }
            "SAN" { 
                $TD_BasicDeviceInfo = SST_DeviceConnecCheck
                if([string]::IsNullOrEmpty($TD_BasicDeviceInfo)){$TD_ErrorCode = 1;break}
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at SST_GetCredfGUI Func or no Device Type was found, please check the promt." -TD_ToolMSGType Warning}
        }
        $TD_AddaNewDevice="no"
    }
    if($TD_ErrorCode -eq 0){
        $TD_ExistingCreds = $TD_DG_KnownDeviceList.ItemsSource
        <# ForEach is needed if you import ced, because you musst add the pw this was not exported  #>
        [array]$TD_Credentials = foreach ($TD_ExistingCred in $TD_ExistingCreds) {
            
            if($TD_ExistingCred.IPAdresse -eq $TD_TB_DeviceIPAddr.Text){continue}
            
            $TD_ExistingCred
        }    
        
        $TD_UserInputCred = "" | Select-Object ID,DeviceTyp,ConnectionTyp,IPAdresse,UserName,Password,SSHKeyPath,SVCorVF,MTMCode,ProductDescr,CurrentFirmware,Exportpath
        $TD_UserInputCred.ID               =   $TD_Credentials.Count + 1;
        $TD_UserInputCred.DeviceTyp        =   $TD_CB_DeviceType.Text;
        $TD_UserInputCred.ConnectionTyp    =   $TD_CB_DeviceConnectionType.Text;
        $TD_UserInputCred.IPAdresse        =   $TD_TB_DeviceIPAddr.Text;
        $TD_UserInputCred.UserName         =   $TD_TB_DeviceUserName.Text;
        $TD_UserInputCred.Password         =   $TD_TB_DevicePassword;
        $TD_UserInputCred.SSHKeyPath       =   $TD_TB_PathtoSSHKeyNotVisibil.Text;
        if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "Storage")){$TD_UserInputCred.SVCorVF = "SVC"};
        if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "SAN")){$TD_UserInputCred.SVCorVF = "VF"};
        if(!($TD_CB_SVCorVF.IsChecked)){$TD_UserInputCred.SVCorVF = ""};
        $TD_UserInputCred.MTMCode          =   $TD_BasicDeviceInfo.Prod_MTM
        $TD_UserInputCred.ProductDescr     =   $TD_BasicDeviceInfo.ProductDes
        $TD_UserInputCred.CurrentFirmware  =   $TD_BasicDeviceInfo.Code_Level
        $TD_UserInputCred.Exportpath       =   "$PSRootPath\Export\";
                    
        $TD_Credentials += $TD_UserInputCred
        $TD_DG_KnownDeviceList.ItemsSource = $TD_Credentials
    }

    return $TD_Credentials
}