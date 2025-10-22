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
            if($_.DeviceTyp -eq "Storage"){
                <#Basis Storage Infos#>
                $BaseStorageInfos = IBM_BaseStorageInfos -TD_Device_ConnectionTyp "plink" -TD_Device_DeviceIP $_.IPAddress -TD_Device_UserName $_.UserName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorVF
                try {
                    SST_LiteDBControl -SST_InfoType "StorageBase" -SST_CollectedInformations $BaseStorageInfos
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage Drive Infos#>
                [array]$TD_DriveInfo = IBM_DriveInfo -TD_Line_ID $TD_DevCounter -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Storage $_.SVCorVF -TD_Exportpath $TD_tb_ExportPath.Text
                try {
                    SST_LiteDBControl -SST_InfoType "StorageDrive" -SST_CollectedInformations $TD_DriveInfo
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $_.exception.message" -TD_ToolMSGType Error -TD_Shown no
                }
                <#Storage Host Infos#>
                [array]$TD_Collected_HostInfoResult = IBM_HostInfo -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceIP $_.IPAddress -TD_Device_DeviceName $_.DeviceName -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Storage $_.SVCorV -TD_Exportpath $TD_tb_ExportPath.Text
                try {
                    SST_LiteDBControl -SST_InfoType "StorageHostInfo" -SST_CollectedInformations $TD_Collected_HostInfoResult
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    Write-Host $_.exception.message
                    SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
            <# SAN Area #>
            if($_.DeviceTyp -eq "SAN"){
                $FOS_BasicSwitch = FOS_BasicSwitchInfos -TD_Line_ID $_.ID -TD_Device_ConnectionTyp $_.ConnectionTyp -TD_Device_UserName $_.UserName -TD_Device_DeviceName $_.DeviceName -TD_Device_DeviceIP $_.IPAddress -TD_Device_PW $([Net.NetworkCredential]::new('', $_.Password).Password) -TD_Device_SSHKeyPath $_.SSHKeyPath -TD_Exportpath $TD_tb_ExportPath.Text
                try {
                    SST_LiteDBControl -SST_InfoType "SANBase" -SST_CollectedInformations $FOS_BasicSwitch
                }
                catch {
                    <#Do this if a terminating exception happens#>
                    SST_ToolMessageCollector -TD_ToolMSGCollector "LiteDB SANBase - $($_.exception.message)" -TD_ToolMSGType Error -TD_Shown no
                }
            }
        }
    }
    
    end {
        SST_ToolMessageCollector -TD_ToolMSGCollector "SST_JobMode Ende" -TD_ToolMSGType Message -TD_Shown no
    }
}
