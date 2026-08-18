function SST_JobMode {
    [CmdletBinding()]
    param (
        $SecData
    )
    
    begin {
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_JobMode Start for $($_.DeviceTyp)" -TD_ToolMSGType Message -TD_Shown no
        $ExportPath = Get-ChildItem "$HOME" -Recurse |Where-Object{$_.Name -like "StorageSANTool"} | ForEach-Object {$_.FullName}
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_JobMode Start ExportPath is $ExportPath" -TD_ToolMSGType Message -TD_Shown no
    }
    
    process {
        $SecData | ForEach-Object {
            <# Storage Area #>
            if($_.DeviceTyp -like "*Storage*"){
                $Device = $_
                <#Basis Storage Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTBaseStorageInfos -SSHFunc $null  | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Basis Storage - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage Drive Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTDriveInfo -SSHFunc $null  | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Drive - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage Host Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTHostInfo -SSHFunc $null | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Host - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage EventLog Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTEventLog -SSHFunc $null | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Event Log - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage IBM_RESTMDiskInfo Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTMDiskInfo -SSHFunc $null | Out-Null
                    Start-Sleep -Seconds 2
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTVolumeInfo -SSHFunc $null | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Event Log - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage IBM_RESTFCPortStats Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc IBM_RESTFCPortStats -SSHFunc $null | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Storage Event Log - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
            #<# SAN Area #>
            if($_.DeviceTyp -like "*SAN*"){
                $Device = $_
                <#SAN Get-BrocadePortErrorStats Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc Get-BrocadePortErrorStats -SSHFunc $null | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Get-BrocadePortErrorStats - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
                <#SAN Get-BrocadeSFPShow Infos#>
                try {
                    Invoke-DeviceDataFetch -Device $Device -ExportPath $ExportPath -RESTFunc Get-BrocadeSFPShow -SSHFunc $null | Out-Null
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Get-BrocadeSFPShow - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
            #if($_.DeviceTyp -like "*Tape*"){
            #    $Device = $_
            #    try {
            #        $LibBaseInfo = Invoke_IBMTapeLibraryApi -Device $Device -Endpoint 'library/baseinfo'
            #        Start-Sleep -Seconds 1
            #        $LibInfo = Invoke_IBMTapeLibraryApi -Device $Device -Endpoint 'library'
            #        Start-Sleep -Seconds 1
            #        $MergeLibObj = Merge-PSCustomObject -InputObject @($($LibBaseInfo.BaseInfo), $LibInfo)
            #        SST_CustomerLibraryDBInsertTable -SST_InfoType "LibraryBaseInfo" -SST_CollectedInformations $MergeLibObj
            #    }
            #    catch {
            #        <#Do this if a terminating exception happens#>
            #        SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Tape Base - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
            #    }
#
            #}
            #if($_.DeviceTyp -like "*Power*"){
            #    $Device = $_
            #    try {
            #        New-DeviceBlock -Device $Device -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCConsole | Out-Null
            #        Start-Sleep -Seconds 1
            #        New-DeviceBlock -Device $Device -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCManagedSystems | Out-Null
            #        Start-Sleep -Seconds 1
            #        New-DeviceBlock -Device $Device -ExportPath $TD_TB_ExportPath.Text -RESTFunc HMC_RESTHMCLogicalPartitions | Out-Null
            #    }
            #    catch {
            #        <#Do this if a terminating exception happens#>
            #        SST_ToolMessageCollector -TD_ToolMSGCollector "CockPit JobMode Power - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
            #    }
#
            #}
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_JobMode Ende" -TD_ToolMSGType Message -TD_Shown no
    }
}