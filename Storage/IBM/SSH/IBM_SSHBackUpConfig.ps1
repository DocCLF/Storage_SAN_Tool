function IBM_SSHBackUpConfig {
    <#
    .SYNOPSIS
    .DESCRIPTION
        Used as a placeholder for the moment, but can also be used as a standalone function!
        Version 1.0.0 | 20240730
    .EXAMPLE
    .LINK
    #>
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [string]$TD_Exportpath = ".\"
    )
    
    begin{
        $ErrorActionPreference="SilentlyContinue"
        Write-Debug -Message "IBM_BackUpConfig Begin block |$(Get-Date)"
        $IBM_STOSysBackUpInfos =[ordered]@{}
        <# int for the progressbar #>
        [int]$ProgCounter=25
        $ProgressBar = New-ProgressBar
    }

    process{
        SST_ToolMessageCollector -TD_ToolMSGCollector "IBM_BackUpConfig Process block" -TD_ToolMSGType Debug
        
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName) please wait this can take some seconds" -PercentComplete (($ProgCounter/50) * 100)
        Start-Sleep -Seconds 0.5

        $TD_BUInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "svcconfig backup"
        Start-Sleep -Seconds 0.5
        $TD_BUResault = $TD_BUInfo.TrimStart('.')
        pscp -unsafe -pw $TD_Device_PW $TD_Device_UserName@$($TD_Device_DeviceIP):/dumps/svc.config.backup.* $TD_Exportpath
    }

    end {
        $IBM_STOSysBackUpInfos.Add('RowID',"$($TD_Device_UserName.count)|$TD_Line_ID")
        $IBM_STOSysBackUpInfos.Add('DeviceName',$TD_Device_DeviceName)
        $IBM_STOSysBackUpInfos.Add('BackUpMsg',$TD_BUResault)
        Close-ProgressBar -ProgressBar $ProgressBar
        SST_ToolMessageCollector -TD_ToolMSGCollector "IBM_BackUpConfig End block" -TD_ToolMSGType Debug
        return $IBM_STOSysBackUpInfos
    }
}