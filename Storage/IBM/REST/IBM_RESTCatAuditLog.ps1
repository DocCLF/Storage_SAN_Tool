function IBM_RESTCatAuditLog {
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
        $body = @{first = "100";} <# This is the only part you are allowed to change. #>
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
            $TD_CatAuditLogInfo = SST_SpectrumSystemAPI -Endpoint catauditlog -Body $body -BaseUrl $BaseUrl -RESTInfo $RESTInfo
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
        [int]$imax = $TD_CatAuditLogInfo.Count
        [array]$TD_AuditLog = for ($i = 0; $i -le $imax; $i++) {
            <# Node Info#>
            $TD_CatAuditLog = "" | Select-Object AuditSeqNo,TimeStamp,User,Challenge,SourcePanel,TargetPanel,SSH_IP,Result,ResObjID,UsedCommand,Origin,TwoPersonIntegrity,WWNN,SerialNumber

            $TD_CatAuditLog.AuditSeqNo          = $TD_CatAuditLogInfo.audit_seq_no[$i]
            $TD_CatAuditLog.TimeStamp           = $TD_CatAuditLogInfo.timestamp[$i]
            $TD_CatAuditLog.User                = $TD_CatAuditLogInfo.cluster_user[$i]
            $TD_CatAuditLog.Challenge           = $TD_CatAuditLogInfo.challenge[$i]
            $TD_CatAuditLog.SourcePanel         = $TD_CatAuditLogInfo.source_panel[$i]
            $TD_CatAuditLog.TargetPanel         = $TD_CatAuditLogInfo.target_panel[$i]
            $TD_CatAuditLog.SSH_IP              = $TD_CatAuditLogInfo.ssh_ip_address[$i]
            $TD_CatAuditLog.Result              = $TD_CatAuditLogInfo.result[$i]
            $TD_CatAuditLog.ResObjID            = $TD_CatAuditLogInfo.res_obj_id[$i]
            $TD_CatAuditLog.UsedCommand         = $TD_CatAuditLogInfo.action_cmd[$i]
            $TD_CatAuditLog.Origin              = $TD_CatAuditLogInfo.origin[$i]
            $TD_CatAuditLog.TwoPersonIntegrity  = $TD_CatAuditLogInfo.two_person_integrity_promoted[$i]

            $TD_CatAuditLog.WWNN = $IBMSTOWWNN
            $TD_CatAuditLog.SerialNumber = $IBMSTOSN


            $TD_CatAuditLog

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    end {

        Close-ProgressBar -ProgressBar $ProgressBar

        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_AuditLog | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_AuditLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_AuditLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_AuditLog | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_AuditLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_AuditLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_AuditLog
        }
        return $TD_AuditLog
    }
}