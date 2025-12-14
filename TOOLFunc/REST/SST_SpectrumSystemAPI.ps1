function SST_SpectrumSystemAPI {
    [CmdletBinding()]
    param (
        [Int16]$TD_PSVersion = $PSVersionTable.PSVersion.Major,
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        [ValidateSet("GET","POST","PUT","DELETE")]
        [string]$Method = "POST",
        [string]$RESTFileName,
        [object]$Body
    )
    
    begin {
        try {
            $CredImportXML = Import-Clixml -Path "$PSScriptRoot\ToolLog\ToolTEMP\$RESTFileName.xml"
        }
        catch {
            Write-Host $_.Exception.Message 
        }
        $Uri = "$($CredImportXML.BaseUrl)/rest/v1/$Endpoint"
        $Headers = @{
            "accept"       = "application/json"
            "X-Auth-Token" = "$($CredImportXML.Token)"
        }
        $bodyJson = if ($null -ne $Body) { $Body | ConvertTo-Json } else { "" }
    }
    
    process {
        if($TD_PSVersion -eq 5){
            # Save old callback
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
                Write-Host "API error when calling $Endpoint :" -ForegroundColor Red
                Write-Host $_ -ForegroundColor Red
                return $null
            }
        }
    }
    
    end {
        return $response
    }
}