function IBM_RESTIPQuorum { 
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsquorum -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
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
        [array]$TD_Quorum = for ($i = 0; $i -lt $imax; $i++) {
            <# Node Info#>
            $TD_QuorumInfo = "" | Select-Object RowID,QuorumIndex,Status,ID,Name,ControllerID,ControllerName,Active,ObjectType,Override,SideID,SideName,WWNN,SerialNumber

            $TD_QuorumInfo.QuorumIndex      = $TD_DeviceInformation.quorum_index[$i]
            $TD_QuorumInfo.Status           = $TD_DeviceInformation.status[$i]
            $TD_QuorumInfo.ID               = $TD_DeviceInformation.id[$i]
            $TD_QuorumInfo.Name             = $TD_DeviceInformation.name[$i]
            $TD_QuorumInfo.ControllerID     = $TD_DeviceInformation.controller_id[$i]
            $TD_QuorumInfo.ControllerName   = $TD_DeviceInformation.controller_name[$i]
            $TD_QuorumInfo.Active           = $TD_DeviceInformation.active[$i]
            $TD_QuorumInfo.ObjectType       = $TD_DeviceInformation.object_type[$i]
            $TD_QuorumInfo.Override         = $TD_DeviceInformation.override[$i]
            $TD_QuorumInfo.SideID           = $TD_DeviceInformation.site_id[$i]
            $TD_QuorumInfo.SideName         = $TD_DeviceInformation.site_name[$i]

            $TD_QuorumInfo.WWNN         = $IBMSTOWWNN
            $TD_QuorumInfo.SerialNumber = $IBMSTOSN
            $TD_QuorumInfo.RowID       = "$IBMSTOSN|$($TD_QuorumInfo.QuorumIndex)"

            $TD_QuorumInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($IBMSTOSN)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {

        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_Quorum | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($IBMSTOSN)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_($IBMSTOSN)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_Quorum | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($IBMSTOSN)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_($IBMSTOSN)_Quorum_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_Quorum
        }
        return $TD_Quorum
    }
}