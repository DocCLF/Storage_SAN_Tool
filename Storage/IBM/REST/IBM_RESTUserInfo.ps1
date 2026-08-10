function IBM_RESTUserInfo {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        #[string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath,
        $body = @{} <# This is the only part you are allowed to change. #>
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        $BaseUrl = "https://$TD_Device_DeviceIP"+":7443"
        if(Test-Path -Path "$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db"){
            $RESTInfo = SST_RESTDBControl -SST_InfoType "UseStorageToken" -SST_BaseUrl $BaseUrl
            if(([string]::IsNullOrEmpty($RESTInfo)) -and ($TD_Device_ConnectionTyp -eq "REST")){
                $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            }
        }
        if([string]::IsNullOrWhiteSpace($TD_Device_ConnectionTyp)){
            $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW 
        }
        Clear-Variable -Name TD_Device_PW -Force
        if($TD_Device_ConnectionTyp -eq "REST"){
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsuser -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
        [int]$imax = $STONodeInfo.Count
        for ($i = 0; $i -le $imax; $i++) {
            if($STONodeInfo.config_node[$i] -eq "yes"){
                $IBMSTOWWNN = $STONodeInfo.WWNN[$i]
                $IBMSTOSN = if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}
            }
        }
    }

    process{
        [int]$imax = $TD_DeviceInformation.Count
        [array]$TD_UserInfoResault = for ($i = 0; $i -le $imax; $i++) {
            if([string]::IsNullOrWhiteSpace($TD_DeviceInformation.id[$i])){continue}
            <# Node Info#>
            $TD_Userinfo = "" | Select-Object ID,UserName,Password,SSHKey,Remote,UserGrpID,UserGrpName,OwnerID,OwnerName,Locked,PWChangerequired,WWNN,SerialNumber,RowID

            $TD_Userinfo.ID                 = $TD_DeviceInformation.id[$i]
            $TD_Userinfo.UserName          = $TD_DeviceInformation.name[$i]
            $TD_Userinfo.Password           = $TD_DeviceInformation.password[$i]
            $TD_Userinfo.SSHKey            = $TD_DeviceInformation.ssh_key[$i]
            $TD_Userinfo.Remote             = $TD_DeviceInformation.remote[$i]
            $TD_Userinfo.UserGrpID         = $TD_DeviceInformation.usergrp_id[$i]
            $TD_Userinfo.UserGrpName       = $TD_DeviceInformation.usergrp_name[$i]
            $TD_Userinfo.OwnerID           = $TD_DeviceInformation.owner_id[$i]
            $TD_Userinfo.OwnerName         = $TD_DeviceInformation.owner_name[$i]
            $TD_Userinfo.Locked             = $TD_DeviceInformation.locked[$i]
            $TD_Userinfo.PWChangerequired = $TD_DeviceInformation.password_change_required[$i]
            $TD_Userinfo.RowID          = "$IBMSTOSN|$($TD_DeviceInformation.id)"

            $TD_Userinfo.WWNN = $IBMSTOWWNN
            $TD_Userinfo.SerialNumber = $IBMSTOSN

            $TD_Userinfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($IBMSTOSN)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_UserInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_UserInfoResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_User_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_UserInfoResault
        }
        return $TD_UserInfoResault
    }
}