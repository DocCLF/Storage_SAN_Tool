function IBM_FCPortInfo {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )
    
    begin{
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        <# int for the progressbar #>
        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar
        <# Connection to the system via ssh and filtering and provision of data #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CollectFCPortInfos = ssh $TD_Device_UserName@$TD_Device_DeviceIP "lstargetportfc -nohdr -delim : && lsportfc -delim :"
        }else {
            $TD_CollectFCPortInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "lstargetportfc -nohdr -delim : && lsportfc -delim :"
        }
        [int]$TD_i=0
        $TD_CollectFCPortInfos = Get-Content -Path D:\GitRepo\Storage_SAN_Kit\fcinfo.txt
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
            $TD_FCPortInfo.HostIOPermitted = ($TD_FCPortMore|Select-String -Pattern ':(yes|no):(yes|no):(scsi|nvme):' -AllMatches).Matches.Groups[1].Value
            $TD_FCPortInfo.Virtualized = ($TD_FCPortMore|Select-String -Pattern ':(yes|no):(yes|no):(scsi|nvme):' -AllMatches).Matches.Groups[2].Value
            $TD_FCPortInfo.Protocol = ($TD_FCPortMore|Select-String -Pattern ':(yes|no):(yes|no):(scsi|nvme):' -AllMatches).Matches.Groups[3].Value
            $TD_FCPortInfo.HostCount = ($TD_FCPortMore|Select-String -Pattern ':(\d+):\d+$' -AllMatches).Matches.Groups[1].Value
            $TD_FCPortInfo.ActiveLoginCount = ($TD_FCPortMore|Select-String -Pattern ':\d+:(\d+)$' -AllMatches).Matches.Groups[1].Value
            
            Write-Host $TD_FCPortInfo.WWPN
            foreach ($TD_FCPort in $TD_PortFCInfos){
                #Infos from lsportfc
                $TD_LSPortFCWWPN = ($TD_FCPort|Select-String -Pattern ':([a-zA-Z0-9-_]+):([a-zA-Z0-9-_]+):(active|inactive_configured|inactive_unconfigured|disabled):' -AllMatches).Matches.Groups[1].Value
                if($TD_FCPortInfo.WWPN -eq $TD_LSPortFCWWPN){
                    $TD_FCPortInfo.CardID = ($TD_FCPort|Select-String -Pattern ':(\d+):\d+$' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.CardPortID = ($TD_FCPort|Select-String -Pattern ':(\d+)$' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.Speed = ($TD_FCPort|Select-String -Pattern ':(N/A|\d+Gb):' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.Status = ($TD_FCPort|Select-String -Pattern ':(active|inactive_configured|inactive_unconfigured|disabled):' -AllMatches).Matches.Groups[1].Value
                    $TD_FCPortInfo.NodeName = ($TD_FCPort|Select-String -Pattern ':(N/A|\d+Gb):\d+:([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
                    $TD_FCPortInfo.Attachment = ($TD_FCPort|Select-String -Pattern ':(active|inactive_configured|inactive_unconfigured|disabled):(switch|none|[a-zA-Z]+):' -AllMatches).Matches.Groups[2].Value
                    break
                }
            }
            $TD_FCPortInfo

            <# Progressbar  #>
            #$ProgCounter++
            #Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_CollectFCPortInfos.Count) * 100)
            #Start-Sleep -Seconds 0.5
        }
    }
    
    end {
        
    }
}