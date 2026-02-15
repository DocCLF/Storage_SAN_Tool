function HMC_RESTHMCLogicalPartitions {
    [CmdletBinding()]
    param (
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        #[string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )

    $ip   = $TD_Device_DeviceIP
    [int]$port = 12443

    $user = $TD_Device_UserName
    $pass = $TD_Device_PW

    $lpars = HMC_InvokeHmcQuery `
        -HMCIP $ip `
        -HMCPort $port `
        -CredentialUN $user `
        -CredentialPW $pass `
        -Query LPARs `
        -IgnoreCertificate

    <# Write to the local database first before displaying it in the GUI! #>
    SST_CustomerDeviceDBInsertTable -SST_InfoType "LPARSummary" -SST_CollectedInformations $lpars

    $i = 0
    $lpars | ForEach-Object {
        $i++
        $_ | Add-Member -NotePropertyName RowID -NotePropertyValue ("{0}-LPAR-{1}" -f $ip, $i) -Force
        $_
    }
}
