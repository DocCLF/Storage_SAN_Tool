function Invoke_IBMTapeLibraryApi {
    <#
    .EXAMPLE
        $libinfo = Invoke_IBMTapeLibraryApi -Connection $connect -Method GET -Endpoint 'library/baseinfo'
    .OUTPUTS
        $libinfo.BaseInfo | Format-List *
        SerialNumber        : 3#*#ZM6
        MacAdress_1         : 00:0e:11:18:59:0c
        MacAdress_2         : 00:0e:11:18:59:0d
        Vendor              : IBMi
        ......
        NoOfModules         : 1
        LibraryType         : 60
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
        $Connection = SST_GetTapeLibraryToken -TD_Device_DeviceIP $Device.IPAddress -TD_Device_UserName $Device.UserName -TD_Device_PW $pw -SkipCertificateCheck
        $pw = $null
    }else {
        $Connection = $TapeTokenObj
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
                try {
                    $result = Invoke-RestMethod @irmParams
                    
                }
                catch {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Invoke_IBMTapeLibraryApi: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
                    continue
                }
                
                if ($null -eq $TapeTokenObj) {

                    $SaveTapeObj= [pscustomobject]@{
                        BaseUrl              = $BaseUrl
                        Token                = $Connection.Token
                        SkipCertificateCheck = $Connection.SkipCertificateCheck
                        LoginTime            = $Connection.LoginTime
                    }

                    SST_RESTDBControl -SST_InfoType "SaveTapeToken" -SST_NewDBObject $SaveTapeObj
                }

                return $result
             
            }
            catch {
                SST_ToolMessageCollector -TD_ToolMSGCollector "Invoke_IBMTapeLibraryApi: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
            }
        }else {
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

                try {
                    $result = Invoke-RestMethod @irmParams
                    
                }
                catch {
                    SST_ToolMessageCollector -TD_ToolMSGCollector "Invoke_IBMTapeLibraryApi: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
                    continue
                }
                if ($null -eq $TapeTokenObj) {

                    $SaveTapeObj= [pscustomobject]@{
                        BaseUrl              = $BaseUrl
                        Token                = $Connection.Token
                        SkipCertificateCheck = $Connection.SkipCertificateCheck
                        LoginTime            = $Connection.LoginTime
                    }

                    SST_RESTDBControl -SST_InfoType "SaveTapeToken" -SST_NewDBObject $SaveTapeObj
                }

                return $result
            }
            catch {
                SST_ToolMessageCollector -TD_ToolMSGCollector "Invoke_IBMTapeLibraryApi: $($_.Exception.Message)" -TD_ToolMSGType Error -TD_Shown yes
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