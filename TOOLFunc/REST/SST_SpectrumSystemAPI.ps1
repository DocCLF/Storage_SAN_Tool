function SST_SpectrumSystemAPI {
    [CmdletBinding()]
    param (
        [Int16]$TD_PSVersion = $PSVersionTable.PSVersion.Major,
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        [ValidateSet("GET","POST","PUT","DELETE")]
        [string]$Method = "POST",
        [string]$BaseUrl,
        [string]$RESTInfo,
        [object]$Body
    )
    
    begin {

        $Uri = "$BaseUrl/rest/v1/$Endpoint"
        Write-Host "$Uri"
        if([string]::IsNullOrWhiteSpace($RESTInfo)){
            $RESTToken = SST_RESTDBControl -SST_InfoType "UseStorageToken" -SST_BaseUrl $BaseUrl
            
        }else{
            $RESTToken = $RESTInfo
        }
        $Headers = @{
            "accept"       = "application/json"
            "X-Auth-Token" = $RESTToken
        }
        $bodyJson = if ($null -ne $Body) { $Body | ConvertTo-Json -Depth 10 -Compress } else { "" }
    }
    
    process {
        if($TD_PSVersion -eq 5){
            # Save old callback
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
            # Disable certificate validation
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

            try {
                $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -ContentType "application/json" -Body $bodyJson
            }
            finally {
                # Restore original callback
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
            }
        }else{
            try {
                $response = Invoke-RestMethod -Uri $Uri -Method $Method -Headers $Headers -ContentType "application/json" -Body $bodyJson -SkipCertificateCheck -SslProtocol Tls12
            } catch {
                Write-Error "API error when calling $Endpoint :" -ForegroundColor Red
                Write-Error $_ -ForegroundColor Red
                return $null
            }
        }
    }
    
end {
  # optional debug:
  #$response | Select-Object -First 5 | Format-List * | Out-String | Write-Host
  return $response
}
}