function SST_ExportCred {
    param (
        [Parameter(Mandatory)]
        [string]$TD_DeviceType,
        [Parameter(Mandatory)]
        [Int16]$STP_ID,
        [Parameter(Mandatory)]
        [string]$TD_ConnectionTyp,
        [Parameter(Mandatory)]
        [string]$TD_IPAdresse,
        [Parameter(Mandatory)]
        [string]$TD_UserName,
        [bool]$TD_IsSVCIP
    )
    <# collect the access data for subsequent processing #>
    Write-Host $TD_IsSVCIP
    $TD_CredCollection=[ordered]@{
        'DeviceType' = $TD_DeviceType;
        'ID'= $STP_ID;
        'ConnectionTyp'= $TD_ConnectionTyp;
        'IPAddress'= $TD_IPAdresse;
        'UserName'= $TD_UserName;
        'IsSVCIP'= $TD_IsSVCIP;
    }
    $TD_CredObject=New-Object -TypeName psobject -Property $TD_CredCollection
    
    return $TD_CredObject
}