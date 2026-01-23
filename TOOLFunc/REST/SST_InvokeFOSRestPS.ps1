function SST_InvokeFOSRestPS {
  <#
  .SYNOPSIS
    Executes a FOS REST call (Login -> Request -> Logout) in PowerShell 5.1 
    via curl.exe (robust against TLS/renegotiation issues in WinPS/.NET).

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
    HTTP method (Default: GET)

  .PARAMETER VfId
    Optional: VFID (appended as ?vf_id=<id>)

  .PARAMETER Accept
    Optional: Accept Header (Default: application/yang-data+json)

  .PARAMETER ReturnRaw
    If set: returns the raw string from curl. Otherwise, attempts to convert JSON to a PS object.

  .EXAMPLE
    $cred = Get-Credential
    SST_InvokeFOSRestPS -SwitchIp 192.168.249.81 -Credential $cred -Resource "brocade-chassis/chassis"

  .EXAMPLE
    SST_InvokeFOSRestPS -SwitchIp 192.168.249.81 -Credential $cred -Resource "brocade-fabric/fabric-switch" -VfId 100
  #>

  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$SwitchIp,

    [Parameter(Mandatory)]
    [string]$User,

    [Parameter(Mandatory)]
    [string]$Pass,

    [pscredential]$Credential,

    [Parameter(Mandatory)]
    [string]$Resource,

    [ValidateSet("GET","POST","PUT","PATCH","DELETE")]
    [string]$Method = "GET",

    [int]$VfId,

    [string]$Accept = "application/yang-data+json",

    [switch]$ReturnRaw
  )

  # WinPS 5.1: curl is an alias for Invoke-WebRequest -> we want curl.exe
  $curl = (Get-Command curl.exe -ErrorAction SilentlyContinue)
  if (-not $curl) { throw "curl.exe nicht gefunden. Bitte sicherstellen, dass curl.exe verfügbar ist (Windows 10/11/Server 2019+ i.d.R. vorhanden)." }

  $base = "https://$SwitchIp"
  $resource = $Resource.TrimStart('/')

  # If a Credential object exists, retrieve it from PSCredential, removing #.
  $User #= $Credential.UserName
  $Pass #= $Credential.GetNetworkCredential().Password

  # Build URL (+ optional vf_id)
  $uri = "$base/rest/running/$resource"
  if ($PSBoundParameters.ContainsKey('VfId')) {
    $join = ($uri -match '\?') ? '&' : '?'
    $uri = "$uri$join" + "vf_id=$VfId"
  }

  # --- Login: Output header (-D -), discard body (-o NUL) ---
  # Note: -u takes user:pass; we escape the colon in PS with `:
  $hdr = & curl.exe -sk -D - -o NUL -X POST -u "$user`:$pass" "$base/rest/login"

  # Extract authorization header
  $tokenLine = ($hdr | Select-String -Pattern '^(?i)Authorization:\s*' | Select-Object -First 1).Line
  if (-not $tokenLine) {
    throw "Login fehlgeschlagen: Kein Authorization-Header erhalten. Prüfe User/Passwort und mgmtapp AuthMode."
  }

  $token = ($tokenLine -replace '^(?i)Authorization:\s*','').Trim()

  try {
    # curl arguments for request
    $args = @('-sk', '-H', "Authorization: $token", '-H', "Accept: $Accept")

    switch ($Method) {
      'GET'    { $args += @('-X','GET',    $uri) }
      'POST'   { $args += @('-X','POST',   $uri) }
      'PUT'    { $args += @('-X','PUT',    $uri) }
      'PATCH'  { $args += @('-X','PATCH',  $uri) }
      'DELETE' { $args += @('-X','DELETE', $uri) }
    }

    $raw = & curl.exe @args

    if ($ReturnRaw) { return $raw }

    # If JSON, convert to object; otherwise return raw
    $trim = ($raw | Out-String).Trim()
    if ($trim.StartsWith('{') -or $trim.StartsWith('[')) {
      return $trim | ConvertFrom-Json
    } else {
      return $trim
    }
  }
  finally {
    # --- Logout always ---
    try {
      & curl.exe -sk -X POST -H "Authorization: $token" "$base/rest/logout" | Out-Null
    } catch { }
  }
}