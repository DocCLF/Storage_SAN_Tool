function SST_GetTapeLibraryToken {
    <#
    .EXAMPLE
        $res = Connect_IBMTapeLibary -TD_Device_DeviceIP <ip> -TD_Device_UserName $cred.UserName -TD_Device_PW $cred.GetNetworkCredential().Password -SkipCertificateCheck
    .OUTPUTS
        TD_Device_DeviceIP   : <ip>
        TD_Device_Port       : 3031
        BaseUri              : https://<ip>:3031
        Token                : Bearer WLnyfGwnc9fD7_f8hk0zRNoUuA
        SkipCertificateCheck : True
        LoginTime            : 25.03.2026 19:43:59
        LoginEndpoint        : /rest/login
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TD_Device_DeviceIP,
        [string]$TD_Device_UserName,
        [string]$TD_Device_PW,
        [int]$TD_Device_Port = 3031,
        [ValidateSet('v1','rest')]
        [string]$PreferredLoginApi = 'v1',
        [switch]$SkipCertificateCheck
    )

    $BaseUrl  = "https://$TD_Device_DeviceIP"+":$TD_Device_Port"

    $loginCandidates =
        if ($PreferredLoginApi -eq 'v1') {
            @('/v1/login', '/rest/login')
        }
        else {
            @('/rest/login', '/v1/login')
        }

    $body = @{
        username = $TD_Device_UserName
        password = $TD_Device_PW
    } | ConvertTo-Json -Compress
    
    $response = $null
    $usedEndpoint = $null

    foreach ($loginEndpoint in $loginCandidates) {
        $loginUri = "$BaseUrl$loginEndpoint"

        $irmParams = @{
            Uri         = $loginUri
            Method      = 'POST'
            ContentType = 'application/json'
            Body        = $body
            ErrorAction = 'Continue'
        }

        if ($SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 6) {

            $irmParams.SkipCertificateCheck = $true
            try{
            $response = Invoke-RestMethod @irmParams
            $usedEndpoint = $loginEndpoint
            break
            }catch{
                SST_ToolMessageCollector -TD_ToolMSGCollector "Tape get Token: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
            }

        }else {
            # PowerShell 5.1 (HttpWebRequest): Using callback
            $irmParams.UseBasicParsing = $true

            $OldCallback = $null
            try {
                if ($SkipCertificateCheck) {
                    $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                }

                $response = Invoke-RestMethod @irmParams
            }
            finally {
                if ($SkipCertificateCheck) {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
                }
            }
        }
    }

    if (-not $response) {
        SST_ToolMessageCollector -TD_ToolMSGCollector "The login was successful, but no token was returned." -TD_ToolMSGType Error -TD_Shown yes
    }
    
    # Some APIs return { token = â€˜Bearer ...â€™ }, while others may return string content directly.
    $token = $null

    if ($response -is [string]) {
        $token = $response
    }
    elseif ($response.PSObject.Properties.Name -contains 'token') {
        $token = $response.token
    }
    elseif ($response.PSObject.Properties.Name -contains 'Token') {
        $token = $response.Token
    }

    if ([string]::IsNullOrWhiteSpace($token)) {
        SST_ToolMessageCollector -TD_ToolMSGCollector "The login was successful, but no token was returned." -TD_ToolMSGType Error -TD_Shown yes
    }

    [pscustomobject]@{
        PSTypeName           = 'IbmTapeLibrary.Connection'
        TD_Device_DeviceIP   = $TD_Device_DeviceIP
        TD_Device_Port       = $TD_Device_Port
        BaseUrl              = $BaseUrl
        Token                = $token
        SkipCertificateCheck = [bool]$SkipCertificateCheck
        LoginTime            = Get-Date
    }
}
