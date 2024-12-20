function SST_GetCredfGUI {
    [CmdletBinding()]
    param(
        [Int16]$TD_ErrorCode =0,
        [Int16]$TD_CredentialsCount=1,
        [string]$TD_AddaNewDevice
    )

    if($TD_AddaNewDevice -eq "yes"){
        switch ($TD_CB_DeviceType.Text) {
            "Storage" { 
                $TD_BasicDeviceInfo = SST_DeviceConnecCheck -TD_Selected_Items "no"
                if([string]::IsNullOrEmpty($TD_BasicDeviceInfo)){$TD_ErrorCode = 1;break}
            }
            "SAN" { 
                $TD_BasicDeviceInfo = SST_DeviceConnecCheck -TD_Selected_Items "no"
                if([string]::IsNullOrEmpty($TD_BasicDeviceInfo)){$TD_ErrorCode = 1;break}
            }
            Default {SST_ToolMessageCollector -TD_ToolMSGCollector "Something went wrong at SST_GetCredfGUI Func or no Device Type was found, please check the promt." -TD_ToolMSGType Warning}
        }
        $TD_AddaNewDevice="no"
    }
    <# can be set to 1 for tests default value is 0 #>
    if($TD_ErrorCode -eq 0){
        $TD_ExistingCreds = $TD_DG_KnownDeviceList.ItemsSource
        <# ForEach is needed if you import ced, because you musst add the pw this was not exported  #>
        [array]$TD_Credentials = foreach ($TD_ExistingCred in $TD_ExistingCreds) {
            
            if($TD_ExistingCred.IPAddress -eq $TD_TB_DeviceIPAddr.Text){
                SST_ToolMessageCollector -TD_ToolMSGCollector $("This $($TD_TB_DeviceIPAddr.Text) is already in use") -TD_ToolMSGType Warning
                continue
            }
            
            $TD_ExistingCred
        }
        <# Split between Storage and SAN #>
        if($TD_CB_DeviceType.Text -eq "Storage"){
            $TD_CredentialsCount=(($TD_Credentials |Where-Object {$_.DeviceTyp -eq "Storage"}).count + 1)
            SST_ToolMessageCollector -TD_ToolMSGCollector "Storage ID is $TD_CredentialsCount" -TD_ToolMSGType Debug
        }

        if($TD_CB_DeviceType.Text -eq "SAN"){
            $TD_CredentialsCount= (($TD_Credentials |Where-Object {$_.DeviceTyp -eq "SAN"}).count + 1)
            SST_ToolMessageCollector -TD_ToolMSGCollector "SAN ID is $TD_CredentialsCount" -TD_ToolMSGType Debug
        }

        if($TD_CB_DeviceConnectionType.Text -like "Classic*"){$TD_CB_DeviceConnectionTypeText="plink"}else{$TD_CB_DeviceConnectionTypeText="ssh"}
        <# Create the Main_CredObj #>
        $TD_UserInputCred = "" | Select-Object ID,DeviceTyp,ConnectionTyp,IPAddress,UserName,Password,SSHKeyPath,SVCorVF,MTMCode,ProductDescr,CurrentFirmware,Exportpath
        $TD_UserInputCred.ID               =   $TD_CredentialsCount;
        $TD_UserInputCred.DeviceTyp        =   $TD_CB_DeviceType.Text;
        $TD_UserInputCred.ConnectionTyp    =   $TD_CB_DeviceConnectionTypeText;
        $TD_UserInputCred.IPAddress        =   $TD_TB_DeviceIPAddr.Text;
        $TD_UserInputCred.UserName         =   $TD_TB_DeviceUserName.Text;
        <# The PwLine needs a better Option #>
        $TD_UserInputCred.Password         =   ConvertTo-SecureString $TD_TB_DevicePassword.Password -AsPlainText -Force;
        $TD_UserInputCred.SSHKeyPath       =   $TD_TB_PathtoSSHKeyNotVisibil.Text;
        if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "Storage")){$TD_UserInputCred.SVCorVF = "SVC"}else{if($TD_CB_DeviceType.Text -eq "Storage"){$TD_UserInputCred.SVCorVF = "FSystem"}};
        if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "SAN")){$TD_UserInputCred.SVCorVF = "VF"}else{if($TD_CB_DeviceType.Text -eq "SAN"){$TD_UserInputCred.SVCorVF = ""}};
        $TD_UserInputCred.MTMCode          =   $TD_BasicDeviceInfo.Prod_MTM;
        $TD_UserInputCred.ProductDescr     =   $TD_BasicDeviceInfo.ProductDes;
        $TD_UserInputCred.CurrentFirmware  =   $TD_BasicDeviceInfo.Code_Level;
        $TD_UserInputCred.Exportpath       =   "$PSRootPath\Export\";

        $TD_Credentials += $TD_UserInputCred

        $TD_DG_KnownDeviceList.ItemsSource = $TD_Credentials
    }

    return $TD_Credentials
}