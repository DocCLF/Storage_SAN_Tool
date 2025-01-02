function AddSSHKeytoLine {
    param (
        [string]$TD_Storage
    )

    $TD_ImportaddsshkeyObj = SST_OpenFile_from_Directory
    if($TD_ImportaddsshkeyObj.FileName -ne ""){
        $TD_IsKeyInOne = ssh-add $TD_ImportaddsshkeyObj.FileName 2>&1
        if(!($($TD_IsKeyInOne.GetType().Name) -eq "ErrorRecord")){
            if($TD_Storage -eq "yes"){
                $TD_TB_PathtoSSHKeyNotVisibil.IsReadOnly="True"
                $TD_TB_PathtoSSHKeyNotVisibil.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                $TD_BTN_AddSSHKey.Background="LightGreen"
                $TD_BTN_AddSSHKey.Content="Remove Key"
                SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to Storage Cred Line") -TD_ToolMSGType Message
            }else{
                $TD_TB_PathtoSSHKeyNotVisibil.IsReadOnly="True"
                $TD_TB_PathtoSSHKeyNotVisibil.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                $TD_BTN_AddSSHKey.Background="LightGreen"
                $TD_BTN_AddSSHKey.Content="Remove Key"
                SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to SAN Cred Line") -TD_ToolMSGType Message
            }
        }else{
            SST_ToolMessageCollector -TD_ToolMSGCollector $($TD_SSHKeyForLine,$TD_IsKeyInOne.GetType() -join " get a ") -TD_ToolMSGType Warning
            Write-Debug -Message $TD_IsKeyInOne
        }
    }

}