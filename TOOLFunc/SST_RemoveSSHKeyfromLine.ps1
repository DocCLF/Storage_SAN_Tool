function RemoveSSHKeyfromLine {
    param (
        [Int16]$TD_SSHKeyForLine,
        [string]$TD_Storage
    )
    switch ($TD_SSHKeyForLine) {
        1 { 
            if($TD_Storage -eq "yes"){
                $SSHKeyNamePath=$TD_tb_pathtokeyone.Text
                $TD_tb_pathtokeyone.Text= ""
            }else {
                $SSHKeyNamePath=$TD_tb_pathtokeyoneSAN.Text
                $TD_tb_pathtokeyoneSAN.Text= ""
            }
            $SSHKeyName = Split-Path -Path $SSHKeyNamePath -Leaf
            ssh-add -d $SSHKeyName
            if($TD_Storage -eq "yes"){
                $TD_btn_addsshkeyone.Content="Add SSH-Key"
                $TD_btn_addsshkeyone.Background="#FFDDDDDD"
            }else {
                $TD_btn_addsshkeyoneSAN.Content="Add SSH-Key"
                $TD_btn_addsshkeyoneSAN.Background="#FFDDDDDD"
            }
        }
        2 { 
            if($TD_Storage -eq "yes"){
                $SSHKeyNamePath=$TD_tb_pathtokeytwo.Text
                $TD_tb_pathtokeytwo.Text= ""
            }else {
                $SSHKeyNamePath=$TD_tb_pathtokeytwoSAN.Text
                $TD_tb_pathtokeytwoSAN.Text= ""
            }
            $SSHKeyName = Split-Path -Path $SSHKeyNamePath -Leaf
            ssh-add -d $SSHKeyName
            if($TD_Storage -eq "yes"){
                $TD_btn_addsshkeytwo.Content="Add SSH-Key"
                $TD_btn_addsshkeytwo.Background="#FFDDDDDD"
            }else {
                $TD_btn_addsshkeytwoSAN.Content="Add SSH-Key"
                $TD_btn_addsshkeytwoSAN.Background="#FFDDDDDD"
            }
        }
        3 { 
            if($TD_Storage -eq "yes"){
                $SSHKeyNamePath=$TD_tb_pathtokeythree.Text
                $TD_tb_pathtokeythree.Text= ""
            }else {
                $SSHKeyNamePath=$TD_tb_pathtokeythreeSAN.Text
                $TD_tb_pathtokeythreeSAN.Text= ""
            }
            $SSHKeyName = Split-Path -Path $SSHKeyNamePath -Leaf
            ssh-add -d $SSHKeyName
            if($TD_Storage -eq "yes"){
                $TD_btn_addsshkeythree.Content="Add SSH-Key"
                $TD_btn_addsshkeythree.Background="#FFDDDDDD"
            }else {
                $TD_btn_addsshkeythreeSAN.Content="Add SSH-Key"
                $TD_btn_addsshkeythreeSAN.Background="#FFDDDDDD"
            }
        }
        4 { 
            if($TD_Storage -eq "yes"){
                $SSHKeyNamePath=$TD_tb_pathtokeyfour.Text
                $TD_tb_pathtokeyfour.Text= ""
            }else {
                $SSHKeyNamePath=$TD_tb_pathtokeyfourSAN.Text
                $TD_tb_pathtokeyfourSAN.Text= ""
            }
            $SSHKeyName = Split-Path -Path $SSHKeyNamePath -Leaf
            ssh-add -d $SSHKeyName
            if($TD_Storage -eq "yes"){
                $TD_btn_addsshkeyfour.Content="Add SSH-Key"
                $TD_btn_addsshkeyfour.Background="#FFDDDDDD"
            }else {
                $TD_btn_addsshkeyfourSAN.Content="Add SSH-Key"
                $TD_btn_addsshkeyfourSAN.Background="#FFDDDDDD"
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
