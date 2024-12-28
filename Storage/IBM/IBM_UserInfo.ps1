function IBM_UserInfo {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Storage,
        [string]$TD_Exportpath
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connect to Device and get all needed Data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_UserInformation = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP 'lsuser -delim :'
        }else {
            $TD_UserInformation = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch 'lsuser -delim :'
        }
        $TD_UserInformation = $TD_UserInformation |Select-Object -Skip 1
    }
    
    process {
        $TD_UserInfoResault = foreach($TD_User in $TD_UserInformation){
            $TD_Userinfo = "" | Select-Object User_Name,Password,SSH_Key,Remote,UserGrp,Locked,PW_Change_required
            $TD_Userinfo.User_Name = ($TD_User|Select-String -Pattern '^\d+:([a-zA-Z0-9-_]+)' -AllMatches).Matches.Groups[1].Value
            $TD_Userinfo.Password = ($TD_User|Select-String -Pattern ':(yes|no):(yes|no):(yes|no):' -AllMatches).Matches.Groups[1].Value
            $TD_Userinfo.SSH_Key = ($TD_User|Select-String -Pattern ':(yes|no):(yes|no):(yes|no):' -AllMatches).Matches.Groups[2].Value
            $TD_Userinfo.Remote = ($TD_User|Select-String -Pattern ':(yes|no):(yes|no):(yes|no):' -AllMatches).Matches.Groups[3].Value
            $TD_Userinfo.UserGrp = ($TD_User|Select-String -Pattern ':(yes|no):\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
            $TD_Userinfo.Locked = ($TD_User|Select-String -Pattern ':(no|auto|manual):(yes|no)$' -AllMatches).Matches.Groups[1].Value
            $TD_Userinfo.PW_Change_required = ($TD_User|Select-String -Pattern ':(no|auto|manual):(yes|no)$' -AllMatches).Matches.Groups[2].Value

            $TD_Userinfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_UserInformation.Count) * 100)
        }
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_UserInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_UserInfoResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_UserInfoResault
        }
        return $TD_UserInfoResault
    }
}