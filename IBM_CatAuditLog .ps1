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
        Write-Debug -Message "IBM_CatAuditLog Begin block |$(Get-Date)"

        [int]$ProgCounter=0
        $ProgressBar = New-ProgressBar

        <# Action when all if and elseif conditions are false #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CatAuditLogInfos = ssh $TD_Device_UserName@$TD_Device_DeviceIP "catauditlog -delim :"
        }else {
            $TD_CatAuditLogInfos = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "catauditlog -delim :"
        }
    }

    process{
        Write-Debug -Message "IBM_CatAuditLog Process block |$(Get-Date)"


        $TD_AuditLog = foreach ($TD_CatAuditLogInfo in $TD_CatAuditLogInfos){
            $TD_CatAuditLog = "" | Select-Object AuditSeqNo,TimeStamp,User,SourceAddress,ActionCommand
            $TD_CatAuditLog.AuditSeqNo = ($TD_CatAuditLogInfo|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[1].Value
            $TD_CatAuditLog.TimeStamp = ($TD_CatAuditLogInfo|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[2].Value
            $TD_CatAuditLog.User = ($TD_CatAuditLogInfo|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_]+):' -AllMatches).Matches.Groups[3].Value
            $TD_CatAuditLog.SourceAddress = ($TD_CatAuditLogInfo|Select-String -Pattern ':(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):' -AllMatches).Matches.Groups[2].Value
            $TD_CatAuditLog.ActionCommand = ($TD_CatAuditLogInfo|Select-String -Pattern ':\d+:(\d+|):(.*)$' -AllMatches).Matches.Groups[1].Value
            $TD_CatAuditLog

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID)" -PercentComplete (($ProgCounter/$TD_CatAuditLogInfos.Count) * 100)
            Start-Sleep -Seconds 0.5
        
        }


    }
    end {

        Close-ProgressBar -ProgressBar $ProgressBar

        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\Export\"){
                $TD_AuditLog | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_AuditLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }else {
                $TD_AuditLog | Export-Csv -Path $PSCommandPath\Export\$($TD_Line_ID)_AuditLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            }
        }else {
            <# output on the promt #>
            return $TD_AuditLog
        }
        return $TD_AuditLog
    }
}