function GET-BrocadeAuditInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        $TD_Exportpath = $null
    )

    $PB = New-ProgressBar
    try {
        $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
        $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
        $SwitchAuditDumpInfo = Get-BrocadeAuditDump -Device $Device

        $SwitchName = $SwitchInfo.'user-friendly-name'
        if ([string]::IsNullOrWhiteSpace($SwitchName)) {
            $SwitchName = "Unknown_$($ChassisInfo.'vendor-serial-number')"
        }
        Write-ProgressBar -ProgressBar $PB -Activity 'Get-BrocadeAuditDump completed' -PercentComplete 20

        $IsRestError = $SwitchAuditDumpInfo.PSObject.Properties['Success'] -and -not $SwitchAuditDumpInfo.Success

        if ($IsRestError) {
            if ($SwitchAuditDumpInfo.StatusCode -in 401, 403 -or $SwitchAuditDumpInfo.Error -match '\(400\)') {
                $Message = @"
The currently logged-in user does not have the necessary permissions to
read the security configuration of the Brocade switch.

Please enter a user with sufficient permissions.
"@

                $PrivilegedCredential = Get-Credential -Message $Message

                if ($null -eq $PrivilegedCredential) {
                    return [PSCustomObject]@{
                        Success    = $false
                        Uri        = $SwitchAuditDumpInfo.Uri
                        Data       = $null
                        Error      = 'The entry of privileged credentials was canceled.'
                        StatusCode = $SwitchAuditDumpInfo.StatusCode
                    }
                }

                Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 40

                $SwitchAuditDumpInfo = Get-BrocadeAuditDump -Device $Device -Credential $PrivilegedCredential

                $PrivilegedCredential = $null

                if ($SwitchAuditDumpInfo.PSObject.Properties['Success'] -and -not $SwitchAuditDumpInfo.Success) {
                    return $SwitchAuditDumpInfo
                }
            }
            else {
                return $SwitchAuditDumpInfo
            }
        }
        Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 60



        if(-not [string]::IsNullOrWhiteSpace($TD_Exportpath)){
            Out-File -FilePath "$($TD_Exportpath)\SwitchAuditDumpInfo$($SwitchName)_$(Get-Date -Format "yyyy-MM-dd").csv" -InputObject $SwitchAuditDumpInfo
        }
        
    }
    finally {
        Close-ProgressBar -ProgressBar $PB
    }

}