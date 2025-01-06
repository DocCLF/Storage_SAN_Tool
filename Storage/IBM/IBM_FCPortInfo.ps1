function IBM_FCPortInfo {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Storage,
        [string]$TD_Exportpath,
        [int]$TD_i=0
    )
    
    begin{
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        <# int for the progressbar #>
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connection to the system via ssh and filtering and provision of data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CollectFCPortInfos = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP "lstargetportfc -nohdr -delim : && lsportfc -delim :"
        }else {
            $TD_CollectFCPortInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "lstargetportfc -nohdr -delim : && lsportfc -delim :"
        }

        $TD_TargetPortInfos = foreach ($TD_PortTemp in $TD_CollectFCPortInfos){
            if($TD_PortTemp -like "*id:fc_io_port_id:port_id:*"){
                $TD_PortFCInfos = $TD_CollectFCPortInfos |Select-Object -Skip ($TD_i +1) #-SkipLast 1
                break
            }else{
                $TD_i++
                $TD_PortTemp
            }
        }
    }
    
    process {
        $TD_FCPortInfoResault = foreach($TD_FCPortMore in $TD_TargetPortInfos){
            $TD_FCPortInfo = "" | Select-Object CardID,CardPortID,Speed,Status,WWPN,WWNN,NodeName,HostIOPermitted,Virtualized,Protocol,HostCount,ActiveLoginCount,Attachment
            #Infos from lstargetportfc
            $TD_FCPortInfo.WWPN = ($TD_FCPortMore|Select-String -Pattern '^\d+:([0-9A-z]+):' -AllMatches).Matches.Groups[1].Value
            $TD_FCPortInfo.WWNN = ($TD_FCPortMore|Select-String -Pattern '^\d+:([0-9A-z]+):([0-9A-z]+):' -AllMatches).Matches.Groups[2].Value
            $TD_FCPortInfo.HostIOPermitted = ($TD_FCPortMore|Select-String -Pattern ':(yes|no):(yes|no):(scsi|nvme)' -AllMatches).Matches.Groups[1].Value
            $TD_FCPortInfo.Virtualized = ($TD_FCPortMore|Select-String -Pattern ':(yes|no):(yes|no):(scsi|nvme)' -AllMatches).Matches.Groups[2].Value
            $TD_FCPortInfo.Protocol = ($TD_FCPortMore|Select-String -Pattern ':(yes|no):(yes|no):(scsi|nvme)' -AllMatches).Matches.Groups[3].Value
            $TD_FCPortInfo.HostCount = ($TD_FCPortMore|Select-String -Pattern ':(\d+):\d+$' -AllMatches).Matches.Groups[1].Value
            $TD_FCPortInfo.ActiveLoginCount = ($TD_FCPortMore|Select-String -Pattern ':\d+:(\d+)$' -AllMatches).Matches.Groups[1].Value

            $TD_TargetPortFCPortID = ($TD_FCPortMore|Select-String -Pattern '^\d+:([0-9A-z]+):([0-9A-z]+):(\d+):' -AllMatches).Matches.Groups[3].Value
            $TD_FCPortInfoWWNN = $($TD_FCPortInfo.WWNN).Substring($TD_FCPortInfo.WWNN.Length -4)

            foreach ($TD_FCPort in $TD_PortFCInfos){
                #Infos from lsportfc
                $TD_LSPortFCWWPN = ($TD_FCPort|Select-String -Pattern ':([a-zA-Z0-9-_]+):([a-zA-Z0-9-_]+):(active|inactive_configured|inactive_unconfigured|disabled):' -AllMatches).Matches.Groups[1].Value
                $TD_LSPortFCWWPNEnd = $TD_LSPortFCWWPN.Substring($TD_LSPortFCWWPN.Length -4)
                if($TD_FCPortInfoWWNN -ne $TD_LSPortFCWWPNEnd){continue}

                $TD_LSPortFCPortID = ($TD_FCPort|Select-String -Pattern ':(\d+):fc:' -AllMatches).Matches.Groups[1].Value
                
                if($TD_FCPortInfo.WWPN -eq $TD_LSPortFCWWPN){[bool]$TD_WWPNaEqual = $true}
                if(($TD_WWPNaEqual)-and ($TD_TargetPortFCPortID -eq $TD_LSPortFCPortID)){
                    $TD_FCPortInfo.CardID = ($TD_FCPort|Select-String -Pattern ':(\d+):\d+$' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.CardPortID = ($TD_FCPort|Select-String -Pattern ':(\d+)$' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.Speed = ($TD_FCPort|Select-String -Pattern ':(N/A|\d+Gb):' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.Status = ($TD_FCPort|Select-String -Pattern ':(active|inactive_configured|inactive_unconfigured|disabled):' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.NodeName = ($TD_FCPort|Select-String -Pattern ':(N/A|\d+Gb):\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
                    $TD_FCPortInfo.Attachment = ($TD_FCPort|Select-String -Pattern ':(active|inactive_configured|inactive_unconfigured|disabled):(switch|none|[a-zA-Z]+):' -AllMatches).Matches.Groups[2].Value
                }
            }
            $TD_FCPortInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_FCPortInfo.NodeName)" -PercentComplete (($ProgCounter/$TD_TargetPortInfos.Count) * 100)
            Start-Sleep -Seconds 0.2
        }
    }
    
    end {
        if($TD_Line_ID -eq 1){$TD_CB_STO_DG1.IsChecked="true";$TD_CB_STO_DG1.Visibility="visible";$TD_LB_STO_DG1.Visibility="visible"; $TD_LB_STO_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_CB_STO_DG2.IsChecked="true";$TD_CB_STO_DG2.Visibility="visible";$TD_LB_STO_DG2.Visibility="visible"; $TD_LB_STO_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_CB_STO_DG3.IsChecked="true";$TD_CB_STO_DG3.Visibility="visible";$TD_LB_STO_DG3.Visibility="visible"; $TD_LB_STO_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_CB_STO_DG4.IsChecked="true";$TD_CB_STO_DG4.Visibility="visible";$TD_LB_STO_DG4.Visibility="visible"; $TD_LB_STO_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_CB_STO_DG5.IsChecked="true";$TD_CB_STO_DG5.Visibility="visible";$TD_LB_STO_DG5.Visibility="visible"; $TD_LB_STO_DG5.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 6){$TD_CB_STO_DG6.IsChecked="true";$TD_CB_STO_DG6.Visibility="visible";$TD_LB_STO_DG6.Visibility="visible"; $TD_LB_STO_DG6.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 7){$TD_CB_STO_DG7.IsChecked="true";$TD_CB_STO_DG7.Visibility="visible";$TD_LB_STO_DG7.Visibility="visible"; $TD_LB_STO_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_CB_STO_DG8.IsChecked="true";$TD_CB_STO_DG8.Visibility="visible";$TD_LB_STO_DG8.Visibility="visible"; $TD_LB_STO_DG8.Content=$TD_Device_DeviceName}
        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_FCPortInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($_.DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($_.DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_FCPortInfoResault | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($_.DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($_.DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_FCPortInfoResault
        }
        return $TD_FCPortInfoResault
    }
}