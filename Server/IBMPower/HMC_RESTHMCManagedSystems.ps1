function HMC_RESTHMCManagedSystems {
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

    # Device should have: IP address, user name, password, port if applicable
    $ip   = $TD_Device_DeviceIP
    [int]$port = 12443

    $user = $TD_Device_UserName
    $pass = $TD_Device_PW

    # --- High Level Wrapper: Login -> Query -> Logout ---
    $ms = HMC_InvokeHmcQuery -HMCIP $ip -HMCPort $port -CredentialUN $user -CredentialPW $pass -Query ManagedSystems -IgnoreCertificate

    <# Write to the local database first before displaying it in the GUI! #>
    SST_CustomerDeviceDBInsertTable -SST_InfoType "PowerSysSummary" -SST_CollectedInformations $ms

    # RowID for Add-MappedRows (stable for the grid)
    $i = 0
    $ms | ForEach-Object {
        $i++
        $_ | Add-Member -NotePropertyName RowID -NotePropertyValue ("{0}-MS-{1}" -f $ip, $i) -Force
        $_
    }
}
