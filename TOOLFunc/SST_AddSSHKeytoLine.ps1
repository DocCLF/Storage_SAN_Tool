function AddSSHKeytoLine {
    param (
        [Int16]$TD_SSHKeyForLine,
        [string]$TD_Storage
    )
    switch ($TD_SSHKeyForLine) {
        1 { 
            $TD_ImportaddsshkeyObj = SST_OpenFile_from_Directory
            if($TD_ImportaddsshkeyObj.FileName -ne ""){
                $TD_IsKeyInOne = ssh-add $TD_ImportaddsshkeyObj.FileName 2>&1
                if(!($($TD_IsKeyInOne.GetType().Name) -eq "ErrorRecord")){
                    if($TD_Storage -eq "yes"){
                        $TD_tb_pathtokeyone.IsReadOnly="True"
                        $TD_tb_pathtokeyone.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeyone.Background="LightGreen"
                        $TD_btn_addsshkeyone.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to Storage Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }else{
                        $TD_tb_pathtokeyoneSAN.IsReadOnly="True"
                        $TD_tb_pathtokeyoneSAN.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeyoneSAN.Background="LightGreen"
                        $TD_btn_addsshkeyoneSAN.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to SAN Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }
                }else{
                    SST_ToolMessageCollector -TD_ToolMSGCollector $($TD_SSHKeyForLine,$TD_IsKeyInOne.GetType() -join " get a ") -TD_ToolMSGType Warning
                    Write-Debug -Message $TD_IsKeyInOne
                }
            }
        }
        2 {    
            $TD_ImportaddsshkeyObj = SST_OpenFile_from_Directory
            if($TD_ImportaddsshkeyObj.FileName -ne ""){
                $TD_IsKeyInTwo = ssh-add $TD_ImportaddsshkeyObj.FileName 2>&1
                if(!($($TD_IsKeyInTwo.GetType().Name) -eq "ErrorRecord")){
                    if($TD_Storage -eq "yes"){
                        $TD_tb_pathtokeytwo.IsReadOnly="True"
                        $TD_tb_pathtokeytwo.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeytwo.Background="LightGreen"
                        $TD_btn_addsshkeytwo.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to Storage Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }else {
                        $TD_tb_pathtokeytwoSAN.IsReadOnly="True"
                        $TD_tb_pathtokeytwoSAN.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeytwoSAN.Background="LightGreen"
                        $TD_btn_addsshkeytwoSAN.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to SAN Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }
                }else{
                    SST_ToolMessageCollector -TD_ToolMSGCollector $($TD_SSHKeyForLine,$TD_IsKeyInOne.GetType() -join " get a ") -TD_ToolMSGType Warning
                    Write-Debug -Message $TD_IsKeyInTwo
                }
            }
        }
        3 {    
            $TD_ImportaddsshkeyObj = SST_OpenFile_from_Directory
            if($TD_ImportaddsshkeyObj.FileName -ne ""){
                $TD_IsKeyInThree = ssh-add $TD_ImportaddsshkeyObj.FileName 21
                if(!($($TD_IsKeyInThree.GetType().Name) -eq "ErrorRecord")){
                    if($TD_Storage -eq "yes"){
                        $TD_tb_pathtokeythree.IsReadOnly="True"
                        $TD_tb_pathtokeythree.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeythree.Background="LightGreen"
                        $TD_btn_addsshkeythree.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to Storage Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }else {
                        $TD_tb_pathtokeythreeSAN.IsReadOnly="True"
                        $TD_tb_pathtokeythreeSAN.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeythreeSAN.Background="LightGreen"
                        $TD_btn_addsshkeythreeSAN.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to SAN Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }
                }else{
                    SST_ToolMessageCollector -TD_ToolMSGCollector $($TD_SSHKeyForLine,$TD_IsKeyInOne.GetType() -join " get a ") -TD_ToolMSGType Warning
                    Write-Debug -Message $TD_IsKeyInThree
                }
            }
        }
        4 {    
            $TD_ImportaddsshkeyObj = SST_OpenFile_from_Directory
            if($TD_ImportaddsshkeyObj.FileName -ne ""){
                $TD_IsKeyInFour = ssh-add $TD_ImportaddsshkeyObj.FileName 2>&1
                if(!($($TD_IsKeyInFour.GetType().Name) -eq "ErrorRecord")){
                    if($TD_Storage -eq "yes"){
                        $TD_tb_pathtokeyfour.IsReadOnly="True"
                        $TD_tb_pathtokeyfour.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeyfour.Background="LightGreen"
                        $TD_btn_addsshkeyfour.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to Storage Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }else {
                        $TD_tb_pathtokeyfourSAN.IsReadOnly="True"
                        $TD_tb_pathtokeyfourSAN.Text= "$($TD_ImportaddsshkeyObj.FileName)" 
                        $TD_btn_addsshkeyfourSAN.Background="LightGreen"
                        $TD_btn_addsshkeyfourSAN.Content="Remove Key"
                        SST_ToolMessageCollector -TD_ToolMSGCollector $("SSH-Key is added to SAN Cred Line $TD_SSHKeyForLine") -TD_ToolMSGType Message
                    }
                }else{
                    SST_ToolMessageCollector -TD_ToolMSGCollector $($TD_SSHKeyForLine,$TD_IsKeyInOne.GetType() -join " get a ") -TD_ToolMSGType Warning
                    Write-Debug -Message $TD_IsKeyInFour
                }
            }
        }
        Default {
            if($TD_Storage -eq "yes"){ 
                $TD_DeviceIs="Storage" 
            }else {
                $TD_DeviceIs="SAN"
            }
            SST_ToolMessageCollector -TD_ToolMSGCollector $("Line $TD_SSHKeyForLine get a Error at $TD_DeviceIs Type") -TD_ToolMSGType Error
        }
    }
}