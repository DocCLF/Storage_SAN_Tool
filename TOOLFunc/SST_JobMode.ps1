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
                $Device = $_
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
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Drive - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
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
                <#Storage EventLog Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTEventLog -SSHFunc IBM_SSHEventLog | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Event Log - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
            <# SAN Area #>
            if($_.DeviceTyp -like "*SAN*"){
                $Device = $_
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc Get-BrocadeBaseInfo -SSHFunc FOS_SSHBasicSwitchInfos | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode SAN Base - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
            if($_.DeviceTyp -like "*Tape*"){
                $Device = $_
                try {
                    $LibBaseInfo = Invoke_IBMTapeLibraryApi -Device $Device -Endpoint 'library/baseinfo'
                    Start-Sleep -Seconds 1
                    $LibInfo = Invoke_IBMTapeLibraryApi -Device $Device -Endpoint 'library'
                    Start-Sleep -Seconds 1
                    $MergeLibObj = Merge-PSCustomObject -InputObject @($($LibBaseInfo.BaseInfo), $LibInfo)
                    SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryBaseInfo" -SST_CollectedInformations $MergeLibObj
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Tape Base - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }

            }
            if($_.DeviceTyp -like "*Power*"){
                $Device = $_
                try {
                    New-DeviceBlock -Device $Device -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCConsole | Out-Null
                    Start-Sleep -Seconds 1
                    New-DeviceBlock -Device $Device -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCManagedSystems | Out-Null
                    Start-Sleep -Seconds 1
                    New-DeviceBlock -Device $Device -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCLogicalPartitions | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Power - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }

            }
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_JobMode Ende" -TD_ToolMSGType Message -TD_Shown no
    }
}