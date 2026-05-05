function SST_JobMode {
    [CmdletBinding()]
    param (
        $SecData
    )
    
    begin {
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_JobMode Start for $($_.DeviceTyp)" -TD_ToolMSGType Message -TD_Shown no
    }
    
    process {
        $SecData | ForEach-Object {
            <# Storage Area #>
            if($_.DeviceTyp -like "*Storage*"){
                <#Basis Storage Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTBaseStorageInfos -SSHFunc IBM_SSHBaseStorageInfos  | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Basis Storage - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage Drive Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTDriveInfo -SSHFunc IBM_SSHDriveInfo  | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Drive - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage Host Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTHostInfo -SSHFunc IBM_SSHHostInfo | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Host - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
            <# SAN Area #>
            if($_.DeviceTyp -like "*SAN*"){
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTHostInfo -SSHFunc IBM_SSHHostInfo | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode SAN Base - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_JobMode Ende" -TD_ToolMSGType Message -TD_Shown no
    }
}