function SST_ImportCredential {
    [CmdletBinding()]
    param (
        
    )
    $TD_ImportCredentialObjs = SST_OpenFile_from_Directory
    #$test = Get-Content -Path C:\Users\r.glanz\Documents\testexp.csv
    if($TD_ImportCredentialObjs.FileName -ne ""){
    $TD_ImportedCredentials = Import-Csv -Path $TD_ImportCredentialObjs.FileName -Delimiter ';'
    }
    #Write-Host $TD_ImportedCredentials -ForegroundColor Blue
    return $TD_ImportedCredentials
}