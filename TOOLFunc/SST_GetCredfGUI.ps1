function SST_GetCredfGUI {
    [CmdletBinding()]
    param(

    )

    $TD_ExistingCred = $TD_DG_KnownDeviceList.ItemsSource
    [array]$TD_Credentials = $TD_ExistingCred

    $TD_UserInputCred = "" | Select-Object TD_ID,TD_DeviceTyp,TD_ConnectionTyp,TD_IPAdresse,TD_UserName,TD_Password,TD_SSHKeyPath,TD_SVCorVF,TD_Exportpath
    $TD_UserInputCred.TD_ID               =   $TD_Credentials.Count + 1;
    $TD_UserInputCred.TD_DeviceTyp        =   $TD_CB_DeviceType.Text;
    $TD_UserInputCred.TD_ConnectionTyp    =   $TD_CB_DeviceConnectionType.Text;
    $TD_UserInputCred.TD_IPAdresse        =   $TD_TB_DeviceIPAddr.Text;
    $TD_UserInputCred.TD_UserName         =   $TD_TB_DeviceUserName.Text;
    $TD_UserInputCred.TD_Password         =   $TD_TB_DevicePassword.Password;
    $TD_UserInputCred.TD_SSHKeyPath       =   $TD_TB_PathtoSSHKeyNotVisibil.Text;
    if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "Storage")){$TD_UserInputCred.TD_SVCorVF = "SVC"};
    if($TD_CB_SVCorVF.IsChecked -and ($TD_CB_DeviceType.Text -eq "SAN")){$TD_UserInputCred.TD_SVCorVF = "VF"};
    if(!($TD_CB_SVCorVF.IsChecked)){$TD_UserInputCred.TD_SVCorVF = ""};
    $TD_UserInputCred.TD_Exportpath       =   "$PSRootPath\Export\";
                            
    $TD_Credentials += $TD_UserInputCred
    $TD_DG_KnownDeviceList.ItemsSource = $TD_Credentials
    Write-Host $TD_Credentials
    
    return $TD_Credentials
}