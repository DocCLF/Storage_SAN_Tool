function SST_GetSpectrumToken {
    [CmdletBinding()]
    param (
        [Int16]$TD_PSVersion = $PSVersionTable.PSVersion.Major,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW,
        [string]$TD_Device_Typ,
        [Int16]$TD_Device_ID
    )
    
    begin {
        <# Write the token to a file in the first phase of 1.4 and later to the DB for release. #>
        $RESTFileName = "RESTTempInfos_$TD_Device_Typ"+"_"+"$TD_Device_ID"
        if(Test-Path -Path "$PSScriptRoot\ToolLog\ToolTEMP\$RESTFileName.xml"){
            Remove-Item -Path "$PSScriptRoot\ToolLog\ToolTEMP\$RESTFileName.xml" -Confirm:$false -Force
        }
        <# Build headers (FlashSystem expects X-Auth-Username / X-Auth-Password for this endpoint) #>
        $Headers = @{
            "accept" = "application/json"
            "X-Auth-Username" = $TD_Device_UserName
            "X-Auth-Password" = $TD_Device_PW
        }
        $BaseUrl = "https://$TD_Device_DeviceIP"+":7443"
    }
    
    process {
        try {
            if($TD_PSVersion -ge 7){        
                $response = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/auth" -Method Post -Headers $Headers -Body "" -ContentType 'application/json' -SkipCertificateCheck -ErrorAction Stop
            }else{
                # Save old callback
                $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                # Disable certificate validation
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                $response = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/auth" -Method Post -Headers $Headers -Body "" -ContentType 'application/json'
                # Restore original callback
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
            }
            $FlashAPI_Token = $response.token
            $FlashAPI_TokenExpiry = $null
            if ($response.expires) {
            # Try the most common formats
                try { $FlashAPI_TokenExpiry = [datetime]::Parse($response.expires) } catch {}
            }else{
                if($TD_PSVersion -ge 7){        
                    $lssecurityInfo = Invoke-RestMethod -Uri $BaseUrl/rest/v1/lssecurity -Method Post -Headers @{"accept"="application/json"; "X-Auth-Token"=$FlashAPI_Token } -ContentType "application/json" -SkipCertificateCheck -SslProtocol Tls12 -Body ""
                }else{
                    # Save old callback
                    $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                    # Disable certificate validation
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                    $lssecurityInfo = Invoke-RestMethod -Uri $BaseUrl/rest/v1/lssecurity -Method Post -Headers @{"accept"="application/json"; "X-Auth-Token"=$FlashAPI_Token } -ContentType "application/json" -Body ""
                    # Restore original callback
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
                }
                $FlashAPI_TokenExpiry = $lssecurityInfo.restapi_timeout_mins
            }
        }
        catch {
            <#Do this if a terminating exception happens#>
        } finally {
            # Delete variable
            $TD_Device_PW = $null
            # really remove
            Remove-Variable TD_Device_PW -ErrorAction SilentlyContinue
        }
    }
    
    end {
        $RESTInfoObj = [pscustomobject]@{
            BaseUrl = $BaseUrl
            Token   = $FlashAPI_Token
            Expires = $FlashAPI_TokenExpiry
        }
        $RESTInfoObj | Export-Clixml -Path "$PSScriptRoot\ToolLog\ToolTEMP\$RESTFileName.xml"
        if([string]::IsNullOrEmpty($FlashAPI_Token)){
            return "REST"
        }else {
            return "plink"
        }
    }
}