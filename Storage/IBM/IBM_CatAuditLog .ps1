function IBM_CatAuditLog {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE

    .LINK
 
    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Storage,
        [string]$TD_Exportpath
    )
    
    begin{
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"

        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar

        <# Action when all if and elseif conditions are false #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CatAuditLogInfos = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP "catauditlog -delim :"
        }else {
            $TD_CatAuditLogInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "catauditlog -delim :"
        }
        $TD_CatAuditLogInfos = $TD_CatAuditLogInfos | Select-Object -Last 75
    }

    process{
        $TD_AuditLog = foreach ($TD_CatAuditLogInfo in $TD_CatAuditLogInfos){
            $TD_CatAuditLog = "" | Select-Object AuditSeqNo,TimeStamp,User,SourceAddress,ActionCommand
            $TD_CatAuditLog.AuditSeqNo = ($TD_CatAuditLogInfo|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_CatAuditLog.TimeStamp = ($TD_CatAuditLogInfo|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
            $TD_CatAuditLog.User = ($TD_CatAuditLogInfo|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[3].Value
            $TD_CatAuditLog.SourceAddress = ($TD_CatAuditLogInfo|Select-String -Pattern ':(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):' -AllMatches).Matches.Groups[1].Value
            $TD_CatAuditLog.ActionCommand = ($TD_CatAuditLogInfo|Select-String -Pattern ':\d+:(\d+|):(.*)$' -AllMatches).Matches.Groups[2].Value
            $TD_CatAuditLog

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_CatAuditLogInfos.Count) * 100)
            Start-Sleep -Seconds 0.5
        }
    }
    end {

        if($TD_Line_ID -eq 1){$TD_lb_StorageAuditLogOne.Visibility="visible"  ;$TD_lb_StorageAuditLogOne.Content=$TD_Device_DeviceName  ;$TD_CB_STO_DG1.Visibility="visible";$TD_LB_STO_DG1.Visibility="visible"; $TD_LB_STO_DG1.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 2){$TD_lb_StorageAuditLogTwo.Visibility="visible"  ;$TD_lb_StorageAuditLogTwo.Content=$TD_Device_DeviceName  ;$TD_CB_STO_DG2.Visibility="visible";$TD_LB_STO_DG2.Visibility="visible"; $TD_LB_STO_DG2.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 3){$TD_lb_StorageAuditLogThree.Visibility="visible";$TD_lb_StorageAuditLogThree.Content=$TD_Device_DeviceName;$TD_CB_STO_DG3.Visibility="visible";$TD_LB_STO_DG3.Visibility="visible"; $TD_LB_STO_DG3.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_lb_StorageAuditLogFour.Visibility="visible" ;$TD_lb_StorageAuditLogFour.Content=$TD_Device_DeviceName ;$TD_CB_STO_DG4.Visibility="visible";$TD_LB_STO_DG4.Visibility="visible"; $TD_LB_STO_DG4.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_lb_StorageAuditLogFive.Visibility="visible" ;$TD_lb_StorageAuditLogFive.Content=$TD_Device_DeviceName ;$TD_CB_STO_DG5.Visibility="visible";$TD_LB_STO_DG5.Visibility="visible"; $TD_LB_STO_DG5.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 6){$TD_lb_StorageAuditLogSix.Visibility="visible"  ;$TD_lb_StorageAuditLogSix.Content=$TD_Device_DeviceName  ;$TD_CB_STO_DG6.Visibility="visible";$TD_LB_STO_DG6.Visibility="visible"; $TD_LB_STO_DG6.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 7){$TD_lb_StorageAuditLogSeven.Visibility="visible";$TD_lb_StorageAuditLogSeven.Content=$TD_Device_DeviceName;$TD_CB_STO_DG7.Visibility="visible";$TD_LB_STO_DG7.Visibility="visible"; $TD_LB_STO_DG7.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_lb_StorageAuditLogEight.Visibility="visible";$TD_lb_StorageAuditLogEight.Content=$TD_Device_DeviceName;$TD_CB_STO_DG8.Visibility="visible";$TD_LB_STO_DG8.Visibility="visible"; $TD_LB_STO_DG8.Content=$TD_Device_DeviceName}

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