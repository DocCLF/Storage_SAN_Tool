function IBM_RESTCleanUpDumps {
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
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (25)
        Clear-Variable -Name TD_Device_PW -Force
        if($TD_Device_ConnectionTyp -eq "REST"){
            $TD_DeviceClearDumps = SST_SpectrumSystemAPI -Endpoint "cleardumps -prefix /dumps"-Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (50)
            Start-Sleep -Milliseconds 1500
            $TD_DeviceClearUpgrade = SST_SpectrumSystemAPI -Endpoint "cleardumps -prefix /home/admin/upgrade"-Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (75)

        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
    }
    
    process {
        
        $IBM_STOSysDumpInfos =[ordered]@{}
        $IBM_STOSysDumpInfos.Add('RowID',"$TD_Line_ID|$($TD_Device_UserName.count)")
        Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (95)
        Start-Sleep -Seconds 1
        Close-ProgressBar -ProgressBar $ProgressBar
        <# returns the hashtable for further processing, not mandatory but the safe way #>
        SST_ToolMessageCollector -TD_ToolMSGCollector "IBM_CleanUpDumps End block " -TD_ToolMSGType Debug
        Write-Debug -Message "IBM_CleanUpDumps End block |$(Get-Date) `n"
        
    }
    
    end {
        if([String]::IsNullOrEmpty($TD_DeviceClearDumps)){
            $TD_CleanUpDumpResult ="Everything on Device $($TD_DeviceName) deleted."
        }else{
            $TD_CleanUpDumpResult = $TD_DeviceClearDumps
        }
        if([String]::IsNullOrEmpty($TD_DeviceClearUpgrade)){
            $TD_CleanUpgradeResult ="Everything on Device $($TD_DeviceName) deleted."
        }else{
            $TD_CleanUpgradeResult = $TD_DeviceClearUpgrade
        }
        $IBM_STOSysDumpInfos.Add('DeviceName',$TD_DeviceName)
        $IBM_STOSysDumpInfos.Add('DumpMsg',$TD_CleanUpDumpResult)
        $IBM_STOSysDumpInfos.Add('UpgradeMsg',$TD_CleanUpgradeResult)

        return $IBM_STOSysDumpInfos
    }
}

