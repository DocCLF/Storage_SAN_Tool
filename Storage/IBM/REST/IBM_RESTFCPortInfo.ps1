function IBM_RESTFCPortInfo {
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
                SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW
            }
        }
        if([string]::IsNullOrWhiteSpace($TD_Device_ConnectionTyp)){
            $TD_Device_ConnectionTyp = SST_GetSpectrumToken -TD_Device_UserName $TD_Device_UserName -TD_Device_DeviceIP $TD_Device_DeviceIP -TD_Device_PW $TD_Device_PW 
        }
        Clear-Variable -Name TD_Device_PW -Force
        if($TD_Device_ConnectionTyp -eq "REST"){
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lstargetportfc -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $TD_SecondDeviceInformation = SST_SpectrumSystemAPI -Endpoint lsportfc -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            $STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
        [int]$imax = $STONodeInfo.Count
        for ($i = 0; $i -le $imax; $i++) {
            if($STONodeInfo.config_node[$i] -eq "yes"){
                #$IBMSTOWWNN = $STONodeInfo.WWNN[$i] <# not needed here#>
                $IBMSTOSN = if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}
            }
        }
    }

    process{
        [int]$imax = $TD_DeviceInformation.Count
        [array]$TD_FCPortInfoResault = for ($i = 0; $i -le $imax; $i++) {
            <# Node Info#>
            $TD_FCPortInfo = "" | Select-Object ID,CardID,CardPortID,Speed,Status,WWPN,WWNN,NodeName,HostIOPermitted,Virtualized,Protocol,HostCount,ActiveLoginCount,Attachment,SerialNumber
            <# Infos from lstargetportfc #>
            $TD_FCPortInfo.ID                 = $TD_DeviceInformation.id[$i]
            $TD_FCPortInfo.WWPN               = $TD_DeviceInformation.WWPN[$i]
            $TD_FCPortInfo.WWNN               = $TD_DeviceInformation.WWNN[$i]
            $TD_FCPortInfo.HostIOPermitted    = $TD_DeviceInformation.host_io_permitted[$i]
            $TD_FCPortInfo.Virtualized        = $TD_DeviceInformation.virtualized[$i]
            $TD_FCPortInfo.Protocol           = $TD_DeviceInformation.protocol[$i]
            $TD_FCPortInfo.HostCount          = $TD_DeviceInformation.host_count[$i]
            $TD_FCPortInfo.ActiveLoginCount   = $TD_DeviceInformation.active_login_count[$i]
            
            <# Infos from lsportfc #>
            if(($TD_DeviceInformation.WWPN[$i]) -eq($TD_SecondDeviceInformation.WWPN[$i])){
                $TD_FCPortInfo.CardID             = $TD_SecondDeviceInformation.adapter_location[$i]
                $TD_FCPortInfo.CardPortID         = $TD_SecondDeviceInformation.adapter_location[$i]
                $TD_FCPortInfo.Speed              = $TD_SecondDeviceInformation.port_speed[$i]
                $TD_FCPortInfo.Status             = $TD_SecondDeviceInformation.status[$i]
                $TD_FCPortInfo.NodeName           = $TD_SecondDeviceInformation.node_name[$i]
                $TD_FCPortInfo.Attachment         = $TD_SecondDeviceInformation.attachment[$i]
            }

            $TD_FCPortInfo.SerialNumber = $IBMSTOSN

            $TD_FCPortInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        <# export y or n #>
        if($TD_export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_FCPortInfoResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_FCPortInfoResault | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_FCPortInfoOverview_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_FCPortInfoResault
        }
        return $TD_FCPortInfoResault
    }
}