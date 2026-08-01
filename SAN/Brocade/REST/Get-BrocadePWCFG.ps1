function Get-BrocadePWCFG {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $PB = New-ProgressBar

    try {
        $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
        $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
        $SwitchPasswdcfgInfo = Get-BrocadePasswdcfg -Device $Device

        $SwitchName = $SwitchInfo.'user-friendly-name'
        if ([string]::IsNullOrWhiteSpace($SwitchName)) {
            $SwitchName = "Unknown_$($ChassisInfo.'vendor-serial-number')"
        }
        Write-ProgressBar -ProgressBar $PB -Activity 'Get-BrocadeSecurity completed' -PercentComplete 20

        $IsRestError = $SwitchPasswdcfgInfo.PSObject.Properties['Success'] -and -not $SwitchPasswdcfgInfo.Success

        if ($IsRestError) {
            if ($SwitchPasswdcfgInfo.StatusCode -in 401, 403 -or $SwitchPasswdcfgInfo.Error -match '\(400\)') {
                $Message = @"
The currently logged-in user does not have the necessary permissions to
read the security configuration of the Brocade switch.

Please enter a user with sufficient permissions.
"@

                $PrivilegedCredential = Get-Credential -Message $Message

                if ($null -eq $PrivilegedCredential) {
                    return [PSCustomObject]@{
                        Success    = $false
                        Uri        = $SwitchPasswdcfgInfo.Uri
                        Data       = $null
                        Error      = 'The entry of privileged credentials was canceled.'
                        StatusCode = $SwitchPasswdcfgInfo.StatusCode
                    }
                }

                Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 40

                $SwitchPasswdcfgInfo = Get-BrocadePasswdcfg -Device $Device -Credential $PrivilegedCredential
                

                $PrivilegedCredential = $null

                if ($SwitchPasswdcfgInfo.PSObject.Properties['Success'] -and -not $SwitchPasswdcfgInfo.Success) {
                    return $SwitchPasswdcfgInfo
                }
            } else {
                return $SwitchPasswdcfgInfo
            }
        }

        Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 60

        $RowID = "$($SwitchPasswdcfgInfo.count)|$($Device.ID)"
        $CreationTime = Get-Date -Format "yyyy/MM/dd HH:mm"
        $SwitchPasswordPolicyInfo = [PSCustomObject]@{
        
            HashType                    = $SwitchPasswdcfgInfo.'hash-type'
            ManualHashEnabled           = [bool]$SwitchPasswdcfgInfo.'manual-hash-enabled'
        
            MinimumLength               = [int]$SwitchPasswdcfgInfo.'minimum-length'
            CharacterSet                = [int]$SwitchPasswdcfgInfo.'character-set'
            UserNameAllowed             = [bool]$SwitchPasswdcfgInfo.'user-name-allowed'
        
            MinimumLowerCaseCharacters  = [int]$SwitchPasswdcfgInfo.'minimum-lower-case-character'
            MinimumUpperCaseCharacters  = [int]$SwitchPasswdcfgInfo.'minimum-upper-case-character'
            MinimumNumericCharacters    = [int]$SwitchPasswdcfgInfo.'minimum-numeric-character'
            MinimumSpecialCharacters    = [int]$SwitchPasswdcfgInfo.'minimum-special-character'
        
            PastPasswordHistory         = [int]$SwitchPasswdcfgInfo.'past-password-history'
            MinimumPasswordAge          = [int]$SwitchPasswdcfgInfo.'minimum-password-age'
            MaximumPasswordAge          = [int]$SwitchPasswdcfgInfo.'maximum-password-age'
            WarnOnExpire                = [int]$SwitchPasswdcfgInfo.'warn-on-expire'
        
            LockOutThreshold            = [int]$SwitchPasswdcfgInfo.'lock-out-threshold'
            LockOutDuration             = [int]$SwitchPasswdcfgInfo.'lock-out-duration'
            AdminLockOutEnabled         = [bool]$SwitchPasswdcfgInfo.'admin-lock-out-enabled'
        
            RepeatCharacterLimit        = [int]$SwitchPasswdcfgInfo.'repeat-character-limit'
            SequenceCharacterLimit      = [int]$SwitchPasswdcfgInfo.'sequence-character-limit'
            ReverseUserNameAllowed      = [bool]$SwitchPasswdcfgInfo.'reverse-user-name-allowed'
            MinimumDifference           = [int]$SwitchPasswdcfgInfo.'minimum-difference'
        
            PasswordConfigChanged       = [bool]$SwitchPasswdcfgInfo.'password-config-changed'
            CreationTime                = $CreationTime
            DataSource                  = 'REST'
            RowID                       = $RowID
        }

        Write-ProgressBar -ProgressBar $PB -Activity 'Security information collected' -PercentComplete 100
        Out-File -FilePath "$($TD_TB_ExportPath.Text)\PasswordPolicy_$($SwitchName)_$(Get-Date -Format "yyyy-MM-dd").csv" -InputObject $SwitchPasswordPolicyInfo
        
    }
    finally {
        Close-ProgressBar -ProgressBar $PB
    }
    return $SwitchPasswordPolicyInfo
}