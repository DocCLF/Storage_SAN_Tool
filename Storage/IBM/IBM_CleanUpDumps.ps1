function IBM_CleanUpDumps {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [Int16]$TD_Line_ID,
        [Parameter(Mandatory)]
        [string]$TD_Device_ConnectionTyp,
        [Parameter(Mandatory)]
        [string]$TD_Device_UserName,
        [string]$TD_DeviceName,
        [Parameter(Mandatory)]
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Device_SSHKeyPath,
        [string]$TD_Storage,
        [string]$TD_Exportpath
    )
    
    begin {
        <# suppresses error messages #>
        $ErrorActionPreference="SilentlyContinue"
        $ProgressBar = New-ProgressBar
        Write-Debug -Message "IBM_CleanUpDumps Begin block |$(Get-Date)"
        [int]$ProgCounter=25
        
        <# Progressbar  #>
        $ProgCounter++
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Delete all unnecessary files from the device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/50) * 100)

    }
    
    process {

        Write-Debug -Message "IBM_CleanUpDumps Process block |$(Get-Date)"
        <# Action when all if and elseif conditions are false #>
        if($TD_Device_ConnectionTyp -eq "ssh"){
            $TD_CleanUpDumps = ssh -i $($TD_Device_SSHKeyPath) $TD_Device_UserName@$TD_Device_DeviceIP "cleardumps -prefix /dumps && cleardumps -prefix /home/admin/upgrade "
        }else {
            $TD_CleanUpDumps = plink $TD_Device_UserName@$TD_Device_DeviceIP -pw $TD_Device_PW -batch "cleardumps -prefix /dumps && cleardumps -prefix /home/admin/upgrade "
        }
        SST_ToolMessageCollector -TD_ToolMSGCollector "IBM_CleanUpDumps end of Process block $($TD_CleanUpDumps)" -TD_ToolMSGType Debug
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        <# returns the hashtable for further processing, not mandatory but the safe way #>
        SST_ToolMessageCollector -TD_ToolMSGCollector "IBM_CleanUpDumps End block " -TD_ToolMSGType Debug
        Write-Debug -Message "IBM_CleanUpDumps End block |$(Get-Date) `n"
        <# export y or n #>
        if([String]::IsNullOrEmpty($D_CleanUpDumps)){
            $TD_CleanUpDumpResult ="Everything on Device $($TD_DeviceName) deleted."
        }else{
            $TD_CleanUpDumpResult = $TD_CleanUpDumps
        }

        return $TD_CleanUpDumpResult
    }
}