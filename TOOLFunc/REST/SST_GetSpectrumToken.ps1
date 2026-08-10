function SST_GetSpectrumToken {
    [CmdletBinding()]
    param (
        [Int16]$TD_PSVersion = $PSVersionTable.PSVersion.Major,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_PW 
    )
    
    begin {
        <# Write the token to a file in the first phase of 1.4 and later to the DB for release. #>
        $BaseUrl = "https://$TD_Device_DeviceIP"+":7443"

        if(!(Test-Path -Path "$PSRootPath\Resources\DBFolder\ToolDB\ToolDB.db")){
            return $null
        }
        <# Build headers (FlashSystem expects X-Auth-Username / X-Auth-Password for this endpoint) #>
        $Headers = @{
            "accept" = "application/json"
            "X-Auth-Username" = $TD_Device_UserName
            "X-Auth-Password" = $TD_Device_PW
        }
    }
    
    process {
        try {
            if ($TD_PSVersion -ge 7) {
                $response = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/auth" -Method Post -Headers $Headers -Body "" -ContentType 'application/json' -SkipCertificateCheck -ErrorAction Stop
            }
            else {
                $OldCallback =
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback

                try {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

                    $response = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/auth" -Method Post -Headers $Headers -Body "" -ContentType 'application/json' -ErrorAction Stop
                }
                finally {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
                }
            }

            $FlashAPI_Token = [string]$response.token

            if ([string]::IsNullOrWhiteSpace($FlashAPI_Token)) {
                throw "The authentication response did not contain a token."
            }

            $FlashAPI_TokenExpiry = [datetime]::MinValue

            if ($response.PSObject.Properties['expires'] -and -not [string]::IsNullOrWhiteSpace([string]$response.expires)) {
                $ExpiresText = [string]$response.expires

                $HasValidExpiry = [datetime]::TryParse(
                        $ExpiresText,
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        [System.Globalization.DateTimeStyles]::RoundtripKind,
                        [ref]$FlashAPI_TokenExpiry
                    )

                if (-not $HasValidExpiry) {
                    throw "The authentication response contains an invalid expiry value: '$ExpiresText'."
                }
            }
            else {
                if ($TD_PSVersion -ge 7) {
                    $lssecurityInfo = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/lssecurity" -Method Post `
                        -Headers @{
                            accept         = "application/json"
                            "X-Auth-Token" = $FlashAPI_Token
                        } `
                        -ContentType "application/json" `
                        -SkipCertificateCheck `
                        -SslProtocol Tls12 `
                        -Body "" `
                        -ErrorAction Stop
                }
                else {
                    $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback

                    try {
                        [System.Net.ServicePointManager]::
                            ServerCertificateValidationCallback = {
                                $true
                            }

                        $lssecurityInfo = Invoke-RestMethod -Uri "$BaseUrl/rest/v1/lssecurity" -Method Post `
                            -Headers @{
                                accept         = "application/json"
                                "X-Auth-Token" = $FlashAPI_Token
                            } `
                            -ContentType "application/json" `
                            -Body "" `
                            -ErrorAction Stop
                    }
                    finally {
                        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
                    }
                }

                $TimeoutMinutes = 0

                if (-not [int]::TryParse([string]$lssecurityInfo.restapi_timeout_mins,[ref]$TimeoutMinutes)) {
                    throw "The REST API timeout value is missing or invalid."
                }

                $FlashAPI_TokenExpiry = (Get-Date).AddMinutes($TimeoutMinutes)
            }

            $TokenExpiryinISO = $FlashAPI_TokenExpiry.ToString("o",[System.Globalization.CultureInfo]::InvariantCulture)
        }
        catch {
            $TokenRequestError = $_

            SST_ToolMessageCollector -TD_ToolMSGCollector "Spectrum REST authentication failed for $TD_Device_DeviceIP`: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes

            $FlashAPI_Token     = $null
            $TokenExpiryinISO   = $null
        }
        finally {
            $TD_Device_PW = $null

            Remove-Variable TD_Device_PW -ErrorAction SilentlyContinue
        }
    }

    end {
        if ($null -ne $TokenRequestError -or [string]::IsNullOrWhiteSpace([string]$FlashAPI_Token) -or [string]::IsNullOrWhiteSpace([string]$TokenExpiryinISO)) {
            return "plink"
        }

        $RESTInfoObj = [PSCustomObject]@{
            BaseUrl = $BaseUrl
            Token   = $FlashAPI_Token
            Expires = $TokenExpiryinISO
        }

        try {
            $RESTInfo = SST_RESTDBControl -SST_InfoType "SaveStorageToken" -SST_NewDBObject $RESTInfoObj

            if ($RESTInfo -eq "DataSaved") {
                return "REST"
            }
        }
        catch {
            SST_ToolMessageCollector -TD_ToolMSGCollector "Saving the Spectrum REST token failed for $TD_Device_DeviceIP`: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
        }

        return "plink"
    }
}