function GET_BrocadeSecureCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $PB = New-ProgressBar

    try {
        # First attempt using the standard device credentials
        $SwitchSecurityInfo = Get-BrocadeSecurity -Device $Device

        Write-ProgressBar -ProgressBar $PB -Activity "Get-BrocadeSecurity completed" -PercentComplete 20

        # Check whether a REST error object was returned
        $IsRestError = $SwitchSecurityInfo.PSObject.Properties['Success'] -and -not $SwitchSecurityInfo.Success

        if ($IsRestError) {
            # Please contact us only if you encounter authentication or permission issues
            if ($SwitchSecurityInfo.StatusCode -in 401, 403 -or $SwitchSecurityInfo.Error -match '\(400\)') {

                $Message = @"
The currently logged-in user does not have the necessary permissions to,
read the security configuration of the Brocade switch.

Please enter a user with sufficient permissions.
"@

                $PrivilegedCredential = Get-Credential -Message $Message
                # The user canceled the dialog box
                if ($null -eq $PrivilegedCredential) {
                    return [PSCustomObject]@{
                        Success    = $false
                        Uri        = $SwitchSecurityInfo.Uri
                        Data       = $null
                        Error      = "The entry of privileged credentials was canceled."
                        StatusCode = $SwitchSecurityInfo.StatusCode
                    }
                }

                Write-ProgressBar -ProgressBar $PB -Activity "Retry with privileged credentials" -PercentComplete 40

                # Second attempt using temporary privileged credentials
                $SwitchSecurityInfo = Get-BrocadeSecurity -Device $Device -Credential $PrivilegedCredential

                # Credential-Variable nach Gebrauch freigeben
                $PrivilegedCredential = $null

                # The second attempt also failed
                if (
                    $SwitchSecurityInfo.PSObject.Properties['Success'] -and
                    -not $SwitchSecurityInfo.Success
                ) {
                    return $SwitchSecurityInfo
                }
            }
            else {
                # No authorization error:
                # Return standard REST errors unchanged
                return $SwitchSecurityInfo
            }
        }

        Write-ProgressBar -ProgressBar $PB -Activity "Security information collected" -PercentComplete 100

        return $SwitchSecurityInfo
    }
    finally {
        Close-ProgressBar -ProgressBar $PB
    }
}