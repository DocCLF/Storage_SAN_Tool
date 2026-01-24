function SST_InvokeFOSRestPWSH {
  <#
  .SYNOPSIS
    Executes a FOS REST call (Login -> Request -> Logout) in PowerShell 7.
  
  .DESCRIPTION
    The Fabric OS REST interface is enabled by default. 
    To disable the Fabric OS REST interface, enter mgmtapp --disable REST.
    To re-enable the Fabric OS REST interface, enter mgmtapp --enable REST.
    Useful link to the documentation: 

  .LINK
    https://techdocs.broadcom.com/us/en/fibre-channel-networking/fabric-os/fabric-os-cli-to-rest-api/10-0-x/CLI-to-REST-API-Mappings.html

  .PARAMETER SwitchIp
    IP or host name of the switch (without https://)

  .PARAMETER User
    UserName

  .PARAMETER Pass
    Password

  .PARAMETER Resource
    REST resource relative to /rest/running/, e.g., “brocade-chassis/chassis”
    (without leading slash)

  .PARAMETER Method
    HTTP method (default: GET)

  .PARAMETER VfId
    Optional: VFID (appended as ?vf_id=<id>)

  .PARAMETER Accept
    Optional: Header akzeptieren (Standard: application/yang-data+json)

  .EXAMPLE
    $cred = Get-Credential
    SST_InvokeFOSRestPWSH -SwitchIp 192.168.249.81 -Credential $cred -Resource "brocade-chassis/chassis"

  .EXAMPLE
    SST_InvokeFOSRestPWSH -SwitchIp 192.168.249.81 -Credential $cred -Resource "brocade-fabric/fabric-switch" -VfId 100
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$SwitchIp,

    [string]$User,

    [string]$Pass,

    [pscredential]$Credential,

    [Parameter(Mandatory)]
    [string]$Resource,

    [ValidateSet("GET","POST","PUT","PATCH","DELETE")]
    [string]$Method = "GET",

    [int]$VfId,

    [string]$Accept = "application/yang-data+json"
  )

  $base = "https://$SwitchIp"
  $resource = $Resource.TrimStart('/')

  # Basic Auth headers such as curl (explicit)
  if($Credential){
    $u = $Credential.UserName
    $p = $Credential.GetNetworkCredential().Password
  }else{
    $u = $User #$Credential.UserName
    $p = $Pass #$Credential.GetNetworkCredential().Password
  }

  $basic = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$u`:$p"))

  # --- Login ---
  $login = Invoke-WebRequest -Method Post `
    -Uri "$base/rest/login" `
    -Headers @{ Authorization = "Basic $basic"; Accept="*/*" } `
    -ContentType "application/yang-data+xml" `
    -Body "" `
    -SkipCertificateCheck `
    -ErrorAction Stop

  # Normalize token: String[] -> String
  $token = @($login.Headers.Authorization)[0].Trim()

  $headers = @{
    Authorization = $token
    Accept        = $Accept
  }

  # Build URL (+ optional vf_id)
  $uri = "$base/rest/running/$resource"
  if ($PSBoundParameters.ContainsKey('VfId')) {
    $join = ($uri -match '\?') ? '&' : '?'
    $uri = "$uri$join" + "vf_id=$VfId"
  }

  try {
    switch ($Method) {
      "GET"    { return Invoke-RestMethod -Method Get    -Uri $uri -Headers $headers -SkipCertificateCheck -ErrorAction Stop }
      "POST"   { return Invoke-RestMethod -Method Post   -Uri $uri -Headers $headers -SkipCertificateCheck -ErrorAction Stop }
      "PUT"    { return Invoke-RestMethod -Method Put    -Uri $uri -Headers $headers -SkipCertificateCheck -ErrorAction Stop }
      "PATCH"  { return Invoke-RestMethod -Method Patch  -Uri $uri -Headers $headers -SkipCertificateCheck -ErrorAction Stop }
      "DELETE" { return Invoke-RestMethod -Method Delete -Uri $uri -Headers $headers -SkipCertificateCheck -ErrorAction Stop }
    }
  }
  finally {
    # --- Logout (always) ---
    try {
      Invoke-WebRequest -Method Post `
        -Uri "$base/rest/logout" `
        -Headers @{ Authorization = $token } `
        -ContentType "application/yang-data+xml" `
        -Body "" `
        -SkipCertificateCheck `
        -ErrorAction SilentlyContinue | Out-Null
    } catch { }
  }
}
