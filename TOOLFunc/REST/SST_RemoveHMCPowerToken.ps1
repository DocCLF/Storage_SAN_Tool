function SST_RemoveHMCPowerToken {
    <#
      .SYNOPSIS
        Log out of an HMC REST session created with SST_GetHMCPowerToken.
    #>
    param(
        [Parameter(Mandatory)]
        $HmcSession,

        [switch]
        $IgnoreCertificate
    )
<# is needed for powershell 5.1 only#>
    if (-not ("TrustAllCertsPolicy" -as [type])) {
        Add-Type @"
using System;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public static class TrustAllCertsPolicy {
    public static bool Validator(
        object sender,
        X509Certificate certificate,
        X509Chain chain,
        SslPolicyErrors sslPolicyErrors
    ) {
        return true;
    }
}
"@
    }

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
        ErrorAction      = 'Stop'
    }

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        if ($IgnoreCertificate) {
            $RmHMCSessionParams['SkipCertificateCheck'] = $true
        }

        Invoke-WebRequest @RmHMCSessionParams | Out-Null
    }
    else {
        $RmHMCSessionParams['UseBasicParsing'] = $true

        $OldSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
        $OldCallback         = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
        $OldExpect100        = [Net.ServicePointManager]::Expect100Continue
        $OldCRL              = [Net.ServicePointManager]::CheckCertificateRevocationList

        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            [Net.ServicePointManager]::Expect100Continue = $false
            [Net.ServicePointManager]::CheckCertificateRevocationList = $false

if ($IgnoreCertificate) {
    $MethodInfo = [TrustAllCertsPolicy].GetMethod("Validator")

    [System.Net.ServicePointManager]::ServerCertificateValidationCallback =
        [System.Delegate]::CreateDelegate(
            [System.Net.Security.RemoteCertificateValidationCallback],
            $MethodInfo
        )
}

            Invoke-WebRequest @RmHMCSessionParams | Out-Null
        }
        catch {
            Write-Warning $_.Exception.Message

            if ($_.Exception.InnerException) {
                Write-Warning $_.Exception.InnerException.Message
            }
        }
        finally {
            [Net.ServicePointManager]::SecurityProtocol = $OldSecurityProtocol
            [Net.ServicePointManager]::Expect100Continue = $OldExpect100
            [Net.ServicePointManager]::CheckCertificateRevocationList = $OldCRL
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
        }
    }
}