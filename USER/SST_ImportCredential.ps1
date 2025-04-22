function SST_ImportCredential {
    [CmdletBinding()]
    param (
        
    )
    $TD_ImportCredentialObjs = SST_OpenFile_from_Directory

    if($TD_ImportCredentialObjs.FileName -ne ""){
        $TD_ImportedCredentials = Import-Clixml -Path $TD_ImportCredentialObjs.FileName 
        <# must used this line if there is only one entry #>
        [array]$TD_ExportCredtoDG = $TD_ImportedCredentials | Where-Object { $_ }
        $TD_DG_KnownDeviceList.ItemsSource = $TD_ExportCredtoDG
    }

   return $TD_ExportCredtoDG
}