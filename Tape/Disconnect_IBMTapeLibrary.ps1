function Disconnect_IBMTapeLibrary {
    ## this is a placeholder func
    #
    #[CmdletBinding()]
    #param(
    #    [Parameter(Mandatory)]
    #    $Connection,
    #    [Parameter(Mandatory)]
    #    [ValidateSet('GET','POST','PUT','PATCH','DELETE')]
    #    [string]$Method,
    #    [string]$Endpoint = 'logout',
    #    [switch]$SkipCertificateCheck
    #)
#
    ##LocalDB abfrage nach APIVersionwEndpoint und dann den Login Endpoint mit logout ersetzen
    #$uri = if ($APIVersionwEndpoint -match '^https?://') {
    #    $APIVersionwEndpoint.Replace('login','logout')
    #}else {
    #    "$($Connection.BaseUri)/v1/logout"
    #}
#
    #$headers = @{
    #    Accept        = 'application/json'
    #    Authorization = $Connection.Token
    #}
#
    #$irmParams = @{
    #    Uri         = $uri
    #    Method      = $Method
    #    Headers     = $headers
    #    ErrorAction = 'Continue'
    #}
#
    #if ($PSBoundParameters.ContainsKey('Body')) {
    #    $irmParams.ContentType = 'application/json'
    #    $irmParams.Body = if ($Body -is [string]) {
    #        $Body
    #    } else {
    #        $Body | ConvertTo-Json -Depth 20 -Compress
    #    }
    #}
#
    #if ($Connection.SkipCertificateCheck -and $PSVersionTable.PSVersion.Major -ge 6) {
    #    $irmParams.SkipCertificateCheck = $true
    #    Invoke-RestMethod @irmParams
    #}else {
    #    # PowerShell 5.1 (HttpWebRequest): Using callback
    #    $irmParams.UseBasicParsing = $true
    #    $OldCallback = $null
    #    try {
    #        if ($SkipCertificateCheck) {
    #            $OldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
    #            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    #        }
    #        Invoke-RestMethod @irmParams
    #    }
    #    finally {
    #        if ($SkipCertificateCheck) {
    #            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $OldCallback
    #        }
    #    }
    #}
}