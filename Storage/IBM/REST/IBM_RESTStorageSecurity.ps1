function IBM_RESTStorageSecurity {
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
            $TD_DeviceInformation = SST_SpectrumSystemAPI -Endpoint lssecurity -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
            #$STONodeInfo = SST_SpectrumSystemAPI -Endpoint lsnode -Body $null -BaseUrl $BaseUrl -RESTInfo $RESTInfo
        }else {
            <#switch to the ssh version and leave this func #>
            return $null
        }
        #[int]$imax = $STONodeInfo.Count
        #for ($i = 0; $i -le $imax; $i++) {
        #    if($STONodeInfo.config_node[$i] -eq "yes"){
        #        $IBMSTOWWNN = $STONodeInfo.WWNN[$i]
        #        $IBMSTOSN = if($STONodeInfo.enclosure_serial_number[$i] -eq ""){$STONodeInfo.panel_name[$i]}else{$STONodeInfo.enclosure_serial_number[$i]}
        #    }
        #}
    }
    
    process {
        $TD_lsSecSettings = $TD_DeviceInformation | ForEach-Object {
            $TD_SecSettingsInfo = "" | Select-Object Key,Value,RecommendedValue
            # Split name into Attribute and Value
            $Spliter = $_ -split ':'
            $TD_SecSettingsInfo.Key = $Spliter[0]
            $TD_SecSettingsInfo.Value = $Spliter[1]
            switch ($Spliter) {
                "sslprotocol"                           { $TD_SecSettingsInfo.RecommendedValue = 5 }
                "sshprotocol"                           { $TD_SecSettingsInfo.RecommendedValue = 3 }
                "gui_timeout_mins"                      { $TD_SecSettingsInfo.RecommendedValue = 5 }
                "cli_timeout_mins"                      { $TD_SecSettingsInfo.RecommendedValue = 5 }
                "restapi_timeout_mins"                  { $TD_SecSettingsInfo.RecommendedValue = 10 }
                "min_password_length"                   { $TD_SecSettingsInfo.RecommendedValue = 16 }
                "password_special_chars"                { $TD_SecSettingsInfo.RecommendedValue = 1 }
                "password_upper_case"                   { $TD_SecSettingsInfo.RecommendedValue = 1 }
                "password_lower_case"                   { $TD_SecSettingsInfo.RecommendedValue = 1 }
                "password_digits"                       { $TD_SecSettingsInfo.RecommendedValue = 1 }
                "check_password_history"                { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                "max_password_history"                  { $TD_SecSettingsInfo.RecommendedValue = 2 }
                "min_password_age_days"                 { $TD_SecSettingsInfo.RecommendedValue = 30 }
                "password_expiry_days"                  { $TD_SecSettingsInfo.RecommendedValue = 360 }
                "expiry_warning_days"                   { $TD_SecSettingsInfo.RecommendedValue = 21 }
                "superuser_locking"                     { $TD_SecSettingsInfo.RecommendedValue = "enable" }
                "max_failed_login_attempts"             { $TD_SecSettingsInfo.RecommendedValue = 5 }
                "lockout_period_mins"                   { $TD_SecSettingsInfo.RecommendedValue = 30 }
                "superuser_multi_factor"                { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                "ssh_grace_time_seconds"                { $TD_SecSettingsInfo.RecommendedValue = 60 }
                "ssh_max_tries"                         { $TD_SecSettingsInfo.RecommendedValue = 5 }
                "superuser_password_sshkey_required"    { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                "superuser_gui_disabled"                { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                "superuser_rest_disabled"               { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                "superuser_cim_disabled"                { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                "two_person_integrity_enabled"          { $TD_SecSettingsInfo.RecommendedValue = "---" }
                "two_person_integrity_superuser_locked" { $TD_SecSettingsInfo.RecommendedValue = "---" }
                "ssl_protocols_enabled"                 { $TD_SecSettingsInfo.RecommendedValue = "---" }
                "ssl_protocol_suggested"                { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                "ssh_protocol_suggested"                { $TD_SecSettingsInfo.RecommendedValue = "yes" }
                Default {}
            }

            $TD_SecSettingsInfo
            <# Progressbar  #>
            $ProgCounter++
            Write-ProgressBar -ProgressBar $ProgressBar -Activity "Collect data for Device $($TD_Line_ID) $($TD_Device_DeviceName)" -PercentComplete (($ProgCounter/$TD_DeviceInformation.Count) * 100)
        }
        Start-Sleep -Seconds 0.5
        
    }
    
    end {
        Close-ProgressBar -ProgressBar $ProgressBar
        if($TD_Export -eq "yes"){
            <# exported as .\<nbr>_Host_Volume_Map_Result_<date>.csv #>
            if([string]$TD_Exportpath -ne "$PSCommandPath\ToolLog\"){
                $TD_lsSecSettings | Export-Csv -Path $TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_lssecurity_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$TD_Exportpath\$($TD_Line_ID)_$($TD_Device_DeviceName)_lssecurity_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }else {
                $TD_lsSecSettings | Export-Csv -Path $PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_lssecurity_Result_$(Get-Date -Format "yyyy-MM-dd").csv -NoTypeInformation
                SST_ToolMessageCollector -TD_ToolMSGCollector "$PSCommandPath\ToolLog\$($TD_Line_ID)_$($TD_Device_DeviceName)_lssecurity_Result_$(Get-Date -Format "yyyy-MM-dd").csv" -TD_ToolMSGType Debug
            }
        }else {
            <# output on the promt #>
            return $TD_lsSecSettings
        }
        return $TD_lsSecSettings
    }
}