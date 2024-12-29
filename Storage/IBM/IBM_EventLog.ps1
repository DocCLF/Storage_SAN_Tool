function IBM_EventLog {
    <#
    .SYNOPSIS

    .DESCRIPTION

    .EXAMPLE

    .LINK

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Int16]$TD_Line_ID,
        [Parameter(Mandatory)]
        [string]$TD_Device_ConnectionTyp,
        [Parameter(Mandatory)]
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [Parameter(Mandatory)]
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [Parameter(ValueFromPipeline)]
        [ValidateSet("yes","no")]
        [string]$TD_Export = "yes",
        [string]$TD_Storage,
        [string]$TD_Exportpath
    )
    
    begin{
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        $ProgressBar = New-ProgressBar
        Write-Debug -Message "IBM_EventLog Begin block |$(Get-Date)"
        [int]$ProgCounter=0

        <# Action when all if and elseif conditions are false #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CollectEventInfo = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP "lseventlog -delim :"
        }else {
            $TD_CollectEventInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "lseventlog -delim :"
        }
        
        $TD_CollectEventInfo = $TD_CollectEventInfo | Select-Object -Skip 1
        
    }

    process{
        Write-Debug -Message "IBM_EventLog Process block |$(Get-Date)"

        [array]$TD_EventCollection = foreach($EventLine in $TD_CollectEventInfo){
            <# Node Info#>
            $TD_EventSplitInfo = "" | Select-Object SeqID,LastTime,ObjectType,ObjectID,ObjectName,CopyID,Status,Fixed,ErrorCode,Description

            $TD_EventSplitInfo.SeqID = ($EventLine|Select-String -Pattern '^(\d+)' -AllMatches).Matches.Groups[1].Value
            $TD_Timestamp = ($EventLine|Select-String -Pattern '^(\d+):(\d+)' -AllMatches).Matches.Groups[2].Value
            $TD_EventSplitInfo.LastTime = [datetime]::ParseExact($TD_Timestamp, 'yyMMddHHmmss', [cultureinfo]::InvariantCulture)
            $TD_EventSplitInfo.ObjectType = ($EventLine|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_.]+)' -AllMatches).Matches.Groups[3].Value
            if($TD_EventSplitInfo.ObjectType -ne "cluster"){
                $TD_EventSplitInfo.ObjectID = ($EventLine|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9]+):(\d+)' -AllMatches).Matches.Groups[4].Value
                $TD_EventSplitInfo.ObjectName = ($EventLine|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_.]+):(\d+|):([a-zA-Z0-9-_.]+):' -AllMatches).Matches.Groups[5].Value
            }else {
                $TD_EventSplitInfo.ObjectID = "none"
                $TD_EventSplitInfo.ObjectName = ($EventLine|Select-String -Pattern '^(\d+):(\d+):([a-zA-Z0-9-_.]+):(\d+|):([a-zA-Z0-9-_.]+):' -AllMatches).Matches.Groups[5].Value
            }
            if(!([String]::IsNullOrEmpty(($EventLine|Select-String -Pattern '(0|1):(message|monitoring|expired|alert):' -AllMatches).Matches.Groups[1].Value))){
                $TD_EventSplitInfo.CopyID = ($EventLine|Select-String -Pattern '(0|1):(message|monitoring|expired|alert):' -AllMatches).Matches.Groups[1].Value
            }else {
                $TD_EventSplitInfo.CopyID = "none"
            }
            $TD_EventSplitInfo.Status = ($EventLine|Select-String -Pattern ':(message|monitoring|expired|alert):' -AllMatches).Matches.Groups[1].Value
            $TD_EventSplitInfo.Fixed = ($EventLine|Select-String -Pattern ':(no|yes):' -AllMatches).Matches.Groups[1].Value
            if(!([String]::IsNullOrEmpty(($EventLine|Select-String -Pattern ':(\d{3,4}|):([a-zA-Z0-9\s-_.,]+)$' -AllMatches).Matches.Groups[1].Value))){
                $TD_EventSplitInfo.ErrorCode = ($EventLine|Select-String -Pattern ':(\d{3,4}|):([a-zA-Z0-9\s-_.,]+)$' -AllMatches).Matches.Groups[1].Value
            }else {
                $TD_EventSplitInfo.ErrorCode = "none"
            }
            $TD_EventSplitInfo.Description = ($EventLine|Select-String -Pattern '([a-zA-Z0-9\s-_.,]+)$' -AllMatches).Matches.Groups[1].Value

            $TD_EventSplitInfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_CollectEventInfo.Count) * 100)
        }
    }
    
    end {

        if($TD_Line_ID -eq 1){$TD_lb_StoEventLogOne.Visibility="visible"  ;$TD_lb_StoEventLogOne.Content= $TD_Device_DeviceName }
        if($TD_Line_ID -eq 2){$TD_lb_StoEventLogTwo.Visibility="visible"  ;$TD_lb_StoEventLogTwo.Content=$TD_Device_DeviceName }
        if($TD_Line_ID -eq 3){$TD_lb_StoEventLogThree.Visibility="visible";$TD_lb_StoEventLogThree.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 4){$TD_lb_StoEventLogFour.Visibility="visible" ;$TD_lb_StoEventLogFour.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 5){$TD_lb_StoEventLogFive.Visibility="visible" ;$TD_lb_StoEventLogFive.Content=$TD_Device_DeviceName}  
        if($TD_Line_ID -eq 6){$TD_lb_StoEventLogSix.Visibility="visible"  ;$TD_lb_StoEventLogSix.Content=$TD_Device_DeviceName }  
        if($TD_Line_ID -eq 7){$TD_lb_StoEventLogSeven.Visibility="visible";$TD_lb_StoEventLogSeven.Content=$TD_Device_DeviceName}
        if($TD_Line_ID -eq 8){$TD_lb_StoEventLogEight.Visibility="visible";$TD_lb_StoEventLogEight.Content=$TD_Device_DeviceName}
        
        Close-ProgressBar -ProgressBar $ProgressBar
        <# returns the hashtable for further processing, not mandatory but the safe way #>
        Write-Debug -Message "IBM_EventLog End block |$(Get-Date) `n"
        <# export y or n #>
        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSRootPath\ToolLog\"){
                $TD_EventCollection | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_EventLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_EventLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_EventCollection | Export-Csv -Path $PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_EventLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSScriptRoot\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_EventLog_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_EventCollection
        }
        return $TD_EventCollection |Select-Object -Last 100
    }
}