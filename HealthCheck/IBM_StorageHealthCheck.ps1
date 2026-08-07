function IBM_StorageHealthCheck {
    [CmdletBinding()]
    param(
        $SST_DeviceLoggingInfo,
        $ExportPath,
        $UCOBJ
    )

    $TD_DeviceManufacturer = 'IBM'
    switch ($TD_DeviceManufacturer) {
        'IBM' {
            foreach ($Device in @($SST_DeviceLoggingInfo)) {
                try {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Starting IBM Storage HealthCheck for IP: $($Device.IPAddress)" -TD_ToolMSGType Message -TD_Shown no
                    # Create a GUI block.
                    $DeviceIdent = New-IBMStorageHealthCheckBlock -Device $Device -UCOBJ $UCOBJ
                    # Generate status lines and definitions to be executed.
                    $HealthCheckSteps = Initialize-IBMStorageHealthCheckSteps -DeviceIdent $DeviceIdent
                    # Execute all IBM REST steps.
                    $HealthResult = Get-IBMHealthOverview -Device $Device -DeviceIdent $DeviceIdent -UCOBJ $UCOBJ -HealthCheckSteps $HealthCheckSteps -ExportPath $ExportPath
                    # Import names from the BaseStorage return value.
                    if ($null -ne $HealthResult -and $HealthResult.PSObject.Properties['StorageInfo']) {
                        $BaseResult = $HealthResult.StorageInfo
                        $StorageInfo = $BaseResult.StorageInfo | Select-Object -First 1
                        $StorageName = if ($null -ne $StorageInfo -and $StorageInfo.PSObject.Properties['Name']) {
                            [string]$StorageInfo.Name
                        }else {
                            $null
                        }
                        if (-not [string]::IsNullOrWhiteSpace($StorageName)) {
                            $DeviceIdent.DeviceTitle = $StorageName
                            $DeviceIdent.StorageHealthCheckTitle = "IBM Storage Health Overview for - $StorageName"
                        }
                    }
                }
                catch {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "IBM Storage HealthCheck failed for $($Device.IPAddress): $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
                    Write-Host $_.Exception.Message
                }
            }
        }
        default {
        }
    }
}