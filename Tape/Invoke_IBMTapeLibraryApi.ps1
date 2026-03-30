function Invoke_IBMTapeLibraryApi {
    <#
    .EXAMPLE
        $libinfo = Invoke_IBMTapeLibraryApi -Connection $connect -Method GET -Endpoint 'library/baseinfo'
    .OUTPUTS
        $libinfo.BaseInfo | Format-List *
        SerialNumber        : 3555L3A7801ZM6
            $mtm="3555L3A7801ZM6"
            $sn = $mtm.Substring($mtm.Length -7) /  SN = 7801ZM6
            $($mtm.TrimEnd($sn)).Insert(4,"-") /    MTM = 3555-L3A
        MacAdress_1         : 00:0e:11:18:59:0c
        MacAdress_2         : 00:0e:11:18:59:0d
        Vendor              : IBM
        ProductID           : 3573-TL
        BaseFWRevision      : 1.6.0.0-A00
        BaseFWBuildDate     : 2022-12-08
        ExpansionFWRevision : 0.37
        WWNodeName          : 5000E1118590C000
        RoboticHWRevision   : 6
        RoboticFWRevision   : 0.19
        RoboticSerialNumber : 564MC3EC028304
        NoOfModules         : 1
        LibraryType         : 40
    #>
    [CmdletBinding()]
    param(
        $Connection,
        [ValidateSet('GET','POST','PUT','PATCH','DELETE')]
        [string]$Method = 'GET',
        [Parameter(Mandatory)]
        [string]$Endpoint,
        $Device,
        [object]$Body,

        [switch]$SkipCertificateCheck
    )

    $BaseUrl  = "https://$($Device.IPAddress)"+":3031"
    $TapeTokenObj = SST_RESTDBControl -SST_InfoType "UseTapeToken" -SST_BaseUrl $BaseUrl
    
    if($null -eq $TapeTokenObj){
        $pw = [Net.NetworkCredential]::new('', $Device.Password).Password
        $Connection = Connect_IBMTapeLibrary -TD_Device_DeviceIP $Device.IPAddress -TD_Device_UserName $Device.UserName -TD_Device_PW $pw -SkipCertificateCheck
    }else {
        $Connection = $TapeTokenObj
        $APIVersionEndpoint = $TapeTokenObj.WorkingEndpoint
    }

    if ([string]::IsNullOrWhiteSpace($APIVersionEndpoint)) {
        $APIVersionEndpoint = @("/v1/$Endpoint", "/rest/$Endpoint")
    }else {
        $APIVersionEndpoint = "$APIVersionEndpoint$Endpoint"
    }

    $headers = @{
        Accept        = 'application/json'
        Authorization = $Connection.Token
    }

    foreach($APIEndPoint in $APIVersionEndpoint) {

        $uri = if ($APIEndPoint -match '^https?://') {
            $APIEndPoint
        } else {
            "$($BaseUrl)$APIEndPoint"
        }
        if($null -eq $($Device.IPAddress)){continue}
        $irmParams = @{
            Uri         = $uri
            Method      = $Method
            Headers     = $headers
            ErrorAction = 'Stop'
        }

        if ($PSBoundParameters.ContainsKey('Body')) {
            $irmParams.ContentType = 'application/json'
            $irmParams.Body = if ($Body -is [string]) {
                $Body
            } else {
                $Body | ConvertTo-Json -Depth 20 -Compress
            }
        }

        if ($PSVersionTable.PSVersion.Major -ge 6) {
            if ($Connection.SkipCertificateCheck) {
                $irmParams.SkipCertificateCheck = $true
            }

            try {
                $result = Invoke-RestMethod @irmParams

                $SaveTapeObj= [pscustomobject]@{
                    BaseUrl              = $BaseUrl
                    Token                = $Connection.Token
                    SkipCertificateCheck = $Connection.SkipCertificateCheck
                    WorkingEndpoint      = $APIEndPoint.TrimEnd($Endpoint)
                    LoginTime            = $Connection.LoginTime
                }

                SST_RESTDBControl -SST_InfoType "SaveTapeToken" -SST_NewDBObject $SaveTapeObj
                return $result
            }
            catch {
                Write-Verbose $_.Exception.Message

                $statusCode = $null
                if ($_.Exception.Response) {
                    try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
                }

                if ($statusCode -eq 401) {
                    throw
                }
                if ($statusCode -ge 400 -and $statusCode -lt 500) {
                    continue
                }

                throw
            }
        }
        else {
            $irmParams.UseBasicParsing = $true
            $oldCallback = $null
            $oldProtocol = [System.Net.ServicePointManager]::SecurityProtocol

            try {
                # Ensure TLS 1.2 for WinPS 5.1
                [System.Net.ServicePointManager]::SecurityProtocol = `
                    [System.Net.ServicePointManager]::SecurityProtocol -bor `
                    [System.Net.SecurityProtocolType]::Tls12

                if ($Connection.SkipCertificateCheck) {
                    $oldCallback = [System.Net.ServicePointManager]::ServerCertificateValidationCallback
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                }

                $result = Invoke-RestMethod @irmParams

                $SaveTapeObj= [pscustomobject]@{
                    BaseUrl              = $BaseUrl
                    Token                = $Connection.Token
                    SkipCertificateCheck = $Connection.SkipCertificateCheck
                    WorkingEndpoint      = $uri
                    LoginTime            = $Connection.LoginTime
                }

                SST_RESTDBControl -SST_InfoType "SaveTapeToken" -SST_NewDBObject $SaveTapeObj

                return $result
            }
            catch {
                Write-Verbose $_.Exception.Message

                $statusCode = $null
                if ($_.Exception.Response) {
                    try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
                }

                if ($statusCode -eq 401) {
                    throw
                }
                if ($statusCode -ge 400 -and $statusCode -lt 500) {
                    continue
                }
            }
            finally {
                [System.Net.ServicePointManager]::SecurityProtocol = $oldProtocol

                if ($Connection.SkipCertificateCheck) {
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $oldCallback
                }
            }
        }
    }
}