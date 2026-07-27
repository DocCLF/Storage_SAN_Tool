function Invoke-BrocadeRest {
    <#
    .DESCRIPTION
        Central wrapper for Brocade Fabric OS REST API calls.

        Fabric OS feature modules:
            https://host/rest/running/<request-uri>

        Fabric OS operation modules:
            https://host/rest/operations/<request-uri>

        VFID:
            The vf-id query parameter is only added for endpoints that support
            a Logical Switch context.

            Chassis-wide endpoints such as sec-crypto-cfg must be called with
            -IgnoreVFID.

    .EXAMPLE
        Invoke-BrocadeRest `
            -Device $sw `
            -FOSOperation "running/brocade-fabric/fabric-switch"

    .EXAMPLE
        Invoke-BrocadeRest `
            -Device $sw `
            -FOSOperation "running/brocade-security/sec-crypto-cfg" `
            -IgnoreVFID

    .EXAMPLE
        Invoke-BrocadeRest `
            -Device $sw `
            -Method PATCH `
            -FOSOperation "running/brocade-interface/fibrechannel" `
            -Body $Body
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,

        [Parameter(Mandatory)]
        [string]$FOSOperation,

        [ValidateSet("GET", "POST", "PATCH", "PUT", "DELETE")]
        [string]$Method = "GET",

        $Body,

        # Prevents adding ?vf-id=... for chassis-wide endpoints.
        [switch]$IgnoreVFID,

        [PSCredential]$Credential
    )

    # Initialize Uri before try so it is always available in catch.
    $Uri = $null

    try {
        if ($null -ne $Credential) {
            $UserName = $Credential.UserName
            $pw = $Credential.GetNetworkCredential().Password
        }else {
            $UserName = $($Device.UserName)
            $pw = [Net.NetworkCredential]::new('',$Device.Password).Password
        }
        $pair   = "$($UserName):$pw"
        $bytes  = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [Convert]::ToBase64String($bytes)

        # Remove plaintext password reference as soon as possible.
        $pw = $null

        $Headers = @{
            Authorization = "Basic $base64"
            Accept        = "application/yang-data+json"
        }

        $BaseUrl = "https://$($Device.IPAddress)/rest/$FOSOperation"

        # Add VFID only when:
        # - the endpoint is not explicitly chassis-wide,
        # - the device actually has a VFID property,
        # - the VFID contains a value,
        # - and it is not the default VFID 128.
        if (
            -not $IgnoreVFID -and
            $Device.PSObject.Properties['VFID'] -and
            $null -ne $Device.VFID -and
            -not [string]::IsNullOrWhiteSpace([string]$Device.VFID) -and
            [int]$Device.VFID -ne 128
        ) {
            $Uri = "$BaseUrl`?vf-id=$($Device.VFID)"
        }
        else {
            $Uri = $BaseUrl
        }

        if ($PSVersionTable.PSVersion.Major -lt 7) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            if (-not ("TrustAllCertsPolicy" -as [type])) {
                Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;

public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint,
        X509Certificate certificate,
        WebRequest request,
        int certificateProblem) {
        return true;
    }
}
"@
            }

            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }

        $irmParams = @{
            Uri         = $Uri
            Headers     = $Headers
            Method      = $Method
            TimeoutSec  = 30
            ErrorAction = 'Stop'
        }

        if ($null -ne $Body) {
            $irmParams.Body = $Body | ConvertTo-Json -Depth 10
            $irmParams.ContentType = "application/yang-data+json"
        }

        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $irmParams.SkipCertificateCheck = $true
        }

        $result = Invoke-RestMethod @irmParams

        # Some FOS responses wrap the actual result in Response,
        # while others return the object directly.
        if ($null -ne $result.Response) {
            $data = $result.Response
        }
        else {
            $data = $result
        }

        [PSCustomObject]@{
            Success = $true
            Uri     = $Uri
            Data    = $data
            Error   = $null
        }
    }
    catch {
        # Collect all nested exception messages.
        $exceptionMessages = [System.Collections.Generic.List[string]]::new()
        $currentException  = $_.Exception

        while ($null -ne $currentException) {
            $exceptionMessages.Add($currentException.Message)
            $currentException = $currentException.InnerException
        }

        # PowerShell 7 may expose the HTTP response body here.
        $responseBody = $null

        if ($_.ErrorDetails.Message) {
            $responseBody = $_.ErrorDetails.Message
        }

        [PSCustomObject]@{
            Success     = $false
            Uri         = $Uri
            Data        = $null
            Error       = $_.Exception.Message
            ErrorPath   = $exceptionMessages -join " --> "
            ResponseBody = $responseBody
        }
    }
}