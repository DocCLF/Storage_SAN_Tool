function Invoke-BrocadeRest {
    <#
    .DESCRIPTION
        URIs are case-sensitive.
        URIs have two parts:
            + Base URI — For Fabric OS modules for Fibre Channel features, the base URI is https://host:port/rest/running. For Fabric OS modules for operations, the base URI is http://host:port/rest.
            + Request URI — The request URI displays in the REST API URI column of the mapping tables. For example, /brocade-security/ldap-server.
        In this example of a Fibre Channel feature module URI, the text in bold is the base URI, and the remaining portion is the request 
            URI: https://10.10.10.10:443/rest/running/brocade-zone/defined-configuration/zone/zone-name/memberentry/entry-name
        In this example of operations module URI, the text in bold is the base URI, and the remaining portion is the request 
            URI: https://10.10.10.10:443/rest/operations/fibrechannel-zone/action=rename
    .EXAMPLE
        Invoke-BrocadeRest -Device $sw -FOSOperation "running/brocade-fabric/fabric-switch"
    .EXAMPLE
        Invoke-BrocadeRest -Device $sw -Method PATCH -FOSOperation "running/brocade-interface/fibrechannel"
    .OUTPUTS

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Device,
        [Parameter(Mandatory)]
        [string]$FOSOperation,
        [ValidateSet("GET","POST","PATCH","PUT","DELETE")]
        [string]$Method = "GET",
        $Body
    )

    try {
        $pw = [Net.NetworkCredential]::new('', $Device.Password).Password

        $pair   = "$($Device.UserName):$pw"
        $bytes  = [System.Text.Encoding]::ASCII.GetBytes($pair)
        $base64 = [Convert]::ToBase64String($bytes)
        $pw = $null

        $Headers = @{
            Authorization = "Basic $base64"
            Accept         = "application/yang-data+json"
        }
        

        $Uri = "https://$($Device.IPAddress):443/rest/$FOSOperation"

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

        if ($Body) {
            $irmParams.Body = ($Body | ConvertTo-Json -Depth 10)
            $irmParams.ContentType = "application/yang-data+json"
        }

        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $irmParams.SkipCertificateCheck = $true
        }

        $result = Invoke-RestMethod @irmParams

        if($null -ne $result.Response){
            $data = $result.Response
        }
        else{
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

        [PSCustomObject]@{
            Success = $false
            Uri     = $Uri
            Data    = $null
            Error   = $_.Exception.Message
        }
    }
}