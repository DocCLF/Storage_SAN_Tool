function RemoveSSHKeyfromLine {
    param (
        [string]$TD_Storage
    )

            if($TD_Storage -eq "yes"){
                $SSHKeyNamePath=$TD_TB_PathtoSSHKeyNotVisibil.Text
                $TD_TB_PathtoSSHKeyNotVisibil.Text= ""
            }else {
                $SSHKeyNamePath=$TD_TB_PathtoSSHKeyNotVisibil.Text
                $TD_TB_PathtoSSHKeyNotVisibil.Text= ""
            }
            $SSHKeyName = Split-Path -Path $SSHKeyNamePath -Leaf
            ssh-add -d $SSHKeyName
            if($TD_Storage -eq "yes"){
                $TD_BTN_AddSSHKey.Content="Add SSH-Key"
                $TD_BTN_AddSSHKey.Background="#FFDDDDDD"
            }else {
                $TD_BTN_AddSSHKey.Content="Add SSH-Key"
                $TD_BTN_AddSSHKey.Background="#FFDDDDDD"
            }

}
