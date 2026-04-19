function SST_GetHMCPowerToken {
    <#
    .SYNOPSIS
        SST_GetHMCPowerToken Compatible with PS 5.1 and PS 7
        Logs in to the IBM HMC REST API and returns a session object.
    .DESCRIPTION
       ToDos: 
            Address the HMC by host name (not by IP)
            Import the HMC certificate into the Windows Trust Store or have the HMC certificate signed by your CA
            Then PS7 will work without -SkipCertificateCheck and will be secure.
    .PARAMETER HMCIP
        HMC IP oder Hostname
    .PARAMETER HMCPort
        HMC port (typically 12443 or 443)
    .PARAMETER CredentialUN
        UserName
    .PARAMETER CredentialPW
        Userpw
    .PARAMETER IgnoreCertificate
        If set: Temporarily disable certificate verification (as in your tested code)
    #>
    param(
        [Parameter(Mandatory)][string]$HMCIP,
        [Parameter()][int]$HMCPort = 12443,
        [Parameter(Mandatory=$false)]$CredentialUN,
        [Parameter(Mandatory=$false)]$CredentialPW,
        [Parameter(Mandatory=$false)][pscredential]$Credential,
        [switch]$IgnoreCertificate
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Basic Auth headers such as curl (explicit)
    if($Credential){
      $user = $Credential.UserName
      $pass = $Credential.GetNetworkCredential().Password
    }else{
      $user = $CredentialUN
      $pass = $CredentialPW
    }

    $xmlBody = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<LogonRequest xmlns="http://www.ibm.com/xmlns/systems/power/firmware/web/mc/2012_10/" schemaVersion="V1_0">
  <Metadata><Atom/></Metadata>
  <UserID kb="CUR" kxe="false">$user</UserID>
  <Password kb="CUR" kxe="false">$pass</Password>
</LogonRequest>
"@

    $headersLogon = @{
        "Content-Type" = "application/vnd.ibm.powervm.web+xml; type=LogonRequest"
        "Accept"       = "application/vnd.ibm.powervm.web+xml; type=LogonResponse"
    }

    $logonUri = "https://$HMCIP`:$HMCPort/rest/api/web/Logon"

    # --- Build Invoke-WebRequest parameters depending on PS version ---
    $InvokeWebReqParamsBlock = @{
        Method          = 'Put'
        Uri             = $logonUri
        Headers         = $headersLogon
        Body            = $xmlBody
        DisableKeepAlive= $true
        ErrorAction     = 'SilentlyContinue'
    }

    $result = $null

    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell 7+ (HttpClient): Use SkipCertificateCheck
        if ($IgnoreCertificate) { $InvokeWebReqParamsBlock['SkipCertificateCheck'] = $true }
        try {
            $result = Invoke-WebRequest @InvokeWebReqParamsBlock -SkipHttpErrorCheck
            if ($result.StatusCode -ne 200) { throw "HMC Logon HTTP $($result.StatusCode): $($result.Content)" }
        }
        catch {
            $body = $null
            # When we use SkipHttpErrorCheck, body is usually in $result.Content.
            if ($result -and $result.Content) { 
                $body = [string]$result.Content 
            } else { 
                $body = $_.Exception.Message 
            }
            $decoded = [System.Net.WebUtility]::HtmlDecode($body)

            # Detect max sessions
            if ($decoded -match 'Reached maximum allowed number of sessions|maximum number of sessions') {
                $user = ([regex]::Match($decoded,'user\s+([^\.\s<]+)',"IgnoreCase")).Groups[1].Value
                if (!($user)) { $user = $CredentialUN }  # fallback
            
                # One-liner output
                Write-Host ("HMC login blocked: User '{0}' has reached maximum sessions." -f $user)
            }
        }

    }
    else {
        # PowerShell 5.1 (HttpWebRequest): Using callback
        $InvokeWebReqParamsBlock['UseBasicParsing'] = $true

        $OldCallback = $null
        try {
            if ($IgnoreCertificate) {
                $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
            }

            $result = Invoke-WebRequest @InvokeWebReqParamsBlock -UseBasicParsing
        }
        finally {
            if ($IgnoreCertificate) {
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
            }
        }
    }

    $session = ([regex]::Match($result.Content, '<X-API-Session[^>]*>([^<]+)</X-API-Session>')).Groups[1].Value.Trim()
    if (-not $session) { throw "X-API-Session nicht gefunden. (Antwort war: $($result.StatusCode) / ContentLength=$($result.RawContentLength))" }

    [pscustomobject]@{
        HMCIP      = $HMCIP
        HMCPort    = $HMCPort
        Session    = $session
    }
}
