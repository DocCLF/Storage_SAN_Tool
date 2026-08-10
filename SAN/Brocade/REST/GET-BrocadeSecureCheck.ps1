function GET-BrocadeSecureCheck {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device
    )

    $PB = New-ProgressBar

    try {
        $SwitchInfo = Get-BrocadeSwitchInfo -Device $Device
        $ChassisInfo = Get-BrocadeChassisInfo -Device $Device
        $SwitchSecurityInfo = Get-BrocadeSecurity -Device $Device
        #$SwitchIPfilterInfo = Get-BrocadeIPfilter -Device $Device

        $SwitchName = $SwitchInfo.'user-friendly-name'
        if ([string]::IsNullOrWhiteSpace($SwitchName)) {
            $SwitchName = "Unknown_$($ChassisInfo.'vendor-serial-number')"
        }
        Write-ProgressBar -ProgressBar $PB -Activity 'Get-BrocadeSecurity completed' -PercentComplete 20

        $IsRestError = $SwitchSecurityInfo.PSObject.Properties['Success'] -and -not $SwitchSecurityInfo.Success

        if ($IsRestError) {
            if ($SwitchSecurityInfo.StatusCode -in 401, 403 -or $SwitchSecurityInfo.Error -match '\(400\)') {
                $Message = @"
The currently logged-in user does not have the necessary permissions to
read the security configuration of the Brocade switch.

Please enter a user with sufficient permissions.
"@

                $PrivilegedCredential = Get-Credential -Message $Message

                if ($null -eq $PrivilegedCredential) {
                    return [PSCustomObject]@{
                        Success    = $false
                        Uri        = $SwitchSecurityInfo.Uri
                        Data       = $null
                        Error      = 'The entry of privileged credentials was canceled.'
                        StatusCode = $SwitchSecurityInfo.StatusCode
                    }
                }

                Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 40

                $SwitchSecurityInfo = Get-BrocadeSecurity -Device $Device -Credential $PrivilegedCredential
                $SwitchIPfilterInfo = Get-BrocadeIPfilter -Device $Device -Credential $PrivilegedCredential
                

                $PrivilegedCredential = $null

                if ($SwitchSecurityInfo.PSObject.Properties['Success'] -and -not $SwitchSecurityInfo.Success) {
                    return $SwitchSecurityInfo
                }
            }
            else {
                return $SwitchSecurityInfo
            }
        }
        Write-ProgressBar -ProgressBar $PB -Activity 'Retry with privileged credentials' -PercentComplete 60

        $IPFilterRestError = $null -ne $SwitchIPfilterInfo -and $SwitchIPfilterInfo.PSObject.Properties['Success'] -and -not $SwitchIPfilterInfo.Success
        $IPFilterPolicies = if ($IPFilterRestError) { @() } else { @($SwitchIPfilterInfo) }
        $IPFilterError          = if ($IPFilterRestError) {$SwitchIPfilterInfo.Error} else {$null}

        $SSHHostKeyAlgorithms   = if($SwitchSecurityInfo.PSObject.Properties['ssh-host-key-algorithms']){$SwitchSecurityInfo.'ssh-host-key-algorithms'}else{$null}
        $SSHPublicKeyAlgorithms = if($SwitchSecurityInfo.PSObject.Properties['ssh-pub-key-algorithms']){$SwitchSecurityInfo.'ssh-pub-key-algorithms'}else{$null}
        $RSACipher              = if($SwitchSecurityInfo.PSObject.Properties['rsa-cipher']){$SwitchSecurityInfo.'rsa-cipher'}else{$null}
        $FACipher               = if($SwitchSecurityInfo.PSObject.Properties['fa-cipher']){$SwitchSecurityInfo.'fa-cipher'}else{$null}
        $SMTPSCipher            = if($SwitchSecurityInfo.PSObject.Properties['smtps-cipher']){$SwitchSecurityInfo.'smtps-cipher'}else{$null}
        $RSATLSProtocol         = if($SwitchSecurityInfo.PSObject.Properties['rsa-tls-protocol']){$SwitchSecurityInfo.'rsa-tls-protocol'}else{$null}
        $FATLSProtocol          = if($SwitchSecurityInfo.PSObject.Properties['fa-tls-protocol']){$SwitchSecurityInfo.'fa-tls-protocol'}else{$null}
        $SMTPSTLSProtocol       = if($SwitchSecurityInfo.PSObject.Properties['smtps-tls-protocol']){$SwitchSecurityInfo.'smtps-tls-protocol'}else{$null}
        $FIPSInside             = if($SwitchSecurityInfo.PSObject.Properties['fips-inside']){$SwitchSecurityInfo.'fips-inside'}else{$null}
        

        Write-ProgressBar -ProgressBar $PB -Activity 'Security information collected' -PercentComplete 100

        $RowID = "$($SwitchSecurityInfo.count)|$($Device.ID)"

        $FOS_SwitchSecurityInfo = [PSCustomObject]@{
            IPFilterPolicies       = $IPFilterPolicies
            IPFilterPolicyCount    = $IPFilterPolicies.Count
            IPFilterError          = $IPFilterError

            SSHCipher                  = $SwitchSecurityInfo.'ssh-cipher'
            SSHKeyExchange             = $SwitchSecurityInfo.'ssh-kex'
            SSHMacConfiguration        = $SwitchSecurityInfo.'ssh-mac'

            HTTPSCipherExpression      = $SwitchSecurityInfo.'https-cipher'
            HTTPSTLS13Cipher           = $SwitchSecurityInfo.'https-tlsv13-cipher'
            RADIUSCipherExpression     = $SwitchSecurityInfo.'radius-cipher'
            LDAPCipherExpression       = $SwitchSecurityInfo.'ldap-cipher'
            SYSLOGCipherExpression     = $SwitchSecurityInfo.'syslog-cipher'

            HTTPSTLSProtocol           = $SwitchSecurityInfo.'https-tls-protocol'
            RADIUSTLSProtocol          = $SwitchSecurityInfo.'radius-tls-protocol'
            LDAPTLSProtocol            = $SwitchSecurityInfo.'ldap-tls-protocol'
            SYSLOGTLSProtocol          = $SwitchSecurityInfo.'syslog-tls-protocol'

            X509ValidationMode         = $SwitchSecurityInfo.'x509v3-validation-mode'
            CryptoVersion              = $SwitchSecurityInfo.'crypto-version'
            BootUpSelfTestEnabled      = $SwitchSecurityInfo.'boot-up-self-test-enabled'

            # Not provided by the sec-crypto-cfg endpoint
            SSHHostKeyAlgorithms       = $SSHHostKeyAlgorithms  
            SSHPublicKeyAlgorithms     = $SSHPublicKeyAlgorithms
            RSACipher                  = $RSACipher             
            FACipher                   = $FACipher              
            SMTPSCipher                = $SMTPSCipher           
            RSATLSProtocol             = $RSATLSProtocol        
            FATLSProtocol              = $FATLSProtocol         
            SMTPSTLSProtocol           = $SMTPSTLSProtocol      
            FIPSInside                 = $FIPSInside            

            DataSource                 = 'REST'
            RestEndpoint               = 'running/brocade-security/sec-crypto-cfg'
            RowID                       = $RowID
        }

        Out-File -FilePath "$($TD_TB_ExportPath.Text)\SwitchSecurityInfo_$($SwitchName)_$(Get-Date -Format "yyyy-MM-dd").csv" -InputObject $FOS_SwitchSecurityInfo
        
    }
    finally {
        Close-ProgressBar -ProgressBar $PB
    }
    return $FOS_SwitchSecurityInfo
}