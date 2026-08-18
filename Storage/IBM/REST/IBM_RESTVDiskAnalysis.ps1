function IBM_RESTVDiskAnalysis {
    [CmdletBinding()]
    param (
        [string]$STOSN,
        [string]$STOWWNN,
        [string]$RESTInfo,
        [string]$BaseUrl,
        [string]$Body,
        [string]$TD_Exportpath
    )
    
    begin {
        $ErrorActionPreference="SilentlyContinue"

        $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lsvdiskanalysis -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
 
    }
    
    process {
        [int]$imax = $TD_DeviceInformation.Count
        [array]$TD_VDiskFuncResault = for ($i = 0; $i -lt $imax; $i++) {

            $TD_VDiskinfo = "" | Select-Object ID,Name,State,AnalysisTime,Capacity,ThinSize,ThinSavings,ThinSavingsRatio,CompressedSize,CompressionSavings,CompressionSavingsRatio,TotalSavings,TotalSavingsRatio,MarginOfError,WWNN,SerialNumber,RowID

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

            $TD_VDiskinfo.WWNN = $STOWWNN
            $TD_VDiskinfo.SerialNumber = $STOSN
            $TD_VDiskinfo.RowID = "$STOSN|VOLUME|$($TD_DeviceInformation.id[$i])"

            $TD_VDiskinfo
        }
    }
    
    end {
        if($TD_VDiskFuncResault.count -gt 0){
            $null = Save-StorageVolumeHistory -SourceType 'Analysis' -InputObject $TD_VDiskFuncResault
        }

        if(-not [string]::IsNullOrEmpty($TD_Exportpath)){
            $TD_VDiskFuncResault | Export-Csv -Path $TD_Exportpath\$($STOSN)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
            SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($STOSN)_IBM_VDiskAnalysis_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
        }
        return $TD_VDiskFuncResault
    }
}