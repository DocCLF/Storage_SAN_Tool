function IBM_RESTVDiskAnalysis {
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsvdiskanalysis -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
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
    
    process {
        [int]$imax = $TD_DeviceInformation.Count
        [array]$TD_VDiskFuncResault = for ($i = 0; $i -lt $imax; $i++) {
            <# Max requests/sec to command endpoints = 10 -.- #>
            if ($i % 8 -eq 0) { Start-Sleep -Milliseconds 1500 }
            <# Node Info#>
            $TD_VDiskinfo = "" | Select-Object ID,Name,State,AnalysisTime,Capacity,ThinSize,ThinSavings,ThinSavingsRatio,CompressedSize,CompressionSavings,CompressionSavingsRatio,TotalSavings,TotalSavingsRatio,MarginOfError,WWNN,SerialNumber

            $TD_VDiskinfo.ID                        = $TD_DeviceInformation.id[$i]
            $TD_VDiskinfo.Name                      = $TD_DeviceInformation.name[$i]
            $TD_VDiskinfo.State                     = $TD_DeviceInformation.state[$i]
            $TD_VDiskinfo.AnalysisTime              = $TD_DeviceInformation.analysis_time[$i]
            $TD_VDiskinfo.Capacity                  = $TD_DeviceInformation.capacity[$i]
            $TD_VDiskinfo.ThinSize                  = $TD_DeviceInformation.thin_size[$i]
            $TD_VDiskinfo.ThinSavings               = $TD_DeviceInformation.thin_savings[$i]
            $TD_VDiskinfo.ThinSavingsRatio          = $TD_DeviceInformation.thin_savings_ratio[$i]
            $TD_VDiskinfo.CompressedSize            = $TD_DeviceInformation.compressed_size[$i]
            $TD_VDiskinfo.CompressionSavings        = $TD_DeviceInformation.compression_savings[$i]
            $TD_VDiskinfo.CompressionSavingsRatio   = $TD_DeviceInformation.compression_savings_ratio[$i]
            $TD_VDiskinfo.TotalSavings              = $TD_DeviceInformation.total_savings[$i]
            $TD_VDiskinfo.TotalSavingsRatio         = $TD_DeviceInformation.total_savings_ratio[$i]
            $TD_VDiskinfo.MarginOfError             = $TD_DeviceInformation.margin_of_error[$i]

            $TD_VDiskinfo.WWNN = $IBMSTOWWNN
            $TD_VDiskinfo.SerialNumber = $IBMSTOSN

            $TD_VDiskinfo

            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$imax) * 100)
        }
    }
    
    end {

        if($TD_Export -eq "yes"){
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_VDiskFuncResault | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_VDiskFuncResault | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_VDiskFuncResault
        }
        return $TD_VDiskFuncResault
    }
}

