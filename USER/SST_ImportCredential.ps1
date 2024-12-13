function SST_ImportCredential {
    [CmdletBinding()]
    param (
        
    )
    $TD_ImportCredentialObjs = SST_OpenFile_from_Directory

    if($TD_ImportCredentialObjs.FileName -ne ""){
    $TD_ImportedCredentials = Import-Csv -Path $TD_ImportCredentialObjs.FileName -Delimiter ';'
    }

    return $TD_ImportedCredentials
}