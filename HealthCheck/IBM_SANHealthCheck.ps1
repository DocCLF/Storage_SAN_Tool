function IBM_SANHealthCheck {
    [CmdletBinding()]
    param (
        $SST_DeviceLoggingInfo,
        $UCOBJ
    )
    
    begin {
        
    }
    
    process {
        
        $TD_DeviceManufacturer = "Brocade"
        switch ($TD_DeviceManufacturer) {
            "Brocade" 
                {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Starting HealthCheck for IP: $($Temp_Credentials.IPAddress) with Name: $($Temp_Credentials.DeviceName)" -TD_ToolMSGType Message -TD_Shown no

                    foreach ($Device in @($SST_DeviceLoggingInfo)) {
                        try {
                            SST_ToolMessageCollector -TD_ToolMSGCollector "Starting SAN HealthCheck for IP: $($Device.IPAddress)" -TD_ToolMSGType Message -TD_Shown no
                        
                            # GUI-Block für den Switch erzeugen.
                            $DeviceIdent = New-SANHealthCheckBlock -Device $Device -UCOBJ $UCOBJ
                            
                            # HealthCheck-Zeilen erzeugen und gleichzeitig die
                            # auszuführenden HealthCheck-Definitionen erhalten.
                            $HealthCheckSteps = Initialize-SANHealthCheckSteps -DeviceIdent $DeviceIdent -Device $Device 
                            
                            # Alle definierten HealthCheck-Schritte nacheinander ausführen.
                            $HealthResult = Get-BrocadeHealthOverview -Device $Device -DeviceIdent $DeviceIdent -UCOBJ $UCOBJ -HealthCheckSteps $HealthCheckSteps
                        
                            if (
                                $null -ne $HealthResult -and
                                $HealthResult.PSObject.Properties['SwitchInfo']
                            ) {
                                $SwitchInfo = $HealthResult.SwitchInfo
                            
                                # Den tatsächlichen Property-Namen an deine Rückgabe
                                # von Get-BrocadeSwitchInfo anpassen.
                                $SwitchName = if (
                                    $SwitchInfo.PSObject.Properties['Name']
                                ) {
                                    [string]$SwitchInfo.Name
                                }
                                elseif (
                                    $SwitchInfo.PSObject.Properties['SwitchName']
                                ) {
                                    [string]$SwitchInfo.SwitchName
                                }
                            
                                if (-not [string]::IsNullOrWhiteSpace($SwitchName)) {
                                    $DeviceIdent.DeviceTitle = $SwitchName
                                
                                    $DeviceIdent.SANHealthCheckTitle =
                                        "SAN Health Overview for - $($Device.IPAddress)"
                                }
                            }
                        }
                        catch {
                            SST_ToolMessageCollector -TD_ToolMSGCollector "SAN HealthCheck failed for $($Device.IPAddress): $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
                            Write-Host $_.Exception.Message
                        }
                    }
                }
            "Cisco" 
                { 

                }
            Default {}
        }
            
    }
    
    end {
        
    }
}