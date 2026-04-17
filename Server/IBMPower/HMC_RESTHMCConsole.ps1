function HMC_RESTHMCConsole {
    [CmdletBinding()]
    param(
        [Int16]$TD_Line_ID,
        [string]$TD_Device_ConnectionTyp,
        [string]$TD_Device_UserName,
        [string]$TD_Device_DeviceIP,
        #[string]$TD_Device_DeviceName,
        [string]$TD_Device_PW,
        [string]$TD_Export = "yes",
        [string]$TD_Exportpath
    )

    $user = $TD_Device_UserName
    $pass = $TD_Device_PW
    $ip   = $TD_Device_DeviceIP
    [int]$port = 12443

    $hmc = HMC_InvokeHmcQuery `
        -HMCIP $ip `
        -HMCPort $port `
        -CredentialUN $user `
        -CredentialPW $pass `
        -Query HMC `
        -IgnoreCertificate

    <# Write to the local database first before displaying it in the GUI! #>
    SST_CustomerPWRDBInsertTable -SST_InfoType "PowerHMC" -SST_CollectedInformations $hmc

    # RowID for Add-MappedRows (stable for the grid)
    $i = 0
    foreach($o in $hmc){
        $i++
        $o | Add-Member -NotePropertyName RowID -NotePropertyValue ("{0}-HMC-{1}" -f $ip, $i) -Force
        $o
    }
}
