function SST_RemoveHMCPowerToken {
    <#
      .SYNOPSIS
        Log out of an HMC REST session that was created with SST_GetHMCPowerToken, which means you need the object generated there.
        his should contain the HMCIP, HMCPort, and SessionToken.
    #>
    param(
        [Parameter(Mandatory)]$HmcSession,
        [switch]$IgnoreCertificate
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $uri = "https://$($HmcSession.HMCIP)`:$($HmcSession.HMCPort)/rest/api/web/Logon"
    $headers = @{
        "X-API-Session" = $HmcSession.Session
        "Accept"        = "application/vnd.ibm.powervm.web+xml"
    }

    $RmHMCSessionParams = @{
        Method           = 'Delete'
        Uri              = $uri
        Headers          = $headers
        DisableKeepAlive = $true
        ErrorAction      = 'SilentlyContinue'
    }

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IgnoreCertificate) { $RmHMCSessionParams['SkipCertificateCheck'] = $true }
        Invoke-WebRequest @RmHMCSessionParams | Out-Null
    }
    else {
        $RmHMCSessionParams['UseBasicParsing'] = $true

        $OldCallback = $null
        try {
            if ($IgnoreCertificate) {
                $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            }

            Invoke-WebRequest @RmHMCSessionParams | Out-Null
        }
        finally {
            if ($IgnoreCertificate) {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
            }
        }
    }
}
