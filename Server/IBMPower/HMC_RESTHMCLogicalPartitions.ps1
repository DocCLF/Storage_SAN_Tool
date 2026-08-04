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

    $partitions = HMC_InvokeHmcQuery -HMCIP $ip -HMCPort $port -CredentialUN $user -CredentialPW $pass -Query Partitions -IgnoreCertificate

    <# Write to the local database first before displaying it in the GUI! #>
    SST_CustomerPWRDBInsertTable -SST_InfoType "LPARSummary" -SST_CollectedInformations $partitions 
    Out-File -FilePath $TD_Exportpath\$($TD_Line_ID)_lpar_$(Get-Date -Format "yyyy-MM-dd").txt -InputObject $partitions  -Append

    $i = 0
    $partitions  | ForEach-Object {
        $i++
        $_ | Add-Member -NotePropertyName RowID -NotePropertyValue ("{0}-LPAR-{1}" -f $ip, $_.PartitionRole, $i) -Force
        $_
    }
}
