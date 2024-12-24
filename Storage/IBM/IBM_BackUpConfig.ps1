function IBM_BackUpConfig {
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
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Storage,
        [string]$TD_Exportpath

    )
    
    begin{
        $ErrorActionPreference="SilentlyContinue"
        Write-Debug -Message "IBM_BackUpConfig Begin block |$(Get-Date)"
        <# int for the progressbar #>
        [int]$ProgCounter=25
        $ProgressBar = New-ProgressBar
    }

    process{
        Write-Debug -Message "IBM_BackUpConfig Process block |$(Get-Date)"
        
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) please wait this can take some seconds" -PercentComplete (($ProgCounter/50) * 100)
        Start-Sleep -Seconds 0.5

        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_BUInfo = ssh -i $($TD_tb_pathtokey.Text) $TD_Device_UserName@$TD_Device_DeviceIP "svcconfig backup"
            $TD_BUResault = $TD_BUInfo.TrimStart('.')
            Start-Sleep -Seconds 0.5
            pscp -unsafe -pw $TD_Device_PW $TD_Device_UserName@$($TD_Device_DeviceIP):/dumps/svc.config.backup.* $TD_Exportpath
        }else {
            $TD_BUInfo = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "svcconfig backup"
            Start-Sleep -Seconds 0.5
            $TD_BUResault = $TD_BUInfo.TrimStart('.')
            pscp -unsafe -pw $TD_Device_PW $TD_Device_UserName@$($TD_Device_DeviceIP):/dumps/svc.config.backup.* $TD_Exportpath
        }
    }

    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        Write-Debug -Message "IBM_BackUpConfig End block |$(Get-Date) `n"
        return $TD_BUResault
        Clear-Variable TD* -Scope Global
    }
}